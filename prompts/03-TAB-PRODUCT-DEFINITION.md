# PROMPT 03: ĐỊNH HÌNH SẢN PHẨM & KẾ HOẠCH TRIỂN KHAI (TAB 03 — PRODUCT DEFINITION)

*Dán đoạn lệnh này vào AI Agent sau khi hoàn thành Stage 02 (Gate 02 đã mở).*

---

```markdown
# Tab 03 — Stage 03: Product Definition (Bước 06: Interview, Bước 07: Spec & Design & Bước 08: Implementation Plan)

Read and follow `AGENTS.md`, `REVIEW.md`, `.agents/state/MEMORY.md`, and `docs/WORKFLOW_LIFECYCLE.md`.

## Active Skills for this Tab:
- Local Kit Skills (Bắt buộc): `rea-interview` (Bước 06–07), `rea-plan` (Bước 08)

## Điều kiện tiên quyết:
Đọc `.agents/state/active_case.json`. Nếu `gates.gate_02_audit_passed` là `false`, dừng lại và yêu cầu hoàn thành Tab 02 trước.

You are executing **STAGE_03 · PRODUCT DEFINITION**:

### BƯỚC 06: REA INTERVIEW (Phỏng Vấn Người Dùng — Skill `rea-interview`)
1. Đọc kỹ 3 tài liệu:
   - `02_YEU_CAU_CUA_TOI/ho-so-va-muc-tieu.md`
   - `03_KET_QUA_KIEM_TRA/bao-cao-hien-trang.md`
   - `03_KET_QUA_KIEM_TRA/UNKNOWNS_AND_COVERAGE.md`
2. **Cập nhật trạng thái trước khi đặt câu hỏi**:
   - Ghi vào `.agents/state/active_case.json`: `current_phase = "STAGE_03_PRODUCT_DEFINITION"`, `current_step = "06_REA_INTERVIEW"`, `current_gate_status = "GATE_03_WAITING_USER_INPUT"`.
3. Đặt từ 3 đến 5 câu hỏi tiếng Việt đời thường, dễ chọn:
   - **Chiến lược mã nguồn (`build_strategy` — 4 hướng)**:
     * `STRATEGY_1_EXTEND`: Phát triển nối tiếp trên mã nguồn hiện có.
     * `STRATEGY_2_FEATURE_BRANCH`: Tạo nhánh riêng phát triển tính năng cô lập.
     * `STRATEGY_3_COMPATIBLE_CLEANROOM`: Xây dựng bản tương thích mới sạch sẽ.
     * `STRATEGY_4_FULL_REWRITE`: Viết lại hoàn toàn kiến trúc mới từ đầu.
   - **Lộ trình nền tảng đích (`build_route` — 3 hướng)**:
     * `ROUTE_A_WEB_ZERO_INSTALL` (Mặc định): Web App độc lập (`index.html`, `styles.css`, `app.js`) mở chạy ngay trên trình duyệt.
     * `ROUTE_B_ANDROID_NATIVE`: Dự án Android Native (`android create` / Gradle + Kotlin + Jetpack Compose) tại `05_MA_NGUON_PHAT_TRIEN/android/`.
     * `ROUTE_C_PATCH_HYBRID`: Vá tài nguyên/smali trên gói APK hoặc đóng gói Hybrid (PWA/Capacitor).
   - Phương án xử lý các điểm mù (`UNK-XX`) trong `UNKNOWNS_AND_COVERAGE.md`.
   - Các tính năng muốn giữ lại, lược bỏ, hoặc bổ sung mới và ranh giới kết nối mạng.
4. Chờ người dùng trả lời.

### BƯỚC 07: SPEC & DESIGN GATE (Hợp Đồng Giao Diện & Đặc Tả Đóng Băng — Skill `rea-interview`)
1. Khi người dùng trả lời, cập nhật `active_case.json`: `current_step = "07_SPEC_AND_DESIGN"`, ghi nhận `build_strategy` và `build_route`.
2. Chốt **Design System 3 tầng** trong `02_YEU_CAU_CUA_TOI/design.md` theo `templates/05-DESIGN-TOKEN-TEMPLATE.md` (Primitive Tokens ➔ Semantic Components ➔ 4 Trạng thái UI: `Loading`, `Empty`, `Success`, `Error` bảo toàn dữ liệu nhập theo `RULE-INIT-001`).
3. Xuất tài liệu đặc tả đóng băng theo `templates/02-SPEC-TEMPLATE.md` vào:
   👉 `03_KET_QUA_KIEM_TRA/dac-ta-yeu-cau-da-chot.md`.

### BƯỚC 08: IMPLEMENTATION PLAN (Kế Hoạch 6 Vertical Slices — Skill `rea-plan`)
1. Cập nhật `active_case.json`: `current_step = "08_IMPLEMENTATION_PLAN"`.
2. Chia nhỏ dự án thành 6 Vertical Slices nguyên tử theo `templates/07-IMPLEMENTATION-PLAN-TEMPLATE.md` và xuất vào:
   👉 `03_KET_QUA_KIEM_TRA/KE_HOACH_TRIEN_KHAI.md`.
3. **CỔNG 03 (`gate_03_spec_frozen`)**:
   - Đề nghị người dùng xác nhận "Đồng ý" với Đặc tả, Design System và Kế hoạch triển khai.
   - Khi người dùng đồng ý: Cập nhật `active_case.json` (`gates.gate_03_spec_frozen = true`, `current_gate_status = "GATE_03_PASSED"`) và đồng bộ `docs/PROGRESS.md`.
   - **Nếu người dùng yêu cầu chỉnh sửa (Reject Loop)**: Tạo bản `_v2.md`, tăng `revision += 1`, đặt `gate_03_spec_frozen`..`gate_06_handoff_signed = false`, và lùi `current_step` về `"06_REA_INTERVIEW"`.
```
