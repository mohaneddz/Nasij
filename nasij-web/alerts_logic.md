# Alert Logic (Database Triggers)

This documents the automatic alert logic implemented in the database.

## Where It Lives

- The full schema path: supabase_schema.sql
- Incremental migration: nfn-backend/migrations/004_alert_triggers.sql

## Alert Types

### A1_RENDEMENT (Low Yield)

Computed at D1 using the hand-cleaning yield:

- Yield = weight_after_handclean_kg / weight_raw_e1_kg
- C1/C3 target range: 55% - 65%
- C2 target range: 35% - 45%
- Trigger when yield is below the target minimum

This creates a POINT_ROUGE alert with a description like:
"Rendement Tonte: 40.0% (cible 55-65%)."

### E2_INCOHERENT_POIDS (Incoherent Weight)

Flags data entry errors where a later weight is larger than an earlier one:

- weight_after_handclean_kg > weight_raw_e1_kg
- OR weight_clean_d2_kg > weight_after_handclean_kg

This creates a POINT_NOIR alert.

## Why This Is Logical

- A1 targets fraud or excessive dirt/water: yield lower than expected.
- E2 targets impossible weight increases between steps: data integrity.

## How It Runs

A trigger on public.batches runs after INSERT/UPDATE of:
- weight_raw_e1_kg
- weight_after_handclean_kg
- weight_clean_d2_kg
- source_type

The trigger inserts alerts only if the same type is not already active for that batch.

## Notes

- This does not auto-resolve alerts.
- If you want A1 to use D2 yield or different thresholds, update the trigger logic.
