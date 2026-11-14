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

* **Strict Local-First Workspace Persistence:** Case files, decompiled code, evidence, and user decisions are stored strictly in local files; no external cloud database or hosted telemetry services are required.
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

### Layer 1: Transcripts & Event Logs (Ground-Truth Session Ledger)
- **Files:** `.agents/state/events.jsonl` (append-only JSONL event log), `.agents/state/cases/session_<TIMESTAMP>.md`, Git commit history.
- **Role:** Searchable event log of commands executed, REA Evidence IDs collected, test verdicts, and user decisions. Serves as the ground-truth baseline for retroactive verification during offline consolidation (*Dreaming*).

### Layer 2: Memory Notes (Salient Observations, Strategies & Trap Warnings)
- **Files:** `.agents/state/MEMORY.md` (Verified Memory Notes table) and `.agents/state/learned_rules.json`.
- **Role:** Stores provenance-verified technical rules, working tool configurations, architectural decisions, and failure/recovery traps (never restricted to failures-only, per Anthropic's CL-Bench findings).

### Layer 3: Memory Representations (Interlinked Knowledge Wiki)
- **Files:** `docs/WORKFLOW_LIFECYCLE.md`, `docs/ARCHITECTURE.md`, `docs/SOURCE_AUDIT.md`, `docs/adrs/0001..0006`, `templates/`.
- **Role:** Structured, cross-linked documentation maps that organize domain architecture and lifecycle specifications across sessions.

### Layer 4: Injected Context & Operational State (Preemptively Loaded Session Header)
- **Files:** `.agents/state/active_case.json` (6-Gate / 14-Step operational state machine), `AGENTS.md`, `docs/HANDOFF.md`, and the compact `MEMORY.md` index (strictly capped at `<= 200 lines` or `25 KB` per Claude Code Auto-Memory standards).
- **Role:** Preemptively loaded at the start of every session (`prompts/00-SESSION-CONTINUITY.md`) so the agent immediately knows current case state, verified rules, and where to find deeper Layer 2/3 records.

### Positive Consequences

* **Local Storage Privacy:** All case files, evidence, and state ledgers remain on the local filesystem without external database dependencies; model context egress depends on the configured agent provider, with secret redaction applied prior to context injection.
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
