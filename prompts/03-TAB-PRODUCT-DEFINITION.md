# PROMPT 03: ĐỊNH HÌNH SẢN PHẨM & THIẾT KẾ ANTI-SLOP (TAB 03 — PRODUCT DEFINITION)

*Dán đoạn lệnh này vào AI Agent sau khi hoàn thành Stage 02 (Gate 02 đã thông qua hợp lệ).*

---

```markdown
# Tab 03 — Stage 03: Product Definition & Anti-Slop UI Spec (Bước 06, 07 & 08)

Read and follow `AGENTS.md`, `REVIEW.md`, `.agents/state/MEMORY.md`, and `docs/WORKFLOW_LIFECYCLE.md`.

## Active Skills for this Tab:
- Local Kit Skills (Bắt buộc): `rea-interview` (Bước 06–07), `rea-plan` (Bước 08)

## Ranh giới Kiến trúc Tuyệt đối (Spec-First Boundary):
Trong toàn bộ Tab 03, **TUYỆT ĐỐI KHÔNG ĐƯỢC VIẾT CODE SẢN PHẨM, KHÔNG TẠO WORKING PROTOTYPE**.
Toàn bộ đầu ra là các tài liệu Markdown đặc tả hợp đồng thiết kế chống UI Slop và hồ sơ quyết định kiến trúc.

## Điều kiện tiên quyết:
Đọc `.agents/state/active_case.json` hoặc chạy `powershell -NoProfile -ExecutionPolicy Bypass -File .agents/scripts/gate.ps1 status`.
Cổng 02 (`gate_02_audit_passed`) phải ở một trong các trạng thái hợp lệ đã được giải phóng:
- `PASS` (Hoàn thành kiểm toán đầy đủ Bước 05).
- `PASS_WITH_LIMITATIONS` (Vượt qua với giới hạn phân tích tĩnh).
- `REUSED_VALIDATED` (Tái sử dụng bằng chứng hợp lệ từ case trước).
- `SKIPPED` (Bỏ qua hợp lệ có lý do, ví dụ: chế độ Source Repository `WF03`).
- `NOT_APPLICABLE` (Không áp dụng cho chế độ ca làm việc hiện tại).
- `WAIVED` (Được phê duyệt miễn trừ có lý do giải trình).
Nếu Cổng 02 ở trạng thái `FAILED`, `BLOCKED`, `NOT_STARTED` hoặc `INVALIDATED`, dừng lại và xử lý Cổng 02 trước.

You are executing **STAGE_03 · PRODUCT DEFINITION**:

### BƯỚC 06: REA ADAPTIVE INTERVIEW & ART DIRECTION (Skill `rea-interview`)
1. **Context Ingestion & Evidence Analysis**:
   - Tối ưu hóa tải ngữ cảnh thông qua Context Engine:
     `powershell -NoProfile -ExecutionPolicy Bypass -File .agents/scripts/context.ps1 plan -Task "<Mô tả mục tiêu phỏng vấn>"`
     `powershell -NoProfile -ExecutionPolicy Bypass -File .agents/scripts/context.ps1 pack -PlanId "<PlanId>"`
   - Đọc đồng thời các tài liệu đầu vào:
     * `02_YEU_CAU_CUA_TOI/ho-so-va-muc-tieu.md`
     * `03_KET_QUA_KIEM_TRA/bao-cao-hien-trang.md` (nếu có)
     * `03_KET_QUA_KIEM_TRA/UNKNOWNS_AND_COVERAGE.md` (nếu có)
     * `.agents/state/interview_state.json`
   - Phân loại dữ liệu theo 6 nhãn tin cậy: `VERIFIED_FACT`, `USER_STATED`, `AI_INFERENCE`, `ASSUMPTION`, `UNKNOWN`, `CONFLICT`.
   - Phân loại các thông số kỹ thuật theo 5 tầng: `REFERENCE_BENCHMARK`, `CANDIDATE_RECOMMENDATION`, `USER_REQUIREMENT`, `VERIFIED_CONSTRAINT`, `UNAPPROVED_ASSUMPTION`.
   - Cấm hỏi người dùng những thông tin đã được kiểm chứng từ mã nguồn, manifest, hoặc báo cáo hiện trạng.

2. **Khởi tạo / Đồng bộ Interview State**:
   - Cập nhật `.agents/state/active_case.json`: `current_phase = "STAGE_03_PRODUCT_DEFINITION"`, `current_step = "06_REA_INTERVIEW"`, `current_gate_status = "GATE_03_WAITING_USER_INPUT"`.
   - Ghi nhận mục tiêu vào trạng thái qua CLI:
     `powershell -NoProfile -ExecutionPolicy Bypass -File .agents/scripts/interview.ps1 record-goal -GoalId "GOAL-01" -Description "<Mô tả mục tiêu người dùng>"`

3. **Vận hành Động cơ Phỏng vấn Quyết định (Decision-Driven Question Selection)**:
   - Áp dụng công thức ưu tiên và 8 bộ lọc của Question Necessity Engine trong `rea-interview`.
   - **Tuyệt đối không dùng bảng câu hỏi cố định 3-5 câu**. Số lượng câu hỏi hoàn toàn phụ thuộc vào độ phức tạp và rủi ro:
     * Sửa lỗi nhỏ / Tối ưu hẹp: Có thể chỉ cần 0 đến 1 câu làm rõ triệu chứng.
     * Thêm tính năng / Ứng dụng mới: Đặt câu hỏi theo chu kỳ thích ứng, ưu tiên quyết định then chốt (One-Way Door).
   - Tách bạch rõ ràng câu hỏi nghiệp vụ người dùng với quyền hạn của Agent (R10):
     * Hỏi người dùng về tính năng: Ứng dụng cần chạy offline hoàn toàn hay cần đồng bộ đám mây?
     * Không hỏi người dùng về các cờ nội bộ kỹ thuật như `-AllowHighRisk`.

4. **Xử lý Phản Hồi & Giải Quyết Mâu Thuẫn (Contradiction Resolution)**:
   - Phân loại câu trả lời theo 10 loại: `CLEAR`, `PARTIAL`, `AMBIGUOUS`, `UNKNOWN`, `CONDITIONAL`, `MULTIPLE_CHOICE`, `CONFLICTING`, `OUT_OF_SCOPE`, `NEW_REQUIREMENT`, `SCOPE_CHANGE`.
   - Nếu phát hiện mâu thuẫn (ví dụ: "chạy 100% offline" nhưng "đăng nhập Google và đồng bộ mây"):
     * Không tự ý xóa quyết định trước.
     * Ghi nhận conflict qua CLI: `powershell -File .agents/scripts/interview.ps1 record-conflict ...`
     * Giải thích xung đột bằng ngôn ngữ dễ hiểu và hỏi người dùng lựa chọn định hướng thực tế.
   - Nếu người dùng trả lời "Không biết" về kỹ thuật:
     * Không ép chọn. Đề xuất giải pháp an toàn kèm lý do kỹ thuật.
     * Ghi nhận vào Assumption Record: `powershell -File .agents/scripts/interview.ps1 record-assumption ...`

5. **Định Tuyến Khám Phá Thiết Kế (Design Exploration Mode)**:
   - `DESIGN_REUSE_EXACT`: Tái lập 1-1 giao diện cũ. Bỏ qua 3 concepts. Bắt buộc áp dụng Sanitary Ergonomic Lint (48dp touch targets) và Legal Asset Decoupling.
   - `DESIGN_STYLE_SPECIFIED`: Áp dụng đúng phong cách người dùng đã chọn (ví dụ: Material You, Minimalist). Bỏ qua 3 concepts.
   - `DESIGN_STRUCTURAL_EXPLORATION`: Bắt buộc xây dựng 3 Concept có cấu trúc thông tin khác biệt sâu sắc (Concept A: Task-Centric, Concept B: Content-First, Concept C: Contextual Flow) theo `templates/12-ART-DIRECTION-TEMPLATE.md`.
   - 👉 **Human Gate 1 (Bố cục giao diện)**: Chờ người dùng duyệt bố cục:
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
5. **Khóa Design Tokens 3 Tầng**:
   - `02_YEU_CAU_CUA_TOI/design.md` theo `templates/05-DESIGN-TOKEN-TEMPLATE.md`.
6. **Đánh Giá Đầy Đủ Thông Tin (Interview Exit Gate)**:
   - Chạy lệnh kiểm tra tính đầy đủ của thông tin trước khi xuất đặc tả đóng băng:
     `powershell -NoProfile -ExecutionPolicy Bypass -File .agents/scripts/interview.ps1 evaluate-sufficiency`
   - Chỉ khi kết quả đạt `SUFFICIENT`, mới tổng hợp và xuất đặc tả hoàn chỉnh theo `templates/02-SPEC-TEMPLATE.md` vào:
     👉 `03_KET_QUA_KIEM_TRA/dac-ta-yeu-cau-da-chot.md`.
7. 👉 **Human Gate 2 (Đặc tả yêu cầu & Giao diện)**:
   Chờ người dùng duyệt toàn bộ hồ sơ đặc tả bằng lệnh:
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
