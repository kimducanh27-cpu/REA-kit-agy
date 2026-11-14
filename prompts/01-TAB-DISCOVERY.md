# PROMPT 01: KHÁM PHÁ & ĐO KIỂM ỨNG DỤNG GỐC (TAB 01 — DISCOVERY)

*Dán đoạn lệnh này vào AI Agent sau khi đã kéo thả file ứng dụng vào thư mục `01_THA_APP_VAO_DAY`.*

---

```markdown
# Tab 01 — Stage 01: Discovery (Bước 01: App Intake & Bước 02: Reference Baseline)

Read and follow `AGENTS.md`, `.agents/state/MEMORY.md`, and `docs/WORKFLOW_LIFECYCLE.md`.

## Active Skills for this Tab:
- Local Kit Skills (Bắt buộc): `rea-scan`, `reverse-engineer-anything`
- Optional Host Plugins (Nếu máy có cài đặt): `android-cli`

You are executing **STAGE_01 · DISCOVERY**:

### BƯỚC 01: APP INTAKE / PREFLIGHT (Tiếp nhận & Sao lưu Bất khả xâm phạm)
1. Kiểm tra thư mục `01_THA_APP_VAO_DAY/`. Xác định file đầu vào (`.apk`, `.asar`, `.zip`, thư mục mã nguồn, v.v.).
2. **SAO LƯU AN TOÀN**: Sao chép nguyên vẹn file gốc sang `04_SAO_LUU_AN_TOAN/` và đối chiếu SHA-256.
3. Cập nhật `.agents/state/active_case.json`: `case_id`, `target_name`, `target_class`, `backup_verified = true`, `artifacts.backup_file`, `current_phase = "STAGE_01_DISCOVERY"`, `current_step = "01_APP_INTAKE"`.

### BƯỚC 02: REFERENCE BASELINE (Đo kiểm Ứng dụng Gốc)
1. **Nếu mục tiêu là Android APK (`.apk`)**:
   - Kiểm tra xem máy có kết nối AVD hoặc thiết bị qua Android CLI / ADB không:
     * **Nếu có AVD / Thiết bị**:
       1. Cài đặt và khởi chạy APK bằng lệnh Android CLI `android run <đường_dẫn_apk>` (hoặc chạy `adb install -r <đường_dẫn_apk>` trước khi gọi REA MCP `start_adb_app` với tham số `serial`, `package`).
       2. Chụp ảnh màn hình baseline bằng `android screen capture -o 01_THA_APP_VAO_DAY/baseline/screen_01.png` hoặc REA MCP `capture_adb_screen` (tham số JSON bắt buộc: `serial` và `output_directory` — dùng đúng tên trường snake_case `output_directory` với đường dẫn tuyệt đối).
       3. Trích xuất phân cấp giao diện bằng `android layout --full` lưu vào `01_THA_APP_VAO_DAY/baseline/layout_01.json`.
     * **Cơ chế Fallback Tĩnh 3 Lớp (Nếu không có AVD / Thiết bị)**:
       1. Gọi `inspect_android_package` (JADX tĩnh) để trích xuất Manifest declarations, permissions và danh mục classes.
       2. Gọi `decode_android_resources` (nếu có Apktool >= 2.9.2) để trích xuất `strings.xml` và resource tables.
       3. Gọi `open_binary` + `inspect_artifact` / `extract_artifact` để lấy danh mục `res/layout/*.xml`, drawables và assets.
       4. Đánh dấu trạng thái baseline là `PASS_WITH_LIMITATIONS (Static Fallback)`. Tuyệt đối không dừng hay báo lỗi crash.
2. **Nếu là định dạng khác (Web, Electron ASAR, Desktop, Source Repo)**:
   - Thu thập baseline hoặc kiểm kê cấu trúc tương ứng.
3. **MỞ CỔNG 01 (`gate_01_baseline_verified`)**:
   - Chạy lệnh: `powershell -File .agents/scripts/gate.ps1 open 1 -Evidence "04_SAO_LUU_AN_TOAN/<tên_file>"` (hoặc `-Mode PASS_WITH_LIMITATIONS` nếu dùng Static Fallback, hoặc `gate.ps1 waive 1 -Reason "Không có AVD"` nếu người dùng miễn trừ).
   - Cập nhật `current_step = "02_REFERENCE_BASELINE"`.
   - Đồng bộ checklist trong `docs/PROGRESS.md`.

### BÁO CÁO CHO NGƯỜI DÙNG:
Báo cáo ngắn gọn bằng tiếng Việt đời thường:
- Loại file đã nhận & xác nhận đã sao lưu an toàn vào `04_SAO_LUU_AN_TOAN/`.
- Kết quả thu thập Baseline (Qua AVD/Device Hub hoặc Static Fallback 3 lớp).
- Thông báo **CỔNG 01 ĐÃ MỞ** và hướng dẫn dán tiếp `prompts/02-TAB-REVERSE-ENGINEERING.md`.
```
