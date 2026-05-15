-- Hybrid partitioning with zero API changes.
-- - Horizontal: hash partitions for public.supplier_operations (same table name kept).
-- - Vertical: companion detail table for cold supplier operation columns, synced by trigger.
-- Safe to run multiple times.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- 1) Horizontal partitioning: supplier_operations by HASH(id)
-- ============================================================
DO $$
DECLARE
    relkind "char";
BEGIN
    SELECT c.relkind
    INTO relkind
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relname = 'supplier_operations';

    IF relkind = 'r' THEN
        -- Convert heap table to partitioned table without changing its public name.
        ALTER TABLE public.supplier_operations RENAME TO supplier_operations_heap;

        CREATE TABLE public.supplier_operations (
            LIKE public.supplier_operations_heap
                INCLUDING DEFAULTS
                INCLUDING CONSTRAINTS
                INCLUDING GENERATED
                INCLUDING IDENTITY
        ) PARTITION BY HASH (id);

        CREATE TABLE IF NOT EXISTS public.supplier_operations_p0
            PARTITION OF public.supplier_operations FOR VALUES WITH (MODULUS 8, REMAINDER 0);
        CREATE TABLE IF NOT EXISTS public.supplier_operations_p1
            PARTITION OF public.supplier_operations FOR VALUES WITH (MODULUS 8, REMAINDER 1);
        CREATE TABLE IF NOT EXISTS public.supplier_operations_p2
            PARTITION OF public.supplier_operations FOR VALUES WITH (MODULUS 8, REMAINDER 2);
        CREATE TABLE IF NOT EXISTS public.supplier_operations_p3
            PARTITION OF public.supplier_operations FOR VALUES WITH (MODULUS 8, REMAINDER 3);
        CREATE TABLE IF NOT EXISTS public.supplier_operations_p4
            PARTITION OF public.supplier_operations FOR VALUES WITH (MODULUS 8, REMAINDER 4);
        CREATE TABLE IF NOT EXISTS public.supplier_operations_p5
            PARTITION OF public.supplier_operations FOR VALUES WITH (MODULUS 8, REMAINDER 5);
        CREATE TABLE IF NOT EXISTS public.supplier_operations_p6
            PARTITION OF public.supplier_operations FOR VALUES WITH (MODULUS 8, REMAINDER 6);
        CREATE TABLE IF NOT EXISTS public.supplier_operations_p7
            PARTITION OF public.supplier_operations FOR VALUES WITH (MODULUS 8, REMAINDER 7);

        INSERT INTO public.supplier_operations
        SELECT *
        FROM public.supplier_operations_heap;

        DROP TABLE public.supplier_operations_heap;
    ELSIF relkind = 'p' THEN
        -- Already partitioned: ensure partitions exist.
        CREATE TABLE IF NOT EXISTS public.supplier_operations_p0
            PARTITION OF public.supplier_operations FOR VALUES WITH (MODULUS 8, REMAINDER 0);
        CREATE TABLE IF NOT EXISTS public.supplier_operations_p1
            PARTITION OF public.supplier_operations FOR VALUES WITH (MODULUS 8, REMAINDER 1);
        CREATE TABLE IF NOT EXISTS public.supplier_operations_p2
            PARTITION OF public.supplier_operations FOR VALUES WITH (MODULUS 8, REMAINDER 2);
        CREATE TABLE IF NOT EXISTS public.supplier_operations_p3
            PARTITION OF public.supplier_operations FOR VALUES WITH (MODULUS 8, REMAINDER 3);
        CREATE TABLE IF NOT EXISTS public.supplier_operations_p4
            PARTITION OF public.supplier_operations FOR VALUES WITH (MODULUS 8, REMAINDER 4);
        CREATE TABLE IF NOT EXISTS public.supplier_operations_p5
            PARTITION OF public.supplier_operations FOR VALUES WITH (MODULUS 8, REMAINDER 5);
        CREATE TABLE IF NOT EXISTS public.supplier_operations_p6
            PARTITION OF public.supplier_operations FOR VALUES WITH (MODULUS 8, REMAINDER 6);
        CREATE TABLE IF NOT EXISTS public.supplier_operations_p7
            PARTITION OF public.supplier_operations FOR VALUES WITH (MODULUS 8, REMAINDER 7);
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.supplier_operations') IS NOT NULL THEN
        -- Existing + query-driven indexes on partitioned table.
        CREATE INDEX IF NOT EXISTS idx_supplier_operations_supplier_id
            ON public.supplier_operations(supplier_id);
        CREATE INDEX IF NOT EXISTS idx_supplier_operations_status
            ON public.supplier_operations(status);
        CREATE INDEX IF NOT EXISTS idx_supplier_operations_created_at
            ON public.supplier_operations(created_at DESC);
        CREATE INDEX IF NOT EXISTS idx_supplier_ops_supplier_status_created
            ON public.supplier_operations(supplier_id, status, created_at DESC);
        CREATE INDEX IF NOT EXISTS idx_supplier_ops_supplier_created
            ON public.supplier_operations(supplier_id, created_at DESC);

        GRANT ALL ON TABLE public.supplier_operations TO service_role;
        ALTER TABLE public.supplier_operations ENABLE ROW LEVEL SECURITY;
    END IF;
END $$;

DO $$
BEGIN
    IF to_regclass('public.supplier_operations') IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM pg_policies
           WHERE schemaname = 'public'
             AND tablename = 'supplier_operations'
             AND policyname = 'service_role_all_supplier_operations'
       ) THEN
        CREATE POLICY service_role_all_supplier_operations
            ON public.supplier_operations
            FOR ALL TO service_role
            USING (true)
            WITH CHECK (true);
    END IF;
END $$;

-- ============================================================
-- 2) Vertical partitioning companion: cold detail columns
-- ============================================================
DO $$
BEGIN
    IF to_regclass('public.supplier_operations') IS NOT NULL THEN
        CREATE TABLE IF NOT EXISTS public.supplier_operations_details (
            id UUID PRIMARY KEY
                REFERENCES public.supplier_operations(id) ON DELETE CASCADE,
            location_lat DECIMAL(10,8),
            location_lng DECIMAL(11,8),
            collector_phone VARCHAR(20),
            cancel_reason TEXT,
            cancelled_at TIMESTAMPTZ,
            trust_penalty_applied INTEGER,
            updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
        );

        INSERT INTO public.supplier_operations_details (
            id,
            location_lat,
            location_lng,
            collector_phone,
            cancel_reason,
            cancelled_at,
            trust_penalty_applied,
            updated_at
        )
        SELECT
            so.id,
            so.location_lat,
            so.location_lng,
            so.collector_phone,
            so.cancel_reason,
            so.cancelled_at,
            so.trust_penalty_applied,
            COALESCE(so.updated_at, now())
        FROM public.supplier_operations so
        ON CONFLICT (id) DO UPDATE
        SET location_lat = EXCLUDED.location_lat,
            location_lng = EXCLUDED.location_lng,
            collector_phone = EXCLUDED.collector_phone,
            cancel_reason = EXCLUDED.cancel_reason,
            cancelled_at = EXCLUDED.cancelled_at,
            trust_penalty_applied = EXCLUDED.trust_penalty_applied,
            updated_at = EXCLUDED.updated_at;

        CREATE INDEX IF NOT EXISTS idx_supplier_operations_details_cancelled_at
            ON public.supplier_operations_details(cancelled_at DESC);

        GRANT ALL ON TABLE public.supplier_operations_details TO service_role;
    END IF;
END $$;

CREATE OR REPLACE FUNCTION public.sync_supplier_operations_details()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO public.supplier_operations_details (
        id,
        location_lat,
        location_lng,
        collector_phone,
        cancel_reason,
        cancelled_at,
        trust_penalty_applied,
        updated_at
    ) VALUES (
        NEW.id,
        NEW.location_lat,
        NEW.location_lng,
        NEW.collector_phone,
        NEW.cancel_reason,
        NEW.cancelled_at,
        NEW.trust_penalty_applied,
        COALESCE(NEW.updated_at, now())
    )
    ON CONFLICT (id) DO UPDATE
    SET location_lat = EXCLUDED.location_lat,
        location_lng = EXCLUDED.location_lng,
        collector_phone = EXCLUDED.collector_phone,
        cancel_reason = EXCLUDED.cancel_reason,
        cancelled_at = EXCLUDED.cancelled_at,
        trust_penalty_applied = EXCLUDED.trust_penalty_applied,
        updated_at = EXCLUDED.updated_at;

    RETURN NEW;
END;
$$;

DO $$
BEGIN
    IF to_regclass('public.supplier_operations') IS NOT NULL THEN
        DROP TRIGGER IF EXISTS trg_supplier_operations_sync_details
            ON public.supplier_operations;

        CREATE TRIGGER trg_supplier_operations_sync_details
        AFTER INSERT OR UPDATE OF
            location_lat,
            location_lng,
            collector_phone,
            cancel_reason,
            cancelled_at,
            trust_penalty_applied,
            updated_at
        ON public.supplier_operations
        FOR EACH ROW
        EXECUTE FUNCTION public.sync_supplier_operations_details();
    END IF;
END $$;

NOTIFY pgrst, 'reload schema';
