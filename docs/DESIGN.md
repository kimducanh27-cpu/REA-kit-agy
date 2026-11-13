# DESIGN — REA-kit-agy

- Status: BASELINE / NOT IMPLEMENTED
- Last updated: 2026-11-13

## 1. Design goal

The generated workspace should behave like a simple physical desk with clearly labeled trays: one place to put material, one place for personal context, one place to find finished results, and one place for recovery copies.

The user should not need to understand the technical folder structure to use the workspace.

## 2. Visible workspace tree — approved direction

The following names reflect the user's requested direction. Exact file contents and installation behavior remain to be implemented and tested.

    my-ai-workspace/
    ├── HUONG_DAN_SU_DUNG.md
    ├── 01_THA_FILE_VAO_DAY/
    ├── 02_THONG_TIN_CUA_TOI/
    │   ├── ho-so-ca-nhan.md
    │   └── tai-lieu-mau/
    ├── 03_KET_QUA_XUAT_RA/
    ├── 04_SAO_LUU_AN_TOAN/
    ├── AGENTS.md
    ├── CLAUDE.md
    └── .agents/
        ├── rules/
        ├── skills/
        ├── scripts/
        └── templates/

This is a product-workspace proposal, not the source repository's final file tree.

## 3. Folder semantics

- 01_THA_FILE_VAO_DAY: source files supplied by the user.
- 02_THONG_TIN_CUA_TOI: optional personal preferences, role, writing voice, company rules, and approved sample documents.
- 03_KET_QUA_XUAT_RA: new deliverables created by the agent.
- 04_SAO_LUU_AN_TOAN: copies and recovery material created before a permitted operation.
- .agents: technical rules, skills, and supported workspace-local agent configuration.
- HUONG_DAN_SU_DUNG.md: one-screen quick-start guide written in plain Vietnamese.

## 4. Interaction principles

- Vietnamese plain language by default.
- Prefer short instructions and examples the user can copy.
- State what was read, what was changed, and where the result was saved.
- Show a concise preview before bulk or high-impact operations.
- Ask for explicit approval before deletion, overwriting, bulk renaming, external sharing, or other high-impact side effects.
- Never imply a file was successfully processed unless the deliverable exists and the relevant checks have passed.
- Explain failures with a human-readable cause and a practical next step; keep technical details available on request instead of hiding material safety information.

## 5. Technical visibility

- Dot-prefixed directories are a naming convention, not a guarantee that Windows Explorer hides them.
- If true Windows hiding is desired, the installer must set and verify the Windows Hidden attribute without changing the directory's accessibility to the agent.
- Do not hide warnings, security prompts, or approval requests.
- No separate GUI/dashboard is part of the initial approved scope.

## 6. Output design

Proposed naming convention: YYYY-MM-DD_ten-file, with a collision-safe suffix when a filename already exists. Exact collision handling, subfolder rules, output formats, and retention policy remain UNKNOWN pending implementation research.

Outputs should be new files. Preserve source filenames or record their relationship in an output manifest when the workflow requires traceability.

## 7. Accessibility and error experience

- Avoid unexplained acronyms and developer jargon.
- Use clear labels and predictable folder names.
- Use consistent task status wording.
- Report partial success honestly.
- Never replace an understandable warning with a vague success badge.
