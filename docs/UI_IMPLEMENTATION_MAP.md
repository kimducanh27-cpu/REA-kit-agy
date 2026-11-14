# BẢN ĐỒ TRIỂN KHAI GIAO DIỆN & GIAO THỨC KHẢO CỔ MÃ NGUỒN UI
# (UI IMPLEMENTATION MAP & CODE ARCHAEOLOGY PROTOCOL)

> **Mã tài liệu**: `UI_IMPLEMENTATION_MAP`  
> **Phạm vi áp dụng**: Giao diện Web (Route A) và Android Native (Route B)  
> **Liên kết Stage**: STAGE 02 (Evidence Collection), STAGE 03 (Product Definition), STAGE 04 (Implementation & Verification)  
> **Quy chuẩn đối chiếu**: Anti-Slop Visual Governance · WCAG 2.1/2.2 AA · Material Design 3 · W3C Design Tokens Community Group  

---

## 1. TỔNG QUAN & MỤC TIÊU CỐT LÕI

Tài liệu này xác lập quy chuẩn kỹ thuật bắt buộc để chuyển đổi bằng chứng khảo sát giao diện (Reverse-Engineered Evidence) thành đặc tả hệ thống và mã nguồn thực thi. Tài liệu giải quyết 3 bài toán trọng tâm:

1. **Chuẩn hóa Animation & Motion**: Cung cấp danh mục tham chiếu cho chuyển động mượt mà (60/120 FPS), phân cấp thời lượng rõ ràng và hỗ trợ đầy đủ chế độ trợ năng (Reduced Motion).
2. **Quản trị Biểu tượng (Icon Governance)**: Thiết lập thư viện icon chuẩn cho từng nền tảng (Lucide cho Web, Material Symbols cho Android), nghiêm cấm triệt để việc dùng emoji làm icon.
3. **Giao thức khảo cổ giao diện (Code Archaeology Protocol)**: Quy trình bóc tách các hiệu ứng thị giác phức tạp (shadow, blur, transform, z-index), tái tạo lưới không gian (Spacing Grid, Window Size Classes, Safe-Area Insets, Touch Target 48dp), và phân tách rành mạch giữa bằng chứng chạy thực (Runtime Rendered Evidence) với giai đoạn đặc tả tĩnh (Static Specification Phase).

---

## 2. DANH MỤC THAM CHIẾU HOẠT HOẠ (ANIMATION REFERENCE CATALOG)

Hệ thống hỗ trợ 4 động cơ hoạt họa chuẩn tùy theo nền tảng và độ phức tạp:

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                   DANH MỤC THAM CHIẾU ĐỘNG CƠ HOẠT HỌA (ANIMATION)               │
├─────────────────────────┬─────────────────────────┬──────────────────────────────┤
│ ĐỘNG CƠ                 │ PHẠM VI SỬ DỤNG         │ ĐẶC TÍNH & TỐI ƯU HÓA        │
├─────────────────────────┼─────────────────────────┼──────────────────────────────┤
│ 1. CSS Keyframes        │ Web Route A (Micro-UI)  │ Tăng tốc phần cứng (GPU),     │
│                         │ Shimmer, Spin, Pulse    │ chỉ chạy transform & opacity │
├─────────────────────────┼─────────────────────────┼──────────────────────────────┤
│ 2. Lottie Runtime       │ Web & Android (Vector)  │ Đồ họa vector JSON phức tạp, │
│                         │ Splash, Success badge   │ dotLottie tối ưu dung lượng  │
├─────────────────────────┼─────────────────────────┼──────────────────────────────┤
│ 3. Web Animations API   │ Web Route A (Dynamic)   │ Điều khiển thời gian thực qua│
│    (WAAPI)              │ Gesture-driven, physics │ JS, cancelable, promise-ready│
├─────────────────────────┼─────────────────────────┼──────────────────────────────┤
│ 4. Jetpack Compose      │ Android Route B         │ Tích hợp sâu vào UI state,   │
│    Animation APIs       │ Transitions, State-anim │ spring physics, zero-jank    │
└─────────────────────────┴─────────────────────────┴──────────────────────────────┘
```

### 2.1 CSS Keyframes (Web Route A)
- **Mục đích**: Hoạt họa vi mô (micro-interactions), trạng thái loading skeleton shimmer, spinner quay, hover phản hồi nhẹ.
- **Nguyên tắc vàng tối ưu hóa GPU**:
  - Chỉ cho phép animate 2 thuộc tính: `transform` (translate, scale, rotate) và `opacity`.
  - **TUYỆT ĐỐI CẤM**: Animate các thuộc tính kích hoạt Layout Reflow (`width`, `height`, `top`, `left`, `margin`, `padding`) hoặc Repaint diện rộng (`background-color`, `border-width`).
  - Sử dụng `will-change: transform, opacity;` có kiểm soát (chỉ gắn trước khi chuyển động và gỡ bỏ ngay sau đó).

```css
/* Chuẩn Skeleton Shimmer */
@keyframes shimmer {
  0% { transform: translateX(-100%); }
  100% { transform: translateX(100%); }
}

.skeleton-shimmer {
  position: relative;
  overflow: hidden;
  background-color: var(--color-surface-variant);
}

.skeleton-shimmer::after {
  content: "";
  position: absolute;
  inset: 0;
  transform: translateX(-100%);
  background: linear-gradient(
    90deg,
    transparent 0%,
    rgba(255, 255, 255, 0.15) 50%,
    transparent 100%
  );
  animation: shimmer var(--motion-duration-slow) infinite var(--motion-easing-standard);
  will-change: transform;
}
```

### 2.2 Lottie Runtime (Web & Android)
- **Mục đích**: Minh họa sinh động, huy hiệu thành công (celebration badge), linh vật hướng dẫn, onboarding visual.
- **Thư viện tiêu chuẩn**:
  - Web: `lottie-web` hoặc `@dotlottie/player-component`.
  - Android: `com.airbnb.android:lottie-compose` (Jetpack Compose).
- **Quy tắc hiệu năng**:
  - Ưu tiên định dạng `.lottie` (dotLottie) nén dung lượng giảm 70% so với raw `.json`.
  - Tự động tạm dừng (`pause()`) khi phần tử cuộn ra ngoài màn hình (`IntersectionObserver` trên Web, `LifecycleResumeEffect` trên Android).
  - Không nhúng tệp JSON quá 150KB vào bundle ứng dụng; các hoạt họa lớn phải tải bất đồng bộ (lazy load/stream).

```kotlin
// Android Compose Lottie Spec
@Composable
fun SuccessAnimation(onFinished: () -> Unit) {
    val composition by rememberLottieComposition(LottieCompositionSpec.RawRes(R.raw.anim_success))
    val progress by animateLottieCompositionAsState(
        composition = composition,
        iterations = 1,
        speed = 1.0f
    )
    LottieAnimation(
        composition = composition,
        progress = { progress },
        modifier = Modifier.size(120.dp)
    )
}
```

### 2.3 Web Animations API - WAAPI (Web Route A)
- **Mục đích**: Hoạt họa có điều kiện phức tạp, tương tác vuốt chạm thời gian thực (gesture tracking), đồng bộ nhiều chuỗi timeline bằng code JavaScript/TypeScript.
- **Lợi thế**: Bỏ qua overhead của requestAnimationFrame/setInterval, chạy mượt trên compositor thread, cung cấp Promise `finished` phục vụ dọn dẹp state.

```javascript
// WAAPI: Menu Drawer Slide In
function animateDrawerOpen(element) {
  return element.animate(
    [
      { transform: 'translateX(-100%)', opacity: 0 },
      { transform: 'translateX(0)', opacity: 1 }
    ],
    {
      duration: 250, // --motion-duration-base
      easing: 'cubic-bezier(0.05, 0.7, 0.1, 1.0)', // Emphasized Decelerate
      fill: 'forwards'
    }
  ).finished;
}
```

### 2.4 Jetpack Compose Animation (Android Route B)
- **Cấu trúc phân tầng**:
  1. *Cấp cao (High-Level)*: `AnimatedVisibility` (xuất hiện/biến mất theo state), `AnimatedContent` (chuyển đổi giữa các nội dung khác nhau), `Crossfade`.
  2. *Cấp trung (Mid-Level)*: `animateFloatAsState`, `animateColorAsState`, `animateDpAsState` (tự động nội suy giá trị khi state thay đổi).
  3. *Cấp thấp (Low-Level)*: `Animatable`, `updateTransition`, `rememberInfiniteTransition` (điều khiển đa trạng thái đồng bộ).

```kotlin
// Compose AnimatedVisibility kết hợp Motion Specs
AnimatedVisibility(
    visible = isVisible,
    enter = fadeIn(animationSpec = tween(durationMillis = 250, easing = FastOutSlowInEasing)) +
            slideInVertically(
                animationSpec = tween(durationMillis = 250, easing = FastOutSlowInEasing),
                initialOffsetY = { fullHeight -> fullHeight / 4 }
            ),
    exit = fadeOut(animationSpec = tween(durationMillis = 150, easing = FastOutLinearInEasing))
) {
    SurfaceCardContent()
}
```

---

## 3. DANH MỤC THAM CHIẾU CHUYỂN ĐỘNG (MOTION CATALOG)

Hệ thống quy định nghiêm ngặt thang thời lượng và đường cong gia tốc nhằm đảm bảo cảm giác phản hồi nhanh, tự nhiên và tôn trọng trợ năng người dùng.

### 3.1 Thang đo Thời Lượng (Duration Scale)

| Token Tên | Giá Trị | Ngữ Cảnh Áp Dụng | Trải Nghiệm Mục Tiêu |
| :--- | :--- | :--- | :--- |
| `--motion-duration-fast` | **150ms** | Micro-interactions: Checkbox, Switch, Button press, Icon flip, Tooltip | Phản hồi xúc giác tức thì, không gây cảm giác trễ |
| `--motion-duration-base` | **250ms** | Thành phần giao diện: Dropdown mở, Dialog xuất hiện, Bottom sheet trượt lên, Tab chuyển đổi | Nhận diện rõ dịch chuyển mà không bắt người dùng chờ đợi |
| `--motion-duration-slow` | **400ms** | Chuyển cảnh lớn: Toàn trang (Screen Transition), Cấu trúc layout bung rộng (Expanded card to screen) | Dẫn dắt sự tập trung vào sự biến đổi không gian |

### 3.2 Đường Cong Gia Tốc (Easing Curves)

1. **Standard Easing** (`cubic-bezier(0.2, 0.0, 0, 1.0)` / Compose `FastOutSlowInEasing`):
   - Dùng cho các thành phần di chuyển bắt đầu và kết thúc đều nằm trên màn hình (ví dụ nút di chuyển vị trí, thẻ đổi kích thước).
2. **Emphasized Decelerate** (`cubic-bezier(0.05, 0.7, 0.1, 1.0)` / Compose `LinearOutSlowInEasing`):
   - Dùng cho các thành phần **bước vào màn hình** (Incoming: Modal popup, Notification banner, Bottom Sheet). Bắt đầu nhanh để thu hút chú ý rồi giảm tốc êm ái khi dừng lại.
3. **Emphasized Accelerate** (`cubic-bezier(0.3, 0.0, 0.8, 0.15)` / Compose `FastOutLinearInEasing`):
   - Dùng cho các thành phần **rời khỏi màn hình** (Outgoing: Đóng dialog, swipe dismiss). Bắt đầu chậm rồi lao nhanh ra ngoài mép.

### 3.3 Chuẩn Trợ Năng Giảm Chuyển Động (Reduced Motion Governance)
> ⚠️ **BẮT BUỘC THEO WCAG 2.1 THÀNH CÔNG 2.3.3**: Người dùng nhạy cảm với tiền đình (vestibular disorders) phải có khả năng tắt các chuyển động không cần thiết.

- **Web Route A**:
  ```css
  @media (prefers-reduced-motion: reduce) {
    *, ::before, ::after {
      animation-duration: 0.01ms !important;
      animation-iteration-count: 1 !important;
      transition-duration: 0.01ms !important;
      scroll-behavior: auto !important;
    }
  }
  ```
- **Android Route B**:
  - Tôn trọng thiết lập `Settings.Global.ANIMATOR_DURATION_SCALE = 0`.
  - Trong Jetpack Compose, khi hệ thống tắt hoạt họa, các hàm `spring()` và `tween()` tự động chuyển sang nhảy trạng thái tức thì (snap to target value).

---

## 4. QUY TẮC CHỌN THƯ VIỆN BIỂU TƯỢNG (ICON LIBRARY SELECTION)

Để đảm bảo tính nhất quán thị giác và độ tin cậy trong hiển thị, hệ thống phân định rõ thư viện bắt buộc cho từng nền tảng:

```
┌────────────────────────────────────────────────────────────────────────┐
│                   PHÂN ĐỊNH THƯ VIỆN BIỂU TƯỢNG HỆ THỐNG               │
├────────────────────────────┬───────────────────────────────────────────┤
│ WEB ROUTE A                │ Lucide Icons (lucide-react / SVG)         │
│                            │ ViewBox 24x24, Stroke 2px, Round cap/join │
├────────────────────────────┼───────────────────────────────────────────┤
│ ANDROID ROUTE B            │ Google Material Symbols / Material Icons  │
│                            │ Outlined / Rounded, Vector Drawables      │
├────────────────────────────┴───────────────────────────────────────────┤
│ ❌ NGUYÊN TẮC CẤM TUYỆT ĐỐI (ANTI-SLOP RULE):                          │
│ KHÔNG DÙNG EMOJI LÀM BIỂU TƯỢNG UI (NO EMOJIS AS FUNCTIONAL ICONS)      │
└────────────────────────────────────────────────────────────────────────┘
```

### 4.1 Quy Chuẩn Web Route A: Lucide Icons
- Thư viện: `lucide-react` (React) hoặc SVG nguyên bản.
- Quy chuẩn hình học:
  - ViewBox mặc định: `0 0 24 24`.
  - Độ dày nét (`stroke-width`): Mặc định `2px` (hoặc `1.5px` trên giao diện mật độ cao / desktop compact).
  - Đầu nét (`stroke-linecap`): `round`.
  - Khớp nối (`stroke-linejoin`): `round`.
- Quy chuẩn trợ năng (Accessibility):
  - Khi icon đứng cùng nhãn chữ: Đặt `aria-hidden="true"`.
  - Khi icon là nút bấm độc lập: Bắt buộc gắn `aria-label="Tên hành động"` hoặc thẻ `<title>`.

### 4.2 Quy Chuẩn Android Route B: Google Material Symbols
- Thư viện: `androidx.compose.material.icons:material-icons-extended` hoặc Vector Drawable XML (`res/drawable/ic_*.xml`).
- Phong cách ưu tiên: `Outlined` hoặc `Rounded` (tạo cảm giác hiện đại, thanh thoát).
- Kích thước chuẩn: `24dp` (với viewport `24x24dp`).
- Hỗ trợ đổi chiều tự động: Với các icon điều hướng (Mũi tên lui/tiến), bắt buộc sử dụng `autoMirrored = true` hoặc `Icons.AutoMirrored` để hỗ trợ hiển thị chuẩn cho ngôn ngữ RTL.

### 4.3 Rào Chắn Nghiêm Cấm: Tuyệt Đối Không Dùng Emoji Làm Icon UI
- **Hành vi bị cấm**: Sử dụng các ký tự Emoji Unicode như 🔍, 🏠, ⚙️, ❌, ⚠️, 🚀, 💬, 🗑️ làm biểu tượng trên nút bấm, menu, thanh điều hướng hoặc bảng trạng thái.
- **Lý do kỹ thuật & trải nghiệm**:
  1. *Thiếu tính nhất quán giữa các OS*: Emoji hiển thị trên iOS (Apple Color Emoji), Android (Noto Color Emoji), Samsung (Samsung One), và Windows (Segoe UI Emoji) có hình dáng, màu sắc và cảm xúc hoàn toàn khác nhau.
  2. *Không tuân thủ Design Tokens*: Emoji không thể đổi màu theo biến CSS `color` hoặc Jetpack Compose `tint`. Chúng phá vỡ bảng màu hệ thống và chế độ Dark Mode.
  3. *Lệch baseline và phá vỡ font alignment*: Ký tự emoji có kích thước font-metrics khác biệt so với font chữ nội dung, dẫn đến việc căn chỉnh dọc (vertical alignment) bị méo mó.
  4. *Rào cản trợ năng*: Trình đọc màn hình (TalkBack/VoiceOver) sẽ đọc to toàn bộ mô tả văn bản của emoji (ví dụ: "cờ lê và búa đang bắt chéo"), gây phiền toái lớn cho người khiếm thị.

---

## 5. ÁNH XẠ MOTION TOKENS & ICON TOKENS LIÊN NỀN TẢNG

Hệ thống liên kết các khái niệm thiết kế thành mã nguồn đồng bộ trên cả hai nền tảng Web và Android:

### 5.1 Bảng Ánh Xạ Motion Tokens

| Semantic Token | Web CSS (`:root`) | Android Compose (`MotionTokens.kt`) | Android XML (`dimens/integers.xml`) |
| :--- | :--- | :--- | :--- |
| `motion-duration-fast` | `150ms` | `const val DurationFast = 150` | `<integer name="motion_duration_fast">150</integer>` |
| `motion-duration-base` | `250ms` | `const val DurationBase = 250` | `<integer name="motion_duration_base">250</integer>` |
| `motion-duration-slow` | `400ms` | `const val DurationSlow = 400` | `<integer name="motion_duration_slow">400</integer>` |
| `motion-easing-standard` | `cubic-bezier(0.2, 0, 0, 1)` | `CubicBezierEasing(0.2f, 0f, 0f, 1f)` | `<pathInterpolator ... pathData="..."/>` |
| `motion-easing-emphasized` | `cubic-bezier(0.05, 0.7, 0.1, 1)` | `CubicBezierEasing(0.05f, 0.7f, 0.1f, 1f)` | `<pathInterpolator ... pathData="..."/>` |
| `motion-easing-accelerate` | `cubic-bezier(0.3, 0, 0.8, 0.15)` | `CubicBezierEasing(0.3f, 0f, 0.8f, 0.15f)` | `<pathInterpolator ... pathData="..."/>` |

### 5.2 Bảng Ánh Xạ Icon Tokens & Kích Thước

| Token Kích Thước | Web CSS | Android Compose | Ngữ Cảnh |
| :--- | :--- | :--- | :--- |
| `--icon-size-sm` | `16px` | `16.dp` | Inline icon cạnh chữ nhỏ, badge, tag |
| `--icon-size-base` | `24px` | `24.dp` | Thanh công cụ, nút chuẩn, menu, danh sách |
| `--icon-size-lg` | `32px` | `32.dp` | Thẻ lớn, màn hình Empty State, Header |

### 5.3 Bảng Ánh Xạ Semantic Icon Giữa Lucide và Material Symbols

| Ngữ Nghĩa Thao Tác | Web Route A (Lucide) | Android Route B (Material Symbols) |
| :--- | :--- | :--- |
| `action-search` | `<Search size={24} />` | `Icons.Outlined.Search` |
| `action-add` | `<Plus size={24} />` | `Icons.Outlined.Add` |
| `action-delete` | `<Trash2 size={24} />` | `Icons.Outlined.Delete` |
| `action-edit` | `<Pencil size={24} />` | `Icons.Outlined.Edit` |
| `action-refresh` | `<RotateCw size={24} />` | `Icons.Outlined.Refresh` |
| `action-close` | `<X size={24} />` | `Icons.Outlined.Close` |
| `action-settings` | `<Settings size={24} />` | `Icons.Outlined.Settings` |
| `navigation-back` | `<ArrowLeft size={24} />` | `Icons.AutoMirrored.Outlined.ArrowBack` |
| `navigation-forward` | `<ArrowRight size={24} />` | `Icons.AutoMirrored.Outlined.ArrowForward` |
| `navigation-chevron-down` | `<ChevronDown size={24} />` | `Icons.Outlined.KeyboardArrowDown` |
| `status-success` | `<CheckCircle2 size={24} />` | `Icons.Outlined.CheckCircle` |
| `status-warning` | `<AlertTriangle size={24} />` | `Icons.Outlined.Warning` |
| `status-error` | `<AlertCircle size={24} />` | `Icons.Outlined.Error` |
| `status-info` | `<Info size={24} />` | `Icons.Outlined.Info` |

---

## 6. GIAO THỨC KHẢO CỔ GIAO DIỆN: DANH MỤC HIỆU ỨNG THỊ GIÁC
## (CODE ARCHAEOLOGY PROTOCOL: VISUAL EFFECTS INVENTORY)

Khi phân tích dịch ngược mã nguồn cũ (APK decompilation, Smali, layout XML, minified Web bundle, CSS stylesheet), Agent phải thực hiện kiểm kê và chuẩn hóa 5 nhóm hiệu ứng thị giác:

```
┌────────────────────────────────────────────────────────────────────────┐
│                   5 TRỤ CỘT KIỂM KÊ HIỆU ỨNG THỊ GIÁC (VISUAL INVENTORY)│
├────────────────────┬───────────────────────────────────────────────────┤
│ 1. Box-shadow      │ Tách biệt Ambient/Spot shadow, blur, spread, alpha│
├────────────────────┼───────────────────────────────────────────────────┤
│ 2. Blur & Glass    │ Backdrop-filter trên Web, RenderEffect Android 12+│
├────────────────────┼───────────────────────────────────────────────────┤
│ 3. Transform       │ Ma trận dịch chuyển, xoay, co giãn, transform-org │
├────────────────────┼───────────────────────────────────────────────────┤
│ 4. Stacking & Z    │ Phân tầng hiển thị, clipChildren, zIndex isolation│
├────────────────────┼───────────────────────────────────────────────────┤
│ 5. Border & Ring   │ Viền đa lớp, outline offset, focus indicator      │
└────────────────────┴───────────────────────────────────────────────────┘
```

### 6.1 Box-Shadow & Elevation (Đổ Bóng & Cao Độ)
- **Phương pháp khảo cổ**:
  - Web: Bóc tách chuỗi CSS `box-shadow` thành 4 tham số: $X_{offset}, Y_{offset}, R_{blur}, S_{spread}$ và màu $RGBA$. Hệ thống hiện đại thường kết hợp 2 lớp đổ bóng: một lớp bóng tán xạ gần (ambient) và một lớp bóng định hướng xa (spot/key light).
  - Android: Bóc tách thuộc tính `android:elevation`, `android:ambientShadowColor`, `android:spotShadowColor`. Trong Compose, quy đổi sang `Modifier.shadow(elevation, shape, ambientColor, spotColor)`.
- **Bảng quy đổi chuẩn hóa**:
  - Elevation 2dp: Card phẳng, viền nhẹ.
  - Elevation 4dp: Card nổi bật, hover state.
  - Elevation 8dp: Floating Action Button (FAB), Dropdown Menu.
  - Elevation 16dp: Modal Dialog, Bottom Sheet.

### 6.2 Blur & Backdrop-Filter (Hiệu Ứng Làm Mờ Mặt Kính - Glassmorphism)
- **Phương pháp khảo cổ**:
  - Web: Phát hiện `backdrop-filter: blur(Npx)` và `-webkit-backdrop-filter`.
  - Android Native:
    - *Android 12+ (API 31+)*: Hỗ trợ phần cứng qua `Modifier.blur(N.dp)` hoặc `RenderEffect.createBlurEffect(radiusX, radiusY, Shader.TileMode.CLAMP)`.
    - *Android API < 31 (Fallback bắt buộc)*: Android cấp thấp không thể blur runtime hiệu quả mà không tốn pin/gây tụt FPS. **Quy tắc thích ứng**: Tự động chuyển đổi lớp kính mờ thành nền bán trong suốt đơn sắc: `var(--color-surface)` pha $90\%$ alpha kèm viền phân cách `1px solid var(--color-border)`.

### 6.3 Transform & Transformation Matrix (Biến Đổi Hình Học)
- **Phương pháp khảo cổ**:
  - Truy vết các hàm CSS: `translateX/Y/Z`, `scale`, `rotate`, `skew`, hoặc ma trận `matrix() / matrix3d()`.
  - Truy vết mã Android: `android:scaleX`, `android:rotation`, `View.animate().translationY()`.
  - Khi tái cấu trúc sang Jetpack Compose, đưa toàn bộ biến đổi vào `Modifier.graphicsLayer { ... }` để tránh recomposition toàn bộ cây giao diện con.

### 6.4 Stacking Context & Z-Index (Ngữ Cảnh Xếp Chồng & Cắt Lớp)
- **Vấn đề thường gặp khi dịch ngược**: Các thành phần bị cắt ngang mép (clipping) do container cha có `overflow: hidden` hoặc `clipChildren="true"`.
- **Quy tắc giải quyết**:
  - Web: Sử dụng thuộc tính `isolation: isolate` để tạo ngữ cảnh xếp chồng độc lập, quản lý z-index theo thang biến số hệ thống: `--z-dropdown: 1000; --z-sticky: 1020; --z-fixed: 1030; --z-modal-backdrop: 1040; --z-modal: 1050; --z-toast: 1080;`.
  - Android XML: Thiết lập `android:clipChildren="false"` và `android:clipToPadding="false"` tại các ViewGroup cha để bóng và hiệu ứng bay không bị xén.
  - Android Compose: Điều khiển thứ tự hiển thị thông qua cấu trúc lồng nhau trong `Box` hoặc áp dụng `Modifier.zIndex(n)`.

---

## 7. QUY CHUẨN TÁI CẤU TRÚC BỐ CỤC & KHOẢNG CÁCH (LAYOUT & SPACING RULES)

Giao diện tái lập phải vận hành hoàn hảo trên mọi kích thước màn hình mà không để xảy ra hiện tượng tràn chữ, lệch viền hoặc khó bấm.

### 7.1 Lưới Khoảng Cách 4dp/8dp (Spacing Grid)
- Toàn bộ khoảng cách (`margin`, `padding`, `gap`) phải là bội số của `4dp/4px` hoặc `8dp/8px`:
  - `space-1`: 4dp (khoảng cách vi mô giữa icon và text cùng dòng).
  - `space-2`: 8dp (padding nút nhỏ, khoảng cách giữa các phần tử liên quan chặt chẽ).
  - `space-3`: 12dp (padding thẻ vừa).
  - `space-4`: 16dp (lề tiêu chuẩn màn hình di động, padding thẻ chính).
  - `space-6`: 24dp (khoảng cách giữa các khối section).
  - `space-8`: 32dp (khoảng cách giữa các nhóm chức năng lớn).
  - `space-12`: 48dp (khoảng đệm header, đáy trang).
- **CẤM TUYỆT ĐỐI**: Các khoảng cách tùy tiện không nằm trong thang như `7px`, `13px`, `19px`, `27px`.

### 7.2 Lớp Kích Thước Màn Hình (Window Size Classes)
Hệ thống tuân thủ 3 cấp độ kích thước màn hình theo chuẩn Android / Web Responsive:

| Phân Loại | Chiều Rộng Màn Hình | Thiết Bị Tiêu Biểu | Cấu Trúc Bố Cục Bắt Buộc |
| :--- | :--- | :--- | :--- |
| **Compact** | `< 600dp` | Điện thoại di động (chân dung) | 1 cột đơn, Bottom Navigation Bar, Full-width cards, danh sách cuộn dọc |
| **Medium** | `600dp – 839dp` | Tablet nhỏ, Màn hình gập mở rộng | Navigation Rail, Bố cục 2 cột linh hoạt (Master-Detail danh sách/chi tiết) |
| **Expanded** | `≥ 840dp` | Tablet lớn, Màn hình máy tính | Navigation Drawer cố định bên trái, Bố cục đa cột (3 cột hoặc Dashboard) |

### 7.3 Vùng Đệm An Toàn (Safe-Area Insets & Edge-to-Edge)
- **Web Route A**:
  - Thẻ viewport: `<meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">`.
  - CSS Inset Variables:
    ```css
    padding-top: max(16px, env(safe-area-inset-top));
    padding-bottom: max(16px, env(safe-area-inset-bottom));
    padding-left: max(16px, env(safe-area-inset-left));
    padding-right: max(16px, env(safe-area-inset-right));
    ```
- **Android Route B**:
  - Bật Edge-to-Edge trong Activity: `enableEdgeToEdge()`.
  - Trong Compose: Sử dụng `Modifier.safeDrawingPadding()`, `Modifier.statusBarsPadding()`, `Modifier.navigationBarsPadding()`.
  - Bàn phím ảo: Bắt buộc gắn `Modifier.imePadding()` cho khung nhập liệu và nút bấm hành động để không bị bàn phím che khuất.

### 7.4 Vùng Chạm Cảm Ứng Tối Thiểu 48dp (Minimum Touch Target 48dp)
> ⚠️ **QUY TẮC BẮT BUỘC THEO WCAG 2.5.5 & GOOGLE ACCESSIBILITY**: Mọi phần tử có thể tương tác (Interactive Element) phải có kích thước vùng bấm tối thiểu **48x48dp**.

- **Quy tắc bóc tách**: Kích thước thị giác (Visual Size) của icon có thể là `24x24dp`, nhưng khung chứa cảm ứng bao quanh (Touch Bound) bắt buộc phải đạt `48x48dp`.
- **Triển khai kỹ thuật**:
  - Web: `min-width: 48px; min-height: 48px; display: inline-flex; align-items: center; justify-content: center;`
  - Android Compose: `Modifier.minimumInteractiveComponentSize()` hoặc gắn `Modifier.sizeIn(minWidth = 48.dp, minHeight = 48.dp)`.
- **Khoảng cách ly**: Các nút bấm cạnh nhau phải duy trì khoảng cách tối thiểu `8dp` để tránh chạm nhầm.

---

## 8. GIAO THỨC KIỂM CHỨNG THỊ GIÁC (VISUAL VERIFICATION PROTOCOL)

Hệ thống phân biệt rạch ròi giữa việc "xây dựng bản đặc tả" và "kiểm chứng giao diện thực tế" nhằm loại bỏ việc tự nhận định chủ quan.

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│              PHÂN BIỆT RẠCH RÒI 2 GIAI ĐOẠN KIỂM CHỨNG GIAO DIỆN                │
├───────────────────────────────────────┬─────────────────────────────────────────┤
│ GIAI ĐOẠN ĐẶC TẢ TĨNH (STAGE 03)      │ BẰNG CHỨNG CHẠY THỰC (STAGE 02 & 04)    │
│ (Static Specification Phase)          │ (Runtime Rendered Evidence)             │
├───────────────────────────────────────┼─────────────────────────────────────────┤
│ - Phân tích cú pháp AST, CSS, layout  │ - Ảnh chụp màn hình thật từ thiết bị    │
│ - Trích xuất Design Tokens trên giấy  │ - UIAutomator hierarchy node bounds dump│
│ - Bản hợp đồng đặc tả Markdown        │ - DOM Computed Style & Layout Box Model │
│ - Gắn nhãn: [SPECIFIED] / [INFERRED]  │ - Gắn nhãn: [OBSERVED]                  │
│ - TUYỆT ĐỐI CẤM KHẲNG ĐỊNH:           │ - TIÊU CHUẨN THẨM ĐỊNH:                 │
│   "Giao diện đã hiển thị hoàn hảo"    │   So sánh ảnh chụp Pixel-diff & bounds  │
└───────────────────────────────────────┴─────────────────────────────────────────┘
```

### 8.1 Giai Đoạn Đặc Tả Tĩnh (Static Specification Phase - Stage 03)
- Chỉ thao tác trên các bản hợp đồng: `02_YEU_CAU_CUA_TOI/design.md`, `01_SCREEN_COMPOSITION.md`, `02_RESPONSIVE_SPEC.md`, `03_STATE_COMPOSITION.md`, `04_COPY_DECK.md`.
- Mọi nhận định về kích thước, màu sắc trích xuất từ file nguồn hoặc file dịch ngược phải gắn nhãn trạng thái chính xác:
  - `[SPECIFIED]`: Thông số được quy định trong tài liệu thiết kế hoặc người dùng chỉ định.
  - `[INFERRED]`: Thông số suy luận từ mã nguồn dịch ngược (cần kiểm chứng lại ở bước chạy thực).
- **Ranh giới nghiêm ngặt**: Ở giai đoạn này, Agent chưa được phép sinh mã thực thi và không được khẳng định rằng giao diện đã chạy ổn định.

### 8.2 Giai Đoạn Bằng Chứng Chạy Thực (Runtime Rendered Evidence - Stage 02 & Stage 04)
- Chỉ những dữ liệu thu được từ môi trường chạy thực tế mới được gắn nhãn `[OBSERVED]`:
  1. *Ảnh chụp màn hình thực tế (Actual Screenshots)*: Chụp trực tiếp từ emulator/thiết bị qua `adb exec-out screencap -p` hoặc Puppeteer/Playwright headless browser.
  2. *Bản trích xuất cấu trúc cây giao diện (Hierarchy Dump)*: Lấy qua `uiautomator dump` (Android) hoặc `getComputedStyle()` (Web) ghi nhận chính xác tọa độ pixel: `[left,top][right,bottom]`.
  3. *Kiểm tra vùng bấm thực tế*: Tính toán $(right - left) \ge 48$ và $(bottom - top) \ge 48$.
  4. *Kiểm tra tỷ lệ tương phản chữ (Contrast Ratio)*: Đo lường bằng thuật toán WCAG giữa màu chữ và màu nền thực tế (đạt tối thiểu $4.5:1$ cho nội dung thông thường, $3.0:1$ cho chữ lớn).
  5. *Kiểm thử giảm chuyển động*: Kích hoạt toggle Reduced Motion và xác nhận trên thiết bị rằng không có hiệu ứng rung lắc hay chuyển trang gây chóng mặt.

---

## 9. DANH MỤC THẨM ĐỊNH TRƯỚC KHI BÀN GIAO (PRE-RELEASE CHECKLIST)

Trước khi ký duyệt hoàn tất mã nguồn giao diện tại Gate 04, Agent bắt buộc phải đối soát danh mục 8 điểm:

- [ ] **1. Design Tokens**: Toàn bộ mã nguồn sử dụng biến Semantic Tokens; không còn mã màu hardcoded hex/rgb trong component.
- [ ] **2. Motion Governance**: Sử dụng đúng thang 150ms / 250ms / 400ms và đường cong gia tốc chuẩn; hỗ trợ tắt hoạt họa với `prefers-reduced-motion` / `ANIMATOR_DURATION_SCALE`.
- [ ] **3. Icon Integrity**: Sử dụng Lucide (Web) hoặc Material Symbols (Android); **100% không chứa emoji làm icon UI**.
- [ ] **4. 4 Trạng Thái Cốt Lõi**: Mỗi màn hình/khung danh sách đều có đủ Loading (Skeleton), Empty (CTA), Success (Toast), Error (Retry + Form preservation).
- [ ] **5. Mobile Ergonomics**: Vùng chạm tương tác đạt tối thiểu `48x48dp`, khoảng cách các nút tối thiểu `8dp`.
- [ ] **6. Insets & Responsive**: Bọc container chống tràn `verticalScroll`, hỗ trợ bàn phím `imePadding`, hỗ trợ thanh điều hướng hệ thống `safeDrawingPadding`.
- [ ] **7. Copy Deck Thực Tế**: 100% nội dung hiển thị tiếng Việt tự nhiên, không tồn tại `Lorem Ipsum` hoặc văn bản mẫu vô nghĩa.
- [ ] **8. Bằng Chứng Xác Thực**: Có ảnh chụp màn hình chạy thực hoặc kết quả kiểm tra layout bounds chứng minh đạt yêu cầu.
