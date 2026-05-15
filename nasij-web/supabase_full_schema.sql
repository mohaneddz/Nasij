-- NFN Supabase full schema (authoritative, matches current app).
-- Run on a fresh project.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==========================================
-- 1. ENUMS
-- ==========================================

DO $$
BEGIN
    CREATE TYPE public.sector_role AS ENUM (
        'C1_FARMER',
        'C2_ABATTOIR',
        'C3_AGGREGATOR',
        'DEPOT_WORKER',
        'LAVAGE_WORKER',
        'TRANSFORMATEUR'
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    CREATE TYPE public.batch_status AS ENUM (
        'PENDING_PICKUP',
        'COLLECTED_BY_BUYER',
        'AT_D1_STOCKAGE',
        'AT_D2_LAVAGE',
        'IN_TRANSFORMATION',
        'READY_FOR_SALE'
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    CREATE TYPE public.source_enum AS ENUM ('C1', 'C2', 'C3');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    CREATE TYPE public.sheep_breed AS ENUM (
        'OULED_DJELLAL',
        'REMBI',
        'EL_HAMRA',
        'BARBAR',
        'TEZEGZAWET',
        'MIXTE'
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    CREATE TYPE public.wool_type AS ENUM (
        'TOISON_ENTIERE',
        'TOISON_MORCEAUX',
        'LAINE_QUEUE',
        'PELADE_CHIMIQUE',
        'ECHAUFFEE_NATURELLE'
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
    CREATE TYPE public.wool_class AS ENUM (
        'CLASSE_A_PROPRE',
        'CLASSE_B_SOUILLEE'
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ==========================================
-- 2. USERS
-- ==========================================

CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone_number VARCHAR(50) UNIQUE NOT NULL,

    -- Primary role used by the app.
    sector public.sector_role NOT NULL,

    -- Legacy compatibility (older clients/DBs might use role).
    role public.sector_role,

    full_name VARCHAR(255),
    wilaya VARCHAR(100),
    is_approved BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ==========================================
-- 3. BATCHES
-- ==========================================

CREATE TABLE IF NOT EXISTS public.batches (
    batch_id VARCHAR(50) PRIMARY KEY,
    source_type public.source_enum NOT NULL,
    breed public.sheep_breed NOT NULL,
    wilaya VARCHAR(100),
    status public.batch_status NOT NULL DEFAULT 'PENDING_PICKUP',

    -- People involved.
    creator_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    collector_id UUID REFERENCES public.users(id) ON DELETE SET NULL,

    -- Marketplace and GPS data.
    purchase_price_dzd DECIMAL(10,2),
    location_lat DECIMAL(10,8),
    location_lng DECIMAL(11,8),

    -- Annex collection specs.
    type_de_laine public.wool_type,
    proprete_score INTEGER CHECK (proprete_score >= 1 AND proprete_score <= 5),
    sacs_count INTEGER,

    -- Depot D1.
    weight_raw_e1_kg DECIMAL(10,2),
    weight_after_handclean_kg DECIMAL(10,2),
    stockage_zone VARCHAR(50),
    classification public.wool_class,
    temperature_tas_celsius DECIMAL(5,2),
    taux_matiere_vegetale_percent DECIMAL(5,2),

    -- Lavage D2.
    weight_clean_d2_kg DECIMAL(10,2),
    yield_percentage DECIMAL(5,2),
    humidite_sortie_percent DECIMAL(5,2),
    ph_laine DECIMAL(4,2),

    -- C2 cold-chain/audit support from earlier schema drafts.
    slaughter_time TIMESTAMPTZ,

    -- Transformation and commercial routing.
    fiber_length_mm DECIMAL(5,2),
    finesse_micron DECIMAL(5,2),
    humidity_percent DECIMAL(5,2),
    final_destination VARCHAR(50),
    is_ready_for_sale BOOLEAN DEFAULT FALSE,

    -- Offline-first sync timestamps.
    annex_metadata JSONB DEFAULT '{}'::jsonb,
    action_timestamp TIMESTAMPTZ,
    synced_at TIMESTAMPTZ DEFAULT now(),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ==========================================
-- 4. ALERTS
-- ==========================================

CREATE TABLE IF NOT EXISTS public.alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id VARCHAR(50) REFERENCES public.batches(batch_id) ON DELETE CASCADE,
    alert_type VARCHAR(50) NOT NULL,
    severity VARCHAR(20) NOT NULL DEFAULT 'POINT_ROUGE'
        CHECK (severity IN ('POINT_NOIR', 'POINT_ROUGE', 'POINT_JAUNE')),
    description TEXT,
    action VARCHAR(100),
    is_resolved BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ==========================================
-- 5. VOUCHERS
-- ==========================================

CREATE TABLE IF NOT EXISTS public.vouchers (
    voucher_id VARCHAR(50) PRIMARY KEY,
    farmer_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    batch_id VARCHAR(50) REFERENCES public.batches(batch_id) ON DELETE SET NULL,
    reward_type VARCHAR(100) DEFAULT 'BIO_FERTILIZER_50KG',
    is_used BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- ==========================================
-- 6. ALERT AUTOMATION
-- ==========================================

CREATE OR REPLACE FUNCTION public.raise_alert_if_missing(
    p_batch_id VARCHAR,
    p_alert_type VARCHAR,
    p_severity VARCHAR,
    p_description TEXT,
    p_action VARCHAR
) RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_batch_id IS NULL THEN
        RETURN;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM public.alerts
        WHERE batch_id = p_batch_id
          AND alert_type = p_alert_type
          AND is_resolved = false
    ) THEN
        INSERT INTO public.alerts (
            batch_id,
            alert_type,
            severity,
            description,
            action
        ) VALUES (
            p_batch_id,
            p_alert_type,
            p_severity,
            p_description,
            p_action
        );
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.check_batch_quality_alerts()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
    hand_yield NUMERIC;
    min_yield NUMERIC;
    max_yield NUMERIC;
    yield_label TEXT;
BEGIN
    -- A1: low yield after D1 hand-cleaning (Annex ranges).
    IF NEW.weight_raw_e1_kg IS NOT NULL
       AND NEW.weight_after_handclean_kg IS NOT NULL
       AND NEW.weight_raw_e1_kg > 0 THEN
        hand_yield := NEW.weight_after_handclean_kg / NEW.weight_raw_e1_kg;

        IF NEW.source_type = 'C2' THEN
            min_yield := 0.35;
            max_yield := 0.45;
            yield_label := 'Rendement Abattage';
        ELSE
            min_yield := 0.55;
            max_yield := 0.65;
            yield_label := 'Rendement Tonte';
        END IF;

        IF hand_yield < min_yield THEN
            PERFORM public.raise_alert_if_missing(
                NEW.batch_id,
                'A1_RENDEMENT',
                'POINT_ROUGE',
                format(
                    '%s: %.1f%% (cible %.0f-%.0f%%).',
                    yield_label,
                    hand_yield * 100,
                    min_yield * 100,
                    max_yield * 100
                ),
                'Verifier D1'
            );
        END IF;
    END IF;

    -- E2: inconsistent weight increase between steps.
    IF NEW.weight_raw_e1_kg IS NOT NULL
       AND NEW.weight_after_handclean_kg IS NOT NULL
       AND NEW.weight_after_handclean_kg > NEW.weight_raw_e1_kg THEN
        PERFORM public.raise_alert_if_missing(
            NEW.batch_id,
            'E2_INCOHERENT_POIDS',
            'POINT_NOIR',
            'Poids apres nettoyage superieur au poids brut D1.',
            'Recontrole pesee'
        );
    END IF;

    IF NEW.weight_after_handclean_kg IS NOT NULL
       AND NEW.weight_clean_d2_kg IS NOT NULL
       AND NEW.weight_clean_d2_kg > NEW.weight_after_handclean_kg THEN
        PERFORM public.raise_alert_if_missing(
            NEW.batch_id,
            'E2_INCOHERENT_POIDS',
            'POINT_NOIR',
            'Poids apres lavage superieur au poids apres nettoyage D1.',
            'Recontrole lavage'
        );
    END IF;

    RETURN NEW;
END;
$$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_trigger
        WHERE tgname = 'trg_batches_quality_alerts'
    ) THEN
        CREATE TRIGGER trg_batches_quality_alerts
        AFTER INSERT OR UPDATE OF
            weight_raw_e1_kg,
            weight_after_handclean_kg,
            weight_clean_d2_kg,
            source_type
        ON public.batches
        FOR EACH ROW
        EXECUTE FUNCTION public.check_batch_quality_alerts();
    END IF;
END $$;

-- ==========================================
-- 7. INDEXES
-- ==========================================

CREATE INDEX IF NOT EXISTS idx_users_phone_number ON public.users(phone_number);
CREATE INDEX IF NOT EXISTS idx_users_sector ON public.users(sector);
CREATE INDEX IF NOT EXISTS idx_users_wilaya ON public.users(wilaya);

CREATE INDEX IF NOT EXISTS idx_batches_status ON public.batches(status);
CREATE INDEX IF NOT EXISTS idx_batches_source_type ON public.batches(source_type);
CREATE INDEX IF NOT EXISTS idx_batches_breed ON public.batches(breed);
CREATE INDEX IF NOT EXISTS idx_batches_wilaya ON public.batches(wilaya);
CREATE INDEX IF NOT EXISTS idx_batches_synced_at ON public.batches(synced_at DESC);
CREATE INDEX IF NOT EXISTS idx_batches_final_destination ON public.batches(final_destination);
CREATE INDEX IF NOT EXISTS idx_batches_type_de_laine ON public.batches(type_de_laine);
CREATE INDEX IF NOT EXISTS idx_batches_classification ON public.batches(classification);
CREATE INDEX IF NOT EXISTS idx_batches_annex_metadata ON public.batches USING gin(annex_metadata);

CREATE INDEX IF NOT EXISTS idx_alerts_batch_id ON public.alerts(batch_id);
CREATE INDEX IF NOT EXISTS idx_alerts_severity ON public.alerts(severity);
CREATE INDEX IF NOT EXISTS idx_alerts_is_resolved ON public.alerts(is_resolved);
CREATE INDEX IF NOT EXISTS idx_alerts_created_at ON public.alerts(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_vouchers_farmer_id ON public.vouchers(farmer_id);
CREATE INDEX IF NOT EXISTS idx_vouchers_batch_id ON public.vouchers(batch_id);
CREATE INDEX IF NOT EXISTS idx_vouchers_is_used ON public.vouchers(is_used);

-- ==========================================
-- 8. ROW LEVEL SECURITY
-- ==========================================

GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT SELECT ON public.batches, public.alerts TO anon, authenticated;
GRANT ALL ON public.users, public.batches, public.alerts, public.vouchers TO service_role;

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vouchers ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'users'
          AND policyname = 'service_role_all_users'
    ) THEN
        CREATE POLICY service_role_all_users ON public.users
            FOR ALL TO service_role
            USING (true)
            WITH CHECK (true);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'batches'
          AND policyname = 'service_role_all_batches'
    ) THEN
        CREATE POLICY service_role_all_batches ON public.batches
            FOR ALL TO service_role
            USING (true)
            WITH CHECK (true);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'alerts'
          AND policyname = 'service_role_all_alerts'
    ) THEN
        CREATE POLICY service_role_all_alerts ON public.alerts
            FOR ALL TO service_role
            USING (true)
            WITH CHECK (true);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'vouchers'
          AND policyname = 'service_role_all_vouchers'
    ) THEN
        CREATE POLICY service_role_all_vouchers ON public.vouchers
            FOR ALL TO service_role
            USING (true)
            WITH CHECK (true);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'batches'
          AND policyname = 'dashboard_read_batches'
    ) THEN
        CREATE POLICY dashboard_read_batches ON public.batches
            FOR SELECT TO anon, authenticated
            USING (true);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'alerts'
          AND policyname = 'dashboard_read_alerts'
    ) THEN
        CREATE POLICY dashboard_read_alerts ON public.alerts
            FOR SELECT TO anon, authenticated
            USING (true);
    END IF;
END $$;

-- Refresh the Supabase/PostgREST schema cache after setup.
NOTIFY pgrst, 'reload schema';
