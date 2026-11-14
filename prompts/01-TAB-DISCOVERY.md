# PROMPT 01: KHÁM PHÁ & ĐO KIỂM ỨNG DỤNG GỐC (TAB 01 — DISCOVERY)

*Dán đoạn lệnh này vào AI Agent sau khi đã kéo thả file ứng dụng vào thư mục `01_THA_APP_VAO_DAY`.*

---

```markdown
# Tab 01 — Stage 01: Discovery (Bước 01: App Intake & Bước 02: Reference Baseline)

Read and follow `AGENTS.md`, `.agents/state/MEMORY.md`, and `docs/WORKFLOW_LIFECYCLE.md`.

## Active Skills for this Tab:
- Local Kit Skills (Bắt buộc): `rea-scan`, `reverse-engineer-anything`
- Optional Host Plugins (Nếu máy có cài đặt): `android-cli`, `android-device-hub`

## Điều kiện tiên quyết & Ranh giới an toàn (Preflights & Invariants):
1. **Kiểm tra đầu vào (Preflight Intake)**: Xác nhận có ít nhất 1 file ứng dụng hoặc thư mục mã nguồn trong `01_THA_APP_VAO_DAY/`.
2. **Bất biến tính chỉ đọc của 01_ (01_ Immutability)**: Thư mục `01_THA_APP_VAO_DAY/` là **CHỈ ĐỌC TUYỆT ĐỐI**. Tuyệt đối KHÔNG ghi đè, không sửa đổi file trong `01_`, và KHÔNG lưu ảnh chụp hay dữ liệu baseline vào `01_`.
3. **Đường dẫn Baseline thống nhất (Unified Baseline Path)**: Toàn bộ ảnh chụp màn hình, phân cấp layout, và tài nguyên baseline BẮT BUỘC lưu vào thư mục:
   👉 `03_KET_QUA_KIEM_TRA/baseline/`.

You are executing **STAGE_01 · DISCOVERY**:

### BƯỚC 01: APP INTAKE / PREFLIGHT (Tiếp nhận & Sao lưu Bất khả xâm phạm)
1. Quét thư mục `01_THA_APP_VAO_DAY/`. Xác định định dạng mục tiêu (`.apk`, `.asar`, `.zip`, thư mục mã nguồn web/native, v.v.).
2. **SAO LƯU BẤT KHẢ XÂM PHẠM**: Tự động sao chép nguyên vẹn file gốc sang `04_SAO_LUU_AN_TOAN/`, tính mã băm SHA-256 đối chiếu và đặt thuộc tính chỉ đọc. Xác nhận cơ chế hoàn tác khẩn cấp `HOAN_TAC.bat` (hoặc `hoan_tac.sh`) sẵn sàng bảo vệ an toàn dữ liệu.
3. Cập nhật `.agents/state/active_case.json`: `case_id`, `target_name`, `target_class`, `backup_verified = true`, `artifacts.backup_file`, `current_phase = "STAGE_01_DISCOVERY"`, `current_step = "01_APP_INTAKE"`.

### BƯỚC 02: REFERENCE BASELINE (Đo kiểm Ứng dụng Gốc)
1. Tạo thư mục lưu trữ baseline thống nhất nếu chưa có: `03_KET_QUA_KIEM_TRA/baseline/`.
2. **Nếu mục tiêu là Android APK (`.apk`)**:
   - Kiểm tra kết nối máy ảo AVD hoặc thiết bị thật qua Android CLI / ADB:
     * **Nếu có AVD / Thiết bị đang kết nối**:
       1. Cài đặt và khởi chạy APK bằng Android CLI `android run <đường_dẫn_apk>` (hoặc `adb install -r <đường_dẫn_apk>` trước khi gọi REA MCP `start_adb_app` với tham số `serial`, `package`).
       2. Chụp ảnh màn hình baseline lưu vào: `03_KET_QUA_KIEM_TRA/baseline/screen_01.png` qua lệnh `android screen capture -o 03_KET_QUA_KIEM_TRA/baseline/screen_01.png` hoặc REA MCP `capture_adb_screen` (tham số JSON bắt buộc: `serial`, `output_directory` trỏ về `03_KET_QUA_KIEM_TRA/baseline/` dạng tuyệt đối).
       3. Trích xuất cây phân cấp giao diện (UI Hierarchy) bằng `android layout --full` lưu vào: `03_KET_QUA_KIEM_TRA/baseline/layout_01.json`.
     * **Cơ chế Fallback Tĩnh 3 Lớp (Nếu KHÔNG có AVD / Thiết bị)**:
       1. Gọi `inspect_android_package` (JADX tĩnh) để trích xuất Manifest declarations, permissions và danh mục classes.
       2. Gọi `decode_android_resources` (Apktool >= 2.10.0, khuyến nghị 2.11.0+) để trích xuất `strings.xml` và bảng tài nguyên.
       3. Gọi `open_binary` + `inspect_artifact` / `extract_artifact` để lấy danh mục `res/layout/*.xml`, drawables và assets lưu vào `03_KET_QUA_KIEM_TRA/baseline/`.
       4. Đánh dấu trạng thái baseline là `PASS_WITH_LIMITATIONS (Static Fallback)`. Tuyệt đối không dừng hay báo lỗi crash terminal.
3. **Nếu là định dạng khác (Web, Electron ASAR, Desktop, Source Repo)**:
   - Thu thập ảnh chụp giao diện và cấu trúc baseline tương ứng vào `03_KET_QUA_KIEM_TRA/baseline/`.
4. **MỞ CỔNG 01 (`gate_01_baseline_verified`)**:
   - Trạng thái giải phóng hợp lệ của Cổng 01:
     * `PASS`: Thu thập đầy đủ Runtime Baseline trên thiết bị/AVD. Chạy:
       `powershell -NoProfile -ExecutionPolicy Bypass -File .agents/scripts/gate.ps1 open 1 -Evidence "04_SAO_LUU_AN_TOAN/<tên_file>"`
     * `PASS_WITH_LIMITATIONS`: Hoàn tất qua Static Fallback 3 lớp khi thiếu phần cứng. Chạy:
       `powershell -NoProfile -ExecutionPolicy Bypass -File .agents/scripts/gate.ps1 open 1 -Evidence "04_SAO_LUU_AN_TOAN/<tên_file>" -Mode PASS_WITH_LIMITATIONS`
     * `WAIVED`: Người dùng chủ động miễn trừ đo baseline. Chạy:
       `powershell -NoProfile -ExecutionPolicy Bypass -File .agents/scripts/gate.ps1 waive 1 -Reason "<lý_do_miễn_trừ>"`
   - Cập nhật `current_step = "02_REFERENCE_BASELINE"`.
   - Đồng bộ checklist trong `docs/PROGRESS.md`.

### BÁO CÁO CHO NGƯỜI DÙNG:
Báo cáo ngắn gọn bằng tiếng Việt đời thường:
- Loại file đã nhận & xác nhận đã sao lưu an toàn vào `04_SAO_LUU_AN_TOAN/`.
- Kết quả thu thập Baseline tại `03_KET_QUA_KIEM_TRA/baseline/` (Qua AVD/Device Hub hoặc Static Fallback 3 lớp).
- Thông báo **CỔNG 01 ĐÃ ĐƯỢC GIẢI PHÓNG HỢP LỆ** và hướng dẫn dán tiếp `prompts/02-TAB-REVERSE-ENGINEERING.md`.
```
