# Calori

An honest calorie and macro tracker for Android. Photo estimates you can edit,
backed by an offline food database that works with no account and no network.

- **21,791 foods and 52,193 household portions** bundled in the APK, merged from
  eight public food-composition databases with per-row provenance.
- **Manual logging works offline**, immediately, with no setup at all.
- **Photo estimates are optional** and run through a Cloudflare Worker you
  deploy yourself, using your own API key. See
  [Photo estimates](#photo-estimates-optional).

Calori estimates. It does not diagnose, treat, or replace advice from a doctor
or dietitian.

---

## What it looks like

<p align="center">
  <img src="Ui/Screenshot%202026-08-28%20180542.png" alt="Today" width="19%">
  <img src="Ui/Screenshot%202026-08-28%20180659.png" alt="Capture" width="19%">
  <img src="Ui/Screenshot%202026-08-28%20180719.png" alt="Add food" width="19%">
  <img src="Ui/Screenshot%202026-08-28%20180614.png" alt="Calendar" width="19%">
  <img src="Ui/Screenshot%202026-08-28%20180628.png" alt="Goal" width="19%">
</p>

<p align="center"><em>Today &middot; Capture &middot; Add food &middot; Calendar &middot; Goal</em></p>

The palette, spacing and motion come from
[`Ui/Calorie Tracker v3 - Bright Blue.dc.html`](Ui/Calorie%20Tracker%20v3%20-%20Bright%20Blue.dc.html),
the clickable prototype that is the visual source of truth, transcribed literally
into [`lib/core/theme/tokens.dart`](lib/core/theme/tokens.dart). One rule governs
the whole scheme: **there is no red.** Going over budget is information, not
failure, so over-target is a desaturated grey-blue.

---

## What it does

- **Onboarding that can say no.** The goal engine refuses targets below a
  healthy BMI and caps weight change at 1% of bodyweight per week, explaining
  what it changed and why rather than silently correcting you.
- **A daily target you can overrule.** Calories and protein are computed from
  Mifflin-St Jeor, and both can be set by hand. Calori still shows what it would
  have suggested, and says so once if your figure is below the safety floor —
  then gets out of the way.
- **Search that speaks more than English.** Regional foods carry their local
  name, so *channa*, *masur* and *karela* find the same rows as *chickpea*,
  *lentil* and *bitter gourd*.
- **Photo logging that admits when it can't help.** An empty plate, a hand or a
  pet returns "no food in that photo" rather than a confident wrong number.
- **Metric or imperial, separately.** Height in feet and weight in kilos is a
  perfectly ordinary combination, so they are two choices, not one.

---

## Build it

You need the [Flutter SDK](https://docs.flutter.dev/get-started/install)
(Dart `^3.13.0`) and an Android device or emulator running **Android 7.0
(API 24)** or newer.

```bash
git clone <this repo>
cd caltracker
flutter pub get
flutter build apk --release
```

The APK lands in `build/app/outputs/flutter-apk/app-release.apk`. To run it on
a connected device instead, `flutter run --release`.

**That build is a complete, working app.** Onboarding, the goal engine, manual
logging against the full food database, the calendar and the day view all work
with no configuration, no account, no network and no API key. The only thing
missing is photo estimates.

To run the checks:

```bash
flutter analyze && flutter test
```

---

## Photo estimates (optional)

### What it does, and what it costs

You photograph a meal; the app sends it to **a Cloudflare Worker you own**,
which calls a vision model through [OpenRouter](https://openrouter.ai/) using
**your** API key and returns a list of foods with estimated portions and macros.
Nothing is logged until you confirm it, and every number stays editable.

The Worker exists so the API key, the rate limit, the image cache and the model
choice live somewhere other than the APK. Cloudflare's free tier is far more
than this needs. **OpenRouter charges per image** — that is the whole reason
this is off by default rather than simply missing.

### What you need first

- A free [Cloudflare](https://dash.cloudflare.com/) account.
- An [OpenRouter](https://openrouter.ai/) API key with some credit on it.
  Worth setting a spend limit on the key while you are there.

### 1. Deploy the Worker

The full click-by-click walkthrough is **[`worker/README.md`](worker/README.md)**
— it covers the Cloudflare dashboard (no command line needed), the Wrangler CLI
alternative, how to test with a real photo, and a "Things that will bite"
section. Follow that; the shape of it is:

1. Create a **KV namespace** called `CALORI_KV` (rate-limit counters and the
   image cache).
2. Create a **Worker** called `calori-worker`.
3. Paste [`worker/src/index.js`](worker/src/index.js) in whole and deploy. It is
   a single ES module with no imports and no build step.
4. Add two **secrets**: `OPENROUTER_API_KEY` (your OpenRouter key) and
   `APP_SHARED_SECRET` (any long random string you invent).
5. **Bind** the KV namespace to the Worker with the variable name `KV`.

### 2. Point the app at your Worker

Copy the example config and fill in **the copy**:

```bash
cp worker-config.example.json worker-config.json
```

> Edit `worker-config.json`, never `worker-config.example.json`. The example is
> tracked by git; the copy is gitignored, which is what keeps your secret out of
> the repository.

```json
{
  "CALORI_WORKER_URL": "https://calori-worker.YOUR-SUBDOMAIN.workers.dev/analyze",
  "CALORI_WORKER_SECRET": "the same APP_SHARED_SECRET you set in step 4"
}
```

`CALORI_WORKER_SECRET` must match the Worker's `APP_SHARED_SECRET` exactly, and
the URL must end in `/analyze`. Then rebuild with the config:

```bash
flutter build apk --release --dart-define-from-file=worker-config.json
```

### 3. Check it worked

The Worker reports its own configuration, so a bad deploy is one command away
from being obvious:

```bash
curl https://calori-worker.YOUR-SUBDOMAIN.workers.dev/health
```

```json
{"ok":true,"model":"google/gemini-2.5-flash","kv":true,"auth_required":true,"key_present":true}
```

All four of `ok`, `kv`, `auth_required` and `key_present` should be true. If
`key_present` is false you skipped the secret; if `kv` is false you created the
namespace but did not bind it.

In the app, the camera button in the centre of the navigation bar should now
open a viewfinder. Take a photo, add details if you want to, then press **Send**
— nothing is uploaded until you do.

### If the camera says photo estimates are not set up

That build had no `--dart-define-from-file=worker-config.json`. It is the
expected state of a plain `flutter build apk`, not a bug — the app declines up
front rather than sending a request that is certain to be rejected. Rebuild with
the flag.

---

## Where the food data comes from

Eight public databases, merged with strict provenance and deduplicated by
regional specificity. Every row keeps the source it came from, and the app shows
it on each search result and on its Sources screen.

| Source | Region | Foods |
|---|---|---:|
| USDA FoodData Central — SR Legacy | US | 6,312 |
| USDA FoodData Central — FNDDS | US | 5,268 |
| Canadian Nutrient File | Canada | 3,828 |
| CoFID (McCance & Widdowson's) | UK | 2,607 |
| CIQUAL (ANSES) | France | 2,291 |
| Indian Nutrient Databank | India | 1,014 |
| USDA FoodData Central — Foundation | US | 296 |
| Food Composition Table for Pakistan | Pakistan | 175 |

Per-source licences, attribution strings and URLs are in
**[`DATA-LICENSES.md`](DATA-LICENSES.md)**, and the attributions those licences
require are shown in-app on the Sources screen.

> **One caveat before you redistribute a build.** Seven of the eight are
> explicitly redistributable. The Pakistan table is FAO-hosted and its reuse
> terms are **not yet confirmed** — see the note in `DATA-LICENSES.md`. To drop
> it, remove `PAKISTAN` from `SOURCES` in `tools/build_foods_db/build.py` and
> rebuild.

`assets/db/foods.sqlite` is committed, so you do **not** need to build it.
`tools/build_foods_db/` only needs running if you want to change the sources:

```bash
python tools/build_foods_db/build.py
```

It is stdlib-only Python — no pandas, no third-party parsers. Two sources cannot
be downloaded automatically and print instructions instead of failing: the
Canadian archive, and the Pakistan table, which is published only as a scan and
needs a transcribed spreadsheet. If you rebuild with a changed source set, bump
`BUILD_VERSION` in `tools/build_foods_db/manifest.py` **and**
`kFoodsAssetVersion` in `lib/data/foods/foods_db.dart` together — the second is
carried in the on-disk filename and is what makes an existing install pick the
new database up.

---

## How it is put together

The design documents carry the reasoning, and are worth reading before changing
anything structural:

- [`01-concept.md`](01-concept.md) — what the app is, and what it refuses to do
- [`02-phases.md`](02-phases.md) — build phases and status
- [`03-food-data.md`](03-food-data.md) — the merge, the schema, the licensing split
- [`04-use-cases.md`](04-use-cases.md) — the twelve use cases, as flows
- [`05-build-plan.md`](05-build-plan.md) — toolchain and platform decisions

Two databases, deliberately separate: `foods.sqlite` ships read-only in the APK
with an FTS5 index, and `diary.sqlite` is written on device and is the only one
enrolled in Android backup. Neither is ever attached to the other.

---

## Licence

The **food data** carries its own licences and attribution requirements — see
[`DATA-LICENSES.md`](DATA-LICENSES.md), and the caveat above.

No licence is declared for the application code yet, which by default means all
rights reserved. If you intend others to reuse this, add a `LICENSE` file.
