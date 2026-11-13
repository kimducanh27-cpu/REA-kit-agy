# Multi-Target Architecture with Single Verified Target Class for V1

- Status: accepted
- Deciders: Project Maintainers, REA-kit-agy Architects
- Date: 2026-11-13

Technical Story: P00-05, P00-06 (Multi-target taxonomy vs V1 execution scope)

## Context and Problem Statement

Upstream Reverse Engineering Anything (REA) supports a wide spectrum of target types: packaged applications (Electron ASAR, Android APK, .NET binaries, Mach-O/ELF), web applications via passive Chrome DevTools Protocol (CDP), live device runtimes via ADB, and raw source code repositories.

When building REA-kit-agy—a Vietnamese-first autonomous agent kit designed to orchestrate reverse engineering, requirement clarification, and application reconstruction—a fundamental tension emerges:
1. If the kit claims full multi-target support on day one across Android, Electron, Web SPA, and native binaries, testing and verification become fragmented, resulting in shallow prompts, brittle edge cases, and unreliable rebuilds.
2. Conversely, if the kit is designed purely as an Android-only tool, the code, schemas, and prompts become tightly coupled to mobile concepts, preventing future expansion to Web, Desktop, and Cloud targets.

How should REA-kit-agy design its target intake, routing, and verification architecture to support a broad target taxonomy while guaranteeing deep, production-grade quality in its initial release?

## Decision Drivers

* **Quality of Verification:** Every supported target class must provide deterministic, evidence-backed intake, analysis, QA, and rebuild gates without hallucination or mock-only steps.
* **Pluggable Taxonomy:** The core architectural contracts (intake, classification, evidence mapping, state machines, templates) must be decoupled from target-specific execution mechanics.
* **Upstream REA Compatibility:** Must leverage upstream REA provider discovery (`tools/list`, `binary_session`, capability matrices) rather than inventing disconnected abstraction layers.
* **Resource and Maintenance Feasibility:** Limit V1 scope to an end-to-end verifiable slice so that error recovery, security boundaries, and user workflows achieve high reliability.
* **Graceful Degradation:** When an unsupported or secondary target is provided, the kit must clearly report missing prerequisites or guide the user to upstream tools rather than failing silently.

## Considered Options

* **Option 1: Broad Multi-Target Support in V1** — Implement generic prompts and handlers for Android APK, Web SPA, Electron ASAR, and Native Binaries simultaneously in the initial release.
* **Option 2: Single-Target Hardcoded Monolith** — Restrict the entire project, schemas, and directory structure exclusively to Android APK without multi-target taxonomy.
* **Option 3: Multi-Target Pluggable Architecture with Single Verified Target Class (Android APK) in V1** — Formalize the complete multi-target taxonomy and routing interface in architecture and state contracts, but strictly gate and thoroughly verify only `ANDROID_APK` as the V1 production target class.

## Decision Outcome

Chosen option: **Option 3: Multi-Target Pluggable Architecture with Single Verified Target Class (Android APK) in V1**.

We establish a modular target taxonomy in `.agents/state/active_case.json` and `docs/ARCHITECTURE.md` comprising:
- `ANDROID_APK` (V1 Target: Fully integrated, tested, and verified end-to-end)
- `WEB_SPA` (Planned V2: Chrome CDP passive observation, bundle extraction)
- `ELECTRON_DESKTOP` (Planned V2: ASAR unpacking, main/renderer process inspection)
- `NATIVE_BINARY` (Planned V3: Ghidra/PE/ELF inspection via upstream REA providers)
- `SOURCE_REPO` (Integrated fallback: Standard coding-agent source inspection per REA recommendations)

For V1, all automated testing, validation scripts, intake guides, and template workflows are tuned and hard-verified for `ANDROID_APK`. Any attempt to run other targets transitions into an informative `UNSUPPORTED_TARGET_PREFLIGHT` notification explaining required capabilities and falling back to direct REA MCP tools.

### Positive Consequences

* **Clarity of Focus:** Engineering resources concentrate on perfecting the complete decompilation-to-reconstruction loop for Android applications before tackling heterogeneous runtime environments.
* **Clean Architectural Boundaries:** Prevents Android-specific assumptions (e.g. `apktool`, `AndroidManifest.xml`, `dex2jar`) from polluting core state management (`active_case.json`) or general template structures.
* **Zero Technical Debt on Expansion:** Future target adapters (e.g. `WEB_SPA` or `ELECTRON_DESKTOP`) plug into standardized lifecycle stages (`STAGE_01_DISCOVERY` to `STAGE_05_VALIDATION`) without refactoring case state machines or agent roles.
* **Accurate User Expectations:** Transparent capability reporting prevents user frustration with half-baked features on unsupported formats.

### Negative Consequences

* **Delayed Multi-Platform Adoption:** Users seeking immediate turnkey assistance for Electron or Web targets must rely on raw upstream REA commands rather than the guided Vietnamese orchestration kit until V2.

## Pros and Cons of the Options

### Option 1: Broad Multi-Target Support in V1

* Good, because it showcases the full breadth of REA capabilities immediately.
* Bad, because testing matrix complexity scales combinatorially (JVM, Node/Electron, Chrome CDP, Ghidra).
* Bad, because prompts become overly generic and dilute domain-specific rebuild instructions.
* Bad, because maintaining high-confidence security reviews across multiple disparate binary models simultaneously in V1 is unfeasible.

### Option 2: Single-Target Hardcoded Monolith

* Good, because it is straightforward to write without abstract interfaces.
* Bad, because all schemas, folder names, and rules become tied to Android terminologies (e.g. Activities, Intents, Gradle).
* Bad, because supporting Web or Electron later would require a complete rewrite of the kit's core logic.

### Option 3: Multi-Target Pluggable Architecture with Single Verified Target Class (Android APK) in V1

* Good, because it establishes clean taxonomy, separation of concerns, and extensible contracts from Day 1.
* Good, because it provides a rock-solid, production-tested vertical slice for real-world Android modernization.
* Good, because other target types receive safe preflight validation and helpful fallback guidance rather than unhandled exceptions.
* Bad, requires disciplined adherence to abstract target routing interfaces even when only one target class is active in V1.

## Links

* Supersedes: Initial unconstrained multi-target proposal in preliminary design notes.
* References:
  - [ARCHITECTURE.md](../ARCHITECTURE.md) (Section 5: Target Routing Examples)
  - [PRD.md](../PRD.md) (Target Class Scope)
  - [ADR-0005: Android APK as Initial Target Class](0005-android-apk-first-target-via-android-cli.md)
