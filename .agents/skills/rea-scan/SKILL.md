---
name: rea-scan
description: Phụ trách độc quyền STAGE_01 (Bước 01 App Intake & Bước 02 Reference Baseline) và STAGE_02 phần điều tra (Bước 03 REA Scan & Bước 04 REA Investigate). Tự động sao lưu nguyên vẹn vào 04_SAO_LUU_AN_TOAN, cài đặt & đo kiểm baseline qua Android CLI ('android run', 'android layout --full', 'android screen capture -o') hoặc REA ADB ('capture_adb_screen' với 'output_directory'), fallback tĩnh 3 lớp (JADX + Apktool + Artifact Inventory), che mờ [REDACTED] và xuất báo cáo hiện trạng vào 03_KET_QUA_KIEM_TRA/bao-cao-hien-trang.md.
---

# KỸ NĂNG: KHÁM PHÁ, ĐO BASELINE & ĐIỀU TRA DỊCH NGƯỢC (REA-SCAN)

Kỹ năng chuyên biệt cho **STAGE_01 (Bước 01 & 02)** và **STAGE_02 (Bước 03 & 04)** theo `docs/WORKFLOW_LIFECYCLE.md`.
*(Lưu ý ranh giới: Bước 05 Kiểm toán độc lập & mở Cổng 02 do kỹ năng `rea-audit` đảm nhiệm riêng biệt).*

---

## 1. GIAI ĐOẠN 1: STAGE_01 · DISCOVERY (Bước 01 & 02)

### Bước 01: App Intake / Preflight
1. Quét thư mục `01_THA_APP_VAO_DAY/`. Nếu có nhiều hơn 1 file ứng dụng, liệt kê bảng kiểm kê và hỏi người dùng chọn mục tiêu.
2. **Sao lưu bất khả xâm phạm**: Sao chép nguyên vẹn 100% file gốc sang `04_SAO_LUU_AN_TOAN/` và kiểm tra khớp mã băm SHA-256.
3. Cập nhật `.agents/state/active_case.json`:
   - Gán `case_id` (ví dụ `"CASE-001"`), `target_name`, `target_class` (`"ANDROID_APK"`, `"WEB_SPA"`, `"ELECTRON_DESKTOP"`, `"NATIVE_BINARY"`, hoặc `"SOURCE_REPO"`).
   - Đặt `backup_verified = true`, `artifacts.backup_file = "04_SAO_LUU_AN_TOAN/<tên_file>"`.
   - Đặt `current_phase = "STAGE_01_DISCOVERY"`, `current_step = "01_APP_INTAKE"`.

### Bước 02: Reference Baseline (Đo kiểm Ứng dụng Gốc)
1. **Quy trình Runtime với Android APK (Khi có AVD / Thiết bị qua Antigravity Device Hub)**:
   - **Cài đặt & Khởi chạy**: Dùng lệnh Android CLI `android run <đường_dẫn_apk>` (tự động cài đặt APK và mở Main Activity) hoặc chạy `adb install -r <đường_dẫn_apk>` trước khi gọi REA MCP `start_adb_app` (tham số JSON bắt buộc: `serial`, `package`).
     * *Cảnh báo Known Bug (morluto/rea Issue #2225 & #6528)*: Không gọi `start_adb_app` khi APK chưa được cài lên thiết bị; kiểm tra kỹ trường output vì `am start -W` báo `Status: timeout` có thể bị đánh dấu nhầm là `observed`.
   - **Chụp ảnh màn hình Baseline**: Dùng `android screen capture -o 01_THA_APP_VAO_DAY/baseline/screen_01.png` hoặc REA MCP `capture_adb_screen` (tham số JSON bắt buộc: `serial` và `output_directory` — lưu ý dùng đúng `output_directory` dạng snake_case với đường dẫn tuyệt đối tới thư mục chưa có file trùng tên theo *morluto/rea Issue #7550 & #7437*).
   - **Trích xuất cây phân cấp UI**: Chạy `android layout --full` để lưu JSON hierarchy vào `01_THA_APP_VAO_DAY/baseline/layout_01.json`.
     * *Lưu ý giới hạn (Issue #5033)*: Với màn hình viết bằng Jetpack Compose, `uiautomator` / `android layout` chỉ trả về các node có khai báo semantics.
2. **Phân loại Baseline: Runtime vs Static Fallback (P2-13)**:
   - **Nhánh A — Runtime Baseline (`BASELINE_RUNTIME_VERIFIED`)**: Khi có AVD / thiết bị thật, chụp ảnh màn hình và trích xuất `android layout --full`. Lưu `baseline_type = "BASELINE_RUNTIME_VERIFIED"`.
   - **Nhánh B — Static Baseline (`BASELINE_STATIC_ONLY`)**: Khi không có AVD / thiết bị, đánh dấu runtime là `SKIPPED (Static Fallback)` và bóc tách tĩnh 3 lớp:
     * **Lớp 1 — Cấu trúc Package, Manifest & Classes (JADX)**: Gọi `inspect_android_package` với đường dẫn tuyệt đối của APK. *(Lưu ý: `inspect_android_package` chỉ trả về package identity, permissions, class inventory và raw `AndroidManifest.xml` text; KHÔNG trả về `res/layout/*.xml` hay `drawables`)*.
     * **Lớp 2 — Bảng chuỗi & Tài nguyên (Apktool)**: Gọi `decode_android_resources` (yêu cầu `apktool >= 2.9.2` chống CVE-2024-21633) để lấy `strings.xml` và resource tables.
     * **Lớp 3 — Danh mục File & Assets (`res/layout/*.xml`, `assets/`)**: Gọi `open_binary` + `inspect_artifact` / `extract_artifact` để lấy cây file vật lý trong gói APK.
     * *(Lưu ý quan trọng: Toàn bộ các nhận định phụ thuộc runtime lúc này phải đánh dấu là `UNKNOWN`, không dùng tài nguyên tĩnh làm baseline pixel cho Gate 05)*.
3. **Báo cáo Hoàn tất Bước 02 & Đề nghị Coordinator Mở CỔNG 01**:
   - Chạy lệnh: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.agents\scripts\gate.ps1 open 1 -Evidence 01_THA_APP_VAO_DAY/baseline/layout_01.json` (hoặc manifest tĩnh).
   - Đồng bộ bảng tiến độ trong `docs/PROGRESS.md`.

---

## 2. GIAI ĐOẠN 2: STAGE_02 · REVERSE ENGINEERING (Bước 03 & 04)

### Bước 03: REA Scan (Bóc Tách Cấu Trúc & Tài Nguyên)
1. Cập nhật `active_case.json`: `current_phase = "STAGE_02_REVERSE_ENGINEERING"`, `current_step = "03_REA_SCAN"`.
2. Định tuyến công cụ REA MCP theo loại mục tiêu:
   - **Android (`.apk`)**: Kết hợp `inspect_android_package`, `search_android_classes`, `inspect_apk_signature`, và `decode_android_resources`.
     * *Rào chắn Known Bugs trên Windows & APK lớn*:
       - Nếu gặp `provider_timeout` ở 120.000 ms trên APK multidex lớn (*Issue #3918*): Gọi `update_analysis_settings` nâng `jadx.operation_timeout_ms` lên `300000` rồi mới chạy lại.
       - Nếu gặp lỗi `Private DACL contains unexpected trustees (Win32 5)` trên Windows x64 (*Issue #5237*): Hướng dẫn đặt biến môi trường `TEMP`/`TMP` vào một thư mục riêng tư chỉ cấp quyền cho user hiện tại, đồng thời sử dụng `open_binary` + `inspect_artifact` để không làm gián đoạn phiên.
   - **Electron / JS (`.asar`, JS tree)**: `analyze_javascript_application` với `"detail": "summary"`, sau đó phân trang qua `inspect_analysis_view`.
   - **Nhị phân / File nén**: `open_binary` + `inspect_artifact` (`detail: "summary"`).
   - **Mã nguồn đầy đủ**: Dùng công cụ đọc file trực tiếp của Agent (bỏ qua REA theo chuẩn upstream).
3. **Khử trùng dữ liệu nhạy cảm**: Che mờ 100% API keys, tokens, passwords cứng thành `[REDACTED]`.
4. Lập Danh mục Màn hình (`Screen Inventory`) và Ma trận Trạng thái (`State Matrix`).

### Bước 04: REA Investigate (Điều Tra Luồng Nghiệp Vụ)
1. Cập nhật `active_case.json`: `current_step = "04_REA_INVESTIGATE"`.
2. Truy vết các hàm nghiệp vụ trọng yếu (`inspect_android_class`, `inspect_android_method`, `trace_android_references`, hoặc `inspect_android_jni_bindings` cho thư viện `.so`).
3. Phân tích luồng dữ liệu, cơ sở dữ liệu cục bộ (`SharedPreferences`, `SQLite`, `LocalStorage`) và danh sách network endpoints.
4. Xuất báo cáo hiện trạng theo `templates/01-REPORT-TEMPLATE.md` vào:
   👉 `03_KET_QUA_KIEM_TRA/bao-cao-hien-trang.md`.
5. Chuyển giao toàn bộ Evidence IDs và danh sách điểm mù cho kỹ năng **`rea-audit`** để thực hiện Bước 05.
