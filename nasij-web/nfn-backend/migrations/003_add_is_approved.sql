-- 003_add_is_approved.sql
-- Adds an approval flag for source accounts and staff

ALTER TABLE public.users ADD COLUMN IF NOT EXISTS is_approved BOOLEAN DEFAULT FALSE;

-- Ensure all currently existing users are automatically approved so they don't get locked out
UPDATE public.users SET is_approved = TRUE;
