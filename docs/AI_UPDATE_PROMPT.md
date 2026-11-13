# AI_UPDATE_PROMPT — REA-kit-agy

This file is the mandatory operating prompt for every AI or coding agent working in this repository.

## At the beginning of every session

1. Identify the repository, current branch, and current commit.
2. Read this file first.
3. Read HANDOFF.md.
4. Read all six required context files: PRD.md, ARCHITECTURE.md, DESIGN.md, RULES.md, TASKS.md, and PROGRESS.md.
5. Read PLAN.md if it exists and is active.
6. Inspect the actual repository tree, current Git status, recent commits, and relevant source files.
7. Compare documented state with the repository. Treat the repository and verified evidence as reality; treat stale documentation as something to correct, not as proof.
8. Identify the active task and its acceptance criteria before making changes.

## Source-first rule

The user explicitly requires development to be based on existing repositories and verified sources.

Use this mandatory sequence:

RESEARCH → VERIFY → REUSE → INTEGRATE → TEST.

Before creating a component, search and inspect existing repositories, official documentation, actual source files, license terms, notices, maintenance activity, and test coverage.

The priority references are:
- https://github.com/morluto/rea
- https://github.com/storytold/craft-anything

These are references, not blanket permission to copy everything.

For every component, record:
- Source repository and exact URL.
- Exact file, module, or documented feature.
- Commit SHA or release version checked.
- License and any notices/attribution conditions.
- REUSED, ADAPTED, ORIGINAL, or RESEARCH NEEDED classification.
- What changed and why.
- Verification or tests performed.

Do not invent features, scripts, dependencies, APIs, paths, architecture, or compatibility claims. Where evidence is missing, say UNKNOWN or RESEARCH NEEDED. Do not fill gaps with plausible-sounding guesses.

Respect upstream-specific restrictions:
- REA uses MIT; preserve required notices if reusing covered material and inspect individual file provenance.
- Craft Anything's AGENTS.md says original work only and forbids copying code, scripts, schemas, names, assets, or wording. Use it only for high-level product/UX observations unless a separately reviewed permission changes that boundary.

## During implementation

- Follow RULES.md without exception.
- Keep the initial product personal-first and folder-based.
- Antigravity is the primary integration target.
- Preserve compatibility with other agents through adapters that are independently verified.
- Prefer workspace-local Antigravity customizations; do not modify global agent configuration silently.
- Never overwrite or delete user source files by default.
- Back up and verify before permitted modifications.
- Ask for approval before bulk, destructive, irreversible, or external-sharing actions.
- Keep user personal data and credentials out of this public repository.
- Do not add product source files, scripts, generated deliverables, or test fixtures to docs/.

## Documentation updates are part of the task

Keep these six files continuously synchronized:
- PRD.md
- ARCHITECTURE.md
- DESIGN.md
- RULES.md
- TASKS.md
- PROGRESS.md

Also maintain:
- PLAN.md when there is an active plan.
- HANDOFF.md at the end of every substantial session.
- SOURCE_AUDIT.md when research, source attribution, licenses, or reuse decisions change.

Update documents when the underlying facts change, not merely at the end of a phase. Do not create conflicting duplicate truths.

## At the end of every substantial session

1. Run the relevant tests or checks; report NOT RUN where none were run.
2. Inspect the diff and verify only intended files changed.
3. Update the relevant context files.
4. Update TASKS.md with truthful statuses.
5. Append dated factual notes to PROGRESS.md.
6. Refresh HANDOFF.md with exact next steps and remaining blockers.
7. Check document consistency and source links.
8. Commit the documentation and implementation changes when authorized and possible.
9. Push to the intended branch only after checking the branch head. Never force-push. If push fails, report it accurately.

## Required final report

- Phase and task status.
- Files changed.
- Sources and provenance labels.
- Tests/checks performed and results.
- Unverified claims and blockers.
- Commit and push status.
- Exact next action.

Never claim a test, backup, commit, push, or integration succeeded unless the tool or command result confirms it.


## Product-focus guardrail — bootstrap first

The core product is a Non-Tech Workspace Bootstrap Kit, not an OCR/document-conversion suite.

Prioritize workspace folder generation, Antigravity-first workspace-local rules and Skills, understandable Vietnamese onboarding, per-agent adapters, safe setup preview/approval/configuration backup/diagnostics/recovery, and clear boundaries between user-visible folders and technical files.

Do not promote OCR, document parsers, spreadsheet engines, or other specialized office-processing packages into core dependencies merely because optional research exists. OCR is only relevant to scanned/image-only pages; ordinary text PDFs do not inherently require OCR. Treat docs/FILE_WORKFLOWS_RESEARCH.md and docs/OCR_RESEARCH.md as optional future research. These topics must not block or dominate bootstrap-core work unless the owner explicitly changes scope.

Before beginning a new research branch, explain which approved core product requirement it serves and identify the actual upstream repository/source supporting it. Do not invent additional requirements.
