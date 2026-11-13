# TASKS — REA-kit-agy

- Last updated: 2026-11-13
- Overall: P00 IN PROGRESS
- Product: REA-powered app investigation and development kit

## P00 — REA research, evidence contract and v1 boundary

| ID | Task | Status | Exit condition |
|---|---|---|---|
| P00-01 | Audit current REA release, README, Skill, MCP/CLI contracts and target support | IN PROGRESS | Version-pinned capability map |
| P00-02 | Review REA security policy, disclaimer, tool effects and provider boundaries | IN PROGRESS | Threat model and approval matrix reviewed against actual tool effects |
| P00-03 | Define Vietnamese intake and adaptive question logic | DRAFTED — OWNER REVIEW | Questions are evidence-driven and decision-critical |
| P00-04 | Define investigation report and Evidence status contract | DRAFTED — OWNER REVIEW | Report preserves Evidence, coverage and unknowns |
| P00-05 | Define source-repo review versus packaged-app reverse-engineering routes | DRAFTED — NEEDS TARGET MATRIX | Correct routing and fallback per supported target |
| P00-06 | Select first end-to-end target class | BLOCKED — OWNER DECISION | Owner selects target |
| P00-07 | Decide Skill-only, CLI wrapper or both | TODO | Evidence-backed architecture decision |
| P00-08 | Define extend/new/rewrite decision and build safety | DRAFTED — OWNER REVIEW | Acceptance and rollback rules approved |
| P00-09 | Research supplementary SAST/dependency tools if a gap remains | DEFERRED | Only after a documented gap |

## P01 — REA integration
- Build original Vietnamese kit Skill/instructions.
- Verify official REA installation, version pin/update path and setup approval.
- Build target preflight/capability reporting.
- Test in Antigravity.

## P02 — App investigation and report
- Evidence-preserving investigation workflow.
- App/component/feature-flow report.
- Scoped security assessment output.
- Prioritized, evidence-backed improvement backlog.

## P03 — Requirement clarification
- Generate questions from report unknowns.
- Capture owner decisions and assumptions.
- Produce approved requirements and non-goals.

## P04 — Plan and design development
- Compare extending existing app, feature branch, new compatible app and rewrite.
- Produce architecture/design and tasks.
- Prepare isolated branch/copy and rollback baseline.

## P05 — Implementation and verification
- Implement approved scope.
- Run functional, regression and platform tests.
- Run independent hard review.
- Reassess security/privacy.
- Package and hand off.

## Deferred / not core
OCR and office-document research remain optional historical material. Generic folder bootstrap, GUI/dashboard, cloud services and multi-agent orchestration are not v1 priorities.

## Implementation gate
No product code or new dependency until P00 has a version-pinned REA map, security model, Evidence/report contract, proposed v1 target and owner-approved boundary.
