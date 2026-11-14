# BÁO CÁO NGHIỆM THU ĐỐI CHIẾU 1-1 (HARD VERIFY ACCEPTANCE REPORT)
> **Dự án**: [Tên Ứng Dụng Mới]  
> **Ứng dụng gốc tham chiếu**: [Tên Ứng Dụng Gốc tại 01_THA_APP_VAO_DAY/]  
> **Thời gian nghiệm thu**: YYYY-MM-DD HH:mm  
> **Phiên bản mã nguồn**: v1.0  
> **Trạng thái Cổng**: CỔNG 05 (gate_05_hard_verify_passed)

---

## 1. Tóm Tắt Kết Quả Đối Chiếu & Phương Pháp Kiểm Chứng

- **Tổng số tính năng đem so sánh**: [Số lượng]
- **Tỷ lệ tương thích yêu cầu**: [Ví dụ: 100%]
- **Build Route đã chọn**: `[ ] Route A (Web App Zero-Install)` | `[ ] Route B (Android Native Project)` | `[ ] Route C (Patch APK / Hybrid)`
- **Phương pháp & Công cụ kiểm chứng sử dụng**:
  * **Đối với Web (Route A)**: Đối chiếu trực tiếp trên trình duyệt với ảnh baseline trong `01_THA_APP_VAO_DAY/baseline/`.
  * **Đối với Android (Route B / Route C)**:
    - Trích xuất và so sánh phân cấp cây giao diện 1-1: `android layout`.
    - Chụp ảnh màn hình đối chiếu: `android screen capture -o <file_path>` (hoặc REA ADB `capture_adb_screen` với tham số `serial`, `output-directory`).
    - Khởi chạy và kiểm tra luồng runtime trên AVD/thiết bị: `start_adb_app` (với `serial`, `package`) hoặc qua Antigravity Device Hub.
- **Kết luận chung**: `[ ] ĐẠT NGHIỆM THU (PASS)` | `[ ] CẦN CHỈNH SỬA (RETRY)`

---

## 2. Bảng Đối Chiếu Trực Quan 3 Cột (Visual 1-to-1 Matrix)

| Chức Năng / Màn Hình | Cột 1: Khớp 100% (Y Hệt Bản Gốc) | Cột 2: Khác Biệt Có Chủ Đích (Đã Thống Nhất) | Cột 3: Nâng Cấp Mới (Cải Tiến UX/Bảo Mật) | Đánh Giá |
| :--- | :--- | :--- | :--- | :--- |
| **Màn hình Đăng nhập / Bắt đầu** | Giữ nguyên logo, trường nhập tên, nút bấm chính | Bỏ qua bước kết nối máy chủ bí mật (thay bằng phiên cục bộ) | Thêm thông báo lỗi tiếng Việt thân thiện, hỗ trợ Enter | `[x] ĐẠT` |
| **Danh sách Dữ liệu / Sản phẩm** | Bố cục dạng lưới, hiển thị hình ảnh, tên và giá tiền | Dữ liệu mẫu hiển thị ngay không cần chờ mạng chập chờn | Bổ sung thanh tìm kiếm nhanh realtime và bộ lọc trạng thái | `[x] ĐẠT` |
| **Thao tác Thêm / Sửa / Xóa** | Quy trình thao tác dữ liệu chuẩn xác | Lưu trữ trực tiếp trong trình duyệt (LocalStorage) | Tự động kiểm tra tính hợp lệ dữ liệu (Validate form) trước khi lưu | `[x] ĐẠT` |
| **Bảo Mật & Riêng Tư** | Không thay đổi mục đích sử dụng | Đã che mờ và gỡ bỏ toàn bộ telemetry/theo dõi của app gốc | Zero-Install: Không đòi quyền hệ thống hay mạng ngoài nguy hiểm | `[x] ĐẠT` |

---

## 3. Kiểm Thử Trải Nghiệm Thực Tế & 4 Trạng Thái Giao Diện

- [x] **Trạng thái Đang tải (Loading State)**: Hiển thị hiệu ứng mượt mà khi bấm thao tác.
- [x] **Trạng thái Rỗng (Empty State)**: Có thông báo và hướng dẫn thêm dữ liệu khi chưa có nội dung.
- [x] **Trạng thái Thành công (Success State)**: Dữ liệu cập nhật ngay tức thì, có Toast báo thành công.
- [x] **Trạng thái Báo lỗi (Error State)**: Thông báo màu đỏ rõ ràng, hướng dẫn cách sửa lỗi bằng tiếng Việt đời thường.

---

## 4. Xác Nhận Nghiệm Thu (User Sign-off)

- [ ] Tôi đã trực tiếp mở ứng dụng mới và đối chiếu với app gốc.
- [ ] Tôi xác nhận các chức năng hoạt động đúng như mong đợi và đạt yêu cầu.
- [ ] Cho phép Agent chuyển sang Bước 13 để bàn giao và đóng gói sản phẩm.

---
*Tài liệu tự động tạo bởi Kỹ năng `rea-build` tại Bước 12.*
