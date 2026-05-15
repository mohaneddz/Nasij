-- NFN Database Schema
-- Run this in the Supabase SQL Editor (https://supabase.com/dashboard)

-- 1. ENUMS
DO $$ BEGIN
    CREATE TYPE sector_role AS ENUM (
        'C1_FARMER', 'C2_ABATTOIR', 'C3_AGGREGATOR',
        'COLLECTOR', 'WORKER', 'MANAGER'
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE sheep_breed AS ENUM (
        'OULED_DJELLAL', 'REMBI', 'EL_HAMRA',
        'BARBAR', 'TEZEGZAWET', 'MIXTE'
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
    CREATE TYPE batch_status AS ENUM (
        'PENDING_PICKUP', 'COLLECTED_BY_BUYER',
        'AT_D1_STOCKAGE', 'AT_D2_LAVAGE',
        'IN_TRANSFORMATION', 'READY_FOR_SALE'
    );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;


-- 2. USERS TABLE
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY,
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    sector sector_role NOT NULL,
    wilaya VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- 3. BATCHES TABLE
CREATE TABLE IF NOT EXISTS batches (
    batch_id VARCHAR(50) PRIMARY KEY,
    source_type VARCHAR(10),
    breed sheep_breed NOT NULL,
    wilaya VARCHAR(100),
    creator_phone VARCHAR(20),
    collector_phone VARCHAR(20),
    status batch_status DEFAULT 'PENDING_PICKUP',

    -- Financials
    purchase_price_dzd DECIMAL(10,2),

    -- Depot D1
    weight_raw_e1_kg DECIMAL(10,2),
    weight_after_handclean_kg DECIMAL(10,2),
    stockage_zone VARCHAR(50),

    -- Lavage D2
    weight_clean_d2_kg DECIMAL(10,2),

    -- Transformation
    fiber_length_mm DECIMAL(5,2),
    finesse_micron DECIMAL(5,2),
    humidity_percent DECIMAL(5,2),
    final_destination VARCHAR(50),

    -- GPS
    location_lat DECIMAL(9,6),
    location_lng DECIMAL(9,6),

    -- Sync timestamps
    action_timestamp TIMESTAMP,
    synced_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- 4. ALERTS TABLE
CREATE TABLE IF NOT EXISTS alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id VARCHAR(50) REFERENCES batches(batch_id),
    alert_type VARCHAR(50),
    severity VARCHAR(20) DEFAULT 'POINT_ROUGE',
    description TEXT,
    is_resolved BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- 5. RLS POLICIES (allow service role full access)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE alerts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Service role full access" ON users
    FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Service role full access" ON batches
    FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Service role full access" ON alerts
    FOR ALL USING (true) WITH CHECK (true);


-- 6. INDEXES
CREATE INDEX IF NOT EXISTS idx_batches_status ON batches(status);
CREATE INDEX IF NOT EXISTS idx_batches_breed ON batches(breed);
CREATE INDEX IF NOT EXISTS idx_batches_wilaya ON batches(wilaya);
CREATE INDEX IF NOT EXISTS idx_alerts_batch_id ON alerts(batch_id);
CREATE INDEX IF NOT EXISTS idx_alerts_is_resolved ON alerts(is_resolved);
