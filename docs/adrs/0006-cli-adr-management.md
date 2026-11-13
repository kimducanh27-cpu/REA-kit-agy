# File-Persisted Markdown ADRs and CLI Management via PowerShell

- Status: accepted
- Deciders: Project Maintainers, REA-kit-agy Architects
- Date: 2026-11-13

Technical Story: Architecture Governance, Auditability, and CLI Discoverability

## Context and Problem Statement

As REA-kit-agy matures, foundational architectural decisions—such as target boundaries, delivery models, memory architectures, agent governance, and target platform priorities—must be recorded with unambiguous rationale. Without formal decision records, past design discussions are forgotten, leading to architectural regressions, contradictory PRs, and conflicting agent behaviors across chat sessions.

However, architectural tooling frequently introduces friction:
1. Web-based portals (Notion, Confluence, Jira, Backstage) detach architecture decisions from the Git repository, break offline agent access, and require API authentication.
2. Unstructured documentation (informal markdown notes or buried commit messages) lacks standardized metadata, making automated discovery and validation difficult for AI agents.
3. Third-party ADR tools (such as npm-based generators or Ruby/bash `adr-tools`) impose heavy runtime prerequisites on Windows developers and AI environments.

How should REA-kit-agy record and manage architectural decisions to ensure version-controlled permanence, machine readability, and frictionless CLI interaction without introducing external dependencies?

## Decision Drivers

* **Git-Native Version Control:** Architecture records must reside within the project repository alongside the code and schemas they govern.
* **Standardized Specification:** Adhere to the established Markdown Any Architectural Decision Records (MADR) format for consistent human reading and automated parsing.
* **Zero External Dependencies:** No Node.js packages, Ruby gems, Python wheels, Docker containers, or web servers required to create, inspect, or validate ADRs.
* **Native CLI Support:** Provide an intuitive PowerShell automation script (`.agents/scripts/adr.ps1`) that works out of the box on Windows and PowerShell Core.
* **Agent Context Friendliness:** Files must be concise, standard Markdown that can be selectively loaded into LLM prompts without excessive token consumption.

## Considered Options

* **Option 1: Centralized Cloud Wiki / Web Dashboard** — Store ADRs in an external service such as Notion, Confluence, or an internal portal.
* **Option 2: Third-Party CLI Tool (npm `adr-log` / bash `adr-tools`)** — Adopt an established third-party package requiring npm or bash/WSL to generate and view ADRs.
* **Option 3: Repository Markdown ADRs in MADR Format with Native PowerShell Helper (`adr.ps1`)** — Persist ADRs as plain Markdown files in `docs/adrs/` following MADR conventions, managed and audited via a native `.agents/scripts/adr.ps1` script.

## Decision Outcome

Chosen option: **Option 3: Repository Markdown ADRs in MADR Format with Native PowerShell Helper (`adr.ps1`)**.

The architectural decision management system consists of:

1. **Storage Location and Naming:**
   - All records are placed in `docs/adrs/`.
   - Naming follows the four-digit sequential convention: `NNNN-slug-title.md` (e.g. `0001-multi-target-architecture.md`).

2. **MADR Structural Standard:**
   Each record must contain:
   - Header with `# Title`
   - Metadata list: `- Status:`, `- Deciders:`, `- Date:`
   - `Technical Story:` reference
   - `## Context and Problem Statement`
   - `## Decision Drivers`
   - `## Considered Options`
   - `## Decision Outcome`
   - `### Positive Consequences` and `### Negative Consequences`
   - `## Pros and Cons of the Options`
   - `## Links`

3. **Native PowerShell Management Utility (`.agents/scripts/adr.ps1`):**
   - Implements zero-dependency CLI operations:
     - `.\adr.ps1` or `.\adr.ps1 list`: Displays a formatted status table of all ADRs (ID, Title, Status, Date).
     - `.\adr.ps1 show <ID>`: Displays full contents or detailed summary of an ADR by number or filename.
     - `.\adr.ps1 validate`: Audits all ADR files in `docs/adrs/` for MADR schema compliance.
     - `.\adr.ps1 status`: Summarizes counts of accepted, proposed, deprecated, and superseded decisions.

### Positive Consequences

* **Complete Offline and Local Access:** Architecture decisions are always available to offline developers and local AI coding agents.
* **Zero Dependency Footprint:** Relies purely on native PowerShell string and regex parsing; no `npm install` or system packages needed.
* **Continuous Auditability:** The `validate` command can be integrated into pre-commit hooks or `.agents/scripts/health_check.ps1` to prevent ill-formed decision documents.
* **Transparent Traceability:** Every change to an ADR is captured in Git diffs with author attribution and commit history.

### Negative Consequences

* **Manual Sequence Allocation:** Numbering sequence (e.g. `0007`) must be selected sequentially when adding new ADRs (though helper scripts can assist).

## Pros and Cons of the Options

### Option 1: Centralized Cloud Wiki / Web Dashboard

* Good, rich graphical interface and collaborative web editing.
* Bad, disconnected from Git commits and branches.
* Bad, inaccessible to local coding agents without custom API keys and network access.
* Bad, breaks offline development workflows.

### Option 2: Third-Party CLI Tool

* Good, pre-existing community tooling.
* Bad, requires bash or npm dependencies that may fail or conflict in restricted Windows or enterprise CI environments.
* Bad, unnecessary overhead for straightforward Markdown file operations.

### Option 3: Repository Markdown ADRs in MADR Format with Native PowerShell Helper (`adr.ps1`)

* Good, completely self-contained within the repository.
* Good, instantaneous execution with native PowerShell on Windows.
* Good, conforms to global MADR standard recognizable by any software architect.
* Good, perfectly suited for LLM retrieval via file reads.
* Bad, lacks rich web UI widgets (though Markdown renders natively in GitHub, GitLab, and IDEs).

## Links

* References:
  - MADR Standard: https://adr.github.io/madr/
  - Script Implementation: [.agents/scripts/adr.ps1](../../.agents/scripts/adr.ps1)
  - [ADR-0001: Multi-Target Architecture](0001-multi-target-architecture.md)
  - [ADR-0002: Skill-First Delivery](0002-skill-first-delivery.md)
  - [ADR-0003: Hybrid Memory Architecture](0003-hybrid-memory-architecture.md)
  - [ADR-0004: Single Coordinator Agent Model](0004-single-coordinator-agent-model.md)
  - [ADR-0005: Android APK as Initial Target Class](0005-android-apk-first-target-via-android-cli.md)
