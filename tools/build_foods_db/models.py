"""Shared types for the food database build.

Every source adapter converts its own format into `FoodRecord`, and nothing
downstream of the adapters needs to know where a row came from beyond its
`source` tag.
"""

from __future__ import annotations

from dataclasses import dataclass, field


@dataclass(frozen=True, slots=True)
class Portion:
    """A household measure, e.g. "1 cup" at 240 g."""

    label: str
    grams: float
    is_default: bool = False


@dataclass(slots=True)
class FoodRecord:
    """One food, normalised to per-100g macros.

    Only four macros are carried. The app tracks calories, protein, carbs and
    fat and nothing else, so micronutrients are dropped at the adapter rather
    than imported and ignored.
    """

    source: str
    source_id: str
    name: str

    kcal_100g: float
    protein_100g: float
    carbs_100g: float
    fat_100g: float

    #: 'IN', 'PK', 'GB', 'FR', 'CA', 'DK', 'US'. A ranking bias in the app,
    #: never a filter.
    locale_hint: str | None = None

    portions: list[Portion] = field(default_factory=list)

    #: Filled in by normalise.py. The FTS index and dedup both key on this.
    name_normalised: str = ""

    #: Preparation qualifiers split off the name, e.g. "cooked, boiled,
    #: drained, without salt". Kept out of the search name so it does not
    #: dominate the FTS index, but not discarded — it is real information.
    prep: str = ""

    @property
    def key(self) -> tuple[str, str]:
        return (self.source, self.source_id)


@dataclass(frozen=True, slots=True)
class SourceInfo:
    """Provenance and licensing for one dataset.

    Written into the shipped database's `meta` table, which is what the in-app
    Sources screen renders — so the screen can never disagree with what
    actually shipped.
    """

    id: str
    name: str
    licence: str

    #: The exact wording the licence requires. Rendered verbatim in the app.
    attribution: str

    url: str

    #: Lower wins when the same normalised name appears in several datasets.
    #: See dedup.py for the ordering and its rationale.
    precedence: int

    locale_hint: str | None = None
