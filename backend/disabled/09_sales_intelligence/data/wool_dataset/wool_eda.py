from __future__ import annotations

from pathlib import Path
import re
from typing import Iterable

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd


BASE_DIR = Path(__file__).resolve().parent
WOOL_DIR = BASE_DIR / "U.S.WoolSupplyandDemand"
TRADE_DIR = BASE_DIR / "U.S.TextileFiberTrade"
OUT_DIR = BASE_DIR / "eda" / "wool"

MONTH_ORDER = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
MONTH_MAP = {
	"jan": 1,
	"jan.": 1,
	"feb": 2,
	"feb.": 2,
	"mar": 3,
	"mar.": 3,
	"apr": 4,
	"apr.": 4,
	"may": 5,
	"jun": 6,
	"jun.": 6,
	"june": 6,
	"jul": 7,
	"jul.": 7,
	"july": 7,
	"aug": 8,
	"aug.": 8,
	"sep": 9,
	"sep.": 9,
	"sept": 9,
	"sept.": 9,
	"oct": 10,
	"oct.": 10,
	"nov": 11,
	"nov.": 11,
	"dec": 12,
	"dec.": 12,
}


def _read_csv(path: Path) -> pd.DataFrame:
	return pd.read_csv(path)


def _to_numeric(series: pd.Series) -> pd.Series:
	text = series.astype(str).str.replace(",", "", regex=False).str.strip()
	text = text.replace({"": np.nan, "NA": np.nan, "nan": np.nan, "None": np.nan})
	return pd.to_numeric(text, errors="coerce")


def _extract_year(value: object) -> float:
	match = re.search(r"(19|20)\d{2}", str(value))
	if not match:
		return np.nan
	return float(match.group(0))


def _pick_column(columns: Iterable[str], required_tokens: list[str]) -> str:
	for col in columns:
		col_lower = col.lower()
		if all(token in col_lower for token in required_tokens):
			return col
	raise KeyError(f"No column found for tokens: {required_tokens}")


def _safe_slug(name: str) -> str:
	slug = re.sub(r"[^a-zA-Z0-9]+", "_", name).strip("_").lower()
	return slug or "metric"


def _setup_plot_style() -> None:
	plt.style.use("seaborn-v0_8-whitegrid")


def _save_figure(path: Path) -> None:
	path.parent.mkdir(parents=True, exist_ok=True)
	plt.tight_layout()
	plt.savefig(path, dpi=160)
	plt.close()


def _load_table_28() -> pd.DataFrame:
	df = _read_csv(WOOL_DIR / "Table 28.csv")
	df["year"] = df.iloc[:, 0].apply(_extract_year)
	df = df[df["year"].notna()].copy()
	df["year"] = df["year"].astype(int)

	production_col = _pick_column(df.columns, ["production", "clean pounds"])
	imports_col = _pick_column(df.columns, ["imports", "clean pounds"])
	supply_col = _pick_column(df.columns, ["total", "supply"])
	use_col = _pick_column(df.columns, ["mill", "use"])
	ending_stock_col = _pick_column(df.columns, ["ending", "stocks"])
	shorn_wool_col = _pick_column(df.columns, ["shorn", "wool"])

	out = pd.DataFrame(
		{
			"year": df["year"],
			"table28_production_clean_lb_m": _to_numeric(df[production_col]),
			"table28_imports_clean_lb_m": _to_numeric(df[imports_col]),
			"table28_total_supply_clean_lb_m": _to_numeric(df[supply_col]),
			"table28_mill_use_clean_lb_m": _to_numeric(df[use_col]),
			"table28_ending_stocks_clean_lb_m": _to_numeric(df[ending_stock_col]),
			"table28_shorn_wool_greasy_lb_m": _to_numeric(df[shorn_wool_col]),
		}
	)
	return out.sort_values("year")


def _load_table_29() -> pd.DataFrame:
	df = _read_csv(WOOL_DIR / "Table 29.csv")
	df["year"] = df.iloc[:, 0].apply(_extract_year)
	df = df[df["year"].notna()].copy()
	df["year"] = df["year"].astype(int)

	grand_total_col = _pick_column(df.columns, ["grand", "total"])
	percent_col = _pick_column(df.columns, ["raw", "wool", "imports", "percent"])

	out = pd.DataFrame(
		{
			"year": df["year"],
			"table29_raw_wool_imports_1000lb": _to_numeric(df[grand_total_col]),
			"table29_share_of_total_raw_wool_imports_pct": _to_numeric(df[percent_col]),
		}
	)
	return out.sort_values("year")


def _load_table_33() -> pd.DataFrame:
	df = _read_csv(WOOL_DIR / "Table 33.csv")
	df["year"] = df.iloc[:, 0].apply(_extract_year)
	df = df[df["year"].notna()].copy()
	df["year"] = df["year"].astype(int)

	greasy_price_col = _pick_column(df.columns, ["greasy", "cents/pound"])
	micron_21_col = _pick_column(df.columns, ["micron 21", "u.s. dollars/pound"])
	micron_28_col = _pick_column(df.columns, ["micron 28", "u.s. dollars/pound"])

	out = pd.DataFrame(
		{
			"year": df["year"],
			"table33_greasy_basis_cents_per_lb": _to_numeric(df[greasy_price_col]),
			"table33_micron21_usd_per_lb": _to_numeric(df[micron_21_col]),
			"table33_micron28_usd_per_lb": _to_numeric(df[micron_28_col]),
		}
	)
	return out.sort_values("year")


def _load_table_35_wool_only() -> pd.DataFrame:
	df = _read_csv(TRADE_DIR / "Table 35.csv")
	df["year"] = df.iloc[:, 0].apply(_extract_year)
	df = df[df["year"].notna()].copy()
	df["year"] = df["year"].astype(int)

	wool_imports_col = _pick_column(df.columns, ["wool", "imports"])
	wool_exports_col = _pick_column(df.columns, ["wool", "exports"])

	out = pd.DataFrame(
		{
			"year": df["year"],
			"table35_wool_imports_1000lb": _to_numeric(df[wool_imports_col]),
			"table35_wool_exports_1000lb": _to_numeric(df[wool_exports_col]),
		}
	)
	return out.sort_values("year")


def _load_monthly_trade_table(path: Path, metric_prefix: str) -> tuple[pd.DataFrame, pd.DataFrame]:
	df = _read_csv(path)
	period_col = df.columns[0]
	numeric_cols = [col for col in df.columns if col != period_col]

	for col in numeric_cols:
		df[col] = _to_numeric(df[col])

	df["row_total_1000lb"] = df[numeric_cols].sum(axis=1, skipna=True)
	df["period"] = df[period_col].astype(str).str.strip()
	df["year"] = df["period"].apply(_extract_year)
	df["month_token"] = df["period"].str.extract(r"(Jan\.?|Feb\.?|Mar\.?|Apr\.?|May|Jun\.?|June|Jul\.?|July|Aug\.?|Sep\.?|Sept\.?|Oct\.?|Nov\.?|Dec\.?)", expand=False)
	df["month_num"] = df["month_token"].str.lower().map(MONTH_MAP)

	monthly = df[df["month_num"].notna() & df["year"].notna()].copy()
	monthly["year"] = monthly["year"].astype(int)
	monthly["month_num"] = monthly["month_num"].astype(int)
	monthly = (
		monthly.groupby(["year", "month_num"], as_index=False)["row_total_1000lb"]
		.sum()
		.rename(columns={"row_total_1000lb": f"{metric_prefix}_1000lb"})
	)

	annual_from_monthly = (
		monthly.groupby("year", as_index=False)[f"{metric_prefix}_1000lb"]
		.sum()
		.rename(columns={f"{metric_prefix}_1000lb": f"{metric_prefix}_annual_1000lb"})
	)

	year_only = df[df["month_num"].isna() & df["year"].notna()].copy()
	year_only["year"] = year_only["year"].astype(int)
	year_only = (
		year_only.groupby("year", as_index=False)["row_total_1000lb"]
		.sum()
		.rename(columns={"row_total_1000lb": f"{metric_prefix}_annual_1000lb"})
	)

	existing_years = set(annual_from_monthly["year"].tolist())
	year_only = year_only[~year_only["year"].isin(existing_years)]
	annual = pd.concat([annual_from_monthly, year_only], ignore_index=True).sort_values("year")

	return monthly, annual


def _plot_monthly_by_year(monthly: pd.DataFrame, value_col: str, title: str, output_name: str) -> None:
	pivot = monthly.pivot(index="month_num", columns="year", values=value_col).sort_index()
	plt.figure(figsize=(10, 5))
	for year in pivot.columns:
		plt.plot(pivot.index, pivot[year], marker="o", linewidth=2, label=str(year))
	plt.xticks(range(1, 13), MONTH_ORDER)
	plt.xlabel("Month")
	plt.ylabel("1,000 pounds")
	plt.title(title)
	plt.legend(ncol=4, fontsize=8)
	_save_figure(OUT_DIR / output_name)


def _plot_monthly_mean_variance(monthly: pd.DataFrame, value_col: str, title: str, output_name: str) -> pd.DataFrame:
	stats = (
		monthly.groupby("month_num")[value_col]
		.agg(mean="mean", var="var", std="std")
		.reset_index()
	)
	stats["month"] = stats["month_num"].map(lambda x: MONTH_ORDER[x - 1])

	plt.figure(figsize=(10, 5))
	plt.plot(stats["month_num"], stats["mean"], color="#0b6efd", marker="o", linewidth=2.5, label="Mean")
	lower = (stats["mean"] - stats["std"]).clip(lower=0)
	upper = stats["mean"] + stats["std"]
	plt.fill_between(stats["month_num"], lower, upper, color="#8ec5ff", alpha=0.35, label="Mean +/- 1 Std")
	plt.xticks(range(1, 13), MONTH_ORDER)
	plt.xlabel("Month")
	plt.ylabel("1,000 pounds")
	plt.title(title)
	plt.legend()
	_save_figure(OUT_DIR / output_name)

	return stats


def _plot_annual_small_multiples(annual: pd.DataFrame, metric_columns: list[str], output_name: str) -> None:
	valid_metrics = [col for col in metric_columns if col in annual.columns]
	if not valid_metrics:
		return

	n = len(valid_metrics)
	rows = int(np.ceil(n / 2))
	plt.figure(figsize=(14, max(4, rows * 3.2)))
	for idx, col in enumerate(valid_metrics, start=1):
		plt.subplot(rows, 2, idx)
		sub = annual[["year", col]].dropna()
		plt.plot(sub["year"], sub[col], marker="o", linewidth=1.8, color="#1f77b4")
		plt.title(col)
		plt.xlabel("Year")
		plt.ylabel("Value")
	_save_figure(OUT_DIR / output_name)


def _plot_correlation_heatmap(df: pd.DataFrame, output_name: str) -> pd.DataFrame:
	numeric = df.select_dtypes(include=[np.number]).copy()
	numeric = numeric.drop(columns=["year"], errors="ignore")
	numeric = numeric.loc[:, numeric.notna().sum() >= 8]
	corr = numeric.corr()

	plt.figure(figsize=(max(10, 0.4 * len(corr.columns)), max(8, 0.35 * len(corr.columns))))
	im = plt.imshow(corr.values, cmap="coolwarm", vmin=-1, vmax=1)
	plt.colorbar(im, fraction=0.03, pad=0.03, label="Correlation")
	plt.xticks(range(len(corr.columns)), corr.columns, rotation=90, fontsize=8)
	plt.yticks(range(len(corr.columns)), corr.columns, fontsize=8)
	plt.title("Wool Metrics Correlation Heatmap")
	_save_figure(OUT_DIR / output_name)

	return corr


def _prepare_pie_series(df: pd.DataFrame, country_col: str, year_cols: list[str]) -> pd.Series:
	tmp = df.copy()
	tmp[country_col] = tmp[country_col].astype(str).str.strip()
	for col in year_cols:
		tmp[col] = _to_numeric(tmp[col])
	tmp["value"] = tmp[year_cols].sum(axis=1, skipna=True)
	tmp = tmp[tmp["value"].notna()]
	tmp = tmp[~tmp[country_col].str.lower().isin(["total"])]
	series = tmp.set_index(country_col)["value"].sort_values(ascending=False)
	return series


def _plot_pie_top(series: pd.Series, title: str, output_name: str, top_n: int = 8) -> None:
	if series.empty:
		return

	series = series[series > 0]
	if series.empty:
		return

	top = series.iloc[:top_n].copy()
	if len(series) > top_n:
		top.loc["Other"] = series.iloc[top_n:].sum()

	plt.figure(figsize=(7, 7))
	plt.pie(top.values, labels=top.index, autopct="%1.1f%%", startangle=120, pctdistance=0.75)
	plt.title(title)
	plt.axis("equal")
	_save_figure(OUT_DIR / output_name)


def _plot_import_export_bars(df: pd.DataFrame, imports_col: str, exports_col: str, title: str, output_name: str) -> None:
	sub = df[["year", imports_col, exports_col]].dropna().sort_values("year")
	if sub.empty:
		return

	width = 0.42
	x = np.arange(len(sub))
	plt.figure(figsize=(12, 5))
	plt.bar(x - width / 2, sub[imports_col], width=width, label="Imports")
	plt.bar(x + width / 2, sub[exports_col], width=width, label="Exports")
	plt.xticks(x, sub["year"].astype(str), rotation=45)
	plt.xlabel("Year")
	plt.ylabel("1,000 pounds")
	plt.title(title)
	plt.legend()
	_save_figure(OUT_DIR / output_name)


def _build_report(
	annual: pd.DataFrame,
	import_stats: pd.DataFrame,
	export_stats: pd.DataFrame,
	corr: pd.DataFrame,
) -> None:
	report_path = OUT_DIR / "README.md"
	corr_pairs = (
		corr.where(~np.eye(len(corr), dtype=bool))
		.stack()
		.abs()
		.sort_values(ascending=False)
	)
	top_pairs = corr_pairs.head(8)

	lines = [
		"# Wool EDA",
		"",
		"Generated by `models/wool_eda.py`.",
		"",
		"## Scope",
		"- Wool-only datasets from `U.S.WoolSupplyandDemand` and wool sections in `U.S.TextileFiberTrade`.",
		"- Cotton-only metrics are excluded from the analysis outputs.",
		"",
		"## Core Outputs",
		"- Monthly charts by year for wool imports/exports (Tables 40 and 41).",
		"- Monthly mean and variance-band charts (mean +/- std).",
		"- Yearly metric trend small multiples.",
		"- Correlation heatmap over annual wool metrics.",
		"- Country-share pie charts for key wool import/export tables.",
		"",
		"## Data Files",
		"- `annual_wool_metrics.csv`",
		"- `monthly_wool_imports_aggregated.csv`",
		"- `monthly_wool_exports_aggregated.csv`",
		"- `monthly_import_stats.csv`",
		"- `monthly_export_stats.csv`",
		"- `correlation_matrix.csv`",
		"",
		"## Quick Stats",
		f"- Years in annual panel: {int(annual['year'].min())} to {int(annual['year'].max())}",
		f"- Annual metrics count: {annual.shape[1] - 1}",
	]

	if not import_stats.empty:
		top_month = import_stats.sort_values("mean", ascending=False).iloc[0]
		lines.append(
			f"- Highest average monthly wool imports: {top_month['month']} ({top_month['mean']:.2f} thousand lb)"
		)
	if not export_stats.empty:
		top_month = export_stats.sort_values("mean", ascending=False).iloc[0]
		lines.append(
			f"- Highest average monthly wool exports: {top_month['month']} ({top_month['mean']:.2f} thousand lb)"
		)

	lines.extend(["", "## Strongest Absolute Correlations"])
	if top_pairs.empty:
		lines.append("- No sufficient overlap to compute stable correlations.")
	else:
		for (left, right), value in top_pairs.items():
			lines.append(f"- `{left}` vs `{right}`: {value:.3f}")

	report_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def run() -> None:
	OUT_DIR.mkdir(parents=True, exist_ok=True)
	_setup_plot_style()

	table28 = _load_table_28()
	table29 = _load_table_29()
	table33 = _load_table_33()
	table35 = _load_table_35_wool_only()
	monthly_imports, annual_imports = _load_monthly_trade_table(
		TRADE_DIR / "Table 40.csv", "table40_wool_imports_est"
	)
	monthly_exports, annual_exports = _load_monthly_trade_table(
		TRADE_DIR / "Table 41.csv", "table41_wool_exports_est"
	)

	annual = table28.merge(table29, on="year", how="outer")
	annual = annual.merge(table33, on="year", how="outer")
	annual = annual.merge(table35, on="year", how="outer")
	annual = annual.merge(annual_imports, on="year", how="outer")
	annual = annual.merge(annual_exports, on="year", how="outer")
	annual = annual.sort_values("year").reset_index(drop=True)

	monthly_imports = monthly_imports.sort_values(["year", "month_num"]).reset_index(drop=True)
	monthly_exports = monthly_exports.sort_values(["year", "month_num"]).reset_index(drop=True)

	annual.to_csv(OUT_DIR / "annual_wool_metrics.csv", index=False)
	monthly_imports.to_csv(OUT_DIR / "monthly_wool_imports_aggregated.csv", index=False)
	monthly_exports.to_csv(OUT_DIR / "monthly_wool_exports_aggregated.csv", index=False)

	_plot_monthly_by_year(
		monthly_imports,
		"table40_wool_imports_est_1000lb",
		"Monthly Wool Imports by Year (Aggregated Table 40)",
		"monthly_imports_by_year.png",
	)
	_plot_monthly_by_year(
		monthly_exports,
		"table41_wool_exports_est_1000lb",
		"Monthly Wool Exports by Year (Aggregated Table 41)",
		"monthly_exports_by_year.png",
	)

	import_stats = _plot_monthly_mean_variance(
		monthly_imports,
		"table40_wool_imports_est_1000lb",
		"Wool Imports: Monthly Mean and Variance Band",
		"monthly_imports_mean_std_band.png",
	)
	export_stats = _plot_monthly_mean_variance(
		monthly_exports,
		"table41_wool_exports_est_1000lb",
		"Wool Exports: Monthly Mean and Variance Band",
		"monthly_exports_mean_std_band.png",
	)
	import_stats.to_csv(OUT_DIR / "monthly_import_stats.csv", index=False)
	export_stats.to_csv(OUT_DIR / "monthly_export_stats.csv", index=False)

	_plot_import_export_bars(
		annual,
		"table35_wool_imports_1000lb",
		"table35_wool_exports_1000lb",
		"Yearly Wool Imports vs Exports (Table 35)",
		"yearly_wool_import_export_bars_table35.png",
	)
	_plot_import_export_bars(
		annual,
		"table40_wool_imports_est_annual_1000lb",
		"table41_wool_exports_est_annual_1000lb",
		"Yearly Wool Imports vs Exports (Tables 40/41 Aggregated)",
		"yearly_wool_import_export_bars_table40_41.png",
	)

	_plot_annual_small_multiples(
		annual,
		[
			"table28_production_clean_lb_m",
			"table28_total_supply_clean_lb_m",
			"table28_mill_use_clean_lb_m",
			"table28_ending_stocks_clean_lb_m",
			"table29_raw_wool_imports_1000lb",
			"table35_wool_imports_1000lb",
			"table35_wool_exports_1000lb",
			"table33_greasy_basis_cents_per_lb",
			"table33_micron21_usd_per_lb",
			"table33_micron28_usd_per_lb",
			"table40_wool_imports_est_annual_1000lb",
			"table41_wool_exports_est_annual_1000lb",
		],
		"annual_wool_metrics_small_multiples.png",
	)

	corr = _plot_correlation_heatmap(annual, "annual_wool_correlation_heatmap.png")
	corr.to_csv(OUT_DIR / "correlation_matrix.csv")

	table30 = _read_csv(WOOL_DIR / "Table 30.csv")
	year_cols_30 = [col for col in table30.columns if "2021" in col]
	series30 = _prepare_pie_series(table30, table30.columns[0], year_cols_30)
	_plot_pie_top(
		series30,
		"Wool Imports by Country (Table 30, 2021)",
		"pie_table30_import_origins_2021.png",
	)

	table32 = _read_csv(WOOL_DIR / "Table 32.csv")
	import_cols_32 = [col for col in table32.columns if "2021" in col and "imports" in col.lower()]
	export_cols_32 = [col for col in table32.columns if "2021" in col and "exports" in col.lower()]
	series32_import = _prepare_pie_series(table32, table32.columns[0], import_cols_32)
	series32_export = _prepare_pie_series(table32, table32.columns[0], export_cols_32)
	_plot_pie_top(
		series32_import,
		"Wool Top Imports by Country (Table 32, 2021)",
		"pie_table32_import_partners_2021.png",
	)
	_plot_pie_top(
		series32_export,
		"Wool Top Exports by Country (Table 32, 2021)",
		"pie_table32_export_partners_2021.png",
	)

	table34 = _read_csv(WOOL_DIR / "Table 34.csv")
	year_cols_34 = [col for col in table34.columns if "2021" in col]
	series34 = _prepare_pie_series(table34, table34.columns[0], year_cols_34)
	_plot_pie_top(
		series34,
		"Mohair Exports by Destination (Table 34, 2021)",
		"pie_table34_destinations_2021.png",
	)

	_build_report(annual=annual, import_stats=import_stats, export_stats=export_stats, corr=corr)

	print(f"Wool EDA complete. Outputs written to: {OUT_DIR}")


if __name__ == "__main__":
	run()
