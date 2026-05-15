-- Performance indexes for supplier approval and operations flows.
-- Safe to run multiple times.

DO $$
BEGIN
    IF to_regclass('public.users') IS NOT NULL THEN
        -- Manager approval queue: filter by supplier sectors + approval status, then sort by request time.
        CREATE INDEX IF NOT EXISTS idx_users_sector_approval_requested
            ON public.users(sector, approval_status, approval_requested_at DESC);
    END IF;

    IF to_regclass('public.supplier_operations') IS NOT NULL THEN
        -- Supplier operations list (active statuses) ordered by newest first.
        CREATE INDEX IF NOT EXISTS idx_supplier_ops_supplier_status_created
            ON public.supplier_operations(supplier_id, status, created_at DESC);

        -- Supplier operations history list ordered by newest first.
        CREATE INDEX IF NOT EXISTS idx_supplier_ops_supplier_created
            ON public.supplier_operations(supplier_id, created_at DESC);
    END IF;

    IF to_regclass('public.batches') IS NOT NULL THEN
        -- Alert feed lookup for "my batches": first fetch batch IDs by creator.
        CREATE INDEX IF NOT EXISTS idx_batches_creator_id
            ON public.batches(creator_id);
    END IF;

    IF to_regclass('public.alerts') IS NOT NULL THEN
        -- Alert feed for a set of batch IDs with unresolved filter and recency sort.
        CREATE INDEX IF NOT EXISTS idx_alerts_batch_resolved_created
            ON public.alerts(batch_id, is_resolved, created_at DESC);

        -- Duplicate unresolved-alert guard in sync path.
        CREATE INDEX IF NOT EXISTS idx_alerts_unresolved_batch_type
            ON public.alerts(batch_id, alert_type)
            WHERE is_resolved = false;
    END IF;
END $$;

NOTIFY pgrst, 'reload schema';
