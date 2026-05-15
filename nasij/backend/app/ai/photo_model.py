from __future__ import annotations

from pathlib import Path

import joblib
import numpy as np

ARTIFACT_PATH = Path(__file__).resolve().parent / "artifacts" / "photo_verifier.joblib"


class PhotoVerifierModel:
    def __init__(self) -> None:
        if not ARTIFACT_PATH.exists():
            raise FileNotFoundError(f"Missing artifact {ARTIFACT_PATH}. Run train.py first.")
        self.model = joblib.load(ARTIFACT_PATH)

    def predict(self, features: np.ndarray) -> tuple[bool, float]:
        probs = self.model.predict_proba(features.reshape(1, -1))[0]
        confidence = float(max(probs))
        is_wool = bool(int(self.model.predict(features.reshape(1, -1))[0]) == 1)
        return is_wool, confidence
