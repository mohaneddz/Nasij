-- Auto-create alerts based on batch weights.
-- Safe to run more than once.

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

NOTIFY pgrst, 'reload schema';
