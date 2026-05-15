


Here is the absolute deep-dive into the **Web Dashboard (The NFN Control Tower)**. 

Since all the messy, offline data entry happens on the Mobile App, the Web Dashboard has only one job: **To look like a hyper-advanced, governmental command center.** This is what will be projected on the big screen while you talk. It needs to look expensive.

Hand this directly to your Frontend Web Developer (React / Next.js).

---

# 🖥️ THE WEB DASHBOARD: TECHNICAL & UI BLUEPRINT

## 🛠️ 1. The Hackathon Tech Stack (Build it Fast)
*   **Framework:** Next.js (App Router) or Vite + React.
*   **Styling:** Tailwind CSS (Do not write custom CSS, you don't have time).
*   **UI Components:** Use **shadcn/ui** or **Tremor.so**. *(Tremor is specifically built for dashboards and has beautiful charts and metric cards out-of-the-box).*
*   **Maps:** `react-leaflet` (Free, no API keys needed, works instantly).
*   **Charts:** `recharts` (for the yield and breed distribution graphs).

---

## 📐 2. THE GLOBAL LAYOUT (Theme & Navigation)
**Theme:** "Industrial Ministry." White and light gray backgrounds, dark text. Use strict color coding for statuses: 
*   🟢 **Green (Emerald):** Good yield, smooth transit.
*   🟡 **Yellow (Amber):** Waiting in Stockage.
*   🔴 **Red (Rose):** Alerts (A1 / E1) or fraud detection.

**Sidebar Menu (Left Side):**
1. 📊 Tableau de Bord (Home / KPIs)
2. 🗺️ Cartographie Live (The Map)
3. 🔄 Flux NFN (The Kanban Pipeline)
4. ⚠️ Centre de Contrôle (Alerts)
5. 📜 Sceau & Export (Phase 5)

---

## 🔍 3. SCREEN-BY-SCREEN UI BREAKDOWN

### 📊 Screen 1: Tableau de Bord (The KPI Home)
*The PDF explicitly states the problem is "comparer ce qui a été annoncé avec ce qui a été réellement collecté." This screen solves that visually.*

*   **Top Row (4 Big Metric Cards):**
    1.  **Volume Global Annoncé:** "12,500 kg" (Sum of all C1/C2/C3 requests).
    2.  **Volume Réel Réceptionné (D1):** "11,200 kg". *(Underneath, show a red pill: `Écart de -10.4%`. This proves you track the loss!).*
    3.  **Rendement Moyen (Lavage D2):** "42.5%" *(Average clean wool yield).*
    4.  **Alertes Actives:** "3" *(Pulsing red icon).*
*   **Middle Row (Charts):**
    *   *Donut Chart:* **Répartition par Race** (Ouled Djellal: 40%, Rembi: 30%, El Hamra: 20%, Mixte: 10%).
    *   *Bar Chart:* **Qualité Fibre Phase 4** (D3 Textiles vs. D4 Bio-fertilisants).

### 🗺️ Screen 2: Cartographie Live (The "Wow Factor" Map)
*This is where you show the offline-sync working live.*
*   **The UI:** A massive map of Algeria covering the whole screen.
*   **The Markers:**
    *   📍 **Green Pins:** `PENDING_PICKUP` (Farmers waiting for collectors).
    *   🚚 **Blue Truck Icons:** `COLLECTED_BY_BUYER` (Wool currently driving to the D1 warehouse).
*   **The Interaction:** Clicking a pin opens a clean popup:
    *   *"ID: NFN-899 | Wilaya: Djelfa | Source: C1 | Race: Ouled Djellal | Price Paid: 15,000 DZD."*

### 🔄 Screen 3: Flux NFN (The Digital Diagram)
*This proves you digitized the exact diagram they drew on paper.*
*   **The UI:** A Kanban board with 4 vertical columns.
*   **Column 1: Collecte (Phase 1)** - Cards waiting for pickup.
*   **Column 2: Dépôt & Stockage (D1)** - Cards sitting in the warehouse. Show the specific Zone on the card (e.g., `Zone: REMBI`).
*   **Column 3: Lavage (D2)** - Cards currently in the washing phase.
*   **Column 4: Transformation (Phase 4)** - Cards ready to be split into D3/D4.
*   *Live Magic:* Tell your dev to use a simple `setInterval` to fetch the database every 3 seconds. When you scan the QR code on the mobile app during the pitch, the judges will watch a card physically jump from Column 2 to Column 3 on the web screen without you touching the mouse.

### ⚠️ Screen 4: Centre de Contrôle (The Fraud & Alert Center)
*This addresses the "ruptures d'information" and quality control.*
*   **The UI:** A strict data table of flagged batches.
*   **Alert Type 1: Alerte E1 (Perte en Route)**
    *   *Visual:* 🔴 Point Noir.
    *   *Text:* "Batch NFN-102. Collector declared 500kg at farm. D1 Worker received 400kg. **100kg missing.**"
*   **Alert Type 2: Alerte A1 (Rendement Faible / Fraude à la saleté)**
    *   *Visual:* 🔴 Point Rouge.
    *   *Text:* "Batch NFN-304 (Source C2). Weight before hand-cleaning: 200kg. Weight after: 80kg. **Massive 60% drop.** Supplier likely added dirt/water to inflate price."

### 📜 Screen 5: Sceau NFN (Phase 5: Commercialisation)
*The final industrial output for international buyers.*
*   **The UI:** A list of `READY_FOR_SALE` batches.
*   **The Columns:** `Batch ID`, `Race`, `Fiber Length (mm)`, `Microns (µm)`, `Humidity (%)`.
*   **The Button:** **[ Générer Passeport NFN ]**
*   **The Action:** Clicking this opens a beautiful, printable "Digital Certificate" Modal. It contains a giant QR code. You tell the judges: *"If a carpet manufacturer in Italy scans this, they see the exact farm, the exact sheep breed, and the exact micron density verified by the Algerian State."*

---

## 🚀 HACKATHON SURVIVAL TIPS FOR THE WEB DEV

1.  **Do NOT build a Login for the Web:** You are wasting precious hours. Hardcode the dashboard to be "Logged in as Ministry Admin". 
2.  **Seed the Database:** An empty dashboard is boring. Write a quick SQL script or JS function to instantly inject 20 fake batches into your Supabase database. Make sure some are in D1, some are in D2, and force one to have a bad yield so an Alert A1 shows up.
3.  **Tremor is your best friend:** Seriously, Google "Tremor React". You can copy-paste their `Card`, `DonutChart`, and `Badge` components, and your dashboard will look like a $100,000 enterprise software in 10 minutes.
4.  **Fake real-time if WebSockets are hard:** Setting up real-time database listeners (like Supabase Realtime) can sometimes cause annoying bugs during a hackathon. **The Cheat Code:** Just use `SWR` or `React Query` with a `refreshInterval: 2000` (2 seconds). The dashboard will silently update itself in the background, achieving the exact same "real-time" effect for the presentation with zero complex code.

---

## 🎤 THE PITCH SCRIPT FOR THE WEB DASHBOARD

*(While your teammate is showing the Mobile App syncing offline data, you point to the Web Dashboard on the projector).*

> "While the mobile app captures the messy reality of the field, this is the **NFN Control Tower**. 
> 
> The Cahier des Charges asked us to identify 'écarts de quantité' (volume discrepancies). Look at our top metrics. We don't just track what arrives; we track the exact percentage of wool lost between the farm and the factory. 
> 
> If a collector tries to steal wool in transit, or if a slaughterhouse packs their wool with mud to inflate the price, our **Centre de Contrôle** catches it instantly. The Mobile App forces them to input weights at every step, and the Web Dashboard automatically calculates the math, flagging Alert A1 or E1 without human intervention.
> 
> Finally, we organize the data not by generic IDs, but by our national breeds—Ouled Djellal, Rembi, Tezegzawet. By the time the wool reaches Phase 5, we generate a verifiable digital passport containing the exact micron density and fiber length, ready for the global market."

**Send this to your Frontend Dev. Tell them to focus heavily on making the charts and the Map look beautiful. The Backend and Mobile will handle the actual data. Go build!**