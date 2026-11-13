# BÁO CÁO KIỂM SOÁT CHẤT LƯỢNG MÃ NGUỒN (4 TẦNG KIỂM CHỨNG)
*Thời gian kiểm tra: [YYYY-MM-DD HH:mm] | Trạng thái tổng thể: [PASSED / FAILED]*

> **Triết lý kiểm soát chất lượng:**
> *"Đừng biến AI thành một lớp kiểm tra bổ sung cho mọi thứ. Hãy dùng công cụ xác định cho lỗi xác định; chỉ dùng AI ở phần cần suy luận."*

---

## 🏗️ TẦNG 1: KIẾN TRÚC & CẤU TRÚC CODE (ƯU TIÊN CAO)
*Mục tiêu: Thiết kế sao cho lỗi không thể xảy ra ngay từ đầu, ranh giới rõ ràng, dễ chạy.*

- [x] **Mô hình triển khai:** [Web App độc lập (Single-file HTML/CSS/JS) - Zero Install]
- [x] **Ranh giới dữ liệu:** [Toàn bộ dữ liệu lưu trữ cục bộ (LocalStorage/IndexedDB), không gửi ra ngoài]
- [x] **Tính khả dụng:** [Nhấp đúp chuột là mở được ngay trên trình duyệt mà không cần cài Node.js/Python]

---

## ⚙️ TẦNG 2: CÔNG CỤ XÁC ĐỊNH & STATIC ANALYSIS (DETERMINISTIC CHECKS)
*Mục tiêu: Bắt lỗi theo quy tắc xác định, có thể chạy lặp lại bằng script `.agents/scripts/verify_code.ps1`.*

| Hạng mục kiểm tra | Công cụ thực hiện | Kết quả thực tế | Trạng thái |
| :--- | :--- | :--- | :--- |
| **Cú pháp HTML & Cặp thẻ** | PowerShell DOM Parser | [Không có thẻ đóng/mở bị thiếu] | **PASS** |
| **Cú pháp JavaScript** | Node syntax check / AST token | [Cú pháp hợp lệ, không lỗi biên dịch] | **PASS** |
| **Quét rò rỉ Secret & API Key** | Deterministic Regex Scanner | [Không phát hiện chuỗi secret hoặc token lộ] | **PASS** |
| **Mã thoát của công cụ** | `.agents/scripts/verify_code.ps1` | `Exit Code: 0` | **PASS** |

---

## 🤖 TẦNG 3: AI RULES & ĐÁNH GIÁ NGỮ CẢNH (SEMANTIC EVALUATION)
*Mục tiêu: Đánh giá những phần cần hiểu ngữ cảnh, quy trình và ý định mà công cụ xác định chưa kiểm tra được.*

- [x] **Độ khớp với đặc tả yêu cầu:** Mã nguồn đã thực hiện đầy đủ [N] tính năng mới chốt tại `03_KET_QUA_KIEM_TRA/dac-ta-yeu-cau-da-chot.md`.
- [x] **Bảo toàn tính năng cũ:** Các tính năng ban đầu của ứng dụng gốc vẫn được giữ nguyên vẹn.
- [x] **Trải nghiệm giao diện (UX):** Giao diện thân thiện, dễ thao tác, có thông báo trạng thái rõ ràng khi người dùng bấm nút.

---

## 👤 TẦNG 4: NGHIỆM THU NGƯỜI DÙNG (HUMAN CODE REVIEW & ACCEPTANCE)
*Mục tiêu: Người dùng mở ứng dụng và nghiệm thu thực tế trên máy.*

1. **Cách kiểm tra:** Mở file `05_MA_NGUON_PHAT_TRIEN/index.html` trong trình duyệt.
2. **Các nút bấm cần thử nghiệm:**
   - [ ] Bấm nút [Tên chức năng 1] để kiểm tra kết quả.
   - [ ] Bấm nút [Tên chức năng 2] để kiểm tra lưu dữ liệu.
3. **Ý kiến phản hồi:** [Nếu chưa ưng ý, phản hồi lại cho AI để tinh chỉnh tiếp].
