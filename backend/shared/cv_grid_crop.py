from __future__ import annotations

from dataclasses import dataclass
from typing import Any

import numpy as np
from PIL import Image


@dataclass(frozen=True)
class GridDetectionResult:
    x_bounds: list[int]
    y_bounds: list[int]
    meta: dict[str, Any]


def _normalize(values: np.ndarray) -> np.ndarray:
    values = values.astype(np.float32, copy=False)
    vmin = float(values.min())
    vmax = float(values.max())
    if vmax <= vmin:
        return np.zeros_like(values, dtype=np.float32)
    return (values - vmin) / (vmax - vmin)


def _smooth_1d(values: np.ndarray, kernel_size: int = 9) -> np.ndarray:
    kernel_size = max(3, int(kernel_size) | 1)
    kernel = np.ones(kernel_size, dtype=np.float32) / float(kernel_size)
    return np.convolve(values.astype(np.float32, copy=False), kernel, mode="same")


def _detect_axis_bounds(gray: np.ndarray, grid_size: int, axis: str) -> tuple[list[int], list[int]]:
    if axis not in {"x", "y"}:
        raise ValueError(f"Unsupported axis={axis}")

    length = int(gray.shape[1] if axis == "x" else gray.shape[0])
    if length < grid_size * 8:
        return [int(x) for x in np.linspace(0, length, grid_size + 1, dtype=int)], [0] * (grid_size - 1)

    if axis == "x":
        mean_profile = gray.mean(axis=0)
        std_profile = gray.std(axis=0)
    else:
        mean_profile = gray.mean(axis=1)
        std_profile = gray.std(axis=1)

    # Grid separators are usually uniform and either bright (white seams)
    # or dark (black seams), so we score both possibilities.
    uniformity = 1.0 - _normalize(std_profile)
    bright_score = _normalize(mean_profile) + 0.45 * uniformity
    dark_score = _normalize(255.0 - mean_profile) + 0.45 * uniformity
    seam_score = _smooth_1d(np.maximum(bright_score, dark_score), kernel_size=max(5, length // 200))

    spacing = float(length) / float(grid_size)
    search_radius = max(4, int(round(spacing * 0.22)))
    min_gap = max(4, int(round(spacing * 0.55)))

    bounds = [0]
    shifts: list[int] = []

    for k in range(1, grid_size):
        expected = int(round(k * spacing))

        remaining = (grid_size - k)
        lo = max(bounds[-1] + min_gap, expected - search_radius)
        hi = min(length - 1 - remaining * min_gap, expected + search_radius)

        if hi <= lo:
            idx = expected
        else:
            window = seam_score[lo : hi + 1]
            idx = int(lo + int(np.argmax(window)))

        idx = max(bounds[-1] + 1, min(length - 1, idx))
        bounds.append(idx)
        shifts.append(int(idx - expected))

    bounds.append(length)
    return bounds, shifts


def detect_grid_bounds(image: Image.Image, grid_size: int) -> GridDetectionResult:
    if grid_size not in {4, 5}:
        raise ValueError(f"grid_size must be 4 or 5, got {grid_size}")

    rgb = image.convert("RGB")
    gray = np.asarray(rgb.convert("L"), dtype=np.float32)

    x_bounds, x_shifts = _detect_axis_bounds(gray, grid_size=grid_size, axis="x")
    y_bounds, y_shifts = _detect_axis_bounds(gray, grid_size=grid_size, axis="y")

    return GridDetectionResult(
        x_bounds=x_bounds,
        y_bounds=y_bounds,
        meta={
            "method": "cv_seam_detection_v1",
            "grid_size": grid_size,
            "x_shift_px": x_shifts,
            "y_shift_px": y_shifts,
        },
    )
