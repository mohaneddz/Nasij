![Nasij](screenshots/cover.avif)

<h1 style="font-family: Arial, sans-serif; font-size: 36px; color: #2E8B57; display: flex; align-items: center; gap: 12px; border-bottom: 3px solid #2E8B57; padding-bottom: 8px;">
  <img src="nasij/web/icons/Icon-192.png" alt="Nasij Icon" style="height: 55px; width: 55px; object-fit: contain; border-radius: 8px;">
  NASIJ - Wool Traceability and Operations Monorepo
</h1>


NASIJ is a wool traceability and operations platform built as a multi-surface product:

- a Flutter mobile app for field users and suppliers
- a FastAPI backend for mobile and dashboard workflows
- a React/Vite dashboard for operations and monitoring
- a separate set of AI microservices and data/warehouse assets used for experimentation and supporting workflows

This repository is therefore a monorepo, not a single app.

## Repository Structure

```text
AUP-Viltrumites/
├── nasij/                     # Flutter mobile app + mobile-facing FastAPI backend
│   ├── lib/                  # Flutter UI, cubits, offline storage, services
│   ├── backend/              # FastAPI API for mobile flows
│   └── assets/               # Mobile env and app assets
├── nasij-web/
│   ├── nfn-dashboard/        # React/Vite web dashboard
│   └── nfn-backend/          # FastAPI backend for dashboard/control-tower workflows
├── backend/                  # Standalone AI/ML microservices
├── warehouse/                # SQL + ETL + warehouse demo assets
└── scripts/                  # Utility scripts
```

## Confirmed Tech Stack

The stack below is confirmed from the codebase and dependency manifests currently in the repo.

### Mobile App

Location: `nasij/`

- Framework: Flutter
- Language: Dart
- State management: `flutter_bloc` + `equatable`
- Local persistence: Hive / Hive Flutter
- Connectivity handling: `connectivity_plus`
- Background work: `workmanager`
- HTTP client: `http`
- Config loading: `flutter_dotenv`
- Maps and geo: `flutter_map`, `latlong2`, `geolocator`
- QR / camera tooling: `qr_flutter`, `camera`, `google_mlkit_barcode_scanning`
- Localization: Flutter localizations + app-localized string files in `lib/l10n`

### Mobile Backend

Location: `nasij/backend/`

- Framework: FastAPI
- Language: Python
- ASGI server: Uvicorn
- Validation/config: Pydantic + `pydantic-settings`
- Data/auth backend: Supabase
- Testing: `pytest`, `pytest-asyncio`, `httpx`
- Additional ML/data libs present in requirements: NumPy, Pandas, Pillow, Joblib, scikit-learn

### Web Dashboard

Location: `nasij-web/nfn-dashboard/`

- Framework: React
- Bundler/dev server: Vite
- Routing: `react-router-dom`
- UI libraries: MUI (`@mui/material`, Emotion), Lucide icons
- Charts: `recharts`
- Maps: `leaflet`, `react-leaflet`
- QR rendering: `qrcode.react`
- Styling support: Tailwind CSS v4 and custom CSS/theme files
- Backend connection: Supabase JS client

### Dashboard Backend

Location: `nasij-web/nfn-backend/`

- Framework: FastAPI
- Language: Python
- Data/auth backend: Supabase
- API style: router-based modular REST endpoints

### AI / ML Services

Location: `backend/`

- Framework: FastAPI microservices
- Focus: traceability alerts, photo verification, translation, matching, forecasting, sheep/wool classification, and related ML experiments
- Tooling: scikit-learn, joblib, image-processing utilities, model artifacts

### Data / Warehouse

Location: `warehouse/`

- SQL schema and marts
- ETL/sync scripts in Python
- Local demo and setup blueprints

## Product Surfaces

### 1. NASIJ Mobile App

The mobile app is the operational client for field users. From the codebase, it currently includes:

- role-based flows for supplier and worker modes
- localized UI in English, French, and Arabic
- offline session and queue storage with Hive
- background sync support
- supplier declaration and operations screens
- profile, connectivity, and sync visibility
- QR and map-related user flows

Entry point:

- `nasij/lib/main.dart`

Key implementation areas:

- `nasij/lib/cubits`
- `nasij/lib/screens`
- `nasij/lib/services`
- `nasij/lib/data`

### 2. NASIJ Mobile API

The mobile backend exposes a consolidated FastAPI app with modular routers for:

- auth
- batches
- alerts
- sync
- suppliers
- dashboard
- users
- AI endpoints

Key file:

- `nasij/backend/app/main.py`

This backend uses Supabase for authentication and persistence and includes health endpoints and a lightweight Supabase keepalive task.

### 3. NFN Dashboard

The dashboard is the browser-facing operations interface. It is implemented as a React/Vite app with analytics, mapping, and operational views such as:

- home/dashboard views
- alerts
- certification
- map
- pipeline
- user management
- login/session handling

Relevant paths:

- `nasij-web/nfn-dashboard/src/pages`
- `nasij-web/nfn-dashboard/src/hooks`
- `nasij-web/nfn-dashboard/src/layout`

### 4. NFN Dashboard Backend

The dashboard backend is another FastAPI service with routers for:

- auth
- batches
- alerts
- dashboard
- sync
- users

This suggests the repo currently supports two backend entry points:

- `nasij/backend` for mobile-facing and extended workflows
- `nasij-web/nfn-backend` for dashboard/control-tower workflows

That split is also reflected in project planning notes.

## Code Approach Followed

This repo follows a pragmatic, modular, product-oriented approach rather than a strict single-pattern architecture.

### Monorepo with Domain Separation

The code is grouped by application surface and responsibility:

- mobile app code in `nasij`
- mobile API code in `nasij/backend`
- dashboard frontend and backend in `nasij-web`
- AI services in `backend`
- warehouse/data work in `warehouse`

This makes it easier to evolve product surfaces independently while keeping related assets in one repository.

### Router-Based Backend Design

Both FastAPI backends are organized around routers and schemas instead of one large application file.

Examples:

- `auth.py`
- `batches.py`
- `alerts.py`
- `sync.py`
- `suppliers.py`
- `users.py`
- `dashboard.py`

This approach keeps business concerns separated and makes endpoints easier to test and extend.

### Offline-First Mobile Strategy

The mobile app is clearly designed around unreliable connectivity.

The implementation uses:

- Hive for local persistence
- a sync queue / outbox pattern
- connectivity state tracking
- background sync helpers
- UI fallbacks for offline reads and deferred writes

This is one of the clearest architectural themes in the codebase.

### State-Driven UI with Bloc/Cubit

On the Flutter side, app behavior is coordinated through Cubits rather than putting logic directly into widgets.

That gives the project:

- clearer UI state transitions
- easier session/auth handling
- more isolated sync and connectivity logic
- better maintainability than embedding business logic in screens

### Supabase-Centered Backend Integration

Supabase is used as the main hosted platform layer for:

- authentication
- PostgreSQL persistence
- operational data access
- schema/migration workflows

The project relies on backend-mediated access for sensitive actions instead of pushing privileged logic into the mobile client.

### Incremental / Hybrid Delivery

The repo shows a practical mix of:

- production-facing app code
- planning documentation
- migration SQL
- seeded/demo data
- AI experiments and detached services

So the engineering style here is not "greenfield perfect purity"; it is iterative delivery with working product code, supporting experiments, and documented expansion plans living together.

## Architectural Themes Confirmed in the Code

- Offline-first mobile behavior is a primary requirement.
- Supplier onboarding and approval workflows are important business flows.
- Localization is treated as a first-class concern.
- Backend ownership and authorization are emphasized for operational actions.
- The dashboard and mobile experiences are related but not identical products.
- AI services are kept modular and detachable from the core transactional apps.

## Environment and Configuration Approach

The repository uses environment files in multiple places, with separate responsibility by surface:

- `nasij/assets/.env`
  Purpose: mobile-facing runtime values such as `MOBILE_API_BASE_URL`
- `nasij/backend/.env`
  Purpose: backend secrets/config such as `SUPABASE_URL`, anon key, service role key, port, and CORS
- `nasij-web/nfn-dashboard/.env.example`
  Purpose: dashboard frontend environment template

Recommended practice for this repo:

- keep mobile env files free of backend secrets
- keep backend secrets only in backend env files
- treat Supabase service-role keys as backend-only secrets
- restart the mobile app fully after env changes because Flutter asset env loading happens at startup

## Development Workflow

### Mobile

Typical work happens in:

- `nasij/lib/screens` for UI
- `nasij/lib/cubits` for state
- `nasij/lib/services` for API/service integration
- `nasij/lib/data` for offline storage and sync

### Mobile Backend

Typical work happens in:

- `nasij/backend/app/routers`
- `nasij/backend/app/schemas.py`
- `nasij/backend/app/deps.py`
- `nasij/backend/migrations`
- `nasij/backend/tests`

### Dashboard

Typical work happens in:

- `nasij-web/nfn-dashboard/src/pages`
- `nasij-web/nfn-dashboard/src/hooks`
- `nasij-web/nfn-dashboard/src/components`
- `nasij-web/nfn-dashboard/src/lib`

### AI Services

Typical work happens in:

- individual service folders under `backend/`
- training scripts
- artifact generation
- service-specific app entry points

## Running the Project

Because this is a monorepo, there is no single universal startup command for every surface. Use the relevant app or service directory.

### Mobile App

From `nasij/`:

```bash
flutter pub get
flutter run
```

### Mobile Backend

From `nasij/backend/`:

```bash
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8001
```

Health checks:

```bash
GET /health
GET /api/health
```

### Dashboard Frontend

From `nasij-web/nfn-dashboard/`:

```bash
npm install
npm run dev
```

### Dashboard Backend

From `nasij-web/nfn-backend/`:

```bash
uvicorn app.main:app --reload
```

### AI Services

From `backend/`:

```bash
python run_all.py
```

## Current Observations

The codebase is ambitious and broad. A few practical truths are worth calling out:

- there are multiple active backends, so clear API ownership matters
- some older docs in subfolders are stale or template-level
- the repo contains both production workflow code and experiment/prototype material
- planning documents are unusually important here because they explain intended system boundaries

That is not necessarily a problem, but it does mean contributors should confirm which surface they are changing before they start coding.

## Recommended Contribution Discipline

When extending this project, the safest approach is:

1. Confirm which surface owns the feature: mobile app, mobile backend, dashboard, dashboard backend, AI service, or warehouse.
2. Keep env/config changes scoped to the correct subproject.
3. Put business rules in backend routes/services rather than only in UI logic.
4. Preserve offline-first behavior for mobile changes.
5. Add or update localization keys for user-facing text.
6. Prefer extending existing routers/cubits/services over introducing duplicate flows.

## Useful Paths

- [Mobile app](nasij)
- [Mobile backend](nasij/backend)
- [Dashboard frontend](nasij-web/nfn-dashboard)
- [Dashboard backend](nasij-web/nfn-backend)
- [AI services](backend)
- [Warehouse](warehouse)
- [Implementation plan](<nasij/implementation plan.md>)

## Summary

This project uses:

- Flutter + Bloc + Hive for the mobile client
- FastAPI + Supabase for transactional backend services
- React + Vite + MUI + Leaflet + Recharts for the dashboard
- separate Python AI microservices for model-backed capabilities
- SQL and ETL assets for data/warehouse support

The overall code approach is modular, offline-first on mobile, router-driven on the backend, and pragmatic in delivery. It is designed to support operational workflows in low-connectivity environments while keeping analytics, admin tooling, and ML capabilities in adjacent but separable modules.
