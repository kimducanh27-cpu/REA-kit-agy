---
name: rea-audit
description: Kỹ năng kiểm toán bằng chứng độc lập (Independent Evidence Audit), đo lường Ma trận Độ phủ (Coverage Matrix), kiểm toán tĩnh có giới hạn phạm vi (Scoped Static Audit) và quản lý Sổ Theo Dõi Unknowns theo chuẩn Cổng 02 (gate_02_audit_passed) trong STAGE_02 (Reverse Engineering). Đảm bảo phân biệt rạch ròi giữa chứng cứ quan sát thực tế và suy luận.
---

# KỸ NĂNG: KIỂM TOÁN BẰNG CHỨNG & ĐỘ PHỦ ĐỘC LẬP (REA-AUDIT)

Kỹ năng chuyên trách kiểm toán độc lập cho **Bước 05 (REA Audit)** thuộc **STAGE_02 · REVERSE ENGINEERING**, phối hợp cùng `rea-scan` và `reverse-engineer-anything` theo đặc tả `docs/WORKFLOW_LIFECYCLE.md`.

---

## 1. NGUYÊN TẮC KIỂM TOÁN ĐỘC LẬP (INDEPENDENT AUDITOR ROLE)

1. **Tách bạch vai trò**:
   - Investigator (`rea-scan`) thu thập và bóc tách dữ liệu từ APK/ASAR/Binary.
   - Auditor (`rea-audit`) kiểm tra tính xác thực, độ đầy đủ và dẹp bỏ các nhận định chủ quan.
2. **Quy tắc 4 tầng xác thực chứng cứ**:
   - `OBSERVED`: Đã kiểm chứng trực tiếp qua bằng chứng REA hoặc màn hình baseline.
   - `STATIC_INFERRED`: Suy luận logic từ mã nguồn tĩnh / layout XML (chưa chạy runtime).
   - `USER_PROVIDED`: Do người dùng mô tả trong `02_YEU_CAU_CUA_TOI/ho-so-va-muc-tieu.md`.
   - `UNKNOWN`: Điểm mù kỹ thuật, thư viện đóng, hoặc vùng mã bị làm rối (obfuscated).
3. **Tuyệt đối không kết luận tuyệt đối**:
   - Chỉ kết luận trong phạm vi quét tĩnh (Scoped Static Audit).
   - Không tuyên bố "100% sạch mã độc" hay "an toàn tuyệt đối".

---

## 2. QUY TRÌNH THỰC THI 4 BƯỚC

### Bước 1: Rà soát Chỉ mục Bằng chứng (Evidence Index Audit)
- Kiểm tra toàn bộ Evidence IDs được sinh ra từ các công cụ REA (`inspect_android_package`, `inspect_adb_device`, JADX decompiler).
- Đảm bảo 100% Secrets, API Keys, Tokens cứng đều đã được che mờ thành `[REDACTED]`.

### Bước 2: Đo lường Ma trận Độ phủ (Coverage Score)
- Lập bảng danh mục các module/màn hình được khảo sát:
  $$\text{Coverage Score} = \frac{\text{Số màn hình/module có Evidence xác minh}}{\text{Tổng số màn hình/module phát hiện}} \times 100\%$$
- Ghi nhận rõ các module chưa thể khảo sát do hạn chế môi trường hoặc thiếu máy ảo.

### Bước 3: Lập Sổ Theo Dõi Unknowns (Residual Unknowns Ledger)
- Điền đầy đủ vào mẫu `templates/06-UNKNOWNS-AND-COVERAGE-TEMPLATE.md`.
- Xuất file chính thức:
  👉 `03_KET_QUA_KIEM_TRA/UNKNOWNS_AND_COVERAGE.md`.
- Mỗi Unknown bắt buộc có:
  * `unknown_id` (ví dụ: `UNK-001`)
  * `vị trí / component`
  * `lý do chưa xác minh` (mã rối, native `.so`, thiếu backend)
  * `phương án đề xuất xử lý` (hỏi người dùng ở Stage 03, thay thế bằng mock, hoặc viết lại mới).

### Bước 4: Thẩm định CỔNG 02 (`gate_02_audit_passed`)
- Kiểm tra 3 điều kiện tiên quyết:
  1. Đã hoàn thành Scoped Static Audit không phát hiện lỗi bảo mật nghiêm trọng trong phạm vi quét.
  2. Toàn bộ API keys/secrets đã được che mờ `[REDACTED]`.
  3. Mọi điểm chưa rõ ràng đã được đưa vào Sổ Unknowns.
- Nếu đạt: Cập nhật `.agents/state/active_case.json`: `gates.gate_02_audit_passed = true`, đồng bộ `docs/PROGRESS.md`.
- Nếu không đạt (Reject Loop): Yêu cầu Investigator (`rea-scan`) đào sâu thêm các module còn thiếu trước khi chuyển sang phỏng vấn.
