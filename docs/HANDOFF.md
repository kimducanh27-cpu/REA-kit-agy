# HANDOFF — REA-kit-agy

- Handoff date: 2026-11-13
- Repository: https://github.com/kimducanh27-cpu/REA-kit-agy
- Branch: main
- Current phase: P00 — Research & Source Audit
- Current status: IN_PROGRESS
- Current focus: BOOTSTRAP CORE, NOT OCR

## 1. Project in one paragraph

Build a personal-first Non-Tech Workspace Bootstrap Kit for a non-technical user. It creates a clear folder-based workspace, supplies the correct instructions/Skills for the chosen AI agent, makes first use understandable in Vietnamese, and keeps setup and file operations safe. Antigravity is the primary target; Claude Code, Cursor, OpenCode, and other agents remain compatibility targets through verified adapters.

## 2. User-approved decisions

- Destination repository: kimducanh27-cpu/REA-kit-agy.
- Main user-facing folders: 01_THA_FILE_VAO_DAY, 02_THONG_TIN_CUA_TOI, 03_KET_QUA_XUAT_RA, 04_SAO_LUU_AN_TOAN.
- Antigravity is the main agent, but do not abandon other-agent compatibility.
- Priority references: https://github.com/morluto/rea and https://github.com/storytold/craft-anything.
- Research existing repositories before designing/implementing; do not invent systems or present unverified claims as facts.
- Six mandatory context files live in docs: PRD.md, ARCHITECTURE.md, DESIGN.md, RULES.md, TASKS.md, PROGRESS.md.
- Maintain PLAN.md, HANDOFF.md, AI_UPDATE_PROMPT.md, and SOURCE_AUDIT.md.
- docs/ contains project context, decisions, plans, research, and progress only. No product code or user deliverables.

## 3. Scope clarification — important

OCR is not a core requirement. It is only relevant if a later optional Skill needs to read scanned/image-only PDFs or pictures. Ordinary text-based PDFs do not inherently require OCR.

The earlier OCR_RESEARCH.md and FILE_WORKFLOWS_RESEARCH.md are retained as optional future references. They do not authorize installing OCR engines, selecting document libraries, or making document conversion a central product feature. Do not let this research block or dominate the bootstrap kit.

Core v1 focus:
1. Generate the four visible user folders and technical agent configuration.
2. Provide the simplest reliable Antigravity workspace-local setup.
3. Provide clear user instructions and a fill-in personal profile.
4. Distribute Skills at correct locations for each supported Agent.
5. Protect configuration and user files using source-backed setup preview, approval, backups, diagnostics, and recovery.
6. Add verified adapters for other Agents without claiming feature parity.

## 4. Current verified findings

### REA
- MIT; inspected commit 54906fdb1fc735b507961b2954f6968775cae4f6.
- Setup and SetupPlan build planned actions, support dry-run, and ask for approval before applying changes.
- SetupRecoveryBackup uses exclusive copy and verifies backup bytes.
- ClientConfigurationTransaction serializes changes per configuration path.
- SetupSkill validates skill roots and path safety.
- Doctor is a read-only structured health-check workflow.
- Exact source mapping and license boundaries are in SOURCE_AUDIT.md.

### Craft Anything
- Use only high-level UX observations.
- Its AGENTS.md prohibits copying code, scripts, schemas, names, assets, or wording.
- Do not use its current Antigravity adapter as a safe integration template.

### Agent compatibility
- Antigravity is primary.
- Official docs describe .agents/skills for Antigravity, Cursor, and OpenCode.
- Claude Code project Skills use .claude/skills; a CLAUDE.md import adapter is a documented way to import @AGENTS.md.
- These are documentation findings, not runtime tests. See AGENT_COMPATIBILITY.md.

## 5. Repository status

- No product source code or executable kit functionality has been created.
- No dependencies or OCR engine have been installed or selected.
- No live Antigravity/Claude Code/Cursor/OpenCode tests have been performed.
- The root currently contains README.md and docs/ only.

## 6. Exact next actions

1. Continue P00 by researching existing workspace bootstrap/install repositories and official Antigravity setup patterns.
2. Inspect whether REA's setup/client/backup/doctor mechanisms can be reused independently; document exact file and license provenance.
3. Define minimal v1 bootstrap behavior, installation scope, and explicit non-goals.
4. Present the bootstrap-core source map and implementation boundary for owner approval.
5. Do not benchmark or install OCR/document-processing packages unless the owner explicitly brings that capability into scope.

## 7. Instructions to next AI

Read AI_UPDATE_PROMPT.md first, then this HANDOFF.md and all six context files. Verify repository branch, current commit, and Git status. Continue with bootstrap-core P00 tasks, not OCR. Keep docs synchronized and follow RESEARCH → VERIFY → REUSE → INTEGRATE → TEST.
