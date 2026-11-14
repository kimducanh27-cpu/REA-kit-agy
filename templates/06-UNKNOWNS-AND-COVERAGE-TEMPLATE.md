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

| Mã ID | Thành phần / Module | Hiện trạng ghi nhận | Giả thuyết hành vi | Phương án xử lý (Tại Bước 06 Interview) | Mức độ rủi ro |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `UNK-01` | [Ví dụ: libnative-crypto.so] | Mã máy nhị phân, không dịch ngược được C | Chứa logic mã hóa token phiên đăng nhập | Thay thế bằng chuẩn Web Crypto API tiêu chuẩn | CAO |
| `UNK-02` | [Ví dụ: api.internal.endpoint] | URL mã hóa base64 trong asset | Endpoint đồng bộ lịch sử offline | Giữ nguyên mock data trong Web App mới | VỪA |
| `UNK-03` | [Ví dụ: Custom UI Canvas] | Vẽ đồ thị trực tiếp bằng Canvas bytecode | Hiển thị biểu đồ realtime | Dùng Chart.js hoặc SVG thuần viết lại | THẤP |

---

## 3. Rà Soát Bí Mật & Dữ Liệu Nhạy Cảm (Redaction & Secrets Audit)

- [x] **API Keys**: Đã rà soát và che mờ 100% thành `[REDACTED]`
- [x] **Mật khẩu / Private Keys cứng**: Đã loại bỏ hoặc thay thế bằng biến môi trường
- [x] **URL máy chủ nội bộ / IP riêng**: Đã gắn cờ kiểm duyệt
- [x] **Kiểm toán tĩnh có giới hạn phạm vi (Scoped Static Audit)**: Hoàn thành kiểm tra tĩnh có giới hạn; không phát hiện rủi ro trong phạm vi quét; vùng chưa kiểm toán đưa vào Sổ Unknowns

---

## 4. Kiến Nghị Cho Bước 06 (REA Interview)

1. **Câu hỏi trọng tâm 1**: [Ví dụ: Với module UNK-01, bạn muốn viết lại bằng Web Crypto chuẩn hay dùng mock dữ liệu?]
2. **Câu hỏi trọng tâm 2**: [Ví dụ: Tính năng biểu đồ UNK-03 bạn có muốn nâng cấp giao diện hiện đại hơn không?]
3. **Câu hỏi trọng tâm 3**: [Ví dụ: App mới có cần kết nối backend gốc hay chạy 100% offline trên trình duyệt?]

---
*Tài liệu tự động tạo bởi Kỹ năng `rea-scan` / `rea-workflow` tại Bước 05.*
