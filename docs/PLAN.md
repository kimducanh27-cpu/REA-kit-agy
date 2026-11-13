# PLAN — REA-kit-agy

- Version: 0.2
- Last updated: 2026-11-13

## Objective
Use REA plus a coding agent to inspect an authorized application, report verified behavior and scoped risks, ask the owner for missing requirements, then extend or rebuild the app with tests.

## Current phase status — 2026-11-13

| Phase | Status | Current condition |
|---|---|---|
| P00 — Understand REA and define product boundary | IN_PROGRESS | Source audit and workflow drafts are being refined; first target class and v1 boundary require owner decision |
| P01 — Integrate REA with the first agent | TODO | Antigravity is upstream-supported; this kit's runtime is untested |
| P02 — Investigate and assess an app | TODO | Depends on verified P01 integration |
| P03 — Clarify requirements | TODO | Depends on an evidence-backed P02 report |
| P04 — Select and plan development | TODO | Depends on owner decisions from P03 |
| P05 — Build, test and hand off | TODO | Depends on approved P04 scope and rollback plan |

Delivery assessment: Skill-first over upstream REA MCP is **PROPOSED**, not approved. A thin CLI wrapper remains an option only if a verified gap warrants it. See ARCHITECTURE.md and SOURCE_AUDIT.md.
## Phases

### P00 — Understand REA and define the product boundary
Audit current release, Skill, MCP/CLI contracts, target guides, security policy and disclaimer. Define target routing, operation approval, Evidence preservation, report, interview and minimum v1. No implementation before the owner approves the boundary.

### P01 — Integrate REA with the first agent
Create original Vietnamese kit instructions/Skills using the upstream REA Skill and actual connected tools. Verify setup/update, version awareness and approval. Antigravity is the first candidate, not an assumed success.

### P02 — Investigate and assess an app
Implement intake, preflight, target classification, REA/source analysis and Evidence-backed report. Include coverage, unknowns and bounded security review.

### P03 — Clarify requirements
Ask targeted follow-ups grounded in unresolved product decisions. Capture answers, assumptions, non-goals and owner approval.

### P04 — Select and plan development
Compare extending, adding a feature, creating a compatible implementation or rewriting. Produce approved architecture, UX, task plan and acceptance criteria.

### P05 — Build, test and hand off
Implement in an isolated branch/copy, run tests, independent hard review and scoped security reassessment. Provide rollback and residual risks.

## Release gates
- P00: source map, threat model, v1 target and owner-approved boundary.
- P01: clean-environment REA integration verified with one agent.
- P02: evidence-preserving report; no blanket security verdict.
- P03: question loop resolves material requirements without overwhelming the user.
- P04: owner-approved route and acceptance criteria.
- P05: tests/review complete or remaining failures and unknowns explicitly accepted.

## Non-goals
No OCR engine, office converter, generic workspace bootstrap suite, custom REA engine, cloud upload service, public HTTP MCP or universal security scanner in v1.

## Open owner decisions
First target class and delivery model remain undecided. Do not silently choose Android, web, Electron or another platform as the sole v1 target.
