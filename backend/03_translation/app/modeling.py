from __future__ import annotations

from pathlib import Path

import joblib
import numpy as np

ARTIFACT_PATH = Path(__file__).resolve().parents[1] / "artifacts" / "translator_retrieval.joblib"


class RetrievalTranslator:
    def __init__(self) -> None:
        if not ARTIFACT_PATH.exists():
            raise FileNotFoundError(f"Missing artifact {ARTIFACT_PATH}. Run train.py first.")
        payload = joblib.load(ARTIFACT_PATH)
        self.vectorizer = payload["vectorizer"]
        self.matrix = payload["matrix"]
        self.meta = payload["meta"]

    def translate(self, text: str, source_lang: str, target_lang: str) -> tuple[str, float]:
        query = f"{source_lang}->{target_lang}::{text.lower().strip()}"
        q_vec = self.vectorizer.transform([query])
        sims = (q_vec @ self.matrix.T).toarray().ravel()
        idx = int(np.argmax(sims))
        confidence = float(max(0.0, sims[idx]))
        candidate = self.meta[idx]
        return str(candidate["target"]), min(1.0, confidence)

