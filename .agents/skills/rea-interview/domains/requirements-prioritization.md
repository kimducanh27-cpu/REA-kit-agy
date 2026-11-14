# HƯỚNG DẪN PHỎNG VẤN CHUYÊN BIỆT: ƯU TIÊN HÓA YÊU CẦU & ĐÁNH ĐỔI (REQUIREMENTS PRIORITIZATION)
> **Domain**: `REQUIREMENTS_PRIORITIZATION`  
> **Áp dụng cho**: Bước 06 (`06_REA_INTERVIEW`) & Bước 07 (`07_SPEC_AND_DESIGN`) thuộc STAGE_03 · PRODUCT DEFINITION  
> **Quy chuẩn**: REA Adaptive Interview Framework · MoSCoW & Trade-Off Governance  

---

## 1. Mục Tiêu & Phạm Vi Phỏng Vấn

Hướng dẫn này kích hoạt khi **phạm vi yêu cầu của người dùng quá rộng, có sự đánh đổi giữa các yếu tố (ví dụ: Bảo mật cao vs Khởi động nhanh, Đồ họa phức tạp vs Dung lượng nhẹ), hoặc cần phân kỳ lộ trình phát triển thành các Vertical Slices khả thi**.

Nguyên tắc:
- **Không nhồi nhét mọi thứ vào bản v1.0**: Phân loại rõ ràng cái gì bắt buộc có ngay (Must-Have) và cái gì có thể hoãn lại (Deferred / Won't-Have for now).
- **Minh bạch hóa sự đánh đổi (Explicit Trade-Offs)**: Khi người dùng muốn cả 2 thứ đối nghịch, chỉ rõ hệ quả để người dùng quyết định ưu tiên cái nào.

---

## 2. Mô Hình Phân Loại MoSCoW & Đánh Đổi

### 2.1 Ma Trận Phân Loại MoSCoW
- **MUST HAVE (Bắt buộc phải có)**:
  * Không có tính năng này thì sản phẩm vô nghĩa hoặc không thể sử dụng.
  * Không có phương án thay thế thủ công nào khả dĩ.
  * Bắt buộc có mặt tại Milestone 1 - 3 ở Stage 04.
- **SHOULD HAVE (Rất nên có)**:
  * Tính năng quan trọng, tăng mạnh trải nghiệm người dùng nhưng tạm thời có thể dùng giải pháp thủ công hoặc hoãn sang Milestone 4 - 6.
- **COULD HAVE (Có thì tốt)**:
  * Các tiện ích nhỏ, hiệu ứng phụ, tùy biến nâng cao. Chỉ làm khi còn ngân sách thời gian/token.
- **WON'T HAVE / EXPLICIT NON-GOALS (Rõ ràng KHÔNG làm trong đợt này)**:
  * Những tính năng người dùng có thể nghĩ tới nhưng thống nhất loại trừ khỏi phạm vi để đảm bảo giao hàng đúng hạn.

### 2.2 Các Cặp Đánh Đổi Điển Hình (Classic Trade-Offs)
1. **Bảo Mật Tối Đa vs Thời Gian Khởi Động**: Mã hóa toàn bộ dữ liệu cục bộ bằng AES-256 + Play Integrity attestation làm tăng thời gian khởi động app thêm 300-500ms.
2. **Đồng Bộ Realtime vs Tiết Kiệm Pin/Dung Lượng**: WebSocket liên tục tiêu tốn pin hơn polling định kỳ.
3. **Sao Chép 1-1 Tuyệt Đối vs Chuẩn Hóa Tiện Nghi Hiện Đại**: Giữ nguyên layout cũ có thể mang theo lỗi touch target nhỏ hoặc giao diện lỗi thời.

---

## 3. Khung Câu Hỏi Quyết Định Ưu Tiên (Decision-Driven Question Catalog)

### Q-PRIO-01: Phân Định Tính Năng Cốt Lõi Bắt Buộc (Core MVP Boundary)
- **Câu hỏi**: Trong các tính năng bạn vừa nêu ([Liệt kê A, B, C]), nếu bắt buộc phải bàn giao một bản chạy được đầu tiên trong hôm nay, tính năng nào là tuyệt đối không thể thiếu?
- **Intent**: Định hình Milestone 1-3 trong Kế hoạch triển khai (Step 08).
- **Related Decision**: `DECISION-PRIO-01: MVP Feature Boundary`.
- **Expected Information**: Danh sách tính năng Must-Have được chốt.
- **Applicability Conditions**: Yêu cầu người dùng chứa nhiều tính năng độc lập.
- **Skip Conditions**: Bài toán sửa 1 lỗi duy nhất hoặc chỉ tối ưu 1 màn hình.

### Q-PRIO-02: Phân Định Đánh Đổi Hiệu Năng vs Bảo Mật (Performance vs Security Trade-Off)
- **Câu hỏi**: Giữa việc khởi động app siêu nhanh (< 800ms) và việc quét tính toàn vẹn hệ thống sâu (Play Integrity + mã hóa bộ nhớ), bạn muốn ưu tiên hướng nào hơn?
- **Intent**: Lựa chọn giải pháp mã hóa và rà soát an toàn phù hợp.
- **Related Decision**: `DECISION-PRIO-02: Security vs Startup Performance Balance`.
- **Expected Information**: Ưu tiên tốc độ / Ưu tiên an ninh tối đa.
- **Applicability Conditions**: Ứng dụng tài chính hoặc xử lý dữ liệu cá nhân.

---

## 4. Bảng Tiêu Chí Nghiệm Thu Đóng Băng Ưu Tiên

1. Danh mục Non-Goals (những gì không làm) được ghi nhận tường minh trong bản đặc tả `dac-ta-yeu-cau-da-chot.md`.
2. Không có bất kỳ mâu thuẫn ưu tiên nào còn tồn tại ở trạng thái chưa giải quyết (Unresolved Conflict).
3. Bản kế hoạch triển khai tại Bước 08 được sắp xếp đúng thứ tự: Must-Have trước, Should-Have sau.
