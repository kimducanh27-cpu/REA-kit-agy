---
name: rea-plan
description: Kỹ năng chuyên trách lập kế hoạch kỹ thuật (Technical & Architectural Planning), phân tách dự án thành các Vertical Slices nguyên tử, thiết lập đồ thị phụ thuộc (Task Dependency Graph), xác định phạm vi file (Allowed Paths), tiêu chí nghiệm thu (Acceptance Criteria) và kế hoạch Rollback cho Bước 08 trong STAGE_03 (Product Definition) theo chuẩn Cổng 03 (gate_03_spec_frozen).
---

# KỸ NĂNG: LẬP KẾ HOẠCH TRIỂN KHAI NGUYÊN TỬ (REA-PLAN)

Kỹ năng chuyên trách cho **Bước 08 (Implementation Plan)** thuộc **STAGE_03 · PRODUCT DEFINITION**, tiếp thu tinh hoa từ GitHub Spec Kit để đảm bảo chia nhỏ công việc thành các lát cắt dọc (Vertical Slices) có thể kiểm chứng độc lập trước khi giao cho Builder.

---

## 1. NGUYÊN TẮC QUẢN TRỊ KẾ HOẠCH (PLANNING DISCIPLINE)

1. **Tách biệt lập kế hoạch khỏi viết mã**:
   - Planner (`rea-plan`) không trực tiếp viết mã sản phẩm vào `05_MA_NGUON_PHAT_TRIEN/`.
   - Mọi quyết định kiến trúc, danh mục file được phép sửa đổi (Allowed File Paths) phải được xác định rõ ràng trước khi giao cho Builder (`rea-build`).
2. **Không cho phép tự ý mở rộng tính năng (Scope Control)**:
   - Chỉ lập task cho các tính năng đã được người dùng chốt trong `dac-ta-yeu-cau-da-chot.md`.
   - Xác định rõ Non-goals (những việc dứt khoát không làm).
3. **Mỗi Task là một đơn vị nguyên tử (Atomic Task)**:
   - Mỗi task chỉ giải quyết 1 vấn đề cụ thể, có thể chạy thử và kiểm chứng độc lập.

---

## 2. CẤU TRÚC 6 LÁT CẮT DỌC (6 VERTICAL SLICES / MILESTONES)

Kế hoạch bắt buộc được tổ chức theo 6 lát cắt chuẩn:

- **Milestone 01 — Project Foundation & Toolchain**:
  Thiết lập khung dự án theo Build Route đã chọn (Android Native Gradle / Web App Zero-Install / Patch), cấu hình build và dependency.
- **Milestone 02 — Core Navigation & Layout Scaffolding**:
  Dựng khung điều hướng, các màn hình chính theo sơ đồ bóc tách từ Stage 02.
- **Milestone 03 — Primary Business Logic**:
  Cài đặt logic nghiệp vụ cốt lõi (tính toán, giỏ hàng, xác thực, chuyển đổi trạng thái).
- **Milestone 04 — Data Persistence & Storage**:
  Tích hợp lưu trữ cục bộ an toàn (Room/SQLite trên Android hoặc LocalStorage/IndexedDB trên Web).
- **Milestone 05 — Error Handling & 4 UI States**:
  Triển khai đầy đủ 4 trạng thái giao diện bắt buộc (`Loading`, `Empty`, `Success`, `Error`) theo `design.md`.
- **Milestone 06 — Integration & End-to-End Hard Verify**:
  Tích hợp toàn bộ hệ thống, chuẩn bị test case đối chiếu 1-1 với app gốc cho Stage 05.

---

## 3. KHUNG HỢP ĐỒNG NHIỆM VỤ NGUYÊN TỬ (TASK CONTRACT SCHEMA)

Mỗi nhiệm vụ trong kế hoạch phải tuân thủ đầy đủ các trường:

```markdown
### [TASK-001]: Tên nhiệm vụ cụ thể
- **Milestone**: Milestone 01
- **Phụ thuộc (Dependencies)**: Không có / [TASK-XXX]
- **Tập tin được phép can thiệp (Allowed Paths)**: `05_MA_NGUON_PHAT_TRIEN/src/...`
- **Yêu cầu kỹ thuật**: Mô tả chi tiết việc cần làm.
- **Tiêu chí hoàn thành (Acceptance Criteria)**:
  * [ ] Tiêu chí 1 kiểm tra được bằng mắt hoặc test case.
  * [ ] Tiêu chí 2...
- **Kế hoạch kiểm thử (Test Plan)**: Tên file test hoặc thao tác kiểm tra thủ công.
- **Kế hoạch hoàn tác (Rollback Plan)**: Gọi snapshot `.backup/` gần nhất nếu fail.
```

---

## 4. QUY TRÌNH THỰC THI & CHỐT CỔNG 03

1. **Tổng hợp đầu vào**:
   - Đọc kỹ `dac-ta-yeu-cau-da-chot.md` và `02_YEU_CAU_CUA_TOI/design.md`.
2. **Khởi tạo kế hoạch**:
   - Sử dụng khung mẫu `templates/07-IMPLEMENTATION-PLAN-TEMPLATE.md`.
   - Xuất file kế hoạch vào:
     👉 `03_KET_QUA_KIEM_TRA/KE_HOACH_TRIEN_KHAI.md`.
3. **Yêu cầu phê duyệt mở CỔNG 03 (`gate_03_spec_frozen`)**:
   - Trình bày kế hoạch cho người dùng duyệt.
   - Khi người dùng chấp thuận: Cập nhật `.agents/state/active_case.json` (`gate_03_spec_frozen = true`) và đồng bộ `docs/PROGRESS.md`.
