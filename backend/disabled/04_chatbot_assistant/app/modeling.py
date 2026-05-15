from __future__ import annotations

from pathlib import Path

import joblib

ARTIFACT_PATH = Path(__file__).resolve().parents[1] / "artifacts" / "intent_classifier.joblib"


class IntentModel:
    def __init__(self) -> None:
        if not ARTIFACT_PATH.exists():
            raise FileNotFoundError(f"Missing artifact {ARTIFACT_PATH}. Run train.py first.")
        self.model = joblib.load(ARTIFACT_PATH)

    def predict(self, message: str) -> tuple[str, float]:
        probs = self.model.predict_proba([message])[0]
        idx = int(probs.argmax())
        return str(self.model.classes_[idx]), float(probs[idx])

