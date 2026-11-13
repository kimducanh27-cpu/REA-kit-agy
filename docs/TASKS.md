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
| P00-01 | Confirm destination repository, branch, and permissions | DONE | GitHub metadata: public repo, main branch, write/admin permission available to connected integration |
| P00-02 | Inspect REA repository identity, README, package metadata, license, and Antigravity client mapping | DONE | README, package.json, LICENSE, AGENTS.md, SupportedClients.ts inspected; see SOURCE_AUDIT.md |
| P00-03 | Inspect Craft Anything identity, README, status, licenses/notices, contributor rules, and Antigravity adapter grant row | DONE | README, docs/STATUS.md, LICENSE-MIT, LICENSE-APACHE, NOTICE, ATTRIBUTION.md, AGENTS.md, grants.rs inspected; see SOURCE_AUDIT.md |
| P00-04 | Verify Antigravity's current workspace-local customization discovery | DONE | Official Google docs inspected; see SOURCE_AUDIT.md |
| P00-05 | Map reusable features to exact upstream files and licensing conditions | IN_PROGRESS | Initial mapping exists; deeper source-level review and individual-file provenance still required |
| P00-06 | Research office-document workflow implementations and safe file operations | TODO | Identify and verify maintained source repositories/libraries before selecting dependencies |
| P00-07 | Research official support behavior for Claude Code, Cursor, and OpenCode | TODO | Produce capability/path matrix with official references and version/date |
| P00-08 | Produce a final P00 source audit and recommend implementation boundaries | TODO | Findings, gaps, decisions, and explicit user approvals recorded |

## P01 — Workspace Foundation

| ID | Task | Status | Evidence / exit condition |
|---|---|---|---|
| P01-01 | Define exact generated workspace structure | TODO | Source-backed and approved folder specification |
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

## Current blockers

None recorded. Unknowns and unfinished research remain tracked as TODO above.
