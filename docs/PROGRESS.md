# PROGRESS — REA-kit-agy

- Last updated: 2026-11-13
- Overall Project Status: **P01 IN_PROGRESS** (Repo Roadmap: P00 DONE, P01 ACTIVE)
- Case Lifecycle State: **STAGE_00_BOOTSTRAP** completed, ready for **STAGE_01_DISCOVERY**
- Product direction: REA-powered App Investigation & Development Kit (Target: Android APK V1, Skill-first)

---

## KIẾN TRÚC PHÂN LOẠI LỘ TRÌNH (TAXONOMY DECOUPLING)

Nhằm đảm bảo sự tách bạch tuyệt đối giữa việc phát triển công cụ kit và quy trình thực thi một ca phân tích ứng dụng của người dùng, dự án phân định rõ hai hệ quy chiếu:

1. **Lộ trình Phát triển Repo (Repo Development Roadmap — P00 đến P05)**:
   - **P00 (DONE)**: Nghiên cứu REA, thiết lập ranh giới sản phẩm, ban hành 6 ADRs nền tảng.
   - **P01 (IN_PROGRESS)**: Tích hợp công cụ REA MCP và Android CLI plugin với Antigravity, hoàn thiện bộ kỹ năng điều phối.
   - **P02 (TODO)**: Điều tra và đánh giá ứng dụng thực tế.
   - **P03 (TODO)**: Làm rõ yêu cầu và đóng băng đặc tả.
   - **P04 (TODO)**: Lập kế hoạch kiến trúc và thiết kế phát triển.
   - **P05 (TODO)**: Triển khai, kiểm thử độc lập và bàn giao.

2. **Quy trình Điều phối Ca Phân tích Ứng dụng (End-User Case Workflow — STAGE_00 đến STAGE_05)**:
   - Khung điều phối 6 giai đoạn chuẩn hóa, 14 bước nguyên tử và 6 cổng kiểm soát chất lượng do AI Agent thực hiện trên ứng dụng mục tiêu (`active_case.json`).

---

## BẢNG TIẾN ĐỘ QUY TRÌNH CASE 6 GIAI ĐOẠN · 14 BƯỚC (CASE LIFECYCLE CHECKLIST)

| Giai Đoạn (Case Stage) | Bước | Tên Nhiệm Vụ | Đầu Ra / Artifact | Cổng Kiểm Soát (Gate) | Trạng Thái |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **STAGE_00_BOOTSTRAP** | 00 | Project Bootstrap | Workspace, Git, Config, State | Gate 00: Ready | `[x] ĐẠT` |
| **STAGE_01_DISCOVERY** | 01 | App Intake / Preflight | Sao lưu sang `04_SAO_LUU_AN_TOAN/` | — | `[ ] CHỜ` |
| **STAGE_01_DISCOVERY** | 02 | Reference Baseline | Ảnh chụp baseline / Trích xuất tĩnh | **GATE 01**: `gate_01_baseline_verified` | `[ ] CHỜ` |
| **STAGE_02_REVERSE_ENGINEERING** | 03 | REA Scan | Screen Inventory, State Matrix | — | `[ ] CHỜ` |
| **STAGE_02_REVERSE_ENGINEERING** | 04 | REA Investigate | Luồng nghiệp vụ, API, Data flow | — | `[ ] CHỜ` |
| **STAGE_02_REVERSE_ENGINEERING** | 05 | REA Audit | `03_/UNKNOWNS_AND_COVERAGE.md` | **GATE 02**: `gate_02_audit_passed` | `[ ] CHỜ` |
| **STAGE_03_PRODUCT_DEFINITION** | 06 | REA Interview | Biên bản phỏng vấn nhu cầu | — | `[ ] CHỜ` |
| **STAGE_03_PRODUCT_DEFINITION** | 07 | Spec & Design Gate | `02_/design.md`, `03_/dac-ta-yeu-cau-da-chot.md` | — | `[ ] CHỜ` |
| **STAGE_03_PRODUCT_DEFINITION** | 08 | Implementation Plan | `03_/KE_HOACH_TRIEN_KHAI.md` | **GATE 03**: `gate_03_spec_frozen` | `[ ] CHỜ` |
| **STAGE_04_IMPLEMENTATION** | 09 | REA Build | Web App Zero-Install, `preview.html` | — | `[ ] CHỜ` |
| **STAGE_04_IMPLEMENTATION** | 10 | Build QA / Code Review | `03_/KET_QUA_KIEM_THU.md` | **GATE 04**: `gate_04_build_qa_passed` | `[ ] CHỜ` |
| **STAGE_05_VALIDATION** | 11 | Run App / Smoke Test | Khởi chạy thực tế trên trình duyệt | — | `[ ] CHỜ` |
| **STAGE_05_VALIDATION** | 12 | Hard Verify | `03_/BAO_CAO_NGHIEM_THU_HARD_VERIFY.md` | **GATE 05**: `gate_05_hard_verify_passed` | `[ ] CHỜ` |
| **STAGE_05_VALIDATION** | 13 | Release & Handoff | `05_/BAN_GIAO_SAN_PHAM.md` | **GATE 06**: `gate_06_handoff_signed` | `[ ] CHỜ` |

---

## 2026-11-13 — Phê Duyệt 6 Quyết Định Kiến Trúc (ADRs), Hoàn Tất P00, Kích Hoạt P01 & Chuẩn Hóa Phân Loại Lộ Trình

### Completed
- **Phê duyệt trọn bộ 6 Architecture Decision Records (ADRs) theo chuẩn MADR**:
  1. `docs/adrs/0001-multi-target-architecture.md`: Phạm vi sản phẩm đa mục tiêu; lát cắt V1 xác thực chuyên sâu duy nhất `ANDROID_APK`.
  2. `docs/adrs/0002-skill-first-delivery.md`: Sử dụng trực tiếp engine REA MCP upstream; điều phối qua Antigravity Skills tiếng Việt; không làm CLI wrapper thừa thãi.
  3. `docs/adrs/0003-hybrid-memory-architecture.md`: Cấu trúc bộ nhớ 4 tầng (Event log, Trạng thái vận hành `active_case.json`, Tri thức bền vững `learned_rules.json` + `docs/`, Ngữ cảnh nạp tự động); cục bộ 100%, bảo mật tuyệt đối.
  4. `docs/adrs/0004-single-coordinator-agent-model.md`: Mô hình Agent Điều Phối Đơn Lẻ (Single Coordinator) có toàn quyền; subagent chỉ dùng cho tác vụ cô lập; không ép buộc swarm trong V1.
  5. `docs/adrs/0005-android-apk-first-target-via-android-cli.md`: Mục tiêu V1 là Android APK; tích hợp trực tiếp plugin chính thức `android-cli-plugin` của Google Antigravity (Device Hub, AVD, SDK, Layout Inspector) kết hợp REA ADB.
  6. `docs/adrs/0006-cli-adr-management.md`: Quản lý ADR thuần file Markdown trong kho, không phụ thuộc UI web ngoài; cung cấp CLI script `.agents/scripts/adr.ps1`.
- **Cập nhật & Đóng toàn bộ các đầu việc P00-01 đến P00-08**:
  - P00-06 giải quyết dứt điểm qua quyết định `ANDROID_APK` và plugin Android CLI.
  - P00-07 giải quyết dứt điểm qua quyết định Skill-first delivery.
  - Chuyển trạng thái Lộ trình Repo: **P00 DONE**, **P01 IN_PROGRESS**.
- **Tách bạch hoàn toàn Hệ thống Phân loại (Taxonomy Decoupling)**:
  - Tách bạch Lộ trình Phát triển Kho (P00–P05) khỏi Quy trình Vòng đời Ca Phân tích của Người dùng (`STAGE_00_BOOTSTRAP` đến `STAGE_05_VALIDATION`).
  - Cập nhật `.agents/state/active_case.json`: `current_phase` chuyển thành `STAGE_00_BOOTSTRAP`, bổ sung `target_class` là `ANDROID_APK`.

---

## 2026-11-13 — Chuẩn Hóa Toàn Diện Khung 6 Giai Đoạn · 14 Bước & 6 Cổng Kiểm Soát Chất Lượng

### Completed
- Hoàn thành xuất sắc 3 vòng Grilling với 12 quyết định kiến trúc then chốt:
  1. **Đặc tả kiến trúc chuẩn hóa (`docs/WORKFLOW_LIFECYCLE.md`)**:
     - Đặc tả chi tiết từng bước từ Stage 00 đến Stage 05, luồng Mermaid và tiêu chí 6 Cổng kiểm soát.
  2. **Gom Tab Prompts tối ưu hóa UX**:
     - Khởi tạo bộ 5 Tab Prompts chuẩn (`prompts/01-TAB-DISCOVERY.md` đến `05-TAB-VALIDATION.md`) tương ứng 5 Giai đoạn thực thi, giúp người non-tech chỉ cần dán 5 lần.
  3. **Cơ chế Fallback Bước 02 (Reference Baseline)**:
     - Tự động chuyển sang trích xuất tài nguyên tĩnh và đánh dấu `SKIPPED (Tĩnh)` khi thiếu máy ảo/thiết bị thật.
  4. **Bổ sung trọn bộ 4 Templates mới**:
     - `templates/06-UNKNOWNS-AND-COVERAGE-TEMPLATE.md` (Bước 05)
     - `templates/07-IMPLEMENTATION-PLAN-TEMPLATE.md` (Bước 08)
     - `templates/08-HARD-VERIFY-TEMPLATE.md` (Bước 12)
     - `templates/09-HANDOFF-BUNDLE-TEMPLATE.md` (Bước 13)
  5. **Nâng cấp máy trạng thái (`active_case.json`) & Auto-Resume**:
     - Hỗ trợ đầy đủ 6 cờ boolean kiểm soát chất lượng (`gates`), theo dõi bước con và in banner chỉ dẫn bước tiếp theo trong `health_check.ps1`.
  6. **Quy tắc sửa sai (Reject/Retry Loop)**:
     - Tự động tạo bản revision `_v2`, lùi trạng thái về đúng bước cần sửa mà không xóa lịch sử cũ.
  7. **Đồng bộ hóa toàn bộ Skills & Rules**:
     - Cập nhật `rea-scan`, `rea-interview`, `rea-build`, `AGENTS.md`, `.agents/rules/rea-workflow.md`.
  8. **Kiểm tra sức khỏe đạt 6/6 PASSED**.

---

## 2026-11-13 — Hoàn Thiện Trọn Bộ Anthropic Pipeline: Explainers Over Diffs, Tab 05 Review, Accountability & Risk Classifier

### Completed
- Hoàn thành phiên Grilling về 4 mảnh ghép cuối cùng từ bài viết *"How the Claude Code team does code review"*:
  1. **Bản giải thích cho người dùng thay vì đọc diff (Explainers Over Diffs)**:
     - Bắt buộc xuất mục Plain-Language Explainer trong `templates/03-RUN-GUIDE-TEMPLATE.md` và `templates/04-TEST-RESULT-TEMPLATE.md` trả lời 3 câu hỏi (vừa sửa gì, tại sao, giao diện khác ở đâu) bằng tiếng Việt đời thường.
  2. **Thẩm định độc lập trong Fresh Context (`prompts/05-TAB-REVIEW.md`)**:
     - Tạo Tab Prompt 05 cho phép mở cửa sổ chat sạch hoàn toàn độc lập với lượt viết code, xóa sạch thiên kiến AI.
  3. **Hộp kiểm trách nhiệm con người ("You Land It, You Own It")**:
     - Bổ sung ô kiểm tra trách nhiệm vận hành tại Tầng 4 của `templates/04-TEST-RESULT-TEMPLATE.md`.
  4. **Tự động phân loại rủi ro trong `verify_code.ps1` (Automated Risk Classifier)**:
     - Tự động quét và phát hiện các hành vi gọi mạng (`fetch`, `http`), storage (`localStorage`), gán cờ `LOW / MEDIUM / HIGH`.
  5. **Đồng bộ hóa hệ sinh thái**:
     - Cập nhật `UPSTREAMS.md`, `README.md`, `prompts/BOOTSTRAP_KIT.md`, và `docs/HANDOFF.md`.
     - Health check đạt 6/6 PASSED.

---

## 2026-11-13 — Nâng Cấp Chuyên Sâu Anthropic Pipeline: REVIEW.md, High-Signal Filter, Incidents-to-Evals & Staged Preview

### Completed
- Hoàn thành phiên Grilling về 4 nâng cấp chuyên sâu kế thừa từ bài viết *"How the Claude Code team does code review"*:
  1. **Khởi tạo Hợp đồng Thẩm định riêng biệt (`REVIEW.md`)**:
     - Quy chuẩn hóa toàn bộ checklist kiểm toán độc lập 4 tầng, ranh giới Zero-Install, bảo vệ secret, và phân tầng rủi ro.
  2. **Bộ lọc dẹp nhiễu phản hồi (High-Signal Filter)**:
     - Nghiêm cấm AI Reviewer bắt bẻ phong cách viết mã (code style/comment) làm phiền người non-tech; chỉ báo cáo vi phạm hợp đồng (Spec, Tokens, 4 UI States, cú pháp).
  3. **Cơ chế ghi nhớ học từ sự cố (Incidents to Evals)**:
     - Tạo bộ nhớ `.agents/state/learned_rules.json`: Mỗi lần có sự cố hoặc người dùng hoàn tác, AI tự động đúc rút quy tắc cấm để không bao giờ tái phạm.
  4. **Bản xem trước an toàn theo giai đoạn (Staged Preview)**:
     - Khi nâng cấp/sửa lỗi, AI xuất ra `05_MA_NGUON_PHAT_TRIEN/preview.html` để người dùng duyệt trước; chỉ chuyển thành `index.html` khi người dùng phê duyệt.
  5. **Đồng bộ hóa hệ sinh thái**:
     - Cập nhật `.agents/skills/rea-build/SKILL.md`, `.agents/scripts/health_check.ps1`, `prompts/04-TAB-BUILD.md`, `README.md`, `prompts/BOOTSTRAP_KIT.md`, `docs/HANDOFF.md`.
     - Health check đạt 6/6 PASSED.

---

## 2026-11-13 — Tích Hợp Mô Hình Anthropic Code Review (Independent Reviewer, Convergence & 1-Click Rollback)

### Completed
- Nghiên cứu và tích hợp trọn bộ 4 bài học cốt lõi từ bài viết *"How the Claude Code team does code review"* của Anthropic vào `REA-kit-agy`:
  1. **Tách biệt vai trò Builder & Independent Reviewer**:
     - Trong `rea-build` và `templates/04-TEST-RESULT-TEMPLATE.md`, AI thẩm định độc lập theo 2 trục tách biệt: Trục Tiêu chuẩn Giao diện (Standards Review đối chiếu `design.md`) và Trục Đặc tả Chức năng (Spec Review đối chiếu `dac-ta-yeu-cau-da-chot.md`), xóa bỏ thiên kiến xác nhận của AI.
  2. **Khống chế vòng lặp tự sửa (Review Convergence Cap)**:
     - Giới hạn tối đa 2 vòng lặp tự động sửa lỗi cú pháp/logic. Sau 2 vòng nếu không vượt qua `verify_code.ps1` thì dừng lại báo cáo trực diện người dùng, ngăn ngừa lặp vô tận đốt token.
  3. **Phân tầng rủi ro nghiệm thu (Risk-Tiered Sign-off)**:
     - Phân loại 3 cấp độ: Thấp (UI/text -> Auto-approve sau syntax test), Vừa (Form/local logic -> Checklist tính năng), Cao (API ngoài/secret -> Cảnh báo đỏ [HIGH RISK] bắt buộc con người xác nhận).
  4. **Lá chắn hoàn tác 1-Click (`HOAN_TAC.bat` & `rollback.ps1`)**:
     - Tự động lưu snapshot mã nguồn vào `05_MA_NGUON_PHAT_TRIEN/.backup/` trước mỗi đợt sinh code mới.
     - Tạo script `HOAN_TAC.bat` và `.agents/scripts/rollback.ps1` giúp người non-tech hoàn tác 100% về phiên bản chạy tốt gần nhất chỉ bằng 1 cú nhấp đúp chuột.
  5. **Đồng bộ hóa hệ sinh thái**:
     - Cập nhật `templates/04-TEST-RESULT-TEMPLATE.md`, `.agents/skills/rea-build/SKILL.md`, `prompts/04-TAB-BUILD.md`, `UPSTREAMS.md`, `README.md`, `prompts/BOOTSTRAP_KIT.md`, và `docs/HANDOFF.md`.
