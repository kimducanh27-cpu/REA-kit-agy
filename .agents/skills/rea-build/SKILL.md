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
   - Nếu là **Hướng B (Viết lại hoàn toàn)**: Khởi tạo khung dự án mới tinh. **Bắt buộc ưu tiên công nghệ Web độc lập (Single-file HTML/CSS/JavaScript)** để người dùng non-tech có thể mở chạy ngay bằng trình duyệt (Chrome/Edge) mà không cần cài đặt Node.js hay Python.

3. **Cổng kiểm chứng bắt buộc (Verification Gate)**:
   - Viết mã nguồn sạch, có chú thích tiếng Việt.
   - Bắt buộc tự chạy lệnh kiểm tra cú pháp hoặc build thử nghiệm trước khi báo hoàn thành.
   - Xuất file **`05_MA_NGUON_PHAT_TRIEN/KET_QUA_KIEM_THU.md`** gồm:
     * Lệnh kiểm tra đã chạy (Syntax check / Build / Test).
     * Kết quả thực tế (Thành công / Cảnh báo).
     * Bằng chứng chức năng hoạt động bình thường, không có lỗi cú pháp.

4. **Tạo tài liệu hướng dẫn chạy 1 trang (Run Guide)**:
   - Tạo file `05_MA_NGUON_PHAT_TRIEN/HUONG_DAN_CHAY_APP.md` đúng 1 trang:
     1. Cách mở ứng dụng (ví dụ: "Nhấp đúp chuột vào file `index.html` để mở trong trình duyệt").
     2. Cách thử nghiệm các tính năng mới vừa được thêm.
     3. Hướng dẫn sao lưu hoặc hoàn tác nếu cần.

5. **Đồng bộ tiến độ & Trạng thái**:
   - Cập nhật kết quả hoàn thành vào `docs/PROGRESS.md` và `docs/HANDOFF.md`.
   - Cập nhật file `.agents/state/active_case.json`:
     * `build_status`: `"SUCCESS"`
     * `current_phase`: `"BUILD_COMPLETED"`
     * `last_updated`: Thời gian hiện tại.
