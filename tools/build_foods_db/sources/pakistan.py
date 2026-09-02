"""Food Composition Table for Pakistan (revised 2001).

177 foods, and the only source in this merge carrying the dishes people here
actually eat: haleem, shami kabab, chapal kabab, sajji, zarda, kalool, alu
ghosht. No US or UK table has any of them, and INDB -- the next most regional
source -- has none of these either.

Each food also carries its Urdu name, folded into the search name so both
spellings find it. That is not decoration: `chana`, `daal` and `qeema` returned
nothing at all before this, because the merged database held only *channa*,
*dal* and *keema*.

READING THE FILE
----------------
The published table is a scanned PDF with no text layer, so it cannot be parsed
at all. This adapter reads a transcribed spreadsheet instead, placed by hand at
`.cache/pakistan_fct/pakistan_fct.xlsx`.

xlsx is a zip of XML, so no third-party reader is needed and none is used --
the rest of this pipeline is stdlib-only and stays that way. Both storage forms
for strings are handled: inline (`t="inlineStr"`) and the shared-string table.
Supporting only the one the current file happens to use would mean a re-export
from a different tool parses to zero records without erroring, which is exactly
how the FNDDS adapter failed once already.

LICENCE
-------
FAO-hosted, published by the Government of Pakistan with UNICEF. Reuse terms
are **not yet confirmed** -- see DATA-LICENSES.md. Verify before a public
release build.
"""

from __future__ import annotations

import re
import xml.etree.ElementTree as ET
import zipfile
from collections.abc import Iterator
from pathlib import Path

from models import FoodRecord, SourceInfo
from sources.base import ManualDownloadRequired, parse_loose

_NS = "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}"

#: Column headings, matched with punctuation and spacing stripped so a
#: re-export that writes "Lipid(Fat) g" still resolves -- while a genuinely
#: missing column raises rather than importing a column of zeroes.
_ENGLISH = "english"
_URDU = "urdu"
_KCAL = "foodenergykcal"
_PROTEIN = "proteing"
_FAT = "lipidfatg"
_CARBS = "carbohydrateg"
_ID = "srno"

#: What the sheet uses for "no Urdu name for this one" -- every cooked dish.
_ABSENT = {"", "-", "n/a", "na"}


class PakistanSource:
    info = SourceInfo(
        id="pakistan_fct",
        name="Food Composition Table for Pakistan (revised 2001)",
        licence="FAO-hosted; reuse terms unconfirmed - see DATA-LICENSES.md",
        attribution=(
            "Food Composition Table for Pakistan (revised 2001). Department of "
            "Agricultural Chemistry and Human Nutrition, NWFP Agricultural "
            "University Peshawar, with UNICEF Islamabad and the Ministry of "
            "Planning and Development, Government of Pakistan."
        ),
        url=(
            "https://www.fao.org/fileadmin/templates/food_composition/"
            "documents/regional/Book_Food_Composition_Table_for_Pakistan_.pdf"
        ),
        # Just behind INDB. Both are regional and INDB is newer and far more
        # granular, but the rows that matter most here -- the cooked dishes --
        # have no competition at any precedence.
        precedence=11,
        locale_hint="PK",
    )

    def _archive(self, cache: Path) -> Path:
        return cache / self.info.id / "pakistan_fct.xlsx"

    def _require(self, cache: Path) -> Path:
        archive = self._archive(cache)
        if archive.exists() and archive.stat().st_size > 4_000:
            return archive

        raise ManualDownloadRequired(
            self.info.id,
            "The Pakistan FCT is published only as a scanned PDF, which cannot "
            "be parsed. This adapter needs a transcribed spreadsheet carrying "
            "English, Urdu, Food Energy K.cal, Protein g, Lipid (Fat) g and "
            f"Carbohydrate g columns, saved as\n          {archive}\n"
            f"          The scan itself is at {self.info.url}",
        )

    def fetch(self, cache: Path) -> None:
        print(f"  cached  {self._require(cache).name}")

    def records(self, cache: Path) -> Iterator[FoodRecord]:
        # Checked here too, not only in fetch(): `--skip-download` never calls
        # fetch, and a missing file would otherwise surface as a bare
        # FileNotFoundError instead of the instructions above.
        rows = _sheet(self._require(cache))
        if not rows:
            raise ValueError("the Pakistan spreadsheet has no rows")

        header = {_key(text): column for column, text in rows[0].items() if text}
        for required in (_ENGLISH, _KCAL, _PROTEIN, _FAT, _CARBS):
            if required not in header:
                raise ValueError(
                    f"the Pakistan spreadsheet has no {required!r} column; "
                    f"found {sorted(header)}"
                )

        def cell(row: dict[str, str], field: str) -> str:
            column = header.get(field)
            return row.get(column, "") if column else ""

        for index, row in enumerate(rows[1:], start=1):
            english = cell(row, _ENGLISH).strip()
            if not english:
                continue

            kcal = parse_loose(cell(row, _KCAL))
            if kcal is None:
                continue

            yield FoodRecord(
                source=self.info.id,
                source_id=cell(row, _ID).strip() or str(index),
                name=_name(english, cell(row, _URDU)),
                kcal_100g=kcal,
                protein_100g=parse_loose(cell(row, _PROTEIN)) or 0.0,
                carbs_100g=parse_loose(cell(row, _CARBS)) or 0.0,
                fat_100g=parse_loose(cell(row, _FAT)) or 0.0,
                locale_hint=self.info.locale_hint,
                # This table publishes no household measures. Inventing one
                # would be worse than the picker's 100 g fallback.
                portions=[],
            )


def _name(english: str, urdu: str) -> str:
    """`Chickpea Raw` + `Channa` -> `Chickpea Raw (Channa)`.

    The brackets are load-bearing only in that FTS5's unicode61 tokenizer treats
    them as separators, so the result is findable by either word. `normalise()`
    strips them as well, so the stored name_normalised is `chickpea raw channa`.
    """
    urdu = urdu.strip()
    if not urdu or urdu.lower() in _ABSENT:
        return english
    if urdu.lower() in english.lower():
        return english
    return f"{english} ({urdu})"


def _key(heading: str) -> str:
    """Reduce a heading to letters and digits, so spacing and punctuation drift
    between exports cannot break the column lookup."""
    return re.sub(r"[^a-z0-9]", "", heading.lower())


def _sheet(path: Path) -> list[dict[str, str]]:
    """Read the first worksheet as a list of {column letter: text}."""
    with zipfile.ZipFile(path) as archive:
        shared = _shared_strings(archive)

        name = next(
            (n for n in archive.namelist() if n.startswith("xl/worksheets/sheet")),
            None,
        )
        if name is None:
            raise ValueError("the Pakistan spreadsheet has no worksheet")

        with archive.open(name) as handle:
            root = ET.parse(handle).getroot()

    data = root.find(f"{_NS}sheetData")
    if data is None:
        return []

    return [_row(row, shared) for row in data.findall(f"{_NS}row")]


def _shared_strings(archive: zipfile.ZipFile) -> list[str]:
    if "xl/sharedStrings.xml" not in archive.namelist():
        return []

    with archive.open("xl/sharedStrings.xml") as handle:
        root = ET.parse(handle).getroot()

    # A shared string can be split across several runs, so every descendant <t>
    # is joined rather than only the first taken.
    return [
        "".join(t.text or "" for t in si.iter(f"{_NS}t"))
        for si in root.findall(f"{_NS}si")
    ]


def _row(row: ET.Element, shared: list[str]) -> dict[str, str]:
    out: dict[str, str] = {}
    for cell in row.findall(f"{_NS}c"):
        column = re.match(r"[A-Z]+", cell.get("r") or "")
        if column is None:
            continue

        kind = cell.get("t")
        if kind == "inlineStr":
            block = cell.find(f"{_NS}is")
            text = (
                "".join(t.text or "" for t in block.iter(f"{_NS}t"))
                if block is not None
                else ""
            )
        elif kind == "s":
            value = cell.find(f"{_NS}v")
            index = int(value.text) if value is not None and value.text else -1
            text = shared[index] if 0 <= index < len(shared) else ""
        else:
            value = cell.find(f"{_NS}v")
            text = (value.text or "") if value is not None else ""

        out[column.group()] = text

    return out


PAKISTAN = PakistanSource()
