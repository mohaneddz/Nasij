from __future__ import annotations

import io
import json
from pathlib import Path

import numpy as np
import torch
from PIL import Image
from torchvision import models, transforms

ARTIFACT_DIR = Path(__file__).resolve().parents[1] / "artifacts"
MODEL_PATH = ARTIFACT_DIR / "wool_classifier_model.pt"
MODEL_CONFIG_PATH = ARTIFACT_DIR / "model_config.json"


class WoolModelBundle:
    def __init__(self) -> None:
        if not MODEL_PATH.exists():
            raise FileNotFoundError(f"Missing artifact {MODEL_PATH}. Run train.py first.")
        if not MODEL_CONFIG_PATH.exists():
            raise FileNotFoundError(f"Missing artifact {MODEL_CONFIG_PATH}. Run train.py first.")

        config = json.loads(MODEL_CONFIG_PATH.read_text(encoding="utf-8"))
        self.class_names: list[str] = list(config["classes"])
        self.feature_version = str(config.get("feature_version", "resnet18_wool"))

        input_size = int(config.get("input_size", 224))
        mean = config.get("mean", [0.485, 0.456, 0.406])
        std = config.get("std", [0.229, 0.224, 0.225])

        self.model = models.resnet18(weights=None)
        self.model.fc = torch.nn.Linear(self.model.fc.in_features, len(self.class_names))

        state_dict = torch.load(MODEL_PATH, map_location="cpu")
        self.model.load_state_dict(state_dict)
        self.model.eval()

        self.preprocess = transforms.Compose(
            [
                transforms.Resize((input_size, input_size)),
                transforms.ToTensor(),
                transforms.Normalize(mean, std),
            ]
        )

    def predict_proba_from_bytes(self, content: bytes) -> np.ndarray:
        with Image.open(io.BytesIO(content)) as image:
            image = image.convert("RGB")
            x = self.preprocess(image).unsqueeze(0)

        with torch.no_grad():
            logits = self.model(x)
            probs = torch.softmax(logits, dim=1)[0].cpu().numpy()
        return probs.astype(np.float32)
