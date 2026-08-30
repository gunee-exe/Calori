"""Source adapter protocol, plus download and extraction helpers.

One adapter per dataset. Adding or removing a source is a single file and a
single line in `build.py`, which is what keeps any individual dataset — INDB in
particular — cheap to pull if its licensing has to change.
"""

from __future__ import annotations

import csv
import re
import shutil
import sys
import urllib.request
import zipfile
from collections.abc import Iterator
from pathlib import Path
from typing import Protocol

from models import FoodRecord, SourceInfo

#: FoodData Central's nutrient ids. Stable across releases.
FDC_ENERGY_KCAL = 1008
FDC_ENERGY_KJ = 1062
FDC_PROTEIN = 1003
FDC_FAT = 1004
FDC_CARBS = 1005
#: Foundation Foods sometimes carries only the Atwater-derived energy figures.
FDC_ENERGY_ATWATER_GENERAL = 2047
FDC_ENERGY_ATWATER_SPECIFIC = 2048

#: FAO's factor. Not the rounded 4.2 — across a day of logging that rounding is
#: visible, and IFCT 2017 reports energy in kJ throughout.
KJ_PER_KCAL = 4.184


def kj_to_kcal(kj: float) -> float:
    return kj / KJ_PER_KCAL


class Source(Protocol):
    """A dataset adapter."""

    info: SourceInfo

    def fetch(self, cache: Path) -> None:
        """Download whatever this source needs into `cache`.

        Must be idempotent — a second run with a populated cache should do
        nothing and cost nothing.
        """
        ...

    def records(self, cache: Path) -> Iterator[FoodRecord]:
        """Yield every usable food, with macros already per-100g."""
        ...


class ManualDownloadRequired(RuntimeError):
    """Raised when a dataset cannot be fetched without a human.

    Some sources sit behind a registration wall or are published only as a PDF.
    Rather than failing obscurely mid-build, the adapter raises this with
    instructions, and `build.py` reports it as a skipped source instead of
    aborting the whole run.
    """

    def __init__(self, source_id: str, instructions: str) -> None:
        super().__init__(instructions)
        self.source_id = source_id
        self.instructions = instructions


def download(url: str, target: Path, *, label: str = "") -> Path:
    """Fetch `url` to `target` unless it is already there.

    Downloads to a temporary name and renames on completion, so an interrupted
    run cannot leave a truncated file that the next run mistakes for a complete
    one.
    """
    if target.exists() and target.stat().st_size > 0:
        size_mb = target.stat().st_size / 1_048_576
        print(f"  cached  {target.name} ({size_mb:.1f} MB)")
        return target

    target.parent.mkdir(parents=True, exist_ok=True)
    partial = target.with_suffix(target.suffix + ".part")

    print(f"  fetch   {label or target.name}")
    print(f"          {url}")

    request = urllib.request.Request(
        url, headers={"User-Agent": "calori-foods-db-builder/1.0"}
    )

    with urllib.request.urlopen(request) as response, partial.open("wb") as out:
        total = int(response.headers.get("Content-Length") or 0)
        done = 0
        while chunk := response.read(1 << 20):
            out.write(chunk)
            done += len(chunk)
            if total:
                pct = done * 100 // total
                print(
                    f"\r          {done / 1_048_576:7.1f} / "
                    f"{total / 1_048_576:.1f} MB  {pct:3d}%",
                    end="",
                    file=sys.stdout,
                    flush=True,
                )
        print()

    partial.rename(target)
    return target


def extract(archive: Path, into: Path, *, members: list[str] | None = None) -> Path:
    """Unzip `archive` into `into`, skipping work already done.

    `members` selects individual files by suffix match. FNDDS unzips to 1.6 GB,
    almost all of it tables this build never reads, so pulling out only the
    handful that matter saves both time and a lot of disk.
    """
    marker = into / ".extracted"
    if marker.exists():
        print(f"  cached  {archive.name} already extracted")
        return into

    into.mkdir(parents=True, exist_ok=True)
    print(f"  unzip   {archive.name}")

    with zipfile.ZipFile(archive) as zf:
        names = zf.namelist()
        if members is not None:
            wanted = [
                n
                for n in names
                if any(n.endswith(m) for m in members) and not n.endswith("/")
            ]
        else:
            wanted = [n for n in names if not n.endswith("/")]

        for name in wanted:
            destination = into / Path(name).name
            with zf.open(name) as src, destination.open("wb") as dst:
                shutil.copyfileobj(src, dst)

    marker.write_text("ok", encoding="utf-8")
    return into


def read_csv(path: Path) -> Iterator[dict[str, str]]:
    """Stream a CSV as dicts.

    FoodData Central's `food_nutrient.csv` runs to millions of rows, so nothing
    in this pipeline loads a CSV into memory whole.
    """
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        yield from csv.DictReader(handle)


#: Markers national tables use for "below the limit of quantification".
#: They mean present-but-negligible, which for this app is zero — but they must
#: be recognised rather than falling through to "missing" and dropping a food.
_TRACE = re.compile(r"^\s*(traces?|tr|<\s*[\d,.]+)\s*$", re.IGNORECASE)

#: Markers for "not measured". Genuinely unknown, which is *not* zero.
_UNKNOWN = {"", "-", "n", "nd", "n.d.", "na", "n/a"}


def parse_loose(raw: object) -> float | None:
    """Parse a number from a national food table.

    Returns None when the value is unknown and 0.0 when it is a trace. The
    distinction decides whether a food is dropped or merely has a zero in one
    column, so it is worth keeping.

    Handles the French decimal comma, non-breaking spaces used as thousands
    separators, and numbers stored as text — all three appear in CIQUAL and
    CoFID, sometimes in the same column.
    """
    if isinstance(raw, (int, float)):
        return float(raw)

    text = str(raw or "").strip()
    if text.lower() in _UNKNOWN:
        return None
    if _TRACE.match(text):
        return 0.0

    text = text.replace(" ", "").replace(" ", "").replace(",", ".")
    try:
        return float(text)
    except ValueError:
        return None


def to_float(value: str | None, default: float = 0.0) -> float:
    """Parse a CSV cell, tolerating blanks and stray whitespace."""
    if value is None:
        return default
    text = value.strip()
    if not text:
        return default
    try:
        return float(text)
    except ValueError:
        return default
