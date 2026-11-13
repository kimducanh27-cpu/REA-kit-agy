# AGENT COMPATIBILITY — REA-kit-agy

- Research date: 2026-11-13
- Status: DOCUMENTATION VERIFIED / RUNTIME NOT TESTED
- Primary target: Antigravity
- Compatibility targets: Claude Code, Cursor, OpenCode

## 1. Purpose

This document records customization discovery behavior from current official documentation. It is not a claim that this kit has been installed or tested in those applications.

The kit should keep one shared set of essential project instructions and use per-agent adapters where discovery paths or behavior differ.

## 2. Verified support matrix

| Capability | Antigravity | Claude Code | Cursor | OpenCode |
|---|---|---|---|---|
| Root AGENTS.md | Yes | Yes, subject to instruction-file mode/version | Yes | Yes |
| Root GEMINI.md | Yes | Not established | Not established | Not established |
| Root CLAUDE.md | Not primary | Yes | Not established | No fallback in V2 |
| Workspace .agents/rules | Yes | Not documented | Not documented | Not documented |
| Project .agents/skills | Yes | Not listed in current skills docs | Yes | Yes |
| Agent-specific skill path | .agents/skills | .claude/skills | .cursor/skills | .opencode/skills |
| MCP | Supported | Supported | Supported | Supported |
| Runtime test with this kit | NOT TESTED | NOT TESTED | NOT TESTED | NOT TESTED |

A Yes means the official docs describe the discovery mechanism. It does not mean REA-kit-agy has been tested in that application.

## 3. Antigravity — primary target

Official sources:
- https://antigravity.google/docs/customization-discovery/
- https://antigravity.google/docs/commands/learn
- https://antigravity.google/docs/build-plugins/

Verified workspace locations:
- Root instructions: AGENTS.md and GEMINI.md.
- Workspace customizations: .agents/.
- Rules: .agents/rules/*.md.
- Skills: .agents/skills/<skill-name>/SKILL.md.
- Custom agents: .agents/agents/.
- Plugins: .agents/plugins/.
- Hooks: .agents/hooks.json.
- MCP servers: .agents/mcp_config.json.

Important constraints:
- Antigravity checks the active workspace and parent folders up to the repository root.
- It does not automatically scan arbitrary subfolders below the workspace root.
- Normal scan depth is limited; skill folders should sit directly under .agents/skills unless a tested manifest adds nested paths.
- Discovery manifests include skills.json, rules.json, agents.json, and plugins.json.
- Rules in rules/ require YAML frontmatter with a valid trigger.
- Rules and skills are reread before each turn; the CLI may require /skills reload to refresh the skill list.

Design implication:
- Use .agents/ as the primary workspace-local customization root.
- Keep essential shared instructions in root AGENTS.md.
- Avoid global ~/.gemini/config changes by default.

## 4. Claude Code

Official sources:
- https://code.claude.com/docs/en/memory
- https://code.claude.com/docs/en/skills
- https://code.claude.com/docs/en/mcp

Verified instruction behavior:
- Claude Code supports CLAUDE.md and AGENTS.md.
- By default, Claude reads AGENTS.md only when there is no CLAUDE.md or CLAUDE.local.md in the applicable working directory or above it.
- Claude can be configured to read both instruction files.
- A CLAUDE.md can import the shared AGENTS.md using @AGENTS.md.
- On Windows, an import is safer to distribute than a symlink because Git symlinks may not check out as intended without the right settings.

Verified skill behavior:
- Project skills are discovered from .claude/skills/<name>/SKILL.md.
- Current Claude Code skill documentation does not list .agents/skills as a project discovery location.
- Skill descriptions/frontmatter guide discovery and invocation.

Design implication:
- Keep AGENTS.md as the shared instruction source.
- Provide a CLAUDE.md adapter containing @AGENTS.md.
- Generate or synchronize .claude/skills only after a deterministic, tested adapter is selected. Do not assume Claude reads .agents/skills directly.

## 5. Cursor

Official sources:
- https://cursor.com/docs/rules
- https://cursor.com/docs/skills

Verified behavior:
- AGENTS.md is supported at project root and in subdirectories.
- Structured project rules live in .cursor/rules/ and use .mdc files with frontmatter; plain .md files in that directory are not recognized as project rules.
- Skills are discovered from .agents/skills/ and .cursor/skills/.
- Cursor also supports skill locations in .claude/skills/ and .codex/skills/ for compatibility.
- Skill folders use SKILL.md and may include scripts, references, and assets.

Design implication:
- The canonical .agents/skills directory can serve Cursor according to current docs.
- Use .cursor/rules only for Cursor-specific behavior; keep essential shared instructions in AGENTS.md.

## 6. OpenCode

Official sources:
- https://opencode.ai/docs/instructions
- https://opencode.ai/docs/skills/

Verified behavior:
- AGENTS.md supplies persistent project instructions.
- OpenCode V2 recognizes AGENTS.md and does not use CLAUDE.md as a fallback.
- Project skills are discovered from .agents/skills/ and .opencode/skills/.
- Skill packages use SKILL.md with a description and may include supporting scripts and references.

Design implication:
- Root AGENTS.md is the shared instruction file.
- .agents/skills can serve as the canonical skill root.
- Use .opencode/skills only for OpenCode-specific overrides or features not represented in a shared skill.

## 7. Proposed adapter architecture — NOT APPROVED

| Shared source | Antigravity | Claude Code | Cursor | OpenCode |
|---|---|---|---|---|
| AGENTS.md | Native | Native/conditional; CLAUDE.md import adapter handles fallback cases | Native | Native |
| .agents/skills | Native | Generate/sync to .claude/skills | Native | Native |
| Agent-specific rules | .agents/rules | .claude/rules | .cursor/rules/*.mdc | AGENTS.md or configured instructions |
| MCP | .agents/mcp_config.json | Per-agent config adapter | Per-agent config adapter | Per-agent config adapter |

Do not install globally without explicit user approval. Do not claim feature parity unless validated by tests.

## 8. Required runtime verification

For every supported agent:
1. Record application and version.
2. Open a clean generated workspace.
3. Verify root instructions are loaded.
4. Verify each sample skill is discoverable and invocable.
5. Verify agent-specific rules are loaded where applicable.
6. Verify MCP only if the kit needs it.
7. Check that the agent does not silently write to global configuration.
8. Run a representative file task and verify the output.
9. Record reproducible evidence and exact results.

Until these steps are complete, report documentation compatibility only, not runtime support.
