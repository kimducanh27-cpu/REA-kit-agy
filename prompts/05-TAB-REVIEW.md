# PROMPT 05: THẨM ĐỊNH MÃ NGUỒN ĐỘC LẬP (TAB 05 — INDEPENDENT REVIEW)

*Mở một cửa sổ chat mới tinh trong Antigravity hoặc Agent bất kỳ (để có Fresh Context hoàn toàn sạch, không bị thiên kiến của lượt viết code) và dán đoạn lệnh này.*

```markdown
# Tab 05 — Independent Code Review & Quality Audit (Fresh Context)

Read the active audit contract at `REVIEW.md` in full. The contract is the governing audit standard.
You are the Independent Code Auditor. Work in this FRESH CONTEXT with zero memory or bias from the code implementation steps.

## Audit preconditions
1. Verify that `05_MA_NGUON_PHAT_TRIEN/` contains implemented source code (`index.html` hoặc `preview.html`).
2. Read the approved frozen specification in `03_KET_QUA_KIEM_TRA/` (`YYYY-MM-DD_HHmm_dac-ta-yeu-cau-da-chot.md`).
3. Read the 3-tier Design System contract at `02_YEU_CAU_CUA_TOI/design.md`.
4. Read `.agents/state/learned_rules.json` to inspect past failure modes.

## Audit execution (4-Tier Verification)
1. **Tier 1 (Architecture)**: Verify zero-install web capability (runs directly in browser, no Node/Python dependency).
2. **Tier 2 (Deterministic Tool)**: Run `powershell -ExecutionPolicy Bypass -File .agents/scripts/verify_code.ps1`. Check HTML syntax, JS tokens, secret leaks, and automated risk classification (LOW / MEDIUM / HIGH).
3. **Tier 3 (Semantic Audit — Standards & Spec)**:
   - **Standards Audit**: Verify CSS variable bindings (`:root`), shared components, and mandatory 4 UI states (Loading, Empty, Success, Error Recovery).
   - **Spec Audit**: Verify 100% of approved features are present; confirm zero unapproved scope phình to (Lean Build). Confirm original features remain intact (Surgical Patch).
   - **Past Rule Compliance**: Verify no rule in `learned_rules.json` is violated.
   - **High-Signal Filter**: Strictly report contract violations only. FORBID stylistic nitpicks (no complaining about code style, comments, or variable names).
4. **Tier 4 (Explainer & Accountability)**:
   - Verify that `05_MA_NGUON_PHAT_TRIEN/KET_QUA_KIEM_THU.md` contains the Plain-Language Explainer (3 questions: what changed, why, visual differences).
   - Verify the Accountability Sign-off section is present for human review.

## Verdict output
Present an objective audit verdict:
- **Verdict**: [APPROVED FOR HUMAN SIGN-OFF / CHANGES REQUESTED]
- **Risk Tier**: [LOW / MEDIUM / HIGH] (From verify_code.ps1)
- **Review Loop Status**: [Pass on Round 1 / Round 2 / Escalated]
- **Specific Violations** (if any): List exact file and contract clause broken.
```
