create schema if not exists mart;

create table if not exists mart.fact_batch_snapshot (
    batch_id text primary key,
    source_type text,
    breed text,
    wilaya text,
    status text,
    final_destination text,
    purchase_price_dzd numeric(10,2),
    weight_raw_e1_kg numeric(10,2),
    weight_after_handclean_kg numeric(10,2),
    weight_clean_d2_kg numeric(10,2),
    current_yield_pct numeric(8,2),
    d1_loss_pct numeric(8,2),
    action_timestamp timestamptz,
    synced_at timestamptz,
    created_at timestamptz
);

create index if not exists idx_fact_batch_status on mart.fact_batch_snapshot(status);
create index if not exists idx_fact_batch_wilaya on mart.fact_batch_snapshot(wilaya);
create index if not exists idx_fact_batch_source on mart.fact_batch_snapshot(source_type);
create index if not exists idx_fact_batch_status_destination on mart.fact_batch_snapshot(status, final_destination);
create index if not exists idx_fact_batch_action_ts on mart.fact_batch_snapshot(action_timestamp desc);

create table if not exists mart.fact_alert_event (
    alert_id uuid primary key,
    batch_id text,
    alert_type text,
    severity text,
    is_resolved boolean,
    action text,
    created_at timestamptz
);

create index if not exists idx_fact_alert_created on mart.fact_alert_event(created_at desc);
create index if not exists idx_fact_alert_severity on mart.fact_alert_event(severity);
create index if not exists idx_fact_alert_unresolved_created on mart.fact_alert_event(created_at desc) where is_resolved = false;
create index if not exists idx_fact_alert_severity_resolved_created on mart.fact_alert_event(severity, is_resolved, created_at desc);

create table if not exists mart.fact_batch_event (
    event_id bigint primary key,
    batch_id text not null,
    event_time timestamptz not null,
    event_type text not null,
    status_from text,
    status_to text,
    payload jsonb,
    detected_at timestamptz
);

create index if not exists idx_fact_batch_event_time on mart.fact_batch_event(event_time desc);
create index if not exists idx_fact_batch_event_batch_time on mart.fact_batch_event(batch_id, event_time desc);
create index if not exists idx_fact_batch_event_type_time on mart.fact_batch_event(event_type, event_time desc);
create index if not exists idx_fact_batch_event_payload_gin on mart.fact_batch_event using gin(payload);

create table if not exists mart.kpi_wip_by_status (
    status text primary key,
    batch_count integer not null,
    as_of_ts timestamptz not null
);

create table if not exists mart.kpi_yield_summary (
    metric_name text primary key,
    metric_value numeric(10,2) not null,
    as_of_ts timestamptz not null
);

create table if not exists mart.kpi_alerts_summary (
    severity text primary key,
    active_count integer not null,
    total_count integer not null,
    as_of_ts timestamptz not null
);
