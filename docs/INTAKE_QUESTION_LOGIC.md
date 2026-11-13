# INTAKE QUESTION LOGIC — REA-kit-agy

- Status: draft interview contract
- Last updated: 2026-11-13

## 1. Principle
Do not dump a long form on the user. Inspect what can safely be inspected, then ask only for missing information that changes the next decision. Ask conversationally in small batches and do not repeat information already supplied or evidenced.

## 2. Intake minimum
Establish:
1. What app/project is this and what outcome does the user want?
2. What input is available: source repository, local folder, APK, desktop artifact, browser target, capture or other?
3. Does the user own it or have permission to inspect it?
4. What scope is allowed now: static-only, or specifically approved runtime/device/browser/network operations?
5. What platform/environment matters?

If an essential detail is missing, ask one direct question before proceeding.

## 3. When to ask a follow-up
Ask only if the answer is unknown, materially affects product requirements/implementation, is needed now and cannot be handled by a reversible safe default. Internally record the evidence gap, why it matters, options/default, impact if unanswered and phase when needed.

## 4. Question categories
Use only relevant categories:
- Product/audience: users, main job, behavior to preserve, highest-priority feature.
- Platform/delivery: OS/device/browser support, existing app versus separate app, distribution/update path.
- UX: incomplete flows, design references, accessibility, localization and device constraints.
- Data/integrations: stored data, APIs/services, offline mode, data that must remain local.
- Security/roles: roles, access boundaries, authentication, permissions, retention, backup and deletion.
- Engineering/operations: compatibility, backend, CI/release, performance/reliability/cost, secure test data access.

Never ask for actual passwords or API keys.

## 5. If the owner does not know
Do not block unrelated work. Offer a conservative reversible default only when appropriate. Mark it as an assumption, not an accepted fact. Add a verification task and revisit when evidence or a prototype can answer it.

## 6. Completion
For the current milestone, every decision affecting scope, architecture, data/privacy, security, compatibility and acceptance must be answered/approved, explicitly deferred, or recorded as an owner-accepted assumption with a verification task.
