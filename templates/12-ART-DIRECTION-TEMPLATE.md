# HỒ SƠ ĐỊNH HƯỚNG NGHỆ THUẬT & CẤU TRÚC GIAO DIỆN (ART DIRECTION SPECIFICATION)
> **Dự án**: [Tên Sản Phẩm / Ứng Dụng]  
> **Thời gian lập**: YYYY-MM-DD  
> **Quy chuẩn**: Anti-Slop Design Architecture · REA-kit-agy v1.1  
> **Mục tiêu**: Loại bỏ triệt để giao diện khuôn sáo (generic AI slop), lấy nội dung thực tế làm trung tâm.

---

## 1. Bản Sắc & Định Vị Thị Giác (Brand & Visual Personality)

- **Cá tính sản phẩm (Product Personality)**: [Ví dụ: Tinh giản, Đáng tin cậy, Trầm tĩnh, Tập trung cao độ]
- **Ý tưởng thị giác chủ đạo (Visual Thesis)**: [Ví dụ: Không gian học tập biên tập (Editorial Workspace), biến bài học thành trang tạp chí mở thay vì bảng điều khiển thẻ số]
- **Triết lý bố cục không gian (Layout Philosophy)**: [Ví dụ: Khối liền mạch, tận dụng khoảng trắng có chủ đích, phân vùng theo luồng đọc tự nhiên F-pattern]
- **Phân cấp chữ (Typography Hierarchy)**:
  * Display: [Tên font / Kích thước / Trọng lượng]
  * Headline: [Tên font / Kích thước / Trọng lượng]
  * Body: [Tên font / Line-height / Đảm bảo dễ đọc]
  * Label / Caption: [Rõ ràng, không quá nhỏ dưới 12sp]
- **Mức độ đậm đặc thông tin (Information Density)**: `[ ] Thấp (Thư thả, trải nghiệm)` | `[x] Vừa (Cân bằng)` | `[ ] Cao (Công cụ chuyên sâu)`
- **Điểm nhấn đặc trưng (Signature Element)**: [Một đặc điểm nhận diện đáng nhớ, ví dụ: Thanh tiến độ dạng timeline uốn cong nhẹ / Thẻ bài học tràn viền có bookmark]
- **Danh sách lối mòn cấm kỵ (Forbidden Anti-Patterns)**:
  * [x] KHÔNG dùng dashboard 8 thẻ card chỉ để hiển thị con số vô nghĩa.
  * [x] KHÔNG thêm dải màu gradient nổi trôi lอย chỉ để làm màu.
  * [x] KHÔNG dùng icon tròn đặt trong ô vuông có nền mờ trang trí vô bổ.
  * [x] KHÔNG dồn ép người dùng bằng các biểu đồ khi dữ liệu chưa đủ.

---

## 2. Ba Phương Án Đa Dạng Cấu Trúc (3 Structurally Diverse Concepts)

AI bắt buộc đề xuất 3 phương án khác biệt hoàn toàn về **cách tổ chức thông tin và phân cấp thị giác** để người dùng lựa chọn:

### Phương Án A — Tập Trung Nhiệm Vụ (Task-Centric)
- **Triết lý**: Đưa ngay hành động cốt lõi nhất lên vị trí trung tâm màn hình khi mở app.
- **Bố cục chính**: [Mô tả chi tiết vị trí vùng hành động, vùng lịch sử, công cụ hỗ trợ]
- **Điểm mạnh**: Người dùng thao tác nhanh nhất, không mất thời gian tìm kiếm.
- **Phù hợp với**: [Kiểu người dùng / nghiệp vụ phù hợp]

### Phương Án B — Lấy Nội Dung Làm Gốc (Content-First / Editorial)
- **Triết lý**: Dữ liệu và nội dung chính được dàn trang như một cuốn sách/tạp chí; các thanh điều khiển ẩn nhẹ ở góc.
- **Bố cục chính**: [Mô tả chi tiết luồng đọc, cách hiển thị chi tiết, khoảng cách chữ]
- **Điểm mạnh**: Tập trung tối đa vào nội dung, tạo cảm giác cao cấp và tĩnh tại.
- **Phù hợp với**: [Kiểu người dùng / nghiệp vụ phù hợp]

### Phương Án C — Luồng Thích Ứng Ngữ Cảnh (Contextual / Progressive Flow)
- **Triết lý**: Màn hình biến đổi tuần tự theo trạng thái thực tế của người dùng (chưa làm gì -> đang làm dở -> hoàn thành).
- **Bố cục chính**: [Mô tả cách các khối component xuất hiện linh hoạt theo ngữ cảnh]
- **Điểm mạnh**: Tối ưu hóa không gian, không hiển thị thành phần thừa khi chưa cần tới.
- **Phù hợp với**: [Kiểu người dùng / nghiệp vụ phù hợp]

---

## 3. Câu Hỏi Tự Phản Biện Chống Slop (Self-Critique Questions)

- [x] **Tính đặc thù**: Nếu đổi tên app thành tên một sản phẩm khác trong cùng ngành, thiết kế này có dùng được không? (Nếu dùng được ngay -> Cảnh báo thiết kế quá đại trà, cần cá tính hóa thêm).
- [x] **Tính phục vụ**: Mọi thành phần trên màn hình có phục vụ trực tiếp nhiệm vụ của người dùng không?
- [x] **Tính thực tế**: Có thành phần nào sinh ra chỉ vì AI quen tay vẽ thẻ Card hay Gradient không?

---

## 4. Phê Duyệt Của Người Dùng (Human Gate 1 Signoff)

- [ ] Phương án được chọn: `[ ] Phương Án A` | `[ ] Phương Án B` | `[ ] Phương Án C`
- **Câu lệnh người dùng duyệt**:
  `APPROVE SCREEN COMPOSITION`
