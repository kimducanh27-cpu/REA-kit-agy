# Upstream Register — REA-kit-agy

Checked: **2026-11-13**. Primary upstream source is pinned to the exact commit SHA and package version below.

---

## 1. Upstream Engine: morluto/rea

- **Repository**: https://github.com/morluto/rea
- **Inspected main SHA**: `5cddc69c51a0fb18d021417199046314581ba9c2`
- **Package name**: `rea-agents`
- **Package version**: `6.9.0` (published 2026-11-12)
- **Declared License**: MIT
- **Primary Source Skill**: `.agents/skills/reverse-engineer-anything/SKILL.md` (Blob SHA: `5cddc69c51a0fb18d021417199046314581ba9c2`)
- **Key References**:
  - `docs/guides/javascript/javascript-application-workflows.md`
  - `docs/guides/android/android-analysis.md`
  - `docs/guides/web/browser-observation.md`
  - `docs/release-exposure.md`
  - `SECURITY.md` & `DISCLAIMER.md`

---

## 2. Handling & Policy (Upstream-First, Orchestration-Second)

1. **Không viết lại lõi REA**:
   * REA chịu trách nhiệm toàn bộ tầng phân tích dịch ngược, trích xuất cấu trúc và cung cấp bằng chứng (Evidence).
   * REA-kit-agy tuyệt đối không sửa đổi engine của REA hoặc tự tạo một bản fork giả mạo.

2. **Ranh giới bộ kit (Orchestration Layer)**:
   * REA-kit-agy đóng vai trò lớp quy trình tiếng Việt và giao diện thư mục trực quan cho người dùng non-tech:
     - Tiếp nhận và sao lưu an toàn (`01_`, `04_`).
     - Định tuyến công cụ REA và chuyển đổi báo cáo kỹ thuật sang ngôn ngữ thường (`03_`).
     - Phỏng vấn yêu cầu theo `docs/INTAKE_QUESTION_LOGIC.md`.
     - Điều phối sinh mã nguồn và kiểm chứng độc lập (`05_`).

3. **Chính sách cập nhật**:
   * Khi cập nhật phiên bản `rea-agents`, phải kiểm tra lại tính tương thích của danh mục công cụ MCP, cập nhật SHA mới và ghi nhận vào file này.

---

## 3. Upstream Standards cho Khâu Build, Fix & UI Tokens

Để đảm bảo chất lượng kỹ thuật mà không tự bịa quy trình, bộ kit tham chiếu 3 chuẩn upstream mở sau:

1. **Chuẩn Sửa Lỗi (Fix App)**: `caveman/surgical-patch`
   * Nguyên tắc: Sửa lỗi ở phạm vi hẹp nhất có trách nhiệm (Narrowest responsible layer), bảo toàn 100% hành vi xung quanh, có bằng chứng trước và sau khi vá lỗi. Bắt buộc vượt qua `verify_code.ps1`.

2. **Chuẩn Phát Triển (Build App)**: `caveman/lean-build`
   * Nguyên tắc: Triển khai đúng phạm vi chốt trong bản đặc tả đóng băng (Frozen Spec), có điều kiện dừng rõ ràng, ngăn chặn triệt để tình trạng over-building hoặc tự ý phình tính năng.

3. **Chuẩn Thiết Kế Giao Diện & Tokens (UI Design)**: `ui-ux-pro-max/ui-styling` & Design Systems
   * Nguyên tắc: Hợp đồng giao diện điều khiển bằng `design.md`. Ánh xạ tokens thành CSS Variables (`:root`) và Tailwind CSS CDN utility classes, loại bỏ hoàn toàn việc hardcode mã màu tùy tiện. Single-file web zero-install.
