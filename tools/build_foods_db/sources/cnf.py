"""Canadian Nutrient File — Health Canada.

About 5,690 foods, and unusually rich household measures: CNF ships a
CONVERSION FACTOR table mapping each food to named measures, which is exactly
the "1 cup", "1 medium" data the portion picker wants and which most national
tables do not publish at all.

Licence: Open Government Licence — Canada. Redistribution permitted with
attribution, no share-alike.

DOWNLOADING
-----------
`canada.ca` would not serve the archive to this build (the direct link times
out, and the open.canada.ca mirror returns a redirect page), so this adapter
asks for the file rather than pretending it can fetch it. Drop the zip in
`.cache/cnf/cnf.zip` and re-run; everything below then works unattended.

The zip is linked from:
https://www.canada.ca/en/health-canada/services/food-nutrition/healthy-eating/nutrient-data/canadian-nutrient-file-2015-download-files.html
"""

from __future__ import annotations

import csv
import io
import zipfile
from collections.abc import Iterator
from pathlib import Path

from models import FoodRecord, Portion, SourceInfo
from sources.base import ManualDownloadRequired, parse_loose

#: CNF uses the legacy SR nutrient numbering, the same scheme FNDDS uses and a
#: different one from FoodData Central's own ids. See sources/usda.py.
_KCAL = '208'
_PROTEIN = '203'
_FAT = '204'
_CARBS = '205'

#: The archive's member names vary in case and spacing between releases, so
#: they are matched on a lowercased, space-stripped fragment.
_FOOD_NAME = 'foodname'
_NUTRIENT_AMOUNT = 'nutrientamount'
_NUTRIENT_NAME = 'nutrientname'
_CONVERSION = 'conversionfactor'
_MEASURE = 'measurename'


class CnfSource:
    info = SourceInfo(
        id='cnf',
        name='Canadian Nutrient File (CNF)',
        licence='Open Government Licence — Canada',
        attribution=(
            'Canadian Nutrient File, 2015. Health Canada. Contains '
            'information licensed under the Open Government Licence — Canada.'
        ),
        url='https://www.canada.ca/en/health-canada/services/food-nutrition/'
        'healthy-eating/nutrient-data/canadian-nutrient-file-2015-download-'
        'files.html',
        precedence=42,
        locale_hint='CA',
    )

    def _archive(self, cache: Path) -> Path:
        return cache / self.info.id / 'cnf.zip'

    def _require(self, cache: Path) -> Path:
        archive = self._archive(cache)
        # Size-checked, not just existence-checked: a failed download leaves a
        # few hundred bytes of redirect HTML named cnf.zip, and "not a zip
        # file" three frames deep is a worse message than the instructions.
        if archive.exists() and archive.stat().st_size > 100_000:
            return archive

        raise ManualDownloadRequired(
            self.info.id,
            'CNF must be downloaded by hand: canada.ca does not serve the '
            'archive to this build. Get the CSV zip from\n'
            f'          {self.info.url}\n'
            f'          and save it as {archive}',
        )

    def fetch(self, cache: Path) -> None:
        print(f'  cached  {self._require(cache).name}')

    def records(self, cache: Path) -> Iterator[FoodRecord]:
        # Checked here too, not only in fetch(): `--skip-download` never calls
        # fetch, and without this a missing file surfaces as a bare
        # FileNotFoundError and "see traceback" instead of the instructions.
        with zipfile.ZipFile(self._require(cache)) as archive:
            names = {
                _key(n): n for n in archive.namelist() if n.lower().endswith('.csv')
            }

            def table(fragment: str) -> list[dict[str, str]]:
                match = next(
                    (real for key, real in names.items() if fragment in key),
                    None,
                )
                if match is None:
                    raise ValueError(
                        f'CNF archive has no {fragment} table; found '
                        f'{sorted(names)}'
                    )
                return _read(archive, match)

            nutrients = self._nutrient_ids(table(_NUTRIENT_NAME))
            amounts = self._amounts(table(_NUTRIENT_AMOUNT), nutrients)
            portions = self._portions(table(_CONVERSION), table(_MEASURE))

            for row in table(_FOOD_NAME):
                food_id = _get(row, 'FoodID')
                name = _get(row, 'FoodDescription').strip()
                if not food_id or not name:
                    continue

                values = amounts.get(food_id)
                if not values or _KCAL not in values:
                    continue

                yield FoodRecord(
                    source=self.info.id,
                    source_id=food_id,
                    name=name,
                    kcal_100g=values[_KCAL],
                    protein_100g=values.get(_PROTEIN, 0.0),
                    carbs_100g=values.get(_CARBS, 0.0),
                    fat_100g=values.get(_FAT, 0.0),
                    locale_hint=self.info.locale_hint,
                    portions=portions.get(food_id, []),
                )

    @staticmethod
    def _nutrient_ids(rows: list[dict[str, str]]) -> dict[str, str]:
        """Map CNF's internal NutrientID onto the legacy nutrient code.

        The amount table keys on NutrientID, which is an arbitrary row number,
        while the code (208 for energy) is what is stable across releases.
        """
        out: dict[str, str] = {}
        for row in rows:
            nutrient_id = _get(row, 'NutrientID')
            code = _get(row, 'NutrientCode').strip()
            if nutrient_id and code:
                out[nutrient_id] = code
        return out

    @staticmethod
    def _amounts(
        rows: list[dict[str, str]],
        nutrients: dict[str, str],
    ) -> dict[str, dict[str, float]]:
        wanted = {_KCAL, _PROTEIN, _FAT, _CARBS}
        out: dict[str, dict[str, float]] = {}

        for row in rows:
            code = nutrients.get(_get(row, 'NutrientID'))
            if code not in wanted:
                continue

            food_id = _get(row, 'FoodID')
            value = parse_loose(_get(row, 'NutrientValue'))
            if not food_id or value is None:
                continue

            out.setdefault(food_id, {})[code] = value

        return out

    @staticmethod
    def _portions(
        conversions: list[dict[str, str]],
        measures: list[dict[str, str]],
    ) -> dict[str, list[Portion]]:
        """Turn CNF's conversion factors into household portions.

        CNF states nutrients per 100 g and gives each measure a factor to
        convert from that, so the measure's weight is simply the factor times
        100. That is the same trick INDB needs, arrived at from the other
        direction.
        """
        names = {
            _get(m, 'MeasureID'): _get(m, 'MeasureDescription').strip()
            for m in measures
        }

        out: dict[str, list[Portion]] = {}
        for row in conversions:
            food_id = _get(row, 'FoodID')
            label = names.get(_get(row, 'MeasureID'), '').strip()
            factor = parse_loose(_get(row, 'ConversionFactorValue'))

            if not food_id or not label or factor is None:
                continue

            grams = factor * 100
            if not (0 < grams <= 5000):
                continue

            bucket = out.setdefault(food_id, [])
            # Six is plenty for a picker; CNF lists as many as twenty for some
            # foods, most of them minor variants of each other.
            if len(bucket) < 6:
                bucket.append(
                    Portion(
                        label=label,
                        grams=round(grams, 1),
                        is_default=not bucket,
                    )
                )

        return out


def _key(name: str) -> str:
    return Path(name).name.lower().replace(' ', '').replace('_', '')


def _get(row: dict[str, str], field: str) -> str:
    """Read a column, tolerating case and whitespace drift in the header."""
    if field in row:
        return row[field] or ''
    target = field.lower()
    for key, value in row.items():
        if key and key.strip().lower() == target:
            return value or ''
    return ''


def _read(archive: zipfile.ZipFile, member: str) -> list[dict[str, str]]:
    raw = archive.read(member)
    # CNF ships cp1252, not UTF-8: French accents in the bilingual columns are
    # the giveaway. Decoding as UTF-8 raises rather than mojibake-ing, so this
    # is explicit.
    text = raw.decode('utf-8-sig', errors='strict') if _is_utf8(raw) else raw.decode(
        'cp1252', errors='replace'
    )
    return list(csv.DictReader(io.StringIO(text)))


def _is_utf8(raw: bytes) -> bool:
    try:
        raw.decode('utf-8')
        return True
    except UnicodeDecodeError:
        return False


CNF = CnfSource()
