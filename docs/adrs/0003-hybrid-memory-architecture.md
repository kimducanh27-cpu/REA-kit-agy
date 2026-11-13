# Four-Tier Hybrid Memory Architecture for Local-First Privacy-Preserving Agentic Cases

- Status: accepted
- Deciders: Project Maintainers, REA-kit-agy Architects
- Date: 2026-11-13

Technical Story: P00-04, P00-08 (State persistence, context optimization, local privacy guarantees)

## Context and Problem Statement

Reverse-engineering packaged applications and implementing rebuilt source code generates substantial volume: decompiled Java/smali files, APK manifests, asset listings, REA evidence objects, user interview transcripts, and test logs. 

Simultaneously, two conflicting constraints govern agentic execution:
1. **Context Window Limits:** Language model token windows degrade in reasoning fidelity and spike in operational cost when flooded with hundreds of thousands of lines of raw disassembly or intermediate logs.
2. **Data Privacy and IP Confidentiality:** Binaries analyzed in `01_THA_APP_VAO_DAY` frequently contain proprietary algorithms, sensitive enterprise logic, or confidential assets. Transmitting case data to cloud vector databases, SaaS observability platforms, or unvetted external storage violates core security boundaries.

How should REA-kit-agy structure its state persistence and memory model to ensure seamless session continuity and token efficiency while maintaining 100% local-first data privacy?

## Decision Drivers

* **Strict Local-First Privacy:** Case files, decompiled code, evidence, and user decisions must never leave the local workstation; zero external cloud database or telemetry dependencies.
* **Deterministic Session Continuity:** Work must survive agent interruptions, IDE restarts, or model context resets without losing user interview answers, gate status, or previous scan results.
* **Context Budget Optimization:** Raw evidence and decompiled files must be queried on-demand; the active conversation context should only hold concise, high-signal state representations.
* **Auditability and Rollback Safety:** Every gate transition, architectural decision, and code modification must be traceably recorded and reversible.

## Considered Options

* **Option 1: In-Memory / Ephemeral Context Only** — Retain all state solely within the active chat thread. Lose state upon restart or context compaction.
* **Option 2: External Database / Cloud Vector Store** — Store case embeddings, logs, and state in a hosted vector store (e.g. Pinecone, Chroma Cloud, or managed PostgreSQL).
* **Option 3: Four-Tier Local Hybrid Memory Architecture** — Segment memory into four distinct, file-persisted local tiers: Event Log (Tier 1), Operational State (Tier 2), Durable Knowledge (Tier 3), and Injected Context (Tier 4).

## Decision Outcome

Chosen option: **Option 3: Four-Tier Local Hybrid Memory Architecture**.

The system partitions case memory into four complementary tiers, all residing strictly in local workspace storage:

### Tier 1: Event Log (Append-Only Audit Ledger)
- **Files:** Git commit history, `.agents/state/events.jsonl`, local conversation transcripts.
- **Role:** Immutable, append-only record of every command executed, tool invoked, gate checked, and backup taken. Guarantees forensic auditability and enables atomic rollback via `.agents/scripts/rollback.ps1`.

### Tier 2: Operational State (Dynamic Single Source of Truth)
- **Files:** `.agents/state/active_case.json`.
- **Role:** Compact, low-latency JSON object representing current execution status:
  - `case_id`, `target_name`, `target_class`
  - `current_phase`, `current_step`, `current_gate_status`
  - `gates` checklist (boolean verification flags for Gate 01 through Gate 06)
  - `artifacts` mapping (file paths to generated reports, specs, and bundles)
  - `metrics` (coverage score, unknown count, risk level, review rounds)
- Read and mutated by the primary coordinator agent at stage transitions.

### Tier 3: Durable Knowledge (Repository-Level Rules & Blueprints)
- **Files:** `.agents/state/learned_rules.json`, `docs/adrs/`, `docs/ARCHITECTURE.md`, `templates/`.
- **Role:** Cross-session institutional memory. Stores domain heuristics (e.g. `RULE-INIT-001` form preservation), architectural invariants, approved design tokens, and verified templates. Survives case resets and informs future analyses.

### Tier 4: Injected Context (Ephemeral Task-Scoped Working Memory)
- **Files:** `prompts/*.md`, active template instances, dynamic skill guidelines.
- **Role:** Just-in-time contextual prompt segments injected into the LLM context window during specific tasks. Keeps active context small, highly focused, and free of unnecessary background noise.

### Positive Consequences

* **Complete Privacy Compliance:** Zero bytes leave the local filesystem; compliant with strict enterprise data residency and NDA requirements.
* **Rock-Solid Crash Recovery:** If a terminal session dies or the agent window is refreshed, reading `.agents/state/active_case.json` immediately restores exact phase, step, gate, and next action pointers.
* **Lean Token Consumption:** Heavy decompiled artifacts remain on disk in `03_KET_QUA_KIEM_TRA/` and are read selectively via targeted tool calls rather than dumped into conversation prompts.
* **Deterministic Gate Enforcement:** Quality gates are explicit boolean checks recorded in Tier 2, preventing agents from skipping validation steps.

### Negative Consequences

* **Filesystem Serialization Overhead:** The agent must reliably update `.agents/state/active_case.json` when transitioning across stages.
* **Schema Evolution Discipline:** Changes to `active_case.json` structure require schema versioning (`revision` field) to ensure backward compatibility across case revisions.

## Pros and Cons of the Options

### Option 1: In-Memory / Ephemeral Context Only

* Good, requires no filesystem state files.
* Bad, catastrophic context loss on session crash, context truncation, or agent reload.
* Bad, impossible to verify compliance or audit historical decisions.

### Option 2: External Database / Cloud Vector Store

* Good, enables global search across large multi-user deployments.
* Bad, introduces severe privacy leaks when analyzing confidential proprietary applications.
* Bad, requires complex credentials, network connectivity, API keys, and external service maintenance.

### Option 3: Four-Tier Local Hybrid Memory Architecture

* Good, 100% private, self-contained, and local-first.
* Good, separates high-volume audit logs (Tier 1) from machine-readable state (Tier 2) and enduring guidelines (Tier 3).
* Good, minimizes prompt token consumption by keeping Tier 4 lean and on-demand.
* Bad, requires disciplined adherence to state-updating protocols by the orchestrator agent.

## Links

* References:
  - [ARCHITECTURE.md](../ARCHITECTURE.md) (Section 6: Per-App Case Record)
  - [.agents/state/active_case.json](../../.agents/state/active_case.json)
  - [.agents/state/learned_rules.json](../../.agents/state/learned_rules.json)
  - [ADR-0004: Single Coordinator Agent Model](0004-single-coordinator-agent-model.md)
  - [ADR-0006: CLI ADR Management](0006-cli-adr-management.md)
