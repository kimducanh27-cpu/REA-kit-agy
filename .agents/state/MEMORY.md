# MEMORY INDEX — REA-kit-agy (Anthropic 4-Layer Agent Memory Architecture)
> **Kiến trúc 4 Tầng Bộ Nhớ (Anthropic Research, 06/11/2026)**:
> - **Layer 1 (Transcripts / Event Logs)**: Nhật ký phiên làm việc & sự kiện gốc tại `.agents/state/cases/` (Ground-truth để kiểm chứng ngược).
> - **Layer 2 (Memory Notes)**: Các quan sát nổi bật (*salient observations*), chiến lược đã kiểm chứng, quyết định kiến trúc và cảnh báo bẫy kỹ thuật tại bảng dưới đây & `.agents/state/learned_rules.json`.
> - **Layer 3 (Memory Representations / Wiki)**: Hệ thống tài liệu liên kết chéo tại `docs/` (`WORKFLOW_LIFECYCLE.md`, `ARCHITECTURE.md`, `SOURCE_AUDIT.md`, `docs/adrs/`).
> - **Layer 4 (Injected Context)**: Ngữ cảnh nạp tự động đầu mỗi phiên (`AGENTS.md`, `active_case.json`, `docs/HANDOFF.md`, và **tối đa 200 dòng đầu hoặc 25 KB của tệp `MEMORY.md` này**).
>
> **Nguyên tắc Vận hành**:
> 1. **Đơn quyền ghi (Single Writer)**: Duy nhất Coordinator Agent cập nhật tệp này sau khi đối chiếu chứng cứ gốc (`source_refs`).
> 2. **Không giới hạn chỉ ghi lỗi (Salience over Failure-Only)**: Ghi nhận cả chiến lược thành công, cấu hình chuẩn, và các bẫy kỹ thuật (traps).
> 3. **Kiểm chứng ngược khi Dreaming (Retroactive Drift Correction)**: Cuối mỗi Stage, đối chiếu lại các `MEM-*` cũ với Transcripts (`.agents/state/cases/`) và mã nguồn thực tế để sửa ngay các ghi chú bị lệch (drifted/corrupted notes).

---

## 1. Bảng Chỉ Mục Tri Thức Kỹ Thuật Đã Xác Minh (Layer 2 Verified Memory Notes)

| ID | Scope | Loại | Khẳng định cốt lõi & Cảnh báo bẫy (Validated Claim & Trap Warning) | Nguồn chứng cứ (`source_refs`) | Xác minh |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `MEM-001` | `REA_SECURITY` | `TECHNICAL_RULE` | Phân tích tĩnh (Static Inspection) không cấp quyền thực thi runtime. Mọi hành vi chạy app, mở cổng mạng hoặc kết nối ADB trên thiết bị thật đều cần phê duyệt riêng từ người dùng. | `docs/RULES.md`, `docs/SECURITY_REVIEW_MODEL.md` | 2026-11-14 |
| `MEM-002` | `ANDROID_TOOLING` | `TECHNICAL_RULE` | **Phân biệt rõ 3 nhóm công cụ Android**: (1) `inspect_android_package` là công cụ phân tích tĩnh JADX cục bộ (chỉ trích xuất Manifest text, permissions, classes — **KHÔNG phải lệnh ADB** và **KHÔNG giải mã `res/layout/*.xml` hay `drawables`**); (2) Giải mã `strings.xml`/resources dùng `decode_android_resources` (cần Apktool >= 2.9.2 chống CVE-2024-21633), còn bóc tách file layout/assets dùng `open_binary` + `inspect_artifact` / `extract_artifact`; (3) Runtime ADB dùng `android run <apk>`, `android layout --full`, `android screen capture -o <path>`, hoặc REA MCP `capture_adb_screen` (tham số JSON bắt buộc là `output_directory` dạng snake_case, đường dẫn tuyệt đối). | `docs/SOURCE_AUDIT.md`, `.agents/skills/reverse-engineer-anything/references/android-applications.md`, `docs/adrs/0005-android-apk-first-target-via-android-cli.md` | 2026-11-14 |
| `MEM-003` | `AGENT_COORDINATION` | `OPERATIONAL_POLICY` | Mô hình điều phối mặc định là Single Authoritative Coordinator kết hợp Subagents chạy trong context cô lập (chỉ đọc/phân tích). Subagents không giao tiếp trực tiếp với người dùng và không ghi đè `active_case.json`. | `docs/adrs/0004-single-coordinator-agent-model.md`, `REVIEW.md` | 2026-11-14 |
| `MEM-004` | `ENGINEERING_RECOVERY` | `VERIFIED_FIX` | **Bẫy Rollback**: `rollback.ps1` bắt buộc phải kiểm tra snapshot có chứa file thực tế (khác `.gitkeep`) trước khi xóa thư mục phát triển, và phải kiểm tra thuộc tính `ReparsePoint` (symlink/junction) trước khi gọi `Remove-Item -Recurse -Force` để tránh mất trắng mã nguồn. | `.agents/scripts/rollback.ps1`, `.agents/state/learned_rules.json` | 2026-11-14 |
| `MEM-005` | `UI_RESILIENCE` | `TECHNICAL_RULE` | Bảo toàn 100% dữ liệu người dùng đang nhập trên form khi xảy ra lỗi mạng/API hoặc chuyển sang trạng thái `Error`, đồng thời hiển thị nút `Thử lại (Retry)`. | `REVIEW.md`, `.agents/state/learned_rules.json` | 2026-11-14 |
| `MEM-006` | `REA_KNOWN_TRAPS` | `TRAP_WARNING` | **4 Bẫy Upstream REA cần rào chắn**: (1) JADX timeout ở 120s với APK multidex lớn -> gọi `update_analysis_settings` tăng `jadx.operation_timeout_ms`; (2) `start_adb_app` chỉ mở package đã cài sẵn và có thể báo `observed` giả khi Activity Manager timeout -> cài APK trước bằng `android run <apk>`; (3) Trên Windows x64, `inspect_android_package` có thể báo lỗi `Private DACL contains unexpected trustees` nếu `TEMP` kế thừa quyền rộng; (4) `android layout` trên Jetpack Compose chỉ thấy các node có khai báo semantics. | `docs/SOURCE_AUDIT.md`, `.agents/skills/rea-scan/SKILL.md` | 2026-11-14 |

---

## 2. Bản Đồ Liên Kết Tầng 3 (Layer 3 Wiki Representations)

- **Vòng đời 6 Stage · 14 Bước & 6 Cổng**: [`docs/WORKFLOW_LIFECYCLE.md`](../../docs/WORKFLOW_LIFECYCLE.md)
- **Kiến trúc Hệ thống & Định tuyến REA**: [`docs/ARCHITECTURE.md`](../../docs/ARCHITECTURE.md)
- **Hợp đồng Thẩm định Độc lập & Phân tầng Rủi ro**: [`REVIEW.md`](../../REVIEW.md)
- **Kiểm toán Nguồn Upstream & SHA (`rea-agents` v6.9.0 / Skill v62)**: [`docs/SOURCE_AUDIT.md`](../../docs/SOURCE_AUDIT.md)
- **Danh mục Quyết định Kiến trúc (ADRs 0001–0006)**: [`docs/adrs/`](../../docs/adrs/)

---

## 3. Quy Trình Dreaming & Memory Consolidation (5 Bước Chuẩn Anthropic)

1. **Thu thập Ground-Truth (Layer 1)**: Lưu tóm tắt sự kiện phiên, lệnh đã chạy và kết quả kiểm thử vào `.agents/state/cases/session_<YYYYMMDD_HHmmss>.md`.
2. **Kiểm chứng ngược ghi chú cũ (Retroactive Validation)**: Đối chiếu toàn bộ các mục `MEM-*` hiện có với Transcripts và mã nguồn. Nếu phát hiện ghi chú cũ bị sai hoặc lỗi thời (drift), sửa trực tiếp hoặc đánh dấu `DEPRECATED`.
3. **Trích xuất Salience (Strategies, Rules & Traps)**: Chọn lọc cả chiến lược giải quyết thành công lẫn lỗi đã khắc phục có chứng cứ xác thực (`source_refs`).
4. **Cập nhật Layer 2 & Giữ gọn Layer 4 Index**: Ghi vào bảng chỉ mục tại `MEMORY.md` (giữ tổng độ dài tệp <= 200 dòng / 25 KB; nếu vượt ngưỡng, tách chi tiết sang `.agents/state/cases/` và giữ liên kết tại đây).
5. **Đồng bộ Bàn giao**: Cập nhật `docs/HANDOFF.md` và `docs/PROGRESS.md`.
