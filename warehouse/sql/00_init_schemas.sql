create schema if not exists raw;
create schema if not exists mart;

create table if not exists mart.etl_watermark (
    pipeline text primary key,
    last_ts timestamptz not null
);

insert into mart.etl_watermark (pipeline, last_ts)
values ('app_to_wh', '1970-01-01T00:00:00Z')
on conflict (pipeline) do nothing;

create table if not exists raw.users (
    user_id uuid primary key,
    sector text,
    wilaya text,
    created_at timestamptz
);

create table if not exists raw.batches (
    batch_id text primary key,
    source_type text,
    breed text,
    wilaya text,
    status text,
    creator_id uuid,
    collector_id uuid,
    purchase_price_dzd numeric(10,2),
    location_lat numeric(10,8),
    location_lng numeric(11,8),
    type_de_laine text,
    proprete_score integer,
    sacs_count integer,
    weight_raw_e1_kg numeric(10,2),
    weight_after_handclean_kg numeric(10,2),
    stockage_zone text,
    classification text,
    temperature_tas_celsius numeric(5,2),
    taux_matiere_vegetale_percent numeric(5,2),
    weight_clean_d2_kg numeric(10,2),
    yield_percentage numeric(5,2),
    humidite_sortie_percent numeric(5,2),
    ph_laine numeric(4,2),
    fiber_length_mm numeric(5,2),
    finesse_micron numeric(5,2),
    humidity_percent numeric(5,2),
    final_destination text,
    is_ready_for_sale boolean,
    action_timestamp timestamptz,
    synced_at timestamptz,
    created_at timestamptz
);

create index if not exists idx_raw_batches_status on raw.batches(status);
create index if not exists idx_raw_batches_synced_at on raw.batches(synced_at desc);
create index if not exists idx_raw_batches_created_at on raw.batches(created_at desc);
create index if not exists idx_raw_batches_change_ts on raw.batches((coalesce(synced_at, created_at)));
create index if not exists idx_raw_batches_status_synced on raw.batches(status, synced_at desc);
create index if not exists idx_raw_batches_status_destination on raw.batches(status, final_destination);
create index if not exists idx_raw_batches_source_status on raw.batches(source_type, status);

create table if not exists raw.alerts (
    alert_id uuid primary key,
    batch_id text,
    alert_type text,
    severity text,
    is_resolved boolean,
    action text,
    created_at timestamptz
);

create index if not exists idx_raw_alerts_batch_id on raw.alerts(batch_id);
create index if not exists idx_raw_alerts_created_at on raw.alerts(created_at desc);
create index if not exists idx_raw_alerts_severity on raw.alerts(severity);
create index if not exists idx_raw_alerts_unresolved_created on raw.alerts(created_at desc) where is_resolved = false;
create index if not exists idx_raw_alerts_severity_resolved_created on raw.alerts(severity, is_resolved, created_at desc);

create table if not exists raw.batch_events (
    event_id bigserial primary key,
    batch_id text not null,
    event_time timestamptz not null,
    event_type text not null,
    status_from text,
    status_to text,
    payload jsonb default '{}'::jsonb,
    detected_at timestamptz default now()
);

create index if not exists idx_batch_events_batch_time on raw.batch_events(batch_id, event_time desc);
create index if not exists idx_batch_events_type on raw.batch_events(event_type);
create index if not exists idx_batch_events_time on raw.batch_events(event_time desc);
create index if not exists idx_batch_events_status_to_time on raw.batch_events(status_to, event_time desc);
create index if not exists idx_batch_events_payload_gin on raw.batch_events using gin(payload);
