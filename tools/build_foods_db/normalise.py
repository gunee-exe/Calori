"""Name normalisation.

Two jobs, and they are different:

  * `normalise()` produces the key used for cross-source deduplication and for
    matching AI-returned names against `food_cache` on the device. It must be
    aggressive and stable.

  * `split_prep()` pulls USDA's trailing preparation qualifiers off the display
    name. USDA descriptions read "Beans, snap, green, cooked, boiled, drained,
    without salt" — leaving that intact makes every FTS query fight a wall of
    shared tokens, and makes the search results list unreadable.
"""

from __future__ import annotations

import re
import unicodedata

#: Qualifiers that describe preparation or state rather than identity. Order
#: matters only in that longer phrases must be tried before their prefixes.
_PREP_TERMS = frozenset(
    {
        "raw",
        "cooked",
        "boiled",
        "steamed",
        "baked",
        "broiled",
        "grilled",
        "roasted",
        "fried",
        "stewed",
        "braised",
        "microwaved",
        "drained",
        "undrained",
        "rinsed",
        "unprepared",
        "prepared",
        "dry",
        "dried",
        "dehydrated",
        "frozen",
        "canned",
        "unheated",
        "reheated",
        "with salt",
        "without salt",
        "unsalted",
        "salted",
        "sweetened",
        "unsweetened",
        "enriched",
        "unenriched",
        "fortified",
        "unfortified",
        "commercially prepared",
        "home prepared",
        "restaurant prepared",
        "made with water",
        "made with milk",
        "solids and liquids",
        "includes usda commodity",
    }
)

_WS = re.compile(r"\s+")


def _is_kept(char: str) -> bool:
    r"""Whether a character survives normalisation.

    Mirrors the Dart side's `[^\p{L}\p{N}\p{M}]+` exactly. Two details matter:

      * **Combining marks are kept.** Python's `\w` excludes them, which would
        shatter "बिरयानी" into "ब रय न" — every Devanagari food name reduced to
        fragments. Dart's `\p{M}` keeps them. Matching Dart is what is correct
        here, and it is why this is a function rather than a `\w` regex.
      * **Underscore is dropped.** Python's `\w` keeps it; `\p{L}\p{N}\p{M}`
        does not.
    """
    return char.isalnum() or unicodedata.category(char).startswith("M")

# Singularisation was tried and removed. Any rule simple enough to state in a
# regex gets "molasses" -> "molasse" and "couscous" -> "couscou", and the guard
# needed to avoid that grows into an exception list. It bought only the merging
# of plural variants, which USDA is internally consistent about anyway, and it
# would have to be replicated exactly in the Dart normaliser — where a
# divergence would silently stop `food_cache` from ever hitting. Not worth it.


def strip_accents(text: str) -> str:
    """Fold accents: crème -> creme.

    Mirrors the FTS index's `remove_diacritics 2`, so the normalised key and
    the search index agree about what a word is.
    """
    decomposed = unicodedata.normalize("NFKD", text)
    return "".join(c for c in decomposed if not unicodedata.combining(c))


def split_prep(description: str) -> tuple[str, str]:
    """Split a USDA-style description into (display name, prep note).

    "Beans, snap, green, cooked, boiled, drained, without salt"
        -> ("Beans, snap, green", "cooked, boiled, drained, without salt")

    Only *trailing* prep segments are taken. A prep word appearing mid-name is
    left alone, because "Dried apricots, stewed" and "Apricots, dried" are
    genuinely different foods and the leading token carries identity.
    """
    parts = [p.strip() for p in description.split(",")]
    if len(parts) <= 1:
        return description.strip(), ""

    cut = len(parts)
    while cut > 1:
        candidate = parts[cut - 1].lower()
        if candidate in _PREP_TERMS or _looks_like_prep(candidate):
            cut -= 1
        else:
            break

    if cut == len(parts):
        return description.strip(), ""

    return ", ".join(parts[:cut]), ", ".join(parts[cut:])


def _looks_like_prep(segment: str) -> bool:
    """Whether every word in a comma segment is a preparation term."""
    words = segment.split()
    if not words or len(words) > 4:
        return False
    return segment in _PREP_TERMS


def normalise(name: str) -> str:
    """The dedup and cache key for a food name.

    fold accents -> lowercase -> drop punctuation -> collapse whitespace.

    Deliberately simple. Every step has an exact one-line equivalent in the
    Dart normaliser, which is what keeps the two in step.

    Must stay deterministic across builds: it is written into the shipped
    database *and* recomputed on-device to look names up in `food_cache`. A
    change here without a matching change in the Dart normaliser silently stops
    the cache from ever hitting.
    """
    folded = strip_accents(name).lower()
    text = "".join(c if _is_kept(c) else " " for c in folded)
    return _WS.sub(" ", text).strip()


def sort_key(name: str) -> tuple[int, str]:
    """Ranking tiebreak: shorter, more generic names first.

    So a search for "rice" surfaces "Rice, white, long-grain" ahead of
    "Rice, white, long-grain, parboiled, enriched, dry".
    """
    return (len(name), name)
