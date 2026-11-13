# PRD — REA-kit-agy

- Product: Non-Tech Workspace Bootstrap Kit
- Repository: https://github.com/kimducanh27-cpu/REA-kit-agy
- Version: 0.1 — project baseline
- Status: DRAFT / BASELINE
- Last updated: 2026-11-13

## 1. Product vision

Build a personal-first workspace starter kit that lets a non-technical user work with AI agents through a clear folder structure and plain-language instructions. The user should be able to place files in a known input folder, describe the requested outcome in ordinary language, and receive a new result in a predictable output location.

The kit must reduce the need for the user to understand prompts, terminal commands, package managers, MCP configuration, or agent-specific folder conventions.

## 2. Primary user and context

- Primary user: the repository owner, who describes the intended user as non-technical.
- Initial deployment priority: Google Antigravity.
- Additional compatibility goal: Claude Code, Cursor, OpenCode, and other agents when their real capabilities and configuration formats are verified.
- Personal profession, company policies, preferred writing voice, and exact operating environment: UNKNOWN; these belong in a user-editable profile in a generated workspace, not as invented facts in this repository.

## 3. Product scope

### In scope — user-approved direction

1. A self-explanatory workspace folder structure with numbered Vietnamese folder names without diacritics.
2. A visible input folder for files the user wants processed.
3. A personal-context folder with fill-in templates and optional sample documents.
4. A predictable output folder for generated deliverables.
5. A backup folder for source files and recovery copies.
6. A hidden or visually de-emphasized technical area for agent rules, skills, scripts, and templates.
7. Vietnamese, non-technical communication by default.
8. File-based agent workflows (summarizing and organizing user-provided material, spreadsheet work, drafting from samples, and checking outputs) are capability goals to validate after the bootstrap core. Individual parsers and OCR engines are optional extensions, not the product foundation.
9. Antigravity-first integration with adapters for other agents.
10. A continuously maintained project context system in this repository's docs folder.

### Out of scope until separately approved

- A general-purpose multi-agent orchestration platform.
- A standalone desktop dashboard or GUI.
- A cloud service or automatic upload of personal documents.
- Automatic email sending, account actions, purchases, publishing, or external sharing.
- Silent bulk changes to user files.
- Claiming support for an agent or file format before a real integration test.
- Importing an entire upstream project merely because it is available.
- Making OCR, PDF conversion, or specialist document-processing engines mandatory parts of the bootstrap kit.

## 4. Intended user experience

1. The user opens the generated workspace in a supported agent.
2. The user places source material in the input folder.
3. The user gives a short Vietnamese instruction.
4. The agent reads the applicable user profile and relevant material.
5. The agent proposes or performs only actions allowed by documented safety rules.
6. The agent creates a new deliverable in the output folder.
7. The agent verifies the deliverable and reports the result in plain Vietnamese.
8. Original files remain unchanged; recovery copies and action records are available.

This is the intended flow, not yet a verified implementation.

## 5. Initial acceptance criteria

- A newly generated workspace has the agreed visible folders and documented technical folders.
- Antigravity reads the project-local rules and skills from supported locations.
- The user can identify where to put files and where to find results without reading technical documentation.
- No operation overwrites or deletes a source file by default.
- Bulk or irreversible actions require explicit approval.
- Output files are checked for existence, readability, and task-specific correctness before being reported as complete.
- Skills and agent support are tested on real target agents; documentation alone is not treated as proof.
- The repository's docs context files are updated as work changes.

## 6. Constraints

- Research before build: RESEARCH → VERIFY → REUSE → INTEGRATE → TEST.
- Reuse upstream code only after checking the exact source, license, notices, provenance, and compatibility.
- Craft Anything's current AGENTS.md says original work only; this project will not copy its code, scripts, schemas, names, assets, or wording.
- REA is MIT-licensed; any actual reuse must preserve required copyright and license notices.
- No secrets, personal documents, API keys, tokens, or private profile data may be committed to this public repository.
- The docs folder in this repository is for context and project progress only, not product source code or user deliverables.

## 7. Open questions

- Exact supported operating systems and minimum versions: UNKNOWN.
- Whether the kit is distributed as a ZIP, installer, repository template, or setup command: UNKNOWN.
- Whether the core bootstrap kit needs any Python/Node helper: UNKNOWN; prefer no extra runtime unless a verified core function requires one.
- Which optional document-processing extensions are useful later: UNKNOWN; evaluate only after the workspace/bootstrap experience works.
- Exact backup retention and naming policy: UNKNOWN.
- Whether an optional global Antigravity setup is needed in addition to workspace-local configuration: UNKNOWN.
- Exact support matrix and parity levels for non-primary agents: NOT YET VERIFIED.
