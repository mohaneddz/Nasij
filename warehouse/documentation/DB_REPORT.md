# NFN App Database Report

## Scope Reviewed

- `nasij-web/supabase_full_schema.sql`
- `nasij-web/supabase_schema.sql`
- `nasij-web/nfn-backend/migrations/*.sql`
- `nasij-web/nfn-backend/app/seed.py`
- `nasij-web/nfn-backend/app/routers/{batches,alerts,dashboard,sync,auth}.py`
- `nasij-web/alerts_logic.md`
- `nasij/context.md`

---

## Main Entities

### 1. `users`
Core identity/profile table for platform actors.

Key columns:
- `id` (PK, UUID)
- `phone_number` (unique)
- `sector` (`sector_role` enum)
- `role` (legacy compatibility in full schema)
- `full_name`
- `wilaya`
- `created_at`

### 2. `batches`
Core operational table and current state of each wool lot (`batch_id`).

Key columns:
- Identity/flow: `batch_id`, `source_type`, `breed`, `status`
- Actor links: `creator_id`, `collector_id`, `creator_phone`, `collector_phone`
- Geo/commercial: `wilaya`, `purchase_price_dzd`, `location_lat`, `location_lng`
- Annex D1/D2 quality fields: `type_de_laine`, `proprete_score`, `sacs_count`, `classification`, `temperature_tas_celsius`, `taux_matiere_vegetale_percent`, `humidite_sortie_percent`, `ph_laine`
- Weights: `weight_raw_e1_kg`, `weight_after_handclean_kg`, `weight_clean_d2_kg`, `yield_percentage`
- Transformation: `fiber_length_mm`, `finesse_micron`, `humidity_percent`, `final_destination`, `is_ready_for_sale`
- Offline/sync metadata: `annex_metadata`, `action_timestamp`, `synced_at`, `created_at`

### 3. `alerts`
Operational anomaly and control-center alerts.

Key columns:
- `id` (PK, UUID)
- `batch_id` (FK -> `batches.batch_id`)
- `alert_type`
- `severity` (`POINT_NOIR|POINT_ROUGE|POINT_JAUNE`)
- `description`
- `action`
- `is_resolved`
- `created_at`

### 4. `vouchers`
Circular-economy/reward table.

Key columns:
- `voucher_id` (PK)
- `farmer_id` (FK -> `users.id`)
- `batch_id` (FK -> `batches.batch_id`)
- `reward_type`
- `is_used`
- `created_at`

---

## Relationships

- `batches.creator_id -> users.id` (`ON DELETE SET NULL`)
- `batches.collector_id -> users.id` (`ON DELETE SET NULL`)
- `alerts.batch_id -> batches.batch_id` (`ON DELETE CASCADE`)
- `vouchers.farmer_id -> users.id` (`ON DELETE SET NULL`)
- `vouchers.batch_id -> batches.batch_id` (`ON DELETE SET NULL`)

---

## Event/History Model Assessment

- There is **no dedicated immutable event ledger** table (e.g. `batch_events`).
- History is currently represented by:
  - `batches.action_timestamp`
  - `batches.synced_at`
  - `batches.created_at`
  - `alerts.created_at` + `is_resolved`
- `alerts` behaves as an event stream for anomaly/control events.

---

## Important Workflows

1. Auth
- Phone-based login/signup via Supabase Auth.
- Signup also upserts into `users`.

2. Batch lifecycle
- Status progression:
  - `PENDING_PICKUP`
  - `COLLECTED_BY_BUYER`
  - `AT_D1_STOCKAGE`
  - `AT_D2_LAVAGE`
  - `IN_TRANSFORMATION`
  - `READY_FOR_SALE`
- One row in `batches` is progressively enriched as operations advance.

3. Offline-first sync
- `/api/sync` accepts device-cached operations and upserts by `batch_id`.
- Idempotent re-sync behavior is expected.

4. Alerts
- DB trigger-based alerts (`check_batch_quality_alerts`) + API-level checks.
- Main alert logic includes low yield, incoherent weight increases, high pile temperature, high vegetal matter, and major transit losses.

5. Dashboard analytics
- API currently computes KPIs directly from operational tables (`batches`, `alerts`) without a separate warehouse/mart layer.

---

## Analytics Needs (Current + Near-Term)

- Volume declared vs received
- Yield and loss rates by source/status/wilaya/time
- Active alerts and severity trend
- Breed distribution
- D3 vs D4 destination split
- Pipeline WIP by status
- Geo monitoring (lat/lng and wilaya)

---

## Data Volume Assumptions (Demo Context)

- Seed contains ~20+ batches and a handful of alerts.
- Expected demo growth: small to medium (`10^3` to low `10^5` rows).
- Current model is row-update centric, not high-frequency append-only telemetry.

---

## What Should Be Copied to Warehouse

Primary replication:
- `batches`
- `alerts`
- `users` (prefer masked/tokenized phone field)
- `vouchers` (optional if reward KPI is needed)

Warehouse derived objects:
- `fact_batch_snapshot`
- `fact_alert_event`
- `dim_user`
- status/time aggregate marts for dashboard fast reads

---

## What Should Stay Only in App DB

- Supabase Auth internals and session data
- RLS-governed transactional writes
- Raw PII (`phone_number`) unless explicitly anonymized
- Real-time transactional conflict handling
- Source-of-truth trigger logic and operational mutations

