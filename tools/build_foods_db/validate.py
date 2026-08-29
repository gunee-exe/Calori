"""Plausibility checks run over every record before it is written.

The point of this file is to make bad data loud. A silently wrong calorie
figure in a bundled database is worse than a missing food: the user cannot tell
it is wrong, and the app shows it with a source badge that says it is
authoritative.

But an over-eager validator is its own failure. The first version of this file
rejected lard, vodka and whole turkeys, and would have shipped a food database
with no cooking fats in it. So the checks are split three ways:

  * **repair** — defects with an unambiguous correct value, fixed silently.
  * **reject** — the record cannot be true, so it is quarantined for review.
  * **warn**   — surprising but legitimately possible; the record ships and the
                 warning is reported.

The defect that actually matters is a kilojoule value imported as kilocalories.
IFCT 2017 reports energy in kJ throughout, and several European tables carry
both columns. Reading kJ as kcal inflates a food 4.184x, which lands far above
the ceiling below.
"""

from __future__ import annotations

from dataclasses import dataclass

from models import FoodRecord, Portion

#: Pure fat is 900 kcal/100g by Atwater, and USDA reports 902 for oils, lard
#: and tallow. The ceiling sits just above that: high enough to keep every
#: cooking fat, low enough that a kJ value read as kcal — 4.184x too large, so
#: 1,600+ for anything calorie-dense — is still caught with enormous margin.
MAX_KCAL_100G = 920.0

#: USDA computes carbohydrate "by difference": 100 minus water, protein, fat
#: and ash, each measured independently. For meat and fish, where carbohydrate
#: is genuinely zero, accumulated rounding pushes the result slightly below it.
#: Chicken breast, pork chop, lamb and tuna all land near -0.5 g/100g.
#:
#: A small negative is clamped to zero rather than rejected. Anything more
#: negative is not rounding noise, it is a parse error, and still fails.
CARB_ROUNDING_SLACK = -1.0

#: A whole turkey is about 8 kg and a whole watermelon not much less, so the
#: cap on a single household portion has to be generous. Beyond this the number
#: is a unit error rather than a portion.
MAX_PORTION_GRAMS = 25_000.0

#: Atwater cross-check tolerance, used only to warn.
ATWATER_TOLERANCE = 0.25

#: Below this the percentage check is meaningless — a 3 kcal food misses a 25%
#: tolerance on rounding alone.
ATWATER_MIN_KCAL = 50.0


@dataclass(slots=True)
class Rejection:
    record: FoodRecord
    reason: str
    detail: str


@dataclass(slots=True)
class Warning:
    record: FoodRecord
    reason: str
    detail: str


def repair(record: FoodRecord) -> None:
    """Fix defects that have one obviously correct value.

    Mutates in place. Everything here is a measurement or encoding artefact
    rather than a claim about the food.
    """
    for field in ("protein_100g", "carbs_100g", "fat_100g"):
        value = getattr(record, field)
        if value is not None and CARB_ROUNDING_SLACK <= value < 0:
            setattr(record, field, 0.0)

    # An implausible portion costs the app one measure, not the whole food. A
    # turkey with a broken "1 lb" row is still a turkey.
    if record.portions:
        usable = [
            p for p in record.portions if 0 < p.grams <= MAX_PORTION_GRAMS
        ]
        if len(usable) != len(record.portions):
            if usable and not any(p.is_default for p in usable):
                usable[0] = Portion(usable[0].label, usable[0].grams, True)
            record.portions = usable


def check(record: FoodRecord) -> Rejection | None:
    """Return a rejection when the record cannot be true, else None."""

    if not record.name.strip():
        return Rejection(record, "no_name", "empty name")

    for label, value in (
        ("kcal_100g", record.kcal_100g),
        ("protein_100g", record.protein_100g),
        ("carbs_100g", record.carbs_100g),
        ("fat_100g", record.fat_100g),
    ):
        if value is None:
            return Rejection(record, "missing", f"{label} is missing")
        if value != value:  # NaN
            return Rejection(record, "nan", f"{label} is NaN")
        if value < 0:
            return Rejection(record, "negative", f"{label}={value}")
        if label != "kcal_100g" and value > 100:
            return Rejection(
                record, "macro_over_100", f"{label}={value:.1f}g per 100g"
            )

    if record.kcal_100g > MAX_KCAL_100G:
        return Rejection(
            record,
            "kcal_ceiling",
            f"{record.kcal_100g:.0f} kcal/100g exceeds {MAX_KCAL_100G:.0f}. "
            f"Most likely a kJ value imported without dividing by 4.184 "
            f"({record.kcal_100g / 4.184:.0f} kcal if so).",
        )

    macro_mass = record.protein_100g + record.carbs_100g + record.fat_100g
    if macro_mass > 100.5:  # half a gram of slack for rounding
        return Rejection(
            record,
            "mass_over_100",
            f"protein+carbs+fat = {macro_mass:.1f}g per 100g",
        )

    return None


def warnings_for(record: FoodRecord) -> list[Warning]:
    """Surprising but possible. The record ships; the warning is reported.

    A source whose warning count jumps between builds has probably changed
    format, which is worth seeing even when nothing is provably wrong.
    """
    found: list[Warning] = []
    macro_mass = record.protein_100g + record.carbs_100g + record.fat_100g

    if record.kcal_100g > ATWATER_MIN_KCAL and macro_mass == 0:
        # Spirits: the energy is ethanol, which this app does not model. Real
        # food, real calories, no macros to show for them.
        found.append(
            Warning(
                record,
                "energy_without_macros",
                f"{record.kcal_100g:.0f} kcal with no protein, carbs or fat — "
                f"probably alcohol",
            )
        )

    if record.kcal_100g >= ATWATER_MIN_KCAL and macro_mass > 0:
        atwater = (
            record.protein_100g * 4 + record.carbs_100g * 4 + record.fat_100g * 9
        )
        drift = abs(atwater - record.kcal_100g) / record.kcal_100g
        if drift > ATWATER_TOLERANCE:
            # Fibre counted as carbohydrate yields ~2 kcal/g rather than 4;
            # alcohol yields 7 and is invisible here; polyols land in between.
            # Several tables also use food-specific Atwater factors rather than
            # 4/4/9. All of these move the sum legitimately.
            found.append(
                Warning(
                    record,
                    "atwater_drift",
                    f"stated {record.kcal_100g:.0f} kcal vs {atwater:.0f} from "
                    f"macros ({drift:.0%} off)",
                )
            )

    return found


def partition(
    records: list[FoodRecord],
) -> tuple[list[FoodRecord], list[Rejection], list[Warning]]:
    """Repair, then split into kept and quarantined, collecting warnings.

    Quarantined rows go to a CSV for a human pass rather than being dropped
    silently — a source that suddenly quarantines thousands of rows has changed
    format, and that must be visible.
    """
    kept: list[FoodRecord] = []
    rejected: list[Rejection] = []
    warned: list[Warning] = []

    for record in records:
        repair(record)

        rejection = check(record)
        if rejection is not None:
            rejected.append(rejection)
            continue

        warned.extend(warnings_for(record))
        kept.append(record)

    return kept, rejected, warned
