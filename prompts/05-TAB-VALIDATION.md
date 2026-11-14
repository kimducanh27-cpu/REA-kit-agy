# PROMPT 05: NGHIỆM THU ĐỐI CHIẾU & BÀN GIAO (TAB 05 — VALIDATION & RELEASE)

*Dán đoạn lệnh này vào AI Agent sau khi hoàn thành Stage 04 (Gate 04 đã mở). Có thể dán trong một cửa sổ chat sạch mới (Fresh Context) để đảm bảo tính khách quan tối đa.*

---

```markdown
# Tab 05 — Stage 05: Validation (Bước 11: Smoke Test, Bước 12: Hard Verify & Bước 13: Release & Handoff)

Read and follow `AGENTS.md`, `REVIEW.md`, and `docs/WORKFLOW_LIFECYCLE.md`.

## Active Skills for this Tab:
- Local Kit Skills: `rea-build`
- Host Plugin Skills: `verify-and-stop`, `code-review`, `android-cli`, `android-device-hub`, `compose-preview`, `a11y-debugging`

## Điều kiện tiên quyết:
Kiểm tra `.agents/state/active_case.json`. Nếu `gates.gate_04_build_qa_passed` chưa đạt (`false`), dừng lại và yêu cầu hoàn thành Stage 04 trước.

You are executing **STAGE_05 · VALIDATION**:

### BƯỚC 11: RUN APP / SMOKE TEST (Khởi Chạy & Kiểm Thử Nhanh)
1. **Với Web App (Route A)**: Hướng dẫn người dùng mở chạy thử ứng dụng tại `05_MA_NGUON_PHAT_TRIEN/index.html` trên trình duyệt.
2. **Với Android Native / APK (Route B & C)**:
   - Cài đặt và khởi chạy app mới trên máy ảo AVD hoặc thiết bị thật kết nối qua Antigravity Device Hub bằng lệnh `start_adb_app` hoặc lệnh Android CLI.
3. Kiểm tra nhanh các luồng thao tác chính (Happy Path) để đảm bảo không bị crash hoặc vỡ giao diện.

### BƯỚC 12: HARD VERIFY (Đối Chiếu 1-1 Với App Gốc)
1. Đặt app mới cạnh app gốc (hoặc đối chiếu với ảnh chụp/tài nguyên tại `01_THA_APP_VAO_DAY/baseline/`):
   - **Với Android Native / APK**:
     * Chụp ảnh màn hình app mới bằng lệnh `android screen capture -o <file_path>` hoặc `capture_adb_screen`.
     * Trích xuất cây phân cấp giao diện bằng lệnh `android layout` và đối chiếu 1-1 với cây layout baseline của app gốc ghi nhận từ Bước 02.
   - **Với Web App**: So sánh trực tiếp trên trình duyệt hoặc đối chiếu visual với baseline.
2. Lập bảng đối chiếu trực quan 3 cột:
   - Cột 1: Khớp 100% (Y hệt bản gốc).
   - Cột 2: Khác biệt có chủ đích (Đã thống nhất tại Bước 06).
   - Cột 3: Nâng cấp mới (Cải tiến UX/Bảo mật).
3. Điền đầy đủ vào `templates/08-HARD-VERIFY-TEMPLATE.md`.
4. Xuất file nghiệm thu vào:
   👉 `03_KET_QUA_KIEM_TRA/BAO_CAO_NGHIEM_THU_HARD_VERIFY.md`.
5. **CỔNG 05 (Quality Gate 05: `gate_05_hard_verify_passed`)**:
   - Yêu cầu người dùng xác nhận đạt yêu cầu đối chiếu.
   - Khi người dùng xác nhận: Cập nhật `active_case.json`: `gates.gate_05_hard_verify_passed = true`, `current_step = "12_HARD_VERIFY"`.
   - **Vòng lặp sửa sai (Reject Loop)**: Nếu chưa đạt, lập `FIX_PLAN_v2.md` và lùi về Bước 09 (Stage 04) để sửa chữa cục bộ.

### BƯỚC 13: RELEASE & HANDOFF (Đóng Gói & Bàn Giao Trọn Gói)
1. Đóng gói mã nguồn hoàn chỉnh tại `05_MA_NGUON_PHAT_TRIEN/`.
2. Viết bản giải thích đời thường (Plain-Language Explainer) trả lời 3 câu hỏi (Làm gì, Tại sao, Cách dùng).
3. Hướng dẫn sử dụng nút hoàn tác khẩn cấp `HOAN_TAC.bat`.
4. Điền đầy đủ vào `templates/09-HANDOFF-BUNDLE-TEMPLATE.md`.
5. Xuất gói bàn giao chính thức vào:
   👉 `05_MA_NGUON_PHAT_TRIEN/BAN_GIAO_SAN_PHAM.md`.
6. **CỔNG 06 (Quality Gate 06: `gate_06_handoff_signed`)**:
   - Người dùng xác nhận ký nhận bàn giao ("You Land It, You Own It").
   - Cập nhật `active_case.json`: `gates.gate_06_handoff_signed = true`, `current_phase = "STAGE_05_VALIDATION"`, `current_step = "13_RELEASE_AND_HANDOFF"`, `current_gate_status = "GATE_06_COMPLETED"`.
   - Đồng bộ toàn bộ dữ liệu vào `docs/PROGRESS.md` và `docs/HANDOFF.md`.

### BÁO CÁO CHO NGƯỜI DÙNG:
Báo cáo hoàn tất dự án, chúc mừng người dùng và hướng dẫn cách mở ứng dụng hoàn thiện tại `05_MA_NGUON_PHAT_TRIEN/`.
```
