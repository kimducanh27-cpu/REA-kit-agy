# APP REVIEW WORKFLOW — REA-kit-agy

- Status: workflow contract proposal
- Last updated: 2026-11-13

## 1. Intake
Collect only what is needed to route the work: app name and goal; target type/location; source availability; user ownership/authorization; allowed operations; desired outcome (understand, audit, fix, add feature, redesign, compatible implementation or rewrite); platform, compatibility, data-handling and deployment constraints. Never ask for passwords or tokens.

## 2. Preflight
1. Identify input type without executing it.
2. Confirm installed REA version. Read active `tools/list` for canonical schemas and call `binary_session` to inspect `result.tool_availability` for the current host, target, provider and client. Request `detail: "complete"` when effect/annotation or provider-remediation fields are needed. If hot/cold catalog mode is enabled, load exact required tools with `discover_tools`; respect configured tool-family exclusions.
3. Read the current upstream Skill route and version-matched target guide.
4. Check readiness only for the selected provider/operation; a broad `rea doctor` result is not proof every operation is ready or unavailable.
5. Explain target effects and host effects. Tool annotations are hints, not authorization controls. Distinguish an REA-owned worker from execution of the target app. Request separate approval for runtime, browser actions, device, network, external-service or mutation operations.
6. If unsupported, explain the missing prerequisite and offer source/manual review.

When source code is supplied, inspect source directly; do not force REA into ordinary source-repository architecture analysis.

## 3. Investigation
Collect relevant artifact identity, version and provenance; modules/resources/platform boundaries; routes/APIs/IPC/methods/permissions/components where supported; the selected feature flow; runtime observations only when authorized; security-relevant declarations; and version/capture comparisons when supported. Do not launch or interact with an app just because static inspection was requested. Static JavaScript analysis may use an owned worker and private temporary files without executing the supplied app. Passive CDP page inspection attaches to an already-running browser and is not general browser automation; `capture_browser_scenario` performs declared actions and needs a separate approval scope.

## 4. Assessment report
Include:
1. Scope: target, date, REA version, agent, platform, authorization and operations performed.
2. Executive summary.
3. App map and feature flows actually evidenced.
4. Technical/quality findings supported by source, test or evidence.
5. Scoped security review: checks, findings, severity, confidence, coverage, unassessed areas and residual risk.
6. Prioritized improvement backlog with impact, urgency, confidence, effort and dependencies.
7. Unknowns and limitations.
8. Owner questions required for decisions.
9. Recommendation: extend, branch feature, new compatible implementation or rewrite, with rationale.

Each important claim links to a source, test, capture or REA Evidence ID.

## 5. Adaptive questions
Follow the 12-step Decision-Driven Interview Engine contract defined in `docs/INTAKE_QUESTION_LOGIC.md` and `docs/ADAPTIVE_INTERVIEW_FRAMEWORK.md`.
Ask only when an answer is not already known, cannot be determined by static analysis or evidence, materially affects an architectural or business decision, is needed in the current phase, and cannot be handled by a reversible safe default.
Map inquiries across the 10 domain guides in `.agents/skills/rea-interview/domains/`. Explain why the question matters in accessible terms. Maintain structured state via `.agents/scripts/interview.ps1`.
Detect contradictions explicitly, prevent redundant questioning, and record assumptions with verifiable tasks when the owner cannot answer.

## 6. Development route
Prefer extending a usable source codebase. Use a focused branch for bounded features. Create a new compatible implementation when source is unavailable or the owner wants an independent product. Recommend rewrite only when current architecture, security, compatibility or economics justify it. Binary-only inspection does not recover complete source or backend; any reconstruction is a new implementation based on authorized observations and approved requirements.

## 7. Specification and build
Before editing, approve features/flows, non-goals, UX, platform/framework compatibility, data model, privacy/security controls, integrations, architecture, tasks, acceptance tests, files in scope and rollback. Work in a new branch, worktree or safe copy.

## 8. Verify and hand off
Run relevant unit, integration, UI/E2E, regression, build, dependency and security checks. A successful build alone does not prove correct behavior. Provide changes, run/configure instructions, test results, defects/unknowns, security residuals, release steps, rollback and owner actions.
