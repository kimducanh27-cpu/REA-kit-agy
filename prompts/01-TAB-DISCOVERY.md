# PROMPT 01: KHÁM PHÁ & ĐO KIỂM ỨNG DỤNG GỐC (TAB 01 — DISCOVERY)

*Dán đoạn lệnh này vào AI Agent sau khi đã kéo thả file ứng dụng vào thư mục `01_THA_APP_VAO_DAY`.*

---

```markdown
# Tab 01 — Phase 01: Discovery (Bước 01: App Intake & Bước 02: Reference Baseline)

Read and follow `AGENTS.md` and `docs/WORKFLOW_LIFECYCLE.md`.
Activate Skill `rea-scan` and `reverse-engineer-anything`.

You are executing **PHASE 01 · DISCOVERY**:

### BƯỚC 01: APP INTAKE / PREFLIGHT (Tiếp nhận & Kiểm tra)
1. Kiểm tra thư mục `01_THA_APP_VAO_DAY/`. Xác định file đầu vào (APK, Electron ASAR, ZIP, Web URL, v.v.).
2. **SAO LƯU AN TOÀN**: Tự động sao chép nguyên vẹn file gốc sang thư mục `04_SAO_LUU_AN_TOAN/` (đặt cờ Read-Only).
3. Đọc `UPSTREAMS.md` để đảm bảo REA engine đã sẵn sàng.
4. Cập nhật `active_case.json`: `target_name`, `target_type`, `current_phase = "PHASE_01_DISCOVERY"`, `current_step = "01_APP_INTAKE"`.

### BƯỚC 02: REFERENCE BASELINE (Đo kiểm Ứng dụng Gốc)
1. Nếu môi trường hỗ trợ (có máy ảo, trình duyệt hoặc runtime):
   - Chạy thử ứng dụng gốc.
   - Chụp ảnh màn hình giao diện (Screenshots), ghi nhận danh mục màn hình (Screen Inventory) và luồng thao tác người dùng.
   - Lưu ảnh chụp/ghi chép vào `01_THA_APP_VAO_DAY/baseline/`.
2. **Cơ chế Fallback (Nếu không có máy ảo / không thể chạy runtime)**:
   - Tự động chuyển sang bóc tách tài nguyên tĩnh (hình ảnh, icon, layout file, string resources).
   - Đánh dấu trạng thái runtime là `SKIPPED (Tĩnh)`.
   - Tuyệt đối không dừng lại hay báo lỗi crash terminal.
3. **CỔNG 01 (Quality Gate 01: `gate_01_baseline_verified`)**:
   - Khi có đủ ảnh chụp baseline HOẶC đã bóc tách tài nguyên tĩnh dự phòng:
   - Cập nhật `active_case.json`: `gates.gate_01_baseline_verified = true`, `current_step = "02_REFERENCE_BASELINE"`.
   - Cập nhật checklist trong `docs/PROGRESS.md`.

### BÁO CÁO CHO NGƯỜI DÙNG:
Báo cáo ngắn gọn bằng tiếng Việt đời thường:
- Loại file đã nhận & xác nhận đã sao lưu vào `04_SAO_LUU_AN_TOAN/`.
- Trạng thái Baseline (Đã chạy thử thành công / hay Bóc tách tài nguyên tĩnh dự phòng).
- Thông báo CỔNG 01 ĐÃ MỞ. Hướng dẫn người dùng mở `prompts/02-TAB-REVERSE-ENGINEERING.md` để dán tiếp.
```
