from __future__ import annotations

import json
import os
from datetime import datetime, timezone
from pathlib import Path

import psycopg
from psycopg.rows import dict_row


ROOT = Path(__file__).resolve().parents[1]
SQL_DIR = ROOT / "sql"

BATCH_COLS = [
    "batch_id",
    "source_type",
    "breed",
    "wilaya",
    "status",
    "creator_id",
    "collector_id",
    "purchase_price_dzd",
    "location_lat",
    "location_lng",
    "type_de_laine",
    "proprete_score",
    "sacs_count",
    "weight_raw_e1_kg",
    "weight_after_handclean_kg",
    "stockage_zone",
    "classification",
    "temperature_tas_celsius",
    "taux_matiere_vegetale_percent",
    "weight_clean_d2_kg",
    "yield_percentage",
    "humidite_sortie_percent",
    "ph_laine",
    "fiber_length_mm",
    "finesse_micron",
    "humidity_percent",
    "final_destination",
    "is_ready_for_sale",
    "action_timestamp",
    "synced_at",
    "created_at",
]

ALERT_COLS = [
    "alert_id",
    "batch_id",
    "alert_type",
    "severity",
    "is_resolved",
    "action",
    "created_at",
]

USER_COLS = [
    "user_id",
    "sector",
    "wilaya",
    "created_at",
]

EVENT_COMPARE_FIELDS = [
    "status",
    "weight_raw_e1_kg",
    "weight_after_handclean_kg",
    "weight_clean_d2_kg",
    "temperature_tas_celsius",
    "taux_matiere_vegetale_percent",
    "final_destination",
]


def _load_env_file(path: Path) -> None:
    if not path.exists():
        return

    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        if key and key not in os.environ:
            os.environ[key] = value


def _read_sql(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _exec_sql_file(conn: psycopg.Connection, path: Path) -> None:
    conn.execute(_read_sql(path))


def _build_insert_sql(table_name: str, cols: list[str]) -> str:
    columns = ", ".join(cols)
    values = ", ".join(f"%({c})s" for c in cols)
    return f"insert into {table_name} ({columns}) values ({values})"


def _executemany(conn: psycopg.Connection, sql: str, rows: list[dict]) -> None:
    if not rows:
        return
    with conn.cursor() as cur:
        cur.executemany(sql, rows)


def _get_watermark(wh: psycopg.Connection) -> datetime:
    row = wh.execute(
        "select last_ts from mart.etl_watermark where pipeline = 'app_to_wh'"
    ).fetchone()
    return row["last_ts"]


def _update_watermark(wh: psycopg.Connection, new_ts: datetime) -> None:
    wh.execute(
        """
        update mart.etl_watermark
        set last_ts = %s
        where pipeline = 'app_to_wh'
        """,
        (new_ts,),
    )


def _fetch_changed_batches(src: psycopg.Connection, last_ts: datetime) -> list[dict]:
    return src.execute(
        """
        select
            batch_id,
            source_type,
            breed,
            wilaya,
            status,
            creator_id,
            collector_id,
            purchase_price_dzd,
            location_lat,
            location_lng,
            type_de_laine,
            proprete_score,
            sacs_count,
            weight_raw_e1_kg,
            weight_after_handclean_kg,
            stockage_zone,
            classification,
            temperature_tas_celsius,
            taux_matiere_vegetale_percent,
            weight_clean_d2_kg,
            yield_percentage,
            humidite_sortie_percent,
            ph_laine,
            fiber_length_mm,
            finesse_micron,
            humidity_percent,
            final_destination,
            is_ready_for_sale,
            action_timestamp,
            synced_at,
            created_at,
            coalesce(synced_at, created_at) as change_ts
        from public.batches
        where coalesce(synced_at, created_at) > %s
        order by coalesce(synced_at, created_at), batch_id
        """,
        (last_ts,),
    ).fetchall()


def _fetch_changed_alerts(src: psycopg.Connection, last_ts: datetime) -> list[dict]:
    return src.execute(
        """
        select
            id as alert_id,
            batch_id,
            alert_type,
            severity,
            is_resolved,
            action,
            created_at
        from public.alerts
        where created_at > %s
        order by created_at, id
        """,
        (last_ts,),
    ).fetchall()


def _refresh_users(src: psycopg.Connection, wh: psycopg.Connection) -> None:
    # No phone_number copied by design.
    users = src.execute(
        """
        select
            id as user_id,
            sector::text as sector,
            wilaya,
            created_at
        from public.users
        """
    ).fetchall()

    wh.execute("truncate raw.users")
    if users:
        _executemany(wh, _build_insert_sql("raw.users", USER_COLS), users)


def _get_existing_batches(wh: psycopg.Connection, batch_ids: list[str]) -> dict[str, dict]:
    if not batch_ids:
        return {}

    rows = wh.execute(
        """
        select *
        from raw.batches
        where batch_id = any(%s)
        """,
        (batch_ids,),
    ).fetchall()
    return {row["batch_id"]: row for row in rows}


def _insert_batch_events(
    wh: psycopg.Connection, changed_batches: list[dict], previous_map: dict[str, dict]
) -> None:
    event_rows = []

    for row in changed_batches:
        batch_id = row["batch_id"]
        event_time = row["synced_at"] or row["created_at"] or datetime.now(timezone.utc)
        prev = previous_map.get(batch_id)

        if prev is None:
            event_rows.append(
                {
                    "batch_id": batch_id,
                    "event_time": event_time,
                    "event_type": "BATCH_CREATED",
                    "status_from": None,
                    "status_to": row.get("status"),
                    "payload": json.dumps(
                        {
                            "source_type": row.get("source_type"),
                            "breed": row.get("breed"),
                        }
                    ),
                }
            )
            continue

        if prev.get("status") != row.get("status"):
            event_rows.append(
                {
                    "batch_id": batch_id,
                    "event_time": event_time,
                    "event_type": "STATUS_CHANGED",
                    "status_from": prev.get("status"),
                    "status_to": row.get("status"),
                    "payload": json.dumps(
                        {
                            "from": prev.get("status"),
                            "to": row.get("status"),
                        }
                    ),
                }
            )

        changed_fields = []
        for f in EVENT_COMPARE_FIELDS:
            if prev.get(f) != row.get(f):
                changed_fields.append(f)

        if changed_fields:
            event_rows.append(
                {
                    "batch_id": batch_id,
                    "event_time": event_time,
                    "event_type": "BATCH_UPDATED",
                    "status_from": prev.get("status"),
                    "status_to": row.get("status"),
                    "payload": json.dumps({"changed_fields": changed_fields}),
                }
            )

    if not event_rows:
        return

    _executemany(
        wh,
        """
        insert into raw.batch_events (
            batch_id, event_time, event_type, status_from, status_to, payload
        ) values (
            %(batch_id)s, %(event_time)s, %(event_type)s, %(status_from)s, %(status_to)s, %(payload)s::jsonb
        )
        """,
        event_rows,
    )


def _sync_batches(wh: psycopg.Connection, changed_batches: list[dict]) -> None:
    if not changed_batches:
        return

    batch_ids = [row["batch_id"] for row in changed_batches]
    previous_map = _get_existing_batches(wh, batch_ids)
    _insert_batch_events(wh, changed_batches, previous_map)

    wh.execute("delete from raw.batches where batch_id = any(%s)", (batch_ids,))
    cleaned = [{k: row.get(k) for k in BATCH_COLS} for row in changed_batches]
    _executemany(wh, _build_insert_sql("raw.batches", BATCH_COLS), cleaned)


def _sync_alerts(wh: psycopg.Connection, changed_alerts: list[dict]) -> None:
    if not changed_alerts:
        return

    alert_ids = [row["alert_id"] for row in changed_alerts]
    wh.execute("delete from raw.alerts where alert_id = any(%s)", (alert_ids,))
    cleaned = [{k: row.get(k) for k in ALERT_COLS} for row in changed_alerts]
    _executemany(wh, _build_insert_sql("raw.alerts", ALERT_COLS), cleaned)


def _rebuild_marts(wh: psycopg.Connection) -> None:
    as_of_ts = datetime.now(timezone.utc)

    wh.execute("truncate mart.fact_batch_snapshot")
    wh.execute(
        """
        insert into mart.fact_batch_snapshot (
            batch_id, source_type, breed, wilaya, status, final_destination, purchase_price_dzd,
            weight_raw_e1_kg, weight_after_handclean_kg, weight_clean_d2_kg,
            current_yield_pct, d1_loss_pct, action_timestamp, synced_at, created_at
        )
        select
            batch_id,
            source_type,
            breed,
            wilaya,
            status,
            final_destination,
            purchase_price_dzd,
            weight_raw_e1_kg,
            weight_after_handclean_kg,
            weight_clean_d2_kg,
            round((weight_clean_d2_kg / nullif(weight_after_handclean_kg, 0)) * 100, 2) as current_yield_pct,
            round(((weight_raw_e1_kg - weight_after_handclean_kg) / nullif(weight_raw_e1_kg, 0)) * 100, 2) as d1_loss_pct,
            action_timestamp,
            synced_at,
            created_at
        from raw.batches
        """
    )

    wh.execute("truncate mart.fact_alert_event")
    wh.execute(
        """
        insert into mart.fact_alert_event (
            alert_id, batch_id, alert_type, severity, is_resolved, action, created_at
        )
        select
            alert_id, batch_id, alert_type, severity, is_resolved, action, created_at
        from raw.alerts
        """
    )

    wh.execute("truncate mart.fact_batch_event")
    wh.execute(
        """
        insert into mart.fact_batch_event (
            event_id, batch_id, event_time, event_type, status_from, status_to, payload, detected_at
        )
        select
            event_id, batch_id, event_time, event_type, status_from, status_to, payload, detected_at
        from raw.batch_events
        """
    )

    wh.execute("truncate mart.kpi_wip_by_status")
    wh.execute(
        """
        insert into mart.kpi_wip_by_status (status, batch_count, as_of_ts)
        select status, count(*)::int as batch_count, %s
        from mart.fact_batch_snapshot
        group by status
        """,
        (as_of_ts,),
    )

    wh.execute("truncate mart.kpi_yield_summary")
    wh.execute(
        """
        insert into mart.kpi_yield_summary (metric_name, metric_value, as_of_ts)
        select metric_name, metric_value, %s
        from (
            select 'avg_yield_overall_pct'::text as metric_name,
                   coalesce(round(avg(current_yield_pct), 2), 0)::numeric(10,2) as metric_value
            from mart.fact_batch_snapshot
            union all
            select 'avg_yield_c1_pct',
                   coalesce(round(avg(current_yield_pct), 2), 0)::numeric(10,2)
            from mart.fact_batch_snapshot
            where source_type = 'C1'
            union all
            select 'avg_yield_c2_pct',
                   coalesce(round(avg(current_yield_pct), 2), 0)::numeric(10,2)
            from mart.fact_batch_snapshot
            where source_type = 'C2'
            union all
            select 'total_declared_kg',
                   coalesce(round(sum(weight_raw_e1_kg), 2), 0)::numeric(10,2)
            from mart.fact_batch_snapshot
            union all
            select 'total_after_handclean_kg',
                   coalesce(round(sum(weight_after_handclean_kg), 2), 0)::numeric(10,2)
            from mart.fact_batch_snapshot
        ) t
        """,
        (as_of_ts,),
    )

    wh.execute("truncate mart.kpi_alerts_summary")
    wh.execute(
        """
        insert into mart.kpi_alerts_summary (severity, active_count, total_count, as_of_ts)
        select
            severity,
            sum(case when is_resolved = false then 1 else 0 end)::int as active_count,
            count(*)::int as total_count,
            %s
        from mart.fact_alert_event
        group by severity
        """,
        (as_of_ts,),
    )


def main() -> None:
    _load_env_file(ROOT / ".env")

    source_db_url = os.getenv("SOURCE_DB_URL")
    warehouse_db_url = os.getenv("WAREHOUSE_DB_URL")

    if not source_db_url or not warehouse_db_url:
        raise RuntimeError("Missing SOURCE_DB_URL or WAREHOUSE_DB_URL")

    with psycopg.connect(source_db_url, row_factory=dict_row) as src, psycopg.connect(
        warehouse_db_url, row_factory=dict_row
    ) as wh:
        _exec_sql_file(wh, SQL_DIR / "00_init_schemas.sql")
        _exec_sql_file(wh, SQL_DIR / "10_marts.sql")

        last_ts = _get_watermark(wh)

        changed_batches = _fetch_changed_batches(src, last_ts)
        changed_alerts = _fetch_changed_alerts(src, last_ts)

        _refresh_users(src, wh)
        _sync_batches(wh, changed_batches)
        _sync_alerts(wh, changed_alerts)
        _rebuild_marts(wh)

        max_batch_ts = max(
            (row.get("change_ts") for row in changed_batches if row.get("change_ts")),
            default=last_ts,
        )
        max_alert_ts = max(
            (row.get("created_at") for row in changed_alerts if row.get("created_at")),
            default=last_ts,
        )
        new_ts = max(last_ts, max_batch_ts, max_alert_ts)
        _update_watermark(wh, new_ts)

        wh.commit()

        print(
            f"[ETL] Synced batches={len(changed_batches)} alerts={len(changed_alerts)} "
            f"watermark={new_ts.isoformat()}"
        )


if __name__ == "__main__":
    main()
