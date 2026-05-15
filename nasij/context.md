during each intermediary step, scan QR the weigh to validate, if discrepancies are found signal an Alert and continue the workflow with the new weight
roles
farmer (c1), enter number of sheep, call shearer/collector
butcher, calls collectors to take skin + wool or just wool, skin has a time limit before it rots
third-parties, calls collectors to take wool
shearer/collector, view sheering orders, sheer sheep, collect wool and index them using QR (get all wool information and skin information if available)
depot workers, receive wool, perform manual cleaning, if skin-on remove skin and give to external destinations, weigh wool after and validate consistency (need to be close before and after, if not flag A1)
washers, perform intensive cleaning on the wool, weigh after washing, classification of results to 2 classes: D3 and D4
transformers, detail the metrics about the result of the transformation into D3 or D4 products, inputs metrics like density, fiber length, weight, quantity...

list of all screens:
Here is a fully exhaustive list of screens and the navigation flow for the
mobile application.

The app is built on a Role-Based Access Control (RBAC) architecture. After
logging in, the user is automatically routed to their specific interface.

🚪 1. Shared / Global Screens (All Users)

  - Splash Screen: App logo and loading animation.
  - Login Screen: Username/Password, "Forgot Password", and Role
    selection/verification.
  - Profile & Settings Screen: Manage account details, language
    (French/Arabic/English), Bluetooth printer pairing (for QR codes), and
    logout.
  - Notifications Center (Bell Icon): Real-time alerts (e.g., "Collector
    assigned," "Urgent Butcher pickup," "Discrepancy noted").

🌾 2. Source Nodes (Farmer, Butcher, Third-Party)

Navigation: Bottom Bar (Home | New Request | History)

  - Home Dashboard (My Requests):
      - List of active requests grouped by status: Pending, Collector En Route,
        Completed.
      - Urgency Tracker (Butcher Only): A visual countdown timer (in red) for
        active "Skin-On" requests.
  - New Request Flow:
      - Request Type Selection (Butcher Only): Toggle between "Wool Only" or
        "Skin + Wool" (triggers the timer).
      - Details Form (Farmer): Input field for "Number of Sheep".
      - Details Form (Butcher/Third-Party): Input field for "Estimated
        Volume/Weight" and "Number of Bags".
      - Location Screen: GPS pin drop for collection site.
      - Summary & Submit Modal: Confirm details and "Call Collector".
  - Request Details Screen: View assigned Collector's name, vehicle details,
    ETA, and live status.
  - History Screen: Log of past collections and total metrics (e.g., "Total
    sheep sheared this year").

🛻 3. Collector & Shearer Interface

Navigation: Bottom Bar (Map | List | My Loads | History)

  - Map & Radar Screen: Interactive map showing nearby collection requests. Red
    pulsing pins indicate urgent Butcher "Skin-on" requests.
  - Order List Screen: List view of the map. Sorted automatically by priority
    (Butchers with timers first) and distance.
  - Order Detail & Navigation Screen:
      - Customer details, contact button, and "Navigate via Maps" button.
      - "Arrived & Start Job" button.
  - Collection & Indexing Flow (The core data entry):
      - Step 1: Gross Weight Form: Input actual weight from portable scale,
        input number of bags.
      - Step 2: Quality Checklist: Star rating (1-5) for cleanliness. Dropdowns
        for Wool Type (Fleece, Pieces, Tail). Date picker for "Last Parasite
        Treatment".
      - Step 3: Skin Details (Conditional): If the order is "Skin-On", fields
        appear for "Skin Humidity %" and "Skin Condition Notes".
      - Step 4: QR Generation Screen: Review summary -> Tap "Generate QR" ->
        Connects to Bluetooth printer to print the Lot/Bag Tags.
  - My Loads (Transit View): Shows current inventory in the truck. Button to
    "Complete Drop-off" which readies the QR codes for the Depot worker to scan.

🏭 4. Depot Worker (D1) Interface

Navigation: Bottom Bar (Intake | Processing | Inventory | Dispatch)


- Intake Flow (Scan & Reconcile):
      - QR Scanner Screen: Camera opens to scan Collector's QR.
      - Reconciliation Form: Shows Collector's declared weight. Field to input
        the Depot's Actual Weight.
      - System Alert Modal (Invisible to worker if OK, pops up as "Logged" if
        discrepancy): App calculates difference -> If out of bounds, sends Alert
        A1 to dashboard, updates to new weight -> "Intake Successful".
  - Processing Board (Kanban-style):
      - List of intake lots waiting to be cleaned.
      - Manual Cleaning Form: Select lot -> Tap "Start Cleaning" -> Input
        estimated waste removed (straw/dirt).
  - Skin Routing Screen (Conditional):
      - If lot has skin: Button to "Separate Skin".
      - Input weight of isolated skin -> Generates "External Tannery Dispatch
        QR".
  - Consistency Audit (A1) Screen:
      - After cleaning/skin removal, worker inputs the Post-Cleaned Weight of
        the wool.
      - Background Check: App checks if the yield drop is mathematically sound.
        (If fraud/loss is suspected, flags Alert A1). -> Generates new "Depot
        Cleaned QR".
  - Inventory & Dispatch Screen: View all cleaned lots. Select multiple lots ->
    "Create Outbound Shipment" -> Generates a consolidated Transit QR for the
    Washer.

🌊 5. Washer (D2) Interface

Navigation: Bottom Bar (Intake | Wash Queue | Classification | Finished Bales)

  - Intake Flow:
      - QR Scanner: Scan incoming Depot QR.
      - Pre-Wash Weight Form: Input scale weight. (Discrepancy check runs
        automatically).
  - Wash Process Log Screen:
      - Select lot -> "Start Wash".
      - Input form: Water temp, detergent type, batch duration.
  - Post-Wash & True Yield Screen:
      - Worker inputs the Net Dry Weight.
      - App automatically displays Yield % (e.g., "Yield: 52%").
  - Classification & Routing Screen:
      - Worker evaluates the clean wool and divides it.
      - Sliders/Input fields: Split total dry weight into Class D3 (Quality) and
        Class D4 (Fertilizer/Low grade).
      - Tap "Finalize Classification".
  - QR Generation Screen: App prints separate, distinct QR codes for D3 batches
    and D4 batches.

⚙️ 6. Transformer (D3 & D4 Factory) Interface

Navigation: Bottom Bar (Intake | Production | Finished Goods)

  - Intake Flow:
      - QR Scanner: Scan Washer's D3 or D4 QR.
      - Factory Intake Weight: Input weight. (Discrepancy check runs
        automatically).
  - Production Setup Screen:
      - Select available lot from inventory.
      - Product Selector:
          - If D3: Dropdown shows Insulation Panels, Geotextiles, Acoustic
            Rolls.
          - If D4: Dropdown shows Bio-fertilizer Pellets, Agricultural Mats.
  - Manufacturing Metrics Form:
      - Input fields for final product specs:
          - Target Density (kg/m³)
          - Fiber Length Average (mm)
          - Total Units Produced (e.g., 200 panels)
          - Total Finished Weight
  - Final Certification Screen:
      - Review all metrics.
      - Tap "Seal & Certify".
      - Commercial QR Generation: App generates the ultimate "NFN Certified" QR
        codes to be stickered onto the consumer packaging, containing the full
        traceable history from farm to factory.
  - Finished Goods Inventory: List of all produced, tagged, and market-ready
    products.


    - Intake Flow (Scan & Reconcile):
      - QR Scanner Screen: Camera opens to scan Collector's QR.
      - Reconciliation Form: Shows Collector's declared weight. Field to input
        the Depot's Actual Weight.
      - System Alert Modal (Invisible to worker if OK, pops up as "Logged" if
        discrepancy): App calculates difference -> If out of bounds, sends Alert
        A1 to dashboard, updates to new weight -> "Intake Successful".
  - Processing Board (Kanban-style):
      - List of intake lots waiting to be cleaned.
      - Manual Cleaning Form: Select lot -> Tap "Start Cleaning" -> Input
        estimated waste removed (straw/dirt).
  - Skin Routing Screen (Conditional):
      - If lot has skin: Button to "Separate Skin".
      - Input weight of isolated skin -> Generates "External Tannery Dispatch
        QR".
  - Consistency Audit (A1) Screen:
      - After cleaning/skin removal, worker inputs the Post-Cleaned Weight of
        the wool.
      - Background Check: App checks if the yield drop is mathematically sound.
        (If fraud/loss is suspected, flags Alert A1). -> Generates new "Depot
        Cleaned QR".
  - Inventory & Dispatch Screen: View all cleaned lots. Select multiple lots ->
    "Create Outbound Shipment" -> Generates a consolidated Transit QR for the
    Washer.

🌊 5. Washer (D2) Interface

Navigation: Bottom Bar (Intake | Wash Queue | Classification | Finished Bales)

  - Intake Flow:
      - QR Scanner: Scan incoming Depot QR.
      - Pre-Wash Weight Form: Input scale weight. (Discrepancy check runs
        automatically).
  - Wash Process Log Screen:
      - Select lot -> "Start Wash".
      - Input form: Water temp, detergent type, batch duration.
  - Post-Wash & True Yield Screen:
      - Worker inputs the Net Dry Weight.
      - App automatically displays Yield % (e.g., "Yield: 52%").
  - Classification & Routing Screen:
      - Worker evaluates the clean wool and divides it.
      - Sliders/Input fields: Split total dry weight into Class D3 (Quality) and
        Class D4 (Fertilizer/Low grade).
      - Tap "Finalize Classification".
  - QR Generation Screen: App prints separate, distinct QR codes for D3 batches
    and D4 batches.

⚙️ 6. Transformer (D3 & D4 Factory) Interface

Navigation: Bottom Bar (Intake | Production | Finished Goods)

  - Intake Flow:
      - QR Scanner: Scan Washer's D3 or D4 QR.
      - Factory Intake Weight: Input weight. (Discrepancy check runs
        automatically).
  - Production Setup Screen:
      - Select available lot from inventory.
      - Product Selector:
          - If D3: Dropdown shows Insulation Panels, Geotextiles, Acoustic
            Rolls.
          - If D4: Dropdown shows Bio-fertilizer Pellets, Agricultural Mats.
  - Manufacturing Metrics Form:
      - Input fields for final product specs:
          - Target Density (kg/m³)
          - Fiber Length Average (mm)
          - Total Units Produced (e.g., 200 panels)
          - Total Finished Weight
  - Final Certification Screen:
      - Review all metrics.
      - Tap "Seal & Certify".
      - Commercial QR Generation: App generates the ultimate "NFN Certified" QR
        codes to be stickered onto the consumer packaging, containing the full
        traceable history from farm to factory.
  - Finished Goods Inventory: List of all produced, tagged, and market-ready
    products.