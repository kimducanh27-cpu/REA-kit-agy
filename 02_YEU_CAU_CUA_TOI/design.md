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
  /* Mau thuong hieu & Nut chinh */
  --color-primary: #2563eb;         /* Xanh duong hien dai */
  --color-primary-hover: #1d4ed8;   /* Mau di chuot vao nut */
  
  /* Nen trang & Be mat khung */
  --color-background: #f8fafc;      /* Nen xam nhat diu mat */
  --color-surface: #ffffff;         /* Nen trang cho the va bang */
  --color-border: #e2e8f0;          /* Duong vien ngan cach */
  
  /* Mau chu */
  --color-text-main: #0f172a;       /* Chu den dam de doc */
  --color-text-muted: #64748b;      /* Chu phu xam mo */
  
  /* Mau trang thai */
  --color-accent: #10b981;          /* Xanh la: Thanh cong */
  --color-danger: #ef4444;          /* Do: Xoa, Loi */
  --color-warning: #f59e0b;         /* Vang: Canh bao */
  --color-info: #0284c7;            /* Xanh duong nhat: Chi dan */
  
  /* Kich thuoc & Bo goc */
  --radius-sm: 6px;
  --radius-md: 12px;
  --radius-lg: 20px;
  --touch-target-min: 48px;
  
  /* Do bong & Nang be mat (Elevation) */
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
val InfoColor = Color(0xFF0284C7)
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
    <color name="color_info">#0284C7</color>
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
    small = RoundedCornerShape(6dp),
    medium = RoundedCornerShape(12dp),
    large = RoundedCornerShape(20dp)
)
```

```xml
<!-- Android XML Dimens (res/values/dimens.xml) -->
<resources>
    <dimen name="radius_sm">6dp</dimen>
    <dimen name="radius_md">12dp</dimen>
    <dimen name="radius_lg">20dp</dimen>
    <dimen name="touch_target_min">48dp</dimen>
</resources>
```

---

## TẦNG 2: THÀNH PHẦN GIAO DIỆN DÙNG CHUNG (COMPONENTS)
- **Nút bấm chính (Button)**: Bo góc 6px (`--radius-sm`), nền xanh `--color-primary`, chữ trắng đậm, hiệu ứng bóng nhẹ khi bấm (`--shadow-sm`), vùng cảm ứng tối thiểu đạt chuẩn Accessibility `min-height: 48px` / `min-width: 48px` (Compose: `Modifier.defaultMinSize(minHeight = 48.dp)`).
- **Thẻ hiển thị (Card)**: Bo góc 10px (`--radius-md`), nền trắng `--color-surface`, viền mảnh `--color-border`, đổ bóng `--shadow-card`, padding thoải mái 20px.
- **Ô nhập liệu (Input)**: Viền xám nhạt `--color-border`, đổi màu viền xanh `--color-primary` khi focus kèm ring phát sáng, bo góc 6px, chiều cao tối thiểu 48px cho vùng chạm.
- **Thanh menu đầu trang (Header)**: Nền trắng, cố định trên cùng, chiều cao 64px, viền dưới 1px solid `--color-border`, chứa tên ứng dụng và các nút điều hướng nhanh.

---

## TẦNG 3: QUY CHUẨN 6 TRẠNG THÁI GIAO DIỆN (UI STATES)
*(Tuyệt đối không để màn hình đơ hoặc trắng trang trong bất kỳ tình huống nào)*
1. **Đang tải (Loading)**: Hiện hiệu ứng khung xương xám nhấp nháy (skeleton shimmer) hoặc vòng xoay (spinner) tại vị trí thao tác, nút bấm chuyển sang trạng thái vô hiệu (`disabled`) kèm chữ "Đang xử lý..." để chống bấm nhiều lần.
2. **Không có dữ liệu (Empty)**: Hiện biểu tượng minh họa trực quan kèm thông báo *"Chưa có dữ liệu nào ở đây"* và nút bấm hành động nổi bật (CTA) dẫn dắt người dùng tạo mới ngay.
3. **Thành công (Success)**: Thông báo nổi (Toast) hoặc huy hiệu tích xanh góc màn hình *"Đã lưu thành công!"* và tự động biến mất sau 3 giây.
4. **Báo lỗi & Khôi phục (Error Recovery)**: Khung đỏ nổi bật (`var(--color-danger)`) giải thích nguyên nhân bằng ngôn ngữ người dùng dễ hiểu, có nút *"Thử lại"* (Retry).
5. **Đang xử lý / Bản nháp (In-Progress / Draft)**: Tự động lưu tạm dữ liệu nhập dở (Auto-save) sau mỗi 500ms kèm chỉ báo nhỏ "Đã lưu nháp"; **bảo toàn 100% dữ liệu form theo `RULE-INIT-001`**, tuyệt đối không xóa trắng dữ liệu của người dùng khi gặp lỗi.
6. **Ngoại tuyến / Đang kết nối lại (Offline / Reconnecting)**: Hiển thị banner cảnh báo mạng màu vàng/xám trên đầu trang báo trạng thái mất kết nối, chuyển sang chế độ đọc cache cục bộ và tự động retry đồng bộ khi mạng được khôi phục.
