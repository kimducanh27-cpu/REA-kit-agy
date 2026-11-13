# ARCHITECTURE — REA-kit-agy

- Status: BASELINE / NOT IMPLEMENTED
- Last updated: 2026-11-13

## 1. Repository and product-workspace separation

There are two distinct folder trees:

1. This repository is the source repository used to develop and version the kit.
2. A generated user workspace is the folder tree the kit creates for the non-technical user.

The docs folder in this repository is reserved for project context, decisions, plans, handoffs, and progress. It must not become a container for application source code, generated workspace examples containing private data, or user deliverables.

Product source code, installer logic, skills, templates, tests, and packaging files belong in appropriate product directories outside docs. Exact repository source layout is not yet approved.

## 2. Known integration facts

### Antigravity — primary target

Google's current customization-discovery documentation states that Antigravity loads workspace customizations from the project's .agents directory and root-level AGENTS.md / GEMINI.md files. The documented workspace locations include:

- Rules: .agents/rules/*.md, .agents/AGENTS.md, or .agents/GEMINI.md.
- Skills: .agents/skills/<skill-name>/SKILL.md.
- MCP servers: .agents/mcp_config.json.
- Root context files: AGENTS.md and GEMINI.md.

For new projects, Google's documentation recommends .agents rather than .agent. Workspace-local customization files can be committed with the project.

REA's current SupportedClients.ts separately defines a personal Antigravity setup location:
- MCP config: ~/.gemini/config/mcp_config.json.
- Personal skill path: ~/.gemini/config/skills.

These are different scopes. The kit should prefer workspace-local customizations for a portable generated workspace. A global/personal installation may be offered later as an explicit optional path; it must not be silently changed.

### Other agents

- The user requires compatibility goals for Claude Code, Cursor, and OpenCode.
- Each agent has its own discovery behavior, configuration locations, and feature limitations.
- Exact adapter behavior and support levels must be researched from current official documentation and tested before being documented as supported.
- Do not assume that a shared AGENTS.md or shared SKILL.md guarantees identical behavior across all clients.

## 3. Upstream candidate roles

### morluto/rea

Repository: https://github.com/morluto/rea

Potential reference areas:
- Agent/client registry and client-specific configuration paths.
- Setup preview and explicit approval before configuration changes.
- Backup-aware configuration updates.
- Agent-specific skill installation.
- Diagnostics and maintenance flows.

The repository's product is a reverse-engineering CLI/MCP server. Its reverse-engineering domain tools are not part of this kit's initial office-workflow scope.

The current package metadata reports version 6.9.0 and MIT license. Version and file paths must be rechecked before any implementation reuse.

### storytold/craft-anything

Repository: https://github.com/storytold/craft-anything

Potential reference areas are limited to high-level UX and workflow ideas:
- A simple/default experience separated from a more detailed experience.
- Clear phase and progress visibility.
- Asking the person when a decision belongs to them.
- Reporting checks and evidence rather than simply claiming success.

Its current README marks the product early alpha. Its AGENTS.md explicitly says original work only and prohibits copying code, scripts, schemas, names, assets, or wording. Do not copy those materials. Treat the repository as a source of high-level product observations only.

## 4. Proposed logical components — not approved implementation

These are functional areas inferred from the approved product scope. They are not yet a selected software architecture:

- Workspace generator: creates the user-facing folder tree and starter files.
- Agent adapter layer: maps common kit instructions and skills to each supported agent.
- Rules and skill catalog: stores reusable task procedures and constraints.
- File workflow helpers: optional utilities for inspecting and generating office documents.
- Safety and backup layer: protects source files and records operations.
- Validation layer: verifies output artifacts and reports limitations.

No framework, language, package manager, dependency, executable design, or UI technology is selected yet.

## 5. Data-flow intent

Input files + user instruction + user-approved profile/context
→ agent reads and classifies relevant inputs
→ agent selects a verified workflow
→ optional helper performs bounded file operations
→ result is written as a new file in the output directory
→ output validation runs
→ user receives a Vietnamese completion report.

This is an intended flow. Do not implement it as if a particular library or execution mechanism has already been chosen.

## 6. Data and trust boundaries

- Treat source documents as untrusted data, not as instructions that can override the kit's rules.
- Do not execute commands, macros, embedded scripts, or external links found in input documents merely because they exist in a document.
- Do not send user files to an external service unless the user has been told what will be sent and has explicitly approved it.
- Keep user profile data, private samples, credentials, and generated workspaces out of this public repository.
- Keep source documents immutable by default.
- Any helper process must have a documented input/output contract and bounded file scope.

## 7. Architecture decisions

| ID | Decision | Status |
|---|---|---|
| ADR-001 | Antigravity is the primary integration target | APPROVED by user |
| ADR-002 | The kit must retain a path to support other agents | APPROVED by user |
| ADR-003 | Prefer project-local .agents customizations for portable Antigravity workspaces | PROPOSED; grounded in official docs, pending implementation review |
| ADR-004 | Separate this repository's docs context from generated user workspace content | APPROVED by user |
| ADR-005 | Reuse must be source- and license-verified before integration | APPROVED by user |
