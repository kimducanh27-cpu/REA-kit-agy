# REVIEW.MD — HỢP ĐỒNG KIỂM SOÁT, THẨM ĐỊNH THIẾT KẾ & CHẤT LƯỢNG MÃ NGUỒN
*(Chuẩn kiểm toán độc lập tham chiếu từ mô hình Anthropic Code Review Pipeline và Anti-Slop Design Architecture)*

Tài liệu này là quy chuẩn bắt buộc dành cho AI Agent khi đóng vai trò **Thẩm định viên độc lập (Independent Reviewer)** tại giai đoạn thiết kế giao diện (`STAGE_03`) và phát triển mã nguồn (`05_MA_NGUON_PHAT_TRIEN/`).

---

## 1. NGUYÊN TẮC CỐT LÕI (CORE PRINCIPLES)

1. **Tách biệt Tác giả & Thẩm định (Builder/Author vs. Reviewer)**:
   - Agent thiết kế hoặc sinh mã nguồn **tuyệt đối không được tự chứng nhận hoàn thành** nếu chưa qua lượt thẩm định độc lập.
   - Lượt thẩm định phải được thực thi trong một phiên ngữ cảnh độc lập (Fresh Context), không mang theo suy nghĩ chủ quan của tác giả thiết kế.

2. **Bộ lọc dẹp nhiễu — Chỉ báo cáo lỗi thực chất (High-Signal Filter)**:
   - **ĐƯỢC PHÉP BÁO CÁO**: Vi phạm Anti-Slop Contract, sao chép layout rập khuôn, chữ placeholder vô nghĩa, lỗi cú pháp, sai lệch đặc tả, vi phạm Design Tokens, thiếu 1 trong 4 trạng thái UI (Loading/Empty/Success/Error), rò rỉ secret/API key, phá vỡ accessibility.
   - **NGHIÊM CẤM BẮT BẺ RÂU RIA (NO NITPICKS)**: Không bắt bẻ phong cách viết mã cá nhân, không đòi thêm chú thích dài dòng, không bắt bẻ màu sắc khi đã nằm trong palette được duyệt.

3. **Khống chế hội tụ (Review Convergence Cap)**:
   - Tối đa **2 vòng lặp tự sửa**.
   - Nếu sau 2 lần sửa mà script `verify_code.ps1` hoặc Reviewer vẫn chưa PASS, bắt buộc dừng lại và thông báo trực diện cho người dùng điểm nghẽn, không được tự ý lặp vô tận đốt token.

---

## 2. THẨM ĐỊNH ĐỘC LẬP THIẾT KẾ GIAO DIỆN (STAGE_03 ANTI-SLOP DESIGN CRITIQUE)

Thực hiện tại Bước 07 trước khi người dùng cho phép đóng băng Cổng 03. Reviewer kiểm tra đối chiếu 10 tiêu chí đo lường định tính và định lượng:

| STT | Tiêu chí Kiểm Tra | Câu hỏi Thẩm Định Cốt Lõi | Tiêu chuẩn Chấp Nhận (Passing Standard) |
| :--- | :--- | :--- | :--- |
| 1 | **Distinctiveness** | Thiết kế có cá tính riêng hay chỉ là khuôn mẫu dashboard/card quen thuộc? | Bố cục xuất phát từ nội dung thực tế của app, không rập khuôn thẻ card dải gradient. |
| 2 | **Visual Hierarchy** | Người dùng có biết nhìn vào đâu trước và thao tác chính ở đâu không? | Phân cấp thị giác rõ ràng qua kích thước chữ, trọng lượng và khoảng cách; 1 hành động chính nổi bật. |
| 3 | **Composition** | Bố cục không gian có phục vụ thông tin hay chỉ để trang trí? | Không có khối giao diện nào tồn tại chỉ để lấp chỗ trống. Mọi phân vùng đều có mục đích rõ ràng. |
| 4 | **Consistency** | Có tuân thủ Design Tokens 3 tầng trong `design.md` không? | 100% màu sắc, khoảng cách, bán kính cong đều dùng token chuẩn, không hardcode mã màu lạ. |
| 5 | **Information Density** | Mật độ thông tin có cân đối không? | Không quá thưa thớt (loãng trang) và không quá chật chội (ngộp thông tin), phù hợp ngữ cảnh sử dụng. |
| 6 | **Typography & Copy Deck** | Nội dung có thực tế không? Có dính placeholder không? | **CẤM 100% `Lorem ipsum`, `Sample text`, hoặc `Welcome back!` vô nghĩa**. Mọi nhãn đều có Copy Deck thực tế kèm giới hạn ký tự. |
| 7 | **Platform Fit** | Giao diện có đúng quy luật Android Native / Material 3 không? | Tuân thủ Insets (Edge-to-Edge), Bottom Sheet chuẩn, Predictive Back, và Window Size Classes. |
| 8 | **Accessibility** | Có đạt quy chuẩn tiếp cận không? | Kích thước vùng bấm (Tap Target) tối thiểu 48x48dp, tương phản màu chữ đạt chuẩn WCAG AA, có nhãn cho TalkBack. |
| 9 | **Motion & States** | Có xử lý đủ 4 trạng thái giao diện và chuyển động hợp lý không? | Đủ Loading Skeleton, Empty CTA, Success, Error Recovery bảo toàn form (`RULE-INIT-001`), chuyển động mượt không lạm dụng. |
| 10 | **Edge Cases** | Nội dung dài, danh sách rỗng, màn hình gập có làm vỡ layout không? | Quy định rõ cách ngắt dòng, xuống dòng, và hành vi co giãn trên màn hình lớn / Foldables. |

### Cấu Trúc Báo Cáo Finding Chuẩn Mực:
Mỗi khi phát hiện vấn đề trong thiết kế, Reviewer phải ghi rõ:
- `Finding ID`: Ví dụ `DES-CRIT-01`
- `Severity`: `BLOCKER` (chặn đóng băng) | `WARNING` | `INFO`
- `Location`: Màn hình và thành phần cụ thể
- `Evidence`: Trích dẫn chi tiết vi phạm
- `Responsible Artifact`: Tệp tài liệu cần sửa đổi (ví dụ `01_SCREEN_COMPOSITION.md` hoặc `04_COPY_DECK.md`)
- `Remediation`: Hướng khắc phục cụ thể theo phong cách Anti-Slop

---

## 3. CHECKLIST THẨM ĐỊNH MÃ NGUỒN ĐỘC LẬP (STAGE_04 BUILD QA)

Thực hiện tại Bước 10 sau khi triển khai mã nguồn tại `05_MA_NGUON_PHAT_TRIEN/`:

### 🏗️ Tầng 1: Ranh giới Kiến trúc Đã Duyệt (Route A Zero-Install hoặc Route B Android Native)
- **Khi chọn Route A (Web App Zero-Install — Mặc định)**:
  * [ ] Ứng dụng là Web độc lập (HTML5 + Tailwind CSS CDN + Vanilla/Alpine JS).
  * [ ] Mở chạy được trực tiếp trên trình duyệt bằng cách nhấp đúp chuột vào file `index.html` hoặc `preview.html`.
  * [ ] Không đòi hỏi cài đặt môi trường phức tạp (Node.js, Python, Docker) từ phía máy người dùng.
- **Khi chọn Route B (Android Native Project)**:
  * [ ] Cấu trúc dự án Android Native chuẩn mực (khởi tạo qua Antigravity Android CLI `android create` hoặc Gradle/Kotlin/Jetpack Compose/XML).
  * [ ] Mã nguồn đặt đúng thư mục quy định tại `05_MA_NGUON_PHAT_TRIEN/android/`.
  * [ ] File cấu hình build (`build.gradle.kts` / `build.gradle`, `settings.gradle`) hợp lệ, biên dịch được bằng `./gradlew assembleDebug` hoặc công cụ Android CLI.
  * [ ] Sẵn sàng cài đặt và chạy thử trên máy ảo AVD hoặc thiết bị thật qua Antigravity Device Hub.

### ⚙️ Tầng 2: Kiểm tra Xác định (Deterministic Static Checks)
- [ ] Chạy script `.agents/scripts/verify_code.ps1` đạt **Exit Code 0**.
- [ ] Với Route A: Cặp thẻ HTML hợp lệ, không sót thẻ mở/đóng; cú pháp JavaScript hợp lệ, không gây lỗi cú pháp (SyntaxError).
- [ ] Với Route B: Cú pháp Kotlin/Java/XML hợp lệ, không có lỗi cấu trúc build hoặc dependencies chưa khai báo.
- [ ] Không có API key, password, secret chuỗi thô trong mã nguồn (đạt bộ lọc Regex Redaction).

### 🎨 Tầng 3.1: Hợp đồng Giao diện (Đối chiếu `02_YEU_CAU_CUA_TOI/design.md` & UI Spec)
- [ ] **Tokens (Tầng 1)**: Đã ánh xạ toàn bộ biến `--color-primary`, `--color-background`, `--radius-md` vào CSS `:root` và Tailwind classes. Cấm hardcode mã màu lạ.
- [ ] **Components (Tầng 2)**: Nút bấm, thẻ Card, ô Input, Header tuân thủ đúng quy chuẩn style mẫu.
- [ ] **4 Trạng thái UI (Tầng 3)**:
  * [ ] **Loading**: Có skeleton hoặc spinner, nút bấm bị disabled khi đang xử lý.
  * [ ] **Empty**: Có icon minh họa + lời giải thích + nút bấm hành động tạo mới (CTA).
  * [ ] **Success**: Có toast thông báo nổi hoặc tích xanh phản hồi sau khi lưu.
  * [ ] **Error Recovery**: Có banner đỏ giải thích nguyên nhân + nút "Thử lại", giữ nguyên dữ liệu đã gõ theo `RULE-INIT-001`.

### 📋 Tầng 3.2: Đặc tả Chức năng (Đối chiếu `03_.../dac-ta-yeu-cau-da-chot.md`)
- [ ] Thực hiện đầy đủ 100% các tính năng đã chốt trong bản đặc tả đóng băng (Lean Build).
- [ ] Không tự ý bịa thêm tính năng ngoài phạm vi (chống Over-engineering).
- [ ] Bảo toàn toàn bộ chức năng ban đầu của ứng dụng gốc (Surgical Patch).

### 🛡️ Tầng 3.3: Đối chiếu Nhật ký Bài học (.agents/state/learned_rules.json)
- [ ] Quét mã nguồn đối chiếu với danh sách các "Quy tắc cấm kỵ" từng bị người dùng hoàn tác trước đây.
- [ ] Xác nhận không lặp lại bất kỳ lỗi sai nào trong quá khứ.

---

## 4. PHÂN BIỆT RẠCH RÒI: PROCESS 07 DESIGN CRITIQUE VS PROCESS 08 VALIDATION

- **Process 07 (Design Quality & Anti-Slop Critique)**: Đánh giá chất lượng thẩm mỹ, cá tính sản phẩm, tính độc đáo, sự tinh tế của trạng thái UI và nội dung Copy Deck thực tế. Đảm bảo giao diện không rập khuôn và có hồn.
- **Process 08 (Mechanical Validation & Traceability)**: Đánh giá cơ học tính toàn vẹn của chuỗi tài liệu từ đầu đến cuối:
  $$\text{Target Binary / Baseline} \longrightarrow \text{Evidence} \longrightarrow \text{Feature} \longrightarrow \text{Spec} \longrightarrow \text{Composition} \longrightarrow \text{Code} \longrightarrow \text{Test Evidence}$$
  Kiểm tra khớp mã băm SHA-256, không thiếu sót màn hình hay trạng thái nào, và chứng minh mọi tuyên bố đều có bằng chứng ghi nhận.
