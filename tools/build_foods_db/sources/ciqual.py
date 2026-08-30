"""CIQUAL — the French national food composition table (ANSES).

About 3,190 foods. Licence Ouverte / Etalab 2.0: redistribution is permitted
with attribution, and there is no share-alike clause, so it can live in the
permissive `foods.sqlite` rather than the later share-alike pack.

**Names are French only.** This version of the table has no English column, so
CIQUAL contributes French-language coverage rather than more English synonyms —
"pain de mie", "crème fraîche", "cassoulet". That is additive: it does not
compete with the USDA rows for an English query, because the tokens differ. It
is also why `remove_diacritics 2` on the FTS index matters, and why this source
sits at a low precedence — where a French and an English name do normalise to
the same string, the English row should win for the app's main audience.
"""

from __future__ import annotations

import re
from collections.abc import Iterator
from pathlib import Path

from models import FoodRecord, SourceInfo
from sources.base import download

_URL = (
    'https://ciqual.anses.fr/cms/sites/default/files/inline-files/'
    'Table%20Ciqual%202020_FR_2020%2007%2007.xls'
)

#: Column headings, matched case-insensitively on a distinctive fragment
#: because ANSES's headings carry regulation references and inconsistent
#: double spaces that make exact matching brittle across releases.
_NAME = 'alim_nom_fr'
_CODE = 'alim_code'
_KCAL = 'energie, règlement ue'
_KJ_MARKER = 'kj/100'
_PROTEIN = 'protéines, n x 6.25'
_CARBS = 'glucides (g/100'
_FAT = 'lipides (g/100'

#: CIQUAL marks a value below the limit of quantification as "traces" or
#: "< 0,5". Both mean "present but negligible", which for this app's purposes
#: is zero — but they must be recognised rather than falling through a
#: float() and being dropped as missing.
_TRACE = re.compile(r'^\s*(traces?|<\s*[\d,.]+)\s*$', re.IGNORECASE)

#: "-" is not-measured and "" is not-applicable. Both are genuinely unknown,
#: which is different from zero and must not be silently turned into one.
_MISSING = {'', '-', 'nd', 'n.d.'}


def parse_number(raw: object) -> float | None:
    """Parse a CIQUAL cell.

    Returns None for genuinely unknown values and 0.0 for trace amounts. The
    distinction matters: a missing energy figure should drop the food, while a
    trace of fat should not.
    """
    if isinstance(raw, (int, float)):
        return float(raw)

    text = str(raw or '').strip()
    if text.lower() in _MISSING:
        return None
    if _TRACE.match(text):
        return 0.0

    # French decimal comma, and a non-breaking space as a thousands separator.
    text = text.replace('\xa0', '').replace(' ', '').replace(',', '.')
    try:
        return float(text)
    except ValueError:
        return None


class CiqualSource:
    info = SourceInfo(
        id='ciqual',
        name='CIQUAL — French food composition table (ANSES)',
        licence='Licence Ouverte / Open Licence 2.0 (Etalab)',
        attribution=(
            'ANSES-CIQUAL French food composition table, 2020. '
            'Agence nationale de sécurité sanitaire de l\'alimentation, de '
            'l\'environnement et du travail. Licence Ouverte 2.0.'
        ),
        url='https://ciqual.anses.fr/',
        precedence=41,
        locale_hint='FR',
    )

    def _dir(self, cache: Path) -> Path:
        return cache / self.info.id

    def fetch(self, cache: Path) -> None:
        download(_URL, self._dir(cache) / 'ciqual.xls', label=self.info.name)

    def records(self, cache: Path) -> Iterator[FoodRecord]:
        import xlrd

        book = xlrd.open_workbook(self._dir(cache) / 'ciqual.xls')
        sheet = book.sheet_by_index(0)

        header = [str(h).strip() for h in sheet.row_values(0)]
        lowered = [h.lower() for h in header]

        def find(fragment: str, *, exclude: str | None = None) -> int | None:
            for index, heading in enumerate(lowered):
                if fragment in heading:
                    if exclude and exclude in heading:
                        continue
                    return index
            return None

        name_col = find(_NAME)
        code_col = find(_CODE)
        # The energy heading appears twice, once in kJ and once in kcal. Taking
        # the first match would silently import kilojoules as kilocalories and
        # inflate every French food 4.184x.
        kcal_col = find(_KCAL, exclude=_KJ_MARKER)
        protein_col = find(_PROTEIN)
        carbs_col = find(_CARBS)
        fat_col = find(_FAT)

        if name_col is None or kcal_col is None:
            raise ValueError(
                'CIQUAL layout changed: could not find the name or kcal '
                f'column in {header[:12]}'
            )

        for index in range(1, sheet.nrows):
            row = sheet.row_values(index)

            name = str(row[name_col] or '').strip()
            if not name:
                continue

            kcal = parse_number(row[kcal_col])
            if kcal is None:
                # Roughly a sixth of the table has no EU-regulation energy
                # figure. Those rows are skipped rather than back-calculated:
                # a derived value here would be indistinguishable from a
                # measured one downstream.
                continue

            yield FoodRecord(
                source=self.info.id,
                source_id=str(row[code_col]).strip() if code_col is not None else name,
                name=name,
                kcal_100g=kcal,
                protein_100g=_or_zero(row, protein_col),
                carbs_100g=_or_zero(row, carbs_col),
                fat_100g=_or_zero(row, fat_col),
                locale_hint=self.info.locale_hint,
                # CIQUAL publishes no household portions. Foods from this
                # source fall back to grams in the portion picker.
                portions=[],
            )


def _or_zero(row: list, column: int | None) -> float:
    if column is None:
        return 0.0
    return parse_number(row[column]) or 0.0


CIQUAL = CiqualSource()
