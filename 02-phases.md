# Build Phases

Ordering principle: **everything that can be blocked by an external service comes
last.** Phases 0–5 have no network dependency. If the AI work stalls, you still
have a complete, usable calorie tracker.

---

## Phase 0 — Data pipeline (desktop, no Flutter)

Build `foods.sqlite` on your machine. Nothing here runs on a phone.

**Tasks**
- Download USDA FoodData Central bulk CSVs and the INDB dataset
- Python script: read both → normalise → write SQLite
- Normalisation: lowercase, strip punctuation, collapse whitespace, singularise
  where trivial
- Create the FTS5 virtual table over `name`
- Record `source` per row so attribution survives into the app

**Done when**
Querying `roti`, `biryani`, `chicken breast`, `daal` from the CLI returns sane
ranked results with plausible macros. Verify a few rows by hand against the
source CSVs.

**Watch for**
- USDA CSVs are large and awkwardly normalised across several files — expect the
  join to take longer than you think
- Unit mismatches: INDB energy values may be kJ in places (IFCT 2017 used kJ).
  Convert, don't assume kcal.
- Duplicate foods across sources — decide a precedence rule and apply it once

**Output:** `assets/foods.sqlite`, committed. Keep the script in `tools/`.

---

## Phase 1 — Flutter skeleton

```
lib/
  core/        theme, constants, extensions
  data/        drift dbs, daos, repositories
  domain/      models, goal_engine
  features/
    onboarding/  home/  logging/  calendar/  settings/
```

**Tasks**
- Project init, dependencies, Android config
- Drift set up over two databases: bundled read-only `foods.sqlite`, writable
  `diary.sqlite`
- Copy the asset DB to app storage on first run
- Repository interfaces in `domain`, implementations in `data`
- Riverpod providers wired
- Theme and type scale from the UI doc

**Done when**
App boots and renders one hardcoded entry on a bare home screen.

---

## Phase 2 — Goal engine

Pure Dart. No I/O, no Flutter imports, lives in `domain/`.

**Tasks**
- Mifflin-St Jeor, activity factors, deficit maths
- The four safety rules, applied in order
- Macro split from the calorie target
- **Tests written before the UI**

**Required test cases**
| Case | Expected |
|---|---|
| Age 15 | Refuse onboarding |
| Lose 15kg in 30 days | Clamp to 1%/week, return honest date |
| Target BMI 16 | Refuse target, offer maintenance |
| Already underweight, wants to lose | Refuse |
| Aggressive but legal request | Clamp to calorie floor, extend date |
| Maintenance goal | Passes through cleanly |
| Gain goal | Passes through cleanly |

**Done when**
All refusal tests pass and onboarding screens feed the engine end to end.

This is the part of the repo most worth showing someone. Don't rush it.

---

## Phase 3 — Manual logging

No AI anywhere in this phase.

**Tasks**
- Search screen: query → FTS5 → ranked results
- Portion selector (serving units primary, grams secondary)
- Save to `entries` + `entry_items`, `source = db`
- Edit and delete existing items

**Done when**
You can log a full day of food by hand and the totals are correct.

**At the end of Phase 3 you have a working calorie tracker.** Everything after
this is enhancement. Protect this milestone.

---

## Phase 4 — Home & day view

**Tasks**
- Today's totals against target: calories primary, protein prominent, carbs and
  fat secondary
- Entries grouped by meal
- Over-target state in neutral colours — no red
- Empty state that invites the first log

---

## Phase 5 — Calendar

**Tasks**
- Month grid, one cell per day
- Cell tinted by outcome band (under / on target / over)
- Unlogged days render as *absent*, not as failure
- Tap a day → day detail
- Month navigation

Cheap to build, high impact in a demo. This is the screen that shows patterns
the user can't see in a daily view.

---

## Phase 6 — Photo path

First network dependency. Expect this to overrun.

**6a — Worker, tested outside the app**
- Cloudflare Worker with the API key in env
- Strict JSON schema output
- Prompt includes the preparation-fat instruction
- Per-device rate limit, image-hash cache
- **Raw upstream response logging from the first commit**
- Verify with `curl` before Flutter touches it

**6b — Flutter integration**
- Camera / gallery capture
- Optional details field — collapsed by default, must be skippable without a tap
- Proposed card: editable rows, confidence surfaced, add-item row
- Save with `source = ai`; write accepted values to `food_cache`
- Cache hit path skips the API call entirely

**Watch for**
- Dead model slugs (Whispr hit 404s on deprecated ones — verify current)
- Provider billing gates on multimodal requests
- Catch blocks swallowing real errors
- Large base64 payloads — compress before upload

---

## Phase 7 — Polish

- Sources screen (satisfies CC BY attribution)
- Error and empty states with real copy
- Onboarding re-entry / goal editing
- README, screenshots, demo video
- Licence file and third-party attributions

---

## v2 candidates

Not now. Written down so they stop competing for attention.

- Adaptive TDEE from observed weight trend vs. logged intake
- Weekly rolling budget instead of daily
- Barcode scanning (Open Food Facts)
- Export to CSV
- iOS

---

## Realistic sequencing note

Phase 0 is genuinely a few days of unglamorous data work, and it's tempting to
skip ahead to the camera. Don't. Every later phase reads from that database, and
fixing a bad schema after Phase 4 means touching every screen.

---

## Build status

All phases are implemented. 159 tests passing, `flutter analyze` clean, release
APK builds.

| Phase | State | Notes |
|---|---|---|
| 0 toolchain, rename, Android | done | INTERNET verified in the *release* manifest |
| 0b food database | done | 11,889 foods, 34,781 portions, 3.3 MB, USDA only |
| 1 skeleton, tokens, widgets | done | |
| 2 goal engine | done | 44 unit tests |
| 2b onboarding | done | 13 widget tests over the safety rules |
| 3 manual logging | done | 26 tests against the real shipped database |
| 4 home / day view | done | |
| 5 calendar | done | |
| 6 photo path + Worker | code complete | **Worker not yet deployed — see below** |
| 7 goal editing, sources, a11y | done | 9 accessibility checks |

### What still needs a human

1. **Deploy the Worker.** `worker/README.md` has the steps. Until then the
   photo options are simply not offered and manual logging is unaffected — a
   build without `CALORI_WORKER_URL` is valid and complete.
2. **`curl` the Worker before trusting it**, per 6a. A provider quietly
   ignoring the JSON schema is visible in `wrangler tail` and nowhere else.
3. **Run the app on a device.** Every screen is covered by tests, but no test
   judges whether the date strip centres nicely or the ring sweep feels right.
4. **The remaining six food sources** (CoFID, CIQUAL, CNF, Frida, INDB,
   Pakistan FCT). Each is one file in `tools/build_foods_db/sources/`; the
   merge ships with whatever is ready.

### Bugs the tests caught that review would not have

- `@riverpod` is auto-dispose by default in Riverpod 3, so the onboarding draft
  was discarded as each step unmounted — the flow still advanced, reaching the
  final screen with an empty draft and no error.
- Ten of fourteen text tokens carried no colour. Flutter's fallback is **white**,
  so most body text would have rendered invisibly on the near-white background.
  `find.text()` does not check colour, so only a contrast guideline caught it.
- FNDDS uses legacy SR nutrient numbering in a column named `nutrient_id`,
  which parsed to zero records rather than erroring.
- The first validator rejected lard, vodka and whole turkeys as implausible.
