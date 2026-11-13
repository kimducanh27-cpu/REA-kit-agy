# TASKS — REA-kit-agy

- Last updated: 2026-11-13
- Overall: IN_PROGRESS (P00)
- Product: REA-powered app investigation and development kit

## Phase status

| Phase | Status | Dependency / exit gate |
|---|---|---|
| P00 — REA research and v1 boundary | IN_PROGRESS | Owner must select the first target class and approve the v1 boundary before P01 |
| P01 — REA integration | TODO | P00 exit gate passed |
| P02 — App investigation and report | TODO | P01 integration verified |
| P03 — Requirement clarification | TODO | P02 evidence-backed report available |
| P04 — Plan and design development | TODO | P03 material decisions approved |
| P05 — Implementation and verification | TODO | P04 scope, route, acceptance criteria and rollback approved |

## P00 — REA research, evidence contract and v1 boundary

| ID | Task | Status | Review / blocker | Exit condition |
|---|---|---|---|---|
| P00-01 | Audit current REA release, README, full Skill, MCP/CLI contracts and target support | IN_PROGRESS | Source review is version-pinned; installed runtime catalog and target-specific live readiness remain unverified | Version-pinned capability map with routes, prerequisites, effects, limits and environment unknowns |
| P00-02 | Review REA security policy, disclaimer, tool effects and provider boundaries | IN_PROGRESS | Representative effects reviewed; full target-specific matrix awaits selected v1 route | Approval matrix reviewed against actual effects and connected tool definitions |
| P00-03 | Define Vietnamese intake and adaptive question logic | IN_PROGRESS | Draft exists; OWNER REVIEW REQUIRED | Questions are evidence-driven and decision-critical |
| P00-04 | Define investigation report and Evidence status contract | IN_PROGRESS | Draft exists; OWNER REVIEW REQUIRED | Report preserves Evidence, coverage, limitations and unknowns |
| P00-05 | Define source-repo review versus packaged-app reverse-engineering routes | IN_PROGRESS | Candidate routes verified; selected v1 target remains open | Correct routing and fallback for the owner-selected target |
| P00-06 | Select first end-to-end target class | BLOCKED | OWNER DECISION REQUIRED | Owner selects target and authorized test scope |
| P00-07 | Select Skill-first or thin CLI wrapper delivery | TODO | Skill-first is PROPOSED; not approved | Evidence-backed comparison and explicit owner decision |
| P00-08 | Define extend/new/rewrite decision and build safety | IN_PROGRESS | Draft exists; OWNER REVIEW REQUIRED | Acceptance, isolation, backup and rollback rules approved |
| P00-09 | Research supplementary SAST/dependency tools if a gap remains | DEFERRED | Reopen only after a documented gap in the selected route | A concrete gap and source-backed comparison justify added tooling |

## P01 — REA integration

Status: TODO. Depends on P00 approval.

- Build original Vietnamese kit Skill/instructions.
- Verify official REA installation, version pin/update path and setup approval.
- Build target preflight/capability reporting.
- Test in Antigravity using a clean workspace and record exact application/REA versions.

## P02 — App investigation and report

Status: TODO. Depends on verified P01 integration.

- Evidence-preserving investigation workflow.
- App/component/feature-flow report.
- Scoped security assessment output.
- Prioritized, evidence-backed improvement backlog.

## P03 — Requirement clarification

Status: TODO. Depends on a real P02 report.

- Generate questions from report unknowns.
- Capture owner decisions and assumptions.
- Produce approved requirements and non-goals.

## P04 — Plan and design development

Status: TODO. Depends on P03 decisions.

- Compare extending existing app, feature branch, new compatible app and rewrite.
- Produce architecture/design and tasks.
- Prepare isolated branch/copy and rollback baseline.

## P05 — Implementation and verification

Status: TODO. Depends on an owner-approved P04 plan.

- Implement approved scope.
- Run functional, regression and platform tests.
- Run independent hard review.
- Reassess security/privacy.
- Package and hand off.

## Deferred / not core

OCR and office-document research remain optional historical material. Generic folder bootstrap, GUI/dashboard, cloud services and multi-agent orchestration are not v1 priorities.

## Implementation gate

No product code or new dependency until P00 has a version-pinned REA map, route-specific security/effect model, Evidence/report and intake contracts reviewed with the owner, a selected v1 target and an owner-approved delivery boundary.
