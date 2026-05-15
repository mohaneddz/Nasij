from __future__ import annotations

from io import BytesIO

import numpy as np
from PIL import Image


FEATURE_ORDER = [
    "brightness_mean",
    "brightness_std",
    "saturation_mean",
    "edge_density",
    "entropy",
    "color_variance",
]


def _entropy(gray: np.ndarray) -> float:
    hist, _ = np.histogram(gray.flatten(), bins=32, range=(0, 255), density=True)
    hist = hist[hist > 0]
    return float(-np.sum(hist * np.log2(hist)))


def _edge_density(gray: np.ndarray) -> float:
    gx = np.abs(np.diff(gray, axis=1))
    gy = np.abs(np.diff(gray, axis=0))
    edges = (gx.mean() + gy.mean()) / 2.0
    return float(edges / 255.0)


def extract_features(file_bytes: bytes) -> np.ndarray:
    image = Image.open(BytesIO(file_bytes)).convert("RGB").resize((224, 224))
    rgb = np.asarray(image, dtype=np.float32)
    gray = rgb.mean(axis=2)

    max_rgb = rgb.max(axis=2)
    min_rgb = rgb.min(axis=2)
    sat = (max_rgb - min_rgb) / np.maximum(max_rgb, 1e-6)

    features = np.array(
        [
            gray.mean() / 255.0,
            gray.std() / 255.0,
            sat.mean(),
            _edge_density(gray),
            _entropy(gray) / 8.0,
            rgb.var() / (255.0**2),
        ],
        dtype=float,
    )
    return features

