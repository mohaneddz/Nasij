-- Align an existing Supabase database with the backend/seed script.
-- Safe to run more than once.

ALTER TABLE public.batches
    ADD COLUMN IF NOT EXISTS wilaya VARCHAR(100),
    ADD COLUMN IF NOT EXISTS creator_phone VARCHAR(20),
    ADD COLUMN IF NOT EXISTS collector_phone VARCHAR(20),
    ADD COLUMN IF NOT EXISTS weight_after_handclean_kg DECIMAL(10,2),
    ADD COLUMN IF NOT EXISTS stockage_zone VARCHAR(50),
    ADD COLUMN IF NOT EXISTS weight_clean_d2_kg DECIMAL(10,2),
    ADD COLUMN IF NOT EXISTS fiber_length_mm DECIMAL(5,2),
    ADD COLUMN IF NOT EXISTS finesse_micron DECIMAL(5,2),
    ADD COLUMN IF NOT EXISTS humidity_percent DECIMAL(5,2),
    ADD COLUMN IF NOT EXISTS final_destination VARCHAR(50),
    ADD COLUMN IF NOT EXISTS action_timestamp TIMESTAMP,
    ADD COLUMN IF NOT EXISTS synced_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

ALTER TABLE public.alerts
    ADD COLUMN IF NOT EXISTS severity VARCHAR(20) DEFAULT 'POINT_ROUGE',
    ADD COLUMN IF NOT EXISTS action VARCHAR(100);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'users'
          AND column_name = 'sector'
    ) THEN
        IF EXISTS (
            SELECT 1
            FROM pg_type t
            JOIN pg_namespace n ON n.oid = t.typnamespace
            WHERE n.nspname = 'public'
              AND t.typname = 'user_role'
        ) THEN
            EXECUTE 'ALTER TABLE public.users ADD COLUMN sector user_role';
        ELSIF EXISTS (
            SELECT 1
            FROM pg_type t
            JOIN pg_namespace n ON n.oid = t.typnamespace
            WHERE n.nspname = 'public'
              AND t.typname = 'sector_role'
        ) THEN
            EXECUTE 'ALTER TABLE public.users ADD COLUMN sector sector_role';
        ELSE
            EXECUTE 'ALTER TABLE public.users ADD COLUMN sector VARCHAR(50)';
        END IF;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_batches_status ON public.batches(status);
CREATE INDEX IF NOT EXISTS idx_batches_breed ON public.batches(breed);
CREATE INDEX IF NOT EXISTS idx_batches_wilaya ON public.batches(wilaya);
CREATE INDEX IF NOT EXISTS idx_alerts_batch_id ON public.alerts(batch_id);
CREATE INDEX IF NOT EXISTS idx_alerts_is_resolved ON public.alerts(is_resolved);

-- Tell Supabase/PostgREST to refresh its schema cache immediately.
NOTIFY pgrst, 'reload schema';
