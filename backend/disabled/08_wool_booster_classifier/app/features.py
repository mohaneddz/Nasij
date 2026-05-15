from __future__ import annotations

from io import BytesIO

import numpy as np
from PIL import Image

INPUT_SIZE = 224

FEATURE_ORDER = [
    "brightness_mean",
    "brightness_std",
    "saturation_mean",
    "saturation_std",
    "edge_density",
    "entropy",
    "color_variance",
    "r_mean",
    "g_mean",
    "b_mean",
    "r_std",
    "g_std",
    "b_std",
    "high_sat_ratio",
    "dark_ratio",
    "bright_ratio",
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


def _to_resized_rgb(content: bytes) -> np.ndarray:
    image = Image.open(BytesIO(content)).convert("RGB").resize((INPUT_SIZE, INPUT_SIZE))
    return np.asarray(image, dtype=np.float32)


def extract_features_from_bytes(content: bytes) -> np.ndarray:
    rgb = _to_resized_rgb(content)
    gray = rgb.mean(axis=2)

    max_rgb = rgb.max(axis=2)
    min_rgb = rgb.min(axis=2)
    sat = (max_rgb - min_rgb) / np.maximum(max_rgb, 1e-6)

    r = rgb[:, :, 0] / 255.0
    g = rgb[:, :, 1] / 255.0
    b = rgb[:, :, 2] / 255.0
    gray01 = gray / 255.0

    features = np.array(
        [
            gray01.mean(),
            gray01.std(),
            sat.mean(),
            sat.std(),
            _edge_density(gray),
            _entropy(gray) / 8.0,
            rgb.var() / (255.0**2),
            r.mean(),
            g.mean(),
            b.mean(),
            r.std(),
            g.std(),
            b.std(),
            float((sat > 0.45).mean()),
            float((gray01 < 0.2).mean()),
            float((gray01 > 0.8).mean()),
        ],
        dtype=np.float32,
    )
    return features

