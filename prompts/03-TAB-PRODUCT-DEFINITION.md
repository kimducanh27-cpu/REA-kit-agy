# PROMPT 03: ĐỊNH HÌNH SẢN PHẨM & KẾ HOẠCH TRIỂN KHAI (TAB 03 — PRODUCT DEFINITION)

*Dán đoạn lệnh này vào AI Agent sau khi hoàn thành Stage 02 (Gate 02 đã mở).*

---

```markdown
# Tab 03 — Stage 03: Product Definition (Bước 06: Interview, Bước 07: Spec & Design & Bước 08: Implementation Plan)

Read and follow `AGENTS.md`, `REVIEW.md`, and `docs/WORKFLOW_LIFECYCLE.md`.

## Active Skills for this Tab:
- Local Kit Skills: `rea-interview`
- Host Plugin Skills: `ui-styling`, `design-system`

## Điều kiện tiên quyết:
Kiểm tra `.agents/state/active_case.json`. Nếu `gates.gate_02_audit_passed` chưa đạt (`false`), dừng lại và yêu cầu hoàn thành Stage 02 trước.

You are executing **STAGE_03 · PRODUCT DEFINITION**:

### BƯỚC 06: REA INTERVIEW (Phỏng Vấn Người Dùng)
1. Đọc kỹ:
   - `02_YEU_CAU_CUA_TOI/ho-so-va-muc-tieu.md`
   - `03_KET_QUA_KIEM_TRA/bao-cao-hien-trang.md`
   - `03_KET_QUA_KIEM_TRA/UNKNOWNS_AND_COVERAGE.md`
2. Đặt từ 3 đến 5 câu hỏi tiếng Việt đời thường, tập trung vào:
   - Mức độ tương đồng với app gốc (Giữ nguyên hay tối giản?).
   - Phương án giải quyết các Unknowns phát hiện ở Bước 05.
   - Các tính năng mới cần bổ sung hoặc lược bỏ.
   - **Chốt 1 trong 4 Build Routes**:
     * Route 1 (Extend): Tiếp tục phát triển trên source hiện tại của ứng dụng.
     * Route 2 (Feature Branch): Tạo nhánh riêng để phát triển cô lập tính năng mới.
     * Route 3 (Compatible Clean-room): Xây dựng bản tương thích mới (Android Native qua `android-cli` hoặc Web Zero-Install).
     * Route 4 (Full Rewrite): Viết lại hoàn toàn kiến trúc mới từ đầu theo đặc tả.
3. Chờ người dùng trả lời và tổng hợp thành tài liệu rõ ràng.

### BƯỚC 07: SPEC & DESIGN GATE (Đặc Tả Đóng Băng & Hợp Đồng Giao Diện)
1. Chốt hợp đồng thiết kế **Design System 3 tầng** trong `02_YEU_CAU_CUA_TOI/design.md` (sử dụng skill `design-system` và `ui-styling`):
   - Tầng 1: Primitive Tokens (Màu sắc hex, Font chữ hệ thống, Spacing, Bo góc, hoặc Android XML/Compose tokens).
   - Tầng 2: Semantic Components (Button, Card, Input, Header, Navigation).
   - Tầng 3: 4 Trạng thái giao diện bắt buộc (`Loading`, `Empty`, `Success`, `Error`).
2. Xuất tài liệu đặc tả yêu cầu đã chốt theo `templates/02-SPEC-TEMPLATE.md` vào:
   👉 `03_KET_QUA_KIEM_TRA/dac-ta-yeu-cau-da-chot.md`.

### BƯỚC 08: IMPLEMENTATION PLAN (Chia Nhỏ Kế Hoạch Triển Khai)
1. Chia nhỏ toàn bộ dự án thành các nhiệm vụ nguyên tử (Atomic Tasks) kèm thứ tự và phụ thuộc.
2. Điền đầy đủ vào `templates/07-IMPLEMENTATION-PLAN-TEMPLATE.md`.
3. Xuất file kế hoạch chính thức vào:
   👉 `03_KET_QUA_KIEM_TRA/KE_HOACH_TRIEN_KHAI.md`.
4. **CỔNG 03 (Quality Gate 03: `gate_03_spec_frozen`)**:
   - Yêu cầu người dùng xác nhận: "Đồng ý" với Đặc tả, Design System và Kế hoạch.
   - Khi người dùng đồng ý:
     * Cập nhật `active_case.json`: `gates.gate_03_spec_frozen = true`, `current_phase = "STAGE_03_PRODUCT_DEFINITION"`, `current_step = "08_IMPLEMENTATION_PLAN"`.
     * Cập nhật checklist trong `docs/PROGRESS.md`.
   - **Vòng lặp sửa sai (Reject Loop)**: Nếu người dùng yêu cầu chỉnh sửa, tạo bản `SPEC_v2.md` và lùi về Bước 06/07. Tuyệt đối không xóa bản cũ.

### BÁO CÁO CHO NGƯỜI DÙNG:
Trình bày tóm tắt đặc tả, Build Route đã chọn và kế hoạch chia task. Đề nghị người dùng duyệt để mở CỔNG 03 và bắt đầu viết code tại Stage 04.
```
