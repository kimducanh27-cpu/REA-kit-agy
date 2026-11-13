# SOURCE AUDIT — REA-kit-agy

- Audit date: 2026-11-13
- Status: INITIAL AUDIT / PARTIAL
- Purpose: source provenance, reuse boundary, and evidence for P00

## 1. Summary

The two priority repositories are not interchangeable sources.

- REA is the stronger candidate for studying agent client discovery, configuration registration, setup preview, approval, backup, and skill installation.
- Craft Anything is a reference for simple-versus-advanced presentation, progress/status visibility, user approval moments, and evidence-oriented completion. Its contributor guidance forbids copying code, scripts, schemas, names, assets, or wording. Treat its material as high-level observation only.
- Google's official Antigravity documentation is the authority for current Antigravity workspace customization discovery.

No upstream source code has been copied into this repository by this audit.

## 2. REA — morluto/rea

Repository: https://github.com/morluto/rea
License: MIT (repository LICENSE and package.json)
Version observed in package.json: 6.9.0
Main branch commit inspected: 54906fdb1fc735b507961b2954f6968775cae4f6
Package description: reverse-engineering CLI and MCP server. Its reverse-engineering features are outside this kit's initial office-workflow scope.

### Inspected sources

| Source | What was verified | Candidate use |
|---|---|---|
| README.md | Setup connects selected agents, installs matching workflow instructions, and asks users to review and approve changes | ADAPTED candidate: setup UX and client selection pattern |
| package.json | Package name rea-agents, version 6.9.0, MIT, Node engine metadata | RESEARCH reference only; do not inherit runtime requirements without checking need |
| LICENSE | MIT license text | Reuse only with required copyright and permission notice |
| AGENTS.md | Configuration changes should be additive/idempotent with backups; setup should preview changes and require approval; installer should not install unrelated software | ADAPTED candidate: safe configuration change principles |
| src/application/SupportedClients.ts | Client registry; Antigravity name, personal MCP config path ~/.gemini/config/mcp_config.json, personal skill path ~/.gemini/config/skills | ADAPTED candidate: explicit per-client adapter registry |
| docs/getting-started/installation.md | Supported clients table; setup review/approval flow; separate approval for optional installation; client-specific skill installation locations | ADAPTED candidate: installer and documentation flow |

### Reuse boundary

- Candidate REUSED/ADAPTED: only after file-by-file implementation review, preserving MIT notices and checking dependencies/provenance.
- RESEARCH NEEDED: whether a small installer/client-registry module can be reused independently without importing REA's reverse-engineering domain or native dependencies.
- ORIGINAL or RESEARCH NEEDED: office-document workflows are not established by the REA material inspected so far.
- Do not copy the REA product name, branding, reverse-engineering workflows, or unrelated analysis modules into this kit.

## 3. Craft Anything — storytold/craft-anything

Repository: https://github.com/storytold/craft-anything
Main branch commit inspected: 52f1daa668021a84e8c72f2564cf3dfe36ccec67
README status: early alpha.
License declaration: MIT OR Apache-2.0. Root files include LICENSE-MIT, LICENSE-APACHE, NOTICE, and ATTRIBUTION.md.

### Inspected sources

| Source | What was verified | Permitted treatment |
|---|---|---|
| README.md | Describes simple/default and advanced experiences, a four-stage Study/Build/Check/Ready workflow, progress, questions and approval cards | HIGH-LEVEL OBSERVATION only; independently design a different workflow and wording |
| docs/STATUS.md | Describes what works and how it was checked; records partial areas and test evidence | HIGH-LEVEL OBSERVATION only: distinguish implemented, partial, and unverified status |
| docs/ROADMAP.md | Uses stable task IDs, owners, statuses, pending changes, and evidence-linked completion | HIGH-LEVEL OBSERVATION only: evaluate whether a similar traceability need exists |
| AGENTS.md | Explicit “Original work only” rule forbids copying code, scripts, schemas, names, assets, or wording from other projects | BINDING REUSE LIMIT FOR THIS PROJECT: do not copy the listed materials |
| crates/ai/src/cli_agents/grants.rs | The current Antigravity row declares no tool server, no approval integration, and no mid-turn notes; an adjacent comment mentions a permission-bypass launch flag | DO NOT REUSE as an Antigravity integration or safety model |
| NOTICE | Declares MIT or Apache-2.0 licensing, but brand marks are trademarks and third-party material has separate terms | Do not reuse brand assets; audit each third-party item independently |
| ATTRIBUTION.md | Lists separate sources/licenses for bundled fonts, icons, and app imagery | Do not copy or bundle these assets without independent license review |

### Reuse boundary

- Allowed now: high-level observations about beginner-friendly presentation, status clarity, evidence, and asking the user when a decision belongs to them.
- Not allowed by this project's policy: copy its code, scripts, schemas, names, assets, UI text, or documentation wording.
- Do not treat the presence of an Antigravity adapter as proof that the adapter supports MCP tools or approval gates.

## 4. Official Antigravity documentation

| Source | Verified fact | Design implication |
|---|---|---|
| https://antigravity.google/docs/customization-discovery/ | Workspace scope includes .agents; supports rules, skills, agents, plugins, hooks, and mcp_config.json; root AGENTS.md/GEMINI.md are discovered; recommends .agents for new projects | Prefer workspace-local .agents for portable workspaces |
| https://antigravity.google/docs/commands/learn/ | Workspace skill path is .agents/skills/<name>/SKILL.md; global skills use ~/.gemini/config/skills | Keep workspace-local and global installations distinct |
| https://antigravity.google/docs/build-plugins | Plugins can bundle skills, MCP servers, agents, rules, and lifecycle hooks | Plugin packaging is a research candidate, not yet selected |

Official docs were checked on 2026-11-13. Re-check them before implementation because agent products can change.

## 5. Initial source-to-feature map

| Kit feature | Best current source | Classification | Status |
|---|---|---|---|
| Antigravity workspace-local rules/skills discovery | Google official docs | REUSED AS DOCUMENTED INTERFACE | VERIFIED IN DOCS; not live-tested |
| Antigravity personal MCP/skill registration | REA SupportedClients.ts and install guide | ADAPTED candidate | SOURCE REVIEWED; implementation not selected |
| Client-specific registry model | REA SupportedClients.ts | ADAPTED candidate | SOURCE REVIEWED; module extraction not tested |
| Setup preview, approval, and backup principles | REA README and AGENTS.md | ADAPTED candidate | SOURCE REVIEWED; code reuse not yet approved |
| Beginner-friendly status and approvals | Craft Anything README | HIGH-LEVEL OBSERVATION | NOT IMPLEMENTED |
| Office-document processing | No adequate source selected | RESEARCH NEEDED | NOT STARTED |
| User-visible folder naming and Vietnamese quick guide | User-approved requirements | USER-SPECIFIED | NOT IMPLEMENTED |
| Cross-agent adapter matrix | Official docs still incomplete | RESEARCH NEEDED | NOT STARTED |

## 6. Risks and open questions

1. REA currently targets personal Antigravity configuration paths in its client registry, while Google's current documentation also supports workspace-local customizations. Choose the least invasive scope for the kit and test the actual app.
2. Craft Anything is early alpha according to its README. Recheck STATUS.md and ROADMAP.md at the time any future observation is used.
3. Craft Anything's current Antigravity adapter lacks the tool server and approval capabilities expected from a safe integrated builder.
4. REA's MIT license does not prove every bundled submodule, dependency, or asset is MIT. Check individual provenance.
5. The office-document processing stack remains unselected. Research PDF, DOCX, XLSX, CSV, and image sources separately.
6. The current audit is partial. It is not a final approval to copy code.

## 7. Audit references

- REA repository: https://github.com/morluto/rea
- REA README: https://github.com/morluto/rea/blob/54906fdb1fc735b507961b2954f6968775cae4f6/README.md
- REA license: https://github.com/morluto/rea/blob/54906fdb1fc735b507961b2954f6968775cae4f6/LICENSE
- REA agent rules: https://github.com/morluto/rea/blob/54906fdb1fc735b507961b2954f6968775cae4f6/AGENTS.md
- REA client registry: https://github.com/morluto/rea/blob/54906fdb1fc735b507961b2954f6968775cae4f6/src/application/SupportedClients.ts
- REA installation guide: https://github.com/morluto/rea/blob/54906fdb1fc735b507961b2954f6968775cae4f6/docs/getting-started/installation.md
- Craft Anything repository: https://github.com/storytold/craft-anything
- Craft Anything README: https://github.com/storytold/craft-anything/blob/52f1daa668021a84e8c72f2564cf3dfe36ccec67/README.md
- Craft Anything status: https://github.com/storytold/craft-anything/blob/52f1daa668021a84e8c72f2564cf3dfe36ccec67/docs/STATUS.md
- Craft Anything agent rules: https://github.com/storytold/craft-anything/blob/52f1daa668021a84e8c72f2564cf3dfe36ccec67/AGENTS.md
- Craft Anything adapter grants: https://github.com/storytold/craft-anything/blob/52f1daa668021a84e8c72f2564cf3dfe36ccec67/crates/ai/src/cli_agents/grants.rs
- Craft Anything notices: https://github.com/storytold/craft-anything/blob/52f1daa668021a84e8c72f2564cf3dfe36ccec67/NOTICE
- Craft Anything attribution: https://github.com/storytold/craft-anything/blob/52f1daa668021a84e8c72f2564cf3dfe36ccec67/ATTRIBUTION.md
