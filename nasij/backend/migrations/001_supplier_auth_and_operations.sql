-- Supplier auth approval + supplier operations baseline.
-- Safe to run multiple times.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

ALTER TABLE public.users
    ADD COLUMN IF NOT EXISTS approval_status VARCHAR(32) DEFAULT 'APPROVED',
    ADD COLUMN IF NOT EXISTS approval_requested_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS approval_decided_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS approval_decided_by UUID,
    ADD COLUMN IF NOT EXISTS approval_note TEXT,
    ADD COLUMN IF NOT EXISTS trust_score INTEGER DEFAULT 100;

UPDATE public.users
SET trust_score = 100
WHERE trust_score IS NULL;

UPDATE public.users
SET approval_status = 'APPROVED'
WHERE approval_status IS NULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'users_approval_status_check'
    ) THEN
        ALTER TABLE public.users
            ADD CONSTRAINT users_approval_status_check
            CHECK (approval_status IN ('PENDING_APPROVAL', 'APPROVED', 'REJECTED'));
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'users_trust_score_range_check'
    ) THEN
        ALTER TABLE public.users
            ADD CONSTRAINT users_trust_score_range_check
            CHECK (trust_score >= 0 AND trust_score <= 100);
    END IF;
END $$;

CREATE TABLE IF NOT EXISTS public.supplier_operations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    supplier_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    supplier_phone VARCHAR(20) NOT NULL,
    supplier_role public.sector_role NOT NULL,
    status VARCHAR(32) NOT NULL DEFAULT 'PENDING',
    quantity_count INTEGER,
    quantity_weight_kg DECIMAL(10,2),
    location_lat DECIMAL(10,8),
    location_lng DECIMAL(11,8),
    collector_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    collector_phone VARCHAR(20),
    cancel_reason TEXT,
    cancelled_at TIMESTAMPTZ,
    trust_penalty_applied INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    synced_at TIMESTAMPTZ DEFAULT now()
);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'supplier_operations_status_check'
    ) THEN
        ALTER TABLE public.supplier_operations
            ADD CONSTRAINT supplier_operations_status_check
            CHECK (
                status IN (
                    'PENDING',
                    'ASSIGNED',
                    'CANCELLED_PENDING',
                    'CANCELLED_ASSIGNED',
                    'COMPLETED'
                )
            );
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'supplier_operations_quantity_check'
    ) THEN
        ALTER TABLE public.supplier_operations
            ADD CONSTRAINT supplier_operations_quantity_check
            CHECK (
                quantity_count IS NOT NULL
                OR quantity_weight_kg IS NOT NULL
            );
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_users_approval_status
    ON public.users(approval_status);
CREATE INDEX IF NOT EXISTS idx_users_trust_score
    ON public.users(trust_score);

CREATE INDEX IF NOT EXISTS idx_supplier_operations_supplier_id
    ON public.supplier_operations(supplier_id);
CREATE INDEX IF NOT EXISTS idx_supplier_operations_status
    ON public.supplier_operations(status);
CREATE INDEX IF NOT EXISTS idx_supplier_operations_created_at
    ON public.supplier_operations(created_at DESC);

ALTER TABLE public.supplier_operations ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
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

NOTIFY pgrst, 'reload schema';
