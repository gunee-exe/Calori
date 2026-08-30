/**
 * Calori vision Worker.
 *
 * Sits between the app and the model so that four things live on a server the
 * user does not control: the API key, the per-device rate limit, the
 * image-hash cache, and the model choice. That last one is the reason to keep
 * this even though it looks like indirection — swapping providers is a change
 * here and nowhere else, with no app update.
 *
 * Contract: 01-concept.md §9.
 */

const ANALYZE_PATH = '/analyze';
const UPSTREAM = 'https://openrouter.ai/api/v1/chat/completions';

/** 8 MB of base64 is roughly a 6 MB image — far above the ~120 KB the app sends. */
const MAX_BODY_BYTES = 8 * 1024 * 1024;

/** How long an identical photo keeps its answer. */
const CACHE_TTL_SECONDS = 60 * 60 * 24 * 30;

/**
 * The response shape, enforced by the provider rather than parsed out of prose.
 *
 * `additionalProperties: false` and a full `required` list are both load-bearing:
 * without them some providers happily return extra keys or omit ones the app
 * treats as mandatory.
 */
const RESPONSE_SCHEMA = {
  type: 'object',
  properties: {
    items: {
      type: 'array',
      description: 'One entry per distinct food visible in the photo.',
      items: {
        type: 'object',
        properties: {
          name: {
            type: 'string',
            description:
              'Common name of the dish, lowercase. Prefer the specific ' +
              'regional name where it is unambiguous, e.g. "chicken biryani" ' +
              'rather than "rice dish".',
          },
          portion_desc: {
            type: 'string',
            description:
              'How a person would describe the amount, e.g. "1 plate", ' +
              '"2 rotis", "half a bowl".',
          },
          grams: { type: 'number', description: 'Estimated edible weight in grams.' },
          kcal: { type: 'number' },
          protein_g: { type: 'number' },
          carbs_g: { type: 'number' },
          fat_g: { type: 'number' },
          confidence: { type: 'string', enum: ['high', 'medium', 'low'] },
          confidence_reason: {
            type: 'string',
            description:
              'Short, concrete reason for the confidence level, addressed to ' +
              'the user, e.g. "no reference object in frame". Never empty.',
          },
        },
        required: [
          'name',
          'portion_desc',
          'grams',
          'kcal',
          'protein_g',
          'carbs_g',
          'fat_g',
          'confidence',
          'confidence_reason',
        ],
        additionalProperties: false,
      },
    },
  },
  required: ['items'],
  additionalProperties: false,
};

/**
 * The preparation-fat instruction is the single most important line here.
 *
 * Models estimate from what is visible, and cooking oil, ghee and butter are
 * absorbed rather than visible. Without this, South Asian and other
 * oil-forward cuisines come back 30-40% light, consistently — which is worse
 * than a random error because it never looks wrong.
 */
const SYSTEM_PROMPT = `You estimate the nutritional content of food from photographs.

Rules:
1. Identify each distinct food. Use the specific dish name when you are
   confident of it, including regional names (biryani, karahi, dosa, pho).
   Do not invent precision: "mixed salad" is better than a wrong specific name.
2. Estimate the EDIBLE weight in grams. Use visible reference objects — a
   standard dinner plate is 26-28 cm, a teaspoon 5 ml, a mug 300 ml.
3. ACCOUNT FOR PREPARATION FAT. Oil, ghee and butter absorbed during cooking
   are not visible but carry real calories. A restaurant curry, a stir fry, or
   any fried item carries substantially more fat than its ingredients alone
   suggest. Under-counting this is the most common way an estimate goes wrong.
4. Set confidence honestly:
   - high: the food is unambiguous and something in frame gives scale.
   - medium: the food is clear but the portion is a judgement call.
   - low: the dish is ambiguous, hidden, or there is nothing to judge size by.
5. confidence_reason must be a short, concrete phrase the user can act on,
   such as "no reference object in frame" or "sauce hides the portion size".
   Never leave it empty, and never restate the confidence level itself.
6. Report each food once. Do not list ingredients of a mixed dish separately.

Return only the structured object.`;

export default {
  async fetch(request, env, ctx) {
    if (request.method === 'OPTIONS') return cors(new Response(null, { status: 204 }));

    const url = new URL(request.url);

    if (url.pathname === '/health') {
      return cors(json({ ok: true, model: env.MODEL }));
    }

    if (url.pathname !== ANALYZE_PATH) {
      return cors(json({ error: 'not_found' }, 404));
    }
    if (request.method !== 'POST') {
      return cors(json({ error: 'method_not_allowed' }, 405));
    }

    try {
      return cors(await analyze(request, env, ctx));
    } catch (error) {
      // Log the real thing. On Whispr a catch block turned server errors into
      // UI messages and hid the actual failure for weeks.
      console.error('unhandled', {
        message: error?.message,
        stack: error?.stack,
      });
      return cors(json({ error: 'internal', message: 'Analysis failed.' }, 500));
    }
  },
};

async function analyze(request, env, ctx) {
  const auth = request.headers.get('authorization') || '';
  if (env.APP_SHARED_SECRET && auth !== `Bearer ${env.APP_SHARED_SECRET}`) {
    return json({ error: 'unauthorized' }, 401);
  }

  const raw = await request.text();
  if (raw.length > MAX_BODY_BYTES) {
    return json({ error: 'payload_too_large' }, 413);
  }

  let body;
  try {
    body = JSON.parse(raw);
  } catch {
    return json({ error: 'bad_request', message: 'Body is not JSON.' }, 400);
  }

  const imageBase64 = body.image_base64;
  if (typeof imageBase64 !== 'string' || imageBase64.length < 100) {
    return json({ error: 'bad_request', message: 'image_base64 is required.' }, 400);
  }

  const deviceId = request.headers.get('x-device-id') || 'anonymous';
  const limited = await checkRateLimit(env, deviceId);
  if (limited) return limited;

  // Cache by image hash. Re-analysing the identical photo — a retry after a
  // dropped connection, most often — should cost nothing and, more
  // importantly, must return the same numbers. A second opinion that differs
  // from the first reads as a bug.
  const hash = await sha256(imageBase64);
  const cacheKey = `img:${hash}`;

  if (env.KV) {
    const cached = await env.KV.get(cacheKey, 'json');
    if (cached) {
      console.log('cache_hit', { hash, device: deviceId });
      return json({ ...cached, cached: true });
    }
  }

  const hint = typeof body.user_hint === 'string' ? body.user_hint.slice(0, 200) : null;

  let result = await callModel(env, env.MODEL, imageBase64, hint);

  if (!result.ok && env.FALLBACK_MODEL) {
    console.warn('primary_model_failed', {
      model: env.MODEL,
      reason: result.reason,
    });
    result = await callModel(env, env.FALLBACK_MODEL, imageBase64, hint);
  }

  if (!result.ok) {
    return json({ error: 'upstream', message: 'Could not read that photo.' }, 502);
  }

  const payload = { items: result.items };

  if (env.KV) {
    ctx.waitUntil(
      env.KV.put(cacheKey, JSON.stringify(payload), {
        expirationTtl: CACHE_TTL_SECONDS,
      }),
    );
  }

  return json(payload);
}

async function callModel(env, model, imageBase64, hint) {
  const userContent = [
    {
      type: 'text',
      text: hint
        ? `Estimate the nutrition in this photo. The user says: ${hint}`
        : 'Estimate the nutrition in this photo.',
    },
    {
      type: 'image_url',
      image_url: { url: `data:image/jpeg;base64,${imageBase64}` },
    },
  ];

  let response;
  try {
    response = await fetch(UPSTREAM, {
      method: 'POST',
      headers: {
        authorization: `Bearer ${env.OPENROUTER_API_KEY}`,
        'content-type': 'application/json',
        'x-title': 'Calori',
      },
      body: JSON.stringify({
        model,
        messages: [
          { role: 'system', content: SYSTEM_PROMPT },
          { role: 'user', content: userContent },
        ],
        // Load-bearing. OpenRouter's own docs say schema enforcement "differs
        // by provider" — some guarantee it, others treat the schema as a hint.
        // Without this, malformed JSON appears intermittently in production
        // while working perfectly in every test.
        provider: { require_parameters: true },
        response_format: {
          type: 'json_schema',
          json_schema: {
            name: 'nutrition_estimate',
            strict: true,
            schema: RESPONSE_SCHEMA,
          },
        },
        max_tokens: 1500,
        temperature: 0.2,
      }),
    });
  } catch (error) {
    console.error('upstream_fetch_failed', { model, message: error?.message });
    return { ok: false, reason: 'network' };
  }

  const text = await response.text();

  // Raw upstream logging, from the first commit. Truncated only because a
  // Worker log line has a size limit — the head is where the failures show.
  console.log('upstream_response', {
    model,
    status: response.status,
    body: text.slice(0, 2000),
  });

  if (!response.ok) return { ok: false, reason: `status_${response.status}` };

  let parsed;
  try {
    parsed = JSON.parse(text);
  } catch {
    return { ok: false, reason: 'upstream_not_json' };
  }

  const content = parsed?.choices?.[0]?.message?.content;
  if (typeof content !== 'string') return { ok: false, reason: 'no_content' };

  let payload;
  try {
    payload = JSON.parse(content);
  } catch {
    // The schema was not honoured. This is exactly the case require_parameters
    // is meant to prevent, so it is worth seeing in the logs rather than
    // silently falling back.
    console.error('schema_violation', { model, content: content.slice(0, 1000) });
    return { ok: false, reason: 'content_not_json' };
  }

  const items = sanitise(payload?.items);
  if (items.length === 0) return { ok: false, reason: 'no_items' };

  return { ok: true, items };
}

/**
 * Clamps the model's numbers into a range the app can render.
 *
 * The app validates again on its side. This exists so an obviously impossible
 * figure never reaches a screen where it would be shown next to a source badge
 * and look authoritative.
 */
function sanitise(items) {
  if (!Array.isArray(items)) return [];

  return items
    .filter((item) => item && typeof item.name === 'string' && item.name.trim())
    .slice(0, 12)
    .map((item) => {
      const grams = clamp(number(item.grams, 100), 1, 5000);
      return {
        name: item.name.trim().toLowerCase().slice(0, 120),
        portion_desc: String(item.portion_desc || '').slice(0, 80) || null,
        grams,
        // 9 kcal/g is pure fat, the physical ceiling for anything edible.
        kcal: clamp(number(item.kcal, 0), 0, grams * 9),
        protein_g: clamp(number(item.protein_g, 0), 0, grams),
        carbs_g: clamp(number(item.carbs_g, 0), 0, grams),
        fat_g: clamp(number(item.fat_g, 0), 0, grams),
        confidence: ['high', 'medium', 'low'].includes(item.confidence)
          ? item.confidence
          : 'low',
        confidence_reason:
          String(item.confidence_reason || '').slice(0, 160) ||
          'the model gave no reason',
      };
    });
}

function number(value, fallback) {
  const n = typeof value === 'number' ? value : Number(value);
  return Number.isFinite(n) ? n : fallback;
}

function clamp(value, min, max) {
  return Math.min(Math.max(value, min), max);
}

async function checkRateLimit(env, deviceId) {
  if (!env.KV) return null;

  const now = new Date();
  const day = now.toISOString().slice(0, 10);
  const hour = now.toISOString().slice(0, 13);

  const dayKey = `rl:d:${deviceId}:${day}`;
  const hourKey = `rl:h:${deviceId}:${hour}`;

  const [dayCount, hourCount] = await Promise.all([
    env.KV.get(dayKey).then((v) => Number(v) || 0),
    env.KV.get(hourKey).then((v) => Number(v) || 0),
  ]);

  const dailyLimit = Number(env.DAILY_LIMIT) || 50;
  const hourlyLimit = Number(env.HOURLY_LIMIT) || 15;

  if (dayCount >= dailyLimit || hourCount >= hourlyLimit) {
    console.warn('rate_limited', { deviceId, dayCount, hourCount });
    return json(
      {
        error: 'rate_limited',
        // The app turns this into "you have used today's photo estimates —
        // you can still add food by hand", which is true and actionable.
        message: 'Photo limit reached.',
        retry_after_seconds: dayCount >= dailyLimit ? secondsUntilTomorrow(now) : 3600,
      },
      429,
    );
  }

  // Counters are incremented optimistically. A concurrent pair of requests can
  // both read the same value and each write count+1, losing one increment —
  // acceptable here, where the limit is a cost guard rather than a security
  // boundary, and a strongly consistent counter would mean a Durable Object.
  await Promise.all([
    env.KV.put(dayKey, String(dayCount + 1), { expirationTtl: 60 * 60 * 48 }),
    env.KV.put(hourKey, String(hourCount + 1), { expirationTtl: 60 * 60 * 2 }),
  ]);

  return null;
}

function secondsUntilTomorrow(now) {
  const tomorrow = new Date(now);
  tomorrow.setUTCHours(24, 0, 0, 0);
  return Math.round((tomorrow - now) / 1000);
}

async function sha256(text) {
  const data = new TextEncoder().encode(text);
  const digest = await crypto.subtle.digest('SHA-256', data);
  return [...new Uint8Array(digest)]
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

function json(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json' },
  });
}

function cors(response) {
  const headers = new Headers(response.headers);
  headers.set('access-control-allow-origin', '*');
  headers.set('access-control-allow-headers', 'content-type,authorization,x-device-id');
  headers.set('access-control-allow-methods', 'POST,OPTIONS');
  return new Response(response.body, { status: response.status, headers });
}
