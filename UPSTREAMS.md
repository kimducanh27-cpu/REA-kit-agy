# Upstream Register — REA-kit-agy

Checked: **2026-11-13**. Primary upstream source is pinned to the exact commit SHA and package version below.

---

## 1. Upstream Engine: morluto/rea

- **Repository**: https://github.com/morluto/rea
- **Release Tag**: `rea-agents-6.9.0`
- **Pinned Commit**: `5cddc69c51a0fb18d021417199046314581ba9c2`
- **Package name**: `rea-agents@6.9.0` (published 2026-11-12)
- **Declared License**: MIT
- **Primary Source Skill**: `.agents/skills/reverse-engineer-anything/SKILL.md` (Upstream Skill Version: `v62`, kèm 8 references đầy đủ gồm `desktop-build.md`)
- **Key References**:
  - `docs/guides/javascript/javascript-application-workflows.md`
  - `docs/guides/android/android-analysis.md`
  - `docs/guides/web/browser-observation.md`
  - `docs/release-exposure.md`
  - `SECURITY.md` & `DISCLAIMER.md`

---

## 2. Handling & Policy (Upstream-First, Orchestration-Second)

1. **Không viết lại lõi REA (Nguyên văn Upstream Engine)**:
   * File `.agents/skills/reverse-engineer-anything/SKILL.md` và 8 file trong `references/` được giữ nguyên văn từ upstream `morluto/rea` (Skill v62).
   * REA chịu trách nhiệm toàn bộ tầng phân tích dịch ngược, trích xuất cấu trúc và cung cấp bằng chứng (Evidence) qua danh mục MCP tools của server.
   * REA-kit-agy tuyệt đối không sửa đổi engine của REA hoặc tự tạo một bản fork giả mạo.

2. **Ranh giới bộ kit (Orchestration Layer)**:
   * REA-kit-agy đóng vai trò lớp quy trình tiếng Việt và giao diện thư mục trực quan cho người dùng non-tech:
     - Tiếp nhận và sao lưu an toàn (`01_`, `04_`).
     - Định tuyến công cụ REA và chuyển đổi báo cáo kỹ thuật sang ngôn ngữ thường (`03_`).
     - Phỏng vấn yêu cầu theo `docs/INTAKE_QUESTION_LOGIC.md`.
     - Điều phối sinh mã nguồn và kiểm chứng độc lập (`05_`).

3. **Kiểm tra tương thích Runtime & Ranh giới Riêng tư (Scoped Privacy Statement)**:
   * **Môi trường thực thi**: Engine dịch ngược (JADX, Apktool, REA MCP) thực thi hoàn toàn cục bộ trên máy trạm của người dùng.
   * **Truyền dữ liệu (Data Egress)**: Việc gửi dữ liệu ngữ cảnh ra ngoài internet phụ thuộc vào AI Agent Provider được cấu hình (ví dụ: Google Antigravity, Anthropic Claude, hoặc Local LLM). Bộ kit áp dụng chính sách che mờ 100% bí mật `[REDACTED]` trước khi đưa vào context.
   * `health_check.ps1` kiểm tra đăng ký MCP client (`REGISTRATION_ALIGNED`). Lệnh cấu hình chính xác: `npx -y rea-agents@6.9.0 setup --client antigravity --yes`.

---

## 3. Upstream Standards cho Khâu Build, Fix, UI & Flow Inventory

Để đảm bảo chất lượng kỹ thuật mà không tự bịa quy trình, bộ kit tham chiếu các chuẩn upstream mở sau:

1. **Chuẩn Sửa Lỗi (Fix App)**: `caveman/surgical-patch`
   * Nguyên tắc: Sửa lỗi ở phạm vi hẹp nhất có trách nhiệm (Narrowest responsible layer), bảo toàn 100% hành vi xung quanh, có bằng chứng trước và sau khi vá lỗi. Bắt buộc vượt qua `verify_code.ps1`.

2. **Chuẩn Phát Triển (Build App)**: `caveman/lean-build`
   * Nguyên tắc: Triển khai đúng phạm vi chốt trong bản đặc tả đóng băng (Frozen Spec), có điều kiện dừng rõ ràng, ngăn chặn triệt để tình trạng over-building hoặc tự ý phình tính năng.

3. **Chuẩn Thiết Kế Giao Diện & Tokens (UI Design)**: `ui-ux-pro-max/ui-styling` & Design Systems
   * Nguyên tắc: Hợp đồng giao diện 3 tầng điều khiển bằng `design.md`. Ánh xạ tokens thành CSS Variables (`:root`) và Tailwind CSS CDN utility classes, loại bỏ hoàn toàn việc hardcode mã màu tùy tiện. Single-file web zero-install.

4. **Chuẩn Kiến Trúc Màn Hình & Trạng Thái UI**: `kimducanh27-cpu/app-adr-ui` (`templates/04-APP-FLOW/04-SCREEN-INVENTORY.md` & `06-STATE-AND-EXCEPTION-MATRIX.md`)
   * Nguyên tắc: Tách bạch rõ ranh giới các bước: Không vẽ UI khi chưa có `Screen Inventory` và `State Matrix`. Giao diện phải định nghĩa trước 4 trạng thái (`Loading`, `Empty`, `Success`, `Error Recovery`) để không bao giờ bị đơ hoặc trắng trang.

5. **Chuẩn Thẩm Định Mã Nguồn AI (Anthropic Code Review Pipeline)**: `Anthropic Claude Code Team` (*"How the Claude Code team does code review"*)
   * Nguyên tắc:
     - Tách biệt vai trò Builder và Independent Reviewer trong Fresh Context (`prompts/05-TAB-VALIDATION.md`) để tránh thiên kiến xác nhận của AI.
     - Quy chuẩn thẩm định tập trung tại `REVIEW.md` với Bộ lọc dẹp nhiễu (High-Signal Filter, cấm bắt bẻ phong cách).
     - Bắt buộc xuất "Bản giải thích cho người dùng" (Explainers Over Diffs) thay vì bắt người non-tech đọc git diff.
     - Phân tầng rủi ro tự động (Automated Risk Classifier trong `verify_code.ps1`: LOW / MEDIUM / HIGH).
     - Giới hạn cứng vòng lặp tự sửa (Review Convergence: tối đa 2 vòng) chống lặp vô tận đốt token.
     - Chốt chặn trách nhiệm con người ("You Land It, You Own It" Accountability Sign-off).
     - Chốt chặn an toàn tối hậu bằng cơ chế Rollback tự động (`HOAN_TAC.bat`, snapshot `.backup/`, và bộ nhớ học từ sự cố `learned_rules.json`).

6. **Chuẩn Vòng Đời Phát Triển & Dịch Ngược (Workflow Lifecycle)**: `docs/WORKFLOW_LIFECYCLE.md`
   * Nguyên tắc:
     - Chuẩn hóa toàn diện hành trình từ tiếp nhận đến bàn giao thành 6 Phase · 14 Bước nguyên tử.
     - Khóa cứng 6 Cổng kiểm soát chất lượng (Quality Gates): Gate 01 Baseline ➔ Gate 02 Audit ➔ Gate 03 Spec Frozen ➔ Gate 04 Build QA ➔ Gate 05 Hard Verify ➔ Gate 06 Handoff Signed.
     - Cơ chế sửa sai an toàn (Reject / Retry Loop): Đánh số `_v2`, không xóa lịch sử cũ, lùi trạng thái về đúng bước cần khắc phục.
     - Tự động phục hồi phiên làm việc (Auto-Resume) qua `health_check.ps1` và `prompts/00-SESSION-CONTINUITY.md`.
