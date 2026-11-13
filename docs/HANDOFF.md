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
- Two priority upstream repositories: https://github.com/morluto/rea and https://github.com/storytold/craft-anything.
- The six mandatory context files live in this repository's docs folder: PRD.md, ARCHITECTURE.md, DESIGN.md, RULES.md, TASKS.md, PROGRESS.md.
- Maintain PLAN.md, HANDOFF.md, AI_UPDATE_PROMPT.md and SOURCE_AUDIT.md as needed.
- The docs folder contains context, decisions, plans, and progress only; no product source or user deliverables.

## 3. Current verified findings

- REA is MIT-licensed. Its current package metadata reports 6.9.0.
- REA has a client definition for Antigravity and records personal-scope paths under ~/.gemini/config.
- REA installation documentation says setup previews proposed configuration changes and asks for approval; it documents agent-specific skill locations.
- Google's Antigravity docs describe workspace-local .agents customization directories, skills, MCP configuration, and AGENTS.md/GEMINI.md.
- Craft Anything's current README identifies it as early alpha.
- Craft Anything provides LICENSE-MIT and LICENSE-APACHE, a NOTICE, and ATTRIBUTION.md.
- Craft Anything's AGENTS.md expressly says original work only and prohibits copying code, scripts, schemas, names, assets, or wording from another project.
- Craft Anything's current Antigravity grant row declares no tool server and no approval integration. Do not treat its Antigravity adapter as a safe integration template.

See SOURCE_AUDIT.md for exact links and revisions.

## 4. What has NOT been done

- No product code or workspace generator has been written.
- No PDF/Word/Excel dependency has been chosen.
- No Antigravity live integration test has run.
- No other-agent adapter has been tested.
- No final source mapping or architecture has been approved.

## 5. Exact next actions

1. Continue inspecting REA's setup implementation, configuration merge/write behavior, backups, diagnostics, client registry, skill installation, and associated tests.
2. Inspect relevant Craft Anything UX and status documents only; respect its original-work-only restriction.
3. Research PDF, DOCX, XLSX, CSV, and image processing alternatives from primary documentation and maintained repositories.
4. Verify official customization paths for Claude Code, Cursor, and OpenCode.
5. Complete SOURCE_AUDIT.md with exact files, commit SHAs, licenses, and REUSED / ADAPTED / ORIGINAL / RESEARCH NEEDED labels.
6. Present findings and unresolved choices before implementing P01.

## 6. Instructions to the next AI

Read AI_UPDATE_PROMPT.md first, then this HANDOFF.md and all six context files. Verify the current repository branch and git status before changing anything. Do not assume prior chat history is available. Continue at P00-05/P00-06/P00-07; do not jump to coding.
