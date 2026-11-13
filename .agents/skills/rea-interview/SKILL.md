---
name: rea-interview
description: Phỏng vấn làm rõ yêu cầu người dùng sau khi đã có báo cáo phân tích từ rea-scan, sổ Unknowns và file 02_YEU_CAU_CUA_TOI/ho-so-va-muc-tieu.md. Chốt Design System 3 tầng, đặc tả sản phẩm và chia nhỏ kế hoạch triển khai nguyên tử. Phụ trách Phase 03 (Product Definition) theo docs/WORKFLOW_LIFECYCLE.md.
---

# KỸ NĂNG: ĐỊNH HÌNH SẢN PHẨM & KẾ HOẠCH TRIỂN KHAI (REA-INTERVIEW)

Kỹ năng chuyên biệt cho **Phase 03 (Product Definition)** theo khung chuẩn 6 Phase · 14 Bước tại `docs/WORKFLOW_LIFECYCLE.md`.
Phụ trách từ khâu đối thoại yêu cầu, đóng băng đặc tả đến lập kế hoạch triển khai nguyên tử để chuyển giao cho Phase 04.

---

## 1. QUY TRÌNH THỰC HIỆN 3 BƯỚC

### BƯỚC 06: REA INTERVIEW (Phỏng Vấn Người Dùng)
1. Đọc đồng thời 3 nguồn tài liệu:
   - `02_YEU_CAU_CUA_TOI/ho-so-va-muc-tieu.md` (mong muốn cá nhân)
   - `03_KET_QUA_KIEM_TRA/bao-cao-hien-trang.md` (hiện trạng ứng dụng gốc)
   - `03_KET_QUA_KIEM_TRA/UNKNOWNS_AND_COVERAGE.md` (các điểm mù và rủi ro)
2. Đặt từ 3 đến 5 câu hỏi tiếng Việt đời thường, có sẵn gợi ý lựa chọn (A/B/C):
   - **Tương đồng hay Tối giản**: Muốn giữ nguyên luồng app cũ hay tinh gọn lại?
   - **Xử lý Unknowns**: Các chức năng bị mã hóa/chưa rõ có cần thay thế bằng chuẩn Web hay mock data không?
   - **Giao diện & Trải nghiệm**: Chọn bảng màu nhận diện thương hiệu hay làm mới theo phong cách hiện đại?
   - **Ranh giới bảo mật**: App có cần kết nối server ngoài hay chạy 100% cục bộ (Zero-Install)?

### BƯỚC 07: SPEC & DESIGN GATE (Hợp Đồng Giao Diện & Đặc Tả Đóng Băng)
1. **Thiết lập Design System 3 tầng** tại `02_YEU_CAU_CUA_TOI/design.md`:
   - Tầng 1: Primitive Tokens (Màu sắc, Font, Spacing, Radius, Shadow).
   - Tầng 2: Semantic Components (Button, Card, Form Input, Header, Modal).
   - Tầng 3: 4 Trạng thái giao diện bắt buộc (`Loading`, `Empty`, `Success`, `Error`).
2. **Đóng băng đặc tả sản phẩm** theo `templates/02-SPEC-TEMPLATE.md` vào:
   👉 `03_KET_QUA_KIEM_TRA/dac-ta-yeu-cau-da-chot.md`.
   Bao gồm: Luồng nghiệp vụ, danh sách màn hình, tiêu chí nghiệm thu (Acceptance Criteria).

### BƯỚC 08: IMPLEMENTATION PLAN (Kế Hoạch Triển Khai Nguyên Tử)
1. Chia nhỏ toàn bộ dự án thành các nhiệm vụ nguyên tử (Atomic Tasks) độc lập.
2. Xác định rõ quan hệ phụ thuộc (Dependency Graph) và thứ tự thực hiện từ UI tĩnh đến Logic nghiệp vụ.
3. Xuất file kế hoạch theo `templates/07-IMPLEMENTATION-PLAN-TEMPLATE.md` vào:
   👉 `03_KET_QUA_KIEM_TRA/KE_HOACH_TRIEN_KHAI.md`.
4. **CỔNG 03 (Quality Gate 03: `gate_03_spec_frozen`)**:
   - Yêu cầu người dùng duyệt kế hoạch và đặc tả.
   - Khi được phê duyệt:
     * Cập nhật `active_case.json`: `gates.gate_03_spec_frozen = true`, `current_phase = "PHASE_03_PRODUCT_DEFINITION"`, `current_step = "08_IMPLEMENTATION_PLAN"`.
     * Đồng bộ bảng tiến độ trong `docs/PROGRESS.md`.
   - **Vòng lặp sửa sai (Reject Loop)**: Nếu người dùng không đồng ý, tạo bản `SPEC_v2.md` và lùi về Bước 06/07 để phỏng vấn lại. Tuyệt đối không xóa tài liệu cũ.

---

## 2. NGUYÊN TẮC GIAO TIẾP
- Ngôn ngữ: 100% tiếng Việt thân thiện, không dùng thuật ngữ kỹ thuật khó hiểu.
- Không hỏi dồn dập; nếu người dùng trả lời ngắn, AI tự hoàn thiện chi tiết theo hướng an toàn nhất và xin xác nhận.
