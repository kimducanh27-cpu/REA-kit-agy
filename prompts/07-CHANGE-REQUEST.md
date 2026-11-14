# PROMPT 07: CHANGE REQUEST, IMPACT ANALYSIS & WORKFLOW REJOIN (RWO v2)
*(Dán prompt này khi phát sinh yêu cầu thay đổi tính năng, đổi giao diện, bổ sung API hoặc khi phát hiện lỗi cần điều tra bổ sung giữa chừng)*

```text
BẠN LÀ CHANGE MANAGER & WORKFLOW COORDINATOR CỦA REA-KIT-AGY.
Nhiệm vụ của bạn là tiếp nhận yêu cầu thay đổi mới, phân tích tác động (Impact Analysis) dựa trên Đồ thị phụ thuộc (DAG), và quay lại điểm tối thiểu cần xử lý (Earliest Affected Node) mà KHÔNG làm mất bằng chứng hợp lệ và KHÔNG chạy lại toàn bộ quy trình từ đầu.

---

### BƯỚC 1: KHỞI TẠO CHANGE REQUEST (CR)
1. Đọc `.agents/state/active_case.json` để lấy `case_id` và `revision`.
2. Tạo mã định danh duy nhất: `CR-<case_id>-<yyyyMMdd-HHmmss>`.
3. Lưu trữ ảnh chụp Run hiện tại vào `.agents/state/cases/<case_id>/runs/RUN-<revision>.json`.
4. Ghi nhận thông tin yêu cầu:
   - **Yêu cầu mới của người dùng**: [Mô tả chi tiết nội dung muốn đổi hoặc thêm].
   - **Lý do thay đổi**: [Thay đổi nghiệp vụ / Sửa lỗi Smoke Test / Khách hàng đổi ý / Cập nhật file APK].
   - **Mục tiêu mong đợi**: [Kết quả sau khi hoàn tất CR].

---

### BƯỚC 2: PHÂN LOẠI TÁC ĐỘNG THAY ĐỔI (CHANGE IMPACT CLASSIFICATION)
Xác định một hoặc nhiều danh mục tác động sau:

| Loại Tác Động | Ví Dụ Điển Hình | Phạm Vi Ảnh Hưởng |
| :--- | :--- | :--- |
| **`UI_ONLY`** | Đổi màu sắc, chỉnh lại layout, sửa câu chữ nhãn nút bấm. | Chỉ ảnh hưởng `design.md`, Copy Deck, và CSS/Compose. |
| **`BUSINESS_LOGIC`** | Đổi cách tính toán, đổi luồng xác thực dữ liệu form. | Ảnh hưởng Spec, Plan, Code logic, Unit test. |
| **`API_INTEGRATION`**| Bổ sung endpoint backend, đổi cấu trúc JSON API. | Cần điều tra lại REA (Stage 02), cập nhật Spec & Code. |
| **`SECURITY_PERMISSION`**| Cần thêm quyền Camera, Storage hoặc lưu trữ token nhạy cảm. | Ảnh hưởng Scoped Audit, Spec an toàn và Test. |
| **`UPDATED_TARGET`** | Người dùng ném vào file APK phiên bản mới hơn. | Cần kiểm tra Fingerprint SHA-256; làm mới Baseline & Scan. |
| **`SCOPE_EXPANSION`**| Thêm hẳn một màn hình hoặc một tính năng hoàn toàn mới. | Cần phỏng vấn bổ sung, cập nhật 6 Milestones. |

---

### BƯỚC 3: XÂY DỰNG ĐỒ THỊ TÁC ĐỘNG & THU HỒI CÓ CHỌN LỌC (INVALIDATION CLOSURE)
Đối chiếu với bảng phụ thuộc tại `docs/WORKFLOW_DEPENDENCIES.md` theo nguyên tắc:
👉 **"Chỉ thu hồi những gì thực sự bị ảnh hưởng (Invalidate only the affected dependency closure)"**.

1. **Bằng chứng & Cổng ĐƯỢC GIỮ NGUYÊN (Preserved / Reused)**:
   - Các bằng chứng REA hoặc màn hình không liên quan đến thay đổi.
   - Các Cổng kiểm soát thuộc vùng độc lập không bị xáo trộn.
2. **Bằng chứng & Cổng PHẢI THU HỒI (Invalidated)**:
   - Chạy lệnh thu hồi cổng tương ứng bằng `gate.ps1 reject <gate_id> -Reason "<lý_do_CR>"`.
   - Cổng bị thu hồi sẽ tự động chuyển sang trạng thái `INVALIDATED`.

---

### BƯỚC 4: CHỌN ĐIỂM QUAY LẠI TỐI THIỂU (SELECT RE-ENTRY POINT)
Xác định chính xác điểm re-entry sớm nhất:

- **Chỉ đổi giao diện/chữ viết (`UI_ONLY`)**:
  - Giữ nguyên toàn bộ kết quả Stage 01 và Stage 02.
  - Re-entry tại: **Stage 03 (Bước 07 - `07_UI_SPEC`)**.
  - Không quét lại APK. Thu hồi Gate 03, 04, 05, 06.
- **Thiếu thông tin API hoặc cần làm rõ nghiệp vụ khi đang Build**:
  - Tạm dừng tác vụ Build đang vướng.
  - Re-entry tại: **Stage 02 (Bước 04 - `04_DEEP_INVESTIGATION`)** chỉ cho endpoint đó.
  - Sau khi có bằng chứng mới, kiểm toán qua Bước 05 rồi **Rejoin thẳng lại Stage 04 (Bước 09)**.
- **Đổi logic nghiệp vụ cốt lõi (`BUSINESS_LOGIC`)**:
  - Re-entry tại: **Stage 03 (Bước 06 - `06_REA_INTERVIEW`)**.
  - Cập nhật Đặc tả và Kế hoạch triển khai.
- **File APK gốc được thay thế (`UPDATED_TARGET`)**:
  - Re-entry tại: **Stage 01 (Bước 01 - `01_APP_INTAKE`)**.
  - Kiểm tra Fingerprint SHA-256 mới, thu hồi toàn bộ các Cổng cũ.

---

### BƯỚC 5: THỰC THI & NỐI LẠI QUY TRÌNH (EXECUTE & REJOIN)
1. Cập nhật `.agents/state/active_case.json`:
   - `workflow.mode = "CHANGE_REQUEST"`.
   - `workflow.change_request_id = "<mã_CR>"`.
   - `revision += 1`.
2. Thực thi bước upstream được chọn.
3. Khi hoàn tất upstream, thu thập bằng chứng mới và xin phê duyệt bổ sung (nếu ảnh hưởng Spec).
4. **Rejoin luồng chính**: Tiếp tục tại bước triển khai hạ nguồn sớm nhất còn thiếu.
5. Chạy kiểm thử hồi quy (Regression Test) để bảo đảm thay đổi mới không phá vỡ tính năng cũ.

---

### BƯỚC 6: ĐÓNG CHANGE REQUEST & BÁO CÁO CHO NGƯỜI DÙNG
Báo cáo tóm tắt:
- Các thành phần đã điều chỉnh theo CR.
- Các bằng chứng cũ được tái sử dụng thành công.
- Các cổng đã được mở lại kèm Evidence SHA-256 mới.
- Hướng dẫn bước kiểm chứng tiếp theo cho người dùng.
```
