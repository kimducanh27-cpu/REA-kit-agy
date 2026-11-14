---
name: rea-interview
description: Phụ trách độc quyền Bước 06 (REA Interview) và Bước 07 (Spec & Design Gate) trong STAGE_03 (Product Definition). Phỏng vấn người dùng từ 3-5 câu tiếng Việt đời thường, chốt Chiến lược phát triển (Strategies 1-4) và Lộ trình nền tảng (Build Routes A/B/C), khóa hợp đồng Design System 3 tầng tại 02_YEU_CAU_CUA_TOI/design.md và xuất đặc tả đóng băng vào 03_KET_QUA_KIEM_TRA/dac-ta-yeu-cau-da-chot.md.
---

# KỸ NĂNG: PHỎNG VẤN ĐỊNH HÌNH SẢN PHẨM & ĐÓNG BĂNG ĐẶC TẢ (REA-INTERVIEW)

Kỹ năng chuyên biệt cho **Bước 06 (`06_REA_INTERVIEW`)** và **Bước 07 (`07_SPEC_AND_DESIGN`)** thuộc **STAGE_03 · PRODUCT DEFINITION** theo `docs/WORKFLOW_LIFECYCLE.md`.
*(Lưu ý ranh giới: Bước 08 Lập kế hoạch triển khai 6 Vertical Slices & mở Cổng 03 do kỹ năng `rea-plan` đảm nhiệm riêng biệt).*

---

## 1. QUY TRÌNH THỰC HIỆN (BƯỚC 06 & BƯỚC 07)

### BƯỚC 06: REA INTERVIEW (Phỏng Vấn Người Dùng & Chốt Hướng Phát Triển)
1. **Đọc đồng thời 3 nguồn tài liệu đầu vào**:
   - `02_YEU_CAU_CUA_TOI/ho-so-va-muc-tieu.md` (mong muốn ban đầu của người dùng).
   - `03_KET_QUA_KIEM_TRA/bao-cao-hien-trang.md` (hiện trạng ứng dụng gốc từ Bước 04).
   - `03_KET_QUA_KIEM_TRA/UNKNOWNS_AND_COVERAGE.md` (sổ theo dõi điểm mù từ Bước 05).
2. **Cập nhật trạng thái chờ người dùng trước khi đặt câu hỏi**:
   - Ghi ngay vào `.agents/state/active_case.json`: `current_phase = "STAGE_03_PRODUCT_DEFINITION"`, `current_step = "06_REA_INTERVIEW"`, `current_gate_status = "GATE_03_WAITING_USER_INPUT"`.
3. **Đặt từ 3 đến 5 câu hỏi tiếng Việt đời thường, có gợi ý lựa chọn rõ ràng**:
   - **Câu 1 — Chiến lược phát triển mã nguồn (`build_strategy` — 4 lựa chọn)**:
     * *Strategy 1 (`STRATEGY_1_EXTEND`)*: Tiếp tục phát triển nối tiếp trên mã nguồn hiện tại (khi đã có source repo tốt).
     * *Strategy 2 (`STRATEGY_2_FEATURE_BRANCH`)*: Tạo nhánh riêng để phát triển cô lập tính năng mới.
     * *Strategy 3 (`STRATEGY_3_COMPATIBLE_CLEANROOM`)*: Xây dựng bản tương thích mới sạch sẽ dựa trên hành vi quan sát được.
     * *Strategy 4 (`STRATEGY_4_FULL_REWRITE`)*: Viết lại hoàn toàn kiến trúc mới từ đầu.
   - **Câu 2 — Lộ trình nền tảng đích (`build_route` — 3 lựa chọn)**:
     * *Route A (`ROUTE_A_WEB_ZERO_INSTALL` — Mặc định cho người non-tech)*: Web App độc lập (`index.html`, `styles.css`, `app.js`) nhấp đúp mở chạy ngay trên trình duyệt, không cần cài môi trường.
     * *Route B (`ROUTE_B_ANDROID_NATIVE`)*: Dự án Android Native chuẩn (khởi tạo qua Android CLI `android create` hoặc Gradle + Kotlin + Jetpack Compose) trong `05_MA_NGUON_PHAT_TRIEN/android/`.
     * *Route C (`ROUTE_C_PATCH_HYBRID`)*: Vá tài nguyên/smali trên gói APK hoặc đóng gói Hybrid (PWA/Capacitor).
   - **Câu 3 — Giải quyết các điểm mù (`Unknowns`)**: Chọn phương án thay thế bằng chuẩn mở, dùng mock data cục bộ hay lược bỏ đối với từng mã `UNK-XX` trong sổ Unknowns.
   - **Câu 4 — Tính năng & Giao diện**: Giữ/bỏ màn hình nào, chọn phong cách màu sắc nào?
   - **Câu 5 — Ranh giới dữ liệu & Mạng**: Chạy 100% cục bộ offline hay được phép kết nối API ngoài (nếu có API ngoài, ghi nhận rõ để mở cờ `-AllowHighRisk` ở Stage 04)?

### BƯỚC 07: SPEC & DESIGN GATE (Hợp Đồng Giao Diện & Đặc Tả Đóng Băng)
1. Sau khi người dùng trả lời, cập nhật `active_case.json`: `current_step = "07_SPEC_AND_DESIGN"`, lưu `build_strategy` và `build_route` đã chọn.
2. **Thiết lập Design System 3 tầng** tại `02_YEU_CAU_CUA_TOI/design.md` theo `templates/05-DESIGN-TOKEN-TEMPLATE.md`:
   - Tầng 1: Primitive Tokens (Màu sắc, Typography, Spacing, Radius, Shadow cho Web CSS `:root` hoặc Android Compose `Color.kt`/`Theme.kt`).
   - Tầng 2: Semantic Components (Button, Card, Input, Header, Modal/Dialog).
   - Tầng 3: 4 Trạng thái giao diện bắt buộc (`Loading`, `Empty`, `Success`, `Error Recovery` bảo toàn form input theo `RULE-INIT-001`).
3. **Xuất đặc tả sản phẩm** theo `templates/02-SPEC-TEMPLATE.md` vào:
   👉 `03_KET_QUA_KIEM_TRA/dac-ta-yeu-cau-da-chot.md`.
4. Chuyển giao ngay cho kỹ năng **`rea-plan`** để lập kế hoạch triển khai nguyên tử ở Bước 08.
