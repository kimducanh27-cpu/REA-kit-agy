# PROMPT 03: ĐỊNH HÌNH SẢN PHẨM & THIẾT KẾ ANTI-SLOP (TAB 03 — PRODUCT DEFINITION)

*Dán đoạn lệnh này vào AI Agent sau khi hoàn thành Stage 02 (Gate 02 đã mở).*

---

```markdown
# Tab 03 — Stage 03: Product Definition & Anti-Slop UI Spec (Bước 06, 07 & 08)

Read and follow `AGENTS.md`, `REVIEW.md`, `.agents/state/MEMORY.md`, and `docs/WORKFLOW_LIFECYCLE.md`.

## Active Skills for this Tab:
- Local Kit Skills (Bắt buộc): `rea-interview` (Bước 06–07), `rea-plan` (Bước 08)

## Ranh giới Kiến trúc Tuyệt đối (Spec-First Boundary):
Trong toàn bộ Tab 03, **TUYỆT ĐỐI KHÔNG ĐƯỢC VIẾT CODE SẢN PHẨM, KHÔNG TẠO WORKING PROTOTYPE**.
Toàn bộ đầu ra là các tài liệu Markdown đặc tả hợp đồng thiết kế chống UI Slop.

## Điều kiện tiên quyết:
Đọc `.agents/state/active_case.json`. Nếu `gates.gate_02_audit_passed.state` khác `PASS`, dừng lại và yêu cầu hoàn thành Tab 02 trước.

You are executing **STAGE_03 · PRODUCT DEFINITION**:

### BƯỚC 06: REA INTERVIEW & ART DIRECTION (Skill `rea-interview`)
1. Đọc kỹ 3 tài liệu đầu vào:
   - `02_YEU_CAU_CUA_TOI/ho-so-va-muc-tieu.md`
   - `03_KET_QUA_KIEM_TRA/bao-cao-hien-trang.md`
   - `03_KET_QUA_KIEM_TRA/UNKNOWNS_AND_COVERAGE.md`
2. Cập nhật `.agents/state/active_case.json`: `current_phase = "STAGE_03_PRODUCT_DEFINITION"`, `current_step = "06_REA_INTERVIEW"`, `current_gate_status = "GATE_03_WAITING_USER_INPUT"`.
3. Đặt từ 3 đến 5 câu hỏi tiếng Việt làm rõ:
   - Chiến lược phát triển: `STRATEGY_1_EXTEND` | `STRATEGY_2_FEATURE_BRANCH` | `STRATEGY_3_COMPATIBLE_CLEANROOM` | `STRATEGY_4_FULL_REWRITE`
   - Nền tảng đích: `ROUTE_A_WEB_ZERO_INSTALL` | `ROUTE_B_ANDROID_NATIVE` | `ROUTE_C_PATCH_HYBRID`
   - Phương án giải quyết các điểm mù Unknowns (`UNK-XX`)
   - Ranh giới kết nối mạng (chạy offline 100% hay cần mở `-AllowHighRisk`)
4. **Xây dựng Art Direction & 3 Concept Cấu Trúc Đa Dạng (Anti-Slop)** theo `templates/12-ART-DIRECTION-TEMPLATE.md`:
   - Xác định Product Personality, Visual Thesis, Layout Philosophy, Typography, Density, Signature Element.
   - Trình bày 3 Concept khác biệt sâu sắc về cấu trúc thông tin (Concept A: Task-Centric, Concept B: Content-First, Concept C: Contextual Flow). CẤM chỉ đổi 3 bảng màu.
5. 👉 **Human Gate 1**: Chờ người dùng chọn phương án và duyệt bằng lệnh:
   `APPROVE SCREEN COMPOSITION`

### BƯỚC 07: SPEC & DESIGN GATE (Anti-Slop UI Spec — Skill `rea-interview`)
1. Cập nhật `active_case.json`: `current_step = "07_SPEC_AND_DESIGN"`.
2. **Xuất Bố cục Màn hình & Responsive Spec**:
   - `03_KET_QUA_KIEM_TRA/01_SCREEN_COMPOSITION.md` (Thứ tự ưu tiên thị giác, phân vùng, khoảng cách).
   - `03_KET_QUA_KIEM_TRA/02_RESPONSIVE_SPEC.md` (Window size classes, Insets, Foldables).
3. **Xuất 4 Trạng Thái Bắt Buộc (State Composition)**:
   - `03_KET_QUA_KIEM_TRA/03_STATE_COMPOSITION.md`: Loading (Skeleton), Empty (CTA), Success, Error Recovery (bảo toàn form input theo `RULE-INIT-001`), Permission Denied, Destructive Confirmation.
4. **Xuất Hợp Đồng Nội Dung Thực Tế (Copy Deck)**:
   - `03_KET_QUA_KIEM_TRA/04_COPY_DECK.md` theo `templates/13-COPY-DECK-TEMPLATE.md`.
   - CẤM 100% `Lorem ipsum`, `Sample text`, hoặc `Welcome back!`. Quy định giới hạn ký tự và ngắt dòng.
5. **Khóa Design Tokens 3 Tầng & Xuất Đặc Tả**:
   - `02_YEU_CAU_CUA_TOI/design.md` theo `templates/05-DESIGN-TOKEN-TEMPLATE.md`.
   - `03_KET_QUA_KIEM_TRA/dac-ta-yeu-cau-da-chot.md` theo `templates/02-SPEC-TEMPLATE.md`.
6. 👉 **Human Gate 2**: Chờ người dùng duyệt toàn bộ hồ sơ giao diện bằng lệnh:
   `APPROVE UI SPEC`

### BƯỚC 08: IMPLEMENTATION PLAN & ĐÓNG BĂNG ĐẶC TẢ (Skill `rea-plan`)
1. Cập nhật `active_case.json`: `current_step = "08_IMPLEMENTATION_PLAN"`.
2. Chia nhỏ kế hoạch triển khai thành 6 Vertical Slices nguyên tử theo `templates/07-IMPLEMENTATION-PLAN-TEMPLATE.md` vào:
   👉 `03_KET_QUA_KIEM_TRA/KE_HOACH_TRIEN_KHAI.md`.
3. **CỔNG 03 (`gate_03_spec_frozen`)**:
   - Người dùng đóng băng đặc tả bằng câu lệnh:
     `FREEZE UI SPEC`
   - Khi nhận lệnh, chạy script mở cổng:
     `powershell -NoProfile -ExecutionPolicy Bypass -File .\.agents\scripts\gate.ps1 open 3 -Evidence 03_KET_QUA_KIEM_TRA/dac-ta-yeu-cau-da-chot.md -ApprovedBy "user"`
   - Đồng bộ `docs/PROGRESS.md`.
   - **Nếu người dùng từ chối / yêu cầu sửa lại (Reject Loop)**:
     Chạy lệnh tự động thu hồi:
     `powershell -NoProfile -ExecutionPolicy Bypass -File .\.agents\scripts\gate.ps1 reject 3 -Reason "Người dùng yêu cầu chỉnh sửa lại đặc tả hoặc giao diện."`
     Tạo bản `_v2.md` và lùi về Bước 06.
```
