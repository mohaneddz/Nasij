from __future__ import annotations

import numpy as np

from app.schemas import QualityPayload

STATE_MAP = {"raw": 0.0, "washed": 1.0, "sorted": 2.0, "unknown": 3.0}
FEATURE_ORDER = [
    "cleanliness_score",
    "contamination_score",
    "moisture_warning",
    "photo_confidence",
    "actor_reliability",
    "declared_state_code",
]


def to_vector(payload: QualityPayload) -> np.ndarray:
    state_code = STATE_MAP.get(payload.declared_state.lower().strip(), 3.0)
    return np.array(
        [
            payload.cleanliness_score,
            payload.contamination_score,
            1.0 if payload.moisture_warning else 0.0,
            payload.photo_confidence,
            payload.actor_reliability,
            state_code,
        ],
        dtype=float,
    )


def suggested_use(label: str) -> list[str]:
    if label == "high":
        return ["yarn_textile", "premium_felt", "blended_fabric"]
    if label == "medium":
        return ["craft_felt", "padding", "sorted_yarn_after_cleaning"]
    return ["insulation", "industrial_filler", "compost_if_allowed"]

