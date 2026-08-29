"""Cross-source deduplication.

Roughly 29,000 raw rows collapse to ~19,000 because "chicken breast, raw"
exists in almost every national table. Two rules govern the collapse:

  1. **Automatic merging happens only on an exact normalised-name match.**
  2. Near-matches are written to a review CSV and merged by a human, or not
     at all.

Rule 2 is not caution for its own sake. `01-concept.md` argues that a bad fuzzy
match which *succeeds silently* is worse than a miss, because it produces
confident wrong numbers wearing an authoritative source badge. That argument
was made about matching photos against the database, and it applies with equal
force here: auto-merging "chicken curry" onto "chicken karahi" would quietly
give one of them the other's calories, in a file that then ships.
"""

from __future__ import annotations

from collections import defaultdict
from dataclasses import dataclass

from models import FoodRecord, Portion

#: Token-overlap above which two differently-named foods are worth a human
#: look. Not a merge threshold — nothing is merged on this.
REVIEW_JACCARD = 0.85

#: Buckets larger than this are skipped for near-match review. "chicken" heads
#: thousands of names and the pairwise comparison is quadratic; the review pass
#: is a convenience, not a correctness requirement, so it degrades rather than
#: stalling the build.
MAX_BUCKET = 400


@dataclass(slots=True)
class NearMatch:
    kept: FoodRecord
    other: FoodRecord
    similarity: float


def _merge_portions(primary: FoodRecord, others: list[FoodRecord]) -> list[Portion]:
    """Take the winner's portions and add any labels the others contribute.

    Portions are the one thing worth harvesting from a losing duplicate: FNDDS
    and CNF carry household measures that USDA SR Legacy often lacks, and a
    portion is a measurement of the food rather than a claim about it, so
    mixing sources here is safe in a way that mixing macros would not be.
    """
    merged = list(primary.portions)
    seen = {p.label.strip().lower() for p in merged}

    for other in others:
        for portion in other.portions:
            label = portion.label.strip().lower()
            if label and label not in seen:
                seen.add(label)
                merged.append(portion)

    if merged and not any(p.is_default for p in merged):
        merged[0] = Portion(merged[0].label, merged[0].grams, is_default=True)

    return merged


def dedupe(
    records: list[FoodRecord],
    precedence: dict[str, int],
) -> tuple[list[FoodRecord], list[NearMatch], dict[str, int]]:
    """Collapse exact normalised-name collisions.

    Returns the kept records, near-match candidates for human review, and a
    per-source count of how many rows each source actually contributed after
    losing its duplicates. That last figure is the interesting one: it shows
    whether a source is earning its place or just restating USDA.
    """
    by_name: dict[str, list[FoodRecord]] = defaultdict(list)
    for record in records:
        if record.name_normalised:
            by_name[record.name_normalised].append(record)

    kept: list[FoodRecord] = []
    contributed: dict[str, int] = defaultdict(int)

    for group in by_name.values():
        group.sort(key=lambda r: (precedence.get(r.source, 999), r.source_id))
        winner, losers = group[0], group[1:]

        if losers:
            winner.portions = _merge_portions(winner, losers)

        kept.append(winner)
        contributed[winner.source] += 1

    kept.sort(key=lambda r: r.name_normalised)
    return kept, _find_near_matches(kept), dict(contributed)


def _find_near_matches(records: list[FoodRecord]) -> list[NearMatch]:
    """Flag pairs that look like the same food under different names.

    Bucketed on the first normalised token so the comparison stays tractable;
    two foods that disagree on their first word are not near-matches in any
    sense worth reviewing.
    """
    buckets: dict[str, list[FoodRecord]] = defaultdict(list)
    for record in records:
        head = record.name_normalised.split(" ", 1)[0]
        if head:
            buckets[head].append(record)

    matches: list[NearMatch] = []

    for bucket in buckets.values():
        if len(bucket) < 2 or len(bucket) > MAX_BUCKET:
            continue

        token_sets = [(r, frozenset(r.name_normalised.split())) for r in bucket]

        for i in range(len(token_sets)):
            left, left_tokens = token_sets[i]
            for j in range(i + 1, len(token_sets)):
                right, right_tokens = token_sets[j]

                if left.source == right.source:
                    continue

                union = left_tokens | right_tokens
                if not union:
                    continue

                similarity = len(left_tokens & right_tokens) / len(union)
                if similarity >= REVIEW_JACCARD:
                    matches.append(NearMatch(left, right, similarity))

    matches.sort(key=lambda m: -m.similarity)
    return matches
