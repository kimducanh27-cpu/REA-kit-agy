# PROMPT 05: NGHIỆM THU ĐỐI CHIẾU & BÀN GIAO (TAB 05 — VALIDATION & RELEASE)

*Dán đoạn lệnh này vào AI Agent sau khi hoàn thành Stage 04 (Gate 04 đã được giải phóng hợp lệ). Có thể dán trong cửa sổ chat mới (Fresh Context) để đảm bảo tính khách quan tối đa.*

---

```markdown
# Tab 05 — Stage 05: Validation (Bước 11: Smoke Test, Bước 12: Hard Verify & Bước 13: Release & Handoff)

Read and follow `AGENTS.md`, `REVIEW.md`, `.agents/state/MEMORY.md`, and `docs/WORKFLOW_LIFECYCLE.md`.

## Active Skills for this Tab:
- Local Kit Skills (Bắt buộc): `rea-build`
- Optional Host Plugins (Nếu máy có cài đặt): `android-cli`, `android-device-hub`, `code-review`

## Điều kiện tiên quyết (Preflight Gate Check):
Đọc `.agents/state/active_case.json` hoặc chạy `powershell -NoProfile -ExecutionPolicy Bypass -File .agents/scripts/gate.ps1 status`.
Bắt buộc Cổng 04 (`gate_04_build_qa_passed`) đã đạt trạng thái hợp lệ đã thông qua:
- `PASS` (Build QA và verify_code.ps1 đạt chuẩn).
- `PASS_WITH_LIMITATIONS` (Vượt qua với cảnh báo đã được chấp thuận).
- `REUSED_VALIDATED` (Tái sử dụng kết quả kiểm thử từ ca trước).
- `WAIVED` / `SKIPPED` / `NOT_APPLICABLE` (Được miễn trừ hoặc không áp dụng, ví dụ: chế độ `ANALYSIS_ONLY` hoặc `PLAN_ONLY`).
Nếu Cổng 04 ở trạng thái `FAILED`, `BLOCKED`, `NOT_STARTED` hoặc `INVALIDATED`, dừng lại và xử lý Stage 04 trước.

You are executing **STAGE_05 · VALIDATION**:

### BƯỚC 11: RUN APP / SMOKE TEST (Khởi Chạy & Kiểm Thử Nhanh)
1. Cập nhật `active_case.json`: `current_phase = "STAGE_05_VALIDATION"`, `current_step = "11_SMOKE_TEST"`.
2. **Với Route A (Web App)**: Hướng dẫn người dùng mở chạy thử file `05_MA_NGUON_PHAT_TRIEN/index.html` trực tiếp trên trình duyệt.
3. **Với Route B & C (Android Native / APK)**: Cài đặt và khởi chạy app mới trên AVD hoặc thiết bị thật qua Android CLI `android run` (hoặc `./gradlew installDebug` kết hợp REA MCP `start_adb_app` với tham số `serial`, `package`).
4. Kiểm tra các luồng thao tác chính để đảm bảo không crash, không vỡ layout, hiển thị đầy đủ 4 trạng thái UI.

### BƯỚC 12: HARD VERIFY (Đối Chiếu 1-1 Với App Gốc)
1. Cập nhật `active_case.json`: `current_step = "12_HARD_VERIFY"`.
2. **Đối chiếu trực tiếp với baseline tại `03_KET_QUA_KIEM_TRA/baseline/`**:
   - **Với Android Native / APK**: Chụp ảnh màn hình bằng `android screen capture -o <file_path>` hoặc REA MCP `capture_adb_screen` (tham số JSON: `serial`, `output_directory` tuyệt đối trỏ về `03_KET_QUA_KIEM_TRA/baseline/`); trích xuất cây giao diện bằng `android layout --full` và so sánh 1-1 với cây layout baseline gốc từ Bước 02.
   - **Với Web App**: Đối chiếu trực quan và chức năng cạnh nhau trên trình duyệt.
3. Xuất bảng đối chiếu 3 cột:
   - Cột 1: **Khớp 100% (Match)**: Y hệt bản gốc.
   - Cột 2: **Khác biệt có chủ đích (Intended Diff)**: Đã thống nhất tại Bước 06 qua `dac-ta-yeu-cau-da-chot.md`.
   - Cột 3: **Cần sửa (Needs Fix)**: Lỗi sai lệch phát sinh cần khắc phục.
4. Điền đầy đủ vào `templates/08-HARD-VERIFY-TEMPLATE.md` và lưu vào:
   👉 `03_KET_QUA_KIEM_TRA/BAO_CAO_NGHIEM_THU_HARD_VERIFY.md`.
5. **CỔNG 05 (`gate_05_hard_verify_passed`)**:
   - Yêu cầu người dùng xác nhận đạt yêu cầu nghiệm thu.
   - **Khi đạt**: Chạy lệnh mở cổng:
     `powershell -NoProfile -ExecutionPolicy Bypass -File .agents/scripts/gate.ps1 open 5 -Evidence "03_KET_QUA_KIEM_TRA/BAO_CAO_NGHIEM_THU_HARD_VERIFY.md"`
     *(Nếu không có runtime baseline, dùng `-Mode PASS_WITH_LIMITATIONS` cho kiểm chứng đặc tả SPEC_ACCEPTANCE; hoặc `gate.ps1 skip 5 -Reason "Analysis-only"` nếu ca làm việc không viết mã).*
   - **Nếu chưa đạt (Reject Loop — Cascade Invalidation)**:
     Lập `03_KET_QUA_KIEM_TRA/FIX_PLAN_v2.md`, chạy lệnh:
     `powershell -NoProfile -ExecutionPolicy Bypass -File .agents/scripts/gate.ps1 reject 5 -Reason "Phát hiện lỗi sai lệch khi kiểm thử độc lập"`
     *(Hệ thống sẽ tự động vô hiệu hóa Gate 04, 05, 06 và đưa về Stage 04 Step 09 một cách an toàn).*

### BƯỚC 13: RELEASE & HANDOFF (Đóng Gói & Bàn Giao Trọn Gói)
1. Cập nhật `active_case.json`: `current_step = "13_RELEASE_AND_HANDOFF"`.
2. **Xác thực cơ chế hoàn tác khẩn cấp**:
   - Hướng dẫn rõ ràng cách sử dụng **`HOAN_TAC.bat`** (trên Windows) hoặc **`./hoan_tac.sh`** (trên Linux/macOS) để người dùng có thể lùi về bản snapshot trước bất kỳ lúc nào chỉ bằng 1 cú nhấp chuột.
3. Xuất gói bàn giao kèm Plain-Language Explainer (3 câu hỏi: Vừa làm gì, Tại sao, Cách mở dùng) theo `templates/09-HANDOFF-BUNDLE-TEMPLATE.md` vào:
   👉 `05_MA_NGUON_PHAT_TRIEN/BAN_GIAO_SAN_PHAM.md`.
4. **MỞ CỔNG 06 (`gate_06_handoff_signed`)**:
   - Khi người dùng xác nhận ký nhận bàn giao ("You Land It, You Own It"), chạy lệnh:
     `powershell -NoProfile -ExecutionPolicy Bypass -File .agents/scripts/gate.ps1 open 6 -Evidence "05_MA_NGUON_PHAT_TRIEN/BAN_GIAO_SAN_PHAM.md"`
     *(Hoặc `gate.ps1 skip 6 -Reason "Analysis-only mode" -Mode NOT_APPLICABLE` nếu ca làm việc là ANALYSIS_ONLY).*
   - Cập nhật `next_prompt_guide = "Dán 'prompts/06-CONSOLIDATION-AND-MEMORY.md' để chạy Dreaming lưu bài học vào bộ nhớ dài hạn."`.
   - Đồng bộ toàn bộ dữ liệu vào `docs/PROGRESS.md` và `docs/HANDOFF.md`.

### BÁO CÁO CHO NGƯỜI DÙNG:
- Tóm tắt kết quả nghiệm thu Hard Verify và bàn giao sản phẩm.
- Xác nhận trạng thái Cổng 05 và Cổng 06 ĐÃ ĐƯỢC GIẢI PHÓNG HỢP LỆ.
- Hướng dẫn chạy app và hướng dẫn sử dụng `HOAN_TAC.bat` (hoặc `hoan_tac.sh`) khi cần hoàn tác.
- Hướng dẫn dán `prompts/06-CONSOLIDATION-AND-MEMORY.md` để kết thúc ca làm việc.
```
