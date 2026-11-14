---
description: Quy chuẩn triển khai mã nguồn Stage 04: phân định Build Routes (Zero-Install vs Native), bắt buộc thẩm định xác định bằng verify_code.ps1, phân tầng rủi ro tự động và khống chế vòng lặp tự sửa.
globs: "05_MA_NGUON_PHAT_TRIEN/**, prompts/04-TAB-IMPLEMENTATION.md, .agents/scripts/verify_code.ps1"
trigger: model_decision
---

# QUY TẮC TRIỂN KHAI MÃ NGUỒN & KIỂM ĐỊNH XÁC ĐỊNH (IMPLEMENTATION & BUILD QA)

Tài liệu này xác lập các nguyên tắc kỹ thuật bắt buộc trong **STAGE 04 · IMPLEMENTATION** (Bước 09–10). Mọi mã nguồn sinh ra phải có tính xác định cao, tuân thủ đúng Build Route đã duyệt và vượt qua quy trình kiểm định chất lượng tự động.

---

## 1. Quản Trị Nhánh Xây Dựng (Build Routes Governance)

Trước khi thực hiện bất kỳ thao tác viết mã nào, Agent **BẮT BUỘC** kiểm tra trường `build_route` trong `.agents/state/active_case.json` và snapshot mã nguồn vào `05_MA_NGUON_PHAT_TRIEN/.backup/`.

### Route A: Zero-Install Web App (Mặc định cho trải nghiệm nhẹ)
1. **Triết lý Zero-Install**:
   - Ứng dụng phải bao gồm các file tiêu chuẩn: `index.html`, `styles.css`, `app.js` (hoặc module chuẩn ES6).
   - **CẤM TUYỆT ĐỐI**: Bắt buộc người dùng cài đặt thêm môi trường phức tạp (Node.js, npm build, webpack, yarn) chỉ để mở sản phẩm. Người dùng chỉ cần nhấp đúp chuột mở trực tiếp `index.html` trong trình duyệt là ứng dụng phải hoạt động bình thường.
2. **Tính độc lập & Ngoại tuyến (Self-Contained & Offline-First)**:
   - Toàn bộ thư viện JavaScript hoặc kiểu font phải được nhúng trực tiếp hoặc có cơ chế chạy ngoại tuyến, không để giao diện bị vỡ khi mất kết nối Internet.

### Route B: Android Native Project (Tái tạo chuẩn nền tảng)
1. **Cấu trúc Gradle chuẩn hóa**:
   - Triển khai đầy đủ mã nguồn trong thư mục `05_MA_NGUON_PHAT_TRIEN/android/`:
     * Thư mục mã: `app/src/main/java/` (hoặc `kotlin/`).
     * Thư mục tài nguyên: `app/src/main/res/` (layout, values, drawables).
     * `AndroidManifest.xml` hợp lệ với đầy đủ thẻ đóng.
     * Cấu hình biên dịch `build.gradle.kts` (hoặc `build.gradle`) cân bằng ngoặc nhọn.
2. **Tương thích Android CLI**:
   - Đảm bảo dự án sẵn sàng để biên dịch và triển khai lên máy ảo AVD hoặc thiết bị thật qua Antigravity Device Hub.

### Route C: Patch APK / Resources hoặc Hybrid
- Áp dụng khi người dùng yêu cầu vá trực tiếp gói APK gốc hoặc đóng gói wrapper lai (PWA/Capacitor). Phải kiểm tra tính toàn vẹn chữ ký và tài nguyên trước khi xuất bản.
- **Tiêu chuẩn bắt buộc Android 15 (16 KB Page-Alignment)**:
  * Thư viện chia sẻ native (`.so`) phải được biên dịch với căn chỉnh ELF `PT_LOAD` đạt `p_align = 0x4000` (NDK r27+ / r28, kiểm tra bằng `readelf -l <lib.so> | grep LOAD`).
  * Khi đóng gói APK, bắt buộc sử dụng `zipalign -P 16 -f -v 4 input.apk output_aligned.apk` để căn chỉnh các tệp `.so` không nén theo bội số 16 KiB, sau đó xác nhận lại bằng `zipalign -c -P 16 -v 4 output_aligned.apk`.

---

## 2. Bắt Buộc Thẩm Định Xác Định Bằng `verify_code.ps1` (Deterministic QA Enforcement)

Trước khi yêu cầu mở Cổng 04, Agent **BẮT BUỘC PHẢI CHẠY**:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".agents\scripts\verify_code.ps1"
```

Script này thực thi 6 tầng kiểm tra cơ học, Agent không được bỏ qua bất kỳ tiêu chí nào:

1. **Kiểm tra sự tồn tại & Không rỗng**:
   - Thư mục đích `05_MA_NGUON_PHAT_TRIEN/` không được rỗng và không được chỉ chứa file rỗng `.gitkeep`.

2. **Kiểm tra cân bằng cú pháp (Syntax & Tag Balance)**:
   - Các file HTML phải có đầy đủ cặp thẻ mở/đóng (`<html>`, `<div>`, `<script>`, `<style>`).
   - Các file JavaScript/TypeScript phải cân bằng hoàn toàn số lượng ngoặc nhọn `{}` và ngoặc đơn `()`.
   - Các file AndroidManifest.xml phải được phân tích cú pháp hợp lệ bằng bộ phân tích XML chuẩn (`[xml]`).
   - Các file Gradle/Groovy/Kotlin Script phải cân bằng ngoặc nhọn (sử dụng regex single-pass loại trừ chuỗi đa dòng `"""..."""` và comment).

3. **Quét rò rỉ dữ liệu nhạy cảm tự động (Automated Secret Scanner)**:
   - Quét qua toàn bộ file mã nguồn và tệp báo cáo.
   - Bắt buộc dấu nháy cho giá trị gán bí mật (tránh bắt nhầm khai báo kiểu Kotlin `param: String`).
   - Bổ sung quét giải mã Base64 (chuỗi dài >= 24 ký tự), kiểm tra Shannon Entropy (>= 4.5) và mảng byte Hex bí mật.
   - Phát hiện chuỗi API Key thô (AWS `AKIA...`, Private Keys, JWT token, Password thô chưa che mờ `[REDACTED]`) ➔ **ĐÁNH TRƯỢT NGAY LẬP TỨC (FAIL EXIT 1)**.

---

## 3. Phân Tầng Rủi Ro Tự Động (Automated Risk Classifier Standards)

Hệ thống phân tầng rủi ro theo 3 cấp độ dựa trên mã nguồn thực tế:

| Cấp Độ Rủi Ro | Dấu Hiệu Nhận Diện | Hành Động Quản Trị Của Agent |
| :--- | :--- | :--- |
| **LOW RISK** | Mã nguồn thuần giao diện tĩnh, chỉ xử lý DOM cơ bản, không có API mạng hay database. | Tự động thông qua sau khi kiểm tra cú pháp và secret scan thành công. |
| **MEDIUM RISK** | Có sử dụng `localStorage`, `sessionStorage`, `IndexedDB`, `SharedPreferences`, `Room`, `SQLite`, hoặc xử lý form submit. | Yêu cầu đối chiếu checklist dữ liệu cục bộ; kiểm tra không lưu trữ mật khẩu chưa mã hóa. |
| **HIGH RISK** | Gọi mạng ngoài (`fetch`, `XMLHttpRequest`, `WebSocket`, `OkHttpClient`, `Retrofit`), thực thi mã động phân biệt hoa thường (`eval`, `new Function`, `window.Function`, `DexClassLoader`), gọi lệnh shell hệ thống (`exec`, `ProcessBuilder`), hoặc gọi HTTP không mã hóa (Cleartext HTTP). | **CHẶN ĐỨNG CỔNG 04 (HARD BLOCK)**. Nếu tính năng này nằm trong đặc tả đã duyệt, Agent phải chạy với cờ `-AllowHighRisk` kèm biên bản giải trình rõ ràng cho người dùng. |

---

## 4. Khống Chế Vòng Lặp Tự Sửa Lỗi (Review Convergence Cap)

1. **Giới hạn 2 vòng lặp (Max 2 Rounds)**:
   - Nếu `verify_code.ps1` trả về lỗi cú pháp hoặc rủi ro, Agent được phép tự phân tích lỗi và sửa mã nguồn tối đa **2 vòng**.
   - Nếu sau 2 vòng tự sửa mà bài kiểm tra vẫn thất bại:
     * **CẤM**: Tiếp tục sửa trong vòng lặp vô tận gây cạn kiệt token và quota.
     * **BẮT BUỘC**: Dừng lại, giữ nguyên snapshot sao lưu an toàn gần nhất, và báo cáo nguyên nhân chi tiết cho người dùng xin ý kiến chỉ đạo.

---

## 5. Điều Kiện Mở Cổng 04 (`gate_04_build_qa_passed`)

Cổng 04 chỉ được chuyển sang trạng thái `PASS` khi:
1. `verify_code.ps1` trả về mã thoát `0` (Success).
2. Toàn bộ Design Tokens từ `02_YEU_CAU_CUA_TOI/design.md` được phản ánh đầy đủ trong mã nguồn.
3. Xuất bản báo cáo kiểm thử độc lập vào `03_KET_QUA_KIEM_TRA/KET_QUA_KIEM_THU.md`.
