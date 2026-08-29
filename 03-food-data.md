# Food Data — Sources, Pipeline, Schema

> The bundled food database. Built once on desktop by a Python script, shipped as a read-only
> SQLite asset. This is Phase 0 of [02-phases.md](02-phases.md), expanded.

**Goal:** genuinely global coverage — not a desi-only or USDA-only subset — in an asset of a few
megabytes. USDA alone is broad but American-shaped and thin on prepared dishes from elsewhere.
The answer is a **multi-source merge with strict provenance**.

---

## 1. Licence landscape

This table drives the architecture. Read it before touching a downloader.

| Source | Records | Licence | Redistribute in a public app | Share-alike |
|---|---|---|---|---|
| USDA FDC — SR Legacy | 7,793 | Public domain / CC0 | Yes | No |
| USDA FDC — Foundation | ~470 | Public domain / CC0 | Yes | No |
| USDA FDC — FNDDS / Survey | 5,432 | Public domain / CC0 | Yes | No |
| **CoFID** (UK, OHID) | ~2,900 | **Open Government Licence v3** | Yes, attribution | No |
| **CIQUAL** (FR, ANSES) | ~3,200 | **Licence Ouverte / Etalab** | Yes, attribution | No |
| **CNF** (Canada, Health Canada) | ~5,690 | **OGL–Canada** | Yes, attribution | No |
| **Frida** (DK, DTU) | ~1,300 | Free, mandatory credit; no formal licence | Yes, attribution | Unclear |
| **INDB** (India) | 1,095 items + 1,014 recipes | **No LICENSE file** | Accepted risk — see §7 | — |
| **Pakistan FCT** (rev. 2001) | 210 | FAO-hosted, PDF only | Extraction required | Verify |
| AFCD (Australia, FSANZ) | 1,588 | **CC BY-SA 3.0 AU** | Yes | **YES** |
| Open Food Facts | ~3.7M | **ODbL 1.0** (+ DbCL contents) | Yes | **YES** |
| USDA Branded | ~1.9M | CC0 | Yes, but 2.9 GB | No |

### The share-alike split

AFCD (CC BY-SA) and Open Food Facts (ODbL) both impose share-alike on *derivative databases*.
Merging either into `foods.sqlite` arguably makes the whole merged artefact share-alike — which
on a public repo is survivable, but it contaminates every downstream reuse of the build. So keep
them physically separate:

- **`foods.sqlite`** — the permissive core. Ships in the APK. No share-alike encumbrance.
- **`foods_ext.sqlite`** — a later share-alike pack (AFCD + an Open Food Facts slice for packaged
  goods), distributed under ODbL as an optional download.

v1 ships the core only, matching the concept doc's "Open Food Facts — not in v1". Design the
two-file split in from the start so the pack drops in later with no schema change.

USDA Branded is excluded on separate grounds: 2.9 GB, manufacturer-submitted and inconsistent,
and it only pays off with a barcode scanner, which is out of scope.

---

## 2. v1 composition

USDA SR Legacy + Foundation + **FNDDS**, plus CoFID, CIQUAL, CNF and Frida for European and
Canadian coverage, plus INDB and the Pakistan FCT for South Asian.

**FNDDS is the one that matters most.** Prepared and mixed dishes are what people actually
photograph and log, and FNDDS carries the richest household-portion data of any source here.

Raw union ≈ 29,000 rows. After dedup, **~18,000–20,000 unique foods**, landing at an estimated
**4–6 MB** with FTS5 external content and `VACUUM`.

**Honest remaining gaps:** East Asia, Southeast Asia, the Middle East, Latin America, most of
Africa. FAO/INFOODS publishes regional tables (e.g. WAFCT 2019 for Western Africa, with Excel
datasheets) — verify FAO's licence terms before pulling any in.

This gap is precisely what the AI photo path exists to cover, and `food_cache` means each user's
frequent foods converge on correct values whether or not the database ever knew them.

---

## 3. Schema

This **extends** the `foods` table in [01-concept.md](01-concept.md). That version gives each
food a single `serving_desc` / `serving_grams`, which is too narrow: FNDDS, CNF and CoFID all
supply **multiple** household portions per food, and both UC-05 and the prototype's unit chips
need them. Portions are promoted to a child table.

```sql
CREATE TABLE foods (
  id              INTEGER NOT NULL PRIMARY KEY,
  name            TEXT NOT NULL,
  name_normalised TEXT NOT NULL,
  source          TEXT NOT NULL,   -- 'usda_sr'|'usda_fndds'|'cofid'|'ciqual'|'indb'|...
  source_id       TEXT,            -- original key, for traceability back to the CSV
  locale_hint     TEXT,            -- 'IN','PK','GB','FR','US' — a ranking bias, never a filter
  kcal_100g       REAL NOT NULL,
  protein_100g    REAL NOT NULL,
  carbs_100g      REAL NOT NULL,
  fat_100g        REAL NOT NULL
) STRICT;

CREATE TABLE food_portions (
  id         INTEGER NOT NULL PRIMARY KEY,
  food_id    INTEGER NOT NULL REFERENCES foods(id),
  label      TEXT NOT NULL,        -- '1 plate', '1 medium', '1 cup'
  grams      REAL NOT NULL,
  is_default INTEGER NOT NULL DEFAULT 0
) STRICT;

CREATE VIRTUAL TABLE foods_fts USING fts5(
  name, content=foods, content_rowid=id,
  tokenize="unicode61 remove_diacritics 2"
);

-- `key` is reserved in drift's SQL parser, hence `name`.
CREATE TABLE meta (name TEXT PRIMARY KEY, value TEXT) STRICT;
-- build_version, built_at, and a per-source manifest of licence + attribution string
```

Notes:

- **`remove_diacritics 2`** matters once CIQUAL and Frida are in — it makes *crème* findable by
  typing `creme`.
- **`content=foods`** (external content) stops FTS5 duplicating every name string, roughly
  halving the index.
- The **`meta` manifest** is what the in-app Sources screen reads, so that screen can never drift
  from what actually shipped.
- Because the asset is built offline and never written on device, **no FTS5 sync triggers are
  needed** — the builder populates `foods_fts` directly and ships the finished index.

---

## 4. Pipeline

```
tools/build_foods_db/
  build.py                orchestrator
  sources/base.py         Source protocol -> yields FoodRecord
  sources/usda_sr.py  usda_foundation.py  usda_fndds.py
  sources/cofid.py  ciqual.py  cnf.py  frida.py  indb.py  pakistan_fct.py
  normalise.py  dedup.py  validate.py  writer.py  manifest.py
```

One adapter per dataset, each yielding a common `FoodRecord`. Adding or dropping a source is one
file plus one manifest line — this is what makes any single dataset cheap to remove.

### Normalisation

lowercase → strip punctuation → collapse whitespace → trivial singularisation → split USDA's
trailing qualifiers (`, raw`, `, cooked, boiled, drained, without salt`) into a separate `prep`
note rather than either keeping them in the search name or losing the information.

### Dedup and precedence

Match on **exact normalised name only** for automatic merging. Compute token-set overlap
(Jaccard ≥ 0.85) as a *review signal* written to a CSV — **never auto-merge on a fuzzy match.**

The concept doc's argument against fuzzy-matching photos applies verbatim here: a bad match that
*succeeds silently* is worse than a miss, because it produces confident wrong numbers wearing an
authoritative source label.

Precedence on collision:

1. **Regional specificity** — INDB / Pakistan FCT for desi dishes, CoFID for UK dishes. A
   regional table's "biryani" beats USDA's.
2. **FNDDS** for prepared and mixed dishes.
3. **USDA Foundation** (newest lab data), then **SR Legacy**, for generics.
4. **CoFID → CIQUAL → CNF → Frida** for whatever is still net-new.

Sources late in that order contribute only rows nobody else has — which is why CNF's 5,690 rows
add a few hundred net-new entries rather than 5,690 duplicates, and why the merged total lands
near 19,000 rather than 29,000.

### Validation

**IFCT 2017 reports energy in kJ** (IFCT 2004 used kcal). Convert with **kcal = kJ / 4.184** —
the FAO factor, not the rounded 4.2; across a day's logging that difference is visible.

Build-time assertions that fail the build loudly:

- `0 ≤ kcal_100g ≤ 900` — 900 ≈ pure fat, so anything above is a kJ value that escaped conversion
- each macro `0 ≤ x ≤ 100`, and `protein + carbs + fat ≤ 100` per 100 g
- **Atwater cross-check**: `4·protein + 4·carbs + 9·fat` against the stated kcal, tolerance
  **±25 %** — deliberately wide, because fibre, alcohol, polyols and food-specific Atwater
  factors all shift it legitimately. Outside tolerance → quarantine CSV for a human pass, never
  a silent drop.
- every food has ≥ 1 portion, `grams > 0`
- no duplicate `(source, source_id)`; `count(foods_fts) == count(foods)`

Finish with `PRAGMA page_size=4096;` and `VACUUM;`.

**Done when:** CLI queries for `roti`, `biryani`, `chicken breast`, `daal`, `pizza` and
`crème brûlée` all return sane ranked results with plausible macros, and a hand-check of a few
rows against the source CSVs agrees.

---

## 5. App-side implementation

- **Search:** 250 ms debounce → `buildFtsQuery` → `searchFoods` → results.
- **Ranking:** `ORDER BY bm25(foods_fts), length(f.name)`. `bm25()` returns **negative** scores
  where more negative is better, so **ascending is correct** — this reads wrong and is right.
  Add a small precedence tiebreak so a regional row outranks a generic one at equal relevance.
- **Result card:** the source badge (`INDB` / `USDA` / `CoFID`) is already in the prototype and
  is now backed by real provenance. Portion chips come from `food_portions` with `is_default`
  first; grams stay visible as the secondary readout, matching "serving units primary, grams
  secondary" from UC-05.
- **Sources screen** reads the `meta` manifest, so it lists exactly what shipped in this build.
- Bump `kFoodsAssetVersion` on every rebuild; the filename-versioned asset copy handles the swap.

### FTS5 query escaping

FTS5 has its own grammar (`AND OR NOT NEAR`, `*`, `^`, `:`, `"`, parens). Raw user input is both
a syntax-error generator and a DoS vector. **Tokenise and quote — never blocklist characters.**

```dart
/// 'chick-pea "curry' -> '"chick" "pea" "curry"*'
String buildFtsQuery(String input) {
  final t = input.split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
                 .where((s) => s.isNotEmpty).toList();
  if (t.isEmpty) return '';
  return [
    for (var i = 0; i < t.length; i++)
      i == t.length - 1
          ? '"${t[i].replaceAll('"', '""')}"*'   // * OUTSIDE the quote
          : '"${t[i].replaceAll('"', '""')}"',
  ].join(' ');
}
```

Three things this gets right:

- **The `*` sits outside the closing quote.** `"chicken"*` is a prefix query; `"chicken*"` is a
  phrase containing a literal asterisk, which the tokeniser strips, silently degrading to an
  exact-token match. This is the most common FTS5 bug.
- **Splitting on `[^\p{L}\p{N}]+`** removes every operator structurally, so none can reach the
  parser.
- **Prefix on the last token only** — otherwise every keystroke scans a huge prefix range.

Guard `if (q.isEmpty) return [];` before querying — an empty `MATCH` is a runtime error, not an
empty result.

---

## 6. Attribution

The repo is public, so this is an obligation, not a courtesy.

- **`DATA-LICENSES.md`** at the repo root: per-source licence, URL, retrieval date, and the exact
  attribution string each licence demands. Written during Phase 0, not deferred to Phase 7.
- **In-app Sources screen in v1**, driven by the `meta` manifest.
- OGL v3, Licence Ouverte and OGL–Canada all permit commercial use but **require attribution** —
  discharged by the above.
- **AFCD and Open Food Facts stay out of `foods.sqlite`** so share-alike never contaminates the
  merged core.

---

## 7. INDB — recorded decision

The INDB GitHub repo has **no LICENSE file**, which under GitHub's terms defaults to
all-rights-reserved. Its underlying ICMR-NIN IFCT 2017 data must be requested separately from
NIN. [01-concept.md](01-concept.md) describes INDB as CC BY; that is not verified and appears to
be wrong — the open-access licence on the *paper* does not license the *dataset*.

**Decision: use it anyway.** Mitigations:

- Attribute the paper and the repo prominently in `DATA-LICENSES.md` and the Sources screen.
- Email the authors for written permission in parallel with the build; academics usually grant
  this within days.
- Keep `sources/indb.py` swappable, so removing it is one file plus one manifest line and a
  rebuild.

The alternative — `github.com/ifct2017/ifct2017` — relicensed to **AGPL-3.0 in April 2025**,
which is a worse trap in a distributed mobile app. Noted here so the option isn't rediscovered
and mistaken for an easy fix.
