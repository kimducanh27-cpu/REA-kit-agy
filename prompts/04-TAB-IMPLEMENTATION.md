# PROMPT 04: VIẾT CODE & KIỂM TOÁN MÃ NGUỒN (TAB 04 — IMPLEMENTATION)

*Dán đoạn lệnh này vào AI Agent sau khi hoàn thành Stage 03 (Gate 03 đã mở).*

---

```markdown
# Tab 04 — Stage 04: Implementation (Bước 09: REA Build & Bước 10: Build QA / Code Review)

Read and follow `AGENTS.md`, `REVIEW.md`, `.agents/state/MEMORY.md`, and `docs/WORKFLOW_LIFECYCLE.md`.

## Active Skills for this Tab:
- Local Kit Skills (Bắt buộc): `rea-build`
- Optional Host Plugins (Nếu máy có cài đặt): `android-cli`

## Điều kiện tiên quyết:
Đọc `.agents/state/active_case.json` hoặc chạy `powershell -File .agents/scripts/gate.ps1 status`. Bắt buộc Cổng 03 đã ở trạng thái `PASS` hoặc `REUSED_VALIDATED` (Đặc tả đã đóng băng) mới được phép viết mã nguồn.

You are executing **STAGE_04 · IMPLEMENTATION**:

### BƯỚC 09: REA BUILD (Phát Triển Mã Nguồn Theo Build Route)
1. Cập nhật `active_case.json`: `current_phase = "STAGE_04_IMPLEMENTATION"`, `current_step = "09_REA_BUILD"`.
2. **LÁ CHẮN HOÀN TÁC**: Chạy lệnh tạo snapshot tự động trước khi sửa mã nguồn:
   `powershell -NoProfile -ExecutionPolicy Bypass -File .\.agents\scripts\rollback.ps1 -Snapshot`
3. Đọc kỹ `03_KET_QUA_KIEM_TRA/KE_HOACH_TRIEN_KHAI.md`, `03_KET_QUA_KIEM_TRA/dac-ta-yeu-cau-da-chot.md`, `02_YEU_CAU_CUA_TOI/design.md` và `.agents/state/learned_rules.json`.
4. Triển khai mã nguồn vào `05_MA_NGUON_PHAT_TRIEN/` theo `build_route` đã duyệt:
   - **`ROUTE_A_WEB_ZERO_INSTALL`**: `index.html`, `styles.css`, `app.js` (chạy trực tiếp trên trình duyệt, đủ 4 trạng thái UI). Nếu cập nhật app đã có, xuất `preview.html` trước.
   - **`ROUTE_B_ANDROID_NATIVE`**: Khởi tạo dự án Android chuẩn bằng `android create` hoặc Gradle + Kotlin + Jetpack Compose trong `05_MA_NGUON_PHAT_TRIEN/android/`.
   - **`ROUTE_C_PATCH_HYBRID`**: Vá tài nguyên/smali hoặc đóng gói Hybrid theo đặc tả.

### BƯỚC 10: BUILD QA / CODE REVIEW (Thẩm Định Độc Lập & Kiểm Soát Rủi Ro)
1. Cập nhật `active_case.json`: `current_step = "10_BUILD_QA"`.
2. **Thẩm định 2 trục độc lập** theo `REVIEW.md` (Trục Standards đối chiếu `design.md` & 4 UI States; Trục Spec đối chiếu `dac-ta-yeu-cau-da-chot.md`).
3. **Chạy kiểm tra xác định**:
   `powershell -NoProfile -ExecutionPolicy Bypass -File .\.agents\scripts\verify_code.ps1`
   *(Chỉ thêm cờ `-AllowHighRisk` nếu đặc tả đã được người dùng phê duyệt cho phép kết nối API ngoài).*
4. **Khống chế vòng lặp tự sửa (`review_convergence_rounds <= 2`)**:
   - Mỗi lần sửa lỗi, tăng `metrics.review_convergence_rounds += 1` trong `active_case.json`. Quá 2 vòng vẫn lỗi thì dừng ngay và báo cáo người dùng.
5. Xuất báo cáo kiểm thử theo `templates/04-TEST-RESULT-TEMPLATE.md` vào:
   👉 `03_KET_QUA_KIEM_TRA/KET_QUA_KIEM_THU.md`.
6. **MỞ CỔNG 04 (`gate_04_build_qa_passed`)**:
   - Khi `verify_code.ps1` đạt `Exit Code 0`: Chạy lệnh `powershell -File .agents/scripts/gate.ps1 open 4 -Evidence "03_KET_QUA_KIEM_TRA/KET_QUA_KIEM_THU.md"` và đồng bộ `docs/PROGRESS.md`.

### BÁO CÁO CHO NGƯỜI DÙNG:
- Kết quả `verify_code.ps1` và cấp độ rủi ro (`LOW` / `MEDIUM` / `HIGH`).
- Giải thích 3 câu hỏi đời thường (Explainer: Vừa làm gì, Tại sao, Cách mở xem thử).
- Thông báo **CỔNG 04 ĐÃ MỞ** và hướng dẫn dán tiếp `prompts/05-TAB-VALIDATION.md`.
```
