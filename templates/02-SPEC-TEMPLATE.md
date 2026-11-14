# ĐẶC TẢ YÊU CẦU PHÁT TRIỂN ỨNG DỤNG (FROZEN PRODUCT & ENGINEERING SPECIFICATION)
> **Dự án**: [Tên dự án / Ứng dụng]  
> **Mã ca làm việc (Case ID)**: [CASE-ID từ active_case.json]  
> **Thời gian đóng băng**: YYYY-MM-DD HH:mm  
> **Trạng thái Cổng**: ĐÃ ĐÓNG BĂNG (FROZEN SPEC — CỔNG 03)  
> **Quy chuẩn**: REA Adaptive Interview Architecture & Anti-Slop Governance · v1.1  

---

## 1. Mục Tiêu Tổng Thể & Định Tuyến Triển Khai (Executive Goals & Strategy)

- **Mục tiêu sản phẩm cốt lõi (Core Product Goals)**:
  * [Mục tiêu 1: Giá trị nghiệp vụ mang lại cho người dùng]
  * [Mục tiêu 2: Vấn đề cụ thể cần giải quyết triệt để]
- **Nhóm người dùng mục tiêu (User Personas & Target Audience)**:
  * *Nhóm chính*: [Đối tượng người dùng thường xuyên, bối cảnh sử dụng]
  * *Nhóm phụ*: [Quản trị viên, kiểm toán viên, người dùng vãng lai]
- **Chiến lược phát triển mã nguồn (`development_strategy`)**:
  * `[ ] STRATEGY_1_EXTEND`: Mở rộng trực tiếp trên codebase hiện có
  * `[ ] STRATEGY_2_FEATURE_BRANCH`: Phát triển tính năng trên nhánh độc lập
  * `[ ] STRATEGY_3_COMPATIBLE_CLEANROOM`: Tái triển khai tương thích phòng sạch
  * `[ ] STRATEGY_4_FULL_REWRITE`: Viết lại toàn diện với kiến trúc mới
- **Nền tảng bàn giao (`delivery_platform`)**:
  * `[ ] ROUTE_A_WEB_ZERO_INSTALL`: Ứng dụng Web SPA không cần cài đặt
  * `[ ] ROUTE_B_ANDROID_NATIVE`: Dự án mã nguồn Android Native (Kotlin/Compose)
  * `[ ] ROUTE_C_PATCH_HYBRID`: Bản vá APK nhị phân kết hợp
- **Lý do lựa chọn định tuyến**: [Giải trình cơ sở kỹ thuật, thời gian và chi phí bảo trì]

---

## 2. Đặc Tả Yêu Cầu Chức Năng (Functional Requirements)

### 2.1 Danh Mục Tính Năng Cốt Lõi (Core Feature Inventory)
| Mã Tính Năng | Tên Tính Năng | Mô Tả Nghiệp Vụ | Nguồn Gốc | Mức Độ Ưu Tiên |
| :--- | :--- | :--- | :--- | :--- |
| `FEAT-01` | [Ví dụ: Đăng nhập & Xác thực] | Xác thực sinh trắc học hoặc mã PIN cục bộ | Giữ nguyên từ app gốc | `MUST_HAVE` |
| `FEAT-02` | [Ví dụ: Quản lý Danh mục] | Thêm, sửa, xóa, tìm kiếm danh mục dữ liệu | Tối ưu hóa luồng thao tác | `MUST_HAVE` |
| `FEAT-03` | [Ví dụ: Xuất Báo Cáo Excel] | Lọc giao dịch và xuất file `.xlsx` | Tính năng mới bổ sung | `SHOULD_HAVE` |

### 2.2 Quy Chuẩn Xử Lý Luồng Nghiệp Vụ & Quy Tắc Dữ Liệu (Business Rules)
- **Quy tắc 1**: [Ví dụ: Dữ liệu nhập vào form luôn được tự động lưu tạm (Auto-save) sau mỗi 500ms].
- **Quy tắc 2 (Bảo Toàn Form Lỗi - `RULE-INIT-001`)**: Khi người dùng nhấn gửi nhưng gặp lỗi mạng hoặc lỗi xác thực máy chủ, toàn bộ thông tin đã nhập trên form phải được bảo toàn 100%, tuyệt đối không xóa trắng dữ liệu của người dùng.
- **Quy tắc 3**: [Ví dụ: Giới hạn tìm kiếm tối đa 100 kết quả trên một trang, hỗ trợ phân trang vô tận].

---

## 3. Đặc Tả Phi Chức Năng & Ngân Sách Hiệu Năng (Non-Functional Requirements & Performance Budgets)

| Tiêu Chí Kỹ Thuật | Chỉ Số Mục Tiêu (Target Metric) | Ngưỡng Tối Đa (Hard Limit) | Phương Pháp Đo Kiểm |
| :--- | :--- | :--- | :--- |
| **Thời gian khởi động lạnh (Cold Start)** | < 1.0 giây (Mid-tier device) | <= 1.2 giây | Android Vitals / Traceview |
| **Thời gian khởi động ấm (Warm Start)** | < 400 mili-giây | <= 600 mili-giây | Android Vitals |
| **Tỷ lệ khung hình (Frame Rate / Jank)** | 60 FPS (99% khung hình mượt) | Jank Rate < 2.0% | Macrobenchmark / Profile GPU |
| **Mức tiêu thụ RAM đỉnh (Peak Memory)** | < 80 MB (Chế độ thường) | <= 150 MB (Xử lý nặng) | Android Studio Memory Profiler |
| **Mức tiêu thụ Pin (Battery Impact)** | < 1.5% pin / giờ sử dụng | Không giữ WakeLock ngầm | Battery Historian |
| **Dung lượng gói cài đặt (APK Size)** | < 15 MB (Universal APK) | <= 25 MB | APK Analyzer / R8 Minification |

---

## 4. Ma Trận Tương Thích & Môi Trường Nền Tảng (Platform & Compatibility Matrix)

### 4.1 Môi trường Android Mục Tiêu:
- `minSdkVersion`: 26 (Android 8.0 Oreo)
- `targetSdkVersion`: 34 hoặc 35 (Android 14 / Android 15)
- `compileSdkVersion`: 35
- **Chuẩn Căn Chỉnh Trang Bộ Nhớ 16 KB (Android 15 Compliance)**:
  * Toàn bộ thư viện native `.so` biên dịch với NDK r28 (`-Wl,-z,max-page-size=16384`).
  * Gói APK đóng gói với `zipalign -P 16 -f -v 4`.

### 4.2 Ma Trận Tương Thích Màn Hình Di Động (Mobile Display Compatibility Matrix):

> **Mô hình trạng thái dựa trên bằng chứng (Evidence-Based Status Model)**:
> - `NOT_ASSESSED`: Thiết bị/tỷ lệ chưa được đánh giá theo mục tiêu hoặc kho thiết bị đích.
> - `IN_SCOPE`: Nằm trong phạm vi hỗ trợ theo mục tiêu dự án, đang chờ hoàn tất triển khai và kiểm thử.
> - `NOT_VERIFIED`: Đã phát triển giao diện nhưng chưa có kết quả kiểm thử tự động/thị giác đạt yêu cầu.
> - `SUPPORTED`: Đã kiểm chứng thực tế và có bằng chứng đạt chuẩn (ảnh chụp màn hình AVD, layout dump, test pass).
> - `UNSUPPORTED`: Đã đánh giá và xác nhận không hỗ trợ do giới hạn phần cứng/kiến trúc.
> - `OUT_OF_SCOPE`: Nằm ngoài phạm vi dự án một cách minh bạch (thuộc danh mục Non-Goals).
> *CẤM tuyên bố `SUPPORTED` khi chưa có bằng chứng kiểm thử hồi quy thị giác hoặc kiểm thử thiết bị thực tế.*

| Device class | Aspect ratio | Viewport (dp) | Orientation | Support status | Verification |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Small Phone** (Legacy/Compact) | 16:9 | 320 × 568 to 360 × 640 | Portrait / Landscape | IN_SCOPE (Baseline Target) | Automated Screenshot & Smoke Test (320dp) |
| **Standard Smartphone** | 18:9 (2:1) / 18.5:9 | 360 × 720 to 393 × 800 | Portrait / Landscape | IN_SCOPE (Primary Target) | Device Runner / AVD & Visual Review |
| **Tall Smartphone** (Modern Mainstream) | 19.5:9 / 20:9 | 360 × 780 to 412 × 915 | Portrait / Landscape | IN_SCOPE (Primary Target) | Device Runner / AVD & Cutout Check |
| **Ultra-Tall Smartphone** (Cinematic) | 21:9 | 360 × 840 to 412 × 960 | Portrait / Landscape | IN_SCOPE (Pending Verification) | Inset Padding & Scroll Flow Test |
| **Foldable (Outer / Folded)** | 21:9 to 23:9 | 320 × 800 to 360 × 880 | Portrait | IN_SCOPE (Pending Verification) | Aspect Ratio & Text Wrap Test |
| **Foldable (Inner / Unfolded)** | 8:7.1 / 4:3 | 674 × 841 to 768 × 1024 | Portrait / Landscape | NOT_ASSESSED (Optional / Adaptive) | Two-Pane / Dual-Column Layout Test |
| **Tablet** (Large Screen) | 16:10 / 3:2 | 800 × 1280 to 1200 × 1920 | Landscape / Portrait | OUT_OF_SCOPE (Default Non-Goal) | Window Size Class Expanded Test |

### 4.3 Quy Chuẩn Bố Cục Thích Ứng & Ranh Giới Kỹ Thuật (Responsive Layout Rules):
- **Cổng Hiển Thị Tối Thiểu (Minimum Supported Viewport)**:
  * Chiều rộng tối thiểu: **320 dp** (Small phone portrait).
  * Chiều cao tối thiểu: **568 dp** (Small phone portrait) / **320 dp** (Phone landscape with system bars).
  * 100% nội dung phải tiếp cận được, tuyệt đối không bị tràn ngoài mép màn hình không cuộn được.
- **Điểm Ngắt Thích Ứng (Responsive Breakpoints — Window Size Classes)**:
  * `Compact`: Width < 600 dp (Đơn cột, Bottom Navigation Bar, danh sách dọc tràn viền).
  * `Medium`: Width 600 - 840 dp (Bố cục linh hoạt, Navigation Rail, dialog giới hạn maxWidth 560dp).
  * `Expanded`: Width > 840 dp (Đa cột Two-Pane List-Detail, Navigation Rail/Drawer cố định).
- **Xử Lý Vùng An Toàn & Insets (Safe-Area & Edge-to-Edge Handling)**:
  * Áp dụng `enableEdgeToEdge()` chuẩn Android 15.
  * Phân biệt rõ ràng độ phân giải vật lý (Physical Pixels) và kích thước cổng hiển thị logic (Logical Viewport in dp).
  * Xử lý Insets toàn diện qua `WindowInsetsCompat` / Compose `Modifier.windowInsetsPadding()`:
    - Status bar & Navigation bar insets: Bảo vệ các thành phần điều hướng và nút thao tác chính.
    - Camera cutout / Notch / Camera holes: Không đặt chữ, logo hoặc nút bấm đè lên vùng khoét camera.
    - Bo góc màn hình (Rounded corners): Padding tối thiểu 16dp từ mép vật lý trên màn hình bo cong.
    - Bàn phím ảo (IME Insets): Form tự động cuộn lên khi bàn phím mở (`imePadding()`), không che nút CTA.
- **Yêu Cầu Tràn Bố Cục & Cuộn (Layout Overflow Requirements)**:
  * 100% màn hình form và nội dung chi tiết phải nằm trong container cuộn được theo chiều dọc (`Modifier.verticalScroll()` hoặc `NestedScrollView`).
  * Tuyệt đối cấm cuộn ngang không chủ đích (Unintended horizontal scrolling) trên màn hình điện thoại.
  * Khi xoay ngang (Landscape), nội dung phải reflow thành cuộn dọc thông suốt, không bị kẹt chiều cao cố định.
- **Quy Chuẩn Cắt & Xuống Dòng Văn Bản (Text Wrapping & Clipping Requirements)**:
  * Tương thích với tính năng phóng to chữ hệ thống (Font Scaling) từ 100% đến 200% (sử dụng đơn vị `sp`).
  * Tiêu đề và nhãn trong không gian giới hạn: Sử dụng `maxLines` kết hợp `TextOverflow.Ellipsis`.
  * Tuyệt đối không để chữ bị cắt cụt ngang (clipping) hoặc chồng chéo lên thành phần giao diện khác.
  * Vùng chạm cảm ứng (Touch Target): Luôn đảm bảo tối thiểu **48 × 48 dp** bất kể tỷ lệ co giãn giao diện.
- **Kiểm Thử Hồi Quy Thị Giác Dựa Trên Ảnh Chụp (Screenshot-Based Visual Regression)**:
  * Chụp ảnh tự động trên ma trận kích thước: Small Phone (320x568 dp), Tall Phone (412x915 dp, 20:9), và Tablet (800x1280 dp).
  * Kiểm tra xoay màn hình (Portrait ➔ Landscape) đảm bảo không vỡ bố cục, không tràn chữ, không che nút bấm.

---

## 5. Vòng Đời Dữ Liệu, An Ninh & Quyền Riêng Tư (Data Lifecycle, Security & Privacy)

- **Phân Loại Dữ Liệu**:
  * *Dữ liệu cá nhân (PII)*: Họ tên, email, số điện thoại -> Mã hóa lưu trữ cục bộ.
  * *Dữ liệu phiên*: Token truy cập -> Lưu trữ trong Android KeyStore / Encrypted DataStore.
- **Lưu Trữ An Toàn Tại Chỗ (Storage at Rest)**:
  * Tuyệt đối không dùng `EncryptedSharedPreferences` (đã deprecated).
  * Sử dụng **Jetpack DataStore** kết hợp Google Tink (`Aead`) hoặc trực tiếp Android KeyStore Cipher.
- **Bảo Vệ Kênh Truyền Thông (Transmission Security)**:
  * 100% kết nối mạng sử dụng giao thức TLS 1.3 (cưỡng chế qua OkHttp `ConnectionSpec.MODERN_TLS`).
  * Cấm hoàn toàn lưu lượng văn bản rõ (`cleartextTrafficPermitted="false"` trong `network_security_config.xml`).
- **Phát Hiện Can Thiệp Hệ Thống (Device Integrity)**:
  * Tích hợp Google Play Integrity API (Device + App Integrity verdict) với kiểm chứng token ở máy chủ theo chuẩn OWASP MASVS-RESILIENCE v2.0.
  * Không chỉ dựa vào thư viện RootBeer cục bộ.
- **Thu Hồi & Xóa Bỏ Dữ Liệu**:
  * Cung cấp nút "Xóa toàn bộ dữ liệu ứng dụng" thực thi xóa sạch database và giải phóng khóa KeyStore.

---

## 6. Hợp Đồng Giao Diện Chống UI Slop Đã Khóa (Frozen Anti-Slop UI/UX Contract)

Toàn bộ các tài liệu thiết kế sau đã được thẩm định độc lập và đóng băng đính kèm đặc tả này:
1. **Chế độ thiết kế áp dụng**: `[ ] DESIGN_REUSE_EXACT` | `[ ] DESIGN_STYLE_SPECIFIED` | `[ ] DESIGN_STRUCTURAL_EXPLORATION`
2. **Hồ sơ Art Direction**: Đã chốt theo `templates/12-ART-DIRECTION-TEMPLATE.md` (Product Personality, Visual Thesis, Layout Philosophy, Typography, Spacing, Signature Element, Forbidden Patterns).
3. **Bố cục màn hình đã duyệt**: `03_KET_QUA_KIEM_TRA/01_SCREEN_COMPOSITION.md` (Phê duyệt qua lệnh `APPROVE SCREEN COMPOSITION`).
4. **Quy chuẩn Responsive & Insets**: `03_KET_QUA_KIEM_TRA/02_RESPONSIVE_SPEC.md`.
5. **4 Trạng thái giao diện bắt buộc**: `03_KET_QUA_KIEM_TRA/03_STATE_COMPOSITION.md` (Loading Skeleton, Empty State CTA, Success Feedback, Error Recovery bảo toàn dữ liệu form).
6. **Hợp đồng Copy Deck thực tế**: `03_KET_QUA_KIEM_TRA/04_COPY_DECK.md` (CẤM 100% Lorem Ipsum và placeholder slop).
7. **Hợp đồng Design Tokens 3 tầng**: `02_YEU_CAU_CUA_TOI/design.md` (Primitive -> Semantic -> Platform Native).

---

## 7. Phân Hạng Ưu Tiên MoSCoW & Ranh Giới Phạm Vi (Prioritization & Scope Boundaries)

### 7.1 Ma Trận Phân Kỳ Tính Năng:
- **MUST-HAVE (Milestone 1-3 — Bắt buộc phải có trong bản giao đầu tiên)**:
  * [Tính năng bắt buộc 1]
  * [Tính năng bắt buộc 2]
- **SHOULD-HAVE (Milestone 4-5 — Rất nên có, có thể triển khai sau MVP)**:
  * [Tính năng quan trọng 1]
- **COULD-HAVE (Milestone 6 — Tiện ích bổ sung nếu còn ngân sách)**:
  * [Tiện ích mở rộng 1]
- **WON'T-HAVE / EXPLICIT NON-GOALS (Rõ ràng KHÔNG làm trong đợt này)**:
  * *Non-Goal 1*: [Ví dụ: Không hỗ trợ Android TV hoặc WearOS trong đợt này].
  * *Non-Goal 2*: [Ví dụ: Không xây dựng cổng thanh toán trực tiếp trong app, chỉ hiển thị QR].

### 7.2 Các Quyết Định Đánh Đổi Đã Thống Nhất (Trade-Off Agreements):
- **Đánh đổi 1**: [Ví dụ: Ưu tiên mã hóa toàn diện dữ liệu cục bộ thay vì rút ngắn thêm 100ms thời gian khởi động].
- **Đánh đổi 2**: [Ví dụ: Ưu tiên chuẩn hóa touch target >= 48dp thay vì giữ nguyên bố cục chữ siêu nhỏ của app cũ].

---

## 8. Danh Mục Giả Định & Quyết Định Trì Hoãn (Assumptions & Deferred Decisions)

### 8.1 Hồ Sơ Giả Định Đã Được Chấp Thuận (Approved Assumptions):
| Mã Giả Định | Hạng Mục & Nội Dung Giả Định | Cơ Sở / Rationale | Mức Độ Rủi Ro | Nhiệm Vụ Kiểm Chứng (Tại Bước 10 / 12) |
| :--- | :--- | :--- | :--- | :--- |
| `ASM-01` | [Ví dụ: Dung lượng bộ đệm ảnh tối đa 50 MB] | Khuyến nghị chuẩn của Coil/Glide | `BENIGN` | Kiểm thử stress-test bộ nhớ với 500 ảnh |
| `ASM-02` | [Ví dụ: Timeout kết nối mạng mặc định 15 giây] | Chuẩn kết nối di động 4G/5G | `BENIGN` | Kiểm thử ngắt kết nối giả lập |

### 8.2 Danh Mục Quyết Định Trì Hoãn Hợp Lệ (Deferred Decisions):
- `DEC-DEF-01`: [Ví dụ: Quyết định tích hợp Analytics chi tiết hoãn lại đến sau khi hoàn tất kiểm thử cốt lõi].

---

## 9. Tiêu Chí Nghiệm Thu Có Thể Kiểm Chứng (Verifiable Acceptance Criteria)

*Mọi tính năng phải có kịch bản Given / When / Then có thể kiểm chứng được:*

```gherkin
Kịch bản 1: [Tên kịch bản tính năng chính]
GIVEN [Trạng thái tiền đề của hệ thống / ứng dụng]
WHEN  [Người dùng thực hiện hành động cụ thể]
THEN  [Kết quả hiển thị chính xác trên giao diện]
AND   [Dữ liệu được cập nhật hoặc bảo toàn tương ứng]

Kịch bản 2: [Kịch bản xử lý lỗi / Ngoại lệ]
GIVEN [Trạng thái lỗi giả lập: Mất mạng / Nhập sai thông tin]
WHEN  [Người dùng kích hoạt hành động]
THEN  [Thông báo lỗi rõ ràng bằng tiếng Việt đời thường kèm nút thử lại]
AND   [Dữ liệu trên form không bị xóa mất theo RULE-INIT-001]

Kịch bản 3: [Tương Thích Màn Hình Di Động & Tỷ Lệ Khung Hình — AC-RESP-01]
GIVEN Ứng dụng chạy trên thiết bị với bất kỳ tỷ lệ nào: 16:9, 18:9, 19.5:9, 20:9, 21:9 hoặc màn hình gập
WHEN  Người dùng mở ứng dụng ở chế độ dọc (Portrait), xoay ngang (Landscape), hoặc mở bàn phím ảo (IME)
THEN  Toàn bộ các nút thao tác chính (CTA), trường nhập liệu, và thanh điều hướng vẫn hiển thị đầy đủ, không bị che khuất bởi tai thỏ (cutout), thanh hệ thống (system insets) hay bàn phím
AND   Nội dung tự động co giãn, cuộn mượt mà theo chiều dọc, không bị cắt cụt chữ (text clipping) và không phát sinh cuộn ngang ngoài ý muốn
AND   Vùng chạm cảm ứng cho mọi nút bấm duy trì kích thước tối thiểu 48x48dp across all viewport sizes
```

---

## 10. Chữ Ký Phê Duyệt & Đóng Băng Cổng 03 (Gate 03 Verification Sign-off)

- [ ] Đã vượt qua đánh giá tính đầy đủ thông tin: `powershell -File .agents/scripts/interview.ps1 evaluate-sufficiency` đạt **`SUFFICIENT`**.
- [ ] Đã được người dùng phê duyệt bằng lệnh: **`FREEZE UI SPEC`**.
- [ ] Đã mở Cổng 03 qua lệnh: `powershell -File .agents/scripts/gate.ps1 open 3 -Evidence 03_KET_QUA_KIEM_TRA/dac-ta-yeu-cau-da-chot.md -ApprovedBy "user"`.
- [ ] Sẵn sàng chuyển giao cho Kỹ năng `rea-plan` tại Bước 08 để lập kế hoạch 6 Milestones.
