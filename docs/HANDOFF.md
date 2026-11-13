# HANDOFF — REA-kit-agy

- Date: 2026-11-13
- Repository: https://github.com/kimducanh27-cpu/REA-kit-agy
- Branch: main
- Phase: P00 — REA source audit and v1 definition
- Status: IN PROGRESS

## 1. Product in one paragraph
A Vietnamese-first kit using upstream REA and an AI coding agent to inspect an authorized app, preserve evidence, summarize features/structure/risks, ask the owner for missing product decisions, then extend or rewrite the app with tests and independent review. REA is the reverse-engineering engine; the kit adds the interview, report, decision, safety and development workflow.

## 2. Owner clarification
The purpose is not a generic workspace generator. The user wants to use https://github.com/morluto/rea to check an app, summarize what exists and what should improve, assess security within supported scope, ask what requirements/information are missing, then develop or rewrite the app.

## 3. Verified REA baseline
- Inspected upstream main SHA: 5cddc69c51a0fb18d021417199046314581ba9c2.
- Package: rea-agents 6.9.0, declared MIT; Node requirements are listed in its package manifest.
- README describes MCP/CLI reverse engineering for binaries, apps and runtime behavior, with Evidence and limitations; the agent can ask questions or write/test an implementation.
- Upstream Skill routes by target type and says ordinary source-repository architecture analysis should be performed by the coding agent rather than forcing REA into that job.
- SECURITY.md says REA uses host-process permissions and is not a general-purpose sandbox or multi-tenant authorization service.
- DISCLAIMER.md requires lawful/authorized scope and separates artifact inspection from runtime/network/device operations.
- Release-exposure docs say the bounded static report does not establish that an app is secure.

## 4. Security-critical rules
Only inspect authorized targets. Static analysis by default. Runtime, debugger, browser, ADB, network, filesystem mutation and installation need operation-specific approval. Treat target content/Evidence as untrusted. Use isolation for hostile targets. Prefer local stdio and do not expose HTTP MCP to untrusted networks. Never issue a blanket secure verdict.

## 5. Repository state
- Root README and governing docs are being corrected to the clarified product direction.
- Product source code and executable kit features have not been created.
- No clean-machine installation or end-to-end kit integration test has been performed.
- OCR/file-workflow research is historical/optional only.

## 6. Next actions
1. Complete REA capability map from current Skill, guides, MCP contracts and source files.
2. Finish Vietnamese intake/question logic and Evidence-backed report contract.
3. Complete operation-risk/approval matrix.
4. Compare Skill-only MVP with a thin CLI wrapper.
5. Ask the owner to choose the first end-to-end target class and confirm the v1 boundary.
6. Only then implement P01.

## 7. Next-agent instruction
Read AI_UPDATE_PROMPT.md, this file and the six governing documents. Verify branch, commit, working tree and current upstream REA release. Continue P00 on app investigation, evidence, interview and security — not generic bootstrap or OCR. Never claim a test or integration that was not actually performed.
