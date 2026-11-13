# HANDOFF — REA-kit-agy

- Date: 2026-11-13
- Repository: https://github.com/kimducanh27-cpu/REA-kit-agy
- Branch: main
- Phase: P01 — Non-tech Workspace Scaffolding & REA Skill Integration
- Status: READY & ALIGNED (Health Check 6/6 PASSED, REA Doctor Aligned, 6-Phase 14-Step Lifecycle Fully Implemented)

## 1. Product in one paragraph
A Vietnamese-first kit using upstream REA (https://github.com/morluto/rea) and Google Antigravity (with Claude Code, Cursor, OpenCode compatibility) to inspect an authorized app, preserve evidence, summarize features/structure/risks, interview the user on missing requirements, then extend or rewrite the app with tests, independent review, and structured handoff across a 6-Phase · 14-Step lifecycle.

## 2. Completed Workspace Scaffolding & Lifecycle Architecture
- **6-Phase · 14-Step Lifecycle Governance (`docs/WORKFLOW_LIFECYCLE.md`)**:
  - Phase 00 (Foundation): Bước 00 Project Bootstrap
  - Phase 01 (Discovery - Tab 01): Bước 01 App Intake + Bước 02 Reference Baseline (với Static Fallback) ➔ **Gate 01**: `gate_01_baseline_verified`
  - Phase 02 (Reverse Engineering - Tab 02): Bước 03 REA Scan + Bước 04 REA Investigate + Bước 05 REA Audit ➔ **Gate 02**: `gate_02_audit_passed`
  - Phase 03 (Product Definition - Tab 03): Bước 06 REA Interview + Bước 07 Spec & Design Gate + Bước 08 Implementation Plan ➔ **Gate 03**: `gate_03_spec_frozen`
  - Phase 04 (Implementation - Tab 04): Bước 09 REA Build + Bước 10 Build QA / Code Review ➔ **Gate 04**: `gate_04_build_qa_passed`
  - Phase 05 (Validation - Tab 05): Bước 11 Smoke Test + Bước 12 Hard Verify (1-to-1 Matrix) ➔ **Gate 05**: `gate_05_hard_verify_passed` + Bước 13 Release & Handoff ➔ **Gate 06**: `gate_06_handoff_signed`
- **Five user-facing numbered directories created**:
  - `01_THA_APP_VAO_DAY/` (Input for APK, ASAR, source ZIP, binary, web links + `baseline/`)
  - `02_YEU_CAU_CUA_TOI/` (Contains `ho-so-va-muc-tieu.md` and 3-tier Design Tokens in `design.md`)
  - `03_KET_QUA_KIEM_TRA/` (Audit reports, Unknowns ledger, Frozen spec, Implementation plan, QA results, Hard verify report)
  - `04_SAO_LUU_AN_TOAN/` (Immutable backup destination for user inputs)
  - `05_MA_NGUON_PHAT_TRIEN/` (Destination for new or rewritten source code, `preview.html`, `.backup/`, and `BAN_GIAO_SAN_PHAM.md`)
- **Root rule and guides**:
  - `AGENTS.md` (Governing non-tech Vietnamese rules, 6-phase 14-step lifecycle, 6 quality gates)
  - `CLAUDE.md` (Using verified `@AGENTS.md` import pattern)
  - `UPSTREAMS.md` (Upstream register pinned to morluto/rea SHA 5cddc69c51a0fb18d021417199046314581ba9c2)
  - `REVIEW.md` (Independent code review contract, high-signal filter, and risk-tiering)
  - `HUONG_DAN_SU_DUNG.md` (1-page quick start cheat sheet)
  - `KIEM_TRA.bat` (1-click health check launcher for Windows)
  - `HOAN_TAC.bat` (1-click rollback launcher to restore latest working snapshot)
- **Process Playbook & Templates**:
  - `prompts/`: 00-SESSION-CONTINUITY, 01-TAB-DISCOVERY, 02-TAB-REVERSE-ENGINEERING, 03-TAB-PRODUCT-DEFINITION, 04-TAB-IMPLEMENTATION, 05-TAB-VALIDATION, BOOTSTRAP_KIT
  - `templates/`:
    * 01-REPORT-TEMPLATE
    * 02-SPEC-TEMPLATE
    * 03-RUN-GUIDE-TEMPLATE
    * 04-TEST-RESULT-TEMPLATE
    * 05-DESIGN-TOKEN-TEMPLATE
    * 06-UNKNOWNS-AND-COVERAGE-TEMPLATE
    * 07-IMPLEMENTATION-PLAN-TEMPLATE
    * 08-HARD-VERIFY-TEMPLATE
    * 09-HANDOFF-BUNDLE-TEMPLATE
- **Antigravity integration**:
  - 4 skills: 1 upstream engine skill (`.agents/skills/reverse-engineer-anything/`) + 3 orchestration skills (`rea-scan`, `rea-interview`, `rea-build`)
  - `.agents/rules/rea-workflow.md` (Antigravity YAML rule for security and lifecycle integrity)
  - `.agents/scripts/health_check.ps1` (Tested: 6/6 components verified ready, including runtime REA doctor & Auto-Resume banner)
  - `.agents/scripts/verify_code.ps1` (Deterministic syntax, tag & secret checker, exit code 0/1)
  - `.agents/scripts/rollback.ps1` (1-click automated rollback engine)
  - `.agents/state/active_case.json` (State machine tracking live cases across 6 gates and 14 steps)
  - `.agents/state/learned_rules.json` (Incidents to Evals failure pattern memory)
- **Living Docs & Auto-Resume**:
  - `docs/PROGRESS.md`: 14-step checklist synced on every gate transition.
  - `docs/HANDOFF.md`: Comprehensive handoff ledger.
  - Auto-Resume banner printed on session startup and health check runs.
