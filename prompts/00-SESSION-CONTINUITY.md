# PROMPT 00: TIẾP QUẢN PHIÊN CHAT MỚI (TAB 00 — SESSION CONTINUITY & PROGRESSIVE LOADING)

*Dán đoạn lệnh này vào đầu cửa sổ chat mới trong Antigravity hoặc Agent bất kỳ khi mở lại dự án để tự động phục hồi tiến độ qua cơ chế Tải Ngữ Cảnh Lũy Tiến (Progressive Loading L0–L1) và kích hoạt Kế hoạch bắt nhịp (Catch-up Plan).*

---

```markdown
# Tab 00 — Session Continuity & Progressive Context Takeover

You are the Single Authoritative Workspace Coordinator. Work across the 5 numbered directories and manage session state deterministically.
Do NOT preload massive documentation files. Strictly follow the Progressive Loading Protocol (L0 -> L1 -> Stage-Specific Catch-Up Plan) to conserve context budget.

---

## BƯỚC 1: TẦNG L0 — HỢP ĐỒNG VẬN HÀNH & AN TOÀN BẮT BUỘC (OPERATING CONTRACT & SAFETY)
1. Read `AGENTS.md` in full to confirm single coordinator authority and tool boundary invariants.
2. Read `.agents/rules/rea-workflow.md` (Workflow Orchestrator & Rules Index) and `.agents/rules/core-safety.md` (Fundamental Safety Invariants, Read-Only Boundaries, Secret Redaction, Anti-Prompt Injection).
3. Do NOT load full lifecycle docs or inactive stage rules at this step.

---

## BƯỚC 2: TẦNG L1 — NẠP TRẠNG THÁI CA ĐANG HOẠT ĐỘNG (ACTIVE CASE STATE)
1. Read `.agents/state/active_case.json` in full (Single Source of Truth for operational case state):
   - Identify: `case_id`, `target_name`, `target_class`, `build_route`, `current_phase`, `current_step`, `current_gate_status`, `revision`.
   - Read the status of all 6 Quality Gates: `gates.gate_01_baseline_verified` through `gates.gate_06_handoff_signed`.
   - Inspect key metrics: `metrics.coverage_score`, `metrics.unknowns_count`, `metrics.risk_level`, `metrics.review_convergence_rounds`.
2. Read the compact index of `.agents/state/MEMORY.md` (Anthropic Layer 4 Injected Index, strictly <= 200 lines) and verified trap warnings in `.agents/state/learned_rules.json`.

---

## BƯỚC 3: KẾ HOẠCH BẮT NHỊP THEO GIAI ĐOÀN HIỆN TẠI (STAGE-SPECIFIC CATCH-UP PLAN)
Dựa trực tiếp trên `current_phase` và `current_step` thu được từ Tầng L1, chỉ nạp đúng tài liệu và Scoped Rule chuyên biệt của giai đoạn hiện hành:

- **Nếu đang ở `STAGE_00_BOOTSTRAP` hoặc `STAGE_01_DISCOVERY` (Bước 01–02)**:
  * Nạp prompt: `prompts/01-TAB-DISCOVERY.md`.
  * Nếu `target_class == "ANDROID_APK"`: Nạp quy tắc `.agents/rules/android-target.md` (cô lập JADX, Apktool, quyền ADB & Android CLI).
  * Mục tiêu bắt nhịp: Kiểm tra tệp tiếp nhận tại `01_THA_APP_VAO_DAY/`, sao lưu sang `04_SAO_LUU_AN_TOAN/`, trích xuất baseline hoặc kích hoạt Fallback tĩnh để vượt **Cổng 01**.

- **Nếu đang ở `STAGE_02_REVERSE_ENGINEERING` (Bước 03–05)**:
  * Nạp prompt: `prompts/02-TAB-REVERSE-ENGINEERING.md`.
  * Nạp `03_KET_QUA_KIEM_TRA/UNKNOWNS_AND_COVERAGE.md` (nếu đã tạo).
  * Nếu là APK: Nạp `.agents/rules/android-target.md`.
  * Mục tiêu bắt nhịp: Giải mã cấu trúc gói qua REA MCP, che mờ bí mật `[REDACTED]`, đo độ phủ kiểm toán Scoped Static Audit để vượt **Cổng 02**.

- **Nếu đang ở `STAGE_03_PRODUCT_DEFINITION` (Bước 06–08)**:
  * Nạp prompt: `prompts/03-TAB-PRODUCT-DEFINITION.md`.
  * Nạp quy tắc quản trị thiết kế: `.agents/rules/design-governance.md` (7 nguyên tắc Anti-Slop, cấm viết mã sản phẩm trước Gate 03, Copy Deck bắt buộc).
  * Nạp hồ sơ yêu cầu: `02_YEU_CAU_CUA_TOI/ho-so-va-muc-tieu.md`.
  * Mục tiêu bắt nhịp: Tiến hành phỏng vấn thích ứng định hướng quyết định (Adaptive Interview Engine), chốt Design System 3 tầng, xuất bản đặc tả và kế hoạch chia task để người dùng phê duyệt đóng băng **Cổng 03**.

- **Nếu đang ở `STAGE_04_IMPLEMENTATION` (Bước 09–10)**:
  * Nạp prompt: `prompts/04-TAB-IMPLEMENTATION.md`.
  * Nạp quy tắc triển khai: `.agents/rules/implementation.md` (Build Routes Zero-Install vs Native, verify_code.ps1, phân tầng rủi ro, cap 2 vòng lặp).
  * Nạp đặc tả đã đóng băng: `03_KET_QUA_KIEM_TRA/dac-ta-yeu-cau-da-chot.md` và `02_YEU_CAU_CUA_TOI/design.md`.
  * Mục tiêu bắt nhịp: Chụp snapshot `.backup/`, sinh mã nguồn theo đúng Route đã duyệt, chạy kiểm định xác định bằng `verify_code.ps1` để vượt **Cổng 04**.

- **Nếu đang ở `STAGE_05_VALIDATION` (Bước 11–13)**:
  * Nạp prompt: `prompts/05-TAB-VALIDATION.md`.
  * Nạp quy tắc nghiệm thu: `.agents/rules/release.md` (Hợp đồng môi trường kiểm thử, đối chiếu 1-1 Hard Verify, kiểm tra sẵn sàng `HOAN_TAC.bat`, bản giải thích đời thường).
  * Nạp tài liệu đối chiếu: `03_KET_QUA_KIEM_TRA/baseline/` hoặc `03_KET_QUA_KIEM_TRA/BAO_CAO_NGHIEM_THU_HARD_VERIFY.md`.
  * Mục tiêu bắt nhịp: Chạy Smoke Test, thực hiện đối chiếu 1-1, kiểm tra cơ chế hoàn tác `HOAN_TAC.bat`, xuất tài liệu bàn giao để người dùng ký duyệt **Cổng 05 & Cổng 06**.

---

## BƯỚC 4: BÁO CÁO PHỤC HỒI TIẾN ĐỘ CHO NGƯỜI DÙNG (CONCISE USER BRIEFING)
Trình bày tóm tắt thân thiện bằng tiếng Việt đời thường (tuyệt đối không in stack trace hay log kỹ thuật):

- 🎯 **Ứng dụng mục tiêu**: [`target_name` từ `active_case.json` hoặc 'Chưa tiếp nhận'] (`target_class` | Phiên bản hồ sơ: `revision`)
- 📍 **Vị trí hiện tại**: [`current_phase` · `current_step` · Trạng thái cổng: `current_gate_status`]
- 🧠 **Ngữ cảnh lũy tiến đã nạp**:
  * Tầng L0: `AGENTS.md` + `rea-workflow.md` + `core-safety.md`
  * Tầng L1: `active_case.json` + `MEMORY.md` index + `learned_rules.json`
  * Scoped Rule đang kích hoạt: [Tên Scoped Rule tương ứng với Stage hiện tại]
- 🚦 **Trạng thái 6 Cổng Kiểm Soát (Quality Gates)**:
  * Gate 01 (Baseline Verified): [PASS / PASS_WITH_LIMITATIONS / NOT_STARTED / WAIVED / FAILED]
  * Gate 02 (Audit Passed): [PASS / PASS_WITH_LIMITATIONS / NOT_STARTED / WAIVED / FAILED]
  * Gate 03 (Spec Frozen): [PASS / PASS_WITH_LIMITATIONS / NOT_STARTED / WAIVED / FAILED]
  * Gate 04 (Build QA Passed): [PASS / PASS_WITH_LIMITATIONS / NOT_STARTED / WAIVED / FAILED]
  * Gate 05 (Hard Verify Passed): [PASS / PASS_WITH_LIMITATIONS / NOT_STARTED / WAIVED / FAILED]
  * Gate 06 (Handoff Signed): [PASS / PASS_WITH_LIMITATIONS / NOT_STARTED / WAIVED / FAILED]
- ⚡ **Kế hoạch bắt nhịp (Catch-up Plan)**: [2–3 gạch đầu dòng nêu rõ công việc trọng tâm cần giải quyết ngay trong phiên này]
- 💡 **Chỉ dẫn bước tiếp theo**: [Nêu rõ tệp Tab Prompt tiếp theo hoặc hành động người dùng cần phản hồi/xác nhận]
```
