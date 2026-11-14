# HƯỚNG DẪN PHỎNG VẤN CHUYÊN BIỆT: CẢI TIẾN TRẢI NGHIỆM & GIAO DIỆN (UX/UI IMPROVEMENT)
> **Domain**: `UX_UI_IMPROVEMENT`  
> **Áp dụng cho**: Bước 06 (`06_REA_INTERVIEW`) & Bước 07 (`07_SPEC_AND_DESIGN`) thuộc STAGE_03 · PRODUCT DEFINITION  
> **Quy chuẩn**: REA Adaptive Interview Framework · Anti-Slop Visual Governance  

---

## 1. Mục Tiêu & Ba Phân Loại Cải Tiến (Triaging Tracks)

Hướng dẫn này kích hoạt khi mục tiêu dự án là **nâng cấp diện mạo, tối ưu hóa tính tiện dụng, hiện đại hóa trải nghiệm hoặc làm mới ngôn ngữ thiết kế** của sản phẩm.

Để tránh nhầm lẫn giữa việc "đổi màu giao diện" với "tái cấu trúc trải nghiệm", Agent bắt buộc phân loại công việc vào một trong 3 nhánh (Tracks):

```
┌────────────────────────────────────────────────────────────────────────┐
│                   3 PHÂN LOẠI CẢI TIẾN TRẢI NGHIỆM & GIAO DIỆN         │
├───────────────────┬───────────────────┬────────────────────────────────┤
│ TRACK 1:          │ TRACK 2:          │ TRACK 3:                       │
│ VISUAL REDESIGN   │ UX FLOW           │ UI IMPLEMENTATION REFINEMENT   │
│ - Tái sinh diện   │ - Cắt giảm bước   │ - Tinh chỉnh pixel (Pixel-tune)│
│   mạo thương hiệu │   thao tác thừa   │ - Đạt chuẩn Touch Target 48dp  │
│ - Đại tu bảng màu,│ - Tăng tỷ lệ hoàn │ - Micro-interactions & Motion  │
│   typography      │   thành tác vụ    │ - Khắc phục co giãn Responsive │
│ - Đổi cấu trúc bố │ - Tối ưu luồng lỗi│ - Đồng bộ Design Tokens 3 tầng │
│   cục thông tin   │   và Empty states │   vào Theme.kt / CSS           │
└───────────────────┴───────────────────┴────────────────────────────────┘
```

---

## 2. Ba Chế Độ Khám Phá Thiết Kế (Design Exploration Modes)

> ⚠️ **QUY TẮC CỐT LÕI (LOẠI BỎ RẬP KHUÔN 3 CONCEPT BẮT BUỘC)**:
> Trước đây, quy trình cũ bắt buộc vẽ 3 concept cấu trúc cho mọi trường hợp. Nay Agent phải xác định đúng **Chế Độ Thiết Kế (Design Mode)** từ mong muốn của người dùng:

```
                  ┌──────────────────────────────────────────────┐
                  │ XÁC ĐỊNH CHẾ ĐỘ THIẾT KẾ (DESIGN MODE)        │
                  └──────────────────────┬───────────────────────┘
                                         │
         ┌───────────────────────────────┼───────────────────────────────┐
         ▼                               ▼                               ▼
[DESIGN_REUSE_EXACT]          [DESIGN_STYLE_SPECIFIED]      [DESIGN_STRUCTURAL_EXPLORATION]
Người dùng muốn sao chép       Người dùng chỉ định phong     Người dùng muốn tái thiết kế,
100% nguyên bản giao diện cũ   cách cụ thể (ví dụ: Dark Mode khám phá bố cục mới hoặc không
(1-1 Clone / Replication).     Material You, iOS Cupertino). nêu phong cách rõ ràng.
         │                               │                               │
         ▼                               ▼                               ▼
KHÔNG VẼ 3 CONCEPTS.           KHÔNG VẼ 3 CONCEPTS.          BẮT BUỘC ĐỀ XUẤT 3 CONCEPTS
Trích xuất Design Tokens       Áp dụng trực tiếp phong cách  KHÁC BIỆT CẤU TRÚC (Task-First,
chuẩn từ ảnh/source cũ.        đã chọn vào layout hiện có.   Editorial, Progressive Flow).
```

### 2.1 Chế Độ 1: `DESIGN_REUSE_EXACT` (Tái Sử Dụng Nguyên Bản)
- **Dấu hiệu nhận biết**: Người dùng yêu cầu "làm giống hệt app gốc", "clone 1-1", "giữ nguyên UI chỉ viết lại bằng Compose/React".
- **Hành động của Agent**:
  * **Bỏ qua đề xuất 3 concept**.
  * Trích xuất trực tiếp bảng màu, kích thước, font chữ từ ảnh chụp Bước 02 hoặc file giao diện gốc.
  * Lập ngay bản đặc tả khớp 1-1 cho Bước 07.

### 2.2 Chế Độ 2: `DESIGN_STYLE_SPECIFIED` (Phong Cách Chỉ Định Cụ Thể)
- **Dấu hiệu nhận biết**: Người dùng đưa ra phong cách trực diện (ví dụ: "Thiết kế theo Material You tông màu tối", "Phong cách thẻ kính Glassmorphism", "Giao diện Bloomberg Terminal mật độ thông tin dày", "Phong cách tối giản Bắc Âu - Nordic Minimalist").
- **Hành động của Agent**:
  * **Bỏ qua đề xuất 3 concept**.
  * Chốt bộ quy tắc Design Tokens theo đúng phong cách được chỉ định.
  * Phác thảo bố cục duy nhất đáp ứng chuẩn phong cách đó để người dùng duyệt.

### 2.3 Chế Độ 3: `DESIGN_STRUCTURAL_EXPLORATION` (Khám Phá Cấu Trúc Khác Biệt)
- **Dấu hiệu nhận biết**: Người dùng muốn "làm mới giao diện", "nghiên cứu bố cục chống khuôn sáo UI slop", hoặc chưa có định hình cụ thể.
- **Hành động của Agent**:
  * **Bắt buộc đề xuất 3 Concept có cấu trúc tổ chức thông tin khác biệt**:
    * **Concept A (Task-First Focus)**: Đưa hành động cốt lõi nhất lên vị trí trung tâm ngay khi mở app; thao tác nhanh nhất.
    * **Concept B (Content-First / Editorial)**: Dàn trang như tạp chí/sách mở; khoảng thở rộng, giàu tính thẩm mỹ và tĩnh tại.
    * **Concept C (Contextual / Progressive Flow)**: Màn hình biến đổi tuần tự thích ứng theo trạng thái hoàn thành của người dùng.

---

## 3. Quy Chuẩn Chống Khuôn Sáo (Anti-Slop Visual Governance)

Dù ở bất kỳ chế độ nào, bản đặc tả thiết kế phải đáp ứng 4 tiêu chuẩn chống UI slop:

1. **Bản Sắc 7 Thành Phần (Art Direction Portfolio)**:
   - Xác định: Product Personality, Visual Thesis, Layout Philosophy, Typography Hierarchy, Density & Spacing, Signature Element, và Forbidden Anti-Patterns (Card tràn lan, Gradient vô nghĩa).
2. **Soạn Thảo Copy Deck Thực Tế (Tuyệt Đối Cấm Lorem Ipsum)**:
   - Viết toàn bộ tiêu đề, nhãn, nút bấm, thông báo trạng thái bằng tiếng Việt thực tế theo ngữ cảnh nghiệp vụ.
   - Không dùng các câu chào chung chung kiểu "Chào mừng bạn quay lại!" nếu không mang lại giá trị tác vụ.
3. **Bắt Buộc Xử Lý Đầy Đủ 4 Trạng Thái Giao Diện**:
   - `Loading State`: Skeleton loader khớp cấu trúc thật (không dùng spinner xoay tròn vô định).
   - `Empty State`: Minh họa nhã nhặn + thông điệp hướng dẫn + Nút CTA hành động tạo dữ liệu đầu tiên.
   - `Success State`: Xác nhận hoàn thành tác vụ ngay tức thì (Feedback < 100ms).
   - `Error / Recovery State`: Giải thích bằng ngôn ngữ thân thiện + Nút "Thử lại", **bảo toàn 100% dữ liệu form người dùng đang nhập dở theo `RULE-INIT-001`**.
4. **Chuẩn Công Thái Học Di Động (Mobile Ergonomics)**:
   - Kích thước vùng chạm cảm ứng tối thiểu **48x48dp**.
   - Vùng thao tác một tay bằng ngón cái (Thumb zone) cho các nút quan trọng ở nửa dưới màn hình.
   - Độ tương phản chữ đạt tối thiểu **WCAG AA** (tỷ lệ tương phản 4.5:1).

---

## 4. Quy Trình Vận Hành Bộ Lọc Câu Hỏi (Question Necessity Engine)

### 4.1 Những Gì KHÔNG ĐƯỢC Hỏi
- ❌ **CẤM HỎI**: "Bạn thích màu gì?" nếu người dùng đã cung cấp brand guide hoặc đã chọn chế độ `DESIGN_REUSE_EXACT`.
- ❌ **CẤM HỎI**: "Nên dùng padding 8dp hay 16dp?" (Vi phạm Ownership - Agent tự áp dụng 4dp/8dp spacing grid).
- ❌ **CẤM HỎI**: "Trạng thái Empty nên viết gì?" (Vi phạm Ownership - Agent tự soạn thảo Copy Deck thực tế cho người dùng duyệt).

### 4.2 Những Gì ĐƯỢC Hỏi (Quyết Định Trọng Tâm Về Trải Nghiệm)
1. **Mật độ thông tin trên màn hình (Information Density)**:
   - *Ví dụ*: "Bạn muốn giao diện hiển thị theo phong cách: (A) Rộng rãi, thư thả (Spacious) dễ nhìn cho người dùng phổ thông, hay (B) Mật độ cao (Compact) để xem được nhiều thông tin cùng lúc trên một màn hình?"
2. **Ưu tiên luồng thao tác khi tinh gọn (Flow Trade-offs)**:
   - *Ví dụ*: "Để rút ngắn quá trình tạo hồ sơ từ 4 bước xuống 1 bước, chúng tôi có thể gộp các thông tin phụ vào mục 'Cài đặt nâng cao'. Bạn có muốn người dùng điền nhanh hay bắt buộc phải điền đủ mọi trường ngay từ đầu?"
3. **Lựa chọn Concept cấu trúc (chỉ trong chế độ `DESIGN_STRUCTURAL_EXPLORATION`)**:
   - *Ví dụ*: Trình bày tóm tắt 3 Concept A, B, C và yêu cầu người dùng chọn concept ưng ý nhất.

---

## 5. Mẫu Ghi Hồ Sơ Quyết Định & Giả Định (UX/UI Records)

### Mẫu Ghi Quyết Định Giao Diện (Decision Record)
```markdown
### DECISION-UI-[STT]
- **Nhánh Cải Tiến (Track)**: [Visual Redesign / UX Flow / UI Implementation Refinement]
- **Chế Độ Thiết Kế (Design Mode)**: [`DESIGN_REUSE_EXACT` / `DESIGN_STYLE_SPECIFIED` / `DESIGN_STRUCTURAL_EXPLORATION`]
- **Vấn Đề Cần Chốt**: [Ví dụ: Quyết định phong cách chủ đạo]
- **Quyết Định Được Chọn**: [Ví dụ: Phong cách Material You Dark Theme với Tone màu Deep Navy]
- **Lý Do Lựa Chọn**: Khớp mong muốn nhận diện thương hiệu hiện đại của người dùng.
- **Trạng Thái**: `CLOSED`
```

### Mẫu Ghi Giả Định Giao Diện (Assumption Record)
```markdown
### ASSUMPTION-UI-[STT]
- **Hạng Mục**: [Ví dụ: Spacing Scale]
- **Giả Định Áp Dụng**: Sử dụng lưới 4dp chuẩn Android (4dp, 8dp, 16dp, 24dp, 32dp).
- **Lý Do Áp Dụng**: Chuẩn công nghiệp phổ quát cho hệ thống Design Tokens.
- **Nhiệm Vụ Kiểm Chứng (Verification Task)**: Đối chiếu với `verify_code.ps1` và `android layout` ở Bước 12.
- **Trạng Thái**: `ACCEPTED_BY_DEFAULT`
```

---

## 6. Tiêu Chí Hoàn Tất Phỏng Vấn (Exit Gate Criteria)

Agent chỉ được chuyển sang Bước 07 khi:
1. Đã xác định rõ Track và Design Mode tương ứng.
2. Nếu là `DESIGN_STRUCTURAL_EXPLORATION`: Người dùng đã ra lệnh `APPROVE SCREEN COMPOSITION` cho 1 trong 3 concept.
3. Nếu là `DESIGN_REUSE_EXACT` hoặc `DESIGN_STYLE_SPECIFIED`: Đã chốt trực tiếp bản sắc và chuyển ngay sang Bước 07 mà không làm phiền người dùng chọn concept.
4. Sẵn sàng xuất bản đầy đủ 4 file đặc tả: `01_SCREEN_COMPOSITION.md`, `02_RESPONSIVE_SPEC.md`, `03_STATE_COMPOSITION.md` và `04_COPY_DECK.md`.
