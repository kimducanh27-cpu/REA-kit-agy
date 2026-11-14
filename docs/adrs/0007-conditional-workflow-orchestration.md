# Conditional Workflow Orchestration and Directed Acyclic Graph (DAG) Model

- Status: accepted
- Deciders: Project Maintainers, REA-kit-agy Architects
- Date: 2026-11-14

Technical Story: P00-01 to P00-06 (RWO v2, dynamic workflow routing, cascade invalidation, change request management)

## Context and Problem Statement

The initial release of REA-kit-agy (v1.0 / v1.1) defined a linear "Happy Path" lifecycle comprising 6 Stages and 14 sequential Steps (Stage 00 through Stage 05). In this model, every incoming case was assumed to advance monotonically along the single path:
`01 -> 02 -> 03 -> 04 -> 05 -> 06 -> 07 -> 08 -> 09 -> 10 -> 11 -> 12 -> 13`.

However, real-world reverse engineering and application reconstruction workloads deviate significantly from this linear assumption:
1. **Analysis-Only Scope (WF04):** Users frequently want application inspection, security scanning, or architecture reports without commissioning new code synthesis.
2. **Missing Runtime Environments (WF02):** Workstations lacking Android Virtual Devices (AVDs) or USB-connected devices cannot execute runtime baseline capture, yet can still proceed via static fallback.
3. **Mid-Flight Requirement Changes (WF06 / WF07):** Users alter UI preferences or business rules after specification freeze or after code synthesis, requiring targeted rollback rather than full workflow restarts.
4. **Targeted Upstream Evidence Retrieval (Re-entry / Rejoin):** During implementation (Stage 04), an agent may discover an unmapped API endpoint requiring a targeted scan (Stage 02) before resuming implementation.
5. **Cascade Invalidation Failures:** Rejection or invalidation of an upstream gate (e.g. Gate 01 or Gate 02) previously left downstream gates in false `PASS` states.

How can REA-kit-agy model complex, non-linear agent orchestration while preserving deterministic quality gates, auditability, and the Single Authoritative Coordinator invariant?

## Decision Drivers

* **Workflow Flexibility:** Accommodate diverse engagement modes (New Case, Resume, Change Request, Bugfix, Analysis-only, Plan-only) without forcing redundant steps.
* **Selective Invalidation (Closure Invariant):** When an input artifact or requirement changes, invalidate only the downstream closure affected by that change; preserve all valid, independent evidence.
* **Deterministic Gate FSM:** Support an expressive 11-state gate lifecycle (`NOT_STARTED`, `IN_PROGRESS`, `PASS`, `PASS_WITH_LIMITATIONS`, `SKIPPED`, `NOT_APPLICABLE`, `WAIVED`, `BLOCKED`, `FAILED`, `INVALIDATED`, `REUSED_VALIDATED`).
* **Evidence Integrity:** Strictly enforce that gates cannot transition to `PASS` without verified file evidence and computed SHA-256 hashes on disk.
* **Waiver Transparency:** Explicitly distinguish between full achievement (`PASS`), partial achievement (`PASS_WITH_LIMITATIONS`), and human-waived conditions (`WAIVED`); never silently transmute waivers into passes.
* **Zero Swarm Overhead:** Retain the proven Single Authoritative Coordinator topology established in ADR-0004 without spawning uncoordinated multi-agent swarms.

## Considered Options

* **Option 1: Rigid Monolithic Linear Pipeline** — Retain the strict 14-step linear pipeline; force all cases to execute every step or abort.
* **Option 2: Autonomous Multi-Agent Swarm with Dynamic Peer Routing** — Allow peer agents to dynamically negotiate tasks across a message board without centralized orchestration.
* **Option 3: REA Workflow Orchestrator (RWO) with Conditional DAG, Step Classification, and Selective Invalidation** — Elevate the Single Coordinator to execute a Directed Acyclic Graph (DAG) of tasks governed by explicit step classifications (`MANDATORY`, `CONDITIONAL`, `OPTIONAL`, `NOT_APPLICABLE`), cascade invalidation rules, and structured re-entry/rejoin mechanics.

## Decision Outcome

Chosen option: **Option 3: REA Workflow Orchestrator (RWO) with Conditional DAG, Step Classification, and Selective Invalidation**.

### Key Architectural Provisions:

1. **REA Workflow Orchestrator (RWO) Governance:**
   - The primary Coordinator assumes the RWO role, consulting `prompts/00-WORKFLOW-ROUTER.md` before invoking specialized local skills.
   - The RWO outputs a structured `Execution Plan` explicitly declaring mandatory, conditional, skipped, and reused steps prior to execution.

2. **Step Classification Matrix:**
   - `MANDATORY`: Core security, intake, verification, and audit steps that cannot be omitted.
   - `CONDITIONAL`: Context-dependent steps executed only when prerequisites exist (e.g. `03_REA_SCAN` for APKs vs source inspection for git repositories).
   - `OPTIONAL`: User-requested enhancements that may be bypassed without compromising delivery integrity.
   - `NOT_APPLICABLE`: Steps entirely outside the current case mode (e.g. code synthesis steps in `ANALYSIS_ONLY` mode).

3. **11-State Gate Lifecycle & Machine Enforcement:**
   - Expanded gate states in `.agents/scripts/gate.ps1` and `templates/10-CASE-MANIFEST-TEMPLATE.json`.
   - Gate transitions require cryptographic SHA-256 evidence validation.
   - `WAIVED` gates require explicit human owner reasoning and emit residual risk disclosures.
   - `PASS_WITH_LIMITATIONS` explicitly records fallback methods (such as 3-layer Static Fallback).

4. **Cascade Invalidation & Change Management:**
   - Automated cascade invalidation in `gate.ps1 reject` mapped across all 6 gates:
     - Gate 01 rejection invalidates Gates 01 through 06.
     - Gate 02 rejection invalidates Gates 02 through 06.
     - Gate 03 rejection invalidates Gates 03 through 06.
     - Gate 04/05 rejection invalidates Gates 04 through 06.
     - Gate 06 rejection invalidates Gate 06.
   - Formal Change Request protocol (`prompts/07-CHANGE-REQUEST.md`) and single source of truth mapping in `docs/WORKFLOW_DEPENDENCIES.md`.

5. **Optimistic Concurrency & Lineage Snapshotting:**
   - Atomic state writes via temporary swap files (`.tmp`).
   - Incremental revision counters preventing concurrent overwrite conflicts.
   - Run snapshots archived to `.agents/state/cases/<case_id>/runs/<run_id>.json`.

## Pros and Cons of the Options

### Option 1: Rigid Monolithic Linear Pipeline

* Good, straightforward to describe in static documentation.
* Bad, completely inflexible; fails when hardware environments lack AVDs or physical devices.
* Bad, cannot handle analysis-only, plan-only, or bugfix requests without forcing unnatural dummy executions.
* Bad, invalidation is all-or-nothing; minor requirement tweaks trigger wasteful re-decompilations.

### Option 2: Autonomous Multi-Agent Swarm with Dynamic Peer Routing

* Good, theoretically adaptable peer coordination.
* Bad, high token overhead, unpredictable circular loops, and split-brain active case state.
* Bad, human user loses single-point accountability.

### Option 3: REA Workflow Orchestrator (RWO) with Conditional DAG, Step Classification, and Selective Invalidation

* Good, combines full operational agility with deterministic single-coordinator accountability.
* Good, selectively invalidates only affected downstream artifacts (closure invariant), saving tokens and time.
* Good, distinguishes between PASS, PASS_WITH_LIMITATIONS, and WAIVED; never hides risks.
* Good, cleanly supports all 12 real-world scenarios (WF01 through WF12).
* Bad, requires coordinator prompts and scripts to maintain explicit dependency closure mappings.

## Links

* References:
  - [WORKFLOW_DEPENDENCIES.md](../WORKFLOW_DEPENDENCIES.md) (Dependency Graph & Invalidation Matrix)
  - [WORKFLOW_LIFECYCLE.md](../WORKFLOW_LIFECYCLE.md) (Orchestration Lifecycle)
  - [AGENTS.md](../../AGENTS.md) (Single Authoritative Coordinator & RWO Rules)
  - [ADR-0004: Single Coordinator Agent Model](0004-single-coordinator-agent-model.md)
