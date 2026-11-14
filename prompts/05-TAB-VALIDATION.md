# PROMPT 05: NGHIỆM THU ĐỐI CHIẾU & BÀN GIAO (TAB 05 — VALIDATION & RELEASE)

*Dán đoạn lệnh này vào AI Agent sau khi hoàn thành Stage 04 (Gate 04 đã mở). Có thể dán trong cửa sổ chat mới (Fresh Context) để đảm bảo tính khách quan tối đa.*

---

```markdown
# Tab 05 — Stage 05: Validation (Bước 11: Smoke Test, Bước 12: Hard Verify & Bước 13: Release & Handoff)

Read and follow `AGENTS.md`, `REVIEW.md`, `.agents/state/MEMORY.md`, and `docs/WORKFLOW_LIFECYCLE.md`.

## Active Skills for this Tab:
- Local Kit Skills (Bắt buộc): `rea-build`
- Optional Host Plugins (Nếu máy có cài đặt): `android-cli`

## Điều kiện tiên quyết:
Đọc `.agents/state/active_case.json`. Nếu `gates.gate_04_build_qa_passed` là `false`, dừng lại và yêu cầu hoàn thành Tab 04 trước.

You are executing **STAGE_05 · VALIDATION**:

### BƯỚC 11: RUN APP / SMOKE TEST (Khởi Chạy & Kiểm Thử Nhanh)
1. Cập nhật `active_case.json`: `current_phase = "STAGE_05_VALIDATION"`, `current_step = "11_SMOKE_TEST"`.
2. **Với Route A (Web App)**: Hướng dẫn mở `05_MA_NGUON_PHAT_TRIEN/index.html` trên trình duyệt.
3. **Với Route B & C (Android Native / APK)**: Cài đặt và khởi chạy app mới trên AVD hoặc thiết bị qua lệnh Android CLI `android run` (hoặc `./gradlew installDebug` + REA MCP `start_adb_app` với tham số `serial`, `package`).

### BƯỚC 12: HARD VERIFY (Đối Chiếu 1-1 Với App Gốc)
1. Cập nhật `active_case.json`: `current_step = "12_HARD_VERIFY"`.
2. Đối chiếu trực tiếp với baseline tại `01_THA_APP_VAO_DAY/baseline/`:
   - **Với Android**: Chụp ảnh màn hình bằng `android screen capture -o <file_path>` hoặc REA MCP `capture_adb_screen` (tham số JSON bắt buộc: `serial`, `output_directory` dạng snake_case, đường dẫn tuyệt đối); trích xuất cây giao diện bằng `android layout --full` và so sánh 1-1 với baseline.
   - **Với Web App**: Đối chiếu trực quan và chức năng trên trình duyệt.
3. Xuất bảng đối chiếu 3 cột (Khớp 100% / Khác biệt có chủ đích / Nâng cấp mới) theo `templates/08-HARD-VERIFY-TEMPLATE.md` vào:
   👉 `03_KET_QUA_KIEM_TRA/BAO_CAO_NGHIEM_THU_HARD_VERIFY.md`.
4. **CỔNG 05 (`gate_05_hard_verify_passed`)**:
   - Yêu cầu người dùng xác nhận nghiệm thu.
   - **Khi đạt**: Cập nhật `active_case.json` (`gates.gate_05_hard_verify_passed = true`, `current_gate_status = "GATE_05_PASSED"`).
   - **Nếu chưa đạt (Reject Loop — Gate Invalidation Invariant)**: Lập `03_KET_QUA_KIEM_TRA/FIX_PLAN_v2.md`, tăng `revision += 1`, **bắt buộc đặt `gates.gate_04_build_qa_passed = false` và `gates.gate_05_hard_verify_passed = false`**, reset `metrics.review_convergence_rounds = 0`, và lùi `current_phase = "STAGE_04_IMPLEMENTATION"`, `current_step = "09_REA_BUILD"`.

### BƯỚC 13: RELEASE & HANDOFF (Đóng Gói & Bàn Giao Trọn Gói)
1. Cập nhật `active_case.json`: `current_step = "13_RELEASE_AND_HANDOFF"`.
2. Xuất gói bàn giao kèm Plain-Language Explainer và hướng dẫn `HOAN_TAC.bat` theo `templates/09-HANDOFF-BUNDLE-TEMPLATE.md` vào:
   👉 `05_MA_NGUON_PHAT_TRIEN/BAN_GIAO_SAN_PHAM.md`.
3. **MỞ CỔNG 06 (`gate_06_handoff_signed = true`)**:
   - Khi người dùng xác nhận ký nhận bàn giao ("You Land It, You Own It"), cập nhật `active_case.json`: `gates.gate_06_handoff_signed = true`, `current_gate_status = "GATE_06_COMPLETED"`, `next_prompt_guide = "Dán 'prompts/06-CONSOLIDATION-AND-MEMORY.md' để chạy Dreaming lưu bài học vào bộ nhớ dài hạn."`.
   - Đồng bộ toàn bộ dữ liệu vào `docs/PROGRESS.md` và `docs/HANDOFF.md`.
```
