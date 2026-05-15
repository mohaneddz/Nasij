from __future__ import annotations

import io
from pathlib import Path

import numpy as np
from PIL import Image


def extract_features_from_image(image: Image.Image) -> np.ndarray:
    rgb = image.convert("RGB").resize((96, 96), Image.Resampling.BILINEAR)
    arr = np.asarray(rgb, dtype=np.float32) / 255.0

    hist, _ = np.histogramdd(
        arr.reshape(-1, 3),
        bins=(8, 8, 8),
        range=((0.0, 1.0), (0.0, 1.0), (0.0, 1.0)),
    )
    hist = hist.astype(np.float32).reshape(-1)
    hist /= max(float(hist.sum()), 1.0)

    gray = arr.mean(axis=2)
    texture = np.array(
        [
            gray.mean(),
            gray.std(),
            np.percentile(gray, 10),
            np.percentile(gray, 25),
            np.percentile(gray, 50),
            np.percentile(gray, 75),
            np.percentile(gray, 90),
        ],
        dtype=np.float32,
    )

    return np.concatenate([hist, texture], axis=0)


def extract_features_from_bytes(content: bytes) -> np.ndarray:
    with Image.open(io.BytesIO(content)) as image:
        return extract_features_from_image(image)


def extract_features_from_path(path: Path) -> np.ndarray:
    with Image.open(path) as image:
        return extract_features_from_image(image)
