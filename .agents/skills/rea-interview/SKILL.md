---
name: rea-interview
description: Phụ trách độc quyền Bước 06 (REA Adaptive Interview & Art Direction) và Bước 07 (Spec & Anti-Slop Design Gate) trong STAGE_03 (Product Definition). Điều hướng phỏng vấn thích ứng theo 6 Domain chuyên biệt, vận hành Question Necessity Engine (8 bộ lọc triệt tiêu câu hỏi thừa), Decision & Constraint Engine (Question/Decision/Assumption Records), xử lý linh hoạt 3 chế độ thiết kế (DESIGN_REUSE_EXACT, DESIGN_STYLE_SPECIFIED, DESIGN_STRUCTURAL_EXPLORATION - chỉ kích hoạt 3 concepts khi người dùng yêu cầu khám phá cấu trúc), thiết lập Art Direction, soạn thảo Copy Deck thực tế (cấm Lorem Ipsum), xử lý 4 trạng thái UI bắt buộc, khóa Design Tokens 3 tầng và xuất bộ đặc tả Markdown đóng băng. Ranh giới tuyệt đối: KHÔNG VIẾT CODE trong giai đoạn này.
---

# KỸ NĂNG: PHỎNG VẤN THÍCH ỨNG & THIẾT KẾ ĐẶC TẢ ANTI-SLOP (REA-INTERVIEW)

Kỹ năng chuyên biệt cho **Bước 06 (`06_REA_INTERVIEW`)** và **Bước 07 (`07_SPEC_AND_DESIGN`)** thuộc **STAGE_03 · PRODUCT DEFINITION** theo quy chuẩn `docs/WORKFLOW_LIFECYCLE.md` và `docs/ADAPTIVE_INTERVIEW_FRAMEWORK.md`.

> ⚠️ **RANH GIỚI KIẾN TRÚC BẮT BUỘC**:
> Trong toàn bộ STAGE_03, Agent tuyệt đối **KHÔNG ĐƯỢC VIẾT CODE, KHÔNG TẠO WORKING PROTOTYPE, KHÔNG SỬA DESIGN SYSTEM NGOÀI HỢP ĐỒNG**. Chỉ tạo hồ sơ đặc tả Markdown có cấu trúc, bố cục phân cấp, hồ sơ quyết định và Copy Deck thực tế.

---

## 1. TỔNG QUAN KIẾN TRÚC THÍCH ỨNG (ADAPTIVE ARCHITECTURE)

Quy trình phỏng vấn định hình sản phẩm của REA-kit-agy không sử dụng bảng khảo sát cứng nhắc làm phiền người dùng. Quy trình hoạt động dựa trên 4 khối động cơ phối hợp chặt chẽ:

```
┌────────────────────────────────────────────────────────────────────────┐
│                   HỆ THỐNG PHỎNG VẤN THÍCH ỨNG (REA-INTERVIEW)         │
├────────────────────────────────────────────────────────────────────────┤
│ 1. ĐIỀU HƯỚNG TÊN MIỀN (DOMAIN ROUTING ENGINE)                         │
│    Tự động phân loại mục tiêu người dùng vào 1 trong 6 Domain chuyên sâu│
│    (App Opt, Security, Feature Add, Feature Opt, Bug Fix, UX/UI).      │
├────────────────────────────────────────────────────────────────────────┤
│ 2. ĐỘNG CƠ SÀNG LỌC CÂU HỎI (QUESTION NECESSITY ENGINE - 8 FILTERS)    │
│    Loại bỏ 100% câu hỏi thừa đã biết, tự kiểm tra được, hoặc rủi ro thấp│
│    trước khi gửi cho người dùng.                                       │
├────────────────────────────────────────────────────────────────────────┤
│ 3. ĐỘNG CƠ QUYẾT ĐỊNH & GIẢ ĐỊNH (DECISION & CONSTRAINT ENGINE)         │
│    Theo dõi và đóng băng Question Record, Decision Record, Assumption  │
│    Record có tính minh bạch và truy xuất ngược.                        │
├────────────────────────────────────────────────────────────────────────┤
│ 4. ĐIỀU TIẾT KHÁM PHÁ THIẾT KẾ (DESIGN EXPLORATION CONTROLLER)         │
│    Không ép buộc 3 concepts đại trà. Tự động chuyển đổi giữa:          │
│    - DESIGN_REUSE_EXACT (Khớp 1-1, bỏ qua 3 concepts)                  │
│    - DESIGN_STYLE_SPECIFIED (Theo phong cách chỉ định, bỏ 3 concepts)  │
│    - DESIGN_STRUCTURAL_EXPLORATION (Bắt buộc 3 concepts cấu trúc)      │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. ĐIỀU HƯỚNG TÊN MIỀN PHỎNG VẤN (DOMAIN ROUTING)

Tại đầu Bước 06, Agent đọc tài liệu đầu vào và phân loại mục tiêu chính của case vào 1 trong 6 Domain chuyên biệt để nạp tài liệu hướng dẫn tương ứng từ thư mục `.agents/skills/rea-interview/domains/`:

| Mã Domain | Tệp Hướng Dẫn Chuyên Sâu | Trọng Tâm Phỏng Vấn & Đặc Tả |
| :--- | :--- | :--- |
| `APP_OPTIMIZATION` | `domains/app-optimization.md` | Hiệu năng hệ thống (FPS, Jank), Cold Start, RAM/Heap, Pin, ANR, Baseline trước/sau. |
| `SECURITY_HARDENING` | `domains/security-hardening.md` | Tài sản mã nguồn, Auth & Session, Keystore, Cấm Cleartext, Root Policy, R8, Screen leak. |
| `FEATURE_ADDITION` | `domains/feature-addition.md` | Kết quả người dùng (Outcome) ➔ Quy chuẩn hành vi ➔ Đặc tả triển khai, Non-Goals, Schemas. |
| `FEATURE_OPTIMIZATION` | `domains/feature-optimization.md` | Nguyên nhân gốc rễ (RCA), Bảo toàn hành vi 100%, Mục tiêu KPI Before/After, Surgical fix. |
| `BUG_FIX` | `domains/bug-fix.md` | Kịch bản tái hiện (STR), Phân loại RCA, Bán kính tác động, Rào chắn kiểm thử tự động. |
| `UX_UI_IMPROVEMENT` | `domains/ux-ui-improvement.md` | Phân loại 3 nhánh (Visual / UX Flow / Refinement), Chế độ thiết kế, Anti-Slop, Copy Deck. |

---

## 3. ĐỘNG CƠ SÀNG LỌC CÂU HỎI (QUESTION NECESSITY ENGINE)

Mọi câu hỏi tiềm năng đều phải vượt qua chuỗi **8 bộ lọc tuần tự**. Nếu vi phạm bất kỳ bộ lọc tiêu cực nào hoặc không đáp ứng tiêu chí bắt buộc, câu hỏi **BỊ HỦY BỎ** hoặc **CHUYỂN THÀNH GIẢ ĐỊNH MẶC ĐỊNH**:

```
[Ý định hỏi] ──► [Filter 1: Known?] ────────► ĐÃ BIẾT? ────────► HUỶ BỎ
              ──► [Filter 2: Inspectable?] ──► TỰ ĐỌC ĐƯỢC? ───► TỰ ĐỌC & HUỶ BỎ
              ──► [Filter 3: Evidence?] ─────► ĐÃ CÓ BẰNG CHỨNG?► TRÍCH DẪN & HUỶ BỎ
              ──► [Filter 4: Impact?] ───────► KHÔNG ẢNH HƯỞNG?► HUỶ BỎ (TRIVIA)
              ──► [Filter 5: Risk?] ─────────► RỦI RO THẤP? ───► ÁP DỤNG GIẢ ĐỊNH AN TOÀN
              ──► [Filter 6: Reversibility?] ─► DỄ ĐẢO NGƯỢC? ──► ÁP DỤNG GIẢ ĐỊNH AN TOÀN
              ──► [Filter 7: Ownership?] ────► NGOÀI THẨM QUYỀN?► TỰ RA QUYẾT ĐỊNH KỸ THUẬT
              ──► [Filter 8: Timing?] ───────► CHƯA CẦN BÂY GIỜ?► HOÃN ĐẾN STAGE SAU
                                              │
                      ┌───────────────────────┘
                      ▼
            VƯỢT QUA CẢ 8 BỘ LỌC ──► ĐẶT CÂU HỎI NGẮN GỌN CHO NGƯỜI DÙNG
```

### Chi Tiết 8 Bộ Lọc:
1. **Filter 1 - Known (Đã biết)**: Thông tin đã có trong `02_YEU_CAU_CUA_TOI/ho-so-va-muc-tieu.md`, lịch sử trò chuyện, hoặc hồ sơ trước đó? Nếu CÓ ➔ **CẤM HỎI LẠI**.
2. **Filter 2 - Inspectable (Tự kiểm tra được)**: Thông tin có thể xác định rõ ràng qua phân tích tĩnh, đọc `AndroidManifest.xml`, `build.gradle`, assets, layout XML, hay mã nguồn gốc? Nếu CÓ ➔ **TỰ ĐỌC VÀ KHÔNG HỎI**.
3. **Filter 3 - Evidence (Bằng chứng thực tế)**: Đã có ảnh chụp màn hình thực tế (từ Bước 02), logcat hiện trạng, hoặc báo cáo Bước 04 chứng minh hành vi? Nếu CÓ ➔ **TRÍCH DẪN BẰNG CHỨNG, KHÔNG HỎI MƠ HỒ**.
4. **Filter 4 - Decision Impact (Ảnh hưởng quyết định)**: Câu trả lời có làm thay đổi trực tiếp kiến trúc, phạm vi, hoặc code ở Stage 04 không? Nếu KHÔNG (câu hỏi râu ria, hình thức) ➔ **LOẠI BỎ NGAY**.
5. **Filter 5 - Risk (Mức độ rủi ro)**: Có liên quan đến thất thoát dữ liệu, vi phạm pháp lý/bảo mật, hoặc hành động phá hủy không? Nếu RỦI RO CAO ➔ **BẮT BUỘC HỎI**. Nếu RỦI RO THẤP ➔ Tự áp dụng mặc định an toàn.
6. **Filter 6 - Reversibility (Tính thuận nghịch)**: Quyết định là cửa hai chiều (Two-Way Door - dễ sửa đổi sau bằng 1 dòng config) hay cửa một chiều (One-Way Door - thay đổi cấu trúc database nền tảng)? Nếu THUẬN NGHỊCH ➔ **CHỌN MẶC ĐỊNH AN TOÀN, GHI VÀO ASSUMPTION RECORD**.
7. **Filter 7 - Ownership (Thẩm quyền quyết định)**: Người dùng là chủ sản phẩm (Product Owner) định hướng giá trị nghiệp vụ, không phải kỹ sư triển khai. Không hỏi người dùng về thư viện nội bộ, pattern, hoặc cú pháp. Kỹ thuật thuộc thẩm quyền của Agent.
8. **Filter 8 - Timing (Đúng thời điểm)**: Thông tin này có cần thiết ngay trong Stage 03 để đóng băng đặc tả không, hay đến Stage 04/05 mới dùng? Nếu chưa cần ➔ **HOÃN LẠI (DEFER)**.

---

## 4. ĐỘNG CƠ THEO DÕI QUYẾT ĐỊNH & GIẢ ĐỊNH (DECISION & CONSTRAINT ENGINE)

Mọi diễn biến trong phỏng vấn phải được chuẩn hóa thành 3 loại bản ghi:

### 4.1 Question Record (Hồ Sơ Câu Hỏi)
Theo dõi các câu hỏi đã vượt qua 8 bộ lọc:
```markdown
- **Mã câu hỏi**: `Q-[DOMAIN]-[STT]`
- **Nội dung hỏi**: [Câu hỏi cô đọng bằng tiếng Việt đời thường]
- **Kết quả 8 bộ lọc**: [Đạt chuẩn Impact + One-Way Door / Risk]
- **Trạng thái**: `PENDING` | `ANSWERED` | `DEFERRED`
- **Câu trả lời nhận được**: [Tóm tắt ý của người dùng]
```

### 4.2 Decision Record (Hồ Sơ Quyết Định)
Đóng băng các quyết định đã được người dùng chốt hoặc thống nhất:
```markdown
- **Mã quyết định**: `DECISION-[DOMAIN]-[STT]`
- **Ngữ cảnh & Vấn đề**: [Vấn đề kỹ thuật / nghiệp vụ]
- **Quyết định đã chốt**: [Lựa chọn chính thức]
- **Hệ quả kiến trúc**: [Ảnh hưởng đến module nào ở Stage 04]
- **Trạng thái**: `CLOSED` (Đã chốt) | `FROZEN` (Đã đóng băng tại Gate 03)
```

### 4.3 Assumption Record (Hồ Sơ Giả Định Mặc Định)
Ghi nhận các quyết định hai chiều mà Agent tự chọn mặc định an toàn:
```markdown
- **Mã giả định**: `ASSUMPTION-[DOMAIN]-[STT]`
- **Hạng mục & Giá trị mặc định**: [Ví dụ: Giới hạn Cache 50MB, Debounce 300ms]
- **Cơ sở kỹ thuật**: [Best-practice của nền tảng]
- **Mức độ thuận nghịch**: `HIGH` (Dễ đảo ngược)
- **Nhiệm vụ kiểm chứng**: [Kịch bản kiểm thử ở Bước 10 / 12]
- **Trạng thái**: `ACCEPTED_BY_DEFAULT`
```

---

## 5. BƯỚC 06: QUY TRÌNH PHỎNG VẤN & THIẾT LẬP ART DIRECTION

### 5.1 Khảo Sát Nhu Cầu & Đọc Đầu Vào Đóng Băng
1. Đọc đồng thời 3 nguồn tài liệu đầu vào:
   - `02_YEU_CAU_CUA_TOI/ho-so-va-muc-tieu.md` (mong muốn ban đầu của người dùng).
   - `03_KET_QUA_KIEM_TRA/bao-cao-hien-trang.md` (hiện trạng ứng dụng gốc từ Bước 04).
   - `03_KET_QUA_KIEM_TRA/UNKNOWNS_AND_COVERAGE.md` (sổ theo dõi điểm mù từ Bước 05).
2. Cập nhật trạng thái chờ người dùng:
   - Ghi vào `.agents/state/active_case.json`: `current_phase = "STAGE_03_PRODUCT_DEFINITION"`, `current_step = "06_REA_INTERVIEW"`, `current_gate_status = "GATE_03_WAITING_USER_INPUT"`.

### 5.2 Phân Loại Chế Độ Khám Phá Thiết Kế (Design Exploration Mode)
Agent xác định chế độ phù hợp:
1. **`DESIGN_REUSE_EXACT`**:
   - Khi người dùng muốn làm bản sao 1-1 chính xác hoặc tái lập giao diện cũ.
   - **HÀNH ĐỘNG**: Tuyệt đối **KHÔNG ĐƯỢC ÉP BUỘC ĐỀ XUẤT 3 CONCEPT**. Trích xuất ngay bảng màu, kích thước từ UI cũ, chuyển thẳng sang lập đặc tả Bước 07.
2. **`DESIGN_STYLE_SPECIFIED`**:
   - Khi người dùng đã nêu rõ tên phong cách cụ thể (ví dụ: "Material You Dark", "Nordic Minimalist", "Cupertino iOS").
   - **HÀNH ĐỘNG**: Tuyệt đối **KHÔNG ĐƯỢC ÉP BUỘC ĐỀ XUẤT 3 CONCEPT**. Tuân thủ trực tiếp phong cách người dùng đã chọn để lập hồ sơ Art Direction và đặc tả.
3. **`DESIGN_STRUCTURAL_EXPLORATION`**:
   - Kích hoạt **DUY NHẤT** khi người dùng muốn tái thiết kế toàn diện, khám phá bố cục mới, hoặc chưa định hình phong cách cụ thể.
   - **HÀNH ĐỘNG**: Bắt buộc đề xuất **3 Concept có cấu trúc tổ chức thông tin khác biệt** (không chỉ đổi màu):
     * **Concept A (Task-First Focus)**: Tập trung tối đa vào hành động cốt lõi khi mở màn hình.
     * **Concept B (Content-First / Editorial)**: Dàn trang dạng bài viết/tạp chí; phân cấp chữ nghệ thuật và thoáng đãng.
     * **Concept C (Contextual / Progressive Flow)**: Màn hình biến đổi tuần tự thích ứng theo trạng thái hoàn thành của người dùng.

### 5.3 Thiết Lập Art Direction & Tự Phản Biện Chống UI Slop
Dù ở chế độ nào, Agent phải hoàn thiện 7 thành phần Art Direction theo `templates/12-ART-DIRECTION-TEMPLATE.md`:
1. **Product Personality**: Bản sắc sản phẩm (ví dụ: Tinh giản, Đáng tin cậy, Trầm tĩnh).
2. **Visual Thesis**: Ý tưởng thị giác chủ đạo xuyên suốt.
3. **Layout Philosophy**: Triết lý tổ chức không gian (ví dụ: Khối liền mạch, tận dụng khoảng trắng có chủ đích).
4. **Typography Hierarchy**: Phân cấp chữ có chủ đích (Display, Headline, Body, Label).
5. **Density & Spacing**: Mật độ thông tin trên màn hình (Compact / Regular / Spacious).
6. **Signature Element**: Một điểm nhấn nhận diện đặc trưng đáng nhớ.
7. **Forbidden Anti-patterns**: Các lối thiết kế sáo mòn cấm kỵ (card tràn lan vô nghĩa, gradient trôi nổi, icon trang trí thừa thãi).

### 5.4 Lệnh Phê Duyệt Bố Cục (Human Gate 1)
- Đối với `DESIGN_STRUCTURAL_EXPLORATION`: Người dùng chọn concept và xác nhận:
  👉 **`APPROVE SCREEN COMPOSITION`**
- Đối với `DESIGN_REUSE_EXACT` hoặc `DESIGN_STYLE_SPECIFIED`: Người dùng phê duyệt bố cục trực tiếp theo hướng dẫn hoặc tự động chuyển tiếp hợp lệ sang Bước 07.

---

## 6. BƯỚC 07: SPEC & DESIGN GATE (States, Copy Deck & Tokens)

Sau khi bố cục được thông qua, Agent chuyển sang Bước 07 để đóng băng toàn bộ hợp đồng đặc tả:

### 6.1 Bố Cục Màn Hình & Co Giãn (Screen Composition & Responsive Spec)
1. Xuất `03_KET_QUA_KIEM_TRA/01_SCREEN_COMPOSITION.md`:
   - Vị trí các thành phần và thứ tự ưu tiên thị giác.
   - Khoảng cách, phân vùng và cách tổ chức luồng mắt đọc.
2. Xuất `03_KET_QUA_KIEM_TRA/02_RESPONSIVE_SPEC.md`:
   - Quy chuẩn Responsive theo **Window Size Classes** (Compact, Medium, Expanded).
   - Khả năng tương thích Foldable Posture và Insets (Edge-to-Edge display).

### 6.2 Xử Lý Triệt Để 4 Trạng Thái Giao Diện (State Composition)
Xuất `03_KET_QUA_KIEM_TRA/03_STATE_COMPOSITION.md` xử lý đầy đủ:
1. **Loading State**: Skeleton loader tương ứng khung giao diện thật (không chỉ dùng vòng quay spinner mơ hồ).
2. **Empty State**: Minh họa rõ ràng + thông điệp thân thiện + Nút hành động kêu gọi (CTA) cụ thể.
3. **Success State**: Toast hoặc animation xác nhận hoàn thành tác vụ tức thì (<100ms feedback).
4. **Error / Recovery State**: Banner thông báo nguyên nhân bằng tiếng Việt đời thường + Nút "Thử lại", **bảo toàn 100% dữ liệu form người dùng đang nhập dở theo `RULE-INIT-001`**.
5. *Trạng thái đặc thù*: Quyền bị từ chối (`Permission Denied`), Mạng chập chờn (`Partial Data`), và Hộp thoại xác nhận phá hủy (`Destructive Confirmation`).

### 6.3 Soạn Thảo Copy Deck Thực Tế (CẤM Placeholder Slop)
Xuất `03_KET_QUA_KIEM_TRA/04_COPY_DECK.md` theo mẫu `templates/13-COPY-DECK-TEMPLATE.md`:
- **NGHIÊM CẤM**: `Lorem ipsum`, `Sample text`, hoặc các câu chào generic như `Welcome back!` ở mọi nơi.
- Định nghĩa nội dung văn bản thực tế cho toàn bộ nhãn, tiêu đề, nút bấm, thông báo lỗi bằng tiếng Việt chuẩn mực.
- Quy định giới hạn ký tự, cách xuống dòng, và độ dài dự phòng khi chuyển đổi ngôn ngữ.

### 6.4 Khóa Hợp Đồng Design Tokens 3 Tầng
Xuất `02_YEU_CAU_CUA_TOI/design.md` theo `templates/05-DESIGN-TOKEN-TEMPLATE.md`:
- **Tầng 1 (Primitive Tokens)**: Bảng màu Hex, Typography scale, Spacing (4dp grid), Radius, Shadows.
- **Tầng 2 (Semantic Tokens)**: Nút bấm (Primary, Secondary, Destructive), Input field, Cards, Header.
- **Tầng 3 (Platform Native Tokens)**: Ánh xạ chuẩn Android Jetpack Compose (`Theme.kt`, `Color.kt`) hoặc Web CSS `:root`.

### 6.5 Xuất Đặc Tả Sản Phẩm & Lệnh Phê Duyệt Đóng Băng (Human Gate 2)
1. Xuất tổng hợp đặc tả vào `03_KET_QUA_KIEM_TRA/dac-ta-yeu-cau-da-chot.md` theo `templates/02-SPEC-TEMPLATE.md`.
2. Trình bày cho người dùng phê duyệt:
   👉 **`APPROVE UI SPEC`**
3. Sau khi người dùng duyệt `APPROVE UI SPEC`:
   - Ghi nhận trạng thái hoàn thành Bước 07.
   - Chuyển giao ngay cho **`rea-plan`** tại Bước 08 để lập kế hoạch 6 Milestones và đóng băng đặc tả qua lệnh `FREEZE UI SPEC`.
