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

---

## Deploying from the dashboard (no command line)

Everything below is done at **dash.cloudflare.com**. You need a free Cloudflare
account and an [OpenRouter](https://openrouter.ai/) API key.

### 1. Create the KV namespace first

KV is where the rate-limit counters and the image cache live. Creating it first
means it is available to pick from a dropdown later.

1. In the sidebar, open **Storage & Databases → KV**.
2. Select **Create instance**.
3. Name it `CALORI_KV`.
4. Select **Create**.

### 2. Create the Worker

1. In the sidebar, open **Compute (Workers) → Workers & Pages**.
2. Select **Create application → Start with Hello World!** and give it a name —
   `calori-worker` is what the rest of this document assumes.
3. Select **Deploy**. It deploys a placeholder; that is expected.

### 3. Paste the code

1. On the Worker's page, select **Edit code** (the `< >` icon). This opens the
   in-browser VS Code editor.
2. Select everything in `worker.js` and delete it.
3. Open [`src/index.js`](src/index.js) from this repo, copy the whole file, and
   paste it in.
4. Select **Deploy**.

The file is a single ES module with no imports and no build step, which is why
it can be pasted in whole. Do not add a bundler.

### 4. Add the secrets

1. Back on the Worker's page, go to **Settings → Variables and Secrets**.
2. Select **Add**, and add these two with **Type: Secret**:

   | Variable name | Value |
   |---|---|
   | `OPENROUTER_API_KEY` | your OpenRouter key (`sk-or-v1-…`) |
   | `APP_SHARED_SECRET` | any long random string you invent |

   `APP_SHARED_SECRET` is not from anywhere — you make it up, and it goes into
   the app build in step 7. It stops strangers who find the URL from spending
   your API credit. A password manager's "generate password" is ideal.

3. Optionally add these with **Type: Text** to override the defaults:

   | Variable name | Default if unset |
   |---|---|
   | `MODEL` | `google/gemini-2.5-flash` |
   | `FALLBACK_MODEL` | `google/gemini-2.5-flash-lite` |
   | `DAILY_LIMIT` | `50` |
   | `HOURLY_LIMIT` | `15` |

   Use **Secret** for the two keys and **Text** for these. The difference is
   that a secret cannot be read back afterwards, in the dashboard or anywhere
   else — which is exactly what you want for a key and unhelpful for a model
   slug you may want to check.

4. Select **Deploy**.

### 5. Bind the KV namespace

1. On the Worker's page, open the **Bindings** tab.
2. Select **Add binding → KV namespace**.
3. **Variable name:** `KV` — exactly this. The code reads `env.KV`, so a
   different name silently disables the cache and the rate limit rather than
   erroring.
4. **KV namespace:** pick `CALORI_KV`.
5. Select **Add binding**, then **Deploy**.

### 6. Check it worked

Your Worker's URL is on its overview page, shaped like
`https://calori-worker.<your-subdomain>.workers.dev`.

Open **`https://calori-worker.<your-subdomain>.workers.dev/health`** in a
browser. You should see:

```json
{ "ok": true, "model": "google/gemini-2.5-flash", "kv": true,
  "auth_required": true, "key_present": true }
```

All four flags matter:

- `kv: false` → step 5 was missed or the variable name is not exactly `KV`.
- `key_present: false` → step 4's `OPENROUTER_API_KEY` did not save.
- `auth_required: false` → no `APP_SHARED_SECRET`; the Worker is open to anyone
  who finds the URL.

### 7. Build the app against it

The endpoint and the shared secret are compile-time constants, and are
deliberately not committed:

```bash
flutter build apk --release \
  --dart-define=CALORI_WORKER_URL=https://calori-worker.<your-subdomain>.workers.dev/analyze \
  --dart-define=CALORI_WORKER_SECRET=<the APP_SHARED_SECRET you invented>
```

Note the `/analyze` on the end of the URL — `/health` is only for the check
above.

**A build without these is valid and fully functional.** The camera options are
simply not offered, and manual logging — the path that always works — is
unaffected.

### 8. Watch it run

Before trusting an estimate, watch one real request go through. On the Worker's
page open the **Logs** tab and select **Begin log stream**, then take a photo in
the app.

This is where a provider quietly ignoring the JSON schema becomes visible, and
it is visible nowhere else. Look for:

- `upstream_response` — the raw reply, truncated. This is the ground truth.
- `schema_violation` — the model returned prose instead of the object. If this
  appears at all, see the note on `require_parameters` below.
- `rate_limited`, `missing_api_key`, `cache_hit` — self-explanatory.

---

## Deploying from the command line

Equivalent to the above, if you prefer it:

```bash
cd worker
npm install

npx wrangler kv namespace create CALORI_KV
# paste the printed id into wrangler.toml

npx wrangler secret put OPENROUTER_API_KEY
npx wrangler secret put APP_SHARED_SECRET

npx wrangler deploy
npx wrangler tail --format pretty
```

`wrangler.toml` sets the same variables the dashboard's **Variables and
Secrets** panel does. If you deployed through the dashboard, that file is not
consulted — the dashboard values are the live ones.

### Testing with a real photo

```bash
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

---

## Things that will bite

- **`provider: { require_parameters: true }` is load-bearing.** OpenRouter's
  own docs say schema enforcement *"differs by provider"*: some guarantee
  compliance, others treat the schema as a strong hint. Without the flag you
  get malformed JSON intermittently in production while every test passes.

- **The preparation-fat instruction is not decoration.** Models estimate from
  what is visible, and absorbed oil and ghee are not. Remove that line and
  oil-forward cuisines come back 30–40% light — consistently, which is worse
  than a random error because it never looks wrong.

- **Rate-limit counters are optimistic.** Two concurrent requests can each read
  the same count and write `count + 1`, losing one increment. Acceptable here:
  the limit is a cost guard, not a security boundary. Making it exact means a
  Durable Object.

- **Log raw upstream responses.** On Whispr a catch block turned server errors
  into UI messages and hid the real failure for weeks. The `upstream_response`
  and `schema_violation` lines exist for that reason; do not quiet them.

- **Changing the model is a variable, not a deploy.** Edit `MODEL` under
  **Variables and Secrets** and press Deploy. No app update, no code change.
  That is the whole reason this Worker exists.
