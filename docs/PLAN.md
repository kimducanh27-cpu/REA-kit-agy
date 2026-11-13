# PLAN — REA-kit-agy

- Plan version: 0.2
- Status: PROPOSED IMPLEMENTATION SEQUENCE
- Last updated: 2026-11-13

## Goal

Build a personal-first Non-Tech Workspace Bootstrap Kit that makes it easy for a non-technical user to start and use an AI workspace. Antigravity is the primary target; Claude Code, Cursor, OpenCode, and other agents remain compatibility targets through verified adapters.

## Product-focus clarification

The core product is the workspace bootstrap and agent-setup experience:
- Create a clear user-facing folder structure.
- Install or generate the correct rules and Skills for the selected agent.
- Explain how the user starts working in plain Vietnamese.
- Protect files and configuration during setup.
- Check whether the workspace and agent configuration are ready.

OCR, document-conversion engines, PDF parsing libraries, spreadsheet engines, and other task-specific utilities are optional future extensions. They must not block or dominate the core bootstrap project unless the owner explicitly changes scope.

## P00 — Research & Source Audit

Goal: determine what existing projects and official agent mechanisms can be reused before designing the bootstrap implementation.

1. Complete the file-level source map for REA setup flow, client registry, Skills distribution, configuration transactions, backup/recovery, doctor, and tests.
2. Record precise reuse boundaries and license notices for each reusable REA component.
3. Use Craft Anything only for high-level independent UX observations; obey its original-work-only restrictions.
4. Verify current Antigravity workspace-local rules, Skills, MCP, and plugin discovery.
5. Verify Claude Code, Cursor, and OpenCode instruction/Skill discovery and identify minimum adapters.
6. Research existing workspace bootstrap/install projects and compare setup flows, per-agent configuration, dry-run, approval, health checks, and uninstall/rollback.
7. Define the smallest useful v1 bootstrap scope and explicit non-goals.
8. Produce the source-to-feature map, unresolved questions, and implementation boundary for owner review.

OCR/document-processing research already performed is retained as optional future reference. It is not a P00 exit criterion.

Exit criteria:
- Every proposed reusable core component has a source, exact file/location, revision, license, and integration rationale.
- Craft Anything is limited to high-level observations unless its restrictions are separately resolved.
- Agent support statements are evidence-backed and scoped.
- Core scope excludes optional document-engine complexity unless separately approved.
- Owner approves the P01 implementation boundary.

## P01 — Workspace Foundation

Goal: create the user-facing workspace structure and starter instructions after P00 approval.

Expected outcomes:
- Agreed visible folder structure.
- User-editable profile and optional sample templates.
- Clear Vietnamese quick-start guide.
- Root/shared instructions and technical folder layout.
- No unnecessary runtime or package dependencies.

Exact packaging and implementation remain subject to source audit and owner approval.

## P02 — Antigravity-first integration

Goal: make the generated workspace work well in Antigravity using documented workspace-local configuration. Investigate MCP/plugins only where needed. Avoid global configuration changes by default.

## P03 — Other-agent adapters

Goal: add Claude Code, Cursor, and OpenCode compatibility through separate verified adapters. Maintain a capability matrix; do not claim parity without runtime tests.

## P04 — Safety, setup, backup, health check, and recovery

Goal: adapt and test relevant REA installation patterns for setup preview, user approval, configuration preservation, backup verification, diagnostics, and safe rollback.

## P05 — Optional task Skills

Goal: add practical task Skills only after the bootstrap foundation works. Each Skill must have a verified source or an explicit ORIGINAL justification. Document-processing/OCR helpers are optional and require separate approval.

## P06 — Independent Hard Review and release

Review source attribution, licensing, setup safety, usability for non-technical users, Antigravity runtime behavior, other-agent compatibility, tests, documentation, and packaging.

## Approval boundary

This plan records the current product focus and phase order. Specific dependencies, implementation architecture, scripts, global agent settings, and high-impact file operations require evidence and the relevant approval.
