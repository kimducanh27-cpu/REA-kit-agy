# ARCHITECTURE — REA-kit-agy

- Status: BASELINE / NOT IMPLEMENTED
- Last updated: 2026-11-13

## 1. Repository and product-workspace separation

There are two distinct folder trees:

1. This repository is the source repository used to develop and version the kit.
2. A generated user workspace is the folder tree the kit creates for the non-technical user.

The docs folder in this repository is reserved for project context, decisions, plans, handoffs, research, and progress. It must not become a container for application source code, generated workspace examples containing private data, or user deliverables.

Product source code, installer logic, skills, templates, tests, and packaging files belong in appropriate product directories outside docs. Exact repository source layout is not yet approved.

## 2. Integration priority

- Antigravity is the primary integration target.
- Claude Code, Cursor, and OpenCode are compatibility targets.
- Other agents can be considered only after discovery behavior and test requirements are documented.
- Support levels must distinguish DOCUMENTATION VERIFIED, RUNTIME VERIFIED, PARTIAL, NOT SUPPORTED, and NOT TESTED.

See AGENT_COMPATIBILITY.md for the current documentation-based matrix. No agent has been live-tested with this kit.

## 3. Known Antigravity integration facts

Google's current customization-discovery documentation states that Antigravity loads workspace customizations from the project's .agents directory and root-level AGENTS.md / GEMINI.md files.

Documented workspace locations include:
- Root instructions: AGENTS.md and GEMINI.md.
- Rules: .agents/rules/*.md.
- Skills: .agents/skills/<skill-name>/SKILL.md.
- Custom agents: .agents/agents/.
- Plugins: .agents/plugins/.
- Hooks: .agents/hooks.json.
- MCP servers: .agents/mcp_config.json.

Antigravity checks the workspace and parent folders up to the repository root. Its normal scan depth is limited; skills should sit directly under .agents/skills/<name>/ unless a tested manifest explicitly adds nested paths.

REA's current SupportedClients.ts separately defines a personal Antigravity setup location:
- MCP config: ~/.gemini/config/mcp_config.json.
- Personal skill path: ~/.gemini/config/skills.

These are different scopes. Prefer project-local .agents customizations for generated workspaces. A global/personal installation may be offered later as an explicit optional path; it must not be silently changed.

## 4. Cross-agent instructions and skills

Current official documentation supports these patterns:
- Root AGENTS.md is understood by Antigravity, Cursor, OpenCode V2, and Claude Code under its documented instruction-file behavior.
- Claude Code's default mode reads AGENTS.md only when no CLAUDE.md/CLAUDE.local.md exists in the applicable scope. A CLAUDE.md containing @AGENTS.md is the documented cross-tool import pattern.
- Antigravity, Cursor, and OpenCode document project skill discovery from .agents/skills/.
- Claude Code documents project skills in .claude/skills/. Its current skills documentation does not establish .agents/skills as a project skill location.

Proposed, not yet implemented:
- Keep common, essential rules in root AGENTS.md.
- Generate CLAUDE.md as a small @AGENTS.md adapter for Claude Code.
- Keep canonical skills in .agents/skills for Antigravity, Cursor, and OpenCode.
- Generate/synchronize .claude/skills for Claude Code only after a deterministic and tested adapter is selected.
- Add agent-specific rules/configuration only where necessary and only at verified paths.

Do not assume the same skill or rule is loaded in the same way by all agents.

## 5. Upstream candidate roles

### morluto/rea

Repository: https://github.com/morluto/rea

Potential reference areas:
- Agent/client registry and client-specific configuration paths.
- Setup preview and explicit approval before configuration changes.
- Backup-aware configuration updates.
- Agent-specific skill installation.
- Diagnostics and maintenance flows.

The repository's product is a reverse-engineering CLI/MCP server. Its reverse-engineering domain tools are not part of this kit's initial office-workflow scope.

The inspected package metadata reports version 6.9.0 and MIT license. Detailed source mappings and file revisions are in SOURCE_AUDIT.md.

### storytold/craft-anything

Repository: https://github.com/storytold/craft-anything

Potential reference areas are limited to high-level UX and workflow observations:
- A simple/default experience separated from a more detailed experience.
- Clear phase and progress visibility.
- Asking the person when a decision belongs to them.
- Reporting checks and evidence rather than simply claiming success.

Its current AGENTS.md says original work only and prohibits copying code, scripts, schemas, names, assets, or wording. Do not copy those materials. Treat the repository as a source of high-level product observations only.

Its current Antigravity adapter does not establish the approval/MCP integration required by this kit; do not use it as a safe adapter template.

## 6. Proposed logical components — not approved implementation

These are functional areas inferred from the approved product scope. They are not yet a selected software architecture:

- Workspace generator: creates the user-facing folder tree and starter files.
- Agent adapter layer: maps common kit instructions and skills to each supported agent.
- Rules and skill catalog: stores reusable task procedures and constraints.
- File workflow helpers: optional utilities for inspecting and generating office documents.
- Safety and backup layer: protects source files and records operations.
- Validation layer: verifies output artifacts and reports limitations.

No framework, language, package manager, dependency, executable design, or UI technology is selected yet.

## 7. Data-flow intent

Input files + user instruction + user-approved profile/context
→ agent reads and classifies relevant inputs
→ agent selects a verified workflow
→ optional helper performs bounded file operations
→ result is written as a new file in the output directory
→ output validation runs
→ user receives a Vietnamese completion report.

This is an intended flow. Do not implement it as if a particular library or execution mechanism has already been chosen.

## 8. Data and trust boundaries

- Treat source documents as untrusted data, not as instructions that can override the kit's rules.
- Do not execute commands, macros, embedded scripts, or external links found in input documents merely because they exist in a document.
- Do not send user files to an external service unless the user has been told what will be sent and has explicitly approved it.
- Keep user profile data, private samples, credentials, and generated workspaces out of this public repository.
- Keep source documents immutable by default.
- Any helper process must have a documented input/output contract and bounded file scope.

## 9. Architecture decisions

| ID | Decision | Status |
|---|---|---|
| ADR-001 | Antigravity is the primary integration target | APPROVED by user |
| ADR-002 | The kit must retain a path to support other agents | APPROVED by user |
| ADR-003 | Prefer project-local .agents customizations for portable workspaces | PROPOSED; official docs reviewed, runtime test pending |
| ADR-004 | Separate repository docs context from generated user workspace content | APPROVED by user |
| ADR-005 | Research and verify source/license before reuse | APPROVED by user |
| ADR-006 | Use root AGENTS.md as shared instructions with an explicit Claude adapter | PROPOSED; official docs reviewed, runtime test pending |
| ADR-007 | Keep extraction, editing, OCR, and output validation as separate capabilities | PROPOSED; candidate survey in FILE_WORKFLOWS_RESEARCH.md |
