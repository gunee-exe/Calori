# Calori Worker

The photo path's server side. It exists so four things live somewhere the user
does not control:

- **the API key** — never in the APK, where anyone can extract it;
- **the rate limit** — per install, so a leaked build cannot run up a bill;
- **the image-hash cache** — an identical photo returns identical numbers;
- **the model choice** — swapping providers is a change here and nowhere else,
  with no app update.

That last point is the reason to keep this even though it looks like
indirection.

## Deploying

```bash
cd worker
npm install

# One-time: create the KV namespace and paste the id into wrangler.toml
npx wrangler kv namespace create CALORI_KV

# Secrets — never in wrangler.toml
npx wrangler secret put OPENROUTER_API_KEY
npx wrangler secret put APP_SHARED_SECRET   # any long random string

npx wrangler deploy
```

## Verify it before Flutter touches it

`05-build-plan.md` 6a is explicit that the Worker is proven with `curl` first.
A schema violation found here is ten minutes; found through the app it is an
afternoon of wondering which layer is lying.

```bash
# Health
curl https://calori-worker.<subdomain>.workers.dev/health

# A real photo
BASE64=$(base64 -w0 lunch.jpg)
curl -X POST https://calori-worker.<subdomain>.workers.dev/analyze \
  -H 'content-type: application/json' \
  -H 'authorization: Bearer <APP_SHARED_SECRET>' \
  -H 'x-device-id: curl-test' \
  -d "{\"image_base64\":\"$BASE64\"}" | jq
```

Expected:

```json
{ "items": [ { "name": "chicken biryani", "portion_desc": "1 plate",
               "grams": 300, "kcal": 620, "protein_g": 28, "carbs_g": 72,
               "fat_g": 24, "confidence": "high",
               "confidence_reason": "clear plate, fork gives scale" } ] }
```

Watch the raw upstream responses while testing — this is where a provider
quietly ignoring the JSON schema becomes visible:

```bash
npx wrangler tail --format pretty
```

## Building the app against it

The endpoint and secret are compile-time constants, not committed:

```bash
flutter build apk --release \
  --dart-define=CALORI_WORKER_URL=https://calori-worker.<subdomain>.workers.dev/analyze \
  --dart-define=CALORI_WORKER_SECRET=<APP_SHARED_SECRET>
```

**A build without these is valid and fully functional.** The camera options
are simply not offered, and manual logging — which is the path that always
works — is unaffected.

## Things that will bite

- **`provider: { require_parameters: true }` is load-bearing.** OpenRouter's
  own docs say schema enforcement *"differs by provider"*: some guarantee
  compliance, others treat the schema as a strong hint. Without the flag you
  get malformed JSON intermittently in production while every test passes.

- **The preparation-fat instruction is not decoration.** Models estimate from
  what is visible, and absorbed oil and ghee are not. Remove that line and
  oil-forward cuisines come back 30–40% light, consistently — which is worse
  than a random error because it never looks wrong.

- **Rate-limit counters are optimistic.** Two concurrent requests can each read
  the same count and write `count + 1`, losing one increment. Acceptable here:
  the limit is a cost guard, not a security boundary. Making it exact means a
  Durable Object.

- **Log raw upstream responses.** On Whispr a catch block turned server errors
  into UI messages and hid the real failure for weeks. The `upstream_response`
  and `schema_violation` lines exist for that reason; do not quiet them.
