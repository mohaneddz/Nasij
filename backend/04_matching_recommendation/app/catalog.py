from __future__ import annotations

from pathlib import Path

import pandas as pd

CATALOG_PATH = Path(__file__).resolve().parents[1] / "data" / "actors_seed.csv"


def load_catalog() -> pd.DataFrame:
    if not CATALOG_PATH.exists():
        raise FileNotFoundError(f"Missing actor catalog {CATALOG_PATH}.")
    return pd.read_csv(CATALOG_PATH)

