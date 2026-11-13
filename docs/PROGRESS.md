# PROGRESS — REA-kit-agy

- Last updated: 2026-11-13
- Overall: P00 IN PROGRESS
- Product direction: REA-powered App Investigation & Development Kit

## 2026-11-13 — Owner clarification and documentation direction reset

### Completed
- Re-read current REA README and package metadata.
- Verified inspected upstream main SHA: 5cddc69c51a0fb18d021417199046314581ba9c2.
- Verified package rea-agents 6.9.0, declared MIT license and release published 2026-11-12.
- Inspected current upstream REA Skill, Evidence workflow reference, SECURITY.md, DISCLAIMER.md, installation guide, Android static-analysis guide, browser-observation guide and release-exposure report.
- Confirmed REA is the reverse-engineering/evidence engine; REA-kit-agy adds Vietnamese intake, assessment/report, adaptive interview, build-route decision, safety gates and handoff.
- Confirmed ordinary source-repository architecture analysis should be performed by the coding agent; REA should be used where shipped artifact/runtime analysis adds value.
- Recorded security boundaries: REA runs with host permissions, is not a sandbox, treats target/Evidence content as untrusted, and requires operation-specific consent for runtime/device/browser/network actions.
- Recorded release-exposure boundary: bounded static findings with unknown/not-assessed states; no overall security verdict.
- Updated root README and core project documents: PRD, ARCHITECTURE, DESIGN, RULES, TASKS, PLAN, HANDOFF, AI_UPDATE_PROMPT, SOURCE_AUDIT.
- Added APP_REVIEW_WORKFLOW.md, SECURITY_REVIEW_MODEL.md and INTAKE_QUESTION_LOGIC.md as draft workflow contracts.

### Not completed
- No product source code or executable kit functionality.
- No new dependencies selected or installed.
- No clean-machine REA installation.
- No live Antigravity/Claude Code/Cursor/OpenCode integration test.
- No app target analyzed end-to-end by this kit.
- No application security test or security certification.
- No product test suite run; the changes in this session are documentation-only.

### Next work
1. Finish the version-pinned REA capability map from the full Skill, MCP contracts and target guides/source files.
2. Review and refine the draft intake, report and development-route contracts.
3. Complete the operation approval matrix against actual REA tool effects.
4. Compare Skill-only MVP with a thin CLI wrapper.
5. Ask owner to select the first target class and confirm v1 boundary.
6. Begin P01 only after the owner-approved boundary.

## Historical notes
- Earlier generic workspace bootstrap, file-workflow and OCR research is no longer the product's central direction.
- OCR_RESEARCH.md and FILE_WORKFLOWS_RESEARCH.md remain optional historical references only. No OCR engine or document-processing dependency has been selected or installed.
