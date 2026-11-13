---
name: rea-build
description: Triển khai mã nguồn đa lộ trình (Web Zero-Install, Android Native qua Antigravity Android CLI 'android create', hoặc Patch APK/Hybrid) vào thư mục 05_MA_NGUON_PHAT_TRIEN, thẩm định chất lượng độc lập theo chuẩn Anthropic (REVIEW.md), thực hiện smoke test trên browser hoặc AVD/Device Hub, hard verify đối chiếu 1-1 qua 'android layout' / 'android screen' và đóng gói bàn giao sản phẩm hoàn thiện. Phụ trách STAGE_04 (Implementation) và STAGE_05 (Validation) theo docs/WORKFLOW_LIFECYCLE.md.
---

# KỸ NĂNG: PHÁT TRIỂN, KIỂM ĐỊNH & BÀN GIAO SẢN PHẨM (REA-BUILD)

Kỹ năng chuyên biệt cho **STAGE_04 (Implementation)** và **STAGE_05 (Validation)** theo khung chuẩn 6 Stage · 14 Bước tại `docs/WORKFLOW_LIFECYCLE.md`.
Tuân thủ nghiêm ngặt hợp đồng thẩm định tại `REVIEW.md` và mô hình **Anthropic Code Review Pipeline** (*"How the Claude Code team does code review"*), kết hợp công cụ phát triển **Android CLI** của Google Antigravity.

---

## 1. PHÂN CÔNG THEO 2 GIAI ĐOẠN

### GIAI ĐOẠN 1: STAGE_04 · IMPLEMENTATION (Bước 09 & 10)

#### Bước 09: REA Build (Phát Triển Mã Nguồn Đa Lộ Trình)
1. **Kiểm tra điều kiện tiên quyết**: Đọc `03_KET_QUA_KIEM_TRA/KE_HOACH_TRIEN_KHAI.md`, `03_KET_QUA_KIEM_TRA/dac-ta-yeu-cau-da-chot.md` và `02_YEU_CAU_CUA_TOI/design.md`. (Bắt buộc Cổng 03 đã mở).
2. **Lá chắn hoàn tác tự động**: Tự động lưu snapshot mã nguồn cũ vào `05_MA_NGUON_PHAT_TRIEN/.backup/YYYYMMDD_HHmmss/` trước khi sửa code. Đảm bảo nút **`HOAN_TAC.bat`** luôn sẵn sàng.
3. **Nạp bài học quá khứ (Incidents to Evals)**: Đọc `.agents/state/learned_rules.json` để không tái phạm lỗi cũ.
4. **Triển khai theo Build Route đã duyệt**:
   - **Route A (Mặc định — Zero-Install Web App)**: Web App độc lập (`index.html`, `styles.css`, `app.js`) chạy trực tiếp trên trình duyệt, không bắt người dùng cài môi trường.
   - **Route B (Android Native Project)**: Sử dụng plugin **Android CLI** của Antigravity (`android create` hoặc template Android Gradle với Kotlin/Java) khởi tạo dự án Android chuẩn trong `05_MA_NGUON_PHAT_TRIEN/android/`, dựng UI bằng Jetpack Compose hoặc XML layouts bóc tách từ REA.
   - **Route C (Patch APK / Resources hoặc Web/Hybrid)**: Thực hiện vá tài nguyên/smali trực tiếp trên gói APK gốc hoặc đóng gói môi trường Hybrid (Capacitor/PWA).
5. Bắt buộc tuân thủ Design Tokens từ `design.md` và đủ 4 trạng thái UI: `Loading`, `Empty`, `Success`, `Error`.
6. **Bản xem trước Staged Preview**: Khi sửa đổi/nâng cấp, xuất ra `05_MA_NGUON_PHAT_TRIEN/preview.html` (hoặc bản build preview APK) trước khi thay thế bản chính.

#### Bước 10: Build QA / Code Review (Thẩm Định Độc Lập & Kiểm Soát Rủi Ro)
1. **Thẩm định 2 trục độc lập** theo `REVIEW.md`:
   - Trục Tiêu chuẩn (Standards): Đối chiếu Design Tokens và 4 trạng thái UI.
   - Trục Đặc tả (Spec): Đối chiếu tiêu chí hoàn thành trong `dac-ta-yeu-cau-da-chot.md`.
2. **Bộ lọc dẹp nhiễu (High-Signal Filter)**: Không bắt bẻ phong cách viết mã râu ria, chỉ tập trung vào lỗi thật.
3. Chạy script kiểm tra: `powershell -ExecutionPolicy Bypass -File .\.agents\scripts\verify_code.ps1`.
4. **Quy tắc hội tụ (Review Convergence)**: Tối đa 2 vòng tự sửa lỗi cú pháp.
5. **Chốt chặn phân tầng rủi ro**:
   - `LOW RISK`: UI/Text tĩnh ➔ Tự động duyệt sau khi syntax test OK.
   - `MEDIUM RISK`: Logic form, dữ liệu local ➔ Báo cáo checklist tính năng.
   - `HIGH RISK` / `SYNTAX ERROR`: Lỗi cú pháp hoặc gọi mạng ngoài không báo trước ➔ **CHẶN ĐỨNG**. Tuyệt đối không cho sang Stage 05.
6. Xuất báo cáo kiểm thử vào `03_KET_QUA_KIEM_TRA/KET_QUA_KIEM_THU.md` theo `templates/04-TEST-RESULT-TEMPLATE.md`.
7. **MỞ CỔNG 04 (`gate_04_build_qa_passed = true`)**: Cập nhật `active_case.json` và `docs/PROGRESS.md`.

---

### GIAI ĐOẠN 2: STAGE_05 · VALIDATION (Bước 11, 12 & 13)

#### Bước 11: Run App / Smoke Test (Khởi Chạy & Kiểm Thử Nhanh)
1. **Với Web App**: Hướng dẫn người dùng nhấp đúp file `05_MA_NGUON_PHAT_TRIEN/index.html` để chạy app trên trình duyệt.
2. **Với Android Native / APK**: Cài đặt và khởi chạy app mới trên máy ảo AVD hoặc thiết bị thật qua Antigravity Device Hub bằng lệnh `start_adb_app` hoặc Android CLI.
3. Kiểm tra nhanh luồng chính (Happy Path) để đảm bảo giao diện hiển thị đúng, tương tác phản hồi mượt mà.

#### Bước 12: Hard Verify (Đối Chiếu 1-1 Với App Gốc)
1. Đối chiếu trực tiếp với app gốc (hoặc ảnh chụp/tài nguyên tại `01_THA_APP_VAO_DAY/baseline/`):
   - **Với Android**: Sử dụng `android screen` hoặc `capture_adb_screen` để chụp ảnh màn hình app mới; dùng `android layout` để trích xuất cấu trúc phân cấp layout cây component và đối chiếu 1-1 với layout baseline tại Stage 01.
   - **Với Web**: Đối chiếu visual trực quan trên browser với baseline.
2. Lập bảng đối chiếu trực quan 3 cột:
   - Cột 1: Khớp 100% (Y hệt bản gốc).
   - Cột 2: Khác biệt có chủ đích (Đã thống nhất tại Bước 06).
   - Cột 3: Nâng cấp mới (Cải tiến UX/Bảo mật).
3. Điền theo mẫu `templates/08-HARD-VERIFY-TEMPLATE.md` và xuất vào:
   👉 `03_KET_QUA_KIEM_TRA/BAO_CAO_NGHIEM_THU_HARD_VERIFY.md`.
4. **MỞ CỔNG 05 (`gate_05_hard_verify_passed = true`)**: Khi người dùng xác nhận nghiệm thu đạt yêu cầu.
   *(Nếu bị từ chối: Tạo `FIX_PLAN_v2.md` và lùi về Bước 09 để sửa chữa cục bộ).*

#### Bước 13: Release & Handoff (Đóng Gói & Bàn Giao Trọn Gói)
1. Viết bản giải thích đời thường (Plain-Language Explainer) trả lời 3 câu hỏi (Làm gì, Tại sao, Cách dùng).
2. Hướng dẫn sử dụng nút `HOAN_TAC.bat` khi gặp sự cố.
3. Ký nhận trách nhiệm vận hành ("You Land It, You Own It").
4. Điền theo mẫu `templates/09-HANDOFF-BUNDLE-TEMPLATE.md` và xuất vào:
   👉 `05_MA_NGUON_PHAT_TRIEN/BAN_GIAO_SAN_PHAM.md`.
5. **MỞ CỔNG 06 (`gate_06_handoff_signed = true`)**: Hoàn tất dự án. Đồng bộ hóa toàn bộ thông tin vào `docs/PROGRESS.md` và `docs/HANDOFF.md`.
