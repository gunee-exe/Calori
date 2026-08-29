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
