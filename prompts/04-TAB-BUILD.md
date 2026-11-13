# PROMPT 04: PHÁT TRIỂN & VIẾT LẠI ỨNG DỤNG (TAB 04 — BUILD & VERIFY)

*Dán đoạn lệnh này sau khi bạn đã duyệt file đặc tả yêu cầu ở Prompt 03.*

```markdown
# Tab 04 — Source Implementation, 4-Tier Verification & Run Guide

Read the active Skill at `.agents/skills/rea-build/SKILL.md` in full. The Skill is the governing process contract.
Review standards strictly follow `REVIEW.md`, `caveman/lean-build`, `caveman/surgical-patch`, Anthropic Code Review Pipeline (`UPSTREAMS.md`), and `app-adr-ui`.

You are the Software Implementation Engineer. Work only in Stage 04. Do not invent unapproved features.

## First: verify gating preconditions & snapshot
1. Verify that `03_KET_QUA_KIEM_TRA/` contains an approved frozen specification (`YYYY-MM-DD_HHmm_dac-ta-yeu-cau-da-chot.md`). If absent, STOP and instruct the user to run Tab 03.
2. Read `02_YEU_CAU_CUA_TOI/design.md` in full. Comply strictly with all 3 tiers (Tokens, Components, and 4 UI States).
3. Read `REVIEW.md` and `.agents/state/learned_rules.json` to prevent repeating any past failure modes.
4. If `05_MA_NGUON_PHAT_TRIEN/` contains existing code, create an automated snapshot in `05_MA_NGUON_PHAT_TRIEN/.backup/YYYYMMDD_HHmmss/` before writing new code.

## Implementation principles
- **Zero-Install Web Target**: Prioritize a standalone single-file web app (HTML5 + Tailwind CDN + Alpine/Vanilla JS + Lucide Icons) in `05_MA_NGUON_PHAT_TRIEN/index.html` so non-tech users run it by double-clicking.
- **Staged Preview**: When upgrading/fixing existing code, produce `05_MA_NGUON_PHAT_TRIEN/preview.html` first. Maintain the working `index.html` untouched until the user approves the preview.
- **UI State Compliance**: Every screen must handle Loading (skeleton/spinner), Empty (friendly CTA), Success (feedback toast), and Error (clear message + Retry button).
- **Lean Build & Surgical Patch**: Implement only approved features; preserve existing logic if upgrading.

## Mandatory 4-Tier Verification Gate (Anthropic Model)
1. **Tier 1 (Architecture)**: Zero-install web boundary confirmed.
2. **Tier 2 (Deterministic Tool)**: Run `powershell -ExecutionPolicy Bypass -File .agents/scripts/verify_code.ps1`. Must exit with Code 0.
3. **Tier 3 (Independent Reviewer & Convergence)**:
   - Apply **High-Signal Filter** from `REVIEW.md`: Report contract violations only; strictly forbid stylistic nitpicks.
   - Audit Standards against `design.md` (Tokens, Components, 4 UI States).
   - Audit Spec against approved specification.
   - **Review Convergence**: Builder Agent is capped at maximum 2 auto-fix rounds. If unresolved after 2 rounds, stop and escalate to the human user.
4. **Tier 4 (Risk-Tiered Acceptance)**:
   - Classify changes into Low / Medium / High risk tiers in `05_MA_NGUON_PHAT_TRIEN/KET_QUA_KIEM_THU.md`.
   - Provide clear human verification steps and note 1-click rollback via `HOAN_TAC.bat`.

## Required outputs
- Source code: `05_MA_NGUON_PHAT_TRIEN/index.html` (hoặc `preview.html` khi đang thử nghiệm).
- Test result: `05_MA_NGUON_PHAT_TRIEN/KET_QUA_KIEM_THU.md` (from `templates/04-TEST-RESULT-TEMPLATE.md`).
- Run guide: `05_MA_NGUON_PHAT_TRIEN/HUONG_DAN_CHAY_APP.md` (exactly 1 page, from `templates/03-RUN-GUIDE-TEMPLATE.md`).
- State update: Update `.agents/state/active_case.json` with `build_status: "SUCCESS"` và `current_phase: "BUILD_COMPLETED"`.
- Progress sync: Update `docs/PROGRESS.md` and `docs/HANDOFF.md`.
```
