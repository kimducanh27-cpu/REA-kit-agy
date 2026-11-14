---
name: rea-interview
description: Phụ trách độc quyền Bước 06 (REA Interview & Art Direction) và Bước 07 (Spec & Anti-Slop Design Gate) trong STAGE_03 (Product Definition). Phỏng vấn người dùng, đề xuất 3 concept cấu trúc khác biệt (chống UI slop), thiết lập Art Direction, soạn thảo Copy Deck thực tế (cấm Lorem Ipsum), xử lý 4 trạng thái UI bắt buộc, khóa Design Tokens 3 tầng và xuất bộ đặc tả Markdown đóng băng. Ranh giới tuyệt đối: KHÔNG VIẾT CODE trong giai đoạn này.
---

# KỸ NĂNG: PHỎNG VẤN ĐỊNH HÌNH SẢN PHẨM & THIẾT KẾ ANTI-SLOP (REA-INTERVIEW)

Kỹ năng chuyên biệt cho **Bước 06 (`06_REA_INTERVIEW`)** và **Bước 07 (`07_SPEC_AND_DESIGN`)** thuộc **STAGE_03 · PRODUCT DEFINITION** theo `docs/WORKFLOW_LIFECYCLE.md`.

> **RANH GIỚI KIẾN TRÚC BẮT BUỘC**:
> Trong toàn bộ STAGE_03, Agent tuyệt đối **KHÔNG ĐƯỢC VIẾT CODE, KHÔNG TẠO WORKING PROTOTYPE, KHÔNG SỬA DESIGN SYSTEM NGOÀI HỢP ĐỒNG**. Chỉ tạo hồ sơ đặc tả Markdown có cấu trúc, bố cục phân cấp và Copy Deck thực tế.

---

## 1. BƯỚC 06: REA INTERVIEW & ART DIRECTION (Chống Khuôn Sáo UI)

### 1.1 Khảo Sát Nhu Cầu & Đọc Đầu Vào Đóng Băng
1. Đọc đồng thời 3 nguồn tài liệu đầu vào:
   - `02_YEU_CAU_CUA_TOI/ho-so-va-muc-tieu.md` (mong muốn ban đầu của người dùng).
   - `03_KET_QUA_KIEM_TRA/bao-cao-hien-trang.md` (hiện trạng ứng dụng gốc từ Bước 04).
   - `03_KET_QUA_KIEM_TRA/UNKNOWNS_AND_COVERAGE.md` (sổ theo dõi điểm mù từ Bước 05).
2. Cập nhật trạng thái chờ người dùng:
   - Ghi vào `.agents/state/active_case.json`: `current_phase = "STAGE_03_PRODUCT_DEFINITION"`, `current_step = "06_REA_INTERVIEW"`, `current_gate_status = "GATE_03_WAITING_USER_INPUT"`.

### 1.2 Thiết Lập Art Direction & Tự Phản Biện Chống UI Slop
AI phải xác định 7 thành phần Art Direction trước khi vẽ bố cục:
1. **Product Personality**: Sản phẩm có cá tính gì? (ví dụ: Tối giản tập trung, Trợ lý chuyên sâu, Bảng tra cứu thực dụng).
2. **Visual Thesis**: Ý tưởng thị giác chủ đạo xuyên suốt.
3. **Layout Philosophy**: Triết lý tổ chức không gian (ví dụ: Editorial Learning Workspace thay vì Dashboard 8 thẻ quen thuộc).
4. **Typography Hierarchy**: Phân cấp chữ có chủ đích.
5. **Density & Spacing**: Mật độ thông tin trên màn hình (Compact / Regular / Spacious).
6. **Signature Element**: Một đặc điểm nhận diện đáng nhớ.
7. **Anti-patterns**: Các lối thiết kế sáo mòn cần tránh triệt để (card tràn lan, gradient vô nghĩa, icon trang trí thừa).

*Tự phản biện tính khác biệt:*
- Nếu thay tên app bằng một sản phẩm khác, thiết kế này có còn hợp không?
- Bố cục có được dẫn dắt bởi dữ liệu thực tế hay chỉ là khuôn AI quen vẽ?

### 1.3 Đề Xuất 3 Concept Khác Biệt Cấu Trúc (Structural Diversity)
Bắt buộc đề xuất **3 Concept có cấu trúc tổ chức thông tin khác biệt**, không chỉ đổi màu:
- **Concept 1**: Tập trung luồng công việc chính (Task-First Focus).
- **Concept 2**: Tổ chức dạng không gian tài liệu/biên tập (Editorial Workspace).
- **Concept 3**: Luồng thẻ tuần tự tối giản (Streamlined Sequential Flow).

### 1.4 Lệnh Phê Duyệt Bố Cục (Human Gate 1)
Người dùng chọn concept và xác nhận bằng câu lệnh:
👉 **`APPROVE SCREEN COMPOSITION`**

---

## 2. BƯỚC 07: SPEC & DESIGN GATE (States, Copy Deck & Tokens)

Sau khi nhận lệnh `APPROVE SCREEN COMPOSITION`, Agent chuyển sang Bước 07:

### 2.1 Bố Cục Màn Hình & Co Giãn (Screen Composition & Responsive Spec)
1. Xuất `03_KET_QUA_KIEM_TRA/01_SCREEN_COMPOSITION.md`:
   - Vị trí các thành phần và thứ tự ưu tiên thị giác.
   - Khoảng cách, phân vùng và cách tổ chức luồng mắt đọc.
2. Xuất `03_KET_QUA_KIEM_TRA/02_RESPONSIVE_SPEC.md`:
   - Quy chuẩn Responsive theo **Window Size Classes** (Compact, Medium, Expanded).
   - Khả năng tương thích Foldable Posture và Insets (Edge-to-Edge display).

### 2.2 Xử Lý Triệt Để 4 Trạng Thái Giao Diện (State Composition)
Xuất `03_KET_QUA_KIEM_TRA/03_STATE_COMPOSITION.md` xử lý đầy đủ:
1. **Loading State**: Skeleton loader tương ứng khung giao diện thật (không chỉ dùng vòng quay spinner mơ hồ).
2. **Empty State**: Minh họa rõ ràng + thông điệp thân thiện + Nút hành động kêu gọi (CTA) cụ thể.
3. **Success State**: Toast hoặc animation xác nhận hoàn thành tác vụ tức thì.
4. **Error / Recovery State**: Banner thông báo nguyên nhân bằng tiếng Việt đời thường + Nút "Thử lại", **bảo toàn 100% dữ liệu form người dùng đang nhập dở theo `RULE-INIT-001`**.
5. *Trạng thái đặc thù*: Quyền bị từ chối (`Permission Denied`), Mạng chập chờn (`Partial Data`), và Hộp thoại xác nhận phá hủy (`Destructive Confirmation`).

### 2.3 Soạn Thảo Copy Deck Thực Tế (CẤM Placeholder Slop)
Xuất `03_KET_QUA_KIEM_TRA/04_COPY_DECK.md` theo mẫu `templates/13-COPY-DECK-TEMPLATE.md`:
- **NGHIÊM CẤM**: `Lorem ipsum`, `Sample text`, hoặc các câu chào generic như `Welcome back!` ở mọi nơi.
- Định nghĩa nội dung văn bản thực tế cho toàn bộ nhãn, tiêu đề, nút bấm, thông báo lỗi.
- Quy định giới hạn ký tự, cách xuống dòng, và độ dài dự phòng khi chuyển đổi ngôn ngữ.

### 2.4 Khóa Hợp Đồng Design Tokens 3 Tầng
Xuất `02_YEU_CAU_CUA_TOI/design.md` theo `templates/05-DESIGN-TOKEN-TEMPLATE.md`:
- **Tầng 1 (Primitive)**: Bảng màu, Typography scale, Spacing (4dp grid), Radius, Shadows.
- **Tầng 2 (Semantic)**: Nút bấm (Primary, Secondary, Destructive), Input field, Cards, Header.
- **Tầng 3 (Platform Native)**: Ánh xạ chuẩn Android Jetpack Compose (`Theme.kt`, `Color.kt`) hoặc Web CSS `:root`.

### 2.5 Xuất Đặc Tả Sản Phẩm & Lệnh Phê Duyệt (Human Gate 2)
1. Xuất tổng hợp đặc tả vào `03_KET_QUA_KIEM_TRA/dac-ta-yeu-cau-da-chot.md` theo `templates/02-SPEC-TEMPLATE.md`.
2. Trình bày cho người dùng phê duyệt:
   👉 **`APPROVE UI SPEC`**
3. Sau khi người dùng duyệt `APPROVE UI SPEC`, chuyển giao ngay cho **`rea-plan`** tại Bước 08 để lập kế hoạch 6 Milestones và đóng băng đặc tả qua lệnh `FREEZE UI SPEC`.
