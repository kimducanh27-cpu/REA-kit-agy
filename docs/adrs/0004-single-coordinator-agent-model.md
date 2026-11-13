# Single Coordinator Agent Model with Optional Task-Scoped Subagents

- Status: accepted
- Deciders: Project Maintainers, REA-kit-agy Architects
- Date: 2026-11-13

Technical Story: P00-03, P00-08 (Agent governance, concurrency control, user interaction model)

## Context and Problem Statement

When designing AI-assisted software reverse-engineering and reconstruction systems, multi-agent architectures are frequently proposed to parallelize tasks: one agent decompiling, another reviewing security, a third interviewing the user, and a fourth writing code.

However, unconstrained multi-agent swarms introduce severe failure modes:
1. **Split-Brain State and Race Conditions:** Concurrent agents editing `.agents/state/active_case.json` or source files in `05_MA_NGUON_PHAT_TRIEN/` clobber changes and create irreconcilable merge conflicts.
2. **Chaotic User Communication:** Multiple agents messaging the human user simultaneously breaks conversational flow, causing confusion and cognitive overload.
3. **Runaway Token Burn:** Agents conversing in autonomous loops consume excessive API tokens without guaranteed convergence on exit gates.

What agent topology best ensures deterministic gate progression, robust concurrency control, and a seamless human experience for REA-kit-agy?

## Decision Drivers

* **Single Authoritative Accountability:** Exactly one agent must hold authority over gate transitions, case state mutations, and final code approvals.
* **Unified Human Interface:** The human user must communicate with a single, consistent agent persona who speaks clear, contextual Vietnamese.
* **Concurrency Safety:** Writes to operational state and project files must be strictly sequenced to prevent race conditions.
* **Scalable Workload Offloading:** Heavy, read-heavy, or embarrassingly parallel tasks (such as searching hundreds of smali files or running parallel verification suites) should be delegable to subagents without losing governance.
* **V1 Lean Footprint:** Avoid imposing heavy swarm infrastructure, complex distributed locks, or mesh networks for standard user workflows.

## Considered Options

* **Option 1: Autonomous Peer-to-Peer Swarm** — Equal peer agents coordinating autonomously via open message buses without a centralized orchestrator.
* **Option 2: Rigid Monolithic Single-Agent Only** — All tasks must be executed sequentially by a single agent thread; subagents are completely prohibited.
* **Option 3: Single Authoritative Coordinator Model with Optional Task-Scoped Subagents** — A designated primary coordinator agent holds exclusive authority over case state and user dialogue, with the ability to dispatch ephemeral subagents for isolated, bounded tasks.

## Decision Outcome

Chosen option: **Option 3: Single Authoritative Coordinator Model with Optional Task-Scoped Subagents**.

The architectural model establishes:
1. **Authoritative Primary Coordinator:**
   - The coordinator agent acts as the sole custodian of `.agents/state/active_case.json`.
   - The coordinator is the only agent permitted to ask questions to the user, present review deliverables, and approve gate advances (`GATE_01` through `GATE_06`).
   - The coordinator guides the user through the five core case stages:
     - `STAGE_01_DISCOVERY`
     - `STAGE_02_REVERSE_ENGINEERING`
     - `STAGE_03_PRODUCT_DEFINITION`
     - `STAGE_04_IMPLEMENTATION`
     - `STAGE_05_VALIDATION`

2. **Optional Task-Scoped Subagents:**
   - When a specific operation is computationally heavy, repetitive, or isolatable (e.g. deep analysis of multiple Android dex classes, running independent test suites, or drafting modular helper files), the coordinator may invoke a short-lived subagent.
   - Subagents operate on read-only inputs or isolated directory branches.
   - Subagents do NOT communicate directly with the end user and do NOT mutate `active_case.json`.
   - Subagents report their findings/artifacts back to the coordinator, who validates, integrates, and commits the result.
   - No forced swarm is mandated for V1: standard cases run smoothly with the coordinator alone.

### Positive Consequences

* **Deterministic State Integrity:** Zero risk of concurrent file corruption or conflicting updates to `active_case.json`.
* **Clean, Human-Friendly UX:** The user enjoys a coherent, respectful conversational experience with one agent in Vietnamese.
* **Resource Optimization:** Subagents are spawned only when justified by workload complexity, saving token quota and execution time.
* **Clear Debugging and Tracing:** Logs and transcripts follow a single linear narrative rather than interleaved, chaotic multi-agent transcripts.

### Negative Consequences

* **Sequential Bottlenecks on Large Tasks:** If the coordinator chooses not to dispatch subagents, large-scale refactoring must proceed sequentially.
* **Coordinator Responsibility Load:** The primary coordinator prompt must encompass stage lifecycle rules and quality gate criteria.

## Pros and Cons of the Options

### Option 1: Autonomous Peer-to-Peer Swarm

* Good, highly decoupled theoretical architecture.
* Bad, frequent split-brain states, race conditions, and circular debates among agents.
* Bad, confusing and fragmented conversational experience for the human user.
* Bad, extremely difficult to reproduce bugs or verify gate transitions deterministically.

### Option 2: Rigid Monolithic Single-Agent Only

* Good, simplest possible implementation.
* Bad, cannot parallelize time-consuming searches across large decompiled codebases.
* Bad, risks polluting the primary agent's context window with intermediate raw scratch data.

### Option 3: Single Authoritative Coordinator Model with Optional Task-Scoped Subagents

* Good, combines absolute state consistency with on-demand parallel execution power.
* Good, human user always knows who is speaking and who is accountable.
* Good, subagents remain lightweight and disposable workers reporting to a strict supervisor.
* Good, lean V1: works out of the box in single-agent environments without requiring swarm setups.
* Bad, requires the coordinator to carefully synthesize subagent outputs before committing.

## Links

* References:
  - [ARCHITECTURE.md](../ARCHITECTURE.md) (Section 1: System Boundary)
  - [WORKFLOW_LIFECYCLE.md](../WORKFLOW_LIFECYCLE.md) (Lifecycle Stages and Gate Model)
  - [AGENTS.md](../../AGENTS.md) (Core Agent Rules & Operating Principles)
  - [ADR-0003: Hybrid Memory Architecture](0003-hybrid-memory-architecture.md)
