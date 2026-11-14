---
name: rea-build
description: Phụ trách độc quyền STAGE_04 (Bước 09 REA Build & Bước 10 Build QA / Code Review) và STAGE_05 (Bước 11 Smoke Test, Bước 12 Hard Verify & Bước 13 Release & Handoff). Tự động tạo snapshot hoàn tác, viết code theo Build Route A/B/C, chạy verify_code.ps1 với giới hạn hội tụ 2 vòng, kiểm thử đối chiếu 1-1 qua 'android layout --full' / 'android screen capture -o' và bàn giao sản phẩm.
---

# KỸ NĂNG: PHÁT TRIỂN, KIỂM ĐỊNH ĐỘC LẬP & BÀN GIAO (REA-BUILD)

Kỹ năng chuyên biệt cho **STAGE_04 (Implementation)** và **STAGE_05 (Validation)** theo `docs/WORKFLOW_LIFECYCLE.md` và hợp đồng thẩm định `REVIEW.md`.

---

## 1. STAGE_04 · IMPLEMENTATION (Bước 09 & Bước 10)

### Bước 09: REA Build (Phát Triển Mã Nguồn Theo Lát Cắt)
1. **Kiểm tra điều kiện tiên quyết**: Đọc `.agents/state/active_case.json`. Bắt buộc Cổng 03 đã đóng băng (`state == "PASS"` hoặc `"REUSED_VALIDATED"`) qua lệnh `gate.ps1 status` mới được thực thi. Cập nhật `current_phase = "STAGE_04_IMPLEMENTATION"`, `current_step = "09_REA_BUILD"`.
2. **Tạo Snapshot Hoàn Tác Tự Động**:
   - Chạy lệnh: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.agents\scripts\rollback.ps1 -Snapshot`
   - *(Script tự động bỏ qua nếu thư mục phát triển đang trống để không tạo snapshot rỗng)*.
3. **Nạp bộ nhớ bài học (`MEMORY.md` & `learned_rules.json`)**: Tuân thủ nghiêm ngặt `RULE-INIT-001` (bảo toàn dữ liệu form khi lỗi) và Design Tokens 3 tầng tại `02_YEU_CAU_CUA_TOI/design.md`.
4. **Triển khai mã nguồn theo `build_route` đã chốt**:
   - **Route A (`ROUTE_A_WEB_ZERO_INSTALL`)**: Triển khai Web App độc lập (`index.html`, `styles.css`, `app.js`) trong `05_MA_NGUON_PHAT_TRIEN/`. Nếu nâng cấp ứng dụng đã có, xuất `preview.html` trước khi ghi đè `index.html`.
   - **Route B (`ROUTE_B_ANDROID_NATIVE`)**: Khởi tạo dự án Android chuẩn bằng lệnh Android CLI `android create` (hoặc cấu trúc Gradle + Kotlin + Jetpack Compose) tại `05_MA_NGUON_PHAT_TRIEN/android/`.
   - **Route C (`ROUTE_C_PATCH_HYBRID`)**: Vá tài nguyên/smali hoặc đóng gói ứng dụng Hybrid theo đặc tả.

### Bước 10: Build QA / Code Review (Thẩm Định Độc Lập & Kiểm Soát Rủi Ro)
1. Cập nhật `active_case.json`: `current_step = "10_BUILD_QA"`.
2. **Thẩm định 2 trục độc lập** theo `REVIEW.md`:
   - Trục Tiêu chuẩn (Standards): Đối chiếu Design Tokens và đủ 4 trạng thái UI (`Loading`, `Empty`, `Success`, `Error`).
   - Trục Đặc tả (Spec): Đối chiếu từng tiêu chí nghiệm thu trong `03_KET_QUA_KIEM_TRA/dac-ta-yeu-cau-da-chot.md`.
3. **Kiểm tra xác định (Deterministic Verification)**:
   - Chạy: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.agents\scripts\verify_code.ps1` (thêm `-AllowHighRisk` chỉ khi người dùng đã phê duyệt kết nối mạng ngoài trong đặc tả).
   - Script kiểm tra cả file `.js` rời lẫn khối `<script>` inline trong `.html`, quét rò rỉ secret trên cả `05_MA_NGUON_PHAT_TRIEN/` và `03_KET_QUA_KIEM_TRA/`, và kiểm tra cấu trúc Android (`AndroidManifest.xml`, `build.gradle*`).
4. **Khống chế vòng lặp tự sửa (Review Convergence Cap = 2 vòng)**:
   - Mỗi lần `verify_code.ps1` báo lỗi (`Exit Code 1`), tăng `metrics.review_convergence_rounds += 1` trong `active_case.json` và sửa lỗi.
   - Nếu `review_convergence_rounds > 2` mà vẫn lỗi, **dừng lại ngay lập tức**, chạy `powershell -File .\.agents\scripts\gate.ps1 reject 4 -Reason "Hội tụ thất bại sau 2 vòng tự sửa"` và báo cáo điểm nghẽn cho người dùng.
5. **MỞ CỔNG 04 (`gate_04_build_qa_passed`)**:
   - Khi `verify_code.ps1` đạt `Exit Code 0` và Independent Review PASS:
   - Xuất báo cáo vào `03_KET_QUA_KIEM_TRA/KET_QUA_KIEM_THU.md` theo `templates/04-TEST-RESULT-TEMPLATE.md`.
   - Chạy lệnh mở cổng:
     `powershell -NoProfile -ExecutionPolicy Bypass -File .\.agents\scripts\gate.ps1 open 4 -Evidence 03_KET_QUA_KIEM_TRA/KET_QUA_KIEM_THU.md -ApprovedBy "independent-reviewer"`
   - Cập nhật `next_prompt_guide = "Dán 'prompts/05-TAB-VALIDATION.md' để chạy nghiệm thu Hard Verify và bàn giao."`.
   - Đồng bộ `docs/PROGRESS.md`.

---

## 2. STAGE_05 · VALIDATION (Bước 11, 12 & 13)

### Bước 11: Run App / Smoke Test
1. Kiểm tra Cổng 04 đã `PASS` qua `gate.ps1 status`. Cập nhật `current_phase = "STAGE_05_VALIDATION"`, `current_step = "11_SMOKE_TEST"`.
2. **Với Route A (Web)**: Hướng dẫn mở `05_MA_NGUON_PHAT_TRIEN/index.html` trên trình duyệt.
3. **Với Route B/C (Android)**: Triển khai và chạy lên AVD/thiết bị qua lệnh Android CLI `android run` hoặc `./gradlew installDebug` kết hợp REA MCP `start_adb_app` (`serial`, `package`).

### Bước 12: Hard Verify (Đối Chiếu 1-1 Với App Gốc)
1. Cập nhật `active_case.json`: `current_step = "12_HARD_VERIFY"`.
2. **Đối chiếu trực quan & cấu trúc**:
   - **Với Android**: Chụp màn hình bằng `android screen capture -o <file_path>` hoặc REA MCP `capture_adb_screen` (tham số JSON: `serial`, `output_directory` dạng snake_case, đường dẫn tuyệt đối); trích xuất cây UI bằng `android layout --full` và so sánh 1-1 với baseline tại `01_THA_APP_VAO_DAY/baseline/`.
   - **Với Web**: Đối chiếu trực tiếp trên trình duyệt với ảnh chụp/tài nguyên baseline.
3. Xuất bảng đối chiếu 3 cột (Khớp 100% / Khác biệt có chủ đích / Nâng cấp mới) theo `templates/08-HARD-VERIFY-TEMPLATE.md` vào:
   👉 `03_KET_QUA_KIEM_TRA/BAO_CAO_NGHIEM_THU_HARD_VERIFY.md`.
4. **Xử lý kết quả CỔNG 05 (`gate_05_hard_verify_passed`)**:
   - **Khi người dùng xác nhận ĐẠT**:
     * Chạy lệnh mở cổng:
       `powershell -NoProfile -ExecutionPolicy Bypass -File .\.agents\scripts\gate.ps1 open 5 -Evidence 03_KET_QUA_KIEM_TRA/BAO_CAO_NGHIEM_THU_HARD_VERIFY.md -ApprovedBy "user"`
   - **Khi người dùng yêu cầu sửa (Reject Loop — Gate Invalidation Invariant)**:
     * Chạy lệnh tự động thu hồi cổng và quay lui:
       `powershell -NoProfile -ExecutionPolicy Bypass -File .\.agents\scripts\gate.ps1 reject 5 -Reason "Người dùng yêu cầu điều chỉnh lại tính năng hoặc giao diện sau khi đối chiếu 1-1."`
     * Xuất `03_KET_QUA_KIEM_TRA/FIX_PLAN_v2.md`.
     * Reset `metrics.review_convergence_rounds = 0`.

### Bước 13: Release & Handoff (Đóng Gói & Bàn Giao)
1. Cập nhật `active_case.json`: `current_step = "13_RELEASE_AND_HANDOFF"`.
2. Xuất gói bàn giao kèm Plain-Language Explainer và hướng dẫn `HOAN_TAC.bat` theo `templates/09-HANDOFF-BUNDLE-TEMPLATE.md` vào:
   👉 `05_MA_NGUON_PHAT_TRIEN/BAN_GIAO_SAN_PHAM.md`.
3. **MỞ CỔNG 06 (`gate_06_handoff_signed`)**:
   - Khi người dùng ký nhận bàn giao:
     `powershell -NoProfile -ExecutionPolicy Bypass -File .\.agents\scripts\gate.ps1 open 6 -Evidence 05_MA_NGUON_PHAT_TRIEN/BAN_GIAO_SAN_PHAM.md -ApprovedBy "user"`
   - Đồng bộ `docs/PROGRESS.md` và `docs/HANDOFF.md`.
