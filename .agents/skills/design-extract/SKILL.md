---
name: design-extract
description: Trích xuất Design Tokens tĩnh & thị giác từ ứng dụng gốc (APK Android, Web SPA hoặc ảnh baseline). Áp dụng chiến lược Static-First (res/values/colors.xml, themes.xml, dimens.xml hoặc CSS/DOM getComputedStyle) và Visual Fallback (trích xuất bảng màu từ ảnh baseline tại 03_KET_QUA_KIEM_TRA/baseline/ khi bị mã rối obfuscated/Flutter/Unity) để sinh hợp đồng tokens 3 tầng W3C DTCG tokens.json và design.md.
---

# KỸ NĂNG: TRÍCH XUẤT DESIGN TOKENS TĨNH & THỊ GIÁC (DESIGN-EXTRACT)

Kỹ năng chuyên biệt phục vụ bóc tách ngôn ngữ thiết kế nguyên bản của ứng dụng gốc, chuyển đổi thành **Hệ thống Design Tokens 3 tầng chuẩn W3C DTCG (Design Tokens Community Group)**.

---

## 1. NGUYÊN TẮC CỐT LÕI: STATIC-FIRST, VISUAL FALLBACK

```
+----------------------------------------------------------------------------------------------------+
| NHÁNH CHÍNH: STATIC-FIRST EXTRACTION                                                               |
| Phân tích tài nguyên tĩnh (XML, Themes, CSS) -> Độ chính xác 100%, giữ nguyên tên biến ngữ nghĩa   |
+----------------------------------------------------------------------------------------------------+
                                                  │
                                                  ▼ (Khi obfuscated / Flutter / Unity / thiếu XML)
+----------------------------------------------------------------------------------------------------+
| NHÁNH DỰ PHÒNG: VISUAL FALLBACK EXTRACTION                                                         |
| Trích xuất bảng màu & đo đạc từ ảnh chụp baseline tại 03_KET_QUA_KIEM_TRA/baseline/                |
+----------------------------------------------------------------------------------------------------+
                                                  │
                                                  ▼
+----------------------------------------------------------------------------------------------------+
| HỢP ĐỒNG ĐẦU RA CHUẨN HÓA W3C DTCG 3 TẦNG                                                          |
| 02_YEU_CAU_CUA_TOI/tokens.json -> Biên dịch ra tokens.css, Color.kt, Shape.kt, colors.xml         |
+----------------------------------------------------------------------------------------------------+
```

---

## 2. QUY TRÌNH STATIC-FIRST (ƯU TIÊN PHÂN TÍCH TÀI NGUYÊN TĨNH)

### 2.1 Đối với Ứng dụng Android APK
Khi giải mã APK bằng Apktool / JADX, Agent quét theo thứ tự ưu tiên:

1. **Bảng màu cơ sở (`res/values/colors.xml`)**:
   - Trích xuất toàn bộ các thẻ `<color name="...">#HEX</color>`.
   - Phân loại màu:
     * Nhóm thương hiệu (Primary, PrimaryVariant, Accent, Secondary).
     * Nhóm bề mặt (Background, Surface, WindowBackground, CardBackground).
     * Nhóm chữ (TextPrimary, TextSecondary, TextMuted, TextDisabled).
     * Nhóm phản hồi trạng thái (Success, Danger/Error, Warning, Info).
2. **Chủ đề & Thuộc tính ngữ nghĩa (`res/values/themes.xml` hoặc `styles.xml`)**:
   - Trích xuất cấu hình Material Design 3 / Material 2:
     * `colorPrimary`, `colorOnPrimary`, `colorSurface`, `colorOnSurface`.
     * Thuộc tính thanh trạng thái (`android:statusBarColor`, `android:windowLightStatusBar`).
     * Thuộc tính thanh điều hướng (`android:navigationBarColor`, `android:windowLightNavigationBar`).
3. **Kích thước, Khoảng cách & Bo góc (`res/values/dimens.xml`)**:
   - Khoảng cách (Spacing scale): tìm các bội số của 4dp/8dp (4dp, 8dp, 12dp, 16dp, 24dp, 32dp).
   - Bo góc (Corner Radii): tìm `corner_radius`, `radius_sm`, `radius_md`, `radius_lg`.
   - Kích thước chạm (Touch Targets): ghi nhận chiều cao nút, ô nhập liệu; cảnh báo nếu nhỏ hơn `48dp`.
4. **Kiểu chữ & Typography (`res/values/styles.xml` hoặc `res/font/`)**:
   - Xác định font family hệ thống (`sans-serif`, `sans-serif-medium`) hoặc font nhúng (`.ttf`, `.otf`).
   - Kích thước chữ (sp) và line-height tương ứng cho Headline, Title, Body, Caption.

### 2.2 Đối với Web SPA / Electron
1. **Biến CSS Root (`:root`)**:
   - Quét tìm tất cả các biến dạng `--color-*`, `--radius-*`, `--font-*`, `--spacing-*`.
2. **DOM Computed Styles (`window.getComputedStyle`)**:
   - Trích xuất giá trị thực tế của các phần tử đại diện:
     * Nút chính: `backgroundColor`, `color`, `borderRadius`, `padding`, `boxShadow`.
     * Thẻ Card: `backgroundColor`, `border`, `borderRadius`, `boxShadow`.
     * Trường Input: `border`, `borderRadius`, `height`, `focus outline`.
     * Thân trang: `backgroundColor`, `fontFamily`, `fontSize`, `lineHeight`.

---

## 3. QUY TRÌNH VISUAL FALLBACK (DỰ PHÒNG THỊ GIÁC TỪ BASELINE)

Khi ứng dụng đích bị làm rối mã (ProGuard/R8 obfuscation làm mất liên kết tài nguyên), hoặc được xây dựng bằng Flutter (`libflutter.so`) / Unity (`libil2cpp.so`) khiến tài nguyên tĩnh không còn ở định dạng XML truyền thống:

### 3.1 Bóc Tách Bảng Màu Trực Quan Từ Ảnh Chụp Baseline
1. Định vị các ảnh chụp baseline đã thu thập tại:
   👉 `03_KET_QUA_KIEM_TRA/baseline/` (ví dụ `screen_01.png`, `screen_02.png`...).
2. Phân vùng lấy mẫu màu (Region-Based Color Sampling):
   - **Màu thương hiệu (Primary)**: Lấy mẫu tại thanh Header/App Bar, nút hành động chính (Floating Action Button hoặc Nút Submit dưới chân màn hình).
   - **Màu nền (Background)**: Lấy mẫu tại vùng đệm rỗng giữa các khối nội dung.
   - **Màu bề mặt (Surface)**: Lấy mẫu tại vùng nền của thẻ Card, ô danh sách hoặc hộp thoại Modal.
   - **Màu chữ (Text Primary / Muted)**: Lấy mẫu tại các điểm ảnh của tiêu đề đậm và dòng chú thích phụ.
   - **Màu trạng thái (Status Colors)**: Lấy mẫu từ các thông báo lỗi, huy hiệu trạng thái (Status Badges), hoặc icon cảnh báo.
3. Đo lường tỷ lệ tương phản tiếp cận WCAG AA:
   - Sử dụng công thức tương phản tương đối:
     $$CR = \frac{L_1 + 0.05}{L_2 + 0.05}$$
   - Đảm bảo tỷ lệ chữ / nền đạt tối thiểu **4.5:1** cho văn bản thường và **3.0:1** cho văn bản lớn (>= 18pt / 24px) hoặc nút bấm.

### 3.2 Ước Lượng Hình Học & Khoảng Cách
1. Đo pixel từ ảnh chụp màn hình độ phân giải gốc:
   - Bo góc (Corner Radius): 0px (vuông), 4px–6px (nhẹ), 10px–12px (trung bình), 16px–24px (lớn), hoặc bo tròn hoàn toàn (pill 9999px).
   - Chiều cao tương tác: Nút bấm và ô nhập liệu phải được chuẩn hóa về tối thiểu **48px / 48dp** (theo `design-governance.md`).

---

## 4. XUẤT HỢP ĐỒNG DESIGN TOKENS CHUẨN W3C DTCG

Toàn bộ thông số trích xuất được (dù qua Static-First hay Visual Fallback) phải được hợp nhất vào:
👉 `02_YEU_CAU_CUA_TOI/tokens.json`

Cấu trúc chuẩn 3 tầng W3C DTCG:
```json
{
  "global": {
    "color": {
      "blue-600": { "$value": "#2563eb", "$type": "color" },
      "blue-700": { "$value": "#1d4ed8", "$type": "color" },
      "slate-50": { "$value": "#f8fafc", "$type": "color" },
      "white": { "$value": "#ffffff", "$type": "color" },
      "slate-200": { "$value": "#e2e8f0", "$type": "color" },
      "slate-900": { "$value": "#0f172a", "$type": "color" },
      "slate-500": { "$value": "#64748b", "$type": "color" },
      "emerald-500": { "$value": "#10b981", "$type": "color" },
      "red-500": { "$value": "#ef4444", "$type": "color" },
      "amber-500": { "$value": "#f59e0b", "$type": "color" },
      "sky-600": { "$value": "#0284c7", "$type": "color" }
    },
    "dimension": {
      "radius-sm": { "$value": "6px", "$type": "dimension" },
      "radius-md": { "$value": "12px", "$type": "dimension" },
      "radius-lg": { "$value": "20px", "$type": "dimension" },
      "target-min": { "$value": "48px", "$type": "dimension" }
    }
  },
  "semantic": {
    "color": {
      "primary": { "$value": "{global.color.blue-600}", "$type": "color" },
      "primary-hover": { "$value": "{global.color.blue-700}", "$type": "color" },
      "background": { "$value": "{global.color.slate-50}", "$type": "color" },
      "surface": { "$value": "{global.color.white}", "$type": "color" },
      "border": { "$value": "{global.color.slate-200}", "$type": "color" },
      "text-main": { "$value": "{global.color.slate-900}", "$type": "color" },
      "text-muted": { "$value": "{global.color.slate-500}", "$type": "color" },
      "accent": { "$value": "{global.color.emerald-500}", "$type": "color" },
      "danger": { "$value": "{global.color.red-500}", "$type": "color" },
      "warning": { "$value": "{global.color.amber-500}", "$type": "color" },
      "info": { "$value": "{global.color.sky-600}", "$type": "color" }
    }
  },
  "component": {
    "button": {
      "primary": {
        "background": { "$value": "{semantic.color.primary}", "$type": "color" },
        "color": { "$value": "#ffffff", "$type": "color" },
        "min-height": { "$value": "{global.dimension.target-min}", "$type": "dimension" },
        "radius": { "$value": "{global.dimension.radius-sm}", "$type": "dimension" }
      }
    },
    "card": {
      "background": { "$value": "{semantic.color.surface}", "$type": "color" },
      "border": { "$value": "{semantic.color.border}", "$type": "color" },
      "radius": { "$value": "{global.dimension.radius-md}", "$type": "dimension" }
    }
  }
}
```

Sau khi tạo hoặc cập nhật `tokens.json`:
1. Chạy công cụ biên dịch tự động:
   `powershell -NoProfile -ExecutionPolicy Bypass -File .\.agents\scripts\compile_tokens.ps1`
2. Script sẽ tự động đồng bộ mã nguồn sang `tokens.css`, `Color.kt`, `Type.kt`, `Shape.kt`, `colors.xml`, `dimens.xml`, đồng thời làm mới phần xem trước mã trong `02_YEU_CAU_CUA_TOI/design.md`.
