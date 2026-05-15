from __future__ import annotations

import numpy as np

from app.schemas import TraceabilityPayload


FEATURE_ORDER = [
    "mismatch_collected_vs_announced",
    "loss_collected_to_received",
    "loss_received_to_washed",
    "loss_washed_to_transformed",
    "loss_transformed_to_sold",
    "edit_count",
    "missing_photo",
    "missing_location",
    "actor_history_risk",
]


def _safe_ratio(num: float, den: float) -> float:
    return float(num / den) if den > 0 else 0.0


def to_feature_vector(payload: TraceabilityPayload) -> np.ndarray:
    announced = payload.announced_weight_kg
    collected = payload.collected_weight_kg
    received = payload.received_weight_kg
    washed = payload.washed_weight_kg
    transformed = payload.transformed_weight_kg
    sold = payload.sold_weight_kg

    values = [
        _safe_ratio(collected - announced, max(announced, 1e-6)),
        _safe_ratio(collected - received, max(collected, 1e-6)),
        _safe_ratio(received - washed, max(received, 1e-6)),
        _safe_ratio(washed - transformed, max(washed, 1e-6)),
        _safe_ratio(transformed - sold, max(transformed, 1e-6)),
        float(payload.edit_count),
        0.0 if payload.has_photo else 1.0,
        0.0 if payload.has_location_update else 1.0,
        float(payload.actor_history_risk),
    ]
    return np.array(values, dtype=float)

