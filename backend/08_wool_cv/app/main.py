from __future__ import annotations

import json
from pathlib import Path

from fastapi import FastAPI

BASE_DIR = Path(__file__).resolve().parents[1]
ARTIFACT_DIR = BASE_DIR / "artifacts"
DATA_DIR = BASE_DIR / "data"

app = FastAPI(title="Skin Health CV Service", version="0.1.0")


def _read_json(path: Path) -> dict:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/service-info")
def service_info() -> dict:
    model_config = _read_json(ARTIFACT_DIR / "model_config.json")
    training_report = _read_json(ARTIFACT_DIR / "training_report.json")
    manifest = _read_json(DATA_DIR / "dataset_manifest.json")

    return {
        "service": "08_wool_cv",
        "task": "skin_health_cv_tiling_and_resnet_artifacts",
        "artifacts_present": {
            "model_weights": (ARTIFACT_DIR / "flux_resnet_model.pt").exists(),
            "model_config": bool(model_config),
            "training_report": bool(training_report),
            "dataset_manifest": bool(manifest),
        },
        "model_config": model_config,
        "metrics": training_report.get("metrics", {}),
        "tiles": manifest.get("tiles", {}),
    }
