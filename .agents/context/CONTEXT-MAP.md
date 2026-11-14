# CONTEXT MAP — REA-kit-agy Context Subsystem Index

- Status: ACTIVE
- Version: 1.0
- Scope: Directory overview, asset index, load policies, profile routing, and tooling reference.

---

## 1. Directory Structure

The `.agents/context/` directory governs deterministic runtime context injection, budgeting, profile management, and compaction for REA-kit-agy:

```
.agents/context/
├── CONTEXT-MAP.md                  # This file: subsystem overview and complete asset index
├── context-manifest.json           # Authoritative manifest of workspace documents & load policies
├── profiles/                       # 6 Domain and lifecycle execution context profiles
│   ├── discovery.json              # Stage 01 Intake & Stage 02 Static baseline analysis
│   ├── optimization.json           # Performance, resource & battery optimization
│   ├── security.json               # Security audit, permission analysis & hardening
│   ├── feature-addition.json       # Stage 04 Reconstruction & feature addition
│   ├── design.json                 # Stage 03 UI/UX definition & anti-slop governance
│   └── validation.json             # Stage 05 Smoke test, hard verify & handoff
├── schemas/                        # Machine-readable JSON schemas
│   ├── context-packet.schema.json  # Schema for assembled agent runtime context packets
│   └── context-receipt.schema.json # Schema for verification receipts and compaction logs
├── plans/                          # (Generated) Context allocation plans from context.ps1 plan
├── packets/                        # (Generated) Assembled context packets from context.ps1 pack
└── receipts/                       # (Generated) Verified execution receipts from context.ps1 verify
```

---

## 2. Context Layer Mapping (L0 – L5)

Context is stratified into six hierarchical layers to maximize reasoning precision and prefix KV-cache reuse:

| Layer | Designator | Primary Role | Typical Assets | Cache Policy |
|---|---|---|---|---|
| **L0** | Operating Contract | Fundamental safety, read-only boundaries, invariants | `AGENTS.md`, `.agents/rules/core-safety.md`, `.agents/rules/rea-workflow.md` | Immutable Prefix (100% Cache Hit) |
| **L1** | Active Case State | Deterministic state machine & audit trail | `.agents/state/active_case.json`, `.agents/state/events.jsonl` | Monotonic State Machine |
| **L2** | Domain & Execution Profile | Stage-specific rules and target constraints | `.agents/rules/android-target.md`, `design-governance.md`, `profiles/*.json` | Quasi-Static (Swapped per stage) |
| **L3** | Durable Knowledge Wiki | Architecture, lifecycle, ADRs, memory notes | `docs/ARCHITECTURE.md`, `docs/WORKFLOW_LIFECYCLE.md`, `MEMORY.md` | Semi-Stable Reference |
| **L4** | Task Packet & Working Slice | Current task requirements, targeted code slices, specs | `02_YEU_CAU_CUA_TOI/`, `03_KET_QUA_KIEM_TRA/`, `.agents/context/packets/` | Dynamic Active Window |
| **L5** | Ephemeral Observations | Tool outputs, JADX excerpts, test logs | Raw CLI and MCP outputs | Volatile Turn Tail (FIFO Compaction) |

---

## 3. Context Manifest Policies & Modes

Defined in `.agents/context/context-manifest.json`:

### 3.1 Load Policies
- `ALWAYS`: Preemptively loaded in every agent prompt (L0 and L1).
- `CONDITIONAL`: Loaded when active stage, profile, or target class matches conditions.
- `ON_DEMAND`: Loaded only when explicitly invoked by task or agent inquiry.
- `NEVER_AUTO`: Heavy binary data (e.g. `01_THA_APP_VAO_DAY/`, `04_SAO_LUU_AN_TOAN/`) that must NEVER enter prompts directly.
- `DEPRECATED`: Legacy or superseded files; retained for history, never loaded.

### 3.2 Load Modes
- `FULL`: Complete file injected into context.
- `SECTION_RETRIEVAL`: Only relevant Markdown headers/sections matching task keywords are injected.
- `SUMMARY`: High-signal condensed digest injected (e.g., table of memory notes).
- `REFERENCE_ONLY`: Metadata and filesystem path passed; content read on demand via tool calls.

---

## 4. Domain Profile Routing

Profiles configure context bundles based on the current objective:

| Profile | Target Stages | Primary Focus | Included Rules |
|---|---|---|---|
| **`discovery.json`** | Stage 01, Stage 02 | App intake, APK extraction, manifest inspection, baseline setup | `core-safety.md`, `android-target.md` |
| **`optimization.json`** | Stage 02, Stage 04 | Memory leaks, battery drain, DEX size, performance profiling | `core-safety.md`, `android-target.md`, `implementation.md` |
| **`security.json`** | Stage 02, Stage 04 | Permission audit, exposed components, hardcoded secrets | `core-safety.md`, `android-target.md` |
| **`feature-addition.json`** | Stage 03, Stage 04 | Incremental logic, new screens, API wiring, reconstruction | `core-safety.md`, `android-target.md`, `implementation.md` |
| **`design.json`** | Stage 03 | Design tokens, anti-slop rules, Vietnamese copy deck, interview | `core-safety.md`, `design-governance.md` |
| **`validation.json`** | Stage 05 | Smoke tests, hard verification matrix, release handoff | `core-safety.md`, `release.md` |

---

## 5. CLI Tooling: `.agents/scripts/context.ps1`

Deterministic context assembly and verification is executed via PowerShell:

```powershell
# 1. Plan context allocation
.\.agents\scripts\context.ps1 plan -Task "<description>" [-Stage "<STAGE_ID>"]

# 2. Inspect plan details
.\.agents\scripts\context.ps1 inspect -PlanId "<PlanId>"

# 3. Assemble and pack the context bundle
.\.agents\scripts\context.ps1 pack -PlanId "<PlanId>"

# 4. Verify context packet and generate receipt
.\.agents\scripts\context.ps1 verify -PackId "<PackId>"
```

Refer to [docs/CONTEXT_ENGINEERING.md](../../docs/CONTEXT_ENGINEERING.md) for full architecture formulas and compaction protocols.
