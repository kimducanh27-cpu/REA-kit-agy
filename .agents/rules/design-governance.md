---
description: Quy chuẩn quản trị thiết kế Stage 03: hợp đồng chống giao diện khuôn sáo (Anti-Slop), ranh giới cấm sinh mã trước Gate 03, chuẩn hóa Copy Deck nội dung thực tế, Design Tokens 3 tầng và tham chiếu UI Implementation Map (Motion, Icon, Visual Archaeology).
globs: "02_YEU_CAU_CUA_TOI/**, 03_KET_QUA_KIEM_TRA/dac-ta-yeu-cau-da-chot.md, 03_KET_QUA_KIEM_TRA/KE_HOACH_TRIEN_KHAI.md, prompts/03-TAB-PRODUCT-DEFINITION.md, docs/UI_IMPLEMENTATION_MAP.md"
trigger: model_decision
---

# QUY TẮC QUẢN TRỊ THIẾT KẾ & CHỐNG GIAO DIỆN KHUÔN SÁO (DESIGN GOVERNANCE & ANTI-SLOP)

Tài liệu này xác lập các nguyên tắc bắt buộc trong **STAGE 03 · PRODUCT DEFINITION** (Bước 06–08). Mục tiêu là đảm bảo mọi sản phẩm tái tạo hoặc cải tiến đều có chất lượng giao diện nguyên bản, loại bỏ triệt để các khuôn mẫu giao diện giả tạo (AI Slop) và giữ vững ranh giới đóng băng đặc tả.

---

## 1. Ranh Giới Đóng Băng Đặc Tả: CẤM SINH MÃ TẠI STAGE 03 (Spec-First Boundary)

1. **Tuyệt đối không viết mã trước khi Cổng 03 được duyệt**:
   - Trong suốt Stage 03, Agent **CẤM TUYỆT ĐỐI**:
     * Viết mã nguồn sản phẩm (HTML, CSS, JavaScript, Kotlin, Java, XML Layout).
     * Tạo file chạy thử hoặc working prototype trong `05_MA_NGUON_PHAT_TRIEN/`.
     * Chỉnh sửa cấu trúc file trong thư mục mã nguồn.
   - **Đầu ra duy nhất được phép của Stage 03** là các hợp đồng đặc tả định dạng Markdown:
     * `02_YEU_CAU_CUA_TOI/design.md` (Hợp đồng Design System 3 tầng).
     * `03_KET_QUA_KIEM_TRA/dac-ta-yeu-cau-da-chot.md` (Đặc tả yêu cầu & Build Route).
     * `03_KET_QUA_KIEM_TRA/KE_HOACH_TRIEN_KHAI.md` (Kế hoạch phân rã nhiệm vụ nguyên tử).
     * Các bản đặc tả chi tiết: `01_SCREEN_COMPOSITION.md`, `02_RESPONSIVE_SPEC.md`, `03_STATE_COMPOSITION.md`, `04_COPY_DECK.md`.

2. **Chỉ chuyển sang viết mã khi Cổng 03 chuyển sang `PASS`**:
   - Chỉ sau khi người dùng xác nhận phê duyệt chính thức bằng văn bản cho Đặc tả và Kế hoạch triển khai, Agent mới được phép mở Cổng 03 và bước vào Stage 04 (Implementation).

---

## 2. Hợp Đồng Thiết Kế Chống Giao Diện Khuôn Sáo (7 Anti-Slop Design Principles)

Mọi đề xuất giao diện phải vượt qua 7 nguyên tắc thẩm định chất lượng sau:

### Nguyên tắc 01: Thiết Kế Định Hướng Sản Phẩm (Product-Driven Design)
- Tuyệt đối không sao chép lại bố cục mặc định mà các mô hình AI thường tạo ra (như dashboard dạng lưới thẻ bo tròn màu tím, thanh trượt gradient lòe loẹt, đổ bóng mờ ảo không có mục đích).
- Cấu trúc màn hình phải xuất phát từ luồng nghiệp vụ thực tế của ứng dụng gốc đã bóc tách tại Stage 02.

### Nguyên tắc 02: Đa Dạng Hóa Về Mặt Cấu Trúc (Structural Diversity)
- Khi trình bày các phương án thiết kế cho người dùng lựa chọn, Agent **BẮT BUỘC ĐỀ XUẤT TỐI THIỂU 3 KHÁI NIỆM (CONCEPTS) KHÁC BIỆT RÕ RÀNG VỀ CẤU TRÚC**:
  * Khác biệt về phân cấp thị giác (Visual Hierarchy), luồng thao tác chính, cách bố trí thanh điều hướng.
  * **CẤM**: Giữ nguyên một bộ khung layout rồi chỉ thay đổi 3 bảng màu và gọi đó là "3 concept".

### Nguyên tắc 03: Không Sử Dụng Giao Diện Trang Trí Vô Nghĩa (No Decorative UI)
- Mọi thành phần trên giao diện (nút bấm, thẻ, icon, viền) đều phải giải trình được mục đích phục vụ trực tiếp cho tác vụ của người dùng.
- Loại bỏ hoàn toàn các thẻ trắng lấp chỗ trống (filler cards), icon minh họa không có chú thích, hoặc các khối trang trí làm loãng nội dung cốt lõi.

### Nguyên tắc 04: Hành Vi Chuẩn Nền Tảng (Platform-Native Behavior)
- Nếu ứng dụng đích là Android (Route B):
  * Phải tuân thủ chuẩn Material Design 3.
  * Hỗ trợ đúng vùng đệm thanh điều hướng/tai thỏ (WindowInsets / Edge-to-Edge).
  * Hỗ trợ cử chỉ vuốt lùi có dự đoán (Predictive Back Navigation).
  * Kích thước vùng tương tác cảm ứng tối thiểu đạt `48x48 dp`.
  * Thư viện biểu tượng bắt buộc: Google Material Symbols (Outlined/Rounded).
- Nếu ứng dụng đích là Web (Route A):
  * Tuân thủ chuẩn tiếp cận WCAG 2.1/2.2 AA.
  * Hỗ trợ Safe-Area Insets (`env(safe-area-inset-*)`) và bàn phím ảo.
  * Thư viện biểu tượng bắt buộc: Lucide Icons (stroke 2px, viewBox 24x24).
  * **Thực thi 100% Offline-First (Loại bỏ hoàn toàn CDN)**: Tuyệt đối KHÔNG sử dụng Tailwind CSS CDN (`cdn.tailwindcss.com`) hoặc bất kỳ liên kết CDN từ xa nào. Toàn bộ kiểu dáng phải sử dụng tệp CSS cục bộ biên dịch từ token (`tokens.css`) và CSS nội bộ tự chứa, đảm bảo ứng dụng chạy 100% ngoại tuyến khi mở trực tiếp file `index.html` mà không cần kết nối Internet.
- **CẤM TUYỆT ĐỐI**: Sử dụng Emoji làm icon chức năng trên bất kỳ nền tảng nào (tham chiếu chi tiết tại `docs/UI_IMPLEMENTATION_MAP.md`).

### Nguyên tắc 05: Tính Toàn Vẹn Của Hệ Thống Thiết Kế (Design System Integrity)
- Toàn bộ thiết kế phải dựa trên **Hệ Thống Token 3 Tầng**:
  1. *Global Tokens*: Bảng màu gốc, thang kích thước thô (Spacing 4dp/8dp grid, Typography scale, Radius).
  2. *Semantic Tokens*: Màu ngữ nghĩa (`color-primary`, `color-surface`, `color-danger-bg`), Motion Tokens (`motion-duration-fast/base/slow`, easing standard/emphasized), và Icon Tokens (`icon-size-sm/base/lg`).
  3. *Component Tokens*: Kích thước và màu sắc riêng của nút, trường nhập, thẻ.
- **Bắt buộc định nghĩa đủ 6 trạng thái cốt lõi cho mọi thành phần & màn hình UI**:
  1. `Loading` (Đang tải dữ liệu - Skeleton shimmer chuẩn / spinner tại vị trí thao tác, nút bấm bị disabled).
  2. `Empty` (Chưa có dữ liệu - kèm hình minh họa trực quan, thông điệp hướng dẫn và nút bấm Call-To-Action tạo mới).
  3. `Success` (Dữ liệu hiển thị thành công / thông báo nổi Toast xanh tự đóng sau 3 giây).
  4. `Error` (Phát sinh lỗi - kèm thông điệp rõ ràng, nút "Thử lại" và bảo toàn dữ liệu form).
  5. `In-Progress / Draft` (Đang nhập liệu / Bản nháp - tự động lưu tạm, chỉ báo thời gian thực, bảo toàn 100% dữ liệu form theo `RULE-INIT-001`).
  6. `Offline / Reconnecting` (Ngoại tuyến / Đang kết nối lại - banner cảnh báo mạng vàng/xám, lưu thao tác vào hàng đợi cục bộ và tự động retry đồng bộ khi kết nối mạng phục hồi).

### Nguyên tắc 06: Bắt Buộc Sử Dụng Nội Dung Thực Tế & Copy Deck (Real Content Enforcement)
- **CẤM TUYỆT ĐỐI**: Sử dụng văn bản giả (`Lorem Ipsum`, `Sample text`, `Dữ liệu mẫu`, `Tiêu đề ở đây`, hoặc câu chào sáo rỗng `Welcome back! User`).
- **Yêu cầu bắt buộc**:
  * Mọi màn hình phải có tài liệu **Copy Deck** (`04_COPY_DECK.md`) chứa văn bản tiếng Việt tự nhiên, phù hợp với nghiệp vụ ứng dụng.
  * Quy định rõ giới hạn số ký tự tối đa cho từng tiêu đề, nhãn nút và mô tả.
  * Nêu rõ phương án xử lý khi văn bản dài: cắt gọn bằng dấu chấm lửng (`ellipsis`), xuống dòng tự động (`multiline wrap`), hoặc hiển thị tooltip.

### Nguyên tắc 07: Thẩm Định Độc Lập Có Bằng Chứng (Independent Critique & Evidence)
- Agent không được tự phong thiết kế của mình là "đẹp", "hiện đại", hay "trải nghiệm đỉnh cao".
- Mọi quyết định cải tiến phải dẫn chứng bằng chứng cụ thể:
  * So sánh với ảnh chụp baseline tại Bước 02.
  * Phản ánh đúng phản hồi của người dùng ghi nhận tại Bước 06.

---

## 3. Quản Trị Chuyển Động, Biểu Tượng & Khảo Cổ Giao Diện (Motion, Icon & Archaeology Governance)

Mọi hoạt động thiết kế, trích xuất ngược và triển khai giao diện phải tham chiếu và tuân thủ tuyệt đối tài liệu **[Bản Đồ Triển Khai Giao Diện & Giao Thức Khảo Cổ Mã Nguồn UI](file:///C:/Users/ducti/.gemini/antigravity/scratch/REA-kit-agy/docs/UI_IMPLEMENTATION_MAP.md)**:

1. **Quản trị Chuyển động & Hoạt họa (Motion & Animation Governance)**:
   - Tuân thủ thang thời lượng chuẩn: Fast (150ms), Base (250ms), Slow (400ms).
   - Áp dụng đúng đường cong gia tốc: Standard Easing (nội bộ màn hình), Emphasized Decelerate (bước vào), Emphasized Accelerate (bước ra).
   - **Bắt buộc tuân thủ Reduced Motion**: Tôn trọng `@media (prefers-reduced-motion: reduce)` và Android `ANIMATOR_DURATION_SCALE = 0`, tự động tắt hoặc giảm thiểu chuyển động cho người dùng nhạy cảm tiền đình.
2. **Quy chuẩn Thư viện Biểu tượng (Icon Library Rules)**:
   - Web Route A: Bắt buộc sử dụng Lucide Icons (stroke 2px, viewBox 24x24).
   - Android Route B: Bắt buộc sử dụng Material Symbols / Material Icons (Outlined/Rounded, 24dp).
   - **CẤM TUYỆT ĐỐI**: Dùng Emoji làm biểu tượng chức năng trên nút bấm, thanh điều hướng, bảng biểu.
3. **Giao thức Khảo cổ Hiệu ứng Thị giác (Code Archaeology Protocol)**:
   - Khi dịch ngược hoặc phân tích mã cũ, phải kiểm kê đầy đủ 5 trụ cột hiệu ứng: Box-shadow (tách biệt ambient & spot), Blur / Backdrop-filter (có fallback cho Android < API 31), Transform (tối ưu qua `graphicsLayer`), Stacking Context & Z-Index (tránh lỗi xén mép `clipChildren`), và Border / Ring.
   - Tuân thủ lưới khoảng cách 4dp/8dp, chuẩn Window Size Classes (Compact, Medium, Expanded), Safe-Area Insets (`env(safe-area-inset-*)`, `enableEdgeToEdge()`), và vùng chạm tối thiểu **48x48dp**.
4. **Phân biệt rạch ròi 2 Giai đoạn Kiểm chứng Thị giác (Visual Verification Protocol)**:
   - *Giai đoạn đặc tả tĩnh (Stage 03)*: Chỉ thao tác trên markdown contract, gắn nhãn `[SPECIFIED]` hoặc `[INFERRED]`. Nghiêm cấm sinh mã hoặc tuyên bố giao diện đã hoàn thiện khi chưa chạy thực.
   - *Giai đoạn bằng chứng chạy thực (Stage 02 & Stage 04)*: Chỉ gắn nhãn `[OBSERVED]` khi có ảnh chụp màn hình thiết bị thật / headless browser, bản trích xuất cây phân cấp layout bounds từ `uiautomator dump` / DOM box-model, và kết quả đo lường độ tương phản WCAG AA thực tế.
