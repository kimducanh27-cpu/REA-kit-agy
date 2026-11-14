# PROMPT 04: VIẾT CODE & KIỂM TOÁN MÃ NGUỒN (TAB 04 — IMPLEMENTATION)

*Dán đoạn lệnh này vào AI Agent sau khi hoàn thành Stage 03 (Gate 03 đã mở).*

---

```markdown
# Tab 04 — Stage 04: Implementation (Bước 09: REA Build & Bước 10: Build QA / Code Review)

Read and follow `AGENTS.md`, `REVIEW.md`, and `docs/WORKFLOW_LIFECYCLE.md`.
Activate Skill `rea-build`.

## Điều kiện tiên quyết:
Kiểm tra `.agents/state/active_case.json`. Nếu `gates.gate_03_spec_frozen` chưa đạt (`false`), dừng lại và yêu cầu hoàn thành Stage 03 trước.

You are executing **STAGE_04 · IMPLEMENTATION**:

### BƯỚC 09: REA BUILD (Phát Triển Mã Nguồn Chuẩn Zero-Install)
1. **LÁ CHẮN HOÀN TÁC**: Tự động lưu snapshot mã nguồn hiện tại vào `05_MA_NGUON_PHAT_TRIEN/.backup/`.
2. Đọc `03_KET_QUA_KIEM_TRA/KE_HOACH_TRIEN_KHAI.md` và `02_YEU_CAU_CUA_TOI/design.md`.
3. Viết mã nguồn vào `05_MA_NGUON_PHAT_TRIEN/`:
   - Ưu tiên Web App độc lập (`index.html`, `styles.css`, `app.js`).
   - Tuân thủ nghiêm ngặt CSS Tokens từ `design.md`.
   - Triển khai đủ 4 trạng thái UI: `Loading`, `Empty`, `Success`, `Error`.
4. **Bản xem trước Staged Preview**: Nếu là sửa đổi/nâng cấp, xuất ra `05_MA_NGUON_PHAT_TRIEN/preview.html` trước khi ghi đè `index.html`.

### BƯỚC 10: BUILD QA / CODE REVIEW (Thẩm Định Độc Lập & Kiểm Soát Rủi Ro)
1. **Thẩm định 2 trục độc lập** theo `REVIEW.md`:
   - Trục Tiêu chuẩn (Standards): Đối chiếu Design Tokens và 4 trạng thái UI.
   - Trục Đặc tả (Spec): Đối chiếu tiêu chí hoàn thành trong `dac-ta-yeu-cau-da-chot.md`.
2. **Bộ lọc dẹp nhiễu (High-Signal Filter)**: Không bắt bẻ phong cách code/comment, chỉ báo cáo lỗi thực tế.
3. Chạy script kiểm tra cú pháp và quét rủi ro:
   `powershell -ExecutionPolicy Bypass -File .\.agents\scripts\verify_code.ps1`
4. **Khống chế vòng lặp tự sửa (Review Convergence Cap)**: Tối đa 2 vòng lặp tự sửa lỗi cú pháp.
5. **Chốt chặn phân tầng rủi ro**:
   - `LOW RISK`: UI/Text tĩnh ➔ Tự động duyệt sau khi syntax OK.
   - `MEDIUM RISK`: Logic form, LocalStorage ➔ Báo cáo checklist tính năng.
   - `HIGH RISK` / `SYNTAX ERROR`: Lỗi cú pháp hoặc gọi mạng ngoài không phép ➔ **CHẶN ĐỨNG**. Không cho phép sang Stage 05.
6. Xuất báo cáo kiểm thử vào:
   👉 `03_KET_QUA_KIEM_TRA/KET_QUA_KIEM_THU.md`.
7. **CỔNG 04 (Quality Gate 04: `gate_04_build_qa_passed`)**:
   - Khi syntax 100% OK và không còn lỗi chặn:
   - Cập nhật `active_case.json`: `gates.gate_04_build_qa_passed = true`, `current_phase = "STAGE_04_IMPLEMENTATION"`, `current_step = "10_BUILD_QA"`.
   - Cập nhật checklist trong `docs/PROGRESS.md`.

### BÁO CÁO CHO NGƯỜI DÙNG:
Báo cáo ngắn gọn bằng tiếng Việt đời thường:
- Kết quả kiểm tra cú pháp và mức độ rủi ro (LOW/MEDIUM/HIGH).
- Giải thích 3 câu hỏi đời thường (Explainer: Vừa làm gì, Tại sao, Cách mở xem thử).
- Thông báo CỔNG 04 ĐÃ MỞ. Hướng dẫn dán `prompts/05-TAB-VALIDATION.md`.
```
