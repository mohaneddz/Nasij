from __future__ import annotations

from pathlib import Path

import joblib
import numpy as np

ARTIFACT_PATH = Path(__file__).resolve().parents[1] / "artifacts" / "risk_model.joblib"


class TraceabilityModel:
    def __init__(self) -> None:
        if not ARTIFACT_PATH.exists():
            raise FileNotFoundError(
                f"Model artifact not found at {ARTIFACT_PATH}. Run train.py first."
            )
        self.model = joblib.load(ARTIFACT_PATH)

    def score(self, features: np.ndarray) -> float:
        probs = self.model.predict_proba(features.reshape(1, -1))[0]
        return float(probs[1])

