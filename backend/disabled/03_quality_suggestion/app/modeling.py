from __future__ import annotations

from pathlib import Path

import joblib
import numpy as np

ARTIFACT_DIR = Path(__file__).resolve().parents[1] / "artifacts"
MODEL_PATH = ARTIFACT_DIR / "quality_model.joblib"
LABELS = ["low", "medium", "high"]


class QualityModel:
    def __init__(self) -> None:
        if not MODEL_PATH.exists():
            raise FileNotFoundError(f"Missing artifact {MODEL_PATH}. Run train.py first.")
        self.model = joblib.load(MODEL_PATH)

    def predict(self, x: np.ndarray) -> tuple[str, float]:
        probs = self.model.predict_proba(x.reshape(1, -1))[0]
        idx = int(np.argmax(probs))
        return LABELS[idx], float(probs[idx])

