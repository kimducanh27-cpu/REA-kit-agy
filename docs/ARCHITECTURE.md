# ARCHITECTURE — REA-kit-agy

- Status: direction defined / not implemented
- Last updated: 2026-11-13
- Upstream baseline: morluto/rea main SHA 5cddc69c51a0fb18d021417199046314581ba9c2; package 6.9.0

## 1. System boundary

Three cooperating parts:

1. REA upstream: reverse-engineering/observation tools via MCP and CLI, returning structured Evidence.
2. Coding agent: source repository inspection, reasoning, user interview, design, implementation and tests.
3. REA-kit-agy: Vietnamese-first process connecting intake, target routing, evidence interpretation, assessment, approval, build decisions and handoff.

The kit should orchestrate REA rather than fork its analysis engine.

## 2. Logical layers

### Intake
Collect target locator/type, supplied files/repository, goal, ownership/authorization and constraints. Classify source repository, packaged artifact, live runtime/browser/device or capture. Record allowed operation classes. Never request secrets.

### REA adapter
Discover actual MCP tools and provider readiness. Follow the current upstream Skill and version-matched guides. Use CLI only when MCP is unavailable or the upstream workflow requires it. Preserve Evidence IDs, provider/version, authority, provenance, coverage, limitations and unknowns. Do not hard-code a stale tool catalog.

### Source inspection
When source is supplied, use normal coding-agent repository inspection for architecture, code, dependencies and tests. The upstream REA Skill says to skip REA for ordinary source-repository architecture analysis. Use REA for relevant shipped artifacts, runtime behavior, feature tracing or version reconciliation.

### Evidence/report
Classify claims as observed, static inference, runtime observed, user-provided, partial, unknown or not assessed. Retain original Evidence. Produce app map, feature findings, improvement backlog, scoped security review, limitations and next questions.

### Interview/decisions
Generate questions from unresolved decisions. Link each question to the evidence gap it resolves. Record accepted answers and assumptions; reopen a decision if later evidence contradicts it.

### Planning/build
Compare extend-existing, focused feature branch, new implementation and rewrite. Approve requirements, non-goals, UX, architecture, tests and files in scope before edits. Implement in an isolated branch or safe copy.

### Verification/handoff
Run tests and independent review. Report pass, fail, blocked, partial and not-run separately. Provide change summary, limitations, residual risks, release instructions and rollback.

## 3. End-to-end data flow

Intake and authorization → target classification/preflight → permitted REA and source workflows → Evidence collection → findings report → targeted questions → owner decisions → approved specification → isolated implementation → tests and hard review → scoped security reassessment → handoff.

No later phase silently expands permissions. A new runtime, device, account, network or destructive operation requires separate approval.

## 4. REA integration rules

- Prefer official sources: https://github.com/morluto/rea and https://www.npmjs.com/package/rea-agents.
- Use setup preview/plan and explicit approval.
- Prefer local stdio MCP. Do not expose HTTP MCP to public or untrusted networks.
- Check installed version and actual tool catalog before using version-dependent tools.
- Keep upstream REA Skill upstream-owned; install through its supported distribution path. Kit-specific Vietnamese workflows are original content.
- Unsupported target/provider means explain the blocker or fallback; never fabricate results.

### MCP discovery and effects

- `tools/list` is canonical for complete tool definitions and schemas. `binary_session` and `result.tool_availability` describe current host/provider/target/client availability; request `detail: "complete"` when effect/annotation fields or provider remediation are needed.
- If hot/cold discovery is enabled, load exact tools through `discover_tools`. Respect configured `REA_MCP_TOOL_FAMILIES`; excluded tools are not callable merely because they exist upstream.
- Effect annotations are descriptive hints, not authorization controls. Static target analysis can launch an REA-owned worker or write temporary files without executing supplied app code.
- Preserve Evidence identity, authority, provenance, coverage, limitations and unknowns through every projection/page.
## 5. Target routing examples

Exact routes depend on the installed REA version and its Skill:
- JavaScript/Electron directory or ASAR: static application analysis and feature tracing.
- Android APK: static package/manifest/class analysis via documented provider route.
- Android device: ADB workflows only with separate device authorization.
- Website in a user-owned Chrome-family browser: passive CDP observation, not generic remote browser control.
- .NET/native/desktop/firmware and other formats: only documented target/provider route.
- Ordinary source repository: coding-agent source inspection first.

Maintain a capability matrix with version, platform, prerequisites, operation effects, test status and gaps.

## 6. Per-app case record

A case should be able to retain target identity/authorization, input references and hashes, complete Evidence exports/index, human report, questions/decisions, requirements/design, implementation branch, tests and handoff. Exact on-disk layout is not yet approved.

Never store real user artifacts, private Evidence, source code or secrets in this public repository. Use synthetic/public fixtures.

## 7. Security boundaries

REA is local and uses host permissions; it is not a sandbox or multi-tenant authorization system. Treat targets and Evidence as hostile input. Static parsing, external-provider execution and runtime interaction have different effects. MCP host approvals do not replace the kit's scope and consent process.

See SECURITY_REVIEW_MODEL.md and upstream SECURITY.md / DISCLAIMER.md.

## 8. Deferred choices

### Delivery-model comparison — PROPOSED, not approved

- **Skill-first over upstream REA MCP:** smallest initial integration surface. The kit contributes Vietnamese intake, decision-critical questions, report structure, authorization gates and handoff while REA retains its target tools and schemas. This is a preferred prototype candidate only.
- **Thin CLI wrapper:** consider only if a verified gap requires deterministic case persistence, schema validation, repeatable reports, cross-agent setup or automation that a Skill plus existing REA CLI/MCP cannot provide. A wrapper adds packaging, runtime, filesystem, update and test obligations.
- **Status:** PROPOSED. Neither delivery model is approved. Do not create a wrapper, package, server or dependency until the owner approves the v1 boundary and a demonstrated gap justifies it.

Other deferred choices: case schema; Evidence persistence; supplementary source/dependency/UI security tools; GUI; multi-agent orchestration. Add no framework, server, database or dependency without a demonstrated need and source-backed comparison.
