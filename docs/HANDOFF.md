# HANDOFF — REA-kit-agy

- Date: 2026-11-13
- Repository: https://github.com/kimducanh27-cpu/REA-kit-agy
- Branch: main
- Repo Roadmap Status: **P01 IN_PROGRESS (P00 DONE, P01 ACTIVE)**
- Case Workflow State: **STAGE_00_BOOTSTRAP completed, ready for STAGE_01_DISCOVERY**
- Status: READY & ALIGNED (ADRs 0001–0006 Approved, Health Check 6/6 PASSED, REA Doctor Aligned)

## 1. Product in one paragraph
A Vietnamese-first kit using upstream REA (https://github.com/morluto/rea) and Google Antigravity (leveraging the official Android CLI plugin `android-cli-plugin`, with Claude Code, Cursor, OpenCode compatibility) to inspect an authorized app (V1 target class: `ANDROID_APK`), preserve evidence, summarize features/structure/risks, interview the user on missing requirements, then extend or rewrite the app with tests, independent review, and structured handoff across a decoupled 6-Stage · 14-Step case lifecycle.

## 2. Completed Architecture, Governance & Roadmap Sync

### Architectural Taxonomy Decoupling
- **Repo Development Roadmap (P00–P05)**: Tracks engineering milestones of the REA-kit-agy repository.
  - **P00 (DONE)**: Research REA capabilities, establish product boundary, approve ADRs 0001–0006.
  - **P01 (IN_PROGRESS)**: Integrate REA MCP and Android CLI plugin with Antigravity; develop Vietnamese orchestration skills.
  - **P02–P05 (TODO)**: App investigation, requirement clarification, planning, and reconstruction.
- **End-User Case Workflow (STAGE_00–STAGE_05)**: Tracks live application investigation cases in `.agents/state/active_case.json`.

### Architecture Decision Records (ADRs) Established
- Managed locally via standard MADR markdown files and `.agents/scripts/adr.ps1`:
  1. `docs/adrs/0001-multi-target-architecture.md`: Multi-target taxonomy with single verified V1 target class (`ANDROID_APK`).
  2. `docs/adrs/0002-skill-first-delivery.md`: Upstream REA engine as MCP; Vietnamese orchestration skills; no premature CLI wrapper.
  3. `docs/adrs/0003-hybrid-memory-architecture.md`: 4-tier hybrid memory (Event log, `active_case.json`, `learned_rules.json` + `docs/`, Injected context).
  4. `docs/adrs/0004-single-coordinator-agent-model.md`: Single authoritative coordinator model.
  5. `docs/adrs/0005-android-apk-first-target-via-android-cli.md`: Android APK as V1 target via Antigravity Android CLI plugin + REA ADB.
  6. `docs/adrs/0006-cli-adr-management.md`: Zero external dependency file-based ADR management via CLI.

### 6-Stage · 14-Step Case Lifecycle Governance (`docs/WORKFLOW_LIFECYCLE.md`)
- **STAGE_00_BOOTSTRAP** (Foundation): Bước 00 Project Bootstrap ➔ Gate 00: Ready
- **STAGE_01_DISCOVERY** (Tab 01): Bước 01 App Intake + Bước 02 Reference Baseline (với Static Fallback) ➔ **Gate 01**: `gate_01_baseline_verified`
- **STAGE_02_REVERSE_ENGINEERING** (Tab 02): Bước 03 REA Scan + Bước 04 REA Investigate + Bước 05 REA Audit ➔ **Gate 02**: `gate_02_audit_passed`
- **STAGE_03_PRODUCT_DEFINITION** (Tab 03): Bước 06 REA Interview + Bước 07 Spec & Design Gate + Bước 08 Implementation Plan ➔ **Gate 03**: `gate_03_spec_frozen`
- **STAGE_04_IMPLEMENTATION** (Tab 04): Bước 09 REA Build + Bước 10 Build QA / Code Review ➔ **Gate 04**: `gate_04_build_qa_passed`
- **STAGE_05_VALIDATION** (Tab 05): Bước 11 Smoke Test + Bước 12 Hard Verify (1-to-1 Matrix) ➔ **Gate 05**: `gate_05_hard_verify_passed` + Bước 13 Release & Handoff ➔ **Gate 06**: `gate_06_handoff_signed`

## 3. Workspace Scaffolding & Directory Structure
- **Five user-facing numbered directories created**:
  - `01_THA_APP_VAO_DAY/` (Input for APK, ASAR, source ZIP, binary, web links + `baseline/`)
  - `02_YEU_CAU_CUA_TOI/` (Contains `ho-so-va-muc-tieu.md` and 3-tier Design Tokens in `design.md`)
  - `03_KET_QUA_KIEM_TRA/` (Audit reports, Unknowns ledger, Frozen spec, Implementation plan, QA results, Hard verify report)
  - `04_SAO_LUU_AN_TOAN/` (Immutable backup destination for user inputs)
  - `05_MA_NGUON_PHAT_TRIEN/` (Destination for new or rewritten source code, `preview.html`, `.backup/`, and `BAN_GIAO_SAN_PHAM.md`)
- **Root rule and guides**:
  - `AGENTS.md` (Governing non-tech Vietnamese rules, 6-stage 14-step lifecycle, 6 quality gates)
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
  - 7 skills: 1 upstream engine skill (`.agents/skills/reverse-engineer-anything/` v62) + 6 orchestration skills (`rea-scan`, `rea-audit`, `rea-interview`, `rea-plan`, `rea-build`, `memory-consolidation`)
  - `.agents/rules/rea-workflow.md` (Antigravity YAML rule for security and lifecycle integrity)
  - `.agents/scripts/health_check.ps1` (Tested: 6/6 components verified ready, including runtime REA doctor & Auto-Resume banner)
  - `.agents/scripts/verify_code.ps1` (Deterministic syntax, tag & secret checker, exit code 0/1)
  - `.agents/scripts/rollback.ps1` (1-click automated rollback engine)
  - `.agents/scripts/adr.ps1` (CLI ADR inspector and status reporter)
  - `.agents/state/active_case.json` (State machine tracking live cases across STAGE_00 to STAGE_05, target_class `ANDROID_APK`)
  - `.agents/state/learned_rules.json` (Incidents to Evals failure pattern memory)
- **Living Docs & Auto-Resume**:
  - `docs/PLAN.md` & `docs/TASKS.md`: P00 marked DONE (all P00-01 to P00-08 closed), P01 IN_PROGRESS.
  - `docs/PROGRESS.md`: Synced with STAGE_00..STAGE_05 case checklist and P00/P01 roadmap status.
  - `docs/HANDOFF.md`: Comprehensive handoff ledger.
  - Auto-Resume banner printed on session startup and health check runs.
