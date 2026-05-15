from __future__ import annotations

import json
from pathlib import Path

from app.data_sources import EID_AL_ADHA_BY_YEAR, load_algerian_demand_daily, load_time_series_frame

BASE_DIR = Path(__file__).resolve().parent
DATA_DIR = BASE_DIR / "data"
ARTIFACT_DIR = BASE_DIR / "artifacts"


def main() -> None:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    ARTIFACT_DIR.mkdir(parents=True, exist_ok=True)

    daily = load_algerian_demand_daily()
    annual = load_time_series_frame()

    daily_path = DATA_DIR / "algerian_wool_demand_daily_synth.csv"
    annual_path = DATA_DIR / "algerian_wool_demand_annual_synth.csv"
    daily.to_csv(daily_path, index=False)
    annual.to_csv(annual_path, index=False)

    meta = {
        "data_source": "Synthetic Algerian wool demand derived from Table 28 USA imports/exports",
        "annual_observations": int(len(annual)),
        "daily_observations": int(len(daily)),
        "first_year": int(annual["year"].iloc[0]),
        "last_year": int(annual["year"].iloc[-1]),
        "columns_annual": list(annual.columns),
        "columns_daily": list(daily.columns),
        "eid_rule": {
            "pre_eid_window_days": 7,
            "pre_eid_drop_target": "about 90% by Eid",
            "post_eid_window_days": 20,
            "post_eid_multiplier_range": [0.08, 0.18],
        },
        "eid_dates": EID_AL_ADHA_BY_YEAR,
    }
    (ARTIFACT_DIR / "forecast_metadata.json").write_text(json.dumps(meta, indent=2), encoding="utf-8")
    print(f"Saved synthetic daily demand: {daily_path}")
    print(f"Saved synthetic annual demand: {annual_path}")
    print(f"Saved metadata: {ARTIFACT_DIR / 'forecast_metadata.json'}")


if __name__ == "__main__":
    main()
