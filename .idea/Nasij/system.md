# System Overview

## Purpose

This repository contains the NASIJ wool traceability platform and its supporting systems. It is organized as a monorepo with multiple application surfaces that work together:

- a Flutter mobile application for field workers and suppliers
- a FastAPI backend that serves mobile workflows
- a React/Vite dashboard for operational and managerial visibility
- a dashboard-oriented FastAPI backend
- a separate family of AI/ML microservices
- SQL and warehouse assets for data modeling and reporting

The system is designed around real-world field constraints, especially intermittent connectivity, role-based operations, and backend-controlled business rules.

## High-Level System Shape

```text
Users
├── Suppliers / field actors
│   └── NASIJ mobile app (Flutter)
│       └── NASIJ mobile backend (FastAPI)
│           └── Supabase (Auth + Postgres)
├── Internal operations users
│   └── NFN dashboard (React/Vite)
│       └── NFN backend (FastAPI)
│           └── Supabase (Auth + Postgres)
└── Supporting analytics / AI workflows
    ├── AI microservices
    └── Warehouse / SQL / ETL assets
```

## Main Subsystems

### 1. Mobile Client

Location: `nasij/`

The mobile client is built with Flutter and Dart. It contains:

- role-based screens for supplier and worker flows
- Cubit/Bloc state management
- offline storage using Hive
- connectivity-aware sync behavior
- localized user-facing strings in English, French, and Arabic
- field tooling such as maps, QR flows, and camera/barcode integration

The mobile client is the primary operational surface for field use.

Key areas:

- `nasij/lib/main.dart`
- `nasij/lib/screens`
- `nasij/lib/cubits`
- `nasij/lib/services`
- `nasij/lib/data`

### 2. Mobile Backend

Location: `nasij/backend/`

The mobile backend is a FastAPI application that aggregates multiple router modules behind `/api`. It is responsible for:

- authentication
- supplier flows
- batches and operations
- alerts and sync endpoints
- user and dashboard-related API support
- some AI-connected endpoints

This backend uses Supabase for authentication and persistence and is structured with modular routers plus shared schemas and dependency helpers.

Key areas:

- `nasij/backend/app/main.py`
- `nasij/backend/app/routers`
- `nasij/backend/app/schemas.py`
- `nasij/backend/app/deps.py`
- `nasij/backend/migrations`

### 3. Dashboard Frontend

Location: `nasij-web/nfn-dashboard/`

The dashboard is a React/Vite web application. It provides internal operations views such as:

- monitoring dashboards
- alerts
- certification and pipeline views
- mapping and geospatial views
- user management
- authentication/session handling

The frontend uses MUI, React Router, Recharts, and Leaflet-related packages.

### 4. Dashboard Backend

Location: `nasij-web/nfn-backend/`

This is a separate FastAPI service that supports the dashboard/control-tower side of the platform. It has its own router structure and Supabase integration. In practice, this means the repository currently contains two backend entry points:

- `nasij/backend`
- `nasij-web/nfn-backend`

That split should be treated as intentional unless future consolidation is planned explicitly.

### 5. AI / ML Services

Location: `backend/`

This folder contains detachable FastAPI-based AI services and training assets. They cover domains such as:

- traceability alerts
- photo verification
- translation
- matching/recommendation
- forecasting
- breed and wool classification

These services are adjacent to the transactional platform, not the main source of truth for core business flows.

### 6. Warehouse and Data Assets

Location: `warehouse/`

This part of the repo contains:

- SQL schema setup
- marts and demo queries
- ETL/sync scripts
- warehouse setup and recommendation documents

Its role is data organization, reporting, and local warehouse experimentation rather than day-to-day transactional serving.

## Confirmed Technology Stack

### Mobile

- Flutter
- Dart
- flutter_bloc / Cubit
- Hive / hive_flutter
- connectivity_plus
- flutter_dotenv
- http
- workmanager
- flutter_map
- geolocator
- qr_flutter
- camera
- google_mlkit_barcode_scanning

### Backend

- Python
- FastAPI
- Uvicorn
- Pydantic
- pydantic-settings
- Supabase Python client
- pytest / pytest-asyncio / httpx

### Dashboard

- React
- Vite
- React Router
- MUI + Emotion
- Recharts
- Leaflet / React Leaflet
- Supabase JS
- Tailwind CSS support

### Data / ML

- SQL
- Python ETL scripts
- NumPy
- Pandas
- Pillow
- Joblib
- scikit-learn

## Architectural Principles Reflected in the Code

### Monorepo by Surface

The code is grouped by product surface instead of forcing everything into one app. That keeps mobile, dashboard, backend, AI, and warehouse work separable while still versioning them together.

### Router-Driven API Design

Both FastAPI backends organize responsibilities by router modules such as:

- `auth`
- `batches`
- `alerts`
- `sync`
- `suppliers`
- `users`
- `dashboard`

This approach keeps route concerns modular and makes ownership clearer than a single large API module.

### Offline-First Mobile Behavior

Offline capability is a core system concern, not an afterthought. The mobile app uses:

- local session storage
- offline action queues
- explicit connectivity tracking
- background sync behavior
- fallback UI messaging when the network is unavailable

This means backend APIs must be designed to tolerate delayed writes, retries, and reconnect-driven synchronization.

### Backend-Owned Business Rules

Sensitive business rules should remain backend-authoritative. The system direction in the repo emphasizes:

- approval status checks on the backend
- identity and ownership validation on the backend
- trust score and operational status updates on the backend
- protected secrets kept out of the mobile client

### Localization as a First-Class Requirement

The mobile codebase maintains localized strings for `en`, `fr`, and `ar`. New user-facing features should preserve that standard.

## Data and Auth Backbone

Supabase is the main platform dependency across the transactional system. It is used for:

- authentication
- Postgres-backed persistence
- application data access
- schema and migration workflows

The repository also includes SQL migration files and schema alignment scripts, which indicates that database shape is part of the normal development workflow.

## Configuration Model

Configuration is split by application surface.

### Mobile Runtime Config

File:

- `nasij/assets/.env`

Intended for mobile-safe values such as:

- `MOBILE_API_BASE_URL`

This file should not contain backend-only secrets.

### Mobile Backend Config

File:

- `nasij/backend/.env`

Intended for backend values such as:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `PORT`
- `CORS_ORIGINS`

### Dashboard Config

Files/templates:

- `nasij-web/nfn-dashboard/.env.example`
- dashboard/backend env files as needed

## Operational Boundaries

### What the Mobile App Owns

- UI state transitions
- local persistence and caching
- offline queueing
- field interaction workflows
- localized presentation

### What the Backend Owns

- auth validation
- record ownership checks
- durable writes
- approval status and trust/business rules
- data synchronization contracts

### What the Dashboard Owns

- internal visibility
- operational review workflows
- management surfaces
- approval and monitoring support

### What AI Services Own

- prediction and inference capabilities
- optional intelligence features
- model-backed assistance outside the transactional core

## Current System Reality

A few things are important for contributors to understand:

- this is not a small single-app repo
- there are parallel backend surfaces
- some parts are mature product code, while others are exploratory or planning-heavy
- documentation inside subfolders is uneven; some files are detailed and current, while some are stale templates

That means changes should start with one question: which subsystem actually owns this feature?

## Recommended Engineering Rules

1. Keep mobile env, backend env, and dashboard env responsibilities separate.
2. Avoid leaking backend secrets into mobile assets.
3. Preserve offline-first assumptions in mobile changes.
4. Put sensitive business logic in backend code, not only in UI code.
5. Keep new APIs modular by extending existing routers or adding clearly owned ones.
6. Maintain localization coverage for user-facing features.
7. Treat the AI services as supporting modules, not the transactional source of truth.

## Primary Entry Points

- Mobile app: `nasij/lib/main.dart`
- Mobile backend: `nasij/backend/app/main.py`
- Dashboard frontend: `nasij-web/nfn-dashboard/src/main.jsx`
- Dashboard backend: `nasij-web/nfn-backend/app/main.py`
- AI services launcher: `backend/run_all.py`

## Summary

The system is a multi-surface, offline-aware, Supabase-backed platform for wool traceability and operations. Its strongest architectural themes are:

- modular application boundaries
- offline-first mobile design
- router-based FastAPI services
- backend-owned business rules
- adjacent but separable dashboard, AI, and warehouse capabilities

Any future work should preserve those system boundaries unless the team intentionally decides to consolidate them.
