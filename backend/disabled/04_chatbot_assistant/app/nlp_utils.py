from __future__ import annotations

import re

WEIGHT_RE = re.compile(r"(\d+(?:\.\d+)?)\s*(?:kg|kilo|kilos|kilogram)", re.IGNORECASE)
SHEEP_RE = re.compile(r"(\d+)\s*(?:sheep|ewes|mouton|khrouf)", re.IGNORECASE)


def extract_entities(message: str) -> dict[str, str | float | int | list[str] | None]:
    lowered = message.lower()
    weight_match = WEIGHT_RE.search(lowered)
    sheep_match = SHEEP_RE.search(lowered)

    wool_state = None
    if any(k in lowered for k in ["raw", "dirty", "unwashed"]):
        wool_state = "raw_dirty"
    elif any(k in lowered for k in ["washed", "clean"]):
        wool_state = "washed_clean"
    elif "sorted" in lowered:
        wool_state = "sorted"

    availability = None
    for token in ["today", "tomorrow", "sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]:
        if token in lowered:
            availability = token
            break

    missing = []
    if "location" not in lowered and "tizi" not in lowered and "algiers" not in lowered:
        missing.append("location")
    if "photo" not in lowered and "image" not in lowered:
        missing.append("photos")

    return {
        "estimated_weight_kg": float(weight_match.group(1)) if weight_match else None,
        "sheep_count": int(sheep_match.group(1)) if sheep_match else None,
        "wool_state": wool_state,
        "availability": availability,
        "missing_fields": missing,
    }

