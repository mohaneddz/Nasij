create extension if not exists pgcrypto;

do $$
begin
    create type sector_role as enum (
        'C1_FARMER',
        'C2_ABATTOIR',
        'C3_AGGREGATOR',
        'COLLECTOR',
        'WORKER',
        'MANAGER'
    );
exception when duplicate_object then null;
end $$;

do $$
begin
    create type batch_status as enum (
        'PENDING_PICKUP',
        'COLLECTED_BY_BUYER',
        'AT_D1_STOCKAGE',
        'AT_D2_LAVAGE',
        'IN_TRANSFORMATION',
        'READY_FOR_SALE'
    );
exception when duplicate_object then null;
end $$;

create table if not exists users (
    id uuid primary key default gen_random_uuid(),
    phone_number varchar(50) unique not null,
    sector sector_role not null,
    full_name varchar(255),
    wilaya varchar(100),
    created_at timestamptz default now()
);

create table if not exists batches (
    batch_id varchar(50) primary key,
    source_type varchar(10) not null,
    breed varchar(50) not null,
    wilaya varchar(100),
    status batch_status not null default 'PENDING_PICKUP',
    creator_id uuid references users(id) on delete set null,
    collector_id uuid references users(id) on delete set null,
    purchase_price_dzd numeric(10,2),
    location_lat numeric(10,8),
    location_lng numeric(11,8),
    type_de_laine varchar(50),
    proprete_score integer,
    sacs_count integer,
    weight_raw_e1_kg numeric(10,2),
    weight_after_handclean_kg numeric(10,2),
    stockage_zone varchar(50),
    classification varchar(50),
    temperature_tas_celsius numeric(5,2),
    taux_matiere_vegetale_percent numeric(5,2),
    weight_clean_d2_kg numeric(10,2),
    yield_percentage numeric(5,2),
    humidite_sortie_percent numeric(5,2),
    ph_laine numeric(4,2),
    fiber_length_mm numeric(5,2),
    finesse_micron numeric(5,2),
    humidity_percent numeric(5,2),
    final_destination varchar(50),
    is_ready_for_sale boolean default false,
    action_timestamp timestamptz,
    synced_at timestamptz default now(),
    created_at timestamptz default now()
);

create table if not exists alerts (
    id uuid primary key default gen_random_uuid(),
    batch_id varchar(50) references batches(batch_id) on delete cascade,
    alert_type varchar(50) not null,
    severity varchar(20) not null,
    description text,
    action varchar(100),
    is_resolved boolean default false,
    created_at timestamptz default now()
);

create index if not exists idx_users_sector on users(sector);
create index if not exists idx_users_wilaya on users(wilaya);

create index if not exists idx_batches_status on batches(status);
create index if not exists idx_batches_synced_at on batches(synced_at desc);
create index if not exists idx_batches_created_at on batches(created_at desc);
create index if not exists idx_batches_change_ts on batches((coalesce(synced_at, created_at)));
create index if not exists idx_batches_status_synced on batches(status, synced_at desc);
create index if not exists idx_batches_source_status on batches(source_type, status);
create index if not exists idx_batches_status_destination on batches(status, final_destination);

create index if not exists idx_alerts_batch_id on alerts(batch_id);
create index if not exists idx_alerts_created_at on alerts(created_at desc);
create index if not exists idx_alerts_severity on alerts(severity);
create index if not exists idx_alerts_unresolved_created on alerts(created_at desc) where is_resolved = false;
