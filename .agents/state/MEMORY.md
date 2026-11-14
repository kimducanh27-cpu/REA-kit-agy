# MEMORY INDEX — REA-kit-agy (Anthropic 4-Layer Agent Memory Architecture)
> **Kiến trúc 4 Tầng Bộ Nhớ (Anthropic Research, 06/11/2026)**:
> - **Layer 1 (Transcripts & Append-Only Event Logs)**: Nhật ký sự kiện gốc tại `.agents/state/events.jsonl` và biên bản phiên tại `.agents/state/cases/` (Ground-truth bất biến để kiểm chứng ngược).
> - **Layer 2 (Memory Notes & Provenance)**: Các quan sát nổi bật (*salient observations*), chiến lược đã kiểm chứng, quyết định kiến trúc và cảnh báo bẫy kỹ thuật tại bảng dưới đây & `.agents/state/learned_rules.json`.
> - **Layer 3 (Memory Representations / Wiki)**: Hệ thống tài liệu liên kết chéo tại `docs/` (`WORKFLOW_LIFECYCLE.md`, `ARCHITECTURE.md`, `SOURCE_AUDIT.md`, `docs/adrs/`).
> - **Layer 4 (Injected Context)**: Ngữ cảnh nạp tự động đầu mỗi phiên (`AGENTS.md`, `active_case.json`, `docs/HANDOFF.md`, và **tối đa 200 dòng đầu hoặc 25 KB của tệp `MEMORY.md` này**).
>
> **Nguyên tắc Vận hành**:
> 1. **Đơn quyền ghi (Single Writer)**: Duy nhất Workspace Coordinator cập nhật tệp này sau khi đối chiếu chứng cứ gốc (`source_refs`).
> 2. **Không giới hạn chỉ ghi lỗi (Salience over Failure-Only)**: Ghi nhận cả chiến lược thành công, cấu hình chuẩn, và các bẫy kỹ thuật (traps).
> 3. **Kiểm chứng ngược khi Dreaming (Retroactive Drift Correction)**: Cuối mỗi Stage, đối chiếu lại các `MEM-*` cũ với Event Logs (`events.jsonl`) và mã nguồn thực tế để sửa ngay các ghi chú bị lệch (drifted/corrupted notes).
> 4. **Minh bạch trạng thái (Status Governance)**: Phân định rõ `DOCUMENTED` (đã quy định trong tài liệu/hợp đồng) và `RUNTIME_VERIFIED` (đã chạy kiểm thử thành công trên môi trường thực tế).

---

## 1. Bảng Chỉ Mục Tri Thức Kỹ Thuật (Layer 2 Memory Notes with Provenance)

| ID | Scope | Trạng thái (Status) | Độ tin cậy (Confidence) | Khẳng định cốt lõi & Cảnh báo bẫy (Validated Claim & Trap Warning) | Nguồn chứng cứ (`source_refs`) | Xác minh |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `MEM-001` | `REA_SECURITY` | `DOCUMENTED` | `HIGH` | Phân tích tĩnh (Static Inspection) không cấp quyền thực thi runtime. Mọi hành vi chạy app, mở cổng mạng hoặc kết nối ADB trên thiết bị thật đều cần phê duyệt riêng từ người dùng. | `docs/RULES.md:20-25`, `docs/SECURITY_REVIEW_MODEL.md:40-60` | 2026-11-14 |
| `MEM-002` | `ANDROID_TOOLING` | `DOCUMENTED` | `HIGH` | **Phân biệt rõ 3 nhóm công cụ Android**: (1) `inspect_android_package` là công cụ phân tích tĩnh JADX cục bộ (chỉ trích xuất Manifest text, permissions, classes — **KHÔNG phải lệnh ADB** và **KHÔNG giải mã `res/layout/*.xml` hay `drawables`**); (2) Giải mã `strings.xml`/resources dùng `decode_android_resources` (cần Apktool >= 2.9.2 chống CVE-2024-21633), còn bóc tách file layout/assets dùng `open_binary` + `inspect_artifact` / `extract_artifact`; (3) Runtime ADB dùng `android run <apk>`, `android layout --full`, `android screen capture -o <path>`, hoặc REA MCP `capture_adb_screen` (tham số JSON bắt buộc là `output_directory` dạng snake_case, đường dẫn tuyệt đối). | `docs/SOURCE_AUDIT.md:45-80`, `.agents/skills/reverse-engineer-anything/references/android-applications.md`, `docs/adrs/0005-android-apk-first-target-via-android-cli.md` | 2026-11-14 |
| `MEM-003` | `AGENT_COORDINATION` | `DOCUMENTED` | `HIGH` | Mô hình điều phối mặc định là Single Authoritative Coordinator kết hợp Subagents chạy trong context cô lập (chỉ đọc/phân tích). Subagents không giao tiếp trực tiếp với người dùng và không ghi đè `active_case.json`. | `docs/adrs/0004-single-coordinator-agent-model.md:30-55`, `REVIEW.md:15-30` | 2026-11-14 |
| `MEM-004` | `ENGINEERING_RECOVERY` | `SUPERSEDED` | `HIGH` | **Bẫy Rollback & ReparsePoint**: Lệnh `Remove-Item -Recurse -Force` nguyên thủy của PowerShell bị cấm tuyệt đối trên Windows ReparsePoint (symlink/junction) do nguy cơ xóa xuyên ra ngoài thư mục dự án. Được thay thế hoàn toàn bởi hàm chuyên dụng `Remove-SafeItem` kết hợp cơ chế hoán đổi nguyên tử 2 giai đoạn (Staging Atomic Swap) và kiểm tra tệp `manifest.json` chứa mã băm SHA-256. | `.agents/scripts/rollback.ps1:36-48`, `docs/WORKFLOW_LIFECYCLE.md:215-225` | 2026-11-14 |
| `MEM-005` | `UI_RESILIENCE` | `DOCUMENTED` | `HIGH` | Bảo toàn 100% dữ liệu người dùng đang nhập trên form khi xảy ra lỗi mạng/API hoặc chuyển sang trạng thái `Error`, đồng thời hiển thị nút `Thử lại (Retry)` để người dùng không phải gõ lại. | `REVIEW.md:45-55`, `.agents/state/learned_rules.json` | 2026-11-14 |
| `MEM-006` | `REA_KNOWN_TRAPS` | `DOCUMENTED` | `HIGH` | **4 Bẫy Upstream REA cần rào chắn**: (1) JADX timeout ở 120s với APK multidex lớn -> gọi `update_analysis_settings` tăng `jadx.operation_timeout_ms`; (2) `start_adb_app` chỉ mở package đã cài sẵn và có thể báo `observed` giả khi Activity Manager timeout -> cài APK trước bằng `android run <apk>`; (3) Trên Windows x64, `inspect_android_package` có thể báo lỗi `Private DACL contains unexpected trustees` nếu `TEMP` kế thừa quyền rộng -> cô lập `TEMP`/`TMP` trong `KIEM_TRA.bat`; (4) `android layout` trên Jetpack Compose chỉ thấy các node có khai báo semantics. | `docs/SOURCE_AUDIT.md:90-130`, `.agents/skills/rea-scan/SKILL.md:45-55` | 2026-11-14 |

---

## 2. Bản Đồ Liên Kết Tầng 3 (Layer 3 Wiki Representations)

- **Vòng đời 6 Stage · 14 Bước & 6 Cổng**: [`docs/WORKFLOW_LIFECYCLE.md`](../../docs/WORKFLOW_LIFECYCLE.md)
- **Kiến trúc Hệ thống & Định tuyến REA**: [`docs/ARCHITECTURE.md`](../../docs/ARCHITECTURE.md)
- **Hợp đồng Thẩm định Độc lập & Phân tầng Rủi ro**: [`REVIEW.md`](../../REVIEW.md)
- **Kiểm toán Nguồn Upstream & SHA (`rea-agents` v6.9.0 / Skill v62)**: [`docs/SOURCE_AUDIT.md`](../../docs/SOURCE_AUDIT.md)
- **Danh mục Quyết định Kiến trúc (ADRs 0001–0006)**: [`docs/adrs/`](../../docs/adrs/)

---

## 3. Quy Trình Dreaming & Memory Consolidation (5 Bước Chuẩn Anthropic)

1. **Thu thập Ground-Truth (Layer 1)**: Đọc nhật ký sự kiện từ `.agents/state/events.jsonl` và biên bản phiên tại `.agents/state/cases/`.
2. **Kiểm chứng ngược ghi chú cũ (Retroactive Validation)**: Đối chiếu toàn bộ các mục `MEM-*` hiện có với Event Logs và mã nguồn. Nếu phát hiện ghi chú cũ bị lệch (drift), sửa trực tiếp hoặc chuyển thành `SUPERSEDED` / `RETRACTED`.
3. **Trích xuất Salience (Strategies, Rules & Traps)**: Chọn lọc chiến lược giải quyết thành công và bẫy kỹ thuật có chứng cứ xác thực (`source_refs`).
4. **Cập nhật Layer 2 & Giữ gọn Layer 4 Index**: Ghi vào bảng chỉ mục tại `MEMORY.md` (giữ tổng độ dài tệp <= 200 dòng / 25 KB; nếu vượt ngưỡng, tách chi tiết sang `.agents/state/cases/` và giữ liên kết tại đây).
5. **Đồng bộ Bàn giao**: Cập nhật `docs/HANDOFF.md` và `docs/PROGRESS.md`.
