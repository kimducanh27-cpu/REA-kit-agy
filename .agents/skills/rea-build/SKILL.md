---
name: rea-build
description: Lập kế hoạch kiến trúc, triển khai mã nguồn ứng dụng vào thư mục 05_MA_NGUON_PHAT_TRIEN, kiểm thử chức năng và viết tài liệu hướng dẫn chạy app sau khi người dùng đã duyệt đặc tả yêu cầu. Kích hoạt khi người dùng chạy Prompt 4 hoặc yêu cầu phát triển/viết lại app.
---

# KỸ NĂNG: PHÁT TRIỂN & VIẾT LẠI ỨNG DỤNG (REA-BUILD)

Kỹ năng chuyên biệt cho giai đoạn sinh mã nguồn và kiểm thử, đối chiếu chuẩn quy trình `docs/APP_REVIEW_WORKFLOW.md` (Phần 6 đến 8).

---

## 1. QUY TRÌNH TRIỂN KHAI

1. **Kiểm tra điều kiện tiên quyết (Preflight Check)**:
   - Đọc file đặc tả yêu cầu đã chốt trong `03_KET_QUA_KIEM_TRA/`.
   - Nếu chưa có đặc tả: Nhắc nhở người dùng chạy bước phỏng vấn (`rea-interview`) trước khi viết code.

2. **Khởi tạo không gian mã nguồn tại `05_MA_NGUON_PHAT_TRIEN/`**:
   - Nếu là **Hướng A (Nâng cấp tiếp)**: Sao chép mã nguồn gốc từ `04_SAO_LUU_AN_TOAN/` sang `05_MA_NGUON_PHAT_TRIEN/` và tạo nhánh/thư mục làm việc an toàn.
   - Nếu là **Hướng B (Viết lại hoàn toàn)**: Khởi tạo khung dự án mới tinh (Scaffold) với công nghệ hiện đại đã thống nhất.

3. **Viết mã nguồn & Kiểm thử (Build & Test)**:
   - Viết code sạch, có chú thích tiếng Việt rõ ràng.
   - Chạy kiểm tra cú pháp, build thử hoặc chạy unit test (nếu có).
   - Tuyệt đối không để lại file rác hoặc các API key bí mật trong code.

4. **Tạo tài liệu hướng dẫn chạy (Run Guide)**:
   - Tạo file `05_MA_NGUON_PHAT_TRIEN/HUONG_DAN_CHAY_APP.md` dài đúng 1 trang:
     1. Yêu cầu cài đặt tối thiểu (ví dụ: cần cài Node.js hoặc Python).
     2. Lệnh khởi chạy ứng dụng (ví dụ: `npm start` hoặc `python app.py`).
     3. Cách kiểm tra các tính năng mới vừa được thêm.

5. **Đồng bộ tiến độ**:
   - Cập nhật kết quả hoàn thành vào `docs/PROGRESS.md` và `docs/HANDOFF.md`.
