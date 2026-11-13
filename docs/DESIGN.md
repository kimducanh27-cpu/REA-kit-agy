# DESIGN — REA-kit-agy

- Status: experience direction / not implemented
- Last updated: 2026-11-13

## 1. Goal

Make a deep reverse-engineering and app-development process understandable to a Vietnamese-speaking non-specialist without hiding uncertainty, permissions or risk.

## 2. Interaction principles

- Start with the app and the outcome, not REA tool names.
- Explain what will be inspected and what an operation may do before running it.
- Show meaningful phases: intake, preflight, inspection, findings, questions, planning, building and verification.
- Distinguish evidence from interpretation and recommendation.
- Ask a small number of decision-critical questions at a time.
- Explain why each question matters. Allow “chưa biết” and record a reversible assumption.
- Never label incomplete checks as passed.
- Show exactly what the user must approve before state-changing actions.

## 3. User flow

1. **Start case:** user provides app/project and goal; collect authorization and target type.
2. **Preflight:** show target, platform, available inputs, REA/provider readiness and proposed operations. Separate static inspection from runtime/device/browser/network/mutation.
3. **Investigation:** show progress and scope inspected. Keep raw Evidence available, but default to concise Vietnamese explanations with source references.
4. **Findings report:** current state, verified features/flows, technology/components, issues/improvements, scoped security review, unknowns, prioritized backlog and owner questions.
5. **Interview:** ask one logical group at a time; do not repeat facts already supplied or evidenced.
6. **Build route:** compare update existing app, focused feature branch, new compatible implementation and rewrite, including trade-offs.
7. **Approval:** show scope, non-goals, architecture, UX direction, milestones, file impact, acceptance criteria and rollback.
8. **Build/verify:** report work, tests, failures, skipped checks and independent review.
9. **Handoff:** run/configure/update/release/rollback instructions and residual risks.

## 4. Evidence status

Every material claim uses one status:
- OBSERVED — directly returned by a tool or verified in a file/test.
- INFERRED — reasoned from evidence with assumptions stated.
- USER-PROVIDED — stated by the user, not independently verified.
- UNKNOWN — absent or inconclusive evidence.
- NOT ASSESSED — outside scope or unavailable.
- PARTIAL — some data collected but coverage incomplete.

Do not hide material unknown/partial status.

## 5. Report and visual direction

Use clear hierarchy, concise tables/cards and neutral status styling. Reserve strong warning emphasis for material risks. Avoid a large dashboard until a conversational workflow proves insufficient. Markdown is the first report format; PDF/HTML can be considered later. Diagrams must represent evidence-backed structure/flows, not invented architecture.

## 6. Localization

Vietnamese by default. Keep source paths, package/API/class/method names, Evidence IDs and test identifiers exact. Explain necessary technical terms at first use.
