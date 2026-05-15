## Document Control
- Project name: NASIJ Mobile Auth + Supplier Flow Integration
- Artifact type: Mobile app + API service + web dashboard workflow integration
- Target runtime/platform: Flutter (Android/iOS), FastAPI (Python 3.11), Supabase (Auth + Postgres), React dashboard (Vite)
- Primary language/stack: Dart/Flutter + Bloc + Hive, Python/FastAPI, PostgreSQL/Supabase, JavaScript/React
- Version: 1.0 planning baseline
- Date: 2026-04-24
- Planning assumptions flagged for review:
  - A1 (Needs clarification): `nasij/backend` is the canonical API for mobile integration; `nasij-web/nfn-backend` is used for dashboard workflows.
  - A2 (Needs clarification): Supplier phone+OTP flow applies only to supplier mode; worker mode remains email/password.
  - A3 (Needs clarification): Trust-score penalty default for cancelling an assigned operation is `-10` (clamped to `[0, 100]`) until product confirms.

## 1. Vision and Outcome
Build a production-ready integration between the NASIJ mobile frontend and backend for supplier authentication and supplier operations so that suppliers can declare wool, track only their own operations, work offline-first, and be manually approved through the dashboard before full activation. This matters because the current flow is mostly UI-mocked, while the business requires controlled onboarding, auditability, and robust sync behavior under unreliable connectivity.

1. Supplier enters phone number, passes format validation, and requests OTP.
2. Supplier enters any 6-digit code (fake OTP for V1), then system checks supplier onboarding status.
3. If supplier is new/unapproved, auth form transitions to a verification-wait state and blocks operational access.
4. If supplier is approved, supplier lands on role-specific home and submits declaration (count/weight + optional auto-location).
5. Supplier sees only own active operations, can cancel pending directly, and can cancel assigned only after call-confirm dialog with collector contact.
6. Supplier profile displays identity, connectivity, offline queue, trust score (/100), manual sync trigger, and logout.

## 2. Scope
### In Scope (V1)
- Two-step supplier auth UI in mobile app: phone entry, fake OTP entry (6 boxes), resend timer (60s), and smooth state transitions.
- Backend contract for fake OTP request/verify with supplier approval-state response (`PENDING_APPROVAL` vs `APPROVED`).
- Manual supplier validation workflow in dashboard (list pending suppliers, approve/reject, audit metadata, and timestamped action).
- Supplier declaration creation linked to backend and stored offline-first when network is unavailable.
- Optional location capture during declaration with graceful fallback if denied/unavailable.
- Supplier operations list filtered to current supplier only, with cancel logic for `PENDING` and `ASSIGNED`.
- Assigned-operation cancellation modal with collector phone display and call action.
- Trust score model in backend + mobile profile display, updated on assigned cancellation.
- Offline-first outbox sync enhancements including background sync attempt when app is closed (best effort per OS constraints).
- Full localization for every new UI string in `en/fr/ar`; no hardcoded new user-facing text.
- API/client error handling, structured logging, and test coverage for new auth and supplier flows.

### Out of Scope (V1)
- Real SMS OTP provider integration (deferred because free-tier limitation; fake OTP accepted in V1).
- Advanced fraud/ML trust scoring (deferred; V1 uses deterministic penalty rules).
- Automatic collector assignment optimization (routing/dispatch intelligence deferred).
- Push notifications and call-center workflow automation (manual process remains in V1).
- Web dashboard redesign beyond required supplier-approval views/actions (scope containment).

## 3. Quality Bar and Success Criteria
- **Functional Success**
  - Supplier auth supports phone -> OTP -> status gate path with zero hardcoded bypasses.
  - New supplier cannot access supplier pages until backend status is `APPROVED`.
  - Declaration persists locally offline and syncs without data loss on reconnect.
  - Operations list shows only current supplier records (no cross-user leakage).
  - Assigned cancellation updates operation status and trust score atomically.
- **Security Success**
  - `SUPABASE_SERVICE_ROLE_KEY` never exposed in Flutter client.
  - All supplier-scoped read/write routes validate identity and ownership.
  - OTP endpoints are rate-limited and abuse-auditable even if OTP is fake.
  - Cancellation/trust updates are server-authoritative (not client-calculated).
- **Performance Success**
  - Auth step transitions respond in <300 ms (excluding network).
  - Supplier home and operations list initial render in <1.5 s on mid-tier devices.
  - Sync flush processes at least 50 queued actions per minute on stable 4G/Wi-Fi.
- **Operability Success**
  - Migrations are idempotent and reversible for new columns/tables.
  - CI executes deterministic unit/integration tests for auth + supplier workflows.
  - Retry/backoff and dead-letter behavior are observable via logs/metrics.
- **UX/DX Success**
  - All new strings are localized in `app_en.dart`, `app_fr.dart`, `app_ar.dart`.
  - Auth and pending-approval transitions are animated and non-jarring.
  - Developer setup requires one documented `.env` + one command to run backend and app.

## 4. Target Architecture
### 4.1 Core Components
1. Mobile Auth State Machine (`lib/screens/auth_screen.dart`, `lib/cubits/auth_cubit.dart`)
   - Owns supplier phone->OTP->approval waiting UX and preserves worker flow isolation. It handles timer state, OTP box input orchestration, and transient UI states with smooth transitions. It should never decide approval on-device; it delegates to backend response.
2. Mobile API/Repository Layer (new `lib/services` and `lib/repositories`)
   - Provides typed calls for auth, supplier declarations, operations, cancellations, and profile/trust fetch. It centralizes retry, timeout, and error mapping so UI remains thin and testable. It also normalizes backend DTOs into app models.
3. Mobile Offline Outbox + Background Sync (`lib/data/offline_storage.dart`, `lib/cubits/sync_cubit.dart`, new background worker adapter)
   - Stores unsynced writes and flushes on reconnect, app resume, periodic foreground checks, and OS-permitted background windows. It enforces idempotency keys and retry policy. It must preserve action order for same-operation mutations.
4. FastAPI Auth + Supplier Domain API (`backend/app/routers/auth.py`, new supplier router/service modules)
   - Exposes fake OTP request/verify, supplier approval status checks, declaration endpoints, operation listing, and cancellation with trust updates. It enforces ownership and business rules server-side. It remains the only component writing trust score and approval status.
5. Supabase Persistence Layer (new SQL migrations + `users`/operations schema updates)
   - Stores supplier approval state, trust score, declarations/operations, assignment metadata, and audit columns. It supports offline idempotent upserts and supplier-scoped queries. It is indexed for hot paths (pending approvals, supplier operations, status filters).
6. Web Dashboard Validation Module (`nasij-web/nfn-dashboard` + `nasij-web/nfn-backend`)
   - Lets managers review pending suppliers and approve/reject with audit info. It provides explicit visibility into supplier onboarding status transitions. It must avoid direct DB writes from browser; actions go through backend API.

### 4.2 Proposed Folder/Module Structure
```text
nasij/
  lib/
    cubits/
      auth_cubit.dart
      sync_cubit.dart
    data/
      offline_storage.dart
      hive_boxes.dart
      sync_action.dart
    models/
      operation.dart
      supplier_profile.dart              # new
      supplier_declaration.dart          # new
    repositories/
      auth_repository.dart               # new
      supplier_repository.dart           # new
      sync_repository.dart               # new
    services/
      api_client.dart                    # new
      auth_api_service.dart              # new
      supplier_api_service.dart          # new
      background_sync_service.dart       # new
    screens/
      auth_screen.dart
      supplier_dashboard_screen.dart
      supplier_operations_screen.dart
      profile_screen.dart
    l10n/
      app_en.dart
      app_fr.dart
      app_ar.dart
  backend/
    app/
      routers/
        auth.py
        suppliers.py                     # new
        operations.py                    # new
        sync.py
      services/
        auth_service.py                  # new
        supplier_service.py              # new
        trust_score_service.py           # new
      schemas.py
      deps.py
      main.py
    migrations/
      006_supplier_approval_and_trust.sql # new
      007_supplier_operations.sql          # new
    tests/
      test_auth.py
      test_supplier_flow.py              # new
      test_operations.py                 # new
      test_sync.py

nasij-web/
  nfn-backend/
    app/
      routers/
        suppliers.py                     # new
  nfn-dashboard/
    src/
      pages/
        SupplierApprovalsPage.jsx        # new
      hooks/
        useSupplierApprovals.js          # new
```

## 5. Phase Plan
### Phase 0 — Requirements and Risk Baseline
**Goals** — Lock business rules, API ownership boundaries, and non-negotiable constraints before implementation. Remove ambiguity in approval flow, trust score policy, and offline sync behavior.
**Work Packages**
1. Confirm canonical backend ownership (`nasij/backend` vs `nasij-web/nfn-backend`) for mobile-facing supplier endpoints.
2. Finalize supplier lifecycle states (`NEW`, `PENDING_APPROVAL`, `APPROVED`, `REJECTED`) and transition rules.
3. Define trust score policy: penalties, floor/ceiling, and optional recovery rules.
4. Define operation status model and cancellation semantics for pending vs assigned.
5. Freeze OTP UX behavior: input length, resend lock, rate limits, and fake validation rule.
**Deliverables**
- Signed requirements decision log (`docs/decisions/supplier-auth-v1.md`).
- State transition diagram for auth and operation lifecycle.
- API boundary map (which repo owns which endpoint).
**Exit Criteria**
- All blocking product decisions resolved and documented.
- No unresolved "TBD" items in auth/operations state model.
**References** — R1, R2, R3, R4

### Phase 1 — Data Model and API Contract
**Goals** — Introduce schema and endpoint contracts required for supplier approval, declarations, operations, and trust scoring. Ensure contracts are explicit and versionable before UI integration.
**Work Packages**
1. Add migration for `users` fields: `approval_status`, `approval_requested_at`, `approved_at`, `approved_by`, `trust_score`.
2. Add migration for supplier declarations/operations (or extend `batches`) with supplier ownership, assignment metadata, and cancel reason fields.
3. Define request/response schemas for:
   - `POST /api/auth/supplier/request-otp`
   - `POST /api/auth/supplier/verify-otp`
   - `GET /api/suppliers/me`
   - `POST /api/suppliers/declarations`
   - `GET /api/suppliers/operations`
   - `POST /api/suppliers/operations/{id}/cancel`
4. Add dashboard admin endpoints:
   - `GET /api/suppliers/pending`
   - `POST /api/suppliers/{id}/approve`
   - `POST /api/suppliers/{id}/reject`
5. Add API contract tests and ownership checks.
**Deliverables**
- SQL migrations + updated schema docs.
- OpenAPI-documented endpoint contracts.
- Backend tests for schema validations and authorization paths.
**Exit Criteria**
- Migrations run cleanly on fresh and existing DB.
- API tests pass for happy path and rejection path.
- Contract approved by mobile + dashboard teams.
**References** — R2, R5, R6

### Phase 2 — Mobile Supplier Authentication Flow
**Goals** — Replace direct supplier login with phone+OTP state machine and pending-approval gate in mobile auth UI. Preserve existing worker auth flow.
**Work Packages**
1. Refactor supplier auth into multi-step state (`phoneEntry`, `otpEntry`, `pendingApproval`, `authenticated`).
2. Implement 6-box OTP UI with paste support, focus auto-advance, and backspace navigation.
3. Implement resend timer button (disabled for 60s, reset behavior on resend).
4. Call `request-otp` after validated phone; call `verify-otp` on continue from OTP step.
5. Implement smooth animated transition from auth form to pending-verification message.
6. Persist minimal session/profile in Hive on success and restore at startup.
7. Add localization keys for all new auth strings in all three locales.
**Deliverables**
- Updated `auth_screen.dart` and `auth_cubit.dart` flow logic.
- New auth service/repository classes with unit tests.
- Localized string additions (`app_en.dart`, `app_fr.dart`, `app_ar.dart`).
**Exit Criteria**
- Supplier cannot reach supplier routes unless backend returns approved state.
- OTP UI works with timer and no hardcoded text.
- Worker login flow unaffected and tested.
**References** — R1, R3, R7

### Phase 3 — Dashboard Manual Supplier Validation
**Goals** — Provide manager-facing tooling to validate newly registered suppliers and update onboarding status. Close the loop between mobile pending state and business approval.
**Work Packages**
1. Add supplier approval list endpoint with filters (`pending`, `approved`, `rejected`, `wilaya`, `sector`).
2. Build dashboard page/table for pending suppliers with approve/reject actions and notes.
3. Implement API guards for manager-only actions.
4. Add action audit fields (`approved_by`, `approval_note`, timestamps).
5. Expose status badge and detail drawer for supplier record history.
**Deliverables**
- New dashboard page + hook + API wiring.
- Backend approval endpoints + tests.
- Audit trail query/report support.
**Exit Criteria**
- Manager can approve/reject supplier and changes are visible to mobile on next verification request.
- All approval actions are auditable.
**References** — R4, R5, R8

### Phase 4 — Supplier Home, Operations, and Trust Score
**Goals** — Connect supplier home and operations screens to real backend data, including declaration creation, ownership filtering, and cancellation policies affecting trust score.
**Work Packages**
1. Implement declaration submission from supplier home (count/weight based on role) with optional geolocation capture and graceful fallback.
2. Replace mock operations list with `GET /suppliers/operations` and pagination/filtering.
3. Add cancel action for pending operations (confirmation + immediate UI update).
4. Add assigned-cancel flow:
   - confirmation popup with collector phone and call button
   - cancel action invocation
   - trust score update readback
5. Add trust score card (`/100`) on supplier profile and explain penalty reason.
6. Localize all new operation/cancellation/trust strings.
**Deliverables**
- Updated supplier home/operations/profile screens bound to repositories.
- New operation modal and phone call integration.
- Backend trust update logic + operation status transitions.
**Exit Criteria**
- Supplier sees only own operations.
- Assigned cancellation enforces popup + triggers trust score reduction.
- Profile displays current trust score and sync-related state.
**References** — R1, R3, R6, R9

### Phase 5 — Offline-First and Background Sync Reliability
**Goals** — Make declaration and cancellation writes resilient offline and auto-synced on reconnect, app resume, and OS background opportunities.
**Work Packages**
1. Extend sync queue payload types for supplier declarations and cancellations with idempotency IDs.
2. Add deterministic replay order and conflict handling policy (last-write-wins per action timestamp unless explicit server rule).
3. Implement background sync adapter:
   - Android periodic work request
   - iOS background fetch/BGTask best effort
4. Add connectivity-aware immediate flush and exponential backoff retry.
5. Add observability: sync attempts, failures, next retry, queue depth.
6. Ensure profile sync section shows offline count and manual sync action.
**Deliverables**
- Updated `offline_storage.dart` schema and migration logic.
- Background worker integration + platform config.
- Sync reliability tests and manual QA checklist.
**Exit Criteria**
- Offline actions survive app restarts and sync automatically when connectivity returns.
- No duplicate server records from repeated retries.
- Sync status is visible and actionable from profile.
**References** — R10, R11, R12

### Phase 6 — Localization, UX Polish, and Validation
**Goals** — Raise UX quality and translation completeness while validating edge cases end-to-end. Ensure no hardcoded newly introduced user-facing text.
**Work Packages**
1. Complete translation keys for all new texts and run missing-key checks.
2. Polish transitions for auth step changes and pending-approval state.
3. Add form validation and error-state UX for phone, OTP, and declaration fields.
4. Add integration tests for critical supplier journeys:
   - new supplier pending
   - approved supplier declaration
   - cancel assigned + trust reduction
   - offline enqueue + reconnect sync
5. Add dashboard-to-mobile approval propagation test.
**Deliverables**
- Updated localization files and localization test report.
- UX polish commit set with animation consistency.
- E2E test checklist and pass report.
**Exit Criteria**
- No missing translation keys for new features.
- Critical journeys pass on Android and iOS test devices.
- Pending/approved behavior matches business rules.
**References** — R1, R3, R10

### Phase 7 — Packaging, Release, and Operational Readiness
**Goals** — Prepare release candidate with operational controls, rollout strategy, and support playbook. Finalize governance artifacts for stable production handoff.
**Work Packages**
1. Freeze API contracts and publish changelog/migration notes.
2. Run full CI test matrix and perform regression sweep for supplier and worker paths.
3. Configure runtime monitoring dashboards for auth failures, approval queue, sync failures, and cancellation rates.
4. Prepare rollback strategy for migrations and feature flags.
5. Execute staged rollout and collect post-release metrics.
**Deliverables**
- Release checklist and go/no-go signoff.
- Production runbook with alert thresholds.
- Post-release monitoring dashboard and escalation policy.
**Exit Criteria**
- Release candidate passes all required checks.
- Rollback and incident response procedures are validated.
- Stakeholders approve production launch.
**References** — R2, R6, R13

## 6. Security Plan (Cross-Cutting)
### 6.1 Threat Model Checklist
- Unauthorized supplier reading/updating another supplier operations.
- Client-side trust score tampering via modified app payloads.
- Fake OTP endpoint abuse (enumeration, brute-force request storms).
- Service-role key leakage into mobile or dashboard client bundles.
- Replay or duplicate submission attacks from offline queue retries.
- Approval endpoint misuse by non-manager users.

### 6.2 Mandatory Controls
1. Enforce supplier ownership checks on every supplier-scoped endpoint.
2. Restrict approval endpoints to manager role with server-side authorization.
3. Keep trust-score mutation server-only; reject client-supplied trust values.
4. Add idempotency token validation for mutation endpoints.
5. Add rate limits for OTP request/verify and cancellation actions.
6. Store service-role credentials only in backend env/secrets manager.
7. Log security-relevant events (approval changes, repeated OTP requests, repeated cancellation abuse).

### 6.3 Security Testing Controls
- Unit tests for auth/authorization guards and trust update paths.
- Integration tests for role-based access (`supplier` vs `manager`).
- Dependency vulnerability scans in CI for Flutter and Python packages.
- Static analysis (`flutter analyze`, `ruff`/`bandit` equivalent for backend).
- Manual penetration checklist for IDOR, replay, and rate-limit bypass.

## 7. Performance Plan (Cross-Cutting)
### 7.1 Key Levers
- Payload size and number of round-trips in auth and operations screens.
- Database indexing on supplier ID, status, and approval status.
- Offline queue batch size and retry cadence.
- Geolocation timeout behavior to avoid declaration flow blocking.
- Background sync frequency and OS scheduling constraints.

### 7.2 Recommended Defaults
- `AUTH_OTP_LENGTH = 6` — aligns with requested UX and common OTP affordance.
- `AUTH_RESEND_SECONDS = 60` — requested behavior with anti-spam baseline.
- `AUTH_REQUEST_TIMEOUT_MS = 10000` — prevents long UI hangs on weak networks.
- `SYNC_BATCH_SIZE = 50` — balances throughput and retry impact.
- `SYNC_MAX_RETRIES = 5` — limits infinite retry loops while preserving resilience.
- `SYNC_FOREGROUND_INTERVAL_SECONDS = 120` — aligns with current periodic sync cadence.
- `GEOLOCATION_TIMEOUT_SECONDS = 8` — captures location opportunistically without blocking declaration.
- `TRUST_SCORE_CANCEL_ASSIGNED_PENALTY = 10` (Needs clarification) — initial policy placeholder.

### 7.3 Runtime Safeguards
- Request timeouts with user-visible retry affordance.
- Exponential backoff for sync retries with jitter.
- Idempotency keys on create/cancel endpoints to prevent duplicates.
- Graceful degradation when location unavailable (continue without GPS).
- Queue caps and dead-letter marker when retries exceed threshold.

## 8. Configuration Surface
### 8.1 Non-Secret Settings
- `MOBILE_API_BASE_URL` — `string` — default `http://10.0.2.2:8001/api`
- `AUTH_OTP_LENGTH` — `int` — default `6`
- `AUTH_RESEND_SECONDS` — `int` — default `60`
- `AUTH_REQUEST_TIMEOUT_MS` — `int` — default `10000`
- `SYNC_FOREGROUND_INTERVAL_SECONDS` — `int` — default `120`
- `SYNC_BACKGROUND_INTERVAL_MINUTES_ANDROID` — `int` — default `15`
- `SYNC_BACKGROUND_INTERVAL_MINUTES_IOS` — `int` — default `15` (best-effort scheduling)
- `SYNC_BATCH_SIZE` — `int` — default `50`
- `SYNC_MAX_RETRIES` — `int` — default `5`
- `GEOLOCATION_TIMEOUT_SECONDS` — `int` — default `8`
- `TRUST_SCORE_CANCEL_ASSIGNED_PENALTY` — `int` — default `10` (Needs clarification)
- `TRUST_SCORE_MIN` — `int` — default `0`
- `TRUST_SCORE_MAX` — `int` — default `100`

### 8.2 Secret / Credential Storage
- `SUPABASE_URL` — backend environment variable (`.env` / secret manager).
- `SUPABASE_ANON_KEY` — backend environment variable (treat as controlled config; never hardcode in mobile).
- `SUPABASE_SERVICE_ROLE_KEY` — backend-only secret manager / `.env` (never sent to client).
- `DASHBOARD_ADMIN_SESSION_SECRET` (if introduced) — backend-only secret storage.
- Mobile auth/session tokens — stored in encrypted local storage strategy (Needs clarification: current implementation uses Hive; recommend secure storage for tokens).

## 9. CI/CD and Governance Plan
1. Pull requests / merges
   - Required checks: `flutter analyze`, Flutter unit/widget tests for changed modules, FastAPI unit/integration tests, migration lint/check.
   - Required code review: at least one mobile reviewer + one backend reviewer for cross-stack changes.
   - Block merge if new user-facing text lacks `en/fr/ar` keys.
2. Release candidates
   - Run full regression suite on auth + supplier + sync paths.
   - Run migration dry-run on staging snapshot.
   - Validate dashboard approval -> mobile pending/approved propagation.
3. Branch and review policy
   - Use short-lived feature branches linked to tracked work packages.
   - No direct pushes to main/release branches.
   - Require changelog entry for API/schema changes.

## 10. Risks and Mitigations
1. **Risk** — Mobile and dashboard backends diverge, causing duplicate logic and inconsistent supplier status. **Mitigation** — Define one canonical supplier lifecycle API and deprecate parallel endpoints behind explicit ownership.
2. **Risk** — Fake OTP without hard controls can be abused for spam account creation. **Mitigation** — Add rate limiting, phone normalization, and approval gate that blocks unapproved operational access.
3. **Risk** — Background sync reliability differs by platform, especially iOS. **Mitigation** — Combine foreground reconnect sync + app-resume sync + best-effort background job, and document iOS scheduling limits.
4. **Risk** — Trust score penalties feel unfair, reducing supplier adoption. **Mitigation** — Make penalty rules transparent in UI, log reasons, and allow admin override.
5. **Risk** — Cancellation + trust update race conditions create inconsistent state. **Mitigation** — Apply transactional server-side update with single endpoint and idempotency key.
6. **Risk** — Missing localization keys degrade multilingual UX. **Mitigation** — CI rule for key completeness and snapshot checks before merge.

## 11. Milestone Timeline
- Week 1: Phase 0 and Phase 1
- Week 2: Phase 2
- Week 3: Phase 3 and Phase 4 (backend-first, then UI wiring)
- Week 4: Phase 5
- Week 5: Phase 6
- Week 6: Phase 7

## 12. Definition of Done (Project)
- Supplier auth uses phone+OTP UX with resend timer and no hardcoded text.
- New/unapproved suppliers are gated and see pending-verification screen until approved.
- Dashboard approval actions propagate correctly to mobile authentication.
- Supplier declarations and operation cancellations are persisted offline and synced reliably.
- Assigned-operation cancellation enforces call-confirm dialog and trust score update.
- Supplier profile shows name, phone, connectivity, offline queue, trust score, sync action, and logout.
- Ownership checks and role-based guards pass security tests.
- All new copy exists in `en`, `fr`, and `ar`.
- CI pipeline is green for mobile, backend, and schema checks.
- Release runbook and rollback plan are validated.

## 13. Reference Index
- R1: Flutter Documentation — https://docs.flutter.dev/
- R2: FastAPI Documentation — https://fastapi.tiangolo.com/
- R3: Bloc Library Documentation — https://bloclibrary.dev/
- R4: Supabase Auth Concepts — https://supabase.com/docs/guides/auth
- R5: Supabase Row Level Security — https://supabase.com/docs/guides/database/postgres/row-level-security
- R6: PostgreSQL Transaction Isolation — https://www.postgresql.org/docs/current/transaction-iso.html
- R7: Flutter Internationalization — https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization
- R8: OWASP ASVS (Access Control) — https://owasp.org/www-project-application-security-verification-standard/
- R9: Flutter `url_launcher` package — https://pub.dev/packages/url_launcher
- R10: Android WorkManager Overview — https://developer.android.com/topic/libraries/architecture/workmanager
- R11: iOS BackgroundTasks Framework — https://developer.apple.com/documentation/backgroundtasks
- R12: Connectivity Plus package — https://pub.dev/packages/connectivity_plus
- R13: Twelve-Factor App Config — https://12factor.net/config

## 14. Immediate Next Execution Steps
1. Resolve all Phase 0 clarifications (backend ownership, trust penalty, status model) and freeze them in a decision doc.
2. Create and apply schema migrations for supplier approval status and trust score, then add backend contract tests.
3. Implement supplier `request-otp` and `verify-otp` endpoints and wire them into mobile auth state machine.
4. Build dashboard pending-supplier approval page and manager-only approve/reject endpoints.
5. Replace supplier mock operations with repository/API integration and implement cancellation + trust-score update flow.
