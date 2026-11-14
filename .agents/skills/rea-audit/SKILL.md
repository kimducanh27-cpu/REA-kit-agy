---
name: rea-audit
description: Phụ trách độc quyền Bước 05 (REA Audit) và Cổng 02 (gate_02_audit_passed) trong STAGE_02 (Reverse Engineering). Kiểm toán độc lập Evidence IDs từ rea-scan, kiểm tra tính đầy đủ và cú pháp mỏ neo bằng chứng [EV: ...] trong 03_KET_QUA_KIEM_TRA/APP_FLOW_SPEC.md, quét rò rỉ secret trên 03_KET_QUA_KIEM_TRA/, tính điểm Coverage Score, thực hiện Scoped Static Audit, xuất Sổ Theo Dõi Unknowns vào 03_KET_QUA_KIEM_TRA/UNKNOWNS_AND_COVERAGE.md và từ chối mở Cổng 02 nếu thiếu APP_FLOW_SPEC.md hoặc thiếu mỏ neo.
---

# KỸ NĂNG: KIỂM TOÁN BẰNG CHỨNG & ĐỘ PHỦ ĐỘC LẬP (REA-AUDIT)

Kỹ năng chuyên trách kiểm toán độc lập cho **Bước 05 (`05_REA_AUDIT`)** thuộc **STAGE_02 · REVERSE ENGINEERING**, tiếp nhận kết quả từ `rea-scan` và quyết định mở **CỔNG 02 (`gate_02_audit_passed`)**.

---

## 1. NGUYÊN TẮC KIỂM TOÁN ĐỘC LẬP (INDEPENDENT AUDITOR ROLE)

1. **Tách bạch vai trò**:
   - Investigator (`rea-scan`) thu thập bằng chứng ở Bước 01–04.
   - Auditor (`rea-audit`) kiểm tra chéo tính xác thực, độ phủ và dẹp bỏ các suy đoán không có Evidence ID ở Bước 05.
2. **Quy chuẩn Mỏ neo Bằng chứng (Evidence Anchor Enforcement - `[EV: ...]`)**:
   - Mọi thực thể trong hồ sơ bóc tách (`Screen Inventory`, `API Sequence`, `Local Storage`, `Background & Intent Map`) bắt buộc phải gắn mỏ neo bằng chứng theo cú pháp chuẩn:
     `[EV: <class_or_file>#<method_or_line>]` (ví dụ: `[EV: MainActivity.kt#onCreate]`, `[EV: AndroidManifest.xml#L25]`).
   - Tuyệt đối không chấp nhận các ghi nhận chung chung như *"ứng dụng có màn hình login"* mà không có mỏ neo chỉ tới file/method cụ thể.
3. **Phân loại 4 tầng xác thực chứng cứ**:
   - `OBSERVED`: Đã kiểm chứng trực tiếp qua bằng chứng REA hoặc màn hình baseline.
   - `STATIC_INFERRED`: Suy luận từ mã nguồn tĩnh / layout XML (chưa chạy runtime).
   - `USER_PROVIDED`: Do người dùng cung cấp trong `02_YEU_CAU_CUA_TOI/ho-so-va-muc-tieu.md`.
   - `UNKNOWN`: Điểm mù kỹ thuật, thư viện đóng (`.so`), vùng mã rối (R8/ProGuard obfuscated) hoặc backend ẩn.
4. **Chuẩn Scoped Static Audit**:
   - Chỉ kết luận trong phạm vi các phép kiểm tra tĩnh đã thực thi (ví dụ `audit_release_exposure`, `inspect_apk_signature`, `inspect_binary_hardening`).
   - Tuyệt đối không tuyên bố "100% sạch mã độc" hay "an toàn tuyệt đối".

---

## 2. QUY TRÌNH THỰC THI 4 BƯỚC (BƯỚC 05)

### Bước 5.1: Rà soát APP_FLOW_SPEC.md, Chỉ mục Bằng chứng & Quét Rò rỉ Secret
1. Cập nhật `active_case.json`: `current_step = "05_REA_AUDIT"`.
2. **Kiểm tra bắt buộc sự tồn tại và tính hợp lệ của `APP_FLOW_SPEC.md`**:
   - Kiểm tra tệp `03_KET_QUA_KIEM_TRA/APP_FLOW_SPEC.md` có tồn tại trên đĩa.
   - Kiểm tra tệp có chứa đủ 6 phần:
     * Sơ đồ điều hướng Mermaid toàn diện (`Launch -> Auth -> Main -> Exit`).
     * Screen Inventory.
     * API & Network Sequence table.
     * Local Storage Schema.
     * Background & Intent Map.
     * 3–5 Golden Input/Output Scenarios.
   - **Xác thực cú pháp mỏ neo bằng chứng**: Kiểm tra toàn bộ tệp xem có các mỏ neo định dạng `\[EV:\s*[^\]]+\]`.
   - **Quy tắc từ chối cứng (Hard Refusal Rule)**: Nếu tệp `03_KET_QUA_KIEM_TRA/APP_FLOW_SPEC.md` không tồn tại HOẶC không chứa bất kỳ mỏ neo `[EV: ...]` nào, Auditor **BẮT BUỘC TỪ CHỐI MỞ CỔNG 02** và kích hoạt vòng lặp quay về Bước 04 (`04_REA_INVESTIGATE`).
3. Kiểm tra mọi nhận định trong `03_KET_QUA_KIEM_TRA/bao-cao-hien-trang.md` đều phải gắn kèm Evidence ID thực tế từ REA.
4. Đảm bảo 100% Secrets, API Keys, Tokens trong báo cáo tại `03_KET_QUA_KIEM_TRA/` đã được che mờ thành `[REDACTED]`.

### Bước 5.2: Đo lường Ma trận Độ phủ (Coverage Score)
- Tính tỷ lệ bao phủ bằng chứng:
  $$\text{Coverage Score} = \frac{\text{Số màn hình/module có Evidence xác minh}}{\text{Tổng số màn hình/module phát hiện}} \times 100\%$$
- Ghi nhận điểm số vào `active_case.json` (`metrics.coverage_score`).

### Bước 5.3: Lập Sổ Theo Dõi Unknowns (Residual Unknowns Ledger)
- Điền đầy đủ theo mẫu `templates/06-UNKNOWNS-AND-COVERAGE-TEMPLATE.md` và xuất ra:
  👉 `03_KET_QUA_KIEM_TRA/UNKNOWNS_AND_COVERAGE.md`.
- Mỗi mục Unknown bắt buộc có: `unknown_id` (`UNK-01`...), vị trí component, nguyên nhân chưa xác minh, mức độ rủi ro và phương án xử lý đề xuất cho buổi phỏng vấn Bước 06.
- Cập nhật tổng số Unknowns vào `active_case.json` (`metrics.unknowns_count`).

### Bước 5.4: Thẩm định & Quyết Định Mở CỔNG 02 (`gate_02_audit_passed`)
- Kiểm tra đủ 4 điều kiện cốt lõi:
  1. Đã hoàn thành `03_KET_QUA_KIEM_TRA/bao-cao-hien-trang.md` có gắn Evidence IDs.
  2. Đã hoàn thành `03_KET_QUA_KIEM_TRA/APP_FLOW_SPEC.md` với đầy đủ 6 phần cấu trúc.
  3. Tệp `03_KET_QUA_KIEM_TRA/APP_FLOW_SPEC.md` có mỏ neo bằng chứng hợp lệ theo cú pháp `[EV: <class_or_file>#<method_or_line>]` (được script `gate.ps1` kiểm tra tự động).
  4. Đã che mờ 100% secrets `[REDACTED]` và xuất `03_KET_QUA_KIEM_TRA/UNKNOWNS_AND_COVERAGE.md`.
- **Nếu đạt 100%**: Thực thi lệnh mở cổng kiểm soát:
  `powershell -NoProfile -ExecutionPolicy Bypass -File .\.agents\scripts\gate.ps1 open 2 -Evidence 03_KET_QUA_KIEM_TRA/bao-cao-hien-trang.md -ApprovedBy "rea-audit"`
  Đồng bộ bảng tiến độ trong `docs/PROGRESS.md`.
- **Nếu chưa đạt (Reject Loop)**:
  - Nếu thiếu `APP_FLOW_SPEC.md` hoặc thiếu mỏ neo `[EV: ...]`:
    `powershell -NoProfile -ExecutionPolicy Bypass -File .\.agents\scripts\gate.ps1 reject 2 -Reason "APP_FLOW_SPEC.md bị thiếu hoặc không chứa mỏ neo bằng chứng [EV: ...] hợp lệ."`
  - Lùi `current_step` về `"04_REA_INVESTIGATE"` để điều tra bổ sung, tuyệt đối không mở Cổng 02.
