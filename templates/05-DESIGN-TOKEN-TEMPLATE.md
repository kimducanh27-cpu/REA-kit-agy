# HỢP ĐỒNG THIẾT KẾ GIAO DIỆN & DESIGN TOKENS (DESIGN.MD)
*(File điều khiển giao diện toàn bộ ứng dụng — Người non-tech chỉ cần sửa mã màu/font ở đây để đổi theme)*

---

## 1. PHONG CÁCH CHỦ ĐẠO (DESIGN THEME)
- **Tên phong cách:** [Chọn: Hiện đại tối giản (Modern Clean) / Bảng điều khiển (Dashboard) / Chuyên nghiệp (Corporate) / Công nghệ tối (Dark Tech)]
- **Chế độ hiển thị:** [Light Mode (Mặc định) / Dark Mode / Tự động theo hệ điều hành]

---

## 2. BẢNG MÀU HỆ THỐNG (COLOR PALETTE TOKENS)
*Toàn bộ mã nguồn sẽ tự động đọc các biến này thay vì hardcode mã màu:*

```css
:root {
  /* Màu chủ đạo thương hiệu */
  --color-primary: #2563eb;         /* Xanh dương chính */
  --color-primary-hover: #1d4ed8;   /* Màu khi di chuột vào nút */
  
  /* Màu nền & Bề mặt thẻ */
  --color-background: #f8fafc;      /* Màu nền toàn trang */
  --color-surface: #ffffff;         /* Màu nền thẻ card / modal */
  --color-border: #e2e8f0;          /* Màu viền ngăn cách */

  /* Màu chữ */
  --color-text-main: #0f172a;       /* Chữ tiêu đề và nội dung chính */
  --color-text-muted: #64748b;      /* Chữ phụ, mô tả mờ */

  /* Màu trạng thái hành động */
  --color-accent: #10b981;          /* Xanh lá: Thành công, nút hoàn thành */
  --color-danger: #ef4444;          /* Đỏ: Nút xóa, cảnh báo rủi ro */
  --color-warning: #f59e0b;         /* Vàng: Cảnh báo cần chú ý */
}
```

---

## 3. PHÔNG CHỮ & KÍCH THƯỚC (TYPOGRAPHY TOKENS)
```css
:root {
  --font-main: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
  --font-size-base: 16px;
  --line-height-base: 1.5;
}
```

---

## 4. BO GÓC & ĐỔ BÓNG (RADIUS & ELEVATION)
```css
:root {
  --radius-sm: 6px;                 /* Bo góc nút bấm nhỏ, ô nhập liệu */
  --radius-md: 12px;                /* Bo góc thẻ card, bảng biểu */
  --radius-lg: 20px;                /* Bo góc modal, khung lớn */
  --shadow-card: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
}
```
