# BÁO CÁO KIỂM SOÁT CHẤT LƯỢNG MÃ NGUỒN (ANTHROPIC GOVERNANCE PIPELINE)
*Thời gian kiểm tra: [YYYY-MM-DD HH:mm] | Trạng thái tổng thể: [PASSED / FAILED]*

> **Triết lý kiểm soát chất lượng (Tham chiếu Anthropic Code Review & app-adr-ui):**
> *"Dùng công cụ xác định cho lỗi xác định; dùng AI độc lập cho phần suy luận; phân tầng rủi ro để con người nghiệm thu đúng trọng tâm; và luôn có chốt chặn hoàn tác (Rollback)."*

---

## 🚦 THÔNG TIN ĐIỀU HÀNH & PHÂN TẦNG RỦI RO (RISK TIERING)
- **Cấp độ rủi ro:** [Chọn: MỨC THẤP (Low Risk - UI/Text) / MỨC VỪA (Medium Risk - Logic/Form) / MỨC CAO (High Risk - API/Dữ liệu nhạy cảm)]
- **Vòng thẩm định (Convergence Cap):** [Vòng 1 / Vòng 2 — Tối đa 2 vòng tự sửa để chống lặp vô tận]
- **Bản sao lưu hoàn tác (Rollback Snapshot):** `05_MA_NGUON_PHAT_TRIEN/.backup/[TIMESTAMP_SNAPSHOT]/` *(Đã sao lưu trước khi sửa)*
- **Lệnh khôi phục tức thì:** Nhấp đúp chuột vào file `HOAN_TAC.bat` nếu muốn quay về phiên bản trước.

---

## 🏗️ TẦNG 1: KIẾN TRÚC & CẤU TRÚC CODE (ZERO-INSTALL WEB)
*Mục tiêu: Thiết kế sao cho lỗi không thể xảy ra ngay từ đầu, ranh giới rõ ràng, dễ chạy.*

- [x] **Mô hình triển khai:** Web App độc lập (Single-file HTML5 + Tailwind CSS CDN + Alpine/Vanilla JS).
- [x] **Ranh giới dữ liệu:** Dữ liệu lưu trữ cục bộ trên máy (LocalStorage/IndexedDB), không gửi ra ngoài trái phép.
- [x] **Khả dụng tức thì:** Nhấp đúp chuột vào file `index.html` mở chạy ngay trên trình duyệt mà không cần cài Node.js, Python hay Docker.

---

## ⚙️ TẦNG 2: CÔNG CỤ XÁC ĐỊNH & STATIC ANALYSIS (DETERMINISTIC CHECKS)
*Mục tiêu: Bắt lỗi theo quy tắc xác định bằng script `.agents/scripts/verify_code.ps1` (Exit Code 0/1).*

| Hạng mục kiểm tra | Công cụ thực hiện | Kết quả thực tế | Trạng thái |
| :--- | :--- | :--- | :--- |
| **Cú pháp HTML & Cặp thẻ** | PowerShell DOM Parser | [Không có thẻ đóng/mở bị thiếu] | **PASS** |
| **Cú pháp JavaScript** | Node syntax check / AST token | [Cú pháp hợp lệ, không lỗi runtime cơ bản] | **PASS** |
| **Quét rò rỉ Secret & API Key** | Deterministic Regex Scanner | [Không phát hiện token, mật khẩu hoặc secret lộ] | **PASS** |
| **Mã thoát của công cụ** | `.agents/scripts/verify_code.ps1` | `Exit Code: 0` | **PASS** |

---

## 🤖 TẦNG 3: AI RULES & THẨM ĐỊNH ĐỘC LẬP (INDEPENDENT REVIEWER — ANTHROPIC MODEL)
*Mục tiêu: Tách biệt vai trò Builder và Reviewer để loại bỏ thiên kiến xác nhận của AI.*

### 3.1. Trục Tiêu chuẩn Giao diện (Standards Review — Đối chiếu `02_YEU_CAU_CUA_TOI/design.md`)
- [x] **Tầng 1 (Tokens):** Ánh xạ đầy đủ biến màu `--color-primary`, font chữ, bo góc vào CSS `:root` và Tailwind classes, không hardcode mã màu lung tung.
- [x] **Tầng 2 (Components):** Các nút bấm, thẻ card, ô nhập liệu tuân thủ đúng quy chuẩn kích thước và hiệu ứng hover/focus.
- [x] **Tầng 3 (UI States):** Triển khai đủ 4 trạng thái bắt buộc:
  * *Loading*: Có hiệu ứng khung xương (skeleton) hoặc vòng xoay khi tải.
  * *Empty*: Có biểu tượng minh họa và nút bấm kêu gọi hành động (CTA) tạo mới.
  * *Success*: Có thông báo nổi (toast) xác nhận lưu thành công.
  * *Error Recovery*: Có banner báo lỗi rõ ràng và nút "Thử lại", giữ nguyên dữ liệu đã gõ.

### 3.2. Trục Đặc tả Chức năng (Spec Review — Đối chiếu `03_.../dac-ta-yeu-cau-da-chot.md`)
- [x] **Đúng phạm vi (Lean Build):** Triển khai đầy đủ [N] tính năng đã chốt trong đặc tả, tuyệt đối không tự ý phình tính năng ngoài luồng.
- [x] **Bảo toàn tính năng cũ (Surgical Patch):** Logic nghiệp vụ của app gốc được duy trì nguyên vẹn, không gây lỗi hồi quy (regression).

---

## 👤 TẦNG 4: NGHIỆM THU NGƯỜI DÙNG DỰA TRÊN RỦI RO (RISK-TIERED ACCEPTANCE)
*Mục tiêu: Người dùng kiểm tra trực quan mà không bị quá tải kỹ thuật.*

1. **Cách kiểm tra nhanh:**
   - Nhấp đúp chuột vào file `05_MA_NGUON_PHAT_TRIEN/index.html` để mở app.
2. **Danh sách các tính năng cần nhấp thử:**
   - [ ] **Thao tác 1:** [Tên chức năng 1] ➔ Kiểm tra kết quả hiển thị trên màn hình.
   - [ ] **Thao tác 2:** [Tên chức năng 2] ➔ Kiểm tra dữ liệu được lưu đúng.
3. **Chốt chặn an toàn (Rollback):**
   - Nếu chạy thử thấy không vừa ý hoặc phát sinh lỗi lạ:
     👉 Nhấp đúp vào file **`HOAN_TAC.bat`** ở thư mục gốc để khôi phục 100% về phiên bản chạy tốt trước đó!
