# HỢP ĐỒNG THIẾT KẾ GIAO DIỆN & DESIGN SYSTEM 3 TẦNG (DESIGN.MD)
*(File điều khiển giao diện toàn bộ ứng dụng — Người non-tech chỉ cần sửa mã màu/font/quy chuẩn ở đây để đổi toàn bộ theme)*

---

## TẦNG 1: THIẾT KẾ CƠ SỞ & DESIGN TOKENS (FOUNDATIONS)

### 1. Phong cách chủ đạo (Design Theme)
- **Tên phong cách:** [Hiện đại tối giản (Modern Clean) / Bảng điều khiển (Dashboard) / Chuyên nghiệp (Corporate) / Công nghệ tối (Dark Tech)]
- **Chế độ hiển thị:** [Light Mode (Mặc định) / Dark Mode / Tự động theo hệ điều hành]

### 2. Bảng màu hệ thống (Color Tokens)
*Toàn bộ mã nguồn đọc các biến này, tuyệt đối không hardcode mã màu:*

#### a) Web CSS Tokens (Route A)
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
  --color-info: #0284c7;            /* Xanh dương nhạt: Thông tin chỉ dẫn */
}
```

#### b) Android Native Tokens (Route B — Jetpack Compose & XML)
```kotlin
// Jetpack Compose Colors (ui/theme/Color.kt)
val Primary = Color(0xFF2563EB)
val PrimaryHover = Color(0xFF1D4ED8)
val Background = Color(0xFFF8FAFC)
val Surface = Color(0xFFFFFFFF)
val Border = Color(0xFFE2E8F0)
val TextMain = Color(0xFF0F172A)
val TextMuted = Color(0xFF64748B)
val Accent = Color(0xFF10B981)
val Danger = Color(0xFFEF4444)
val Warning = Color(0xFFF59E0B)
val Info = Color(0xFF0284C7)
```

```xml
<!-- Android XML Colors (res/values/colors.xml) -->
<resources>
    <color name="color_primary">#2563EB</color>
    <color name="color_primary_hover">#1D4ED8</color>
    <color name="color_background">#F8FAFC</color>
    <color name="color_surface">#FFFFFF</color>
    <color name="color_border">#E2E8F0</color>
    <color name="color_text_main">#0F172A</color>
    <color name="color_text_muted">#64748B</color>
    <color name="color_accent">#10B981</color>
    <color name="color_danger">#EF4444</color>
    <color name="color_warning">#F59E0B</color>
    <color name="color_info">#0284C7</color>
</resources>
```

### 3. Phông chữ & Kích thước (Typography)

#### a) Web CSS
```css
:root {
  --font-main: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
  --font-size-sm: 14px;
  --font-size-base: 16px;
  --font-size-lg: 20px;
  --font-size-xl: 24px;
  --line-height-base: 1.5;
}
```

#### b) Android Native (Compose Typography)
```kotlin
// Compose Typography (ui/theme/Type.kt)
val Typography = Typography(
    bodyLarge = TextStyle(fontSize = 16.sp, lineHeight = 24.sp),
    titleLarge = TextStyle(fontSize = 20.sp, fontWeight = FontWeight.Bold),
    headlineMedium = TextStyle(fontSize = 24.sp, fontWeight = FontWeight.Bold)
)
```

### 4. Bo góc & Đổ bóng (Radius & Elevation)

#### a) Web CSS
```css
:root {
  --radius-sm: 6px;                 /* Bo góc nút bấm nhỏ, ô nhập liệu */
  --radius-md: 12px;                /* Bo góc thẻ card, bảng biểu */
  --radius-lg: 20px;                /* Bo góc modal, khung lớn */
  --shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);
  --shadow-card: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
  --shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1);
}
```

#### b) Android Native (Compose Shapes & XML Dimens)
```kotlin
// Compose Shapes (ui/theme/Shape.kt)
val Shapes = Shapes(
    small = RoundedCornerShape(6.dp),
    medium = RoundedCornerShape(12.dp),
    large = RoundedCornerShape(20.dp)
)
```

```xml
<!-- Android Dimens (res/values/dimens.xml) -->
<resources>
    <dimen name="radius_sm">6dp</dimen>
    <dimen name="radius_md">12dp</dimen>
    <dimen name="radius_lg">20dp</dimen>
</resources>
```

---

## TẦNG 2: QUY CHUẨN COMPONENTS DÙNG CHUNG (SHARED COMPONENT STYLES)
*Mọi nút bấm, khung nhập liệu, thẻ hiển thị trên các màn hình phải tuân theo cấu trúc mẫu:*

1. **Nút bấm chính (Primary Button)**:
   - Nền: `var(--color-primary)`, Chữ: trắng, Bo góc: `var(--radius-sm)`, Padding: 10px 20px.
   - Hover: `var(--color-primary-hover)`, chuyển động mượt `transition: 0.2s`.
2. **Nút phụ / Nút thứ cấp (Secondary Button)**:
   - Nền: trong suốt hoặc `var(--color-surface)`, Viền: 1px solid `var(--color-border)`, Chữ: `var(--color-text-main)`.
3. **Thẻ nội dung (Card Container)**:
   - Nền: `var(--color-surface)`, Bo góc: `var(--radius-md)`, Viền: 1px solid `var(--color-border)`, Đổ bóng: `var(--shadow-card)`, Padding: 24px.
4. **Ô nhập liệu (Input Field)**:
   - Nền: `var(--color-surface)`, Viền: 1px solid `var(--color-border)`, Bo góc: `var(--radius-sm)`, Padding: 10px 14px.
   - Focus: Viền đổi sang `var(--color-primary)` kèm vòng sáng nhẹ (ring).
5. **Thanh điều hướng / Đầu trang (Navbar / Header)**:
   - Nền: `var(--color-surface)`, Đường kẻ dưới: 1px solid `var(--color-border)`, Chiều cao: 64px, Hiển thị logo, tiêu đề và điều hướng chính.

---

## TẦNG 3: QUY CHUẨN 4 TRẠNG THÁI GIAO DIỆN (UI STATE PATTERNS)
*(Tham chiếu app-adr-ui: Giao diện không bao giờ được phép để màn hình trắng hoặc đơ khi tải dữ liệu)*

### 1. Trạng thái Đang tải (Loading State)
- **Quy chuẩn**: Hiển thị hiệu ứng khung xương nhấp nháy (Skeleton Loading) hoặc biểu tượng xoay (Spinner) ở vị trí thao tác.
- **Yêu cầu**: Nút bấm đang gửi dữ liệu phải bị vô hiệu hóa (`disabled`) kèm chữ "Đang xử lý..." để chống bấm nhiều lần.

### 2. Trạng thái Trống (Empty State)
- **Quy chuẩn**: Khi bảng biểu hoặc danh sách chưa có dữ liệu, tuyệt đối không để trống màn hình.
- **Yêu cầu bắt buộc 3 thành phần**:
  1. Biểu tượng minh họa trực quan (hộp rỗng / tài liệu trống).
  2. Dòng mô tả ngắn gọn: *"Chưa có dữ liệu nào ở đây."*
  3. Một nút bấm hành động chính (Call-To-Action) dẫn người dùng đến bước tạo mới ngay.

### 3. Trạng thái Thành công (Success Feedback)
- **Quy chuẩn**: Thông báo nổi (Toast Notification) hoặc biểu tượng dấu tích xanh kèm nhãn rõ ràng: *"Đã lưu thành công!"*.
- **Yêu cầu**: Tự động biến mất sau 3 giây hoặc người dùng có thể bấm nút tắt.

### 4. Trạng thái Báo lỗi & Khôi phục (Error Recovery State)
- **Quy chuẩn**: Banner cảnh báo màu đỏ (`var(--color-danger)`), giải thích nguyên nhân bằng ngôn ngữ người dùng dễ hiểu (tránh in mã lỗi kỹ thuật phức tạp).
- **Yêu cầu bắt buộc**: Phải có nút **"Thử lại" (Retry)** và **bảo toàn 100% dữ liệu đã nhập** trong các ô input để người dùng không phải gõ lại từ đầu.
