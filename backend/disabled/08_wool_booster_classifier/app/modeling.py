from __future__ import annotations

import io
import json
from pathlib import Path

import joblib
import numpy as np
from PIL import Image

from app.features import FEATURE_ORDER, extract_features_from_bytes

ARTIFACT_DIR = Path(__file__).resolve().parents[1] / "artifacts"
MODEL_PATH = ARTIFACT_DIR / "best_model.joblib"
MODEL_CONFIG_PATH = ARTIFACT_DIR / "model_config.json"


class WoolBoosterBundle:
    def __init__(self) -> None:
        if not MODEL_PATH.exists():
            raise FileNotFoundError(f"Missing artifact {MODEL_PATH}. Run train.py first.")
        if not MODEL_CONFIG_PATH.exists():
            raise FileNotFoundError(f"Missing artifact {MODEL_CONFIG_PATH}. Run train.py first.")

        self.model = joblib.load(MODEL_PATH)
        self.config = json.loads(MODEL_CONFIG_PATH.read_text(encoding="utf-8"))
        self.class_names: list[str] = list(self.config["classes"])
        self.feature_version = str(self.config.get("feature_version", "wool_booster_v1"))
        self.best_model_name = str(self.config["best_model_name"])
        self.selection_metric = str(self.config.get("selection_metric", "macro_f1"))
        self.candidates = dict(self.config.get("candidates", {}))

    def predict_proba_from_bytes(self, content: bytes) -> np.ndarray:
        # Decode to ensure valid image early and consistent errors.
        Image.open(io.BytesIO(content)).convert("RGB")
        features = extract_features_from_bytes(content).reshape(1, -1)

        if hasattr(self.model, "predict_proba"):
            probs = self.model.predict_proba(features)[0]
            return np.asarray(probs, dtype=np.float32)

        # Fallback for models without predict_proba.
        pred = int(self.model.predict(features)[0])
        probs = np.zeros(len(self.class_names), dtype=np.float32)
        probs[pred] = 1.0
        return probs

