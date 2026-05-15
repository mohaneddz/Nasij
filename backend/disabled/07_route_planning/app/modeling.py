from __future__ import annotations

from pathlib import Path

import joblib
import numpy as np

MODEL_PATH = Path(__file__).resolve().parents[1] / "artifacts" / "duration_model.joblib"


class DurationModel:
    def __init__(self) -> None:
        if not MODEL_PATH.exists():
            raise FileNotFoundError(f"Missing artifact {MODEL_PATH}. Run train.py first.")
        self.model = joblib.load(MODEL_PATH)

    def predict_minutes(self, distance_km: float, load_ratio: float, road_quality: float) -> float:
        x = np.array([distance_km, load_ratio, road_quality], dtype=float).reshape(1, -1)
        return float(max(1.0, self.model.predict(x)[0]))

