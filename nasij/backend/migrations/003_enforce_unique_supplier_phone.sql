-- Migration 003: Enforce unique supplier mobile number in users table.
-- Normalizes whitespace before creating a uniqueness guarantee.

UPDATE public.users
SET phone_number = regexp_replace(phone_number, '\s+', '', 'g')
WHERE phone_number IS NOT NULL;

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM public.users
        WHERE phone_number IS NOT NULL AND btrim(phone_number) <> ''
        GROUP BY phone_number
        HAVING COUNT(*) > 1
    ) THEN
        RAISE EXCEPTION
            'Cannot enforce unique phone_number: duplicate values exist in public.users.';
    END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS idx_users_phone_number_unique
    ON public.users (phone_number)
    WHERE phone_number IS NOT NULL AND btrim(phone_number) <> '';
