


You are 100% right. I was overcomplicating it. For a hackathon, building a separate web portal just for the slaughterhouse is a waste of time. **Putting ALL data entry into the Mobile App is a much smarter, faster, and cleaner architecture.** 

Let's strip away the noise. 

**The New Rule:**
*   **Data IN = Mobile App** (and the Bot for old-school farmers).
*   **Data OUT / Tracking = Web Dashboard** (Only the Boss/Manager uses the web).

Here is the fully reorganized plan, along with the exact **PostgreSQL database code** so your backend dev can just copy and paste it right now.

---

### 🗄️ THE POSTGRESQL DATABASE (Copy & Paste this)

Give this exact SQL code to your backend developer to run in Supabase or any Postgres database.

```sql
-- 1. Create ENUMs for clean data
CREATE TYPE user_role AS ENUM ('FARMER', 'ABATTOIR', 'AGGREGATOR', 'DRIVER', 'WORKER', 'MANAGER');
CREATE TYPE batch_status AS ENUM ('PENDING', 'EN_ROUTE', 'AT_D1', 'AT_D2', 'TRANSFORMING', 'CERTIFIED');
CREATE TYPE source_enum AS ENUM ('C1', 'C2', 'C3');

-- 2. Users Table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role user_role NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    phone_number VARCHAR(50) UNIQUE,
    wilaya VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Batches Table (The Core NFN QR Code Flow)
CREATE TABLE batches (
    batch_id VARCHAR(50) PRIMARY KEY, -- e.g., 'NFN-1042' (The QR Code)
    source_type source_enum NOT NULL,
    creator_id UUID REFERENCES users(id),
    status batch_status DEFAULT 'PENDING',
    
    -- Location for the Map
    location_lat DECIMAL(10, 8),
    location_lng DECIMAL(11, 8),
    wool_breed VARCHAR(100),
    
    -- The NFN Audit Weights
    declared_weight_kg DECIMAL(10, 2), -- What app/bot says at the start
    actual_weight_d1_kg DECIMAL(10, 2), -- What worker inputs at D1
    clean_weight_d2_kg DECIMAL(10, 2), -- What worker inputs at D2
    yield_percentage DECIMAL(5, 2), -- Calculated automatically
    
    -- Specific to C2 (Slaughterhouse)
    slaughter_time TIMESTAMP, -- Triggers the Cold Chain Alert
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Alerts Table (Feeds the Web Dashboard)
CREATE TABLE alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id VARCHAR(50) REFERENCES batches(batch_id),
    alert_type VARCHAR(50) NOT NULL, -- 'A1_RENDEMENT', 'E1_RECONCILIATION', 'C2_COLD_CHAIN'
    description TEXT,
    is_resolved BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Vouchers Table (The Circular Economy Loop)
CREATE TABLE vouchers (
    voucher_id VARCHAR(50) PRIMARY KEY, -- e.g., 'FERT-9981'
    farmer_id UUID REFERENCES users(id),
    batch_id VARCHAR(50) REFERENCES batches(batch_id),
    reward_type VARCHAR(100) DEFAULT 'BIO_FERTILIZER_50KG',
    is_used BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

### 👥 THE USERS (Simplified)

1.  **The Farmer (C1):** Uses the **Telegram Bot** (if low-tech) OR the **Mobile App** (if modern).
2.  **The Abattoir Manager (C2):** Uses the **Mobile App**.
3.  **The Aggregator (C3):** Uses the **Mobile App**.
4.  **The Driver & Warehouse Workers (D1/D2):** Uses the **Mobile App** (Scanner Mode).
5.  **The NFN Manager (The Boss):** Uses the **Web Dashboard** (Tracking only).

---

### 📱 THE MOBILE APP (Detailed Screen-by-Screen)
*This app handles ALL data entry.*

**Screen 1: Login**
*   User logs in and selects their role.

**Screen 2: The "Declaration" Tab (If user is C1, C2, or C3)**
*   **Feature:** "+ New Declaration"
*   **Dynamic Form:**
    *   *If Farmer (C1) or Aggregator (C3):* Asks for Estimated Weight (or number of fleeces), Breed, and fetches GPS.
    *   *If Abattoir (C2):* Asks for Skin Weight, Breed, GPS, **AND asks for "Time of Slaughter"** (this is what triggers the 24h cold-chain alert).
    *   *Bonus UI Button:* "Use AI to estimate volume" (opens camera, fakes an estimation).
*   **Output:** Submits to DB, generates a QR Code on their screen. Status = `PENDING`.

**Screen 3: The "Scanner / Logistics" Tab (If user is Driver or Worker)**
*   **Feature:** Giant **[ SCAN QR ]** button opening the camera.
*   **Action 1 (Driver picking up):** Scans the code on the farmer/abattoir's phone. Clicks "Pickup". Status -> `EN_ROUTE`.
*   **Action 2 (Worker at D1):** Scans the bag. App prompts: *"Enter exact weight received."* (Updates `actual_weight_d1_kg` in DB). Status -> `AT_D1`.
*   **Action 3 (Worker at D2):** Scans the bag. App prompts: *"Enter clean weight after washing."* (Updates `clean_weight_d2_kg` in DB). Status -> `AT_D2`.

**Screen 4: Wallet (For Farmers only)**
*   Shows their earned Fertilizer Vouchers.

---

### 🖥️ THE WEB DASHBOARD (Detailed Screen-by-Screen)
*This is purely a Control Tower. No data entry happens here. It just reads the PostgreSQL database.*

**Screen 1: The Live Map (Vue Géospatiale)**
*   **Visuals:** Map of Algeria.
*   *Green Dots:* Batches with status `PENDING` (Waiting to be picked up).
*   *Blue Dots:* Batches with status `EN_ROUTE`.
*   *Flashing Red Dots:* Abattoir (C2) batches where `Current Time` is > 24 hours past `slaughter_time` (Cold Chain Warning).

**Screen 2: The Process Flowchart (Vue Processus)**
*   **Visuals:** Four columns (Collecte -> Dépôt D1 -> Lavage D2 -> Transformation).
*   **Function:** Counts how many batches are currently in each phase. When a worker scans something on the Mobile App, the number on the Web Dashboard instantly moves from one column to the next.

**Screen 3: The Alert Feed (Point Noir/Rouge)**
*   **Visuals:** A sidebar or table showing automatic alerts.
*   *Alerte E1 (Réconciliation):* Shows up if a worker at D1 enters a weight that is 15% lower than what the App/Bot originally declared.
*   *Alerte A1 (Rendement):* Shows up if a worker at D2 enters a clean weight that drops the yield below 30%.
*   *Alerte C2 (Chaine du froid):* Shows up if slaughterhouse wool isn't collected fast enough.

**Screen 4: Certification (Sceau NFN)**
*   **Visuals:** A list of batches that have passed `AT_D2` and are ready for the market.
*   **Action:** A "Generate NFN Seal" button that spits out a final summary QR code proving the wool is legit, traceable, and legal.

---

### 🚀 WHY THIS IS THE WINNING ARCHITECTURE
1.  **Less Code:** You only build ONE frontend app (Mobile) and ONE tracking dashboard (Web).
2.  **No Confusion:** The judges will easily understand: *"App = Input. Web = Management."*
3.  **Covers Every PDF Rule:** You still have all 3 sources (C1, C2, C3), the alerts (A1, E1), the cold chain, and the yield tracking. 

Tell your Mobile Dev to build the form and the scanner. Tell your Web Dev to build the Map and the Flowchart. Tell your Backend Dev to run that SQL script. You're set!