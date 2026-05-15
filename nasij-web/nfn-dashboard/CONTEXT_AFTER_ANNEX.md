1. Screen: Tableau de Bord (The Home KPIs)
Update your charts to reflect the Matrix (Annex 2).
KPI 1: Rendement Tonte (C1): Show a green number like "62%". Add subtext: "Cible: 55-65%".
KPI 2: Rendement Abattage (C2): Show a yellow number like "38%". Add subtext: "Cible: 35-45%".
(Why? This proves you read the matrix and know that C1 and C2 have completely different expected yields).
Chart: Qualité du Tri (D1): Create a Donut Chart showing Classe A (Propre - 60%) vs Classe B (Souillée - 40%).
2. Screen: The "Lot Details" Sidebar (NEW - THE ULTIMATE FLEX)
When a user clicks on a batch (on the Map or the Kanban board), a sleek Sidebar/Drawer slides out from the right side. It should display the highly technical Annex data:
Header: LOT NFN-1042 | Source: Abattage (C2) | Race: Ouled Djellal
Section 1: Collecte: Extraction: Chimique (Pelade) | Qualité: 4/5
Section 2: Tri (Dépôt D1): Température du tas: 38°C | Taux VM: 2%
Section 3: Lavage (D2): Humidité résiduelle: 13% | pH: 7.1
(Mock this data! Even if the mobile guy isn't sending it yet, hardcode a fake JSON object in your React state so you can show it on screen).
3. Screen: Alert Center (Centre de Contrôle)
Instead of generic alerts, hardcode these 3 specific Annex Alerts into your table to prove you integrated the document:
🔴 Alerte Rendement Intelligent: "Lot NFN-202 (Tonte C1). Rendement actuel: 40%. Anomalie: Le rendement tonte doit être > 55%. Risque de fraude."
🔥 Alerte Auto-Combustion: "Lot NFN-304 (Dépôt D1). Température du tas critique (45°C). Risque d'incendie ou pourriture." (Directly from Annex 1, Section 3).
🟡 Alerte Matières Végétales (VM%): "Lot NFN-405. Taux de paille > 5%. Action auto: Redirigé vers Classe B (Engrais).”
4. Screen: Kanban (Flux NFN)
Update the columns to match the Annex exact routing:
Col 1: En Attente (Collecte)
Col 2: Dépôt D1 (Tri) -> Show tags on the cards: [Classe A] or[Classe B]
Col 3: Lavage D2
Col 4: Transformation -> Split visually into two sub-areas: [D3: Isolants] and [D4: Engrais]



In the world of software and logistics, a Kanban is a visual way to manage a
process. Think of it like a Trello Board.

It’s the perfect way to show the "Flux de Matière" (Flow of Material) that the
judges asked for in the diagram.

How it works:

1.  Columns: Each column represents a Phase of the wool's journey.
2.  Cards: Each card is a Batch (Lot) of wool.
3.  The Flow: As the wool moves physically (from the farm to the warehouse to
    the factory), the card moves horizontally across the screen from one column
    to the next.

Your Kanban Board Structure (The "NFN Flux")

Since you are building the web dashboard, you should create a page with 4
columns side-by-side. Here is what should be in each column:

Column 1: Collecte (Phase 1)

  - What it shows: Wool that has been bought by a collector but hasn't reached
    the warehouse yet.
  - Card Info: Batch ID, Race (e.g., Ouled Djellal), Collector Name.
  - Color: Blue.

Column 2: Dépôt D1 / Stockage (Phase 2)

  - What it shows: Wool currently sitting in the warehouse.
  - Card Info: Weight E1, Zone (e.g., Zone A), and classification (Classe A or
    B).
  - Color: Yellow.

Column 3: Lavage D2 (Phase 3)

  - What it shows: Wool currently being cleaned.
  - Card Info: Water temperature, pH, and the "Yield" (Rendement) progress.
  - Color: Orange.

Column 4: Transformation (Phase 4)

  - What it shows: Clean wool ready for the factory.
  - Card Info: Fiber Length, Micron Density, Humidity.
  - Final Destination: Tagged as "D3 (Textiles)" or "D4 (Engrais)".
  - Color: Green.

🚀 Why this "Wins" the Hackathon for you:

1.  Real-Time Visual Proof: During your pitch, when your friend scans a QR code
    on the mobile app, the card on your web screen should instantly move to the
    next column. This proves your system is "Live."
2.  Identifies Bottlenecks: If you have 50 cards in "Lavage" and 0 in
    "Transformation," a manager can instantly see that the washing facility is
    too slow.
3.  No More "Black Holes": The PDF said it’s hard to know what’s happening at
    each step. The Kanban board makes it impossible to lose a batch.

💻 Tech Tip for the Web Dev:

If you are using React, don't build a complex drag-and-drop system. You don't
have time.

  - Just use a CSS Grid with 4 columns (grid-cols-4).
  - Map through your batches array and use a filter for each column:
      - Col 1: batches.filter(b => b.status === 'EN_ROUTE')
      - Col 2: batches.filter(b => b.status === 'AT_D1_STOCKAGE')
      - ...and so on.

This will look like a professional logistics tool and will be the most
impressive part of your "Flux" presentation!
