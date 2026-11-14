# ĐẶC TẢ YÊU CẦU PHÁT TRIỂN ỨNG DỤNG (FROZEN SPECIFICATION)
> **Dự án**: [Tên dự án mới]  
> **Thời gian chốt**: YYYY-MM-DD HH:mm  
> **Trạng thái**: ĐÃ ĐÓNG BĂNG (FROZEN SPEC — CỔNG 03)  
> **Quy chuẩn**: Anti-Slop Design Architecture · REA-kit-agy v1.1

---

## 1. Mục Tiêu & Định Tuyến Phát Triển

- **Chiến lược phát triển mã nguồn (`development_strategy`)**: `[ ] EXTEND` | `[ ] FEATURE_BRANCH` | `[ ] COMPATIBLE_CLEANROOM` | `[ ] FULL_REWRITE`
- **Nền tảng bàn giao (`delivery_platform`)**: `[ ] Route A (Web App Zero-Install)` | `[ ] Route B (Android Native Project)` | `[ ] Route C (Patch Hybrid)`
- **Lý do lựa chọn chiến lược**: [Nêu rõ lý do kỹ thuật, khả năng tái sử dụng mã nguồn và đối tượng người dùng]

---

## 2. Danh Mục Hồ Sơ Thiết Kế Anti-Slop Đã Khóa (Frozen UI/UX Contract)

Toàn bộ các tài liệu thiết kế sau đã được thẩm định độc lập và đóng băng đính kèm đặc tả này:
1. **Art Direction & Concept**: [Tên Concept đã duyệt từ `templates/12-ART-DIRECTION-TEMPLATE.md`]
2. **Bố cục màn hình**: `03_KET_QUA_KIEM_TRA/01_SCREEN_COMPOSITION.md`
3. **Quy chuẩn thích ứng & Insets**: `03_KET_QUA_KIEM_TRA/02_RESPONSIVE_SPEC.md`
4. **4 Trạng thái giao diện bắt buộc**: `03_KET_QUA_KIEM_TRA/03_STATE_COMPOSITION.md` (Loading Skeleton, Empty CTA, Success, Error Recovery)
5. **Nội dung thực tế (Copy Deck)**: `03_KET_QUA_KIEM_TRA/04_COPY_DECK.md` (CẤM 100% placeholder)
6. **Hợp đồng Design Tokens 3 tầng**: `02_YEU_CAU_CUA_TOI/design.md`

---

## 3. Ranh Giới Tính Năng & Rủi Ro

1. **Tính năng cốt lõi giữ nguyên từ app gốc**:
   - [Mô tả tính năng A, B...]
2. **Tính năng mới phát triển bổ sung**:
   - [Mô tả tính năng mới 1]
   - [Mô tả tính năng mới 2]
3. **Phương án xử lý các Unknowns**:
   - [Giải pháp thay thế cho từng mã UNK-XX trong UNKNOWNS_AND_COVERAGE.md]
4. **Ranh giới mạng & dữ liệu (Security Scope)**:
   - [x] Chạy 100% dữ liệu cục bộ trên máy, không gửi telemetry ra ngoài (hoặc nêu rõ API ngoài cần `-AllowHighRisk`).
   - [x] Bảo toàn 100% dữ liệu người dùng nhập trên form khi gặp lỗi theo `RULE-INIT-001`.

---

## 4. Tiêu Chí Nghiệm Thu Đóng Băng (Acceptance Criteria)

- [ ] Tuân thủ 100% 7 điều khoản của Hợp đồng Anti-Slop (không rập khuôn card/gradient, không placeholder).
- [ ] Vượt qua Independent Design Critique theo bộ tiêu chí trong `REVIEW.md`.
- [ ] Vượt qua kiểm tra xác định `verify_code.ps1` (Exit Code 0).
- [ ] Đối chiếu 1-1 với app gốc và đặc tả này tại Bước 12 đạt yêu cầu người dùng.
