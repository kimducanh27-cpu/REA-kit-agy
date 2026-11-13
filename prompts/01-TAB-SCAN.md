# PROMPT 01: QUÉT & KIỂM TRA ỨNG DỤNG (TAB 01 — SCAN & INVENTORY)

*Dán đoạn lệnh này sau khi đã thả file vào thư mục `01_THA_APP_VAO_DAY/`.*

```markdown
# Tab 01 — Application Intake, Evidence Scan & Screen Inventory

Read the active Skill at `.agents/skills/rea-scan/SKILL.md` in full. The Skill is the governing process contract.
The underlying analysis engine is `.agents/skills/reverse-engineer-anything/SKILL.md`.

You are the Application Intake Inspector. Work only in Stage 01. Do not modify files outside authorized output paths.

## First: verify input and safety preconditions
1. Inspect directory `01_THA_APP_VAO_DAY/`:
   - If empty: Notify the user in Vietnamese with guidance on supported formats (APK, ASAR, ZIP, EXE, Web URL).
   - If >1 file: Present a Multi-file Inventory table (Name, Size, Predicted Format) and request user prioritization before scanning.
2. Once the target file is confirmed, create an immutable, exact copy into `04_SAO_LUU_AN_TOAN/`. Verify copy size and integrity before any analysis.

## Analysis and target routing
3. Route the target according to its artifact type using REA engine tools:
   - **Android APK**: `inspect_android_package`. Fall back to static ZIP resource inspection if Java/JADX is unavailable.
   - **Electron / JS ASAR**: `analyze_javascript_application` or `npx -y rea-agents analyze-javascript-application <path> --json`.
   - **Native Binary**: `open_binary` and `inspect_artifact`. Fall back to header/metadata inspection if Ghidra is missing.
   - **Web / Browser Target**: `list_browser_targets` / observation.
   - **Plain Source Code**: Use standard agent source reading tools (do not force REA on plain source).
4. Extract the **Functional Screen Inventory** and **UI State Matrix** (Loading, Empty, Success, Error) conforming to `templates/01-REPORT-TEMPLATE.md`.
5. Redact all secret credentials, private tokens, passwords, and sensitive keys to `[REDACTED]`.

## Required templates and output paths
- Report template: `templates/01-REPORT-TEMPLATE.md` → `03_KET_QUA_KIEM_TRA/YYYY-MM-DD_HHmm_bao-cao-hien-trang.md`
- Extracted design tokens: `03_KET_QUA_KIEM_TRA/design-system-cu.md` (colors, fonts, layout found in old app)
- State persistence: Update `.agents/state/active_case.json` with target details, report path, and set `current_phase = "SCAN_COMPLETED"`.
```
