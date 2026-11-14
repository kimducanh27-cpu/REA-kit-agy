# REVIEW.MD — HỢP ĐỒNG KIỂM SOÁT & THẨM ĐỊNH CHẤT LƯỢNG MÃ NGUỒN
*(Chuẩn kiểm toán độc lập tham chiếu từ mô hình Anthropic Code Review Pipeline và app-adr-ui)*

Tài liệu này là quy chuẩn bắt buộc dành cho AI Agent khi đóng vai trò **Thẩm định viên độc lập (Independent Reviewer)** tại giai đoạn phát triển mã nguồn (`05_MA_NGUON_PHAT_TRIEN/`).

---

## 1. NGUYÊN TẮC CỐT LÕI (CORE PRINCIPLES)

1. **Tách biệt Tác giả & Thẩm định (Builder vs. Reviewer)**:
   - Agent sinh mã nguồn không được tự chứng nhận hoàn thành nếu chưa qua lượt thẩm định độc lập.
   - Lượt thẩm định phải đọc mã nguồn với tư duy kiểm toán khách quan, đối chiếu từng dòng với hợp đồng giao diện và đặc tả.

2. **Bộ lọc dẹp nhiễu — Chỉ báo cáo lỗi thực chất (High-Signal Filter)**:
   - **ĐƯỢC PHÉP BÁO CÁO**: Lỗi cú pháp, sai lệch tính năng so với đặc tả, vi phạm Design Tokens, thiếu 1 trong 4 trạng thái UI (Loading/Empty/Success/Error), rò rỉ secret/API key, mất tính năng cũ.
   - **NGHIÊM CẤM BẮT BẺ RÂU RIA (NO NITPICKS)**: Tuyệt đối không bắt bẻ phong cách viết mã (code style), không đòi thêm chú thích (comments), không bắt tách file CSS/JS riêng nếu không có lỗi, không bình luận về sở thích cá nhân làm người non-tech hoang mang.

3. **Khống chế hội tụ (Review Convergence Cap)**:
   - Tối đa **2 vòng lặp tự sửa**.
   - Nếu sau 2 lần sửa mà script `verify_code.ps1` hoặc Reviewer vẫn chưa PASS, bắt buộc dừng lại và thông báo trực diện cho người dùng điểm nghẽn, không được tự ý lặp vô tận đốt token.

---

## 2. CHECKLIST THẨM ĐỊNH ĐỘC LẬP 4 TẦNG

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

### 🎨 Tầng 3.1: Hợp đồng Giao diện (Đối chiếu `02_YEU_CAU_CUA_TOI/design.md`)
- [ ] **Tokens (Tầng 1)**: Đã ánh xạ toàn bộ biến `--color-primary`, `--color-background`, `--radius-md` vào CSS `:root` và Tailwind classes. Cấm hardcode mã màu lạ.
- [ ] **Components (Tầng 2)**: Nút bấm, thẻ Card, ô Input, Header tuân thủ đúng quy chuẩn style mẫu.
- [ ] **4 Trạng thái UI (Tầng 3)**:
  * [ ] **Loading**: Có skeleton hoặc spinner, nút bấm bị disabled khi đang xử lý.
  * [ ] **Empty**: Có icon minh họa + lời giải thích + nút bấm hành động tạo mới (CTA).
  * [ ] **Success**: Có toast thông báo nổi hoặc tích xanh phản hồi sau khi lưu.
  * [ ] **Error Recovery**: Có banner đỏ giải thích nguyên nhân + nút "Thử lại", giữ nguyên dữ liệu đã gõ.

### 📋 Tầng 3.2: Đặc tả Chức năng (Đối chiếu `03_.../dac-ta-yeu-cau-da-chot.md`)
- [ ] Thực hiện đầy đủ 100% các tính năng đã chốt trong bản đặc tả đóng băng (Lean Build).
- [ ] Không tự ý bịa thêm tính năng ngoài phạm vi (chống Over-engineering).
- [ ] Bảo toàn toàn bộ chức năng ban đầu của ứng dụng gốc (Surgical Patch).

### 🛡️ Tầng 3.3: Đối chiếu Nhật ký Bài học (.agents/state/learned_rules.json)
- [ ] Quét mã nguồn đối chiếu với danh sách các "Quy tắc cấm kỵ" từng bị người dùng hoàn tác trước đây.
- [ ] Xác nhận không lặp lại bất kỳ lỗi sai nào trong quá khứ.

---

## 3. PHÂN TẦNG RỦI RO & BÀN GIAO (RISK TIERING)

| Cấp độ rủi ro | Dấu hiệu nhận diện | Quy trình nghiệm thu |
| :--- | :--- | :--- |
| **THẤP (Low Risk)** | Chỉ sửa màu sắc, font chữ, nhãn chữ (labels), chỉnh style CSS | Tự động duyệt sau khi Tầng 2 đạt Exit Code 0 |
| **VỪA (Medium Risk)** | Thêm màn hình mới, form tính toán, lưu trữ dữ liệu cục bộ LocalStorage | Cung cấp checklist 2-3 bước để người dùng nhấp thử |
| **CAO (High Risk)** | Gọi API mạng ra ngoài, nạp thư viện mới, lưu mật khẩu/dữ liệu nhạy cảm | Cảnh báo đỏ nổi bật, bắt buộc người dùng xác nhận thủ công mới kích hoạt |

---

## 4. QUY TRÌNH XEM TRƯỚC THEO GIAI ĐOẠN (STAGED PREVIEW)
1. Khi cập nhật ứng dụng đã có, AI xuất ra `05_MA_NGUON_PHAT_TRIEN/preview.html`.
2. Giữ nguyên `05_MA_NGUON_PHAT_TRIEN/index.html` ổn định.
3. Người dùng mở `preview.html` xem thử.
4. Chỉ khi người dùng duyệt, AI mới chuyển `preview.html` thành `index.html` chính thức.
5. Nếu người dùng không ưng ý: nhấp đúp `HOAN_TAC.bat` để khôi phục 100%.
