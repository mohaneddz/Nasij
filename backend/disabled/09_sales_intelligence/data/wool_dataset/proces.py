from pathlib import Path
import csv
import re

import pandas as pd


MOJIBAKE_REPLACEMENTS = {
	"\u00e2\u20ac\u201c": "-",  # â€“
	"\u00e2\u20ac\u201d": "-",  # â€”
	"\u00e2\u20ac\u02dc": "'",  # â€˜
	"\u00e2\u20ac\u2122": "'",  # â€™
	"\u00e2\u20ac\u0153": '"',  # â€œ
	"\u00e2\u20ac\u009d": '"',  # â€
	"\u00c2": "",  # Â
}

NUMERIC_RE = re.compile(r"^-?\d+(?:\.\d+)?$")
YEAR_RE = re.compile(r"^(?:19|20)\d{2}$")
MONTH_VALUES = {
	"jan",
	"jan.",
	"feb",
	"feb.",
	"mar",
	"mar.",
	"apr",
	"apr.",
	"may",
	"jun",
	"jun.",
	"june",
	"jul",
	"jul.",
	"july",
	"aug",
	"aug.",
	"sep",
	"sep.",
	"sept",
	"sept.",
	"oct",
	"oct.",
	"nov",
	"nov.",
	"dec",
	"dec.",
}


def _safe_filename(name: str) -> str:
	invalid_chars = '<>:"/\\|?*'
	safe = "".join("_" if c in invalid_chars else c for c in name).strip()
	return safe or "Sheet"


def _normalize_text(value: object) -> str:
	if pd.isna(value):
		return ""

	text = str(value).strip()
	if not text:
		return ""
	if re.fullmatch(r"Unnamed:\s*\d+", text):
		return ""

	for old, new in MOJIBAKE_REPLACEMENTS.items():
		text = text.replace(old, new)

	text = re.sub(r"\s+", " ", text)
	return text.strip()


def _is_numeric_token(value: str) -> bool:
	if not value:
		return False
	return bool(NUMERIC_RE.fullmatch(value.replace(",", "")))


def _is_placeholder_token(value: str) -> bool:
	return value in {"--", "---"}


def _normalize_data_value(value: str) -> str:
	if not value:
		return ""
	if _is_placeholder_token(value):
		return ""

	candidate = value.replace(",", "")
	if NUMERIC_RE.fullmatch(candidate):
		number = float(candidate)
		if number.is_integer():
			return str(int(number))
		return f"{number:.10f}".rstrip("0").rstrip(".")

	return value


def _dedupe_headers(headers: list[str]) -> list[str]:
	counts: dict[str, int] = {}
	deduped: list[str] = []
	for header in headers:
		base = header or "column"
		seen = counts.get(base, 0)
		if seen == 0:
			deduped.append(base)
		else:
			deduped.append(f"{base}_{seen + 1}")
		counts[base] = seen + 1
	return deduped


def _drop_empty_rows_cols(df: pd.DataFrame) -> pd.DataFrame:
	if df.empty:
		return df

	non_empty_rows = df.ne("").any(axis=1)
	df = df.loc[non_empty_rows]
	if df.empty:
		return df

	non_empty_cols = df.ne("").any(axis=0)
	df = df.loc[:, non_empty_cols]
	return df.reset_index(drop=True)


def _row_values(df: pd.DataFrame, index: int) -> list[str]:
	return [_normalize_text(value) for value in df.iloc[index].tolist()]


def _first_non_empty(values: list[str]) -> str:
	for value in values:
		if value:
			return value
	return ""


def _row_data_token_count(values: list[str]) -> int:
	count = 0
	for value in values[1:]:
		if _is_numeric_token(value) or _is_placeholder_token(value):
			count += 1
	return count


def _looks_like_header_row(first_value: str, joined_lower: str) -> bool:
	first = first_value.lower()
	if first in {"year", "month", "country", "calendar", "and", "table"}:
		return True
	if first.startswith("table "):
		return True
	if joined_lower.startswith("source:") or joined_lower.startswith("note:"):
		return True
	return False


def _find_data_start(df: pd.DataFrame) -> int | None:
	for idx in range(len(df)):
		values = _row_values(df, idx)
		non_empty = [value for value in values if value]
		if len(non_empty) < 2:
			continue

		first = _first_non_empty(values)
		joined_lower = " ".join(non_empty).lower()
		if _looks_like_header_row(first, joined_lower):
			continue
		if _row_data_token_count(values) < 1:
			continue

		data_like_rows = 0
		for look_ahead in range(idx, min(idx + 8, len(df))):
			look_values = _row_values(df, look_ahead)
			look_non_empty = [value for value in look_values if value]
			if len(look_non_empty) < 2:
				continue
			look_first = _first_non_empty(look_values)
			look_joined_lower = " ".join(look_non_empty).lower()
			if _looks_like_header_row(look_first, look_joined_lower):
				continue
			if _row_data_token_count(look_values) >= 1:
				data_like_rows += 1

		if data_like_rows >= 2:
			return idx

	return None


def _build_headers(df: pd.DataFrame, data_start: int) -> tuple[list[str], list[str]]:
	pre_data = df.iloc[:data_start]
	metadata_lines: list[str] = []
	header_indices: list[int] = []

	for idx in pre_data.index:
		values = _row_values(df, idx)
		non_empty = [value for value in values if value]
		if not non_empty:
			continue

		joined = " ".join(non_empty)
		lowered = joined.lower()

		if lowered.startswith("source:") or lowered.startswith("note:"):
			metadata_lines.append(joined)
			continue

		if len(non_empty) == 1 and (
			lowered.startswith("table ") or lowered.startswith("u.s.")
		):
			metadata_lines.append(non_empty[0])
			continue

		header_indices.append(idx)

	header_indices = header_indices[-6:]
	if not header_indices:
		fallback_headers = [f"column_{idx + 1}" for idx in range(df.shape[1])]
		return fallback_headers, metadata_lines

	header_block = df.loc[header_indices].replace("", pd.NA).ffill(axis=1).ffill(axis=0)
	headers: list[str] = []

	for col_idx in range(df.shape[1]):
		tokens: list[str] = []
		for raw_value in header_block.iloc[:, col_idx].tolist():
			raw_token = _normalize_text(raw_value).strip(" ,-")
			if not raw_token:
				continue

			parts: list[str] = []
			for part in raw_token.split("|"):
				clean_part = part.strip(" ,-")
				if not clean_part:
					continue
				lowered = clean_part.lower()
				if lowered in {"and", "or"}:
					continue
				if lowered.startswith("unnamed:"):
					continue
				if lowered.startswith("table "):
					continue
				parts.append(clean_part)

			token = " | ".join(parts)
			if not token:
				continue
			if token not in tokens:
				tokens.append(token)

		header = " | ".join(tokens[-3:]) if tokens else f"column_{col_idx + 1}"
		headers.append(header)

	return _dedupe_headers(headers), metadata_lines


def _is_group_year_row(values: list[str]) -> bool:
	if not values:
		return False
	first = values[0]
	if not YEAR_RE.fullmatch(first):
		return False
	return all(not value for value in values[1:])


def _is_month_row_label(label: str) -> bool:
	return label.lower().strip() in MONTH_VALUES


def _process_table_sheet(df: pd.DataFrame) -> tuple[pd.DataFrame | None, list[str], str]:
	data_start = _find_data_start(df)
	if data_start is None:
		return None, [], "Could not detect a stable tabular data region."

	headers, metadata_lines = _build_headers(df, data_start)
	data_rows: list[list[str]] = []
	current_year = ""

	for idx in range(data_start, len(df)):
		values = _row_values(df, idx)
		if all(not value for value in values):
			continue

		joined_lower = " ".join(value for value in values if value).lower()
		if joined_lower.startswith("source:") or joined_lower.startswith("note:"):
			metadata_lines.append(" ".join(value for value in values if value))
			continue
		if set(joined_lower) <= {" ", ",", "`", "-"}:
			continue

		if _is_group_year_row(values):
			current_year = values[0]
			continue

		if values and values[0] and _is_month_row_label(values[0]) and current_year:
			values[0] = f"{current_year} {values[0]}"

		min_data_tokens = 1
		first_value = values[0].lower() if values and values[0] else ""
		if _row_data_token_count(values) < min_data_tokens and first_value not in {"total", "subtotal"}:
			continue

		normalized_values = [_normalize_data_value(value) for value in values]
		if all(not value for value in normalized_values):
			continue
		if all(not value for value in normalized_values[1:]):
			continue

		data_rows.append(normalized_values)

	if not data_rows:
		return None, metadata_lines, "No valid data rows remained after cleaning."

	processed_df = pd.DataFrame(data_rows, columns=headers)
	processed_df = processed_df.loc[:, processed_df.ne("").any(axis=0)]

	if processed_df.empty or processed_df.shape[1] < 2:
		return None, metadata_lines, "Table output was too sparse after processing."

	return processed_df, metadata_lines, ""


def _is_descriptive_sheet(df: pd.DataFrame, sheet_name: str) -> bool:
	if "content" in sheet_name.lower():
		return True

	non_empty_cells = int(df.ne("").sum().sum())
	if non_empty_cells == 0:
		return True

	max_non_empty_per_row = int(df.ne("").sum(axis=1).max())
	numeric_cells = 0
	for value in df.to_numpy().flatten():
		text = _normalize_text(value)
		if _is_numeric_token(text):
			numeric_cells += 1

	numeric_ratio = numeric_cells / non_empty_cells
	if max_non_empty_per_row <= 2 and numeric_ratio < 0.15:
		return True

	return False


def _extract_text_lines(df: pd.DataFrame, limit: int = 40) -> list[str]:
	lines: list[str] = []
	for idx in range(len(df)):
		values = _row_values(df, idx)
		non_empty = [value for value in values if value]
		if not non_empty:
			continue
		line = " | ".join(non_empty)
		if line not in lines:
			lines.append(line)
		if len(lines) >= limit:
			break
	return lines


def _write_readme(
	readme_path: Path,
	workbook_name: str,
	sheet_name: str,
	reason: str,
	lines: list[str],
) -> None:
	content_lines = [
		f"# {sheet_name}",
		"",
		"This sheet was exported as documentation instead of CSV.",
		"",
		"## Why",
		f"- {reason}",
		f"- Workbook: {workbook_name}",
		f"- Sheet: {sheet_name}",
		"",
		"## Extracted Content",
	]

	if lines:
		for line in lines:
			content_lines.append(f"- {line}")
	else:
		content_lines.append("- No non-empty content was detected.")

	readme_path.write_text("\n".join(content_lines) + "\n", encoding="utf-8")


def _prepare_dataframe(raw_df: pd.DataFrame) -> pd.DataFrame:
	df = raw_df.map(_normalize_text)
	return _drop_empty_rows_cols(df)


def _export_sheet_output(
	output_dir: Path,
	workbook_name: str,
	sheet_name: str,
	file_stem: str,
	df: pd.DataFrame,
) -> tuple[str, Path]:
	csv_path = output_dir / f"{file_stem}.csv"
	readme_path = output_dir / f"{file_stem}.README.md"

	if df.empty or _is_descriptive_sheet(df, sheet_name):
		if csv_path.exists():
			csv_path.unlink()
		if readme_path.exists():
			readme_path.unlink()
		reason = "The sheet is descriptive/index-style content and not a stable data table."
		lines = _extract_text_lines(df)
		_write_readme(readme_path, workbook_name, sheet_name, reason, lines)
		return "Documented", readme_path

	processed_df, metadata_lines, error_reason = _process_table_sheet(df)
	if processed_df is None:
		if csv_path.exists():
			csv_path.unlink()
		if readme_path.exists():
			readme_path.unlink()
		reason = error_reason or "The table could not be confidently normalized."
		lines = metadata_lines + _extract_text_lines(df)
		_write_readme(readme_path, workbook_name, sheet_name, reason, lines)
		return "Documented", readme_path

	if readme_path.exists():
		readme_path.unlink()
	processed_df.to_csv(csv_path, index=False)
	return "Processed", csv_path


def _read_loose_csv(csv_path: Path) -> pd.DataFrame:
	rows: list[list[str]] = []
	with csv_path.open("r", encoding="utf-8", errors="replace", newline="") as handle:
		reader = csv.reader(handle)
		for row in reader:
			rows.append([_normalize_text(cell) for cell in row])

	if not rows:
		return pd.DataFrame()

	max_cols = max(len(row) for row in rows)
	padded = [row + [""] * (max_cols - len(row)) for row in rows]
	return pd.DataFrame(padded)


def _process_xlsx_workbooks(root: Path) -> int:
	xlsx_files = [p for p in root.rglob("*.xlsx") if not p.name.startswith("~$")]
	if not xlsx_files:
		return 0

	for xlsx_path in xlsx_files:
		output_dir = xlsx_path.with_suffix("")
		output_dir.mkdir(exist_ok=True)
		excel_file = pd.ExcelFile(xlsx_path)
		used_names: set[str] = set()

		for sheet_name in excel_file.sheet_names:
			raw_df = pd.read_excel(excel_file, sheet_name=sheet_name, header=None, dtype=object)
			df = _prepare_dataframe(raw_df)

			base_name = _safe_filename(sheet_name)
			file_name = base_name
			counter = 1
			while file_name.lower() in used_names:
				counter += 1
				file_name = f"{base_name}_{counter}"
			used_names.add(file_name.lower())

			mode, output_path = _export_sheet_output(
				output_dir=output_dir,
				workbook_name=xlsx_path.name,
				sheet_name=sheet_name,
				file_stem=file_name,
				df=df,
			)
			print(f"{mode}: {xlsx_path} [{sheet_name}] -> {output_path}")

	return len(xlsx_files)


def _process_existing_csv_folders(root: Path) -> int:
	processed_folders = 0

	for folder in sorted(root.rglob("*")):
		if not folder.is_dir():
			continue

		csv_files = sorted(folder.glob("*.csv"))
		if not csv_files:
			continue

		processed_folders += 1
		for csv_path in csv_files:
			sheet_name = csv_path.stem
			raw_df = _read_loose_csv(csv_path)
			df = _prepare_dataframe(raw_df)
			file_stem = _safe_filename(sheet_name)
			mode, output_path = _export_sheet_output(
				output_dir=folder,
				workbook_name=folder.name,
				sheet_name=sheet_name,
				file_stem=file_stem,
				df=df,
			)
			print(f"{mode}: {folder} [{sheet_name}] -> {output_path}")

	return processed_folders


def convert_all_xlsx_to_csv(root_dir: str = ".") -> None:
	root = Path(root_dir)

	xlsx_count = _process_xlsx_workbooks(root)
	if xlsx_count > 0:
		return

	csv_folder_count = _process_existing_csv_folders(root)
	if csv_folder_count == 0:
		print(f"No .xlsx files or CSV folders were found under {root.resolve()}.")


if __name__ == "__main__":
	convert_all_xlsx_to_csv()
