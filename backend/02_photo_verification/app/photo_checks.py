from __future__ import annotations

import numpy as np


def blur_score_from_features(features: np.ndarray) -> float:
    edge_density = float(features[3])
    return round(max(0.0, min(1.0, edge_density * 3.0)), 4)


def guess_photo_type(features: np.ndarray) -> str:
    brightness = float(features[0])
    edge_density = float(features[3])
    entropy = float(features[4])
    if brightness < 0.18:
        return "dark_or_unclear"
    if edge_density > 0.35 and entropy > 0.55:
        return "wool_closeup_texture"
    if edge_density < 0.15:
        return "wide_batch_or_blurry"
    return "general_wool_photo"


def classify_wool_condition(
    features: np.ndarray,
    *,
    is_wool: bool,
    confidence: float,
    blur_score: float,
) -> tuple[str, list[str]]:
    if not is_wool:
        return "BAD", ["Photo does not appear to contain wool."]

    brightness = float(features[0])
    saturation = float(features[2])
    edge_density = float(features[3])
    entropy = float(features[4])

    condition_score = 0

    if 0.35 <= brightness <= 0.78:
        condition_score += 1
    if saturation < 0.32:
        condition_score += 1
    if edge_density > 0.24:
        condition_score += 1
    if entropy > 0.52:
        condition_score += 1
    if confidence >= 0.72:
        condition_score += 1
    if blur_score >= 0.35:
        condition_score += 1

    reasons: list[str] = []
    if condition_score >= 5:
        label = "NEW"
        reasons.append("Texture and clarity are strong with low visible contamination.")
    elif condition_score >= 4:
        label = "SLIGHTLY"
        reasons.append("Minor contamination/noise detected but quality is mostly good.")
    elif condition_score >= 3:
        label = "MODERATE"
        reasons.append("Average quality; cleaning/sorting likely needed before processing.")
    else:
        label = "BAD"
        reasons.append("Low visual quality or high contamination indicators.")

    return label, reasons


def review_notes(features: np.ndarray, confidence: float) -> list[str]:
    notes: list[str] = []
    if features[0] < 0.2:
        notes.append("Image is too dark; request daylight capture.")
    if features[3] < 0.12:
        notes.append("Image appears blurry; ask for a sharper close-up.")
    if confidence < 0.6:
        notes.append("Low confidence; suggest manual review.")
    if not notes:
        notes.append("Photo quality is acceptable for automated pre-check.")
    return notes
