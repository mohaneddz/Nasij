from __future__ import annotations

from pathlib import Path

import joblib
import numpy as np

ARTIFACT_PATH = Path(__file__).resolve().parents[1] / "artifacts" / "matching_model.joblib"


class MatchingModel:
    def __init__(self) -> None:
        if not ARTIFACT_PATH.exists():
            raise FileNotFoundError(f"Missing artifact {ARTIFACT_PATH}. Run train.py first.")
        self.model = joblib.load(ARTIFACT_PATH)

    def score(self, features: np.ndarray) -> float:
        prob = self.model.predict_proba(features.reshape(1, -1))[0][1]
        return float(prob)

