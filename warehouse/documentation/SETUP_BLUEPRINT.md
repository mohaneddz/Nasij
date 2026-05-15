# Warehouse Setup Blueprint (Docker + ETL + Demo Queries)

## Proposed Folder Structure

```text
warehouse/
  DB_REPORT.md
  WAREHOUSE_RECOMMENDATION.md
  SETUP_BLUEPRINT.md
  docker-compose.yml
  .env.example
  scripts/
    sync_app_to_wh.py
  sql/
    00_init_schemas.sql
    10_marts.sql
    20_demo_queries.sql
```

---

## `docker-compose.yml` (Proposed)

```yaml
version: "3.9"

services:
  warehouse:
    image: postgres:16-alpine
    container_name: nfn_warehouse
    environment:
      POSTGRES_DB: nfn_wh
      POSTGRES_USER: wh_user
      POSTGRES_PASSWORD: wh_pass
    ports:
      - "5433:5432"
    volumes:
      - wh_pgdata:/var/lib/postgresql/data

  adminer:
    image: adminer:4
    container_name: nfn_wh_adminer
    ports:
      - "8081:8080"
    depends_on:
      - warehouse

volumes:
  wh_pgdata:
```

---

## ETL/Sync Script (Proposed)

`scripts/sync_app_to_wh.py`

```python
import os
import psycopg
from datetime import datetime, timezone

SRC = os.environ["SOURCE_DB_URL"]   # Supabase/Postgres
WH = os.environ["WAREHOUSE_DB_URL"] # local warehouse Postgres

DDL = """
create schema if not exists raw;
create schema if not exists mart;
create table if not exists mart.etl_watermark (
  pipeline text primary key,
  last_ts timestamptz not null
);
insert into mart.etl_watermark(pipeline, last_ts)
values ('app_sync', '1970-01-01T00:00:00Z')
on conflict (pipeline) do nothing;
"""

def main():
    with psycopg.connect(WH) as wh, psycopg.connect(SRC) as src:
        wh.execute(DDL)
        last_ts = wh.execute(
            "select last_ts from mart.etl_watermark where pipeline='app_sync'"
        ).fetchone()[0]

        # Pull changed operational records
        batches = src.execute(
            "select * from public.batches where coalesce(synced_at, created_at) > %s",
            (last_ts,)
        ).fetchall()
        alerts = src.execute(
            "select * from public.alerts where created_at > %s",
            (last_ts,)
        ).fetchall()
        users = src.execute("select * from public.users").fetchall()
        vouchers = src.execute("select * from public.vouchers").fetchall()

        # Demo-friendly loads (replace with proper MERGE in production)
        wh.execute("truncate raw.users, raw.vouchers")
        if users:
            wh.executemany("insert into raw.users values (%s,%s,%s,%s,%s,%s,%s)", users)
        if vouchers:
            wh.executemany("insert into raw.vouchers values (%s,%s,%s,%s,%s,%s)", vouchers)

        if batches:
            wh.execute("delete from raw.batches where batch_id = any(%s)", ([r[0] for r in batches],))
            wh.executemany("insert into raw.batches values (" + ",".join(["%s"]*len(batches[0])) + ")", batches)

        if alerts:
            wh.execute("delete from raw.alerts where id = any(%s)", ([r[0] for r in alerts],))
            wh.executemany("insert into raw.alerts values (" + ",".join(["%s"]*len(alerts[0])) + ")", alerts)

        # Build marts
        wh.execute("""
        create materialized view if not exists mart.fact_batch_snapshot as
        select
          batch_id, source_type, breed, wilaya, status,
          purchase_price_dzd, weight_raw_e1_kg, weight_after_handclean_kg,
          weight_clean_d2_kg, final_destination, action_timestamp, synced_at, created_at
        from raw.batches;
        """)
        wh.execute("refresh materialized view mart.fact_batch_snapshot")

        wh.execute("""
        create materialized view if not exists mart.fact_alert_event as
        select id, batch_id, alert_type, severity, is_resolved, created_at
        from raw.alerts;
        """)
        wh.execute("refresh materialized view mart.fact_alert_event")

        wh.execute(
            "update mart.etl_watermark set last_ts=%s where pipeline='app_sync'",
            (datetime.now(timezone.utc),)
        )
        wh.commit()

if __name__ == "__main__":
    main()
```

---

## Demo Queries

```sql
-- 1) Pipeline WIP
select status, count(*) as batches
from mart.fact_batch_snapshot
group by status
order by batches desc;

-- 2) Yield by source
select
  source_type,
  round(avg((weight_clean_d2_kg / nullif(weight_after_handclean_kg,0))*100),2) as avg_yield_pct
from mart.fact_batch_snapshot
where weight_clean_d2_kg is not null and weight_after_handclean_kg is not null
group by source_type;

-- 3) Alert trend by day/severity
select date_trunc('day', created_at) as day, severity, count(*) as alerts
from mart.fact_alert_event
group by 1,2
order by 1 desc, 2;

-- 4) D3 vs D4 split
select final_destination, count(*) as lots
from mart.fact_batch_snapshot
where status in ('IN_TRANSFORMATION','READY_FOR_SALE')
group by final_destination;

-- 5) Wilaya loss percentage
select
  wilaya,
  round(
    100 * (sum(coalesce(weight_raw_e1_kg,0)) - sum(coalesce(weight_after_handclean_kg,0)))
    / nullif(sum(coalesce(weight_raw_e1_kg,0)),0), 2
  ) as loss_pct
from mart.fact_batch_snapshot
group by wilaya
order by loss_pct desc nulls last;
```

---

## Notes

- This blueprint is intentionally demo-oriented and minimal.
- For production, replace delete/reinsert sections with robust `MERGE`/upsert and explicit column mapping.
- Add masking/tokenization for PII before exposing analytics layers.

