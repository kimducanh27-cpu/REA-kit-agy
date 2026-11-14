---
description: Quy chuẩn quản trị thiết kế Stage 03: hợp đồng chống giao diện khuôn sáo (Anti-Slop), ranh giới cấm sinh mã trước Gate 03, chuẩn hóa Copy Deck nội dung thực tế và Design Tokens 3 tầng.
globs: "02_YEU_CAU_CUA_TOI/**, 03_KET_QUA_KIEM_TRA/dac-ta-yeu-cau-da-chot.md, 03_KET_QUA_KIEM_TRA/KE_HOACH_TRIEN_KHAI.md, prompts/03-TAB-PRODUCT-DEFINITION.md"
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
- Nếu ứng dụng đích là Android:
  * Phải tuân thủ chuẩn Material Design 3.
  * Hỗ trợ đúng vùng đệm thanh điều hướng/tai thỏ (WindowInsets / Edge-to-Edge).
  * Hỗ trợ cử chỉ vuốt lùi có dự đoán (Predictive Back Navigation).
  * Kích thước vùng tương tác cảm ứng tối thiểu đạt `48x48 dp`.

### Nguyên tắc 05: Tính Toàn Vẹn Của Hệ Thống Thiết Kế (Design System Integrity)
- Toàn bộ thiết kế phải dựa trên **Hệ Thống Token 3 Tầng**:
  1. *Global Tokens*: Bảng màu gốc, thang kích thước thô (Spacing, Typography scale).
  2. *Semantic Tokens*: Màu ngữ nghĩa (`color-primary`, `color-surface`, `color-danger-bg`).
  3. *Component Tokens*: Kích thước và màu sắc riêng của nút, trường nhập, thẻ.
- **Bắt buộc định nghĩa đủ 4 trạng thái cốt lõi cho mọi thành phần UI**:
  * `Loading` (Đang tải dữ liệu).
  * `Empty` (Chưa có dữ liệu - kèm nút dẫn dắt hành động).
  * `Success` (Dữ liệu hiển thị thành công).
  * `Error` (Phát sinh lỗi - kèm thông điệp rõ ràng và nút thử lại).

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
