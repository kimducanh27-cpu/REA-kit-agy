# HƯỚNG DẪN PHỎNG VẤN CHUYÊN BIỆT: TIÊU CHÍ NGHIỆM THU (ACCEPTANCE CRITERIA SPECIFICATION)
> **Domain**: `ACCEPTANCE_CRITERIA`  
> **Áp dụng cho**: Bước 06 (`06_REA_INTERVIEW`) & Bước 07 (`07_SPEC_AND_DESIGN`) thuộc STAGE_03 · PRODUCT DEFINITION  
> **Quy chuẩn**: REA Adaptive Interview Framework · Verifiable Given/When/Then Contracts  

---

## 1. Mục Tiêu & Phạm Vi Phỏng Vấn

Hướng dẫn này chịu trách nhiệm **chuyển đổi mọi mong muốn định tính của người dùng ("chạy mượt", "bảo mật", "dễ dùng", "xuất file đẹp") thành các điều kiện nghiệm thu định lượng, có thể kiểm chứng được bằng mắt hoặc bằng mã kiểm thử tự động (Verifiable Specifications)** trước khi đóng băng Cổng 03.

Nguyên tắc:
- **Cấm các tính từ mơ hồ không đo lường được**: Không chấp nhận "chạy nhanh" (phải là `< 1.2s`), không chấp nhận "giao diện đẹp" (phải là "đạt WCAG AA 4.5:1, touch target >= 48dp, 4 UI states").
- **Định dạng Given / When / Then chuẩn hóa**: Mỗi tính năng nghiệp vụ phải có ít nhất 1 kịch bản kiểm thử Happy Path và 1 kịch bản Edge Case / Error Recovery.

---

## 2. Cấu Trúc Tiêu Chí Nghiệm Thu Given / When / Then

```gherkin
Kịch bản: [Tên kịch bản kiểm thử]
GIVEN [Trạng thái bắt đầu / Tiền đề hệ thống]
WHEN  [Hành động của người dùng hoặc sự kiện kích hoạt]
THEN  [Kết quả quan sát được trên giao diện hoặc phản hồi hệ thống]
AND   [Trạng thái dữ liệu được bảo toàn hoặc cập nhật]
```

### Ví Dụ Chuyển Đổi Thực Tế:

#### Trường hợp 1: Xuất Báo Cáo Excel (Case C)
- *Mong muốn mơ hồ*: "Cho tôi xuất file Excel danh sách giao dịch."
- *Tiêu chí nghiệm thu định lượng*:
  ```gherkin
  Kịch bản 1: Xuất file thành công khi có kết nối lưu trữ
  GIVEN Người dùng đang ở màn hình Lịch sử giao dịch và đã chọn bộ lọc từ ngày 01/10 đến 31/10
  WHEN Người dùng nhấn nút "Xuất file Excel (.xlsx)"
  THEN Hệ thống tạo tệp "Bao_Cao_Giao_Dich_202610.xlsx" chứa đúng số dòng theo bộ lọc, có đầy đủ 6 cột: Ngày, Mã GD, Loại, Số tiền, Trạng thái, Ghi chú
  AND Hiển thị thông báo thành công kèm nút "Mở tệp" hoặc "Chia sẻ" trong vòng 2 giây.

  Kịch bản 2: Không có quyền ghi bộ nhớ hoặc danh sách rỗng
  GIVEN Bộ lọc trả về 0 kết quả giao dịch
  WHEN Người dùng nhấn "Xuất file Excel"
  THEN Nút xuất bị vô hiệu hóa hoặc hiển thị banner "Không có dữ liệu trong khoảng thời gian đã chọn"
  AND Không tạo ra tệp rỗng trên bộ nhớ thiết bị.
  ```

#### Trường hợp 2: Khôi Phục Form Khi Lỗi Mạng (RULE-INIT-001)
- *Tiêu chí nghiệm thu định lượng*:
  ```gherkin
  Kịch bản: Bảo toàn dữ liệu người dùng khi gửi form thất bại
  GIVEN Người dùng đã nhập đầy đủ 5 trường thông tin trên form thanh toán
  WHEN Nhấn "Xác nhận gửi" nhưng thiết bị mất kết nối mạng
  THEN Hiển thị banner lỗi màu đỏ: "Không thể kết nối máy chủ. Vui lòng thử lại"
  AND Toàn bộ 5 trường dữ liệu người dùng vừa nhập KHÔNG BỊ XÓA TRẮNG.
  ```

---

## 3. Khung Câu Hỏi Quyết Định Tiêu Chí Nghiệm Thu (Decision-Driven Question Catalog)

### Q-ACCEPT-01: Định Lượng Kết Quả Kỳ Vọng (Measurable Outcome Definition)
- **Câu hỏi**: Khi tính năng này hoạt động đúng theo ý bạn, dấu hiệu cụ thể nào trên màn hình hoặc tệp đầu ra chứng minh nó đã thành công?
- **Intent**: Lập kịch bản `THEN` trong đặc tả Given/When/Then.
- **Related Decision**: `DECISION-ACCEPT-01: Verifiable Acceptance Benchmark`.
- **Expected Information**: Bảng cột cụ thể / Thông báo hiển thị / Trạng thái cập nhật.
- **Applicability Conditions**: Mọi tính năng mới hoặc tính năng tối ưu.
- **Skip Conditions**: Đã có bản mô tả chi tiết kèm mockup / test case.

### Q-ACCEPT-02: Hành Vi Khi Gặp Lỗi / Không Đạt Điều Kiện (Failure & Edge Case Handling)
- **Câu hỏi**: Nếu người dùng nhập sai thông tin hoặc mất mạng giữa chừng, ứng dụng nên thông báo thế nào và làm gì với dữ liệu đã nhập?
- **Intent**: Lập kịch bản Error Recovery theo `RULE-INIT-001`.
- **Related Decision**: `DECISION-ACCEPT-02: Error Recovery Behavior`.
- **Expected Information**: Giữ nguyên form + nút Thử lại / Tự động lưu bản nháp.

---

## 4. Bảng Tiêu Chí Nghiệm Thu Đóng Băng

1. Toàn bộ tính năng Must-Have đều có ít nhất 1 kịch bản Given / When / Then hoàn chỉnh trong `dac-ta-yeu-cau-da-chot.md`.
2. Không còn bất kỳ chỉ số định tính mơ hồ nào (ví dụ: "nhanh", "đẹp", "chuẩn") chưa được lượng hóa thành con số hoặc trạng thái cụ thể.
3. Kịch bản nghiệm thu được dùng làm đầu vào trực tiếp cho Bước 10 (`10_BUILD_QA`) và Bước 12 (`12_HARD_VERIFY`).
