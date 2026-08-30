"""CoFID — McCance and Widdowson's Composition of Foods Integrated Dataset (UK).

About 2,900 foods from OHID. Open Government Licence v3: redistribution is
permitted with attribution and there is no share-alike clause.

Useful here for two reasons beyond raw coverage. It names British and
Commonwealth dishes USDA has no entry for at all, and its naming convention is
close enough to USDA's that a great many rows dedupe cleanly against the
existing merge rather than adding near-duplicates.
"""

from __future__ import annotations

from collections.abc import Iterator
from pathlib import Path

from models import FoodRecord, SourceInfo
from sources.base import download, parse_loose

_URL = (
    'https://assets.publishing.service.gov.uk/media/60538b91e90e07527df82ae4/'
    'McCance_Widdowsons_Composition_of_Foods_Integrated_Dataset_2021..xlsx'
)

#: Proximates carries the four figures this app needs. The other sheets are
#: inorganics, vitamins and fatty-acid fractions, none of which are tracked.
_SHEET = '1.3 Proximates'

#: The sheet has three header rows: a human title, a short code, and a repeat
#: of the title. Data starts on the fourth.
_HEADER_ROWS = 3


class CofidSource:
    info = SourceInfo(
        id='cofid',
        name="McCance and Widdowson's Composition of Foods (CoFID)",
        licence='Open Government Licence v3.0',
        attribution=(
            "McCance and Widdowson's Composition of Foods Integrated Dataset "
            '2021. Office for Health Improvement and Disparities. Contains '
            'public sector information licensed under the Open Government '
            'Licence v3.0.'
        ),
        url='https://www.gov.uk/government/publications/'
        'composition-of-foods-integrated-dataset-cofid',
        precedence=40,
        locale_hint='GB',
    )

    def _dir(self, cache: Path) -> Path:
        return cache / self.info.id

    def fetch(self, cache: Path) -> None:
        download(_URL, self._dir(cache) / 'cofid.xlsx', label=self.info.name)

    def records(self, cache: Path) -> Iterator[FoodRecord]:
        import openpyxl

        workbook = openpyxl.load_workbook(
            self._dir(cache) / 'cofid.xlsx',
            read_only=True,
            data_only=True,
        )
        sheet = workbook[_SHEET]

        rows = sheet.iter_rows(values_only=True)
        header = [str(h or '').strip().lower() for h in next(rows)]

        def find(fragment: str, *, exclude: str | None = None) -> int | None:
            for index, heading in enumerate(header):
                if fragment in heading:
                    if exclude and exclude in heading:
                        continue
                    return index
            return None

        code_col = find('food code')
        name_col = find('food name')
        # "Energy (kcal) (kcal)" sits immediately before "Energy (kJ) (kJ)".
        # Excluding the kJ heading is what stops a 4.184x error from being
        # imported wholesale.
        kcal_col = find('energy (kcal)', exclude='(kj)')
        protein_col = find('protein')
        fat_col = find('fat (g)')
        carbs_col = find('carbohydrate')

        if name_col is None or kcal_col is None:
            raise ValueError(
                f'CoFID layout changed: no name or kcal column in {header[:14]}'
            )

        # Skip the remaining header rows.
        for _ in range(_HEADER_ROWS - 1):
            next(rows, None)

        for row in rows:
            if name_col >= len(row):
                continue

            name = str(row[name_col] or '').strip()
            if not name:
                continue

            kcal = parse_loose(row[kcal_col]) if kcal_col < len(row) else None
            if kcal is None:
                continue

            yield FoodRecord(
                source=self.info.id,
                source_id=str(row[code_col] or '').strip()
                if code_col is not None and code_col < len(row)
                else name,
                name=name,
                kcal_100g=kcal,
                protein_100g=_at(row, protein_col),
                carbs_100g=_at(row, carbs_col),
                fat_100g=_at(row, fat_col),
                locale_hint=self.info.locale_hint,
                # CoFID's portion data lives in a separate publication that is
                # not part of this dataset, so these fall back to grams.
                portions=[],
            )


def _at(row: tuple, column: int | None) -> float:
    if column is None or column >= len(row):
        return 0.0
    return parse_loose(row[column]) or 0.0


COFID = CofidSource()
