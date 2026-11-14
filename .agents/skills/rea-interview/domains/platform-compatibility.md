# HƯỚNG DẪN PHỎNG VẤN CHUYÊN BIỆT: TƯƠNG THÍCH NỀN TẢNG & MÀN HÌNH DI ĐỘNG (PLATFORM & MOBILE DISPLAY COMPATIBILITY)
> **Domain**: `PLATFORM_COMPATIBILITY`  
> **Áp dụng cho**: Bước 06 (`06_REA_INTERVIEW`) & Bước 07 (`07_SPEC_AND_DESIGN`) thuộc STAGE_03 · PRODUCT DEFINITION  
> **Quy chuẩn**: REA Adaptive Interview Framework · Mobile Screen Dimensions, Aspect Ratios & Responsive Layout Governance  

---

## 1. Mục Tiêu & Nguyên Tắc Phỏng Vấn Thích Ứng

Hướng dẫn này kích hoạt khi bài toán yêu cầu **đảm bảo ứng dụng chạy mượt mà, đúng chuẩn trên các phiên bản hệ điều hành đích (Android 14 API 34, Android 15 API 35), đa dạng thiết bị (smartphone, tablet, foldable), và đặc biệt là tương thích toàn diện với các tỷ lệ khung hình (Aspect Ratios) cùng bố cục thích ứng (Responsive Layout)**.

### Nguyên Tắc Bắt Buộc (Iron Rules):
1. **Kiểm Tra Bằng Chứng Trước Khi Hỏi (Evidence-First Inspection)**:
   * Agent tự động kiểm tra mã nguồn hoặc file APK đã giải nén: các thư mục tài nguyên (`res/layout/`, `res/layout-sw600dp/`, `res/layout-land/`), file cấu hình `AndroidManifest.xml` (các thuộc tính `android:screenOrientation`, `android:resizeableActivity`), và các file Compose/XML layout.
   * Tuyệt đối không hỏi người dùng những thông số kỹ thuật đã có bằng chứng rõ ràng trong ứng dụng.
2. **Không Ép Buộc Người Dùng Chọn Thông Số Kỹ Thuật (Friendly Non-Technical Defaults)**:
   * Người dùng thông thường không biết sự khác biệt giữa 18.5:9, 19.5:9 hay 20:9.
   * Nếu người dùng không nắm rõ, Agent tự động đề xuất chiến lược bố cục co giãn thích ứng (Responsive Fluid Strategy) bao phủ toàn bộ dải tỷ lệ phổ thông (16:9 đến 21:9) và ghi nhận thành `Assumption Record` với rủi ro `BENIGN`.
3. **Phân Biệt Rõ Ràng Độ Phân Giải Vật Lý & Kích Thước Logic**:
   * Phân biệt rõ Physical Resolution (pixels, ví dụ 1080×2400 px, mật độ 400 DPI) với Logical Viewport Dimensions (dp, ví dụ 360×800 dp, `dp = px / (dpi / 160)`).
   * Mọi quy chuẩn thiết kế và kiểm thử phải dựa trên đơn vị `dp` và `sp`, không dùng hardcoded `px`.
4. **Không Giả Định Khả Năng Tương Thích (Never Assume Compatibility)**:
   * Tuyệt đối không giả định việc ứng dụng chạy đúng trên 1 độ phân giải (ví dụ 1080×1920 16:9) thì sẽ tự động hiển thị đẹp trên màn hình dài (20:9) hoặc màn hình gập (4:3 / 8:7.1).
   * Phải lập Ma trận Tương thích Màn hình Di động (Mobile Display Compatibility Matrix) chính thức trong đặc tả đóng băng trước Gate 03.

---

## 2. Các Trụ Cột Điều Tra Màn Hình Di Động & Tương Thích Nền Tảng

### 2.1 Ma Trận Tỷ Lệ Khung Hình Màn Hình (Screen Aspect Ratios Matrix)
Agent phải điều tra và lập kế hoạch tương thích cho các dải tỷ lệ khung hình thực tế:
- **16:9 (1.78:1 — Dòng máy truyền thống & phổ thông)**:
  * Ví dụ: 720×1280, 1080×1920 (Logical viewport ~ 360×640 dp).
  * Rủi ro: Không gian chiều dọc hẹp; dễ bị che nút CTA nếu có bàn phím hoặc danh sách dài không cuộn được.
- **18:9 / 18.5:9 (2.0:1 — Chuẩn màn hình hiện đại cơ bản)**:
  * Ví dụ: 1080×2160, 1080×2220 (Logical viewport ~ 360×720 dp hoặc 411×822 dp).
- **19.5:9 (2.17:1 — Dòng flagship phổ biến nhất hiện nay)**:
  * Ví dụ: iPhone 13/14/15/16, Samsung Galaxy S21/S22/S23/S24, 1080×2340 hoặc 1170×2532 (Logical viewport ~ 390×844 dp, 393×852 dp).
  * Đặc điểm: Bắt buộc xử lý Dynamic Island hoặc Camera Notch khoét sâu.
- **20:9 (2.22:1 — Màn hình dài phổ biến dòng tầm trung/cao cấp)**:
  * Ví dụ: Xiaomi Redmi Note, Galaxy A-series, Pixel 7/8/9, 1080×2400 (Logical viewport ~ 360×800 dp hoặc 412×915 dp).
- **21:9 (2.33:1 — Màn hình siêu dài Cinematic / Màn hình phụ điện thoại gập)**:
  * Ví dụ: Sony Xperia 1/5/10, Galaxy Z Fold Cover screen, 1080×2520.
  * Rủi ro: Nội dung đơn lẻ bị kéo giãn quá dài nếu căn lề không hợp lý; khoảng trống thừa ở chân màn hình.
- **Tỷ Lệ Màn Hình Gập & Máy Tính Bảng (Foldables & Tablets)**:
  * Màn hình chính khi mở gập (Unfolded Inner): 8:7.1, 4:3, 1:1 (Ví dụ 1812×2176, ~ 674×841 dp).
  * Máy tính bảng: 16:10, 3:2, 4:3 (Ví dụ 1200×1920, 800×1280 dp).
  * Yêu cầu: Bố cục Two-Pane List-Detail, không để một danh sách đơn kéo dài toàn chiều ngang tablet.

### 2.2 Kích Thước Màn Hình & Cổng Hiển Thị (Dimensions & Viewports)
- **Độ phân giải vật lý (Physical resolution)**: Width × Height in pixels.
- **Mật độ điểm ảnh (Screen Density - DPI)**: mdpi (160), hdpi (240), xhdpi (320), xxhdpi (480), xxxhdpi (640).
- **Cổng hiển thị logic (Logical Viewport)**: Đo bằng `dp`.
  * **Cổng hiển thị tối thiểu hỗ trợ (Minimum Supported Viewport)**:
    - Chiều rộng tối thiểu: **320 dp** (Small devices như iPhone SE / Galaxy Mini).
    - Chiều cao tối thiểu: **568 dp** (Portrait) / **320 dp** (Landscape trừ insets hệ thống).
- **Vùng nội dung khả dụng (Available Content Area)**: Diện tích màn hình thực tế sau khi đã trừ đi thanh trạng thái (status bar), thanh điều hướng cử chỉ (navigation bar), và các phần khoét camera (cutouts).

### 2.3 Cấu Hình Hiển Thị & Vùng An Toàn (Display Configurations & Safe Areas)
- **Định hướng màn hình (Orientation)**:
  * Chế độ dọc (Portrait): Bố cục mặc định cho smartphone.
  * Chế độ xoay ngang (Landscape): Nội dung phải tự động chuyển đổi thành container cuộn dọc mượt mà; các dialog không được vượt quá chiều cao màn hình.
- **Thanh hệ thống & Edge-to-Edge**:
  * Chuẩn Android 15 bắt buộc kích hoạt `enableEdgeToEdge()`.
  * Nội dung vẽ tràn dưới thanh trạng thái và thanh điều hướng trong suốt.
  * Sử dụng `WindowInsetsCompat.Type.systemBars()` để đệm (padding) các nút bấm, thanh công cụ, không để chữ đè lên đồng hồ hoặc nút điều hướng cử chỉ.
- **Vùng khoét camera, tai thỏ & bo góc (Cutouts, Notches & Rounded Corners)**:
  * Xử lý `displayCutout`: Tránh đặt nút quay lại (Back button) hoặc tiêu đề sát mép camera lỗ đục.
  * Bo góc màn hình: Màn hình bo cong lớn yêu cầu padding tối thiểu 16dp từ 4 góc ngoài.
- **Thiết Bị Màn Hình Gập & Cửa Sổ Linh Hoạt (Foldables, Split-Screen & Resizable)**:
  * Hỗ trợ gập mở liên tục (Fold/Unfold posture): Ứng dụng tự động khôi phục trạng thái mà không khởi động lại Activity (`android:configChanges="screenSize|smallestScreenSize|screenLayout|orientation"`).
  * Chế độ nửa gập (Tabletop / Flex Mode): Đưa phần xem nội dung lên nửa trên, thanh điều khiển ở nửa dưới.
  * Chế độ đa cửa sổ (Split-screen / Freeform Multi-Window): Ứng dụng phải tự co giãn mượt mà khi kích thước cửa sổ bị thu nhỏ dưới 50% màn hình.

### 2.4 Hành Vi Giao Diện Thích Ứng (Responsive UI Behavior)
- **Co giãn linh hoạt thành phần (Component Resizing)**: Sử dụng tỷ lệ phần trăm hoặc ràng buộc mềm (`weight`, `fillMaxWidth()`), cấm hardcode chiều rộng pixel.
- **Tái cấu trúc bố cục (Layout Reflow)**: Chuyển từ cột đơn trên điện thoại sang lưới 2 cột trên màn hình rộng.
- **Bọc & Cắt Chữ (Text Wrapping & Truncation)**:
  * Khi người dùng tăng kích thước chữ hệ thống (Font Scaling up to 200%), chữ phải tự động xuống dòng (wrap).
  * Tiêu đề giới hạn dòng: Dùng `maxLines` kết hợp `TextOverflow.Ellipsis`. Cấm để chữ bị cắt ngang thân ký tự hoặc tràn đè lên icon bên cạnh.
- **Tỷ lệ hình ảnh (Image Scaling & Cropping)**: Sử dụng `ContentScale.Crop` hoặc `ContentScale.Fit` bảo toàn tỷ lệ gốc; cấm làm méo hình khi kéo giãn tỷ lệ màn hình.
- **Thích ứng điều hướng (Navigation Adaptation)**:
  * Màn hình hẹp / Chế độ dọc: Dùng Bottom Navigation Bar (3 - 5 mục).
  * Màn hình rộng / Xoay ngang: Tự động reflow sang Navigation Rail hoặc Navigation Drawer bên trái.
- **Hành vi cuộn (Scroll Behavior)**: Mọi màn hình có nguy cơ vượt quá chiều cao viewport bắt buộc được bọc trong container cuộn dọc (`verticalScroll`).
- **Định vị Dialog & Bottom Sheet**:
  * Trên màn hình rộng: Dialog giới hạn `maxWidth = 560dp`, căn giữa màn hình.
  * Bottom Sheet: Tự động điều chỉnh chiều cao tối đa 80% màn hình và phản hồi khi bàn phím mở.
- **Tương tác bàn phím ảo (Keyboard / IME Interactions)**:
  * Tích hợp `imePadding()`: Khi bàn phím xuất hiện, toàn bộ form tự động cuộn đẩy trường nhập liệu và nút CTA lên trên bàn phím, không làm mất khả năng thao tác.

---

## 3. Khung Câu Hỏi Quyết Định Tương Thích (Decision-Driven Question Catalog)

### Q-COMPAT-01: Phạm Vi Hỗ Trợ Thiết Bị & Màn Hình Lớn
- **Câu hỏi**: Ứng dụng này chủ yếu phục vụ người dùng điện thoại thông minh tiêu chuẩn, hay cần tối ưu hóa giao diện chia đôi cột (Two-Pane) cho máy tính bảng / màn hình gập?
- **Intent**: Quyết định có cần lập Responsive Spec theo Window Size Classes (`Expanded`) tại Bước 07 hay không.
- **Related Decision**: `DECISION-COMPAT-01: Form Factor Support Strategy`.
- **Expected Information**: Chỉ cần điện thoại dọc / Bắt buộc hỗ trợ cả Tablet và Foldable.
- **Applicability Conditions**: Ứng dụng có màn hình danh sách - chi tiết (List-Detail).
- **Skip Conditions**: Đã có thông tin trong hồ sơ mục tiêu hoặc ứng dụng là công cụ tiện ích nhỏ.

### Q-COMPAT-02: Ràng Buộc Phân Phối Lên Cửa Hàng Ứng Dụng (Store Distribution Requirements)
- **Câu hỏi**: Ứng dụng sẽ được phát hành chính thức lên Google Play Store (yêu cầu nghiêm ngặt về targetSdk 34+, 16 KB Page-Size, 64-bit binaries) hay chỉ cài đặt nội bộ (Sideload / APK direct)?
- **Intent**: Định hình rào chắn xác thực bản build tại Gate 04 và Gate 05.
- **Related Decision**: `DECISION-COMPAT-02: Distribution Channel & Compliance Target`.
- **Expected Information**: Google Play Store / Phân phối nội bộ APK.
- **Applicability Conditions**: Dự án phát triển mã nguồn native Android.
- **Skip Conditions**: Dự án Route A (Web App Zero-Install).

### Q-COMPAT-03: Tương Thích Tỷ Lệ Màn Hình Di Động & Bố Cục Thích Ứng (Aspect Ratio & Responsive Strategy)
- **Câu hỏi**: Về hiển thị trên các dòng điện thoại khác nhau, bạn muốn ứng dụng tối ưu hóa theo định hướng nào:
  * **Lựa chọn A (Khuyến nghị)**: Bố cục co giãn linh hoạt (Fluid Responsive), tự động tương thích hoàn hảo từ màn hình tiêu chuẩn (16:9, 18:9) đến màn hình dài hiện đại (19.5:9, 20:9, 21:9), bảo vệ vùng tai thỏ và bo góc.
  * **Lựa chọn B**: Khóa cứng khung hình theo một tỷ lệ cố định (Letterbox / Fixed Ratio, chấp nhận có dải đen trên màn hình dài).
  * **Lựa chọn C (Mở rộng)**: Hỗ trợ toàn diện cả điện thoại, màn hình xoay ngang, và giao diện 2 cột thích ứng cho máy tính bảng/màn hình gập.
- **Intent**: Chốt chiến lược responsive layout và ma trận hiển thị màn hình di động cho Bước 07 Spec Freeze.
- **Related Decision**: `DECISION-COMPAT-03: Mobile Display Compatibility Strategy`.
- **Expected Information**: Lựa chọn A / B / C hoặc phản hồi "anh chọn giúp giải pháp tốt nhất".
- **Applicability Conditions**: Mọi ứng dụng có giao diện người dùng trên thiết bị di động.
- **Skip Conditions**: Đã có layout responsive hoàn chỉnh trong mã nguồn gốc đã thẩm định.
- **Quy tắc khi người dùng không chuyên**: Nếu người dùng trả lời "chưa rõ" hoặc "làm sao cho chuẩn nhất", Agent tự động chọn **Lựa chọn A**, ghi nhận vào `Assumption Record` (Risk: `BENIGN`) và chuyển sang bước tiếp theo, không ép hỏi thông số aspect ratio.

---

## 4. Ma Trận Đóng Băng & Tiêu Chí Nghiệm Thu Màn Hình Di Động

Bản đặc tả tại Bước 07 bắt buộc phải có **Mobile Display Compatibility Matrix**:

| Device class | Aspect ratio | Viewport (dp) | Orientation | Support status | Verification |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Small Phone** | 16:9 | 320 × 568 to 360 × 640 | Portrait / Landscape | SUPPORTED (Baseline) | Automated Screenshot & Smoke Test |
| **Standard Smartphone** | 18:9 / 18.5:9 | 360 × 720 to 393 × 800 | Portrait / Landscape | SUPPORTED (Primary) | Device Runner / AVD & Visual Review |
| **Tall Smartphone** | 19.5:9 / 20:9 | 360 × 780 to 412 × 915 | Portrait / Landscape | SUPPORTED (Primary) | Device Runner / AVD & Cutout Check |
| **Ultra-Tall Smartphone** | 21:9 | 360 × 840 to 412 × 960 | Portrait / Landscape | SUPPORTED | Inset Padding & Scroll Flow Test |
| **Foldable (Outer / Folded)** | 21:9 to 23:9 | 320 × 800 to 360 × 880 | Portrait | SUPPORTED | Aspect Ratio & Text Wrap Test |
| **Foldable (Inner / Unfolded)** | 8:7.1 / 4:3 | 674 × 841 to 768 × 1024 | Portrait / Landscape | SUPPORTED (Adaptive) | Two-Pane / Dual-Column Layout Test |
| **Tablet** | 16:10 / 3:2 | 800 × 1280 to 1200 × 1920 | Landscape / Portrait | SUPPORTED (Expanded) | Window Size Class Expanded Test |

### Tiêu Chí Nghiệm Thu Bắt Buộc (Verifiable Acceptance Criteria):
1. **Khả Năng Tiếp Cận & Vị Trí Thành Phần Cốt Lõi**:
   * Mọi nút bấm hành động chính (CTA, Submit, Confirm), trường nhập liệu, và thanh điều hướng duy trì khả năng truy cập và vị trí chính xác trên tất cả các tỷ lệ từ 16:9 đến 21:9.
   * Không có thành phần nào bị đẩy ra ngoài mép màn hình mà không cuộn tới được.
2. **Bảo Vệ Vùng An Toàn & Insets**:
   * Giao diện Edge-to-Edge không bị thanh trạng thái, thanh điều hướng cử chỉ hoặc camera lỗ đục đè lên nội dung thao tác trên Android 14 và Android 15.
   * Vùng chạm cảm ứng duy trì tối thiểu 48×48dp trên mọi kích thước màn hình.
3. **Phản Hồi Bàn Phím Ảo (IME)**:
   * Khi mở bàn phím ảo, container tự động cuộn lên để trường nhập liệu và nút bấm chính luôn nằm trên bàn phím.
4. **Kiểm Thử Hồi Quy Thị Giác**:
   * Kiểm thử chụp ảnh tự động trên ít nhất 3 cấu hình: Màn hình nhỏ (320dp width), Màn hình dài (19.5:9 / 20:9), và Xoay ngang (Landscape), chứng minh không vỡ bố cục và không có chữ bị cắt xén bất thường.
