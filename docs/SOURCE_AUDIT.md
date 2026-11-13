# SOURCE AUDIT — REA-kit-agy

- Audit date: 2026-11-13
- Status: INITIAL SOURCE MAP COMPLETE / IMPLEMENTATION RESEARCH CONTINUES
- Repository: https://github.com/kimducanh27-cpu/REA-kit-agy
- Method: inspect repository contents, source files, documentation, licenses, and current branch commits. No upstream code was copied in this audit.

## 1. Executive summary

The two user-selected repositories have different and limited roles:

1. **morluto/rea** is the strongest implementation reference for client discovery, configuration planning, approval, backups, skill installation, diagnostics, and setup recovery. Its reverse-engineering product domain is outside this kit's office-workflow scope.
2. **storytold/craft-anything** is a high-level product/UX observation source only. Its contributor instructions prohibit copying code, scripts, schemas, names, assets, or wording. Its Antigravity adapter currently declares no tool server and no approval integration, so it is not a safe Antigravity adapter reference.
3. Google's current Antigravity documentation is the authority for workspace-local customization discovery.
4. Office-file processing requires separate extraction, editing, OCR, and verification capabilities. No dependency is selected.

## 2. REA — morluto/rea

Repository: https://github.com/morluto/rea
Inspected main commit: 54906fdb1fc735b507961b2954f6968775cae4f6
Inspected package version: 6.9.0
License: MIT
Repository language: TypeScript
Product focus: reverse-engineering CLI and MCP server.

### Exact source mapping

| Source file | Verified behavior | Kit relevance | Classification |
|---|---|---|---|
| README.md | Setup discovers/selects agent clients, previews planned changes, requires approval, and backs up existing configuration | Setup UX and safety flow | ADAPTED candidate |
| package.json | Package identity, version, runtime constraints, and dependency metadata | Dependency/provenance reference | RESEARCH reference |
| LICENSE | MIT license text | Conditions for code/documentation reuse | RESEARCH reference |
| AGENTS.md | Configuration changes should be additive/idempotent and backed up; setup previews changes and requires approval; installer should not install unrelated software | Installation guardrails | ADAPTED candidate |
| src/application/SupportedClients.ts | Client registry with per-client config format/path and skill destination; Antigravity entry maps personal MCP config to ~/.gemini/config/mcp_config.json and skills to ~/.gemini/config/skills | Per-agent adapter registry | ADAPTED candidate |
| src/application/Setup.ts | Selects clients and skills, calculates planned actions, supports dry-run, confirms plan, then applies approved changes | Explicit plan/consent sequence | ADAPTED candidate |
| src/application/SetupPlan.ts | Preflights selected clients and creates concrete setup actions; blocks unsupported or unsafe configurations | Preflight and blockers | ADAPTED candidate |
| src/application/SetupRecoveryBackup.ts | Uses exclusive copy, preserves original bytes, verifies the resulting backup, and creates content-addressed recovery paths when a prior backup differs | Backup integrity/recovery | ADAPTED candidate |
| src/application/ClientConfigurationTransaction.ts | Serializes read/merge/publish operations per resolved configuration path | Prevent concurrent configuration writes | ADAPTED candidate |
| src/application/SetupSkill.ts | Resolves client skill roots, inspects directory types, rejects symbolic-link skill roots, and validates paths before publishing | Safe skill distribution | ADAPTED candidate |
| src/application/Doctor.ts | Provides a read-only structured readiness report, with client/skill states and remediation | Health check concept | ADAPTED candidate |
| src/cli/interactiveSetup.ts | Client selection, dry-run summary, action preview, user confirmation, and progress output | Nontechnical installer interaction | ADAPTED candidate |
| tests/boundary/filesystem/setupConfig.test.ts | Tests preserving existing configuration and backup creation | Regression-test reference | RESEARCH reference |
| tests/boundary/filesystem/setupSkill.test.ts | Tests recovery backup selection, rollback failures, byte preservation, and invalid skill directories | Regression-test reference | RESEARCH reference |

### Reuse boundary

- MIT permits reuse subject to preserving copyright and permission notices in copies or substantial portions.
- Check each file and bundled dependency for its own provenance before copying it.
- A small installer/client-registry extraction may be feasible, but dependency coupling and module boundaries still need review.
- Do not import REA's reverse-engineering domain tools, native analysis engines, product identity, or unrelated dependencies into this workspace kit.
- The audit inspected source and tests; it did not run REA's test suite or prove a module can be extracted independently.

## 3. Craft Anything — storytold/craft-anything

Repository: https://github.com/storytold/craft-anything
Inspected main commit: 52f1daa668021a84e8c72f2564cf3dfe36ccec67
Inspected README status: early alpha
License declaration: MIT OR Apache-2.0
Inspected legal/provenance files: LICENSE-MIT, LICENSE-APACHE, NOTICE, ATTRIBUTION.md
No code, assets, schemas, or wording were copied.

### Exact source mapping

| Source | Verified observation | Kit treatment |
|---|---|---|
| README.md | Simple and advanced user experiences; visible Study/Build/Check/Ready stages; plain-language questions and approval cards | HIGH-LEVEL UX OBSERVATION only |
| docs/STATUS.md | Distinguishes what works from how it was checked | HIGH-LEVEL QA/status observation only |
| docs/ROADMAP.md | Stable task IDs, status, owner, pending changes, and completion evidence | HIGH-LEVEL work-tracking observation only |
| AGENTS.md | Explicit original-work-only instruction prohibits copying code, scripts, schemas, names, assets, or wording from other projects | DO NOT COPY those materials |
| crates/ai/src/cli_agents/grants.rs | Antigravity row declares no tool server, no approvals, and no mid-turn notes; its comment mentions a permission-bypass launch mode | DO NOT USE as the kit's Antigravity safety or integration design |
| NOTICE and ATTRIBUTION.md | Brand marks and bundled assets have separate restrictions and provenance | Do not reuse brand assets or third-party bundled material |

### Treatment boundary

Use only independent, high-level observations about clarity of progress, simple-versus-advanced presentation, decision ownership, and evidence-backed completion. Do not copy code, scripts, schemas, identifiers, branding, assets, UI text, or documentation wording. Recheck its status and rules before each future research pass because the repository changes quickly.

## 4. Official agent customization sources

- Antigravity customization discovery: https://antigravity.google/docs/customization-discovery/
- Antigravity Skills: https://antigravity.google/docs/commands/learn
- Antigravity plugin packaging: https://antigravity.google/docs/build-plugins/
- Claude Code instruction files: https://code.claude.com/docs/en/memory
- Claude Code skills: https://code.claude.com/docs/en/skills
- Cursor rules: https://cursor.com/docs/rules
- Cursor skills: https://cursor.com/docs/skills
- OpenCode instructions: https://opencode.ai/docs/instructions
- OpenCode skills: https://opencode.ai/docs/skills/

Detailed findings and proposed adapters are in AGENT_COMPATIBILITY.md. These are documentation findings; live runtime support remains NOT TESTED.

## 5. Office-file processing sources

Detailed capability limits and research gaps are in FILE_WORKFLOWS_RESEARCH.md.

| Candidate | License/source status | Potential role | Classification |
|---|---|---|---|
| microsoft/markitdown | MIT; main inspected at ed178952a6672abdfd35b5f9e76a80b6cefc086e | Broad read-only document-to-Markdown extraction for AI analysis | RESEARCHED CANDIDATE |
| py-pdf/pypdf | BSD-3-Clause; main inspected at 77c9a418421b6a783b9e7795973e778f3a10fb9d; 7.0.1 released 2026-11-10 | PDF extraction and page operations | RESEARCHED CANDIDATE |
| python-openxml/python-docx | MIT; inspected master at e45454602b53e8e572b179ccf1c91093ec9f4ed7; docs version 1.2.0 | DOCX creation and controlled updates | RESEARCHED CANDIDATE |
| openpyxl | MIT/Expat in official docs; upstream at foss.heptapod.net; PyPI latest release metadata inspected as 2024-06-28 | XLSX/XLSM reading and writing | RESEARCHED CANDIDATE WITH MAINTENANCE CONCERN |
| pandas | Official documentation 3.1.1 | Tabular analysis, aggregation, and export | RESEARCHED CANDIDATE |

Do not pin or install these dependencies based solely on this survey. Check current versions, transitive dependency licenses, security advisories, and representative-file behavior before selection.

## 6. Initial source-to-feature map

| Kit capability | Best current source | Classification | Status |
|---|---|---|---|
| Antigravity workspace-local discovery | Google official documentation | REUSE DOCUMENTED INTERFACE | Docs verified; runtime not tested |
| Shared root instructions | Official agent documentation | ADAPTATION required for Claude behavior | Docs verified; runtime not tested |
| Skills distribution to Antigravity/Cursor/OpenCode | Official agent documentation and REA client model | ADAPTED candidate | Docs verified; sync not implemented |
| Claude project skill adapter | Claude Code official docs | ADAPTED candidate | Docs verified; not implemented |
| Agent client registry | REA SupportedClients.ts | ADAPTED candidate | Source inspected |
| Setup plan and explicit consent | REA Setup.ts, SetupPlan.ts | ADAPTED candidate | Source inspected |
| Backup integrity and recovery | REA SetupRecoveryBackup.ts | ADAPTED candidate | Source inspected |
| Client configuration serialization | REA ClientConfigurationTransaction.ts | ADAPTED candidate | Source inspected |
| Read-only health check | REA Doctor.ts | ADAPTED candidate | Source inspected |
| Beginner-facing status and approvals | High-level UX observation only | ORIGINAL design required | Not implemented |
| Broad office-document extraction | MarkItDown | RESEARCHED CANDIDATE | Not installed or tested |
| PDF extraction | pypdf | RESEARCHED CANDIDATE | Not installed or tested |
| DOCX generation/editing | python-docx | RESEARCHED CANDIDATE | Not installed or tested |
| Excel analysis | pandas | RESEARCHED CANDIDATE | Not installed or tested |
| Excel workbook edits | openpyxl | RESEARCHED CANDIDATE | Maintenance/compatibility concern |
| OCR | No source selected | RESEARCH NEEDED | Not started |

## 7. Open risks and decisions

1. REA's Antigravity path in SupportedClients.ts is personal/global scope. Prefer Antigravity's workspace-local .agents layout for generated workspaces, and test before choosing an installer.
2. Claude Code's default AGENTS.md behavior changes if a CLAUDE.md exists. The CLAUDE.md adapter must explicitly import @AGENTS.md or use a verified supported setting.
3. Claude Code's current documented project skill path is .claude/skills; do not assume it loads .agents/skills.
4. Antigravity's scan depth and skill manifests constrain how the skill folder tree should be generated.
5. openpyxl's documentation identifies a non-GitHub upstream and its PyPI metadata shows an older release date. Reassess maintenance and alternatives.
6. MarkItDown executes with current-process I/O privileges and is not a high-fidelity document conversion tool.
7. OCR, format preservation, and representative-file test corpus remain open.
8. No live agent or document-processing tests have been performed.

## 8. Reference revisions

- REA: https://github.com/morluto/rea/tree/54906fdb1fc735b507961b2954f6968775cae4f6
- REA Setup.ts: https://github.com/morluto/rea/blob/54906fdb1fc735b507961b2954f6968775cae4f6/src/application/Setup.ts
- REA SetupPlan.ts: https://github.com/morluto/rea/blob/54906fdb1fc735b507961b2954f6968775cae4f6/src/application/SetupPlan.ts
- REA SetupRecoveryBackup.ts: https://github.com/morluto/rea/blob/54906fdb1fc735b507961b2954f6968775cae4f6/src/application/SetupRecoveryBackup.ts
- REA ClientConfigurationTransaction.ts: https://github.com/morluto/rea/blob/54906fdb1fc735b507961b2954f6968775cae4f6/src/application/ClientConfigurationTransaction.ts
- REA SetupSkill.ts: https://github.com/morluto/rea/blob/54906fdb1fc735b507961b2954f6968775cae4f6/src/application/SetupSkill.ts
- REA Doctor.ts: https://github.com/morluto/rea/blob/54906fdb1fc735b507961b2954f6968775cae4f6/src/application/Doctor.ts
- REA interactiveSetup.ts: https://github.com/morluto/rea/blob/54906fdb1fc735b507961b2954f6968775cae4f6/src/cli/interactiveSetup.ts
- Craft Anything: https://github.com/storytold/craft-anything/tree/52f1daa668021a84e8c72f2564cf3dfe36ccec67
- MarkItDown: https://github.com/microsoft/markitdown/tree/ed178952a6672abdfd35b5f9e76a80b6cefc086e
- pypdf: https://github.com/py-pdf/pypdf/tree/77c9a418421b6a783b9e7795973e778f3a10fb9d
- python-docx: https://github.com/python-openxml/python-docx/tree/e45454602b53e8e572b179ccf1c91093ec9f4ed7
- openpyxl documentation: https://openpyxl.readthedocs.io/en/stable/


## 9. OCR research — Vietnamese and Windows
Detailed findings are in [OCR_RESEARCH.md](OCR_RESEARCH.md). Exact inspected sources:

| Candidate | Inspected source | License evidence | Status |
|---|---|---|---|
| RapidOCR | https://github.com/RapidAI/RapidOCR/tree/ae1d898295ecec19df7f4782f52949780e56d211; python/rapidocr/default_models.yaml; python/MODEL_LICENSES.md | Apache-2.0 code; registered models Apache-2.0; dictionaries/fonts have separate terms | Priority prototype candidate; not tested |
| Tesseract | https://github.com/tesseract-ocr/tesseract/tree/34f4e3ffc25847740a4b1d52d39d40e8013ace83; https://github.com/tesseract-ocr/tessdata_best/tree/e12c65a915945e4c28e237a9b52bc4a8f39a0cec | Apache-2.0 engine and tessdata_best; Vietnamese model file exists | Baseline comparator; not tested |
| PaddleOCR | https://github.com/PaddlePaddle/PaddleOCR/tree/dab3fe35379033fdcb2d0e9572fac0b36c9a9ebf | Apache-2.0 repository; audit model assets separately | Alternative; not tested |
| Docling | https://github.com/docling-project/docling/tree/b9bf356f9763095ca9d51e7452a054a7db20f237 | MIT repository; audit model/engine dependencies separately | Document-level parser candidate; not tested |
| EasyOCR | https://github.com/JaidedAI/EasyOCR/tree/2f77e2e8125d666af859a57d49014731ecbf40c6 | Apache-2.0 source; model-weight terms not yet audited | Lower-priority alternative; not tested |

No OCR code, model weights, or third-party binaries have been copied or installed.
