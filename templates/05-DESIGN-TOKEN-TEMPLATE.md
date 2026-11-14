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

### 5. Động lực học & Chuyển động (Motion Tokens)
*(Tham chiếu docs/UI_IMPLEMENTATION_MAP.md — Quy chuẩn thời lượng 150ms / 250ms / 400ms và đường cong gia tốc chuẩn)*

#### a) Web CSS Tokens (Route A)
```css
:root {
  /* Thời lượng chuyển động */
  --motion-duration-fast: 150ms;       /* Micro-interactions: switch, checkbox, tooltip */
  --motion-duration-base: 250ms;       /* Chuyển đổi thành phần: dropdown, sheet, dialog */
  --motion-duration-slow: 400ms;       /* Chuyển trang, cấu trúc layout lớn */

  /* Đường cong gia tốc (Easing curves) */
  --motion-easing-standard: cubic-bezier(0.2, 0, 0, 1);       /* Di chuyển trên màn hình */
  --motion-easing-emphasized: cubic-bezier(0.05, 0.7, 0.1, 1); /* Xuất hiện vào màn hình */
  --motion-easing-accelerate: cubic-bezier(0.3, 0, 0.8, 0.15); /* Rời khỏi màn hình */
}

/* Hỗ trợ chế độ giảm chuyển động (Reduced Motion) */
@media (prefers-reduced-motion: reduce) {
  :root {
    --motion-duration-fast: 0.01ms;
    --motion-duration-base: 0.01ms;
    --motion-duration-slow: 0.01ms;
  }
}
```

#### b) Android Native Tokens (Route B — Jetpack Compose & XML)
```kotlin
// Compose Motion Tokens (ui/theme/Motion.kt)
object MotionTokens {
    const val DurationFast = 150
    const val DurationBase = 250
    const val DurationSlow = 400

    val EasingStandard = CubicBezierEasing(0.2f, 0.0f, 0.0f, 1.0f)
    val EasingEmphasized = CubicBezierEasing(0.05f, 0.7f, 0.1f, 1.0f)
    val EasingAccelerate = CubicBezierEasing(0.3f, 0.0f, 0.8f, 0.15f)
}
```

```xml
<!-- Android XML Motion (res/values/motion.xml & integers.xml) -->
<resources>
    <integer name="motion_duration_fast">150</integer>
    <integer name="motion_duration_base">250</integer>
    <integer name="motion_duration_slow">400</integer>
</resources>
```

### 6. Biểu tượng & Icon Tokens (Icon Tokens)
*(Tham chiếu docs/UI_IMPLEMENTATION_MAP.md — Route A dùng Lucide Icons, Route B dùng Material Symbols; TUYỆT ĐỐI CẤM DÙNG EMOJI LÀM ICON)*

#### a) Web CSS & Sizing Tokens (Route A — Lucide Icons)
```css
:root {
  --icon-size-sm: 16px;             /* Inline icon cạnh text nhỏ, badge */
  --icon-size-base: 24px;           /* Nút chuẩn, toolbar, navigation item */
  --icon-size-lg: 32px;             /* Empty state illustration, banner */
  --icon-stroke-width: 2px;         /* Độ dày nét chuẩn của Lucide */
}
```
*Thư viện áp dụng*: `lucide-react` (Ví dụ: `<Search size={24} />`, `<ArrowLeft size={24} />`). Cấm dùng emoji.

#### b) Android Native Tokens (Route B — Jetpack Compose & XML)
```kotlin
// Compose Icon Dimens (ui/theme/Dimens.kt)
object IconTokens {
    val SizeSmall = 16.dp
    val SizeBase = 24.dp
    val SizeLarge = 32.dp
}
```

```xml
<!-- Android Dimens (res/values/dimens.xml) -->
<resources>
    <dimen name="icon_size_sm">16dp</dimen>
    <dimen name="icon_size_base">24dp</dimen>
    <dimen name="icon_size_lg">32dp</dimen>
</resources>
```
*Thư viện áp dụng*: `androidx.compose.material.icons:material-icons-extended` (Ví dụ: `Icons.Outlined.Search`, `Icons.AutoMirrored.Outlined.ArrowBack`) hoặc Vector Drawable XML (`res/drawable/ic_*.xml`). Cấm dùng emoji.

---

## TẦNG 2: QUY CHUẨN COMPONENTS DÙNG CHUNG (SHARED COMPONENT STYLES)
*Mọi nút bấm, khung nhập liệu, thẻ hiển thị trên các màn hình phải tuân theo cấu trúc mẫu:*

1. **Nút bấm chính (Primary Button)**:
   - Nền: `var(--color-primary)`, Chữ: trắng, Bo góc: `var(--radius-sm)`, Padding: 10px 20px.
   - Hover: `var(--color-primary-hover)`, chuyển động mượt `transition: background-color var(--motion-duration-fast) var(--motion-easing-standard)`.
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

## TẦNG 3: QUY CHUẨN 6 TRẠNG THÁI GIAO DIỆN (UI STATE PATTERNS)
*(Tham chiếu app-adr-ui & design-governance.md: Giao diện không bao giờ được phép để màn hình trắng hoặc đơ khi tải dữ liệu)*

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
- **Yêu cầu bắt buộc**: Phải có nút **"Thử lại" (Retry)**.

### 5. Trạng thái Đang xử lý / Bản nháp (In-Progress / Draft State)
- **Quy chuẩn**: Hiển thị chỉ báo lưu tạm thời gian thực ("Đang lưu nháp...", "Đã lưu nháp lúc HH:mm").
- **Yêu cầu bắt buộc**: **Bảo toàn 100% dữ liệu đã nhập** trong các ô input theo `RULE-INIT-001`, tự động lưu tạm sau 500ms vào LocalStorage hoặc SharedPreferences.

### 6. Trạng thái Ngoại tuyến / Đang kết nối lại (Offline / Reconnecting State)
- **Quy chuẩn**: Banner thông báo ngoại tuyến màu vàng (`var(--color-warning)`) hoặc xám, thông báo ứng dụng đang hoạt động ở chế độ ngoại tuyến.
- **Yêu cầu bắt buộc**: Chuyển các thao tác ghi dữ liệu vào hàng đợi cục bộ (Local Outbox Queue) và tự động kích hoạt đồng bộ khi có mạng trở lại.
