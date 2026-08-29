"""Builds the `meta` table contents.

This is what the in-app Sources screen reads. Deriving it from the sources that
actually ran — rather than from a hand-maintained list — is the point: the
screen then cannot claim a dataset the build did not include, or omit one it
did. That matters because several of these licences require attribution, and an
attribution screen that has drifted from the shipped data is worse than none.
"""

from __future__ import annotations

import json
from datetime import datetime, timezone

from models import SourceInfo

#: Bump when the schema or the source set changes in a way the app must notice.
#: Must be kept in step with kFoodsAssetVersion in lib/data/foods/foods_db.dart,
#: which is what triggers the on-device re-copy.
BUILD_VERSION = 1


def build(
    sources: list[SourceInfo],
    contributed: dict[str, int],
    total_foods: int,
    total_portions: int,
) -> dict[str, str]:
    """Assemble the key/value rows for the `meta` table."""

    meta: dict[str, str] = {
        "build_version": str(BUILD_VERSION),
        "built_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "total_foods": str(total_foods),
        "total_portions": str(total_portions),
        "source_ids": ",".join(s.id for s in sources),
    }

    for source in sources:
        # One JSON blob per source rather than five flat keys each, so the app
        # can render a source it has never heard of without a schema change.
        meta[f"source.{source.id}"] = json.dumps(
            {
                "name": source.name,
                "licence": source.licence,
                "attribution": source.attribution,
                "url": source.url,
                "foods": contributed.get(source.id, 0),
                "locale": source.locale_hint,
            },
            ensure_ascii=False,
            separators=(",", ":"),
        )

    return meta
