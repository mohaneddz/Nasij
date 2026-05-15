from __future__ import annotations

import numpy as np
from fastapi import UploadFile

from app.modeling import WoolBoosterBundle


async def predict_from_upload(
    bundle: WoolBoosterBundle,
    file: UploadFile,
    top_k: int,
) -> dict[str, object]:
    if not file.content_type or not file.content_type.startswith("image/"):
        raise ValueError("Uploaded file must be an image content type.")

    content = await file.read()
    if not content:
        raise ValueError("Uploaded file is empty.")

    probabilities = bundle.predict_proba_from_bytes(content)

    if len(probabilities) != len(bundle.class_names):
        raise ValueError("Model output shape does not match configured class labels.")

    sorted_indices = np.argsort(probabilities)[::-1]
    top_indices = sorted_indices[:top_k]

    top_items = [
        {
            "label": bundle.class_names[int(index)],
            "confidence": round(float(probabilities[int(index)]), 5),
        }
        for index in top_indices
    ]

    best = top_items[0]
    return {
        "predicted_label": best["label"],
        "confidence": best["confidence"],
        "top_k": top_items,
        "feature_version": bundle.feature_version,
    }

