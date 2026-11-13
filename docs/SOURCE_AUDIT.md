# SOURCE AUDIT — REA-kit-agy

- Last updated: 2026-11-13
- Primary upstream: https://github.com/morluto/rea
- Inspected upstream main SHA: 5cddc69c51a0fb18d021417199046314581ba9c2
- Inspected package version: 6.9.0
- Declared upstream license: MIT
- Status: capability/source mapping in progress; no code copied

## 1. Verified upstream package

- Repository metadata identifies morluto/rea as a public non-fork repository described as reverse engineering applications and native binaries.
- Root package is rea-agents 6.9.0, ESM; package manifest declares Node.js 22.x >=22.23.4, 24.x >=24.22.1 or >=26.12.1.
- The latest release endpoint inspected in this task reports rea-agents 6.9.0 published 2026-11-12.
- package.json and LICENSE declare MIT. Copies/substantial portions must preserve the copyright and permission notice. Dependencies and commercial analysis providers retain their own licenses; inspect THIRD_PARTY_NOTICES.md and vendor terms.
- This audit is pinned to the SHA above. Re-audit when main/release changes.

## 2. Product fit

Current README says REA connects an agent to tools for inspecting native binaries, JavaScript/Electron apps, .NET assemblies and websites, alongside many other formats. The agent can investigate how a feature works, inspect evidence and then build a similar feature for the user's project. CLI and MCP use the same workflows; results include evidence and limitations.

Therefore REA is the investigation/evidence engine. REA-kit-agy adds Vietnamese intake, reporting, adaptive questions, improvement prioritization, owner decisions, build-route selection and delivery/verification workflow.

## 3. Important sources at the inspected SHA

| File | Verified role | Kit relevance |
|---|---|---|
| README.md | Product boundary, setup, MCP/CLI, analysis scope and limitations | Capability overview |
| package.json and LICENSE | Package version, Node range and MIT notice | Runtime/licensing gate |
| .agents/skills/reverse-engineer-anything/SKILL.md | Target routing, workflows and exclusions | Upstream Skill; avoid casual forking |
| .agents/skills/reverse-engineer-anything/references/evidence-workflows.md | Evidence identity, reuse, coverage and unknowns | Evidence contract |
| SECURITY.md | Threat model, host permissions, untrusted data and limits | Security boundary |
| DISCLAIMER.md | Lawful use, authorization and runtime/network/device duties | Responsible use |
| docs/getting-started/installation.md | Setup preview, approval, backup/recovery and readiness | Safe integration |
| docs/guides/javascript/javascript-application-workflows.md | JavaScript/Electron analysis and feature tracing | Target route |
| docs/guides/android/android-analysis.md | Static APK analysis and manifest/class limitations | Target route |
| docs/guides/web/browser-observation.md | Passive CDP observation, not general remote control | Browser route |
| docs/release-exposure.md | Bounded static release exposure checks; no secure verdict | Scoped security signal |
| docs/reference/mcp-contracts.md | Tool contracts and Evidence delivery | Runtime schema source |

Pinned links:
- https://github.com/morluto/rea/blob/5cddc69c51a0fb18d021417199046314581ba9c2/README.md
- https://github.com/morluto/rea/blob/5cddc69c51a0fb18d021417199046314581ba9c2/package.json
- https://github.com/morluto/rea/blob/5cddc69c51a0fb18d021417199046314581ba9c2/.agents/skills/reverse-engineer-anything/SKILL.md
- https://github.com/morluto/rea/blob/5cddc69c51a0fb18d021417199046314581ba9c2/SECURITY.md
- https://github.com/morluto/rea/blob/5cddc69c51a0fb18d021417199046314581ba9c2/DISCLAIMER.md
- https://github.com/morluto/rea/blob/5cddc69c51a0fb18d021417199046314581ba9c2/docs/release-exposure.md

## 4. Technical boundaries

### Source repo versus packaged app
The upstream REA Skill explicitly says to skip REA for ordinary source-repository architecture analysis. If source is supplied, inspect code/build/tests directly with the coding agent. Use REA where shipped artifacts, runtime behavior, feature tracing or version reconciliation add value.

### Static versus runtime
README distinguishes static JavaScript/.NET inspection from operations that run or interact with targets. Runtime/debugger/instrumentation/browser/device/network workflows may execute code, attach to processes, make requests, write files or interact with apps/devices. Static inspection does not authorize those actions.

### Security
The release-exposure guide reports what static analysis recovered, keeps unknown/not-assessed counts and has no overall pass verdict/grade. It explicitly does not establish that the app is secure.

### Host trust and transport
SECURITY.md says REA runs with host-process permissions and is not a sandbox or multi-tenant authorization service. Targets can be malicious. Opt-in HTTP MCP has no TLS/client authentication and shares runtime state; use local stdio and isolate hostile targets.

## 5. Capability areas to verify for v1
JavaScript/Electron analysis and feature tracing; Android APK and separately scoped ADB workflows; passive website/browser observation and saved network captures; .NET/native/desktop/firmware and other documented formats; Evidence export/import/comparison; readiness and setup approval.

This is a candidate map, not a claim that every provider or target is installed or tested in the user's environment. Check the connected tool catalog and version-matched docs at runtime.

## 6. Reuse decision
- REA engine: official package/repository integration first; no fork/source copying planned.
- Upstream REA Skill: upstream-owned content; use supported installation/distribution path. Vendoring requires separate review.
- Kit interview logic, Vietnamese workflow instructions, report templates and decision framework: original material to develop here.
- Third-party providers: optional/user-managed unless separately reviewed for license, install, security and approval.

No REA source code or third-party implementation has been copied into this repo.

## 7. Historical research
Craft Anything is only optional UX background, not the engine. FILE_WORKFLOWS_RESEARCH.md and OCR_RESEARCH.md are historical/optional and do not define product scope. The earlier setup-only audit used REA commit 54906fdb1fc735b507961b2954f6968775cae4f6; those findings are not the current capability baseline.

## 8. Version-pinned Skill and MCP contract

The full upstream Skill at the inspected SHA declares metadata version **62**. For a complete source repository, use ordinary repository tools and do not run REA readiness/provider commands for ordinary source-architecture analysis. Use REA when the question depends on a shipped artifact, decompilation, requested runtime evidence or version comparison.

The MCP contract establishes:
- `tools/list` is canonical for complete tool definitions and schemas.
- `binary_session({})` reports `result.tool_availability` for current host, target, provider and client. `detail: "complete"` adds provider diagnostics and tool effect/annotation fields omitted from the summary.
- If `REA_MCP_TOOL_CATALOG_PROFILE=hot-cold` is enabled, use `discover_tools` to load cold tools before calling them.
- `REA_MCP_TOOL_FAMILIES` may exclude tool families. Documented examples: Android `android,adb,apktool,session`; browser `browser,pcap,session,javascript-runtime`. These are not frozen catalog values.
- Evidence references preserve source identity, authority, provenance, coverage, limitations and unknowns. Page exhaustion never upgrades incomplete coverage.

### Target-routing matrix for v1 selection

| Supplied target | Upstream route | Verified prerequisites / limits | Approval boundary |
|---|---|---|---|
| Complete source repository | Normal coding-agent repository inspection; skip REA | Direct source, build and test inspection | Supplied/authorized repository and approved worktree only |
| JavaScript/Electron directory or ASAR | `analyze_javascript_application` | Node range from package manifest; static JS analysis does not require native decompiler. Owned worker and temporary files are used; target app code is not executed | Artifact read scope; runtime interaction is separate |
| Android APK code/classes/methods | `inspect_android_package`, then focused advertised tools | Full JDK 17+; `jadx-headless-mcp` 0.7.1 with SHA-256 `6e5eacf500b64292bfb73c49797c1958f6ee44646e43e868039ae7feb573ff75`; Linux also needs procps-compatible `ps`. Static parsing does not install/run APK | APK only by default; ADB, installation, device interaction and Frida require separate approval |
| APK signing facts | `inspect_apk_signature` | Static scheme, signer fingerprint, lineage and digest self-consistency; not trust/authenticity verdict | Local artifact inspection only |
| Existing website in user-owned browser | `list_browser_targets`, then `inspect_web_page` | Chrome-family browser with loopback CDP. Passive attach, not general automation; can affect observed session | Explicit browser/profile/origin scope; scenario navigation/click/type via `capture_browser_scenario` needs separate approval |
| .NET assembly | `inspect_managed_artifact` | Static managed metadata/CIL; no external engine prerequisite stated | Supplied assembly only; do not execute |
| Native binary | `open_binary`, then selected-provider tools | Hopper/Ghidra/IDA/Kuna availability depends on host and target; query `binary_session` | Disclose provider/process effects; runtime/debugger actions separately approved |
| Shipped app exposure | `audit_release_exposure` / `rea audit-release-exposure` | Bounded static report for `.app`, install directory, ASAR or executable. Native hardening, Mach-O hardened runtime and Android manifest are not assessed by this report | Static artifact scope; no overall security verdict |

This matrix does not select a v1 platform or imply every provider is installed/tested.

## 9. Host effects and authorization semantics

Upstream MCP does not implement owner authorization through per-call permission grants; MCP clients provide confirmation UI. Tool annotations are hints, not authorization controls. `readOnlyHint` may be false because Evidence is recorded even when the target is unchanged. `destructiveHint` may describe data loss, execution/driving of code not owned by REA, or Android device mutation.

Verified examples: `analyze_javascript_application` starts an owned worker and writes private temporary files without executing supplied app code; `analyze_web_bundle` likewise uses a worker and temporary files without executing captured code; Android static analysis invokes JADX but does not install/run the APK; passive CDP attaches to an already-running browser and does not navigate; DMG inventory may launch `hdiutil`; extraction writes to a fresh output directory. Show host effects, target effects and outputs separately. “Static” does not mean “no host side effects”.

## 10. Agent setup and delivery-model comparison

REA 6.9.0's official installation guide lists Antigravity with client ID `antigravity`. At the inspected SHA, `src/application/SupportedClients.ts` defines MCP config path `~/.gemini/config/mcp_config.json` and upstream Skill destination `~/.gemini/config/skills`. This proves upstream setup/path support, not a working REA-kit-agy runtime integration. Upstream setup previews client changes and requests approval; it does not install Node.js, Java/JDK, JADX or native analysis engines.

**Delivery evaluation — PROPOSED, not approved:** Skill-first over upstream REA MCP is the smallest initial prototype. It adds the Vietnamese workflow, authorization gates, Evidence/report contract, interview and handoff without duplicating the engine. Consider a thin wrapper only if tests prove a concrete need for case persistence, report/schema validation, cross-agent setup or automation not reasonably handled by a Skill plus existing CLI/MCP. No delivery model is owner-approved.
## 11. Not verified
No clean-machine REA install, agent runtime integration, app analysis with this kit, Evidence-to-report pipeline, security audit, dependency benchmark or product implementation has been performed.
