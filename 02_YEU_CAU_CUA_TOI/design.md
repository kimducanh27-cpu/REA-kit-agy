# HỢP ĐỒNG THIẾT KẾ GIAO DIỆN & DESIGN SYSTEM 3 TẦNG CỦA TÔI
*(Người dùng: Tùy chỉnh màu sắc, font chữ hoặc quy chuẩn giao diện tại đây. AI sẽ tự động đọc và áp dụng vào toàn bộ mã nguồn)*

---

## TẦNG 1: THIẾT KẾ CƠ SỞ & BẢNG MÀU (TOKENS)

### 1. Phong cách mong muốn
- **Tên phong cách:** Hiện đại & Tối giản (Modern Clean)
- **Chế độ hiển thị:** Light Mode (Sáng)

### 2. Bảng màu ứng dụng (CSS & Android Native Tokens)

#### a) Web CSS Tokens (Route A)
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
  --color-info: #0284c7;            /* Xanh dương nhạt: Chỉ dẫn */

  /* Đổ bóng & Nâng bề mặt (Elevation) */
  --shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);
  --shadow-card: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
  --shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1);
}
```

#### b) Android Native Tokens (Route B — Jetpack Compose & XML)
```kotlin
// Jetpack Compose Color Tokens (ui/theme/Color.kt)
val PrimaryColor = Color(0xFF2563EB)
val PrimaryHoverColor = Color(0xFF1D4ED8)
val BackgroundColor = Color(0xFFF8FAFC)
val SurfaceColor = Color(0xFFFFFFFF)
val BorderColor = Color(0xFFE2E8F0)
val TextMainColor = Color(0xFF0F172A)
val TextMutedColor = Color(0xFF64748B)
val AccentColor = Color(0xFF10B981)
val DangerColor = Color(0xFFEF4444)
val WarningColor = Color(0xFFF59E0B)
```

```xml
<!-- Android XML Color Tokens (res/values/colors.xml) -->
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
</resources>
```

### 3. Phông chữ, Bo góc & Kích thước (Web & Android Dimensions)

#### a) Web CSS
```css
:root {
  --font-main: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
  --radius-sm: 6px;
  --radius-md: 10px;
  --radius-lg: 16px;
}
```

#### b) Android Native (Compose Shapes & XML Dimens)
```kotlin
// Jetpack Compose Shapes (ui/theme/Shape.kt)
val Shapes = Shapes(
    small = RoundedCornerShape(6.dp),
    medium = RoundedCornerShape(10.dp),
    large = RoundedCornerShape(16.dp)
)
```

```xml
<!-- Android XML Dimens (res/values/dimens.xml) -->
<resources>
    <dimen name="radius_sm">6dp</dimen>
    <dimen name="radius_md">10dp</dimen>
    <dimen name="radius_lg">16dp</dimen>
</resources>
```

---

## TẦNG 2: THÀNH PHẦN GIAO DIỆN DÙNG CHUNG (COMPONENTS)
- **Nút bấm chính (Button)**: Bo góc 6px (`--radius-sm`), nền xanh `--color-primary`, chữ trắng đậm, hiệu ứng bóng nhẹ khi bấm (`--shadow-sm`), vùng cảm ứng tối thiểu đạt chuẩn Accessibility `min-height: 48px` / `min-width: 48px` (Compose: `Modifier.defaultMinSize(minHeight = 48.dp)`).
- **Thẻ hiển thị (Card)**: Bo góc 10px (`--radius-md`), nền trắng `--color-surface`, viền mảnh `--color-border`, đổ bóng `--shadow-card`, padding thoải mái 20px.
- **Ô nhập liệu (Input)**: Viền xám nhạt `--color-border`, đổi màu viền xanh `--color-primary` khi focus kèm ring phát sáng, bo góc 6px, chiều cao tối thiểu 48px cho vùng chạm.
- **Thanh menu đầu trang (Header)**: Nền trắng, cố định trên cùng, chiều cao 64px, viền dưới 1px solid `--color-border`, chứa tên ứng dụng và các nút điều hướng nhanh.

---

## TẦNG 3: QUY CHUẨN 4 TRẠNG THÁI GIAO DIỆN (UI STATES)
*(Tuyệt đối không để màn hình đơ hoặc trắng trang trong bất kỳ tình huống nào)*
1. **Đang tải (Loading)**: Hiện hiệu ứng khung xương xám nhấp nháy (skeleton) hoặc vòng xoay, nút bấm chuyển sang trạng thái mờ (disabled).
2. **Không có dữ liệu (Empty)**: Hiện biểu tượng thư mục rỗng kèm thông báo *"Chưa có dữ liệu nào"* và nút bấm to rõ *"Tạo mới ngay"*.
3. **Thành công (Success)**: Hiện thông báo xanh góc màn hình *"Đã lưu thành công"* và tự tắt sau 3 giây.
4. **Báo lỗi (Error)**: Khung đỏ nổi bật giải thích nguyên nhân rõ ràng, có nút *"Thử lại"* và giữ nguyên dữ liệu người dùng vừa nhập.
