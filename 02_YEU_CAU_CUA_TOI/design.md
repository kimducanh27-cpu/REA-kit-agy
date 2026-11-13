# HỢP ĐỒNG THIẾT KẾ GIAO DIỆN & DESIGN SYSTEM 3 TẦNG CỦA TÔI
*(Người dùng: Tùy chỉnh màu sắc, font chữ hoặc quy chuẩn giao diện tại đây. AI sẽ tự động đọc và áp dụng vào toàn bộ mã nguồn)*

---

## TẦNG 1: THIẾT KẾ CƠ SỞ & BẢNG MÀU (TOKENS)

### 1. Phong cách mong muốn
- **Tên phong cách:** Hiện đại & Tối giản (Modern Clean)
- **Chế độ hiển thị:** Light Mode (Sáng)

### 2. Bảng màu ứng dụng (CSS Tokens)
```css
:root {
  /* Màu thương hiệu & Nút chính */
  --color-primary: #2563eb;         /* Xanh dương hiện đại */
  --color-primary-hover: #1d4ed8;   /* Màu di chuột vào nút */
  
  /* Nền trang & Bề mặt khung */
  --color-background: #f8fafc;      /* Nền xám nhạt dịu mắt */
  --color-surface: #ffffff;         /* Nền trắng cho thẻ và bảng */
  --color-border: #e2e8f0;          /* Đường viền ngăn cách */

  /* Màu chữ */
  --color-text-main: #0f172a;       /* Chữ đen đậm dễ đọc */
  --color-text-muted: #64748b;      /* Chữ phụ xám mờ */

  /* Màu trạng thái */
  --color-accent: #10b981;          /* Xanh lá: Thành công */
  --color-danger: #ef4444;          /* Đỏ: Xóa, Lỗi */
  --color-warning: #f59e0b;         /* Vàng: Cảnh báo */
}
```

### 3. Phông chữ & Bo góc
```css
:root {
  --font-main: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
  --radius-sm: 6px;
  --radius-md: 10px;
  --radius-lg: 16px;
}
```

---

## TẦNG 2: THÀNH PHẦN GIAO DIỆN DÙNG CHUNG (COMPONENTS)
- **Nút bấm chính (Button)**: Bo góc 6px, nền xanh `--color-primary`, chữ trắng đậm, hiệu ứng bóng nhẹ khi bấm.
- **Thẻ hiển thị (Card)**: Bo góc 10px, nền trắng, viền mảnh `--color-border`, padding thoải mái 20px.
- **Ô nhập liệu (Input)**: Viền xám nhạt, đổi màu viền xanh khi nhấp chuột vào để gõ, bo góc 6px.
- **Thanh menu đầu trang (Header)**: Nền trắng, cố định trên cùng, chứa tên ứng dụng và các nút điều hướng nhanh.

---

## TẦNG 3: QUY CHUẨN 4 TRẠNG THÁI GIAO DIỆN (UI STATES)
*(Tuyệt đối không để màn hình đơ hoặc trắng trang trong bất kỳ tình huống nào)*
1. **Đang tải (Loading)**: Hiện hiệu ứng khung xương xám nhấp nháy (skeleton) hoặc vòng xoay, nút bấm chuyển sang trạng thái mờ (disabled).
2. **Không có dữ liệu (Empty)**: Hiện biểu tượng thư mục rỗng kèm thông báo *"Chưa có dữ liệu nào"* và nút bấm to rõ *"Tạo mới ngay"*.
3. **Thành công (Success)**: Hiện thông báo xanh góc màn hình *"Đã lưu thành công"* và tự tắt sau 3 giây.
4. **Báo lỗi (Error)**: Khung đỏ nổi bật giải thích nguyên nhân rõ ràng, có nút *"Thử lại"* và giữ nguyên dữ liệu người dùng vừa nhập.
