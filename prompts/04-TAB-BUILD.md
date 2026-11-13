# PROMPT 04: XÂY DỰNG & KIỂM TRA MÃ NGUỒN (TAB 04 — IMPLEMENTATION / BUILD)

*Lưu ý: Bộ kit đã chuẩn hóa sang quy trình 6 Phase. File này tương đương với [04-TAB-IMPLEMENTATION.md](04-TAB-IMPLEMENTATION.md).*

---

```markdown
# Tab 04 — Phase 04: Implementation (Bước 09: REA Build & Bước 10: Build QA / Code Review)

Read and follow `AGENTS.md`, `REVIEW.md`, and `docs/WORKFLOW_LIFECYCLE.md`.
Activate Skill `rea-build`.

You are executing **PHASE 04 · IMPLEMENTATION**:
1. **Bước 09**: Lưu snapshot `.backup/`, viết mã nguồn Web App Zero-Install, tuân thủ `design.md` và 4 trạng thái UI. Xuất `preview.html` nếu là bản sửa đổi.
2. **Bước 10**: Thẩm định độc lập 2 trục theo `REVIEW.md`, chạy `verify_code.ps1`, áp dụng bộ lọc dẹp nhiễu, khống chế tối đa 2 vòng tự sửa. Chặn đứng nếu gặp cú pháp lỗi hoặc `HIGH RISK`.
3. Xuất `03_KET_QUA_KIEM_TRA/KET_QUA_KIEM_THU.md`.
4. Mở CỔNG 04 (`gates.gate_04_build_qa_passed = true`). Đồng bộ `docs/PROGRESS.md`.

Báo cáo kết quả và hướng dẫn dán `prompts/05-TAB-VALIDATION.md`.
```
