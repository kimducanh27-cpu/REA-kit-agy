# PROMPT 01: QUÉT & TIẾP NHẬN ỨNG DỤNG (TAB 01 — SCAN / DISCOVERY)

*Lưu ý: Bộ kit đã chuẩn hóa sang quy trình 6 Phase. File này tương đương với [01-TAB-DISCOVERY.md](01-TAB-DISCOVERY.md).*

---

```markdown
# Tab 01 — Phase 01: Discovery (Bước 01: App Intake & Bước 02: Reference Baseline)

Read and follow `AGENTS.md` and `docs/WORKFLOW_LIFECYCLE.md`.
Activate Skill `rea-scan` and `reverse-engineer-anything`.

You are executing **PHASE 01 · DISCOVERY**:

### BƯỚC 01: APP INTAKE / PREFLIGHT
1. Kiểm tra `01_THA_APP_VAO_DAY/`. Xác định file đầu vào.
2. Tự động sao lưu an toàn sang `04_SAO_LUU_AN_TOAN/`.
3. Cập nhật `active_case.json`: `target_name`, `target_type`, `current_phase = "PHASE_01_DISCOVERY"`.

### BƯỚC 02: REFERENCE BASELINE
1. Thử chạy app gốc, chụp màn hình và ghi nhận danh mục màn hình.
2. **Fallback**: Nếu không có runtime/máy ảo, tự động bóc tách tài nguyên tĩnh và đánh dấu `SKIPPED (Tĩnh)`.
3. Đóng CỔNG 01 (`gates.gate_01_baseline_verified = true`). Đồng bộ `docs/PROGRESS.md`.

Báo cáo kết quả bằng tiếng Việt đời thường và hướng dẫn dán tiếp `prompts/02-TAB-REVERSE-ENGINEERING.md`.
```
