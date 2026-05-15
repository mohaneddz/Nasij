from __future__ import annotations

import csv
from functools import lru_cache
from pathlib import Path

from fastapi import FastAPI

BASE_DIR = Path(__file__).resolve().parents[1]
DATASET_PATH = BASE_DIR / "wool_flux_dataset_10k_attributes_only.csv"

app = FastAPI(title="Skin Health ML Dataset Service", version="0.1.0")


@lru_cache(maxsize=1)
def _dataset_profile() -> dict:
    if not DATASET_PATH.exists():
        return {"exists": False, "rows": 0, "columns": 0, "column_names": []}

    with DATASET_PATH.open("r", encoding="utf-8", newline="") as f:
        reader = csv.reader(f)
        header = next(reader, [])
        rows = sum(1 for _ in reader)

    return {
        "exists": True,
        "rows": rows,
        "columns": len(header),
        "column_names": header,
    }


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/dataset-info")
def dataset_info() -> dict:
    profile = _dataset_profile()
    return {
        "service": "09_wool_ml",
        "dataset_path": str(DATASET_PATH),
        **profile,
    }
