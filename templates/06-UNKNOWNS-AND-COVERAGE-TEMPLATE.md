# SỔ THEO DÕI ĐIỂM MÙ & ĐỘ PHỦ BẰNG CHỨNG DỊCH NGƯỢC (UNKNOWNS & COVERAGE LEDGER)
> **Dự án**: [Tên Ứng Dụng]  
> **Thời gian xuất**: YYYY-MM-DD HH:mm  
> **Phiên bản Audit**: v1.0  
> **Mã hồ sơ**: [Case ID trong active_case.json]  
> **Trạng thái Cổng**: CỔNG 02 (gate_02_audit_passed)

---

## 1. Điểm Số Bao Phủ Bằng Chứng (Evidence Coverage Score)

- **Tổng số thành phần phát hiện**: [Số lượng]
- **Số thành phần đã giải mã rõ ràng**: [Số lượng]
- **Tỷ lệ bao phủ (Coverage Score)**: [Ví dụ: 85%]
- **Đánh giá mức độ rủi ro chung**: `[ ] THẤP (>=80%)` | `[ ] TRUNG BÌNH (60-79%)` | `[ ] CAO (<60%)`

---

## 2. Bảng Danh Mục Điểm Mù Chưa Rõ (Unknowns Ledger)

*Liệt kê tất cả các thành phần bị làm rối (obfuscated), thư viện nhị phân (native .so/.dll), logic nghiệp vụ mã hóa hoặc endpoint chưa thể phân tích trọn vẹn:*

| Mã ID | Thành phần / Module | Hiện trạng ghi nhận | Giả thuyết hành vi | Các phương án kỹ thuật khả thi (Trình bày kèm hệ quả tại Bước 06) | Mức độ rủi ro |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `UNK-01` | [Ví dụ: libnative-crypto.so] | Mã máy nhị phân, không dịch ngược được C | Chứa logic mã hóa token phiên đăng nhập | **Tùy chọn A**: Tái sử dụng thư viện chuẩn của nền tảng đích (Android Keystore / Web Crypto).<br>**Tùy chọn B**: Giữ nguyên cơ chế mock trong môi trường thử nghiệm.<br>*Hệ quả*: Tùy chọn A cần cấu hình thêm, Tùy chọn B không phù hợp cho bản phát hành thực tế. | CAO |
| `UNK-02` | [Ví dụ: api.internal.endpoint] | URL mã hóa base64 trong asset | Endpoint đồng bộ lịch sử offline | **Tùy chọn A**: Kết nối trực tiếp máy chủ nếu có quyền truy cập.<br>**Tùy chọn B**: Tạm thời dùng mock data và cung cấp cấu hình endpoint linh hoạt.<br>*Hệ quả*: Tùy chọn A cần xác minh chính sách mạng, Tùy chọn B cần đồng bộ lại khi bàn giao. | VỪA |
| `UNK-03` | [Ví dụ: Custom UI Canvas] | Vẽ đồ thị trực tiếp bằng Canvas bytecode | Hiển thị biểu đồ realtime | **Tùy chọn A**: Tái hiện bằng thư viện đồ thị chuẩn (Canvas / Compose / SVG).<br>**Tùy chọn B**: Tối giản hóa thành bảng số liệu trực quan.<br>*Hệ quả*: Tùy chọn A tốn công lập trình hơn nhưng giữ trải nghiệm tương đương. | THẤP |

---

## 3. Rà Soát Bí Mật & Dữ Liệu Nhạy Cảm (Redaction & Secrets Audit)

- [x] **API Keys**: Đã rà soát và che mờ 100% thành `[REDACTED]`
- [x] **Mật khẩu / Private Keys cứng**: Đã loại bỏ hoặc thay thế bằng biến môi trường
- [x] **URL máy chủ nội bộ / IP riêng**: Đã gắn cờ kiểm duyệt
- [x] **Kiểm toán tĩnh có giới hạn phạm vi (Scoped Static Audit)**: Hoàn thành kiểm tra tĩnh có giới hạn; không phát hiện rủi ro trong phạm vi quét; vùng chưa kiểm toán đưa vào Sổ Unknowns

---

## 4. Kiến Nghị Lựa Chọn Cho Bước 06 (REA Interview)

*Các gợi ý dưới đây là ví dụ minh họa phương án kỹ thuật, KHÔNG PHẢI giải pháp mặc định đã định sẵn. Agent phải giải thích hệ quả bằng ngôn ngữ dễ hiểu trước khi ghi nhận quyết định của người dùng:*

1. **Phương án cho module nhị phân (UNK-01)**: Trình bày sự đánh đổi giữa việc chuẩn hóa bằng thư viện nền tảng chính thống hay giữ nguyên cơ chế stub tạm thời.
2. **Phương án cho kết nối mạng (UNK-02)**: Xác định rõ ràng nhu cầu nghiệp vụ của sản phẩm (chạy độc lập ngoại tuyến hay cần đồng bộ máy chủ nội bộ), không đánh đồng với quyền thực thi của công cụ.
3. **Phương án cho thành phần giao diện đặc thù (UNK-03)**: Trình bày các lựa chọn hiển thị trực quan và thu thập phản hồi về mức độ ưu tiên của người dùng.

---
*Tài liệu tự động tạo bởi Kỹ năng `rea-scan` / `rea-workflow` tại Bước 05.*
