You are a senior software architect and technical program manager.

Produce a complete, implementation-ready project plan for the following project:

---
PROJECT DESCRIPTION:
[Describe what you are building. Include the type of artifact (library, CLI tool, web app, VS Code extension, API service, mobile app, etc.), the primary technology stack if known, and the problem it solves.]

TARGET USERS:
[Who will use this? Developers, end users, internal teams, etc.]

KEY CONSTRAINTS:
[List any hard constraints: platform targets, language requirements, security requirements, existing systems to integrate with, timeline pressure, team size, etc. Leave blank if none.]

OUT OF SCOPE (V1):
[Optionally list features or concerns you explicitly do not want in the first version.]
---

Generate a plan structured exactly as follows. Be specific, opinionated, and practical. Avoid vague filler. Every section should contain information a developer can act on immediately.

---

## Document Control
- Project name, artifact type, target runtime/platform, primary language/stack, version (1.0 planning baseline), date.

## 1. Vision and Outcome
One paragraph stating what is being built and why it matters.
Then a numbered user flow (3–6 steps) showing the experience from the user's perspective end to end.

## 2. Scope
### In Scope (V1)
A bullet list of concrete features and capabilities included in the first version.

### Out of Scope (V1)
A bullet list of explicitly deferred features with a brief rationale for each.

## 3. Quality Bar and Success Criteria
Define measurable success across all relevant dimensions. Include as many of the following as apply to the project:
- **Functional Success** — what the system must correctly do
- **Security Success** — threat controls that must be in place
- **Performance Success** — latency, throughput, or resource budgets
- **Operability Success** — build reproducibility, test determinism, upgrade paths
- **UX/DX Success** — usability or developer experience standards

## 4. Target Architecture
### 4.1 Core Components
Number and name each major component. For each one write 2–3 sentences on its responsibility and the key design decisions it owns.

### 4.2 Proposed Folder/Module Structure
Show a representative directory or module tree using a code block. Include every top-level area and at least one level of depth inside each.

## 5. Phase Plan
Break the work into sequential phases numbered from 0. Phase 0 is always a requirements and risk baseline. The final phase is always packaging, release, and operational readiness. For every phase include:

### Phase N — [Name]
**Goals** — 1–3 sentences on what this phase achieves.
**Work Packages** — numbered list of concrete tasks. Each task should be specific enough for a developer to start without further clarification.
**Deliverables** — tangible outputs (files, documents, deployed services, test suites).
**Exit Criteria** — objective conditions that must be true before moving to the next phase.
**References** — link to relevant docs, specs, or external resources (use R-numbers matching Section 13).

## 6. Security Plan (Cross-Cutting)
### 6.1 Threat Model Checklist
Bullet list of the top security risks relevant to this project type.

### 6.2 Mandatory Controls
Numbered list of security controls that must be implemented before any production release.

### 6.3 Security Testing Controls
How security will be validated (unit tests, integration tests, SAST, dependency scans, penetration tests, etc.).

## 7. Performance Plan (Cross-Cutting)
### 7.1 Key Levers
Bullet list of the architectural and implementation choices that most influence performance.

### 7.2 Recommended Defaults
A table or list of concrete configuration defaults with the reasoning or source behind each value.

### 7.3 Runtime Safeguards
Mechanisms that prevent performance degradation from reaching the user (timeouts, circuit breakers, rate limits, result caps, graceful degradation).

## 8. Configuration Surface
### 8.1 Non-Secret Settings
List every user-configurable setting with its key name, type, and default.

### 8.2 Secret / Credential Storage
List all secrets, how they are stored, and what storage mechanism is used (environment variable, secret manager, keychain, etc.).

## 9. CI/CD and Governance Plan
Define the automated checks required on:
1. Pull requests / merges
2. Release candidates
3. Branch and review policy

## 10. Risks and Mitigations
Number each risk. Format: **Risk** — one sentence. **Mitigation** — one sentence. Include at least 4 risks covering technical, security, operational, and UX/adoption dimensions.

## 11. Milestone Timeline
Map each phase to a week or sprint. Express as a simple list: "Week N: Phase X and Phase Y".

## 12. Definition of Done (Project)
Bullet list of conditions that must all be true for the project to be considered complete and production-ready.

## 13. Reference Index
List all external references cited in the phase plan using R-numbers. Format: R1: [Title] — [URL].

## 14. Immediate Next Execution Steps
A numbered list of 3–5 concrete actions a developer can take right now to begin. These should be specific enough to act on within the first working session.
---

Be exhaustive. Prefer specificity over generality. When you are uncertain about a detail, state your assumption explicitly and flag it for review. Do not omit any section.
```