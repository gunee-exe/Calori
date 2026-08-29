# Build Plan — Calori

> The executable plan. [02-phases.md](02-phases.md) sets the ordering principle; this document
> is the concrete version, with the decisions resolved and the research done.
> Food data lives in [03-food-data.md](03-food-data.md).

---

## Decisions

| Decision | Choice |
|---|---|
| App name | **Calori** |
| Application ID | `com.usmanghani.calori` |
| Toolchain | Upgrade to **Flutter 3.44+** before writing code |
| Codegen | Full: `drift_dev` + `riverpod_generator` + `freezed` via one `build_runner watch` |
| Food data | Multi-source, global — [03-food-data.md](03-food-data.md) |
| Repo | **Public** — portfolio piece |
| Onboarding | Full multi-step flow on real screens |

Because the repo is public and this is a finished product rather than a demo, three things
[02-phases.md](02-phases.md) defers to Phase 7 move earlier: the **Sources screen ships in v1**
(it substantiates the honesty claim and discharges the attribution obligations), `DATA-LICENSES.md`
is written **during Phase 0**, and every food source sits behind a swappable adapter.

### Research findings that changed the plan

1. **The current toolchain cannot resolve the intended stack.** Flutter 3.32.7 / Dart 3.8.1 caps
   drift at 2.31 and Riverpod at 3.3.2, and forces the deprecated `sqlite3_flutter_libs`
   (`0.6.0+eol`). Nothing is built yet, so upgrading first is free.
2. **Four spec assumptions are wrong.** Drift has no asset-seeding helper. FTS5 must be declared
   in `.drift` files with an explicit `build.yaml` module. `image_picker` — not SQLite — sets the
   minSdk floor. And the main `AndroidManifest.xml` is missing `INTERNET`, which fails *only in
   release builds*.

---

## Phase 0 — Toolchain and project reset

Do this first; every later phase assumes it.

1. `flutter upgrade` to 3.44+ (verify `flutter --version` reports Dart ≥ 3.12).
2. `git init` and commit the scaffold as-is, so the reset is reviewable.
3. Delete the counter template in `lib/main.dart` and the stock `test/widget_test.dart` (it
   breaks the moment `MyApp` is replaced).
4. Rename off `com.example.*`:
   - `android/app/build.gradle.kts` — `namespace` and `applicationId` → `com.usmanghani.calori`;
     `minSdk = 24` (hard floor from `image_picker`, ~99.5 % device coverage).
   - Move `android/app/src/main/kotlin/com/example/caltracker/MainActivity.kt` to
     `com/usmanghani/calori/` and update its `package` line.
   - `android/app/src/main/AndroidManifest.xml` — `android:label="Calori"`, and **add
     `<uses-permission android:name="android.permission.INTERNET"/>`**. It currently exists only
     in the debug and profile manifests, so a release build has no network at all.
   - `pubspec.yaml` — `name: calori`, real description.
5. `android/gradle.properties` — delete `android.enableJetifier=true`. Nothing in this stack
   needs Jetifier and it slows every build.
6. `.gitignore` — add what the template omits: `android/local.properties` (currently tracked, and
   it contains machine-specific paths), `android/key.properties`, `*.jks`, `*.keystore`.
7. Create `build.yaml`. **Without this, `drift_dev` rejects `CREATE VIRTUAL TABLE ... USING fts5`
   at codegen time:**
   ```yaml
   targets:
     $default:
       builders:
         drift_dev:
           options:
             sqlite: { version: "3.45", modules: [fts5] }
   ```
8. `analysis_options.yaml` — add an `analyzer.exclude` for `**/*.g.dart`, `**/*.freezed.dart`,
   `**/*.drift.dart`.

**Done when:** `flutter run` shows a blank themed screen under the new package name, and
`flutter build apk --release` succeeds.

### Dependencies

```yaml
dependencies:
  flutter_riverpod: ^3.4.2        # annotation/generator are 4.x — not a typo
  riverpod_annotation: ^4.0.6
  drift: ^2.34.3
  drift_flutter: ^0.3.1
  sqlite3: ^3.5.2                 # self-bundles SQLite via Dart build hooks; no NDK, no plugin
  path_provider: ^2.1.6
  path: ^1.9.1
  freezed_annotation: ^3.x
  json_annotation: ^4.x
  image_picker: ^1.2.3
  camera: ^0.12.0+2
  flutter_image_compress: ^2.x
  http: ^1.x
  intl: ^0.20.x
  google_fonts: ^6.x              # Poppins; or bundle the TTFs to keep it offline

dev_dependencies:
  build_runner, drift_dev, riverpod_generator, freezed, json_serializable,
  custom_lint, riverpod_lint, flutter_lints
```

> Do **not** add `sqlite3_flutter_libs` — it is deprecated (`0.6.0+eol`). From `sqlite3` 3.x,
> SQLite is bundled automatically and the prebuilt binaries ship with `SQLITE_ENABLE_FTS5`.
> Never point it at system SQLite (`source: system`); that reintroduces exactly the FTS5 roulette
> on older Android that [01-concept.md](01-concept.md) worries about.

---

## Phase 0b — Food database

Desktop Python work, no Flutter. Full spec in [03-food-data.md](03-food-data.md).
Output: `assets/db/foods.sqlite` (committed), the builder in `tools/build_foods_db/`, and
`DATA-LICENSES.md`.

Run this **in parallel with Phases 1–2**, not before them. It is the long pole — dataset
downloads are slow and the dedup pass needs a human review round — but Phases 1 and 2 don't
depend on real data: the skeleton needs only a schema, and the goal engine touches no food data
at all. Phase 3 is the first phase that genuinely blocks on it.

---

## Phase 1 — Skeleton, theme, data layer

### Structure

```
lib/
  core/
    theme/        tokens.dart, app_theme.dart, motion.dart
    widgets/      calori_card.dart, pill_button.dart, section_label.dart,
                  stepper_row.dart, progress_ring.dart, shimmer_box.dart
    format.dart   number/date formatting (tabular figures)
  data/
    foods/        foods_db.dart, foods.drift, foods_dao.dart
    diary/        diary_db.dart, tables.dart, entries_dao.dart, profile_dao.dart,
                  food_cache_dao.dart
    remote/       analysis_client.dart  (Phase 6)
    repositories/ food_repository_impl.dart, diary_repository_impl.dart
  domain/
    models/       profile.dart, entry.dart, entry_item.dart, food.dart, goal_result.dart
    goal_engine.dart
    repositories/ food_repository.dart, diary_repository.dart   (interfaces)
  features/
    onboarding/ home/ logging/ search/ calendar/ goal/ settings/
      (each: screen + widgets/ + providers.dart)
  app.dart
  main.dart
```

### Design tokens

Extracted from `Ui/Calorie Tracker v3 - Bright Blue.dc.html`, which is the visual source of
truth. Encode these literally in `core/theme/tokens.dart` — do **not** re-derive them from a
Material seed colour, because `ColorScheme.fromSeed` will not reproduce them.

| Token | Hex | Use |
|---|---|---|
| `bg` | `#EAEFF9` | app background |
| `surface` | `#FFFFFF` | cards, nav bar, sheets |
| `primary` | `#2E5BFF` | ring, FAB, active tab, target number |
| `primaryPressed` | `#1B3FCC` | pressed |
| `primaryContainer` | `#EAF0FF` | selected chip, active tab pill, selected day |
| `primaryContainerPressed` | `#DCE6FF` | |
| `textPrimary` | `#0B0D12` | |
| `textSecondary` | `#5A6273` | |
| `textTertiary` | `#9AA2B4` | |
| `border` | `#E9EDF5` | 1px borders, dividers |
| `neutralOver` | `#C7CEDC` | **over-target arc, not-logged dot — this replaces red** |
| `ringTrack` | `#D9E1F0` | 224px ring track |
| `miniRingTrack` | `#EDF1F8` | calendar cell track |
| `shimmerHi` | `#F8FAFD` | skeleton highlight over `#EEF1F7` |
| `carbs` | `#FFA114` | 8px dot only |
| `fat` | `#8B5CF6` | 8px dot only |
| `scrim` | `rgba(11,13,18,0.40)` | sheet backdrop |

**Elevation** — two composited shadows, not Material elevation:
- card: `0 2px 8px rgba(11,13,18,.04)` + `0 12px 32px rgba(11,13,18,.06)`
- floating (nav bar, sheet buttons): `0 8px 32px rgba(11,13,18,.10)`
- blue FAB: `0 6px 20px rgba(46,91,255,.32)`

**Radius:** 10 / 16 (chips, icon buttons) / 20 (cards) / 22 (calendar card) / 26 (FAB) /
28 (sheet top) / 32 (nav bar) / `StadiumBorder` (pills).

**Type** — Poppins 400/500/600, `FontFeature.tabularFigures()` on every number:
56/600 goal target · 48/600 ring % · 28/600 screen title (ls −0.01em) · 26/600 day kcal ·
22/600 stat number · 18/600 section header · 17/600 meal kcal · 16/500 body-strong ·
15/500 body · 13/400 secondary · 12/400 caption · **11/500 uppercase ls 0.12em** section label ·
10/500 source badge.

**Motion** — `core/theme/motion.dart`, all honouring `MediaQuery.disableAnimations`:

| Name | Spec |
|---|---|
| standard curve | `Cubic(0.2, 0.9, 0.2, 1.0)` |
| `screenIn` | 300 ms, fade + slide 8px up |
| `rise` | 380 ms, fade + slide 12px up, **stagger 40–60 ms per list index** |
| `sheetUp` | 340 ms, translateY 100 %→0 |
| `fadeIn` | 180 ms |
| `ringIn` | 500 ms, scale 0.94→1 + fade |
| ring fill | **950 ms, `Cubic(0.22, 0.85, 0.24, 1.0)`**, from 0 on every entry to Home |
| `shimmer` | 1400 ms linear, infinite |
| `savePop` | 420 ms, translateY 0→−4→0 |

**Layout:** screen padding `16 / 20 / 20 / 96` (bottom clears the nav). Min tap target 44px.
Nav bar: inset 16 left/right, 20 bottom, height 64, radius 32. Centre FAB 52px, raised −12px.
Ring 224px, r 94, stroke 26. Over-target inner lap: r 68, stroke 8, `neutralOver`.

### Navigation

Take this from the prototype exactly. The bottom bar has **three slots: Home · Camera FAB ·
Goal.** It is *not* a five-tab bar.

- Calendar is reached from the calendar icon in the Home header.
- Manual search is reached from the `+` FAB floating above the nav, on Home only.
- Capture and Review are full-screen and **hide the nav bar**.

### Data layer

**Two separate `@DriftDatabase` classes with independent executors. Do not `ATTACH`.**
There are no cross-database joins: `entry_items` already denormalises name and macros at write
time, and `food_cache` exists precisely so the diary never reaches into `foods`. `food_id` is a
provenance breadcrumb, not a join key. ATTACH would also break codegen — Drift generates one
`Migrator` per database and would try to `CREATE TABLE foods` in the diary.

`foods.sqlite` **must be copied out of assets** on first run; Flutter assets live inside the APK
zip and SQLite needs a seekable path. Version the copy *in the filename*, and write via a temp
file + rename so a crash mid-copy can never leave a truncated file that `exists()` then trusts:

```dart
const kFoodsAssetVersion = 1;   // bump whenever foods.sqlite is rebuilt

QueryExecutor openFoodsDb() => LazyDatabase(() async {
  final dir  = await getApplicationSupportDirectory();
  final file = File(p.join(dir.path, 'foods_v$kFoodsAssetVersion.sqlite'));

  if (!await file.exists()) {
    final tmp  = File('${file.path}.tmp');
    final blob = await rootBundle.load('assets/db/foods.sqlite');
    await tmp.writeAsBytes(
      blob.buffer.asUint8List(blob.offsetInBytes, blob.lengthInBytes), flush: true);
    await tmp.rename(file.path);                          // atomic on the same filesystem
    // reap superseded foods_v*.sqlite copies here
  }

  sqlite3.tempDirectory = (await getTemporaryDirectory()).path;
  return NativeDatabase.createInBackground(
    file,
    enableMigrations: false,                              // never write user_version
    readPool: 2,                                          // concurrent as-you-type searches
    setup: (db) => db.execute('PRAGMA query_only = ON;'),
  );
});
```

- **foods → `getApplicationSupportDirectory()`** (Android `files/`) and **excluded from Android
  Auto Backup** via `data_extraction_rules.xml`. It is a regenerable blob and would otherwise
  burn the user's 25 MB backup quota.
- **diary → `getApplicationDocumentsDirectory()`** (Android `app_flutter/`) and **included** in
  backup. It is irreplaceable user data.
- Never the cache directory — Android evicts it and search would silently die.

`enableMigrations: false` is required: without it Drift tries to write `user_version` on open,
which fails against a `query_only` connection.

**Done when:** the app boots, copies the asset DB, and renders one hardcoded entry on a bare
themed Home screen.

---

## Phase 2 — Goal engine

Pure Dart in `domain/goal_engine.dart`. No I/O, no Flutter imports. **Tests before UI.**

```
BMR  = 10·kg + 6.25·cm − 5·age + (male ? 5 : −161)          [Mifflin-St Jeor]
TDEE = BMR × activity                (1.2 / 1.375 / 1.55 / 1.725 / 1.9)
rate = (weight − target) / weeks
```

Constraints applied **in this order**, returning a sealed result:

```dart
sealed class GoalResult {}
class GoalRefused  extends GoalResult { RefusalReason reason; String message; String? alternative; }
class GoalAdjusted extends GoalResult { GoalTarget target; String explanation; DateTime honestDate; }
class GoalAccepted extends GoalResult { GoalTarget target; }
```

1. **Age < 18** → `GoalRefused(minor)`. Hard stop, no bypass.
2. **Target BMI < 18.5**, or current BMI < 18.5 with a loss goal → `GoalRefused(unsafeTarget)`,
   offering maintenance.
3. **Clamp rate to 1 % bodyweight/week** → `GoalAdjusted` with the honest achievable date.
4. `deficit = rate × 7700 / 7`
5. `target = TDEE − deficit`, clamped to **1500 kcal (male) / 1200 kcal (female)** →
   `GoalAdjusted`, extending the date.

Gain and maintain are first-class, not a loss-only path.

Required tests — all seven pass before any goal UI: age 15 → refuse; lose 15 kg in 30 days →
clamp + honest date; target BMI 16 → refuse; already underweight + loss goal → refuse;
aggressive-but-legal → clamp to floor + extend date; maintenance → clean pass; gain → clean pass.

Two numbers [01-concept.md](01-concept.md) flags as needing sourcing before they are defended:
**7700 kcal/kg** overestimates loss over long horizons (metabolic adaptation) — fine for 6–12
weeks, wrong for a year; and the **1500/1200 floors** are consumer-guidance folklore that should
be traced to an authoritative source. Put both in a doc comment with the citation.

**Refusals render inline at the offending input** — plain language, reason plus an alternative.
No modal dialogs.

---

## Phase 2b — Onboarding

The prototype has no onboarding screens, so this is designed fresh against the Phase 1 tokens.
It is the first thing a user sees and the best showcase for the goal engine, so it gets real
screens rather than a stripped first-run form.

Five steps, one question per screen, a thin progress rule at the top, back always available:

1. **Sex** — two large selectable cards. Needed for both the Mifflin-St Jeor constant and the
   calorie floor.
2. **Age** — numeric. **Under 18 is a hard stop**: the flow ends with a plain-language screen
   pointing to a doctor or guardian, with no continue button and no bypass. This is the only dead
   end in the app, and it must not be dressed up as an error.
3. **Height and current weight** — paired inputs with unit affordances.
4. **Target weight and timeframe** — where refusals and corrections surface. Target BMI below
   18.5 (or a loss goal from an already-underweight start) refuses inline and offers maintenance
   as a one-tap alternative. A too-fast rate does **not** block: it clamps and shows the honest
   achievable date beneath the input.
5. **Activity level** — five options with concrete descriptions, not jargon ("desk job, little
   exercise" rather than "sedentary, 1.2").

Then a **result screen**: the daily target at 56/600 in `primary` with the macro split beneath,
phrased as a plan rather than a verdict, and a confirm that writes `profile` and lands on Home.

Constraints from [01-concept.md](01-concept.md): refusals inline, never modal; no body-shape
imagery, no before/after, no "ideal body" language; gaining and maintaining are first-class paths
through this flow, not afterthoughts behind a loss default.

The result screen and the Phase 7 goal-editing screen render the same `GoalTarget` widget.

**Done when:** a fresh install walks to a saved profile, and each of the seven engine test cases
is reachable and correctly presented through the UI.

---

## Phase 3 — Manual logging (no AI)

The milestone to protect: **at the end of Phase 3 you have a working calorie tracker.**

- **Search screen** — 250 ms debounce → `buildFtsQuery` → FTS5 `MATCH` → ranked results. Before
  any typing, show recent and frequent foods as chips (UC-05 step 2).
- **Result card** — name, source badge, default serving, kcal. Tapping expands it in place into
  unit chips (`0.5 ×`, `1 ×`, `2 ×`), a grams readout, a live kcal figure, and a Save button.
  Serving units primary, grams secondary.
- **FTS5 escaping** — see [03-food-data.md §5](03-food-data.md). Tokenise and quote; never
  blocklist characters; the `*` goes outside the closing quote.
- Save to `entries` + `entry_items` with `source = db`; edit and delete existing items.

**Done when:** you can log a full day by hand and the totals are correct.

---

## Phase 4 — Home and day view

- **Header** — 44px calendar icon button, then a horizontally scrolling 12-day strip that
  **auto-centres the selected day** on mount and on change. Active chip: filled `primary`, white
  text. Inactive: white, `border`, `textSecondary`.
- **Ring** — 224px, animates from 0 with the 950 ms curve *every time Home is entered*. Centre
  shows the integer percentage at 48/600. On a cold start, the centre is a shimmer block, not a
  zero.
- **Over target draws a second dim lap** at r 68 in `neutralOver` — the visual grammar that
  replaces red. Caption changes from "left today" to "over today"; nothing turns red anywhere.
- **kcal line** — `1,040 / 2,070 kcal` at 16/500, caption beneath at 13/500.
- **Protein card** — uppercase label, `44 / 140 g` right-aligned, **12 discrete pips**, then a
  divider and a row of carbs/fat with their coloured dots. Protein prominent; carbs and fat
  secondary, exactly as [01-concept.md](01-concept.md) orders them.
- **Meal list** — white cards, uppercase meal type in `textTertiary`, item summary, kcal
  right-aligned at 17/600 with a small "kcal" label. Staggered `rise` entry.
- **Empty state** — "Nothing logged yet." plus the `+` FAB inviting the first log.

---

## Phase 5 — Calendar

- Month header `‹ August 2026 ›`, 48px hit targets.
- White card, `M T W T F S S` header, 7-column grid of 1:1 cells.
- **Each logged day is a ring arc**, not a filled tint: r 16.5, stroke 3, `primary` when on
  target, `neutralOver` when over. Selected day gets an `EAF0FF` circle behind it. **Unlogged
  days get a 3px grey dot** — absent, not failed. Future days are `#C7CEDC` and not tappable.
- Legend: on target / over / not logged.
- Two stat cards: `Average` kcal per logged day, `Logged` days this month.
- A selected-day summary card with a 56px mini-ring, the day's kcal at 26/600, and
  "1,030 under target" — tapping opens the day.

---

## Phase 6 — Photo path

First network dependency. Deliberately last, so a model outage never blocks logging.

### 6a — Worker, tested with `curl` before Flutter touches it

Cloudflare Worker in `worker/`. Responsibilities: hold the API key, per-device rate limit, cache
by image hash, model fallback, and **log raw upstream responses from the first commit** —
[01-concept.md](01-concept.md) records that on a previous project a Flutter catch block turned
server errors into UI messages and hid the real failure for weeks.

Contract per [01-concept.md §9](01-concept.md). Schema-constrained; never regex-parse prose.

**Model:** `google/gemini-2.5-flash` is alive on OpenRouter but three generations stale and
*more expensive on output* ($2.50/M) than **`google/gemini-3.7-flash`** ($1.875/M). Pin an
explicit slug — never the floating `~google/gemini-flash-latest`, which would silently change
behaviour under your prompt tuning. **Keep the slug in a Worker env var, not the APK**; that one
decision neutralises the whole dead-slug risk class.

**`provider: { require_parameters: true }` is load-bearing.** OpenRouter's docs admit schema
enforcement *"differs by provider"* — some guarantee compliance, others treat the schema as a
strong hint. Without this flag you get malformed JSON intermittently in production while it works
perfectly in testing. Also set `strict: true`, `additionalProperties: false`, and mark every
field required.

The prompt must **explicitly instruct the model to account for preparation fat** — oil, ghee,
butter, frying. This is the targeted fix for the documented failure mode described in
[01-concept.md §2](01-concept.md).

Fallback if schema violations appear in the raw logs: the direct Google AI API with
`responseSchema`. Because the Worker owns this, that is a one-file change — which is the reason
to keep the Worker even though it looks like indirection.

### 6b — Flutter integration

- Capture, then **compress before upload**: 1024px longest edge, JPEG q80, ~150 KB. Gemini tiles
  images internally and base64 inflates the payload ~33 %, so a raw 4 MB phone photo costs real
  money and latency for zero accuracy gain.
- **Optional details field, collapsed by default.** It must never take focus automatically —
  capture stays one tap for users who skip it (UC-04).
- **Proposed card** — the signature interaction. A low-confidence item renders at `blur(3px)` and
  `opacity 0.55` with "tap to confirm portion" beneath. Tapping expands portion chips; confirming
  snaps it sharp. Uncertainty is shown as *softness*, never as a warning colour. Header reads
  "2 to confirm" / "all confirmed".
- While analysing, show 3 shimmer skeletons at 96px.
- Editing: tap name → edit or replace via DB lookup; tap a macro → edit directly; swipe → remove;
  "+ Add item" → append a row the photo missed.
- Save with `source = ai`, then write the **accepted** values to `food_cache` — the cache learns
  from the user's corrections, not from the model.
- **Cache hit skips the API call entirely** (UC-12), tagged `source = cache`.
- **Failure (UC-11)** — *"Couldn't read that photo. Try again, or add the food manually."* with a
  direct button into search. Retain the photo so a retry costs nothing.

**Riverpod 3 gotchas — real money and battery bugs here, not cosmetic:**

- **Automatic retry is on by default in 3.x.** A failed photo analysis silently re-fires with
  backoff and **re-bills you**. Set `retry: null` on the analysis provider.
- **Notifiers get a fresh instance on every rebuild in 3.x** (the 2.x pseudo-singleton is gone),
  so a `CameraController`, `Timer` or `StreamSubscription` held as a notifier field **leaks**.
  Hoist them into their own providers bound with `ref.onDispose`. This bites the camera controller
  and the search debounce directly.

---

## Phase 7 — Polish

- **Sources screen** — driven by the `meta` manifest, so it lists exactly what shipped.
- Real error and empty-state copy everywhere.
- Goal editing (UC-10): the engine re-runs live and shows the resulting target before saving, all
  safety constraints reapplied. Past entries are **not** retroactively re-evaluated.
- The quiet safety net: if intake logs run implausibly low for several consecutive days, stop
  nudging toward the target and surface a non-clinical suggestion to check in with a professional.
  Do not gamify the user back on track.
- README, screenshots, demo video, LICENSE, third-party attributions.
- **Release signing config** — release currently signs with the debug key.

---

## Verification

| Phase | Check |
|---|---|
| 0 | `flutter build apk --release` succeeds; installs as "Calori"; `INTERNET` present in the **merged release** manifest (`build/app/outputs/logs/manifest-merger-release-report.txt`) |
| 0b | CLI queries for `roti`, `biryani`, `chicken breast`, `daal`, `pizza`, `crème brûlée` return sane ranked results; validation gate passes; hand-verify rows against source CSVs |
| 1 | App boots, copies the asset DB once; second launch does **not** re-copy |
| 2 | `flutter test` — all seven goal-engine cases pass; engine has zero Flutter imports |
| 2b | Fresh install reaches a saved profile; age 15 dead-ends with no bypass; every refusal and correction is reachable and correctly worded |
| 3 | Log a full day manually; totals correct; edit and delete work; search survives `chick-pea "curry*` without throwing |
| 4 | Ring animates from 0 on entry; over-target shows the grey second lap and **no red**; empty state reads correctly |
| 5 | Month grid matches the screenshot; unlogged days show a dot; future days inert |
| 6a | `curl` the Worker with a real photo before any Flutter code; confirm schema-valid JSON and that raw responses are logged |
| 6b | Airplane mode → the manual path still works end to end; a repeat meal hits `food_cache` with **no** network call |
| 7 | Sources screen lists every dataset actually present in the shipped DB |

Run against the `Ui/` screenshots side by side at Phases 4 and 5 — they are acceptance criteria
for layout, not just inspiration.

---

## Risks

| Risk | Mitigation |
|---|---|
| Flutter upgrade breaks other projects on this machine | It is a global toolchain change; verify other repos still build, or use FVM to pin per-project |
| Phase 0b data work is unglamorous and easy to skip | Every later phase reads from that DB; fixing a bad schema after Phase 4 means touching every screen |
| OpenRouter routes to a provider that ignores the JSON schema | `require_parameters: true`; log raw upstream responses; direct Google AI API as the contained fallback |
| Riverpod 3 auto-retry silently re-bills failed vision calls | `retry: null` on the analysis provider |
| INDB has no LICENSE file | Accepted by decision — see [03-food-data.md §7](03-food-data.md) |
| Share-alike (AFCD, Open Food Facts) contaminating the merged DB | Kept out of `foods.sqlite`; shipped later as a separate ODbL pack |
| Fuzzy dedup silently merges two different foods | Auto-merge on exact normalised name only; fuzzy candidates go to a review CSV |
| A kJ value reaches the app as kcal | Build fails on `kcal_100g > 900` plus a ±25 % Atwater cross-check |
