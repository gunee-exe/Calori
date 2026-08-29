"""Builds assets/db/foods.sqlite from the public food composition tables.

Runs on a desktop, never on a phone. The app ships the *output* of this script,
not the script — think of it as a compiler whose artefact is committed.

    python build.py                       # everything
    python build.py --only usda_sr        # one source, for a fast loop
    python build.py --skip-download       # reuse .cache, reparse
    python build.py --list                # what is registered

See 03-food-data.md for the source list, licences, and the dedup rationale.
"""

from __future__ import annotations

import argparse
import csv
import sys
import traceback
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import dedup  # noqa: E402
import manifest  # noqa: E402
import validate  # noqa: E402
import writer  # noqa: E402
from models import FoodRecord  # noqa: E402
from normalise import normalise, split_prep  # noqa: E402
from sources.base import ManualDownloadRequired, Source  # noqa: E402
from sources.usda import FNDDS, FOUNDATION, SR_LEGACY  # noqa: E402

#: Every registered adapter. Adding a dataset is one import and one entry.
#:
#: Sources not yet implemented (CoFID, CIQUAL, CNF, Frida, INDB, Pakistan FCT)
#: are tracked in 03-food-data.md. The pipeline is deliberately additive: each
#: is an independent file, so the merge can ship with whatever is ready and
#: gain the rest without any change to the app.
SOURCES: list[Source] = [
    SR_LEGACY,
    FOUNDATION,
    FNDDS,
]

DEFAULT_OUT = HERE.parent.parent / "assets" / "db" / "foods.sqlite"
DEFAULT_CACHE = HERE / ".cache"
REPORT_DIR = HERE / "out"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", type=Path, default=DEFAULT_OUT)
    parser.add_argument("--cache", type=Path, default=DEFAULT_CACHE)
    parser.add_argument(
        "--only",
        default="",
        help="comma-separated source ids to build (default: all)",
    )
    parser.add_argument("--skip-download", action="store_true")
    parser.add_argument("--list", action="store_true")
    args = parser.parse_args(argv)

    if args.list:
        for source in SOURCES:
            print(f"{source.info.id:20} {source.info.name}")
        return 0

    wanted = {s.strip() for s in args.only.split(",") if s.strip()}
    selected = [s for s in SOURCES if not wanted or s.info.id in wanted]

    if not selected:
        print(f"No sources matched {args.only!r}", file=sys.stderr)
        return 2

    REPORT_DIR.mkdir(parents=True, exist_ok=True)

    records: list[FoodRecord] = []
    used = []
    skipped: list[tuple[str, str]] = []

    for source in selected:
        print(f"\n=== {source.info.name} ===")
        try:
            if not args.skip_download:
                source.fetch(args.cache)

            before = len(records)
            for record in source.records(args.cache):
                _prepare(record)
                records.append(record)

            print(f"  parsed  {len(records) - before:,} records")
            used.append(source.info)

        except ManualDownloadRequired as needed:
            print(f"  SKIP    {needed.instructions}")
            skipped.append((source.info.id, needed.instructions))
        except Exception:  # noqa: BLE001 - one bad source must not kill the run
            print(f"  ERROR   {source.info.id} failed:", file=sys.stderr)
            traceback.print_exc()
            skipped.append((source.info.id, "adapter raised; see traceback"))

    if not records:
        print("\nNo records parsed. Nothing to write.", file=sys.stderr)
        return 1

    print(f"\n=== validate ({len(records):,} raw) ===")
    kept, rejected, warned = validate.partition(records)
    print(f"  ok         {len(kept):,}")
    print(f"  quarantine {len(rejected):,}")
    print(f"  warnings   {len(warned):,}")
    if rejected:
        _write_rejections(rejected)
    if warned:
        _write_warnings(warned)

    print("\n=== dedupe ===")
    precedence = {s.id: s.precedence for s in used}
    merged, near, contributed = dedup.dedupe(kept, precedence)

    collapsed = len(kept) - len(merged)
    print(f"  unique     {len(merged):,}  ({collapsed:,} duplicates collapsed)")
    for source_id, count in sorted(contributed.items(), key=lambda kv: -kv[1]):
        print(f"    {source_id:20} {count:>7,}")

    if near:
        _write_near_matches(near)
        print(f"  review     {len(near):,} near-matches -> out/near_matches.csv")

    print("\n=== write ===")
    portion_count = sum(len(r.portions) for r in merged)
    meta = manifest.build(used, contributed, len(merged), portion_count)
    writer.write(args.out, merged, meta)

    stats = writer.verify(args.out)
    size_mb = int(stats["bytes"]) / 1_048_576
    print(f"  foods      {stats['foods']:,}")
    print(f"  portions   {stats['portions']:,}")
    print(f"  fts rows   {stats['indexed']:,}")
    print(f"  probe      'rice' -> {stats['probe']}")
    print(f"  size       {size_mb:.1f} MB")
    print(f"  written    {args.out}")

    if skipped:
        print("\n=== skipped sources ===")
        for source_id, why in skipped:
            print(f"  {source_id}: {why}")

    return 0


def _prepare(record: FoodRecord) -> None:
    """Split the prep qualifier off the name and compute the dedup key."""
    name, prep = split_prep(record.name)
    record.name = name
    record.prep = prep
    record.name_normalised = normalise(name)


def _write_rejections(rejected: list[validate.Rejection]) -> None:
    path = REPORT_DIR / "quarantine.csv"
    with path.open("w", encoding="utf-8", newline="") as handle:
        w = csv.writer(handle)
        w.writerow(
            ["reason", "detail", "source", "source_id", "name", "kcal", "p", "c", "f"]
        )
        for item in rejected:
            r = item.record
            w.writerow(
                [
                    item.reason,
                    item.detail,
                    r.source,
                    r.source_id,
                    r.name,
                    f"{r.kcal_100g:.1f}",
                    f"{r.protein_100g:.1f}",
                    f"{r.carbs_100g:.1f}",
                    f"{r.fat_100g:.1f}",
                ]
            )
    print(f"  quarantine -> {path}")


def _write_warnings(warned: list[validate.Warning]) -> None:
    """Warnings ship. They exist so a format change is visible between builds."""
    path = REPORT_DIR / "warnings.csv"
    with path.open("w", encoding="utf-8", newline="") as handle:
        w = csv.writer(handle)
        w.writerow(["reason", "detail", "source", "name", "kcal", "p", "c", "f"])
        for item in warned:
            r = item.record
            w.writerow(
                [
                    item.reason,
                    item.detail,
                    r.source,
                    r.name,
                    f"{r.kcal_100g:.1f}",
                    f"{r.protein_100g:.1f}",
                    f"{r.carbs_100g:.1f}",
                    f"{r.fat_100g:.1f}",
                ]
            )
    print(f"  warnings   -> {path}")


def _write_near_matches(near: list[dedup.NearMatch]) -> None:
    """Near-matches go to a human, never to an automatic merge.

    A wrong merge here ships confident wrong numbers under an authoritative
    source badge, which is precisely the failure mode 01-concept.md argues is
    worse than having no match at all.
    """
    path = REPORT_DIR / "near_matches.csv"
    with path.open("w", encoding="utf-8", newline="") as handle:
        w = csv.writer(handle)
        w.writerow(
            [
                "similarity",
                "kept_source",
                "kept_name",
                "kept_kcal",
                "other_source",
                "other_name",
                "other_kcal",
            ]
        )
        for match in near:
            w.writerow(
                [
                    f"{match.similarity:.2f}",
                    match.kept.source,
                    match.kept.name,
                    f"{match.kept.kcal_100g:.0f}",
                    match.other.source,
                    match.other.name,
                    f"{match.other.kcal_100g:.0f}",
                ]
            )


if __name__ == "__main__":
    raise SystemExit(main())
