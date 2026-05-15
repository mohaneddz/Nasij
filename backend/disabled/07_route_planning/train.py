from __future__ import annotations

from pathlib import Path
import sys

import joblib
import numpy as np
import pandas as pd
import requests
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_absolute_error
from sklearn.model_selection import train_test_split

BACKEND_DIR = Path(__file__).resolve().parents[1]
if str(BACKEND_DIR) not in sys.path:
    sys.path.append(str(BACKEND_DIR))

from shared.nfn_seed_data import load_seed_batches_and_alerts

BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / "data"
ARTIFACT_DIR = BASE_DIR / "artifacts"


def _fetch_osrm_route(lat1: float, lon1: float, lat2: float, lon2: float) -> tuple[float, float] | None:
    url = (
        "https://router.project-osrm.org/route/v1/driving/"
        f"{lon1:.6f},{lat1:.6f};{lon2:.6f},{lat2:.6f}?overview=false"
    )
    resp = requests.get(url, timeout=12)
    resp.raise_for_status()
    payload = resp.json()
    routes = payload.get("routes") or []
    if not routes:
        return None
    route = routes[0]
    return float(route["distance"]) / 1000.0, float(route["duration"]) / 60.0


def _collect_real_coordinates() -> list[tuple[float, float]]:
    coords: list[tuple[float, float]] = []

    batches_df, _ = load_seed_batches_and_alerts()
    for _, row in batches_df.iterrows():
        lat = float(row.get("location_lat") or np.nan)
        lon = float(row.get("location_lng") or np.nan)
        if np.isfinite(lat) and np.isfinite(lon):
            coords.append((lat, lon))

    actors_path = BACKEND_DIR / "06_matching_recommendation" / "data" / "actors_seed.csv"
    if actors_path.exists():
        actors = pd.read_csv(actors_path)
        for _, row in actors.iterrows():
            lat = float(row.get("lat") or np.nan)
            lon = float(row.get("lon") or np.nan)
            if np.isfinite(lat) and np.isfinite(lon):
                coords.append((lat, lon))

    unique: list[tuple[float, float]] = []
    seen: set[tuple[int, int]] = set()
    for lat, lon in coords:
        key = (int(round(lat * 1_000_000)), int(round(lon * 1_000_000)))
        if key in seen:
            continue
        seen.add(key)
        unique.append((lat, lon))
    return unique


def _build_dataset_from_real_routes(n_pairs: int = 220, seed: int = 42) -> pd.DataFrame:
    rng = np.random.default_rng(seed)
    coords = _collect_real_coordinates()
    if len(coords) < 6:
        raise ValueError("Not enough real coordinates for route sampling.")

    rows: list[dict[str, float]] = []
    attempts = 0
    successes = 0
    max_attempts = n_pairs * 8
    while successes < n_pairs and attempts < max_attempts:
        attempts += 1
        i, j = rng.choice(len(coords), size=2, replace=False)
        lat1, lon1 = coords[int(i)]
        lat2, lon2 = coords[int(j)]
        route = None
        try:
            route = _fetch_osrm_route(lat1, lon1, lat2, lon2)
        except Exception:
            route = None
        if route is None:
            continue

        dist_km, base_duration_min = route
        if dist_km <= 0.3 or base_duration_min <= 1.0:
            continue

        successes += 1
        for _ in range(5):
            load_ratio = float(rng.uniform(0.12, 1.0))
            road_quality = float(rng.uniform(0.35, 1.0))
            adjusted = (
                base_duration_min
                * (1.0 + 0.18 * load_ratio)
                * (1.0 + 0.28 * (1.0 - road_quality))
                + float(rng.normal(0, 2.2))
            )
            rows.append(
                {
                    "distance_km": dist_km,
                    "load_ratio": load_ratio,
                    "road_quality": road_quality,
                    "duration_min": float(max(2.0, adjusted)),
                }
            )

    df = pd.DataFrame(rows)
    if df.empty:
        raise ValueError("Failed to collect enough route samples from OSRM.")
    return df


def _build_synthetic_fallback(n_samples: int = 2500, seed: int = 42) -> pd.DataFrame:
    rng = np.random.default_rng(seed)
    distance = rng.uniform(1, 140, n_samples)
    load_ratio = rng.uniform(0.1, 1.0, n_samples)
    road_quality = rng.uniform(0.2, 1.0, n_samples)

    speed_kmh = 65 * road_quality - 10 * load_ratio
    speed_kmh = np.clip(speed_kmh, 20, 80)
    duration = (distance / speed_kmh) * 60 + rng.normal(0, 3, n_samples)
    duration = np.clip(duration, 3, None)

    return pd.DataFrame(
        {
            "distance_km": distance,
            "load_ratio": load_ratio,
            "road_quality": road_quality,
            "duration_min": duration,
        }
    )


def main() -> None:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    ARTIFACT_DIR.mkdir(parents=True, exist_ok=True)

    try:
        df = _build_dataset_from_real_routes()
        df.to_csv(DATA_DIR / "route_duration_training_real.csv", index=False)
    except Exception as exc:
        print(f"[route] Real route training failed ({exc}); using synthetic fallback.")
        df = _build_synthetic_fallback()
        df.to_csv(DATA_DIR / "route_duration_training.csv", index=False)

    x_train, x_test, y_train, y_test = train_test_split(
        df[["distance_km", "load_ratio", "road_quality"]],
        df["duration_min"],
        test_size=0.2,
        random_state=42,
    )
    model = RandomForestRegressor(n_estimators=280, random_state=42)
    model.fit(x_train, y_train)
    preds = model.predict(x_test)
    mae = mean_absolute_error(y_test, preds)

    joblib.dump(model, ARTIFACT_DIR / "duration_model.joblib")
    (ARTIFACT_DIR / "metrics.txt").write_text(f"MAE_minutes={mae:.3f}\n", encoding="utf-8")
    print("Saved artifacts to", ARTIFACT_DIR)


if __name__ == "__main__":
    main()
