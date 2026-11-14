# PROMPT 01: KHÁM PHÁ & ĐO KIỂM ỨNG DỤNG GỐC (TAB 01 — DISCOVERY)

*Dán đoạn lệnh này vào AI Agent sau khi đã kéo thả file ứng dụng vào thư mục `01_THA_APP_VAO_DAY`.*

---

```markdown
# Tab 01 — Stage 01: Discovery (Bước 01: App Intake & Bước 02: Reference Baseline)

Read and follow `AGENTS.md` and `docs/WORKFLOW_LIFECYCLE.md`.

## Active Skills for this Tab:
- Local Kit Skills: `rea-scan`, `reverse-engineer-anything`
- Host Plugin Skills: `android-cli`, `android-device-hub`

You are executing **STAGE_01 · DISCOVERY**:

### BƯỚC 01: APP INTAKE / PREFLIGHT (Tiếp nhận & Kiểm tra)
1. Kiểm tra thư mục `01_THA_APP_VAO_DAY/`. Xác định file đầu vào (Android APK, Electron ASAR, ZIP, Web URL, v.v.).
2. **SAO LƯU AN TOÀN**: Tự động sao chép nguyên vẹn file gốc sang thư mục `04_SAO_LUU_AN_TOAN/` (đặt cờ Read-Only).
3. Đọc `UPSTREAMS.md` để đảm bảo REA engine đã sẵn sàng.
4. Cập nhật `active_case.json`: `target_name`, `target_type`, `current_phase = "STAGE_01_DISCOVERY"`, `current_step = "01_APP_INTAKE"`.

### BƯỚC 02: REFERENCE BASELINE (Đo kiểm Ứng dụng Gốc)
1. **Nếu mục tiêu là Android APK (`.apk`)**:
   - Kiểm tra Antigravity Device Hub và máy ảo AVD:
     * Nếu có máy ảo AVD hoặc thiết bị thật kết nối: Khởi chạy app với `start_adb_app` hoặc lệnh Android CLI.
     * Chụp ảnh màn hình giao diện baseline bằng lệnh `android screen capture -o <file_path>` hoặc `capture_adb_screen` và lưu vào `01_THA_APP_VAO_DAY/baseline/`.
     * Bóc tách phân cấp giao diện (UI Component Hierarchy) bằng lệnh `android layout` để lập danh mục màn hình gốc.
   - **Cơ chế Fallback tĩnh**: Nếu máy người dùng chưa có AVD / Device Hub / thiết bị thật kết nối, tự động chuyển sang bóc tách tài nguyên tĩnh với `inspect_android_package` (layout XML, strings.xml, icons, drawable, AndroidManifest.xml) và đánh dấu trạng thái runtime là `SKIPPED (Tĩnh)`. Tuyệt đối không dừng lại hay báo lỗi crash terminal.
2. **Nếu là các định dạng khác (Web, Electron ASAR, Desktop)**:
   - Chạy thử app trong trình duyệt hoặc runtime cục bộ, chụp ảnh baseline và ghi nhận luồng thao tác.
3. **CỔNG 01 (Quality Gate 01: `gate_01_baseline_verified`)**:
   - Khi có đủ ảnh chụp baseline HOẶC đã bóc tách tài nguyên tĩnh dự phòng:
   - Cập nhật `active_case.json`: `gates.gate_01_baseline_verified = true`, `current_step = "02_REFERENCE_BASELINE"`.
   - Cập nhật checklist trong `docs/PROGRESS.md`.

### BÁO CÁO CHO NGƯỜI DÙNG:
Báo cáo ngắn gọn bằng tiếng Việt đời thường:
- Loại file đã nhận & xác nhận đã sao lưu an toàn vào `04_SAO_LUU_AN_TOAN/`.
- Trạng thái Baseline (Chạy thử qua AVD/Device Hub với `android layout`/`android screen capture`, hoặc Bóc tách tài nguyên tĩnh dự phòng).
- Thông báo CỔNG 01 ĐÃ MỞ. Hướng dẫn người dùng mở `prompts/02-TAB-REVERSE-ENGINEERING.md` để dán tiếp.
```
