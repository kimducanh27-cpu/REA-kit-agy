# TASKS — REA-kit-agy

- Last updated: 2026-11-13
- Overall: IN_PROGRESS (P01 Active, P00 Closed)
- Product: REA-powered app investigation and development kit

---

## Architectural Taxonomy Decoupling

- **Repo Development Roadmap (P00–P05)**: Tracks the engineering milestones of the REA-kit-agy framework.
- **End-User Case Workflow (STAGE_00–STAGE_05)**: Tracks execution of individual application analysis cases (`.agents/state/active_case.json`).

---

## Repo Development Roadmap Phase Status

| Phase | Status | Dependency / exit gate |
|---|---|---|
| **P00 — REA research and v1 boundary** | **DONE** | ADRs 0001–0006 approved. Target class (`ANDROID_APK`) and Skill-first delivery formalized. |
| **P01 — REA integration** | **IN_PROGRESS** | P00 exit gate passed; integrating Antigravity Android CLI plugin, upstream REA MCP, and Vietnamese skills. |
| **P02 — App investigation and report** | TODO | P01 integration and preflight verified |
| **P03 — Requirement clarification** | TODO | P02 evidence-backed report and unknowns ledger available |
| **P04 — Plan and design development** | TODO | P03 material decisions and design tokens approved |
| **P05 — Implementation and verification** | TODO | P04 scope, route, acceptance criteria, and rollback approved |

---

## P00 — REA research, evidence contract and v1 boundary [DONE]

| ID | Task | Status | Resolution / Decision Artifact | Exit Condition Met |
|---|---|---|---|---|
| P00-01 | Audit current REA release, README, full Skill, MCP/CLI contracts and target support | **DONE** | ADR-0001, ADR-0002, and `docs/SOURCE_AUDIT.md`. Pinned to upstream REA 5cddc69. | Version-pinned capability map with routes, prerequisites, and effects documented. |
| P00-02 | Review REA security policy, disclaimer, tool effects and provider boundaries | **DONE** | ADR-0003, ADR-0004, and `docs/SECURITY_REVIEW_MODEL.md`. Local-first data boundary enforced. | Approval matrix reviewed against actual effects and connected tool definitions. |
| P00-03 | Define Vietnamese intake and adaptive question logic | **DONE** | ADR-0002, `docs/INTAKE_QUESTION_LOGIC.md`, and `prompts/01-TAB-DISCOVERY.md`. | Intake prompts and question logic are evidence-driven and decision-critical. |
| P00-04 | Define investigation report and Evidence status contract | **DONE** | ADR-0003, `templates/01-REPORT-TEMPLATE.md`, and `templates/06-UNKNOWNS-AND-COVERAGE-TEMPLATE.md`. | Report preserves Evidence, coverage, limitations, and unknowns without hallucination. |
| P00-05 | Define source-repo review versus packaged-app reverse-engineering routes | **DONE** | ADR-0001 (Multi-Target Architecture with pluggable routing and source fallback). | Correct routing and fallback formalized across target types. |
| P00-06 | Select first end-to-end target class | **DONE** | **SOLVED by Android APK target** (`ANDROID_APK`) via ADR-0001 & ADR-0005 (leveraging Antigravity Android CLI plugin + REA ADB). | Target selected, authorized test scope and tooling contract approved. |
| P00-07 | Select Skill-first or thin CLI wrapper delivery | **DONE** | **SOLVED by Skill-first delivery** via ADR-0002 (upstream REA MCP + native Vietnamese Antigravity skills; zero wrapper CLI). | Evidence-backed comparison and explicit architectural decision recorded. |
| P00-08 | Define extend/new/rewrite decision and build safety | **DONE** | ADR-0003, `REVIEW.md`, `rollback.ps1`, and `docs/WORKFLOW_LIFECYCLE.md` (Zero-Install, 1-Click Rollback). | Acceptance criteria, isolated workspace, backup, and rollback rules approved. |
| P00-09 | Research supplementary SAST/dependency tools if a gap remains | DEFERRED | Reopen only after a documented gap in the selected Android APK route. | A concrete gap and source-backed comparison justify added tooling. |

---

## P01 — REA integration

Status: **IN_PROGRESS** (P00 exit gate passed with ADRs 0001–0006; integration artifacts delivered & verified via health check 6/6 PASSED).

- [x] Establish MADR repository architecture decisions (`docs/adrs/0001`–`0006`) and CLI runner (`.agents/scripts/adr.ps1`).
- [x] Connect and verify upstream REA MCP server (`npx -y rea-agents`) with Google Antigravity (runtime doctor check in `health_check.ps1`).
- [x] Integrate Antigravity Android CLI plugin (`android-cli-plugin`) for Android APK target class (SDK, AVD, Device Hub, Layout Inspector in `WORKFLOW_LIFECYCLE.md`, `AGENTS.md`, `health_check.ps1`).
- [x] Build original Vietnamese kit skills (`rea-scan`, `rea-interview`, `rea-build` in `.agents/skills/`).
- [x] Implement target preflight / capability reporting for `ANDROID_APK` (`prompts/01-TAB-DISCOVERY.md`, `health_check.ps1`, `active_case.json`).
- [x] Test in Antigravity workspace and verify environment integrity (Health check 6/6 PASSED, Auto-Resume banner active).
- [ ] Complete live end-to-end sample APK ingestion through P01 exit gate into P02.

---

## P02 — App investigation and report

Status: TODO. Depends on verified P01 integration.

- Evidence-preserving investigation workflow (`STAGE_02_REVERSE_ENGINEERING`).
- App/component/feature-flow report.
- Scoped security assessment output.
- Prioritized, evidence-backed improvement backlog and unknowns ledger.

---

## P03 — Requirement clarification

Status: TODO. Depends on a real P02 report.

- Generate questions from report unknowns (`STAGE_03_PRODUCT_DEFINITION`).
- Capture owner decisions and assumptions.
- Produce frozen spec (`dac-ta-yeu-cau-da-chot.md`), 3-tier design tokens, and atomic implementation plan.

---

## P04 — Plan and design development

Status: TODO. Depends on P03 decisions.

- Compare extending existing app, feature branch, new compatible app and rewrite.
- Produce architecture/design and task plan (`STAGE_04_IMPLEMENTATION`).
- Prepare isolated branch/copy and rollback baseline.

---

## P05 — Implementation and verification

Status: TODO. Depends on an owner-approved P04 plan.

- Implement approved scope (`STAGE_05_VALIDATION`).
- Run functional, regression, and platform tests.
- Run independent hard review and 1-to-1 matrix verification.
- Reassess security/privacy and complete structured handoff.

---

## Deferred / not core

OCR and office-document research remain optional historical material. Generic folder bootstrap, GUI/dashboard, cloud services, and forced multi-agent orchestration are not v1 priorities.

---

## Implementation gate

**PASSED FOR P00**. P00 requirements have been fully resolved with version-pinned REA mapping, route-specific security model, Evidence/report contracts, selected V1 target (`ANDROID_APK`), and approved Skill-first delivery boundary. P01 implementation is authorized and in progress.
