"""Writes the finished SQLite asset.

The schema here must stay in lockstep with `lib/data/foods/foods.drift`. Drift
generates Dart against that file, but the database that actually ships is this
one — a mismatch is not caught at compile time and surfaces as a runtime column
error on a user's phone.
"""

from __future__ import annotations

import sqlite3
from pathlib import Path

from models import FoodRecord

#: Kept identical to foods.drift, except that STRICT is applied here. Drift's
#: parser gains nothing from it, but on the real database it turns a type
#: mismatch into an error at insert time rather than a silently coerced value.
SCHEMA = """
CREATE TABLE foods (
    id INTEGER NOT NULL PRIMARY KEY,
    name TEXT NOT NULL,
    name_normalised TEXT NOT NULL,
    source TEXT NOT NULL,
    source_id TEXT,
    locale_hint TEXT,
    kcal_100g REAL NOT NULL,
    protein_100g REAL NOT NULL,
    carbs_100g REAL NOT NULL,
    fat_100g REAL NOT NULL
) STRICT;

CREATE TABLE food_portions (
    id INTEGER NOT NULL PRIMARY KEY,
    food_id INTEGER NOT NULL REFERENCES foods (id),
    label TEXT NOT NULL,
    grams REAL NOT NULL,
    is_default INTEGER NOT NULL DEFAULT 0
) STRICT;

CREATE INDEX idx_food_portions_food ON food_portions (food_id);

CREATE VIRTUAL TABLE foods_fts USING fts5 (
    name,
    content = foods,
    content_rowid = id,
    tokenize = "unicode61 remove_diacritics 2"
);

CREATE TABLE meta (
    name TEXT NOT NULL PRIMARY KEY,
    value TEXT NOT NULL
) STRICT;
"""


def write(
    path: Path,
    records: list[FoodRecord],
    meta: dict[str, str],
) -> None:
    """Build the database at `path`, replacing anything already there."""

    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        path.unlink()

    connection = sqlite3.connect(path)
    try:
        connection.executescript("PRAGMA page_size=4096;")
        connection.executescript(SCHEMA)

        # Drift compares user_version against its schemaVersion on open. Left
        # at 0 the database looks brand new, and drift runs onCreate — which
        # for FoodsDb deliberately throws, because a finished database has
        # nothing to create. Must match FoodsDb.schemaVersion.
        connection.executescript("PRAGMA user_version = 1;")

        food_rows = []
        portion_rows = []

        for food_id, record in enumerate(records, start=1):
            food_rows.append(
                (
                    food_id,
                    record.name,
                    record.name_normalised,
                    record.source,
                    record.source_id,
                    record.locale_hint,
                    float(record.kcal_100g),
                    float(record.protein_100g),
                    float(record.carbs_100g),
                    float(record.fat_100g),
                )
            )
            for portion in record.portions:
                portion_rows.append(
                    (
                        food_id,
                        portion.label,
                        float(portion.grams),
                        1 if portion.is_default else 0,
                    )
                )

        connection.executemany(
            "INSERT INTO foods (id, name, name_normalised, source, source_id, "
            "locale_hint, kcal_100g, protein_100g, carbs_100g, fat_100g) "
            "VALUES (?,?,?,?,?,?,?,?,?,?)",
            food_rows,
        )
        connection.executemany(
            "INSERT INTO food_portions (food_id, label, grams, is_default) "
            "VALUES (?,?,?,?)",
            portion_rows,
        )
        connection.executemany(
            "INSERT INTO meta (name, value) VALUES (?,?)",
            sorted(meta.items()),
        )

        # External-content FTS: the index is populated from `foods` in one
        # pass. No sync triggers are created, because this database is built
        # here and never written on device.
        connection.execute(
            "INSERT INTO foods_fts (foods_fts) VALUES ('rebuild')"
        )

        connection.commit()

        # Must run outside a transaction, and after the index is built.
        connection.isolation_level = None
        connection.execute("VACUUM")
        connection.execute("PRAGMA optimize")
    finally:
        connection.close()


def verify(path: Path) -> dict[str, int | str]:
    """Re-open the finished file and assert it is actually usable.

    Building a database that opens but cannot be searched is a real failure
    mode — an FTS index that was never populated returns zero rows for every
    query, with no error anywhere. So the search path is exercised here rather
    than trusted.
    """
    connection = sqlite3.connect(f"file:{path}?mode=ro", uri=True)
    try:
        foods = connection.execute("SELECT count(*) FROM foods").fetchone()[0]
        portions = connection.execute(
            "SELECT count(*) FROM food_portions"
        ).fetchone()[0]
        indexed = connection.execute(
            "SELECT count(*) FROM foods_fts"
        ).fetchone()[0]

        if indexed != foods:
            raise AssertionError(
                f"FTS index holds {indexed} rows but foods holds {foods}. "
                f"The index did not rebuild; every search would return nothing."
            )

        # A real ranked query, not just a row count. The probe term is taken
        # from the data rather than hardcoded: a French-only or Hindi-only
        # build has no "rice" in it, and failing that build would be the check
        # being wrong rather than the database.
        seed = connection.execute(
            "SELECT name FROM foods WHERE length(name) > 3 LIMIT 1"
        ).fetchone()
        if seed is None:
            raise AssertionError("the foods table is empty")

        word = "".join(
            c for c in seed[0].split(",")[0].split()[0] if c.isalnum()
        )
        if not word:
            raise AssertionError(f"no searchable token in {seed[0]!r}")

        probe = connection.execute(
            "SELECT f.name FROM foods_fts "
            "JOIN foods f ON f.id = foods_fts.rowid "
            "WHERE foods_fts MATCH ? ORDER BY bm25(foods_fts) LIMIT 1",
            (f'"{word}"*',),
        ).fetchone()

        if probe is None:
            raise AssertionError(
                f"FTS query for {word!r} returned nothing, even though that "
                f"word came from a row in the foods table. The index exists "
                f"but is not searchable."
            )

        return {
            "foods": foods,
            "portions": portions,
            "indexed": indexed,
            "probe": probe[0],
            "bytes": path.stat().st_size,
        }
    finally:
        connection.close()
