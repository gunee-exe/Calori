# Calorie Tracker — Concept & Specification

> **Working name: TBD.** The app is unnamed. Pick one before Phase 1 — it affects
> package name, theming, and the repo, and renaming later is annoying.

---

## 1. What this is

An Android calorie and macro tracker built around AI photo logging, with a manual
database-backed path as the fallback. Personal/portfolio project, solo build.

**Principle:** *simplicity means only the necessary steps — not fewer steps.*
The app doesn't remove control to look clean. It removes anything that isn't
load-bearing.

**Personality:** honest about what it doesn't know. Every AI estimate is a
proposal the user can edit, never a verdict.

---

## 2. Why the honesty angle is grounded

An NIH/NIDDK team tested four photo-based trackers (MyFitnessPal, LoseIt!, CalAI,
Appediet) against 102 meals prepared in a metabolic kitchen and measured to 0.1g.
All four underestimated by roughly 250–345 kcal per meal, and underestimated fat
by around 30g. Presented at NUTRITION 2026; **preliminary, not yet peer-reviewed.**

Two design consequences:

1. The error is systematic and runs *low*. Users think they have budget left when
   they don't, fail to progress, and blame themselves.
2. The miss concentrates in **fat** — cooking oil, ghee, butter, frying. Invisible
   in a photo. For desi food this is enormous; a karahi's oil can be a large share
   of its calories.

So the vision prompt explicitly instructs the model to account for preparation fat.
That's a targeted fix, not a fudge constant.

---

## 3. Scope

**In:**
- Onboarding + goal engine with hard safety constraints
- Photo logging → editable proposed card
- Optional pre-photo details field (name / portion, if the user knows it)
- Manual logging from a bundled food database
- Four macros: calories, protein, carbs, fat
- Calendar view of days
- Local-only storage

**Out (deliberately):**
- Accounts, login, cloud sync
- Barcode scanning
- Recipe builder, meal planning
- Exercise logging
- Streaks, badges, social feed
- Micronutrients, fiber, sugar, sodium
- Adaptive TDEE (v2 candidate)
- iOS (needs a Mac)

Every "out" item is something a competitor has that makes it worse.

---

## 4. Goal engine

```
BMR   = 10×kg + 6.25×cm − 5×age + (male ? 5 : −161)     [Mifflin-St Jeor]
TDEE  = BMR × activity_factor    (1.2 / 1.375 / 1.55 / 1.725 / 1.9)
rate  = (weight − target_weight) / weeks_requested
```

### Safety constraints — enforced in the domain layer

Applied in order:

1. **Age < 18** → refuse onboarding. Point to a doctor or guardian. No bypass path.
2. **Target BMI < 18.5**, or current BMI < 18.5 with a loss goal → refuse the
   target, offer maintenance instead.
3. **Clamp rate to 1% bodyweight/week.** If the requested timeframe needs more,
   don't fail silently — show the honest achievable date and why.
4. `deficit_per_day = rate × 7700 / 7`
5. `target = TDEE − deficit`, **clamped** to 1500 kcal (male) / 1200 kcal (female).
   If the clamp bites, extend the date.

Gaining and maintaining are first-class goals. Not a loss-only app.

### Numbers to verify before defending these

- **7700 kcal/kg** is a rule of thumb that overestimates loss over long horizons
  (metabolic adaptation). Fine for 6–12 week goals, wrong for a year.
- **1500/1200 floors** are widely repeated in consumer health guidance but should
  be traced to an authoritative source before being cited in a viva.

### Tone rules

- No streaks that break. No badges. No "you failed today."
- **No red anywhere for over-target.** Neutral colours only.
- Weight is never the sole progress metric.
- No body-shape imagery, no before/after, no "ideal body" language.
- If intake logs run implausibly low for several consecutive days, stop nudging
  toward the target and surface a quiet, non-clinical suggestion to check in with
  a professional. Do not gamify the user back on track.

---

## 5. Two logging paths

Deliberately separate. Each does what it's actually good at.

### Photo path (AI provides macros)

1. User optionally types details — name, portion — before shooting.
   *Must be skippable without a tap.* This is grounding data: it hands the model
   the scale information it cannot infer from pixels.
2. Photo + optional details → Cloudflare Worker → Gemini 2.5 Flash.
3. Strict JSON schema out.
4. Editable proposed card. Nothing is logged until the user confirms.

### Manual path (database provides macros)

1. Search box → FTS5 query over bundled SQLite → ranked results.
2. User picks the entry and a portion.
3. Log.

Used when the user forgot to photograph the meal, is logging retroactively, or
already knows exactly what they ate.

**Why not force photos through the database:** INDB has ~1,000 recipes; a photo
can be anything. Most matches would fail, and worse, bad matches would *succeed*
silently — "chicken karahi" fuzzy-matching to "chicken curry" and returning
confident wrong numbers wearing an authoritative source label. That's a worse
failure than an honest estimate. Fuzzy matching belongs where a human picks from
ranked results and can reject a bad one.

### Consistency between the two paths

Same food logged two ways gives two numbers, and that reads as a bug.

Fix: a **food cache**. When the user accepts an AI result, store
`normalised_name → per-100g values`. Next time that name comes back, reuse the
cached values. The app converges toward per-user consistency, repeat meals skip
the API call, and every entry is tagged with its source.

---

## 6. Data sources

| Source | Licence | Obligation | Use for |
|---|---|---|---|
| **USDA FoodData Central** | CC0 | None | Generic foods, raw ingredients |
| **INDB** (Indian Nutrient Databank) | CC BY | Attribution | Desi recipes — biryani, daal, karahi |
| Open Food Facts | ODbL | Share-alike on derived DBs | Packaged goods (not in v1) |

Start with USDA + INDB. Both are clean.

**INDB:** ~1,095 raw food items plus ~1,014 commonly consumed recipes, built
mainly from ICMR-NIN's Indian Food Composition Table 2017. Values per 100g and per
serving. Recipes as entries, not just ingredients — this is the one that makes
desi food work.

Attribution goes in the README *and* an in-app Sources screen.

**Reference reading (not code to copy):** OpenNutriTracker is a Flutter calorie
tracker under GPL v3 — read its architecture, don't paste from it. Its separate
backend repo is the more useful half: someone else's solution to the same import
problem.

Ignore the "500K foods, 99.2% accurate" datasets published by calorie-app
companies. Self-reported accuracy, no methodology.

---

## 7. Stack

| Layer | Choice | Why |
|---|---|---|
| Client | Flutter | Known stack |
| State | Riverpod | Known stack |
| Storage | Drift (SQLite) | Bundled food DB is SQLite; one engine, not two |
| AI proxy | Cloudflare Worker | Keeps keys off-device; pattern reused from Whispr |
| Model | Gemini 2.5 Flash via OpenRouter | Multimodal, cheap, fallback flexibility |
| Platform | Android | iOS needs a Mac |

---

## 8. Data model

**`foods.sqlite`** — bundled read-only asset, built once by a Python script.

```
foods(id, name, name_normalised, source,
      serving_desc, serving_grams,
      kcal_100g, protein_100g, carbs_100g, fat_100g)
foods_fts  -- FTS5 virtual table over name
```

**`diary.sqlite`** — writable on device.

```
profile(id, sex, age, height_cm, weight_kg, target_weight_kg,
        activity_factor, target_date, daily_kcal, daily_protein_g,
        daily_carbs_g, daily_fat_g)

entries(id, date, logged_at, meal_type, photo_path, source, note)

entry_items(id, entry_id, name, portion_desc, grams,
            kcal, protein_g, carbs_g, fat_g,
            confidence, confidence_reason, source, food_id?)

food_cache(name_normalised, kcal_100g, protein_100g,
           carbs_100g, fat_100g, last_used_at)
```

`source` on every item: `ai` | `db` | `cache` | `manual`. That's what makes the
Sources screen possible.

---

## 9. Worker contract

**Request**
```json
{
  "image_base64": "...",
  "user_hint": "one plate, roughly 300g"   // optional, may be null
}
```

**Response**
```json
{
  "items": [{
    "name": "chicken biryani",
    "portion_desc": "1 plate",
    "grams": 300,
    "kcal": 620, "protein_g": 28, "carbs_g": 72, "fat_g": 24,
    "confidence": "high|medium|low",
    "confidence_reason": "no reference object in frame"
  }]
}
```

Schema-constrained output. Never regex-parse prose.

**Worker responsibilities:** hold the API key, rate-limit per device, cache by
image hash, handle model fallback, **log raw upstream responses.**

> On Whispr, a Flutter catch block turned server errors into UI messages and hid
> the real failure for weeks. Log raw responses from the first commit.

---

## 10. Open decisions

- [ ] App name
- [ ] Exact Gemini model slug (verify current — Whispr hit 404s on dead slugs)
- [ ] Verify the calorie-floor source
- [ ] Confirm which Hive/Drift package versions are current on pub.dev
- [ ] Whether Sources screen ships in v1 or v2
