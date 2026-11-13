# TASKS — REA-kit-agy

- Last updated: 2026-11-13
- Overall phase: P00 — Research & Source Audit
- Overall phase status: IN_PROGRESS

## Status definitions

- TODO: not started.
- IN_PROGRESS: active work.
- BLOCKED: cannot proceed; reason must be stated.
- DONE: completed with evidence.
- DEFERRED: intentionally postponed with reason.

## P00 — Research & Source Audit

| ID | Task | Status | Evidence / exit condition |
|---|---|---|---|
| P00-01 | Confirm destination repository, branch, and permissions | DONE | GitHub metadata and initial commit verified |
| P00-02 | Inspect REA identity, README, package metadata, license, and Antigravity client mapping | DONE | README, package.json, LICENSE, AGENTS.md, SupportedClients.ts inspected |
| P00-03 | Inspect Craft Anything identity, status, licenses/notices, contributor rules, and Antigravity grants | DONE | README, STATUS.md, LICENSE-MIT, LICENSE-APACHE, NOTICE, ATTRIBUTION.md, AGENTS.md, grants.rs inspected |
| P00-04 | Verify Antigravity workspace-local customization discovery | DONE | Current official Google documentation inspected |
| P00-05 | Map candidate REA/Craft features to exact sources and reuse boundaries | DONE | Source-level mapping recorded in SOURCE_AUDIT.md |
| P00-06 | Research office-document workflow sources and safe file operations | IN_PROGRESS | Candidate survey in FILE_WORKFLOWS_RESEARCH.md; OCR, alternatives, version/security review, and representative-file tests remain |
| P00-07 | Research official support behavior for Claude Code, Cursor, and OpenCode | DONE | Documentation-based matrix in AGENT_COMPATIBILITY.md; runtime tests remain separate |
| P00-08 | Finalize P00 source map and present implementation boundaries for owner approval | IN_PROGRESS | Initial findings documented; dependency choice and P01 boundary not approved |

## P01 — Workspace Foundation

| ID | Task | Status | Evidence / exit condition |
|---|---|---|---|
| P01-01 | Define exact generated workspace structure | TODO | Source-backed and owner-approved folder specification |
| P01-02 | Define user profile and sample-document templates | TODO | Templates reviewed for privacy and usability |
| P01-03 | Define the visible one-page Vietnamese quick guide | TODO | Non-technical review completed |
| P01-04 | Define output naming, collision, and file-state tracking | TODO | Tested behavior and explicit rules |

## Later phases

| ID | Phase | Status | Exit condition |
|---|---|---|---|
| P02 | Antigravity integration | TODO | Workspace rules, skills, MCP only where needed, and install flow verified in Antigravity |
| P03 | Office-workflow skills and helpers | TODO | Each workflow researched, implemented/reused under license, and tested on representative files |
| P04 | Backup, safety, and recovery | TODO | Original-file preservation, approval, backup verification, and recovery tests pass |
| P05 | Cross-agent adapters | TODO | Per-agent support matrix backed by live tests |
| P06 | Hard Review and release readiness | TODO | Independent audit and documented release criteria pass |

## Current constraints

- No live test has run in any target agent.
- No PDF/DOCX/XLSX/OCR dependency is approved.
- Do not begin P01 implementation until P00 source boundaries and unresolved decisions are reviewed.
