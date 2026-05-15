from __future__ import annotations

from pathlib import Path

import numpy as np
import pandas as pd

# USA wool trade data (Table 28, USDA) embedded directly.
# Columns: year, imports_million_clean_pounds, exports_million_clean_pounds
_US_TRADE_DATA = [
    (1980, 29.6, 6.1), (1981, 26.4, 5.8), (1982, 23.1, 5.2),
    (1983, 28.5, 4.9), (1984, 32.0, 5.5), (1985, 30.8, 4.7),
    (1986, 33.2, 4.3), (1987, 37.1, 4.8), (1988, 38.5, 5.1),
    (1989, 36.2, 5.6), (1990, 33.9, 5.3), (1991, 29.7, 4.8),
    (1992, 31.4, 4.5), (1993, 28.6, 4.1), (1994, 30.2, 3.9),
    (1995, 27.8, 3.7), (1996, 25.3, 3.4), (1997, 26.1, 3.2),
    (1998, 24.7, 2.9), (1999, 22.5, 2.7), (2000, 21.3, 2.5),
    (2001, 19.8, 2.3), (2002, 18.6, 2.1), (2003, 17.9, 2.0),
    (2004, 19.2, 2.2), (2005, 20.1, 2.4), (2006, 21.8, 2.6),
    (2007, 23.4, 2.8), (2008, 20.7, 2.3), (2009, 16.5, 1.9),
    (2010, 18.3, 2.1), (2011, 19.7, 2.3), (2012, 20.4, 2.4),
    (2013, 21.1, 2.5), (2014, 22.6, 2.7), (2015, 21.9, 2.6),
    (2016, 20.3, 2.4), (2017, 19.8, 2.3), (2018, 18.5, 2.1),
    (2019, 17.2, 1.9), (2020, 14.8, 1.6), (2021, 16.1, 1.8),
    (2022, 17.5, 2.0),
]

EID_AL_ADHA_BY_YEAR: dict[int, str] = {
    2010: "2010-11-16", 2011: "2011-11-06", 2012: "2012-10-26",
    2013: "2013-10-15", 2014: "2014-10-04", 2015: "2015-09-24",
    2016: "2016-09-12", 2017: "2017-09-01", 2018: "2018-08-21",
    2019: "2019-08-11", 2020: "2020-07-31", 2021: "2021-07-20",
    2022: "2022-07-09", 2023: "2023-06-28", 2024: "2024-06-16",
    2025: "2025-06-06", 2026: "2026-05-27", 2027: "2027-05-17",
    2028: "2028-05-05", 2029: "2029-04-24", 2030: "2030-04-13",
    2031: "2031-04-02", 2032: "2032-03-22", 2033: "2033-03-11",
    2034: "2034-03-01", 2035: "2035-02-18",
}


def _load_us_trade_frame() -> pd.DataFrame:
    rows = [
        {"year": y, "imports_million_clean_pounds": imp, "exports_million_clean_pounds": exp}
        for y, imp, exp in _US_TRADE_DATA
    ]
    return pd.DataFrame(rows).sort_values("year").reset_index(drop=True)


def _to_algerian_annual_demand(frame: pd.DataFrame, seed: int = 42) -> pd.DataFrame:
    rng = np.random.default_rng(seed)
    out = frame.copy()
    us_imports_kg = out["imports_million_clean_pounds"] * 1_000_000.0 * 0.45359237
    us_exports_kg = out["exports_million_clean_pounds"] * 1_000_000.0 * 0.45359237

    us_baseline_kg = 0.85 * us_imports_kg + 0.15 * us_exports_kg
    scale = 0.04
    jitter = np.clip(rng.normal(1.0, 0.045, size=len(out)), 0.88, 1.12)
    out["annual_demand_kg"] = (us_baseline_kg * scale * jitter).clip(lower=20_000.0)
    return out[["year", "annual_demand_kg"]]


def _apply_eid_shock(daily: pd.DataFrame, seed: int = 42) -> pd.DataFrame:
    rng = np.random.default_rng(seed + 97)
    out = daily.copy()

    for year, eid_text in EID_AL_ADHA_BY_YEAR.items():
        eid = pd.Timestamp(eid_text)

        pre_mask = (out["date"] >= (eid - pd.Timedelta(days=7))) & (out["date"] < eid)
        pre_idx = out.index[pre_mask]
        if len(pre_idx) > 0:
            pre_progress = np.linspace(0.0, 1.0, len(pre_idx))
            pre_multipliers = 1.0 - (0.9 * pre_progress)
            out.loc[pre_idx, "demand_kg"] = out.loc[pre_idx, "demand_kg"].to_numpy() * pre_multipliers

        post_mask = (out["date"] >= eid) & (out["date"] <= (eid + pd.Timedelta(days=20)))
        post_idx = out.index[post_mask]
        if len(post_idx) > 0:
            post_multipliers = np.clip(rng.normal(0.12, 0.015, len(post_idx)), 0.08, 0.18)
            out.loc[post_idx, "demand_kg"] = out.loc[post_idx, "demand_kg"].to_numpy() * post_multipliers

    out["demand_kg"] = out["demand_kg"].clip(lower=0.0)
    return out


def load_algerian_demand_daily(seed: int = 42) -> pd.DataFrame:
    us_trade = _load_us_trade_frame()
    annual = _to_algerian_annual_demand(us_trade, seed=seed)
    rng = np.random.default_rng(seed)

    rows: list[dict[str, object]] = []
    for _, rec in annual.iterrows():
        year = int(rec["year"])
        annual_total = float(rec["annual_demand_kg"])
        dates = pd.date_range(f"{year}-01-01", f"{year}-12-31", freq="D")
        if dates.empty:
            continue

        day = dates.dayofyear.to_numpy(dtype=float)
        seasonality = 1.0 + 0.06 * np.sin(2.0 * np.pi * (day / 365.25 - 0.2))
        noise = np.clip(rng.normal(1.0, 0.015, len(dates)), 0.9, 1.1)
        weights = np.clip(seasonality * noise, 0.35, None)
        daily_values = annual_total * (weights / float(weights.sum()))

        for date, demand in zip(dates, daily_values):
            rows.append(
                {
                    "date": date,
                    "year": year,
                    "demand_kg": float(demand),
                }
            )

    daily = pd.DataFrame(rows)
    if daily.empty:
        raise ValueError("Synthetic Algerian demand generation produced no rows.")

    daily = _apply_eid_shock(daily, seed=seed)
    return daily.sort_values("date").reset_index(drop=True)


def load_time_series_frame() -> pd.DataFrame:
    daily = load_algerian_demand_daily()
    annual = (
        daily.groupby("year", as_index=False)
        .agg(demand_kg=("demand_kg", "sum"))
        .sort_values("year")
        .reset_index(drop=True)
    )
    return annual
