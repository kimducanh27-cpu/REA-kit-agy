# PROMPT 04: VIẾT CODE & KIỂM TOÁN MÃ NGUỒN (TAB 04 — IMPLEMENTATION)

*Dán đoạn lệnh này vào AI Agent sau khi hoàn thành Stage 03 (Gate 03 đã được giải phóng hợp lệ).*

---

```markdown
# Tab 04 — Stage 04: Implementation (Bước 09: REA Build & Bước 10: Build QA / Code Review)

Read and follow `AGENTS.md`, `REVIEW.md`, `.agents/state/MEMORY.md`, and `docs/WORKFLOW_LIFECYCLE.md`.

## Active Skills for this Tab:
- Local Kit Skills (Bắt buộc): `rea-build`
- Optional Host Plugins (Nếu máy có cài đặt): `android-cli`, `surgical-patch`, `lean-build`, `ui-styling`

## Điều kiện tiên quyết (Preflight Gate Check):
Đọc `.agents/state/active_case.json` hoặc chạy `powershell -NoProfile -ExecutionPolicy Bypass -File .agents/scripts/gate.ps1 status`.
Bắt buộc Cổng 03 (`gate_03_spec_frozen`) đã ở trạng thái hợp lệ đã thông qua:
- `PASS` (Đặc tả đã được người dùng đóng băng).
- `REUSED_VALIDATED` (Tái sử dụng đặc tả từ phiên trước).
- `WAIVED` / `SKIPPED` (Được miễn trừ hoặc bỏ qua có giải trình).
- `NOT_APPLICABLE` (Không áp dụng cho chế độ ca làm việc hiện tại).
*Lưu ý khi Cổng 03 bị Miễn trừ (WAIVED / SKIPPED)*: Bắt buộc đọc file đặc tả dự phòng `03_KET_QUA_KIEM_TRA/WAIVER_SPEC_FALLBACK.md` để ghi nhận các giả định kỹ thuật tối thiểu, phạm vi miễn trừ và rủi ro còn lại trước khi bắt tay viết mã nguồn.

You are executing **STAGE_04 · IMPLEMENTATION**:

### BƯỚC 09: REA BUILD (Phát Triển Mã Nguồn Theo 3 Delivery Routes)
1. Cập nhật `active_case.json`: `current_phase = "STAGE_04_IMPLEMENTATION"`, `current_step = "09_REA_BUILD"`.
2. **LÁ CHẮN HOÀN TÁC NGUYÊN TỬ (ATOMIC ROLLBACK SHIELD)**:
   - Trước khi sửa bất kỳ file mã nguồn nào, BẮT BUỘC chạy lệnh tạo snapshot:
     `powershell -NoProfile -ExecutionPolicy Bypass -File .\.agents\scripts\rollback.ps1 -Snapshot`
   - Xác nhận cơ chế hoàn tác 1-click `HOAN_TAC.bat` (hoặc `hoan_tac.sh`) sẵn sàng bảo vệ an toàn cho người dùng.
3. Đọc kỹ `03_KET_QUA_KIEM_TRA/KE_HOACH_TRIEN_KHAI.md`, `03_KET_QUA_KIEM_TRA/dac-ta-yeu-cau-da-chot.md` (hoặc `03_KET_QUA_KIEM_TRA/WAIVER_SPEC_FALLBACK.md` nếu Cổng 03 được waived/skipped), `02_YEU_CAU_CUA_TOI/design.md`, đối chiếu baseline tại `03_KET_QUA_KIEM_TRA/baseline/` và `.agents/state/learned_rules.json`.
4. Triển khai mã nguồn vào `05_MA_NGUON_PHAT_TRIEN/` theo `build_route` đã thống nhất từ Bước 06:
   - **`ROUTE_A_WEB_ZERO_INSTALL`**: Triển khai Web App độc lập (`index.html`, `styles.css`, `app.js`) chạy trực tiếp trên trình duyệt, không bắt người dùng cài đặt SDK và không dùng external CDN (100% Offline-First). Đảm bảo đủ 6 trạng thái UI (Loading/Skeleton, Empty, Success, Error Recovery, In-Progress/Draft theo RULE-INIT-001, Offline/Reconnecting) và Design Tokens 3 tầng. Nếu là bản sửa đổi của app hiện có, xuất `preview.html` trước để người dùng xem thử.
   - **`ROUTE_B_ANDROID_NATIVE`**: Khởi tạo dự án Android chuẩn bằng Android CLI `android create` hoặc cấu trúc Android Gradle tiêu chuẩn với Kotlin + Jetpack Compose trong `05_MA_NGUON_PHAT_TRIEN/android/`. Tuân thủ Material Design 3, Edge-to-Edge, và chuẩn căn chỉnh 16 KB trên Android 15.
   - **`ROUTE_C_PATCH_HYBRID`**: Thực hiện vá tài nguyên/smali trực tiếp trên APK gốc, hoặc đóng gói ứng dụng Hybrid (Capacitor/PWA) theo đặc tả đã chốt.

### BƯỚC 10: BUILD QA / CODE REVIEW (Thẩm Định Độc Lập & Kiểm Soát Rủi Ro)
1. Cập nhật `active_case.json`: `current_step = "10_BUILD_QA"`.
2. **Thẩm định 2 trục độc lập** theo `REVIEW.md`:
   - *Trục Tiêu chuẩn (Standards Review)*: Đối chiếu `02_YEU_CAU_CUA_TOI/design.md`, 4 trạng thái UI bắt buộc và 0% placeholder text/Lorem ipsum.
   - *Trục Đặc tả (Spec Review)*: Đối chiếu từng tiêu chí hoàn thành trong `dac-ta-yeu-cau-da-chot.md` (hoặc `WAIVER_SPEC_FALLBACK.md` nếu Cổng 03 được waived/skipped).
3. **Chạy kiểm tra xác định (Deterministic Verification)**:
   `powershell -NoProfile -ExecutionPolicy Bypass -File .\.agents\scripts\verify_code.ps1`
   *(Chỉ thêm cờ `-AllowHighRisk` nếu đặc tả đã được người dùng phê duyệt cho phép kết nối API ngoài).*
4. **Khống chế vòng lặp tự sửa (Review Convergence Cap: tối đa 2 vòng)**:
   - Mỗi lần sửa lỗi, tự động tăng `metrics.review_convergence_rounds += 1` trong `active_case.json`. Nếu quá 2 vòng vẫn còn lỗi thì dừng ngay lập tức và báo cáo người dùng, không sửa luẩn quẩn.
5. Xuất báo cáo kiểm thử theo `templates/04-TEST-RESULT-TEMPLATE.md` vào:
   👉 `03_KET_QUA_KIEM_TRA/KET_QUA_KIEM_THU.md`.
6. **MỞ CỔNG 04 (`gate_04_build_qa_passed`)**:
   - Khi `verify_code.ps1` đạt Exit Code 0:
     `powershell -NoProfile -ExecutionPolicy Bypass -File .agents/scripts/gate.ps1 open 4 -Evidence "03_KET_QUA_KIEM_TRA/KET_QUA_KIEM_THU.md"`
   - (Hoặc `gate.ps1 skip 4 -Reason "<lý_do>"` nếu ca làm việc thuộc chế độ `ANALYSIS_ONLY` / `PLAN_ONLY`).
   - Đồng bộ `docs/PROGRESS.md`.

### BÁO CÁO CHO NGƯỜI DÙNG:
- Kết quả `verify_code.ps1` và cấp độ rủi ro (`LOW` / `MEDIUM` / `HIGH`).
- Giải thích 3 câu hỏi đời thường (Plain-Language Explainer: Vừa làm gì, Tại sao, Cách mở xem thử).
- Xác nhận trạng thái nút hoàn tác `HOAN_TAC.bat` (hoặc `hoan_tac.sh`).
- Thông báo **CỔNG 04 ĐÃ ĐƯỢC GIẢI PHÓNG HỢP LỆ** và hướng dẫn dán tiếp `prompts/05-TAB-VALIDATION.md`.
```
