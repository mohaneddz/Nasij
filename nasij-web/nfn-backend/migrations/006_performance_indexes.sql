-- Performance-oriented indexes for API and dashboard query patterns.
-- Safe to run multiple times.

create index if not exists idx_batches_status_synced_at
    on public.batches(status, synced_at desc);

create index if not exists idx_batches_source_status
    on public.batches(source_type, status);

create index if not exists idx_batches_status_final_destination
    on public.batches(status, final_destination);

create index if not exists idx_batches_change_ts_expr
    on public.batches((coalesce(synced_at, created_at)));

create index if not exists idx_alerts_batch_created_at
    on public.alerts(batch_id, created_at desc);

create index if not exists idx_alerts_severity_resolved_created
    on public.alerts(severity, is_resolved, created_at desc);

create index if not exists idx_alerts_unresolved_created
    on public.alerts(created_at desc)
    where is_resolved = false;

notify pgrst, 'reload schema';

