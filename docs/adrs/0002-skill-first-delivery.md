# Skill-First Delivery via Upstream MCP and Native Orchestration Skills

- Status: accepted
- Deciders: Project Maintainers, REA-kit-agy Architects
- Date: 2026-11-13

Technical Story: P00-07 (Delivery Model: Skill-first vs Thin CLI Wrapper vs Custom Engine Fork)

## Context and Problem Statement

The upstream Reverse Engineering Anything (REA) project provides a rich reverse-engineering and evidence-collection capability distributed as an npm package (`rea-agents`), a Model Context Protocol (MCP) server, and an agent skill (`reverse-engineer-anything`).

To deliver REA-kit-agy—providing localized Vietnamese workflows, human-in-the-loop interview gates, quality audits, and rebuild generation—we must choose how to package and distribute the kit to end users and coding agents (Antigravity, Gemini CLI, Claude Code, Cursor):
1. Should we develop a standalone CLI executable or npm wrapper (`rea-kit-cli`) that manages the entire lifecycle?
2. Should we fork and modify upstream REA's TypeScript analysis engine?
3. Or should we adopt a "Skill-First" architecture that uses standard agent Skills, native Markdown rules, lightweight PowerShell helper scripts, and connects directly to upstream REA via local stdio MCP?

## Decision Drivers

* **Frictionless Onboarding:** Developers and analysts should be able to clone or open the workspace and immediately begin working without compiling binaries or setting up background daemons.
* **Separation of Concerns:** Upstream REA specializes in low-level binary decompilation, provider execution, and raw evidence extraction. REA-kit-agy specializes in Vietnamese orchestration, quality gates, interactive user interviews, and application reconstruction.
* **Upstream Synchronization:** Upstream REA evolves rapidly. Any architecture that tightly couples to REA's internal TypeScript codebase risks breaking changes and heavy maintenance debt.
* **Avoidance of Premature Abstraction:** Introducing a custom CLI wrapper before workflows, schemas, and user interactions stabilize introduces packaging, OS compatibility, Node/binary versioning, and testing obligations without demonstrable user value.
* **Agent Native Integration:** Modern coding agents (such as Antigravity) are designed to read agent instruction files (`AGENTS.md`, `.agents/rules/`, `.agents/skills/`) natively.

## Considered Options

* **Option 1: Custom Engine Fork** — Fork `morluto/rea`, modify tool definitions, translate outputs into Vietnamese internally, and distribute custom builds.
* **Option 2: Standalone CLI Wrapper (`rea-kit-cli`)** — Build a Node.js or Go command-line wrapper binary that wraps REA CLI, manages git branches, executes validations, and exposes custom CLI subcommands.
* **Option 3: Skill-First Delivery with Upstream Stdio MCP and Native Agent Skills** — Consume upstream REA as an unmodified local stdio MCP server; orchestrate all Vietnamese workflows via native agent skills (`rea-scan`, `rea-audit`, `rea-interview`, `rea-plan`, `rea-build`, `memory-consolidation`), Markdown prompt templates, and lightweight PowerShell scripts (`.agents/scripts/`).

## Decision Outcome

Chosen option: **Option 3: Skill-First Delivery with Upstream Stdio MCP and Native Agent Skills**.

The architecture delegates tool execution entirely to upstream REA via local stdio MCP (`tools/list`, `binary_session`, `discover_tools`). REA-kit-agy encapsulates the orchestration logic into six domain-specific Vietnamese skills plus the upstream REA skill:
1. `rea-scan`: Stage 01 intake preflight, baseline capture, and Stage 02 Step 03–04 investigation.
2. `rea-audit`: Stage 02 Step 05 independent evidence audit, coverage scoring, and Unknowns ledger (Gate 02).
3. `rea-interview`: Stage 03 Step 06–07 user interview, build strategy/route selection, and frozen specification.
4. `rea-plan`: Stage 03 Step 08 6-Vertical-Slice atomic implementation planning (Gate 03).
5. `rea-build`: Stage 04–05 code generation, independent QA (`verify_code.ps1`), 1-to-1 Hard Verify, and release handoff (Gates 04–06).
6. `memory-consolidation`: Anthropic 4-layer memory dreaming, retroactive drift correction, and index maintenance.

Operational tasks requiring deterministic execution (health checks, test verification, backup/rollback, and ADR inspection) are handled by transparent, dependency-free PowerShell scripts in `.agents/scripts/`.

No custom binary or npm package wrapper will be developed for V1.

### Positive Consequences

* **Immediate Usability:** Zero compilation or background server setup; works immediately in Antigravity or any compatible coding agent workspace.
* **Zero Fork Maintenance:** Upstream REA updates can be pulled directly (`npm update -g rea-agents`) without breaking REA-kit-agy's orchestration layer.
* **Full Context Control:** Prompts, interview logic, and verification rules remain transparent Markdown files that developers can inspect, customize, and audit directly.
* **Clean Tool Protocol:** Interaction with REA occurs via standard MCP JSON-RPC, preserving official Evidence schemas, IDs, and provenance fields.

### Negative Consequences

* **Agent Dependency:** Non-agent usage (e.g. headless CI batch runs without an LLM agent) requires calling the underlying PowerShell scripts directly rather than a single unified CLI binary.
* **Shell Environment Requirements:** PowerShell 7+ or Windows PowerShell 5.1 is required for local script execution on Windows hosts.

## Pros and Cons of the Options

### Option 1: Custom Engine Fork

* Good, allows deep low-level modifications to REA analysis algorithms.
* Bad, creates enormous merge conflict burdens whenever upstream REA releases new features or bug fixes.
* Bad, violates the principle of orchestration over engine forking.

### Option 2: Standalone CLI Wrapper

* Good, provides a single branded terminal binary (e.g. `rea-kit run`).
* Bad, adds heavy overhead: Node.js/Go dependencies, npm packaging, binary distribution for multiple operating systems, and separate test suites.
* Bad, creates an unnecessary layer of indirection between the agent and upstream MCP tools.
* Bad, premature: wraps workflows before user feedback on prompt ergonomics has matured.

### Option 3: Skill-First Delivery with Upstream Stdio MCP and Native Agent Skills

* Good, cleanest integration surface with Antigravity and modern LLM coding agents.
* Good, upstream REA remains an independent tool provider; evidence schemas and tool capabilities remain canonical.
* Good, high auditability: all orchestration prompts and workflows are plain text in Vietnamese.
* Good, minimal code to maintain—only declarative skills, markdown rules, and focused PowerShell utilities.
* Bad, requires agents with native skill and MCP support.

## Links

* Resolves: Task P00-07 (Skill-first vs Thin CLI Wrapper)
* References:
  - [ARCHITECTURE.md](../ARCHITECTURE.md) (Section 1: System Boundary, Section 8: Deferred Choices)
  - [PRD.md](../PRD.md) (Delivery Model Specification)
  - [ADR-0001: Multi-Target Architecture](0001-multi-target-architecture.md)
  - [ADR-0003: Hybrid Memory Architecture](0003-hybrid-memory-architecture.md)
