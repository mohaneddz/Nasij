


Let's zoom in entirely on the **Web Dashboard** (The NFN Control Tower). 

Since the Web Dashboard is what you will show on the big screen during your presentation, **this is what the judges will stare at.** It needs to look like a high-tech logistics command center for a national industry. 

Tell your Frontend Web Developer (React / Next.js / Vue) to build exactly this layout.

---

### 🖥️ THE NFN CONTROL TOWER (Overall UI Layout)

**Theme:** Clean, modern, data-heavy. (Think logistics dashboards like Uber Freight or Amazon Logistics). Use a light theme with strong accent colors (Red for alerts, Green for good yield, Blue for active transit).

**Sidebar Navigation (Menu on the left):**
1. 📊 Vue Globale (Dashboard / KPIs)
2. 🗺️ Cartographie (Live Map)
3. 🔄 Flux de Matière (The D1/D2 Pipeline)
4. ⚠️ Centre d'Alertes (Anomalies & Audits)
5. 📜 Sceau NFN (Certifications)

---

### 🔍 DEEP DIVE: SCREEN-BY-SCREEN FOR THE WEB DEV

#### 1. 📊 Vue Globale (The KPI Dashboard)
*This is the home page. It proves to the judge that you give the Ministry a "vision globale" (as requested on Page 4 of the PDF).*
*   **Top Row (4 Big Number Cards):**
    *   *Card 1:* **Volume Annoncé (Ce mois):** e.g., 12.5 Tonnes (Sum of all C1, C2, C3 declarations).
    *   *Card 2:* **Volume Réel Réceptionné (D1):** e.g., 11.2 Tonnes. *(Put a little red indicator underneath saying "-10% d'écart" to show you track the loss).*
    *   *Card 3:* **Rendement Moyen (D2):** e.g., 42% (The average yield after washing. Highly technical detail judges will love).
    *   *Card 4:* **Alertes Actives:** e.g., 3 (Flashing red if > 0).
*   **Below the Cards:** A simple bar chart showing "Collecte par Wilaya" (Djelfa, Tiaret, M'Sila, Batna).

#### 2. 🗺️ Cartographie Nationale (The Live Map)
*This is the "Wow Factor" screen. Use Leaflet.js, Mapbox, or Google Maps.*
*   **The UI:** A large map of Algeria takes up the whole screen.
*   **The Pins (Markers):**
    *   🟢 **Green Pins (En attente):** Wool declared via Bot/App sitting at farms.
    *   🔵 **Blue Truck Icons (En transit):** Batches that drivers scanned and are currently driving to D1.
    *   🔴 **Pulsing Red Pins (Urgence C2):** Slaughterhouses where the 24-hour "Cold Chain" timer is expiring.
*   **Interaction:** If you click a pin, a small popup appears:
    *   *Batch #NFN-883 | Source: C1 (Djelfa) | Quantity: ~500kg | Status: Waiting for pickup.*

#### 3. 🔄 Flux de Matière (The NFN Pipeline / Kanban)
*This screen is the digital translation of the hand-drawn flowchart they gave you.*
*   **The UI:** Four vertical columns (like a Trello or Kanban board).
*   **Column 1: Source (C1/C2/C3)** - Cards sit here when `Status = PENDING`.
*   **Column 2: Dépôt D1 (Pré-tri)** - Cards move here when `Status = AT_D1`.
    *   *On the card it shows:* "Annoncé: 500kg | Reçu: 490kg".
*   **Column 3: Laverie D2 (Lavage)** - Cards move here when `Status = AT_D2`.
    *   *On the card it shows:* "Poids Sale: 490kg | Poids Propre: 210kg | Rendement: 42%".
*   **Column 4: Transformation (D3/D4)** - Cards sit here waiting for final sale.
*   *Presentation Trick:* Have a teammate use the mobile app to "Scan" a QR code while this screen is open. The judges will watch a card literally fly from Column 1 to Column 2 live on screen.

#### 4. ⚠️ Centre d'Alertes (The "Point Noir / Point Rouge" Screen)
*The PDF heavily emphasizes preventing "pertes de matière" (material loss) and "ruptures d'information". This screen proves your system automatically catches thieves and bad data.*
*   **The UI:** A table of active anomalies.
*   **Alert Type 1: ⚫ Point Noir (Audit E1 - Réconciliation)**
    *   *Description:* "Batch NFN-104 from Batna. Driver announced 1000kg. Dépôt D1 only received 800kg. 200kg missing in transit."
    *   *Action Button:* [ Investigate ]
*   **Alert Type 2: 🔴 Point Rouge (Alerte A1 - Rendement Faible)**
    *   *Description:* "Batch NFN-205 at Laverie D2. Yield is critically low (18%). Standard is 40%. Possible fraudulent dirt added by supplier to increase weight."
    *   *Action Button:* [ Flag Supplier ]
*   **Alert Type 3: 🔴 Point Rouge (Alerte C2 - Chaîne du froid)**
    *   *Description:* "Abattoir Tiaret. Skins waiting for > 24 hours. High risk of rotting."
    *   *Action Button:*[ Dispatch Emergency Truck ]

#### 5. 📜 Sceau NFN & Finalisation (The Certification Page)
*The end of the supply chain.*
*   **The UI:** A list of "Finished Goods" (Clean wool ready for factories).
*   **The Feature:** A button that says **"Générer Certificat NFN"**.
*   **The Result:** When clicked, it opens a modal with a big **QR Code**. 
*   *Presentation script:* "If an international buyer scans this seal, they see a digital passport: It proves this wool was sheared in Djelfa on Monday, washed in D2 on Wednesday with a 45% yield, and is certified by the Algerian Ministry. 100% Traceability."

---

### 💻 DEV SHORTCUTS (How to build this in 24 hours)

1.  **Frontend Framework:** Use **Next.js** or **Vite + React**. 
2.  **UI Library:** Do not write custom CSS. Use **Tailwind CSS** combined with **shadcn/ui** or **MUI (Material UI)**. You can copy-paste beautiful tables, cards, and sidebar menus in seconds.
3.  **The Map:** Use **React-Leaflet**. It is free, doesn't require API keys (unlike Google Maps), and you can easily map over your database array to drop pins.
4.  **Mocking the Data (CRITICAL):**
    *   Your database will be empty at the hackathon. 
    *   Tell your backend dev to write a "Seeder" script. A simple file that loops 20 times and pushes fake data into the database so your Web Dashboard is full of numbers, alerts, and map pins before you even start the presentation.
    *   *Example:* Hardcode 5 pins in Djelfa, 3 in Tiaret, 2 in M'sila. Hardcode one `E1` alert so you have something to talk about.

### Why this specific Web layout wins:
The judge told you: *"The Algerian market isn't ready for complex apps."* 
By putting all the complex graphs, analytics, and alerts exclusively on the **Web Dashboard** (used only by trained NFN managers) and keeping the field tools (Bot/App) incredibly stupid-simple, you completely destroy the judge's argument. You give the state the high-tech control they want, without forcing the shepherd to be a tech genius.