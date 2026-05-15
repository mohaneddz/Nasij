


Here is your **Final, Ultimate Master Context Document**, completely upgraded with the **Offline-First Architecture**. 

This is the "Silver Bullet" for your hackathon. When the judges say, *"But there is no 4G in the deep rural areas of Djelfa or Tiaret, your app won't work,"* you will smile, open the app, turn on Airplane Mode, do a full transaction, and say, *"We already thought of that."*

Copy this PRD (Product Requirement Document) and send it to your team.

---

# 🚀 PROJECT NASIJ (نساج) / NFN
**The Slogan:** *Digital Traceability built for the Algerian Reality.*
**The Concept:** An **Offline-First** B2B Marketplace for wool collection, combined with an industrial NFN Traceability and AI Qualification platform.

---

## 📡 THE OFFLINE-FIRST ARCHITECTURE (The Game Changer)
Rural Algeria has patchy internet. The app must never block a user because of a missing connection.
*   **How it works:** The Mobile App uses a local database (SQLite/Hive). When a Collector buys wool or a Worker weighs it, the data is saved *instantly* to the phone, and the QR code is generated locally. 
*   **The Sync:** When the phone detects 3G/4G/Wi-Fi again, a background worker automatically pushes the cached operations to the central NFN database.
*   **The UI Proof:** The app features a visible "Cloud Icon" at the top (🟢 *Online & Synced* | 🟡 *Offline: 3 actions pending*). **You will show this live to the judges by putting your phone in Airplane Mode during the demo.**

---

## 👥 1. AUTHENTICATION & USER ROLES
**No Emails. No Passwords.** 
Users log in using their **Phone Number** and select their **Sector (Role)**. The session is cached locally so they stay logged in even without internet.

1.  **C1/C2/C3 (Producers):** Farmers, Slaughterhouses, or Aggregators.
2.  **Collector (The Buyer):** The merchant who drives the truck.
3.  **D1 Worker:** Handles warehouse sorting, cleaning, and storage.
4.  **D2/D3 Worker:** Handles washing and industrial metrics.
5.  **NFN Manager (Ministry):** Uses the Web Dashboard (Always online).

---

## 🔄 2. THE 5-STEP PIPELINE (The App Logic)

### 📱 PHASE 1: Collecte (The Offline B2B Marketplace & QR Birth)
*   **The Sync (In the City):** The Collector is in the city with 4G. They open the app and download the "Available Wool Feed". 
*   **The Offline Deal:** They drive to a remote farm (No internet). They negotiate the price in DZD with the farmer.
*   **The Offline QR Birth:** The Collector hits **"Buy & Collect"**. The app generates a unique QR Code (e.g., `NFN-1042`) entirely offline. The transaction is cached on the phone. Ownership is transferred.

### 🏭 PHASE 2: Dépôt Intermédiaire (Smart Identification & Stockage)
The Collector arrives at the D1 Warehouse. The D1 Worker uses their app (which works even if warehouse Wi-Fi goes down):
1.  **Réception:** Scan QR confirms arrival.
2.  **Pesée (E1 Audit):** Worker enters raw weight.
3.  **Identification (Smart Logic):** 
    *   *If C2 (Slaughterhouse):* App alerts worker: *"🔴 C2 Source: Perform Peeling (Délainage) & Hand-Cleaning."*
    *   *If C1/C3:* App alerts: *"🟢 C1/C3 Source: Perform Hand-Cleaning Only."*
    *   Worker inputs new weight. *(If weight drops massively, the app caches an **Alert A1**).*
4.  **Stockage (By Breed):** The app instructs the worker to store it in specific heritage zones: **Ouled Djellal, Rembi, El Hamra, Barbar, Tezegzawet.**

### 🧼 PHASE 3: Lavage (Washing & Yield)
*   **Lavage:** Worker scans QR to pull wool from Stockage and wash it.
*   **Mesure du Rendement:** Worker enters the clean, dry weight. The app locally calculates the yield `(Clean Weight / Initial Weight)`.

### 🔬 PHASE 4: Transformation (Qualification de la Fibre)
*   The worker takes a photo of the clean wool (AI visual check).
*   The worker inputs the industrial metrics: **Fiber Length (mm), Finesse (Microns), Humidity Rate (%).**
*   **The Split:** The app routes the wool to **D3** (High-quality textiles) or **D4** (Low-quality bio-fertilizers).

### 🌍 PHASE 5: Commercialisation (The NFN Seal)
*   The data reaches the Web Dashboard (Ministry).
*   The Dashboard generates a **Digital Passport** (NFN Sceau de Certification).
*   Buyers scan this final QR code to see 100% traceability: *Bought offline in Djelfa -> Washed -> 45% Yield -> Rembi Breed -> 80mm Length -> Certified.*

---

## 💻 3. DEVELOPMENT ASSIGNMENTS

### 📱 A. The Mobile App (Flutter/React Native)
*   **The Sync Engine:** Use `ConnectivityPlus` and `Hive/SQLite`. Every action is saved locally first. 
*   **The UI Header:** Put a "Sync Status" indicator in the AppBar so judges can physically see the app caching data when offline.
*   **Screen 1:** Phone Number Login + Sector Dropdown.
*   **Screen 2 (Producers):** "Declare Wool Available" (Select Breed).
*   **Screen 3 (Collectors):** Downloaded Marketplace feed. "Generate QR / Buy" button works offline.
*   **Screen 4 (Workers):** "SCAN QR" button. Triggers dynamic forms for D1 (Smart Identification), D2 (Lavage), and Phase 4 (Transformation).

### 🖥️ B. The Web Dashboard (Next.js/React)
*   **The Live Map:** Shows active Producers (Green) and Collector pick-ups (Blue). Pins appear instantly when field apps sync.
*   **The NFN Flowchart:** Digital Kanban board (*Collecte -> D1 -> Lavage -> Transformation*).
*   **Alert Center:** Flashes red if **Alert A1** (fraud/excessive dirt at D1) triggers.
*   **Commercialisation Tab:** Shows the inventory of finished D3/D4 products ready to be sold internationally.

### 🗄️ C. The PostgreSQL Database (Supabase)
*Crucial Backend Note for Offline Apps: The MOBILE APP must generate the UUIDs and QR Codes, not the Database. This prevents ID clashes when offline data syncs.*

```sql
-- 1. ENUMS
CREATE TYPE sector_role AS ENUM ('C1_FARMER', 'C2_ABATTOIR', 'C3_AGGREGATOR', 'COLLECTOR', 'WORKER', 'MANAGER');
CREATE TYPE sheep_breed AS ENUM ('OULED_DJELLAL', 'REMBI', 'EL_HAMRA', 'BARBAR', 'TEZEGZAWET', 'MIXTE');
CREATE TYPE batch_status AS ENUM ('PENDING_PICKUP', 'COLLECTED_BY_BUYER', 'AT_D1_STOCKAGE', 'AT_D2_LAVAGE', 'IN_TRANSFORMATION', 'READY_FOR_SALE');

-- 2. USERS TABLE
CREATE TABLE users (
    id UUID PRIMARY KEY, -- Generated on device
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    sector sector_role NOT NULL,
    wilaya VARCHAR(100)
);

-- 3. BATCHES TABLE (The Ultimate Tracker)
CREATE TABLE batches (
    batch_id VARCHAR(50) PRIMARY KEY, -- The QR Code ID generated offline
    source_type VARCHAR(10), 
    breed sheep_breed NOT NULL,
    creator_phone VARCHAR(20),
    collector_phone VARCHAR(20),
    status batch_status DEFAULT 'PENDING_PICKUP',
    
    -- Financials
    purchase_price_dzd DECIMAL(10,2),
    
    -- Dépôt D1 (Smart Identification)
    weight_raw_e1_kg DECIMAL(10,2), 
    weight_after_handclean_kg DECIMAL(10,2),
    stockage_zone VARCHAR(50), 
    
    -- Lavage D2
    weight_clean_d2_kg DECIMAL(10,2),
    
    -- Transformation
    fiber_length_mm DECIMAL(5,2),
    finesse_micron DECIMAL(5,2),
    humidity_percent DECIMAL(5,2),
    final_destination VARCHAR(50), -- 'D3' or 'D4'
    
    -- Sync Timestamps (Crucial for offline)
    action_timestamp TIMESTAMP, -- When it actually happened in the field
    synced_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- When it hit the database
);

-- 4. ALERTS TABLE
CREATE TABLE alerts (
    id UUID PRIMARY KEY, 
    batch_id VARCHAR(50) REFERENCES batches(batch_id),
    alert_type VARCHAR(50), 
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## 🎤 4. THE ULTIMATE PITCH & LIVE DEMO
*(This is how you destroy the competition on stage)*

> **Speaker:** "The Algerian market isn't ready for complex apps. And worse, there is no 4G in the deep rural farms of Djelfa or Tiaret. If your traceability app requires the internet to generate a QR code, your supply chain is already broken."
> 
> "That’s why **Nasij** is **Offline-First**. 
> *(Pull out your phone, plug it into the screen, and visibly turn on Airplane Mode).* 
> "I am a Collector. I am in the middle of nowhere. I make a deal with a farmer. I hit 'Buy'. The app generates the QR code and saves the transaction entirely offline. See this yellow cloud icon? It’s caching."
> 
> *(Turn Wi-Fi back on. Point to the Web Dashboard on the main screen).*
> "When the truck hits the highway and detects 3G, it syncs. Watch the dashboard." *(The pin instantly appears on the map).* "The exclamation marks (!) on your diagram are now unbreakable."
> 
> "But we didn't stop at tracking. At Dépôt D1, the app uses Smart Logic: if it scans C2 Slaughterhouse wool, it forces the worker to peel and clean it. If the weight drops suspiciously, we trigger **Alert A1**. We store wool not by random numbers, but by Algerian heritage: **Ouled Djellal, Rembi, El Hamra**."
> 
> "Finally, we track the industrial metrics—**Fiber Length, Microns, Humidity**—routing the wool to D3 Textiles or D4 Bio-fertilizers. The Ministry gets a real-time Control Tower, and international buyers get a digital NFN Seal proving 100% traceability from an offline Algerian farm to the global market."

**This architecture proves you aren't just student coders; you are engineers building for harsh, real-world physical constraints.** Execute this, and you cannot lose.