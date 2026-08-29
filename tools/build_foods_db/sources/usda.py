"""USDA FoodData Central: SR Legacy, Foundation Foods, and FNDDS.

All three ship the same relational CSV layout, so one adapter serves them with
different URLs and precedence.

  * **SR Legacy** (7,793 foods, frozen at April 2018) is the generic backbone —
    raw ingredients and single foods.
  * **Foundation** (~370) is newer lab analysis of the same kind of food, so it
    outranks SR Legacy where they overlap.
  * **FNDDS / Survey** (5,431) is the one that matters most for this app:
    prepared and mixed dishes, which is what people actually photograph, plus
    by far the richest household-portion data of any source in the merge.

Licence: works of the U.S. Government, public domain. Attribution requested as
a courtesy, not required.
"""

from __future__ import annotations

from collections.abc import Iterator
from pathlib import Path

from models import FoodRecord, Portion, SourceInfo
from sources.base import (
    download,
    extract,
    kj_to_kcal,
    read_csv,
    to_float,
)

#: Only these files are unpacked. The survey archive also carries ingredient
#: linkage and attribute tables this build never reads.
_WANTED = [
    "food.csv",
    "food_nutrient.csv",
    "food_portion.csv",
    "measure_unit.csv",
    "nutrient.csv",
]

#: The nutrients this app tracks, keyed by role.
#:
#: Two numbering schemes are in play. SR Legacy and Foundation reference
#: FoodData Central's own nutrient ids (1008 for energy), while FNDDS
#: references the legacy SR `nutrient_nbr` values (208 for the same nutrient) —
#: in a column named `nutrient_id`, which is how this silently parses to zero
#: records rather than failing.
#:
#: Rather than hardcode both, each archive's own `nutrient.csv` is read and both
#: its `id` and `nutrient_nbr` are registered as aliases for the role. That is
#: robust if USDA renumbers again.
_ROLE_BY_FDC_ID = {
    "1008": "kcal",
    "1062": "kj",
    "1003": "protein",
    "1004": "fat",
    "1005": "carbs",
    "2047": "atwater_general",
    "2048": "atwater_specific",
}


class UsdaSource:
    """One FoodData Central dataset."""

    def __init__(self, info: SourceInfo, url: str, *, data_type: str | None = None):
        self.info = info
        self._url = url
        #: food.csv in a combined download can hold several data types; this
        #: keeps a dataset to its own rows.
        self._data_type = data_type

    # -- fetch --------------------------------------------------------------

    def _dir(self, cache: Path) -> Path:
        return cache / self.info.id

    def fetch(self, cache: Path) -> None:
        archive = download(
            self._url,
            self._dir(cache) / Path(self._url).name,
            label=self.info.name,
        )
        extract(archive, self._dir(cache) / "csv", members=_WANTED)

    # -- parse --------------------------------------------------------------

    def records(self, cache: Path) -> Iterator[FoodRecord]:
        csv_dir = self._dir(cache) / "csv"

        roles = self._read_roles(csv_dir / "nutrient.csv")
        names = self._read_names(csv_dir / "food.csv")
        nutrients = self._read_nutrients(
            csv_dir / "food_nutrient.csv", set(names), roles
        )
        portions = self._read_portions(csv_dir)

        for fdc_id, description in names.items():
            values = nutrients.get(fdc_id)
            if not values:
                continue

            kcal = self._energy(values)
            if kcal is None:
                continue

            yield FoodRecord(
                source=self.info.id,
                source_id=str(fdc_id),
                name=description,
                kcal_100g=kcal,
                protein_100g=values.get("protein", 0.0),
                carbs_100g=values.get("carbs", 0.0),
                fat_100g=values.get("fat", 0.0),
                locale_hint=self.info.locale_hint,
                portions=portions.get(fdc_id, []),
            )

    @staticmethod
    def _read_roles(path: Path) -> dict[str, str]:
        """Map every nutrient key this archive might use onto a role.

        Registers both the FDC `id` and the legacy `nutrient_nbr` so a
        `food_nutrient` row resolves whichever scheme it happens to use.
        """
        roles: dict[str, str] = dict(_ROLE_BY_FDC_ID)

        if not path.exists():
            return roles

        for row in read_csv(path):
            fdc_id = (row.get("id") or "").strip()
            role = _ROLE_BY_FDC_ID.get(fdc_id)
            if not role:
                continue

            number = (row.get("nutrient_nbr") or "").strip()
            if number:
                # Normalise "208.0" and "208" to the same key.
                roles[number] = role
                if number.endswith(".0"):
                    roles[number[:-2]] = role

        return roles

    @staticmethod
    def _energy(values: dict[str, float]) -> float | None:
        """Pick an energy figure, preferring a directly reported kcal.

        Foundation Foods often carries only the Atwater-derived figures, and
        some rows carry kilojoules alone. The kJ branch is the one that has to
        be right: reading kJ as kcal inflates a food 4.184x, which is exactly
        the defect validate.py's ceiling exists to catch.
        """
        for role in ("kcal", "atwater_specific", "atwater_general"):
            if role in values:
                return values[role]

        if "kj" in values:
            return kj_to_kcal(values["kj"])

        return None

    def _read_names(self, path: Path) -> dict[int, str]:
        names: dict[int, str] = {}
        for row in read_csv(path):
            if self._data_type and row.get("data_type") != self._data_type:
                continue
            description = (row.get("description") or "").strip()
            if not description:
                continue
            try:
                names[int(row["fdc_id"])] = description
            except (KeyError, ValueError):
                continue
        return names

    @staticmethod
    def _read_nutrients(
        path: Path,
        wanted_ids: set[int],
        roles: dict[str, str],
    ) -> dict[int, dict[str, float]]:
        """Stream food_nutrient.csv, keeping only the nutrients this app uses.

        This is the large file — 19 MB for FNDDS, far more for a combined
        download — so it is never materialised. Amounts in FDC are already
        per 100 g.
        """
        out: dict[int, dict[str, float]] = {}

        for row in read_csv(path):
            role = roles.get((row.get("nutrient_id") or "").strip())
            if role is None:
                continue

            try:
                fdc_id = int(row["fdc_id"])
            except (KeyError, ValueError):
                continue

            if fdc_id not in wanted_ids:
                continue

            out.setdefault(fdc_id, {})[role] = to_float(row.get("amount"))

        return out

    @staticmethod
    def _read_portions(csv_dir: Path) -> dict[int, list[Portion]]:
        """Build household portions from food_portion.csv.

        FDC splits a portion across three columns: an amount, a unit id, and a
        free-text description or modifier. Which of them is populated varies by
        dataset — FNDDS leans on portion_description, SR Legacy on the unit and
        modifier — so all three are consulted.
        """
        portion_path = csv_dir / "food_portion.csv"
        if not portion_path.exists():
            return {}

        units: dict[int, str] = {}
        unit_path = csv_dir / "measure_unit.csv"
        if unit_path.exists():
            for row in read_csv(unit_path):
                try:
                    units[int(row["id"])] = (row.get("name") or "").strip()
                except (KeyError, ValueError):
                    continue

        out: dict[int, list[Portion]] = {}

        for row in read_csv(portion_path):
            try:
                fdc_id = int(row["fdc_id"])
            except (KeyError, ValueError):
                continue

            grams = to_float(row.get("gram_weight"))
            if grams <= 0:
                continue

            label = UsdaSource._portion_label(row, units)
            if not label:
                continue

            bucket = out.setdefault(fdc_id, [])
            bucket.append(Portion(label=label, grams=grams, is_default=not bucket))

        return out

    @staticmethod
    def _portion_label(row: dict[str, str], units: dict[int, str]) -> str:
        description = (row.get("portion_description") or "").strip()
        modifier = (row.get("modifier") or "").strip()
        amount = to_float(row.get("amount"))

        unit_name = ""
        try:
            unit_id = int(row.get("measure_unit_id") or 0)
            unit_name = units.get(unit_id, "")
        except ValueError:
            pass

        # "undetermined" is FDC's placeholder for "no unit recorded".
        if unit_name in {"undetermined", ""}:
            unit_name = modifier

        if description and description.lower() != "quantity not specified":
            return description

        if amount and unit_name:
            return f"{amount:g} {unit_name}".strip()

        return unit_name or modifier


_FDC_DATASETS = "https://fdc.nal.usda.gov/fdc-datasets/"

SR_LEGACY = UsdaSource(
    SourceInfo(
        id="usda_sr",
        name="USDA FoodData Central — SR Legacy",
        licence="Public domain (U.S. Government work)",
        attribution=(
            "U.S. Department of Agriculture, Agricultural Research Service. "
            "FoodData Central, SR Legacy (April 2018)."
        ),
        url="https://fdc.nal.usda.gov/download-datasets/",
        precedence=31,
        locale_hint="US",
    ),
    f"{_FDC_DATASETS}FoodData_Central_sr_legacy_food_csv_2018-04.zip",
)

FOUNDATION = UsdaSource(
    SourceInfo(
        id="usda_foundation",
        name="USDA FoodData Central — Foundation Foods",
        licence="Public domain (U.S. Government work)",
        attribution=(
            "U.S. Department of Agriculture, Agricultural Research Service. "
            "FoodData Central, Foundation Foods (April 2026)."
        ),
        url="https://fdc.nal.usda.gov/download-datasets/",
        # Newer lab analysis than SR Legacy, so it wins where both describe the
        # same food.
        precedence=30,
        locale_hint="US",
    ),
    f"{_FDC_DATASETS}FoodData_Central_foundation_food_csv_2026-04-30.zip",
)

FNDDS = UsdaSource(
    SourceInfo(
        id="usda_fndds",
        name="USDA FoodData Central — FNDDS (Survey Foods)",
        licence="Public domain (U.S. Government work)",
        attribution=(
            "U.S. Department of Agriculture, Agricultural Research Service. "
            "FoodData Central, Survey Foods / FNDDS (October 2024)."
        ),
        url="https://fdc.nal.usda.gov/download-datasets/",
        # Prepared and mixed dishes outrank generic ingredients: someone
        # searching "lasagna" wants the dish, not a list of its components.
        precedence=20,
        locale_hint="US",
    ),
    f"{_FDC_DATASETS}FoodData_Central_survey_food_csv_2024-10-31.zip",
)
