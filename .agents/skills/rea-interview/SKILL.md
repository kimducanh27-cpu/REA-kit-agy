---
name: rea-interview
description: Phỏng vấn làm rõ yêu cầu người dùng sau khi đã có báo cáo phân tích từ rea-scan, sổ Unknowns và file 02_YEU_CAU_CUA_TOI/ho-so-va-muc-tieu.md. Chốt Design System 3 tầng, lựa chọn Build Route (Route A Web Zero-Install, Route B Android Native, Route C Patch/Hybrid), đóng băng đặc tả sản phẩm và chia nhỏ kế hoạch triển khai nguyên tử. Phụ trách STAGE_03_PRODUCT_DEFINITION theo docs/WORKFLOW_LIFECYCLE.md.
---

# KỸ NĂNG: ĐỊNH HÌNH SẢN PHẨM & KẾ HOẠCH TRIỂN KHAI (REA-INTERVIEW)

Kỹ năng chuyên biệt cho **STAGE_03_PRODUCT_DEFINITION** theo khung chuẩn 6 Stage · 14 Bước tại `docs/WORKFLOW_LIFECYCLE.md`.
Phụ trách từ khâu đối thoại yêu cầu, lựa chọn hướng phát triển (Build Routes), đóng băng đặc tả đến lập kế hoạch triển khai nguyên tử để chuyển giao cho Stage 04.

---

## 1. QUY TRÌNH THỰC HIỆN 3 BƯỚC

### BƯỚC 06: REA INTERVIEW (Phỏng Vấn Người Dùng & Chốt Hướng Phát Triển)
1. Đọc đồng thời 3 nguồn tài liệu:
   - `02_YEU_CAU_CUA_TOI/ho-so-va-muc-tieu.md` (mong muốn cá nhân)
   - `03_KET_QUA_KIEM_TRA/bao-cao-hien-trang.md` (hiện trạng ứng dụng gốc)
   - `03_KET_QUA_KIEM_TRA/UNKNOWNS_AND_COVERAGE.md` (các điểm mù và rủi ro)
2. Đặt từ 3 đến 5 câu hỏi tiếng Việt đời thường, có sẵn gợi ý lựa chọn (A/B/C):
   - **Lựa chọn Build Route (3 Hướng Tái Tạo Mã Nguồn)**:
     * *Route A (Mặc định — Zero-Install Web App)*: Web App độc lập (`index.html`, `styles.css`, `app.js`) mở chạy ngay trên trình duyệt mà không cần cài đặt bất kỳ công cụ nào.
     * *Route B (Android Native Project)*: Ứng dụng Android chuẩn (khởi tạo qua Antigravity Android CLI `android create` hoặc template Gradle/Kotlin/Jetpack Compose), hỗ trợ build APK và chạy thử trực tiếp trên máy ảo AVD / Antigravity Device Hub.
     * *Route C (Patch APK / Resources hoặc Web/Hybrid)*: Vá tài nguyên/smali trực tiếp trên gói APK gốc, hoặc đóng gói ứng dụng Hybrid (Capacitor/PWA).
   - **Tương đồng hay Tối giản**: Muốn giữ nguyên luồng app cũ hay tinh gọn lại?
   - **Xử lý Unknowns**: Các chức năng bị mã hóa/chưa rõ có cần thay thế bằng chuẩn Web/Native hay mock data không?
   - **Giao diện & Trải nghiệm**: Chọn bảng màu nhận diện thương hiệu hay làm mới theo phong cách hiện đại?
   - **Ranh giới bảo mật**: App có cần kết nối server ngoài hay chạy 100% cục bộ?

### BƯỚC 07: SPEC & DESIGN GATE (Hợp Đồng Giao Diện & Đặc Tả Đóng Băng)
1. **Thiết lập Design System 3 tầng** tại `02_YEU_CAU_CUA_TOI/design.md`:
   - Tầng 1: Primitive Tokens (Màu sắc, Font, Spacing, Radius, Shadow cho cả Web CSS và Android Compose/XML).
   - Tầng 2: Semantic Components (Button, Card, Form Input, Header, Modal).
   - Tầng 3: 4 Trạng thái giao diện bắt buộc (`Loading`, `Empty`, `Success`, `Error`).
2. **Đóng băng đặc tả sản phẩm** theo `templates/02-SPEC-TEMPLATE.md` vào:
   👉 `03_KET_QUA_KIEM_TRA/dac-ta-yeu-cau-da-chot.md`.
   Bao gồm: Build Route đã chọn (Route A, Route B hoặc Route C), luồng nghiệp vụ, danh sách màn hình, tiêu chí nghiệm thu (Acceptance Criteria).

### BƯỚC 08: IMPLEMENTATION PLAN (Kế Hoạch Triển Khai Nguyên Tử)
1. Chia nhỏ toàn bộ dự án thành các nhiệm vụ nguyên tử (Atomic Tasks) độc lập theo đúng Build Route đã chọn.
2. Xác định rõ quan hệ phụ thuộc (Dependency Graph) và thứ tự thực hiện từ UI tĩnh đến Logic nghiệp vụ.
3. Xuất file kế hoạch theo `templates/07-IMPLEMENTATION-PLAN-TEMPLATE.md` vào:
   👉 `03_KET_QUA_KIEM_TRA/KE_HOACH_TRIEN_KHAI.md`.
4. **CỔNG 03 (Quality Gate 03: `gate_03_spec_frozen`)**:
   - Yêu cầu người dùng duyệt kế hoạch và đặc tả.
   - Khi được phê duyệt:
     * Cập nhật `active_case.json`: `gates.gate_03_spec_frozen = true`, `current_phase = "STAGE_03_PRODUCT_DEFINITION"`, `current_step = "08_IMPLEMENTATION_PLAN"`.
     * Đồng bộ bảng tiến độ trong `docs/PROGRESS.md`.
   - **Vòng lặp sửa sai (Reject Loop)**: Nếu người dùng không đồng ý, tạo bản `SPEC_v2.md` và lùi về Bước 06/07 để phỏng vấn lại. Tuyệt đối không xóa tài liệu cũ.

---

## 2. NGUYÊN TẮC GIAO TIẾP
- Ngôn ngữ: 100% tiếng Việt thân thiện, không dùng thuật ngữ kỹ thuật khó hiểu.
- Không hỏi dồn dập; nếu người dùng trả lời ngắn, AI tự hoàn thiện chi tiết theo hướng an toàn nhất và xin xác nhận.
