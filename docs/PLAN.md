# PLAN — REA-kit-agy

- Plan version: 0.1
- Status: PROPOSED IMPLEMENTATION SEQUENCE
- Last updated: 2026-11-13

## Goal

Build a personal-first, non-technical workspace bootstrap kit with Antigravity as the primary agent and verified compatibility paths for other agents.

## P00 — Research & Source Audit

Goal: establish what can be reused, adapted, or must remain original before product implementation.

1. Inspect REA setup, configuration writers, backup logic, client registry, skills distribution, doctor/diagnostics, and tests.
2. Map exact source files and identify their licenses, notices, and dependencies.
3. Inspect Craft Anything only for permitted high-level user-experience patterns; do not copy its prohibited source materials or wording.
4. Verify Antigravity workspace-local customization rules using official Google docs.
5. Research official documentation and live discovery behavior for Claude Code, Cursor, and OpenCode.
6. Research document-processing tools for PDF, DOCX, XLSX, CSV, and image inputs.
7. Compare candidate sources for maintenance, compatibility, security, license, and integration effort.
8. Produce a source-to-feature matrix and explicit list of unresolved questions.
9. Submit the implementation boundary and any new ORIGINAL components for user approval.

Exit criteria:
- Every proposed reusable component has a source, exact file/location, revision, license, and integration rationale.
- Craft Anything is limited to high-level observations unless its restrictions are separately resolved.
- Agent support statements are evidence-backed and scoped.
- No major architecture or dependency is selected merely by guesswork.

## P01 — Workspace Foundation

Goal: implement the user-visible workspace only after P00 source research and approval.

Expected outcomes:
- Agreed visible folder structure.
- User-editable profile and sample templates.
- Simple Vietnamese quick guide.
- Defined output naming and collision behavior.
- Safe starter rules.

Exact implementation and packaging remain subject to source audit and user approval.

## P02 — Antigravity integration

Goal: create and verify workspace-local Antigravity rules and skills. Investigate MCP only for capabilities that are actually required. Avoid global configuration changes by default.

## P03 — Office-workflow capabilities

Research and validate each workflow before selecting an implementation:
- Document summarization and extraction.
- Spreadsheet cleanup and reporting.
- File organization and safe renaming.
- Writing from user-provided samples.
- Output quality checks.

## P04 — Safety, backup, and recovery

Verify backup contents, file identity, no-overwrite behavior, approval gates, recovery steps, and failure reporting.

## P05 — Other agent adapters

Add only integrations with documented behavior and real tests. Maintain per-agent feature parity rather than claiming uniform support.

## P06 — Independent Hard Review and release

Perform independent review of source attribution, licensing, safety, file workflows, usability, cross-agent compatibility, tests, documentation, and packaging.

## Approval boundary

This plan records the approved phase order and product direction. Specific dependencies, architecture decisions, scripts, global agent settings, and high-impact file operations still require evidence and the relevant approval.
