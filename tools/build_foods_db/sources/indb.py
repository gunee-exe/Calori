"""Indian Nutrient Databank — 1,014 commonly eaten Indian recipes.

The single most valuable source in the merge for this app's purpose. USDA knows
what "rice, white, cooked" is; it does not know what a plate of chicken biryani
or a bowl of sambar weighs, and those are what people actually photograph and
search for. INDB gives both the composition and the household unit — "1 bowl",
"1 plate", "1 roti" — which is exactly the vocabulary UC-05 asks the portion
picker to speak.

Built on ICMR-NIN's IFCT 2017 and 2004, with gaps filled from UK and US tables.

LICENSING — READ THIS BEFORE SHIPPING
-------------------------------------
The INDB repository has **no LICENSE file**, which under GitHub's terms means
all rights reserved. The open-access licence on the *paper* does not license the
*dataset*. `03-food-data.md` §7 records the decision to use it anyway, with
these mitigations, which are conditions rather than suggestions:

  * attribute the paper and the repo in DATA-LICENSES.md and the Sources screen;
  * email the authors for written permission — still outstanding;
  * keep this file swappable, so removing INDB is one deletion in build.py and
    a rebuild.

`github.com/ifct2017/ifct2017` is not the easy alternative it looks like: it
relicensed to AGPL-3.0 in April 2025, which is a worse trap in a distributed
mobile app.
"""

from __future__ import annotations

from collections.abc import Iterator
from pathlib import Path

from models import FoodRecord, Portion, SourceInfo
from sources.base import download

_URL = (
    'https://github.com/lindsayjaacks/Indian-Nutrient-Databank-INDB-'
    '/raw/main/INDB.xlsx'
)

_SHEET = 'Nutrient Data'

#: Serving units that describe a container or a whole item rather than a
#: measured quantity. These make good portion labels; a bare number does not.
_UNIT_ARTICLE = {'a', 'an', 'one', '1'}


class IndbSource:
    info = SourceInfo(
        id='indb',
        name='Indian Nutrient Databank (INDB)',
        licence='No declared licence — see 03-food-data.md §7',
        attribution=(
            'Indian Nutrient Databank (INDB). Jaacks LM et al., Development of '
            'an Indian Food Composition Database, Current Developments in '
            'Nutrition (2024). Built on ICMR-NIN Indian Food Composition '
            'Tables 2017 and 2004.'
        ),
        url='https://github.com/lindsayjaacks/Indian-Nutrient-Databank-INDB-',
        # Beats every USDA dataset for Indian dishes. A search for "biryani"
        # should find the Indian recipe, not FNDDS's American approximation of
        # one.
        precedence=10,
        locale_hint='IN',
    )

    def _dir(self, cache: Path) -> Path:
        return cache / self.info.id

    def fetch(self, cache: Path) -> None:
        download(_URL, self._dir(cache) / 'INDB.xlsx', label=self.info.name)

    def records(self, cache: Path) -> Iterator[FoodRecord]:
        # Imported lazily so the whole build does not require openpyxl when
        # only the USDA sources are selected.
        import openpyxl

        path = self._dir(cache) / 'INDB.xlsx'
        workbook = openpyxl.load_workbook(path, read_only=True, data_only=True)
        sheet = workbook[_SHEET]

        rows = sheet.iter_rows(values_only=True)
        header = [str(h) if h is not None else '' for h in next(rows)]
        column = {name: index for index, name in enumerate(header)}

        def value(row: tuple, name: str) -> float | None:
            index = column.get(name)
            if index is None or index >= len(row):
                return None
            cell = row[index]
            if isinstance(cell, (int, float)):
                return float(cell)
            return None

        for row in rows:
            name_index = column.get('food_name')
            if name_index is None:
                continue

            name = str(row[name_index] or '').strip()
            if not name:
                continue

            # INDB carries both energy_kj and energy_kcal. Taking kcal directly
            # is the whole point: reading the kJ column as kcal inflates every
            # Indian food 4.184x, and IFCT 2017 reports kJ throughout, so this
            # is precisely where that mistake gets made.
            kcal = value(row, 'energy_kcal')
            if kcal is None:
                kj = value(row, 'energy_kj')
                if kj is None:
                    continue
                kcal = kj / 4.184

            code = column.get('food_code')
            yield FoodRecord(
                source=self.info.id,
                source_id=str(row[code]) if code is not None else name,
                name=name,
                kcal_100g=kcal,
                protein_100g=value(row, 'protein_g') or 0.0,
                carbs_100g=value(row, 'carb_g') or 0.0,
                fat_100g=value(row, 'fat_g') or 0.0,
                locale_hint=self.info.locale_hint,
                portions=self._portion(row, column, kcal),
            )

    @staticmethod
    def _portion(
        row: tuple,
        column: dict[str, int],
        kcal_100g: float,
    ) -> list[Portion]:
        """Derive the serving weight from the serving's energy.

        INDB gives a serving's nutrients but not its weight. Since the per-100g
        energy is also given, the weight follows:

            grams = 100 * serving_kcal / kcal_100g

        This is exact rather than an approximation — both figures come from the
        same underlying quantity — and it is the only way to get "1 bowl" to
        mean a number of grams the app can scale.
        """
        unit_index = column.get('servings_unit')
        serving_index = column.get('unit_serving_energy_kcal')
        if unit_index is None or serving_index is None:
            return []

        unit = str(row[unit_index] or '').strip()
        serving_kcal = row[serving_index]

        if not unit or not isinstance(serving_kcal, (int, float)):
            return []
        if kcal_100g <= 0:
            return []

        grams = 100.0 * float(serving_kcal) / kcal_100g
        if not (0 < grams <= 5000):
            return []

        first = unit.split()[0].lower()
        label = unit if first in _UNIT_ARTICLE else f'1 {unit}'

        return [Portion(label=label, grams=round(grams, 1), is_default=True)]


INDB = IndbSource()
