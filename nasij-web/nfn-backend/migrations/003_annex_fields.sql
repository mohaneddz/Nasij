-- Annex-driven wool quality fields for existing Supabase projects.
-- Safe to run more than once.

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

ALTER TABLE public.batches
    ADD COLUMN IF NOT EXISTS type_de_laine public.wool_type,
    ADD COLUMN IF NOT EXISTS proprete_score INTEGER CHECK (proprete_score >= 1 AND proprete_score <= 5),
    ADD COLUMN IF NOT EXISTS sacs_count INTEGER,
    ADD COLUMN IF NOT EXISTS classification public.wool_class,
    ADD COLUMN IF NOT EXISTS temperature_tas_celsius DECIMAL(5,2),
    ADD COLUMN IF NOT EXISTS taux_matiere_vegetale_percent DECIMAL(5,2),
    ADD COLUMN IF NOT EXISTS humidite_sortie_percent DECIMAL(5,2),
    ADD COLUMN IF NOT EXISTS ph_laine DECIMAL(4,2),
    ADD COLUMN IF NOT EXISTS annex_metadata JSONB DEFAULT '{}'::jsonb;

CREATE INDEX IF NOT EXISTS idx_batches_type_de_laine ON public.batches(type_de_laine);
CREATE INDEX IF NOT EXISTS idx_batches_classification ON public.batches(classification);
CREATE INDEX IF NOT EXISTS idx_batches_annex_metadata ON public.batches USING gin(annex_metadata);

DO $$
DECLARE
    severity_constraint TEXT;
BEGIN
    SELECT conname INTO severity_constraint
    FROM pg_constraint
    WHERE conrelid = 'public.alerts'::regclass
      AND contype = 'c'
      AND pg_get_constraintdef(oid) LIKE '%severity%';

    IF severity_constraint IS NOT NULL THEN
        EXECUTE format('ALTER TABLE public.alerts DROP CONSTRAINT %I', severity_constraint);
    END IF;

    ALTER TABLE public.alerts
        ADD CONSTRAINT alerts_severity_check
        CHECK (severity IN ('POINT_NOIR', 'POINT_ROUGE', 'POINT_JAUNE'));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

NOTIFY pgrst, 'reload schema';
