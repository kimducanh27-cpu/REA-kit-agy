# Android APK as Initial Target Class via Antigravity Android CLI Plugin and REA Tools

- Status: accepted
- Deciders: Project Maintainers, REA-kit-agy Architects
- Date: 2026-11-13

Technical Story: P00-06 (Selection of First End-to-End Target Class and Tooling Stack)

## Context and Problem Statement

To deliver a production-ready, fully verifiable V1 slice of REA-kit-agy, we must select an initial target application class. The chosen target must support the complete lifecycle from binary drop in `01_THA_APP_VAO_DAY` to static analysis, dynamic observation, user interview, code reconstruction in `05_MA_NGUON_PHAT_TRIEN`, and automated verification.

Candidate target classes include:
1. **Web SPA:** JavaScript/TypeScript single-page applications observed via Chrome DevTools Protocol (CDP).
2. **Electron Desktop:** Cross-platform desktop apps with ASAR archives and Chromium/Node runtimes.
3. **Android APK:** Compiled Android packages (`.apk`) containing Dalvik/ART dex bytecode, `AndroidManifest.xml`, compiled resources, and native libraries.

Which target class offers the optimal balance of rich structural metadata, mature tool ecosystems, native agent integration, and high real-world value for V1?

## Decision Drivers

* **Structural Richness:** The target format must expose clear manifests, declarative permissions, exported components (activities, services, receivers), and inspectable assets to feed high-confidence REA Evidence generation.
* **Native Agent Ecosystem Synergies:** Maximize leverage of Antigravity's built-in plugins (specifically the official `android-cli-plugin`) rather than requiring users to manually configure custom toolchains.
* **Upstream REA Tool Maturity:** Align with upstream REA's verified static decompilation tools (`apktool`, `jadx`, `apkanalyzer`) and dynamic ADB observation capabilities.
* **Real-World Vietnamese Market Need:** High demand among developers and businesses in Vietnam for auditing, decompiling, localizing, and modernizing legacy Android applications.
* **Deterministic Verification Environment:** Ability to launch headless or emulated runtimes (Android Virtual Devices - AVDs) for automated test verification and UI layout inspection.

## Considered Options

* **Option 1: Web SPA Target via Chrome CDP** — Focus V1 on inspecting web applications via passive Chrome DevTools Protocol observation.
* **Option 2: Electron Desktop Application via ASAR** — Focus V1 on unpacking and analyzing Electron desktop bundles.
* **Option 3: Android APK via Antigravity Android CLI Plugin and Upstream REA Tools** — Focus V1 on Android APK binaries, combining Antigravity's native `android-cli-plugin` with upstream REA's static APK and dynamic ADB capabilities.

## Decision Outcome

Chosen option: **Option 3: Android APK via Antigravity Android CLI Plugin and Upstream REA Tools**.

We designate `ANDROID_APK` as the sole officially verified target class for V1. The end-to-end tooling architecture integrates two complementary engines:

1. **Upstream REA Engine (Analysis & Evidence):**
   - Static APK unpacking via `apktool` (decoding resources, `AndroidManifest.xml`, layouts).
   - Java/Kotlin decompilation via `jadx` or bytecode inspection via `baksmali`.
   - Structural evidence extraction: component trees, permission graphs, hardcoded endpoints, and SDK dependencies.
   - Dynamic device inspection via REA's ADB tools when an authorized device is attached.

2. **Antigravity Android CLI Plugin (`android-cli-plugin`):**
   - Android SDK and build-tools environment discovery and path resolution.
   - Emulator lifecycle management (AVD creation, boot, headless test runner).
   - Device Hub for physical device connection, screen streaming, and logcat filtering.
   - UI layout hierarchy dumping and accessibility tree inspection.
   - Gradle build and test execution for rebuilt source code in `05_MA_NGUON_PHAT_TRIEN`.

This synthesis creates an end-to-end pipeline: drop an `.apk` file into `01_THA_APP_VAO_DAY`, inspect and report findings into `03_KET_QUA_KIEM_TRA`, define modernization scope in `02_YEU_CAU_CUA_TOI`, and build modern Android code (Jetpack Compose / Kotlin) verified via `KIEM_TRA.bat`.

### Positive Consequences

* **Unmatched Depth of Evidence:** Android manifests and bytecode provide deterministic component listings, permission models, and package identities, eliminating guesswork.
* **Zero External Tool Friction:** Antigravity users can leverage the built-in Android CLI plugin without hunting for manual ADB path configurations or ad-hoc shell wrappers.
* **Robust Verification Loop:** Rebuilt source code in `05_MA_NGUON_PHAT_TRIEN` can be compiled into a fresh APK via Gradle and test-run on an AVD emulator, providing verifiable closure.
* **Clear Path for V2 Expansion:** Lessons learned from Android bytecode and manifest parsing directly inform future Web and Electron adapters.

### Negative Consequences

* **Host Machine Requirements:** Full dynamic verification (AVD emulator execution) requires hardware virtualization (VT-x / AMD-V) and adequate RAM (8GB+ free).
* **Static Fallback Necessary:** When an AVD is unavailable or cannot boot on constrained machines, the kit must gracefully fall back to static analysis (`jadx` / `apktool`) without blocking the user.

## Pros and Cons of the Options

### Option 1: Web SPA Target via Chrome CDP

* Good, requires lightweight browser instances.
* Bad, heavily minified/obfuscated JavaScript bundles (Webpack, Vite) without source maps often yield poor decompilation quality compared to typed Java/Kotlin bytecode.
* Bad, does not provide standard manifest structures equivalent to `AndroidManifest.xml`.

### Option 2: Electron Desktop Application via ASAR

* Good, ASAR archives are easily unpacked into Node.js source files.
* Bad, native binary modules (`.node`) and cross-platform native bindings introduce severe OS-specific build failures.
* Bad, lacks the rich emulator ecosystem and standardized UI inspection that Android CLI provides.

### Option 3: Android APK via Antigravity Android CLI Plugin and Upstream REA Tools

* Good, highest fidelity of reverse-engineering evidence: package hierarchy, activity flows, resource mappings, permissions.
* Good, seamlessly taps into Antigravity's native `android-cli-plugin` for SDK/AVD/Device Hub management.
* Good, upstream REA already maintains extensive Android ADB and APK provider references.
* Good, provides a complete, tangible software modernization path (e.g. legacy Java APK -> modern Jetpack Compose project).
* Bad, heavy host requirements for emulator-based dynamic verification.

## Links

* Resolves: Task P00-06 (Select first end-to-end target class)
* References:
  - [ADR-0001: Multi-Target Architecture](0001-multi-target-architecture.md)
  - [ADR-0002: Skill-First Delivery](0002-skill-first-delivery.md)
  - [ARCHITECTURE.md](../ARCHITECTURE.md) (Section 5: Target Routing Examples)
  - [UPSTREAMS.md](../../UPSTREAMS.md)
  - Upstream REA Reference: `.agents/skills/reverse-engineer-anything/references/android-applications.md`
