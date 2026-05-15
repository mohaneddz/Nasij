from __future__ import annotations

import ast
from pathlib import Path
from typing import Any

import pandas as pd


def _default_seed_path() -> Path:
    # backend/shared -> backend -> project root -> nasij-web/nfn-backend/app/seed.py
    return (
        Path(__file__).resolve().parents[2]
        / "nasij-web"
        / "nfn-backend"
        / "app"
        / "seed.py"
    )


def _extract_literal_from_assignments(func_node: ast.FunctionDef, name: str) -> Any | None:
    for stmt in func_node.body:
        if isinstance(stmt, ast.Assign):
            for target in stmt.targets:
                if isinstance(target, ast.Name) and target.id == name:
                    return ast.literal_eval(stmt.value)
    return None


def load_seed_batches_and_alerts(seed_path: Path | None = None) -> tuple[pd.DataFrame, pd.DataFrame]:
    path = seed_path or _default_seed_path()
    if not path.exists():
        raise FileNotFoundError(f"NFN seed file not found at {path}")

    tree = ast.parse(path.read_text(encoding="utf-8"))
    main_func = None
    for node in tree.body:
        if isinstance(node, ast.FunctionDef) and node.name == "main":
            main_func = node
            break

    if main_func is None:
        raise ValueError("Could not find `main()` in NFN seed file.")

    batches: list[dict[str, Any]] = _extract_literal_from_assignments(main_func, "batches") or []
    alerts_data: list[dict[str, Any]] = (
        _extract_literal_from_assignments(main_func, "alerts_data") or []
    )
    annex_defaults: dict[str, dict[str, Any]] = (
        _extract_literal_from_assignments(main_func, "annex_defaults") or {}
    )
    annex_overrides: dict[str, dict[str, Any]] = (
        _extract_literal_from_assignments(main_func, "annex_overrides") or {}
    )

    # Handle `batches.extend([...])`
    for stmt in main_func.body:
        if not isinstance(stmt, ast.Expr) or not isinstance(stmt.value, ast.Call):
            continue
        call = stmt.value
        if (
            isinstance(call.func, ast.Attribute)
            and isinstance(call.func.value, ast.Name)
            and call.func.value.id == "batches"
            and call.func.attr == "extend"
            and call.args
        ):
            extra = ast.literal_eval(call.args[0])
            batches.extend(extra)

    merged_batches: list[dict[str, Any]] = []
    for batch in batches:
        row = dict(batch)
        source_type = str(row.get("source_type", "")).upper()
        row.update(annex_defaults.get(source_type, {}))
        row.update(annex_overrides.get(str(row.get("batch_id")), {}))
        row.setdefault("annex_metadata", {})
        merged_batches.append(row)

    batches_df = pd.DataFrame(merged_batches)
    alerts_df = pd.DataFrame(alerts_data)
    return batches_df, alerts_df

