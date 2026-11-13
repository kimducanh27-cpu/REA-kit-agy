# HANDOFF — REA-kit-agy

- Handoff date: 2026-11-13
- Repository: https://github.com/kimducanh27-cpu/REA-kit-agy
- Branch: main
- Current phase: P00 — Research & Source Audit
- Current status: IN_PROGRESS

## 1. Project in one paragraph

This repository develops a personal-first Non-Tech Workspace Bootstrap Kit. It creates a clear folder-based workspace for a non-technical user to provide files, supply personal context, request work in plain Vietnamese, and receive verified deliverables in a predictable output folder. Antigravity is the primary agent; Claude Code, Cursor, OpenCode, and others remain compatibility targets after verification.

## 2. User-approved decisions

- Destination repository is kimducanh27-cpu/REA-kit-agy.
- The initial user-visible workspace should use numbered Vietnamese folder names without diacritics.
- Main visible folders: 01_THA_FILE_VAO_DAY, 02_THONG_TIN_CUA_TOI, 03_KET_QUA_XUAT_RA, 04_SAO_LUU_AN_TOAN.
- Keep technical agent materials in an organized technical area; use .agents for new Antigravity workspace customizations.
- Antigravity is the main agent, but do not abandon other-agent compatibility.
- Research and reuse existing repositories before writing new components.
- Priority upstream repositories: https://github.com/morluto/rea and https://github.com/storytold/craft-anything.
- Six mandatory context files live in this repository's docs folder: PRD.md, ARCHITECTURE.md, DESIGN.md, RULES.md, TASKS.md, PROGRESS.md.
- Maintain PLAN.md, HANDOFF.md, AI_UPDATE_PROMPT.md, and SOURCE_AUDIT.md.
- docs contains context, decisions, plans, status, and research only; no product source or user deliverables.

## 3. Current verified findings

### REA
- License MIT; inspected main commit 54906fdb1fc735b507961b2954f6968775cae4f6.
- Setup/SetupPlan build actions before applying them, support dry-run, show a plan, and ask approval.
- SetupRecoveryBackup uses exclusive copy behavior and verifies backup bytes.
- ClientConfigurationTransaction serializes configuration writes for a resolved path.
- SetupSkill checks skill directories and path conditions.
- Doctor is a read-only structured readiness workflow.
- Exact files and reuse boundaries are recorded in SOURCE_AUDIT.md.

### Agent compatibility
- Antigravity, Cursor, and OpenCode document .agents/skills discovery.
- Claude Code project skills use .claude/skills. Its AGENTS.md behavior is conditional; a CLAUDE.md @AGENTS.md import is documented.
- Root AGENTS.md plus agent-specific adapters is the current proposed pattern, not runtime tested.
- Detailed paths, scan behavior, and sources are in AGENT_COMPATIBILITY.md.

### Office-file candidate research
- MarkItDown: broad document-to-Markdown extraction candidate; not a high-fidelity output conversion tool.
- pypdf: PDF extraction/structure candidate; scanned PDFs need OCR separately.
- python-docx: DOCX creation and controlled-edit candidate; does not target legacy DOC.
- pandas: tabular analysis candidate.
- openpyxl: XLSX/XLSM candidate with XML security considerations and maintenance freshness concerns.
- No dependency has been approved or installed.
- Detailed limits and sources are in FILE_WORKFLOWS_RESEARCH.md.

### Craft Anything
- Its AGENTS.md explicitly says original work only and forbids copying code, scripts, schemas, names, assets, or wording.
- Use high-level UX observations only.
- Its Antigravity grants row currently reports no tool server and no approval integration.

## 4. What has NOT been done

- No product code or workspace generator has been written.
- No OCR engine has been selected.
- No live agent integration has been tested.
- No office-document benchmark has been run.
- No final architecture or dependency stack has been approved.

## 5. Exact next actions

1. Research OCR candidates, including Vietnamese support, offline capability, license, packaging, and maintenance.
2. Create representative public/synthetic fixtures for searchable PDF, scanned PDF, DOCX, XLSX with formulas/macros/formatting, CSV, and mixed folders.
3. Define comparison criteria and inspect candidate behavior without using private user documents.
4. Complete P00 recommendations and obtain owner approval for implementation boundaries.
5. Do not start P01 code until P00 decisions are accepted.

## 6. Instructions to the next AI

Read AI_UPDATE_PROMPT.md first, then this HANDOFF.md and all six context files. Verify the current repository branch and Git status before changes. Do not assume prior chat history is available. Continue at P00-06 and P00-08; do not jump to implementation.
