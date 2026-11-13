# PLAN — REA-kit-agy

- Version: 0.3
- Last updated: 2026-11-13
- Overall Status: P01 IN_PROGRESS (P00 DONE)

## Objective
Use upstream REA plus Google Antigravity (and compatible agents) to inspect an authorized application, report verified behavior and scoped risks, ask the owner for missing requirements, then extend or rebuild the app with tests and independent code review.

---

## Architectural Taxonomy Decoupling

To prevent ambiguity between developing the REA-kit-agy toolchain and executing individual reverse-engineering cases, two orthogonal lifecycle models are strictly defined:

1. **Repo Development Roadmap (P00–P05)**:
   The engineering milestones for building, integrating, and hardening the REA-kit-agy repository itself.
2. **End-User Case Workflow (STAGE_00–STAGE_05)**:
   The 6-stage, 14-step operational workflow executed by an agent when investigating and rebuilding a target application (`active_case.json` state machine).

---

## Current Repo Development Roadmap Status (P00–P05)

| Phase | Status | Current condition |
|---|---|---|
| **P00 — Understand REA and define product boundary** | **DONE** | ADRs 0001–0006 approved. Multi-target taxonomy with Android APK V1 target, Skill-first delivery, 4-tier hybrid memory, single coordinator agent, and CLI ADR management formalized. |
| **P01 — Integrate REA with the first agent** | **IN_PROGRESS** | Active integration with Google Antigravity: Android CLI plugin integration, upstream REA MCP alignment, and Vietnamese orchestration skills (`rea-scan`, `rea-interview`, `rea-build`). |
| **P02 — Investigate and assess an app** | TODO | Depends on verified P01 integration and preflight test suite. |
| **P03 — Clarify requirements** | TODO | Depends on evidence-backed P02 investigation report and unknowns ledger. |
| **P04 — Select and plan development** | TODO | Depends on owner-approved requirements and design tokens from P03. |
| **P05 — Build, test and hand off** | TODO | Depends on approved P04 scope, independent review, and rollback plan. |

---

## Delivery Assessment & Architectural Decisions

- **Delivery Model**: Skill-first over upstream REA MCP is **APPROVED & ADOPTED** (ADR-0002). The kit relies directly on upstream REA MCP server tools (`tools/list`, `binary_session`, REA ADB) and orchestrates them via native Vietnamese Antigravity skills. No premature wrapper CLI.
- **First Target Class**: **ANDROID_APK** is **APPROVED & ADOPTED** (ADR-0001, ADR-0005). Supported via Antigravity Android CLI plugin (`android-cli-plugin`) for SDK/AVD/Device Hub/Layout Inspector combined with REA static & dynamic tooling.
- **Memory Architecture**: 4-Tier Hybrid Memory Architecture is **APPROVED & ADOPTED** (ADR-0003): Event Log, Operational State (`active_case.json`), Durable Rules (`learned_rules.json`), and Injected Context (`docs/`).
- **Agent Coordination**: Single Authoritative Coordinator Model is **APPROVED & ADOPTED** (ADR-0004).

---

## Phases (Repo Development Roadmap)

### P00 — Understand REA and define the product boundary [DONE]
Audit current release, Skill, MCP/CLI contracts, target guides, security policy and disclaimer. Define target routing, operation approval, Evidence preservation, report, interview and minimum v1. Resolved and codified via ADR-0001 through ADR-0006.

### P01 — Integrate REA with the first agent [IN_PROGRESS]
Author and verify original Vietnamese kit instructions/Skills using upstream REA MCP and Antigravity plugins (notably Android CLI plugin). Verify setup/update, version awareness, preflight routines, and doctor checks.

### P02 — Investigate and assess an app [TODO]
Implement intake, preflight, target classification, REA/source analysis and Evidence-backed report. Include coverage, unknowns, and bounded security review.

### P03 — Clarify requirements [TODO]
Implement targeted follow-ups grounded in unresolved product decisions and unknowns. Capture answers, assumptions, non-goals, and owner approval.

### P04 — Select and plan development [TODO]
Compare extending, adding a feature, creating a compatible implementation or rewriting. Produce approved architecture, UX, task plan, and acceptance criteria.

### P05 — Build, test and hand off [TODO]
Implement in an isolated branch/copy, run tests, independent hard review, and scoped security reassessment. Provide rollback and residual risks.

---

## End-User Case Workflow Stages (Operational Model)

For reference, the case workflow for end-users operates across the following standardized stages:

- **STAGE_00_BOOTSTRAP**: Step 00 (Project Bootstrap, Workspace, Git, Config, State).
- **STAGE_01_DISCOVERY**: Step 01 (App Intake / Preflight) + Step 02 (Reference Baseline) ➔ Gate 01 (`gate_01_baseline_verified`).
- **STAGE_02_REVERSE_ENGINEERING**: Step 03 (REA Scan) + Step 04 (REA Investigate) + Step 05 (REA Audit) ➔ Gate 02 (`gate_02_audit_passed`).
- **STAGE_03_PRODUCT_DEFINITION**: Step 06 (REA Interview) + Step 07 (Spec & Design Gate) + Step 08 (Implementation Plan) ➔ Gate 03 (`gate_03_spec_frozen`).
- **STAGE_04_IMPLEMENTATION**: Step 09 (REA Build) + Step 10 (Build QA / Code Review) ➔ Gate 04 (`gate_04_build_qa_passed`).
- **STAGE_05_VALIDATION**: Step 11 (Smoke Test) + Step 12 (Hard Verify) ➔ Gate 05 (`gate_05_hard_verify_passed`) + Step 13 (Release & Handoff) ➔ Gate 06 (`gate_06_handoff_signed`).

---

## Release Gates
- P00: source map, threat model, v1 target, memory model, and owner-approved ADRs [PASSED].
- P01: clean-environment REA integration verified with Google Antigravity and Android CLI plugin.
- P02: evidence-preserving report; no blanket security verdict.
- P03: question loop resolves material requirements without overwhelming the user.
- P04: owner-approved route, design tokens, and acceptance criteria.
- P05: tests/review complete or remaining failures and unknowns explicitly accepted.

## Non-goals
No OCR engine, office converter, generic workspace bootstrap suite, custom REA engine, cloud upload service, public HTTP MCP, or universal security scanner in v1.

## Resolved Owner Decisions
All open decisions from Phase 00 have been resolved by approved ADRs:
1. **Target Class**: Android APK (`ANDROID_APK`) selected for V1 via ADR-0001 & ADR-0005.
2. **Delivery Model**: Skill-first over upstream REA MCP selected via ADR-0002.
3. **Memory Model**: 4-tier hybrid local memory selected via ADR-0003.
4. **Agent Model**: Single coordinator model selected via ADR-0004.
5. **ADR Tooling**: Markdown ADRs with `adr.ps1` selected via ADR-0006.
