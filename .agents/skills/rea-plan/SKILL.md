---
name: rea-plan
description: Phụ trách độc quyền Bước 08 (Implementation Plan) và Cổng 03 (gate_03_spec_frozen) trong STAGE_03 (Product Definition). Phân tách đặc tả đã chốt thành 6 Vertical Slices nguyên tử, thiết lập đồ thị phụ thuộc (Task Dependency Graph), phạm vi file (Allowed Paths), tiêu chí nghiệm thu, xuất 03_KET_QUA_KIEM_TRA/KE_HOACH_TRIEN_KHAI.md và xử lý vòng lặp Reject Gate 03.
---

# KỸ NĂNG: LẬP KẾ HOẠCH TRIỂN KHAI NGUYÊN TỬ (REA-PLAN)

Kỹ năng chuyên trách cho **Bước 08 (`08_IMPLEMENTATION_PLAN`)** thuộc **STAGE_03 · PRODUCT DEFINITION**, tiếp nhận đặc tả từ `rea-interview` và quản lý **CỔNG 03 (`gate_03_spec_frozen`)**.

---

## 1. NGUYÊN TẮC QUẢN TRỊ KẾ HOẠCH (PLANNING DISCIPLINE)

1. **Tách biệt lập kế hoạch khỏi viết mã**:
   - Planner (`rea-plan`) không viết mã sản phẩm vào `05_MA_NGUON_PHAT_TRIEN/`.
   - Mọi danh mục file được phép can thiệp (`Allowed Paths`) phải được định nghĩa tường minh trước khi chuyển sang Stage 04.
2. **Kiểm soát phạm vi (Scope Control)**:
   - Chỉ lập task cho các tính năng nằm trong `03_KET_QUA_KIEM_TRA/dac-ta-yeu-cau-da-chot.md`.
   - Liệt kê rõ mục `Non-goals` (những việc không thực hiện).

---

## 2. CẤU TRÚC 6 LÁT CẮT DỌC (6 VERTICAL SLICES / MILESTONES)

Kế hoạch trong `03_KET_QUA_KIEM_TRA/KE_HOACH_TRIEN_KHAI.md` bắt buộc chia theo 6 lát cắt chuẩn:
- **Milestone 01 — Project Foundation & Design Tokens**: Thiết lập khung dự án theo `build_route` (`Route A` HTML/CSS/JS, `Route B` Android Native qua `android create`, hoặc `Route C`) và ánh xạ toàn bộ Design Tokens từ `02_YEU_CAU_CUA_TOI/design.md`.
- **Milestone 02 — Core Navigation & Screen Scaffolding**: Dựng khung điều hướng và bố cục các màn hình chính theo `Screen Inventory`.
- **Milestone 03 — Primary Business Logic**: Cài đặt logic nghiệp vụ cốt lõi (tính toán, xử lý sự kiện, chuyển đổi trạng thái).
- **Milestone 04 — Data Persistence & Local Storage**: Tích hợp lưu trữ cục bộ an toàn (`LocalStorage`/`IndexedDB` cho Web hoặc `Room`/`SQLite`/`SharedPreferences` cho Android).
- **Milestone 05 — Error Recovery & 4 UI States**: Hoàn thiện đủ 4 trạng thái (`Loading`, `Empty`, `Success`, `Error` bảo toàn 100% dữ liệu đang nhập theo `RULE-INIT-001`).
- **Milestone 06 — Self-Verification & Hard Verify Prep**: Chạy `verify_code.ps1`, chuẩn bị kịch bản đối chiếu 1-1 với baseline.

---

## 3. QUY TRÌNH THỰC THI & CHỐT CỔNG 03 (`gate_03_spec_frozen`)

1. Cập nhật `active_case.json`: `current_step = "08_IMPLEMENTATION_PLAN"`.
2. Điền đầy đủ kế hoạch 6 Milestones theo mẫu `templates/07-IMPLEMENTATION-PLAN-TEMPLATE.md` và xuất vào:
   👉 `03_KET_QUA_KIEM_TRA/KE_HOACH_TRIEN_KHAI.md`.
3. **Trình bày và xin phê duyệt CỔNG 03 (`gate_03_spec_frozen`)**:
   - **Khi người dùng xác nhận "Đồng ý"**:
     * Cập nhật `.agents/state/active_case.json`: `gates.gate_03_spec_frozen = true`, `current_gate_status = "GATE_03_PASSED"`, `next_prompt_guide = "Dán 'prompts/04-TAB-IMPLEMENTATION.md' để bắt đầu viết code và kiểm thử QA."`.
     * Đồng bộ bảng tiến độ trong `docs/PROGRESS.md`.
   - **Khi người dùng yêu cầu sửa lại (Reject Loop — Gate Invalidation Invariant)**:
     * Giữ nguyên bản cũ, tạo bản revision mới (`dac-ta-yeu-cau-da-chot_v2.md` / `KE_HOACH_TRIEN_KHAI_v2.md`).
     * Trong `active_case.json`: Tăng `revision += 1`, đặt `gates.gate_03_spec_frozen = false`, `gates.gate_04_build_qa_passed = false`, `gates.gate_05_hard_verify_passed = false`, `gates.gate_06_handoff_signed = false`, và lùi `current_step` về `"06_REA_INTERVIEW"`.
