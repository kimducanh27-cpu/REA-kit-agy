# HỒ SƠ NỘI DUNG VĂN BẢN THỰC TẾ (COPY DECK SPECIFICATION)
> **Dự án**: [Tên Sản Phẩm / Ứng Dụng]  
> **Thời gian lập**: YYYY-MM-DD  
> **Quy chuẩn**: Anti-Slop Design Architecture · REA-kit-agy v1.1  
> **Nguyên tắc cốt tử**: CẤM 100% văn bản placeholder (`Lorem ipsum`, `Sample text`, `Welcome back!` vô nghĩa). Mọi màn hình phải có Copy Deck thực tế kèm giới hạn ký tự và phương án xử lý tràn chữ.

---

## 1. Tiêu Chuẩn Giọng Văn & Ngôn Từ (Tone of Voice)
- **Giọng điệu chủ đạo**: [Ví dụ: Rõ ràng, Chân thành, Thấu hiểu, Chuyên nghiệp nhưng bình dân]
- **Ngôn ngữ chính**: Tiếng Việt (chuẩn chính tả, ngữ pháp, không lạm dụng từ mượn tiếng Anh khi có từ tiếng Việt tương đương)
- **Quy tắc viết hoa**: Sentence case cho tiêu đề và nút bấm (viết hoa chữ cái đầu: "Thêm ghi chú mới", tránh "THÊM GHI CHÚ MỚI" hoặc Title Case kiểu tiếng Anh)

---

## 2. Bảng Kê Văn Bản Chi Tiết Từng Màn Hình (Screen Copy Register)

### Màn hình 01: [Tên Màn Hình Chính / Ví dụ: Trang Tổng Quan]
| Vị Trí Thành Phần | Chuỗi Văn Bản Thực Tế (Copy) | Giới Hạn Ký Tự | Hành Vi Khi Tràn Chữ (Overflow / Wrap) | Ghi Chú Ngữ Cảnh |
| :--- | :--- | :--- | :--- | :--- |
| **Tiêu đề chính (Header)** | "Kế hoạch hôm nay" | Tối đa 24 ký tự | Xuống tối đa 2 dòng | Luôn cố định trên cùng |
| **Phụ đề (Subtitle)** | "Bạn có 3 công việc cần giải quyết trước 17:00" | Tối đa 60 ký tự | Cắt ba chấm (...) sau 2 dòng | Thay đổi động theo dữ liệu |
| **Nút bấm chính (Primary CTA)** | "Tạo việc mới" | Tối đa 16 ký tự | Không xuống dòng, co phông chữ nhẹ nếu cần | Nút bấm nổi bật nhất |
| **Thẻ danh mục (Item Title)** | "[Tên công việc cụ thể / ví dụ: Soát hợp đồng mua sắm thiết bị]" | Tối đa 80 ký tự | Xuống dòng tự nhiên, tối đa 3 dòng | Bắt buộc dữ liệu mẫu thực tế |
| **Nhãn trạng thái (Status Badge)**| "Đang thực hiện" / "Đã hoàn thành" | Tối đa 15 ký tự | Cố định 1 dòng | Dùng token màu tương ứng |

---

## 3. Bộ Văn Bản 4 Trạng Thái Giao Diện Bắt Buộc (4 UI States Microcopy)

### 3.1 Trạng Thái Đang Tải (Loading State)
- **Thông điệp chính**: "Đang đồng bộ dữ liệu..."
- **Thông điệp phụ (khi tải lâu > 3s)**: "Hệ thống đang chuẩn bị tài liệu của bạn, vui lòng đợi trong giây lát."

### 3.2 Trạng Thái Rỗng (Empty State)
- **Tiêu đề**: "Chưa có nội dung nào tại đây"
- **Giải thích ngữ cảnh**: "Hãy tạo mục đầu tiên để bắt đầu theo dõi tiến độ công việc của bạn."
- **Nút hành động (CTA)**: "Tạo mục mới ngay"

### 3.3 Trạng Thái Hoàn Thành (Success State)
- **Toast thông báo nhanh**: "Đã lưu thay đổi thành công"
- **Hộp thoại chúc mừng (nếu có)**: "Bạn đã hoàn thành toàn bộ mục tiêu hôm nay!"

### 3.4 Trạng Thái Báo Lỗi & Phục Hồi (Error / Recovery State - RULE-INIT-001)
- **Banner lỗi ngắn gọn**: "Không thể kết nối tới cơ sở dữ liệu cục bộ"
- **Hướng dẫn phục hồi**: "Thông tin bạn vừa nhập đã được giữ nguyên an toàn. Hãy bấm Thử lại để lưu lại."
- **Nút bấm phục hồi**: "Thử lại ngay"

---

## 4. Dự Phòng Đa Ngôn Ngữ & Mở Rộng Ký Tự (Localization Expansion)
- Độ co giãn độ dài chuỗi dự kiến khi dịch sang ngôn ngữ dài nhất (tiếng Đức hoặc tiếng Pháp): **Tăng từ 30% đến 40%**.
- Toàn bộ component UI chứa văn bản bắt buộc có thuộc tính `minHeight` / `wrapContent` mềm dẻo, không cố định chiều cao cứng (hardcoded height) gây mất chữ.
