-- Ensure alerts.action exists for older projects.
-- Safe to run more than once.

ALTER TABLE public.alerts
    ADD COLUMN IF NOT EXISTS action VARCHAR(100);

NOTIFY pgrst, 'reload schema';
