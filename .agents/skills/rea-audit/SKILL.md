---
name: rea-audit
description: Phụ trách độc quyền Bước 05 (REA Audit) và Cổng 02 (gate_02_audit_passed) trong STAGE_02 (Reverse Engineering). Kiểm toán độc lập Evidence IDs từ rea-scan, chạy quét rò rỉ secret trên 03_KET_QUA_KIEM_TRA/, tính điểm Coverage Score, thực hiện Scoped Static Audit và xuất Sổ Theo Dõi Unknowns vào 03_KET_QUA_KIEM_TRA/UNKNOWNS_AND_COVERAGE.md.
---

# KỸ NĂNG: KIỂM TOÁN BẰNG CHỨNG & ĐỘ PHỦ ĐỘC LẬP (REA-AUDIT)

Kỹ năng chuyên trách kiểm toán độc lập cho **Bước 05 (`05_REA_AUDIT`)** thuộc **STAGE_02 · REVERSE ENGINEERING**, tiếp nhận kết quả từ `rea-scan` và quyết định mở **CỔNG 02 (`gate_02_audit_passed`)**.

---

## 1. NGUYÊN TẮC KIỂM TOÁN ĐỘC LẬP (INDEPENDENT AUDITOR ROLE)

1. **Tách bạch vai trò**:
   - Investigator (`rea-scan`) thu thập bằng chứng ở Bước 01–04.
   - Auditor (`rea-audit`) kiểm tra chéo tính xác thực, độ phủ và dẹp bỏ các suy đoán không có Evidence ID ở Bước 05.
2. **Phân loại 4 tầng xác thực chứng cứ**:
   - `OBSERVED`: Đã kiểm chứng trực tiếp qua bằng chứng REA hoặc màn hình baseline.
   - `STATIC_INFERRED`: Suy luận từ mã nguồn tĩnh / layout XML (chưa chạy runtime).
   - `USER_PROVIDED`: Do người dùng cung cấp trong `02_YEU_CAU_CUA_TOI/ho-so-va-muc-tieu.md`.
   - `UNKNOWN`: Điểm mù kỹ thuật, thư viện đóng (`.so`), vùng mã rối (R8/ProGuard obfuscated) hoặc backend ẩn.
3. **Chuẩn Scoped Static Audit**:
   - Chỉ kết luận trong phạm vi các phép kiểm tra tĩnh đã thực thi (ví dụ `audit_release_exposure`, `inspect_apk_signature`, `inspect_binary_hardening`).
   - Tuyệt đối không tuyên bố "100% sạch mã độc" hay "an toàn tuyệt đối".

---

## 2. QUY TRÌNH THỰC THI 4 BƯỚC (BƯỚC 05)

### Bước 5.1: Rà soát Chỉ mục Bằng chứng & Quét Rò rỉ Secret
1. Cập nhật `active_case.json`: `current_step = "05_REA_AUDIT"`.
2. Kiểm tra mọi nhận định trong `03_KET_QUA_KIEM_TRA/bao-cao-hien-trang.md` đều phải gắn kèm Evidence ID thực tế từ REA.
3. Đảm bảo 100% Secrets, API Keys, Tokens trong báo cáo tại `03_KET_QUA_KIEM_TRA/` đã được che mờ thành `[REDACTED]`.

### Bước 5.2: Đo lường Ma trận Độ phủ (Coverage Score)
- Tính tỷ lệ bao phủ bằng chứng:
  $$\text{Coverage Score} = \frac{\text{Số màn hình/module có Evidence xác minh}}{\text{Tổng số màn hình/module phát hiện}} \times 100\%$$
- Ghi nhận điểm số vào `active_case.json` (`metrics.coverage_score`).

### Bước 5.3: Lập Sổ Theo Dõi Unknowns (Residual Unknowns Ledger)
- Điền đầy đủ theo mẫu `templates/06-UNKNOWNS-AND-COVERAGE-TEMPLATE.md` và xuất ra:
  👉 `03_KET_QUA_KIEM_TRA/UNKNOWNS_AND_COVERAGE.md`.
- Mỗi mục Unknown bắt buộc có: `unknown_id` (`UNK-01`...), vị trí component, nguyên nhân chưa xác minh, mức độ rủi ro và phương án xử lý đề xuất cho buổi phỏng vấn Bước 06.
- Cập nhật tổng số Unknowns vào `active_case.json` (`metrics.unknowns_count`).

### Bước 5.4: Thẩm định & Mở CỔNG 02 (`gate_02_audit_passed`)
- Kiểm tra đủ 3 điều kiện:
  1. Đã hoàn thành `03_KET_QUA_KIEM_TRA/bao-cao-hien-trang.md` có gắn Evidence IDs.
  2. Đã che mờ 100% secrets `[REDACTED]` trong báo cáo.
  3. Đã xuất `03_KET_QUA_KIEM_TRA/UNKNOWNS_AND_COVERAGE.md` đầy đủ.
- **Nếu đạt**: Cập nhật `active_case.json` (`gates.gate_02_audit_passed = true`, `current_gate_status = "GATE_02_PASSED"`, `next_prompt_guide = "Dán 'prompts/03-TAB-PRODUCT-DEFINITION.md' để phỏng vấn chốt yêu cầu và lập kế hoạch."`) và đồng bộ `docs/PROGRESS.md`.
- **Nếu chưa đạt (Reject Loop)**: Lùi `current_step` về `"04_REA_INVESTIGATE"` để điều tra bổ sung.
