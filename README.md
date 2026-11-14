# REA-kit-agy v1.1

[![Release](https://img.shields.io/badge/Release-v1.1-blue.svg)](https://github.com/kimducanh27-cpu/REA-kit-agy/releases/tag/v1.1)
[![Tests](https://img.shields.io/badge/Tests-35%2F35%20PASS-brightgreen.svg)](.agents/scripts/test_interview.ps1)
[![Health Check](https://img.shields.io/badge/Health%20Check-6%2F6%20OK-brightgreen.svg)](.agents/scripts/health_check.ps1)
[![ADR](https://img.shields.io/badge/ADR-7%2F7%20MADR-blueviolet.svg)](docs/adrs/)
[![Target](https://img.shields.io/badge/Target-Android%20APK%20%7C%20Web%20%7C%20Desktop-orange.svg)](docs/PRD.md)

**Bộ kit giao diện thư mục trực quan dành cho người dùng non-tech: Kiểm tra ứng dụng, bóc tách cấu trúc pháp y, phỏng vấn nhu cầu thích ứng có cấu trúc, và phát triển/viết lại app bằng AI (Google Antigravity & REA Engine) theo chuẩn 6 Giai đoạn · 14 Bước.**

---

## 1. Sơ đồ Luồng Vòng Đời 6 Giai Đoạn · 14 Bước (Master Lifecycle)

```mermaid
flowchart TD
    subgraph P0["PHASE 00 · FOUNDATION"]
        S00["00. PROJECT BOOTSTRAP<br/>(Git, Workspace, Agent Config, Context Docs)"]
    end

    subgraph P1["PHASE 01 · DISCOVERY (Tab 01)"]
        S01["01. APP INTAKE / PREFLIGHT<br/>(Nhận app, kiểm tra file, sao lưu an toàn)"]
        S02["02. REFERENCE BASELINE<br/>(Chạy thử app gốc, chụp ảnh UI / Fallback tĩnh)"]
        G1{"CỔNG 01: Baseline Verified?"}
    end

    subgraph P2["PHASE 02 · REVERSE ENGINEERING (Tab 02)"]
        S03["03. REA SCAN<br/>(Bóc tách cấu trúc, che mờ [REDACTED], State Matrix)"]
        S04["04. REA INVESTIGATE<br/>(Truy vết hàm nghiệp vụ, API, Data Flow)"]
        S05["05. REA AUDIT<br/>(Kiểm toán bằng chứng, đo Coverage, Sổ Unknowns)"]
        G2{"CỔNG 02: Audit Passed?"}
    end

    subgraph P3["PHASE 03 · PRODUCT DEFINITION (Tab 03)"]
        S06["06. REA INTERVIEW (Adaptive)<br/>(12-Step Engine, 10 Domains, interview.ps1)"]
        EX{"EXIT GATE: Sufficiency Check"}
        S07["07. SPEC & DESIGN GATE<br/>(Mobile Matrix, Tokens 3 tầng, Anti-Slop)"]
        S08["08. IMPLEMENTATION PLAN<br/>(Chia 6 Vertical Slices nguyên tử)"]
        G3{"CỔNG 03: Spec Frozen?"}
    end

    subgraph P4["PHASE 04 · IMPLEMENTATION (Tab 04)"]
        S09["09. REA BUILD<br/>(4 Routes: Extend / Branch / Compatible / Rewrite)"]
        S10["10. BUILD QA / CODE REVIEW<br/>(Thẩm định Standards vs Spec, verify_code.ps1)"]
        G4{"CỔNG 04: Build QA Passed?"}
    end

    subgraph P5["PHASE 05 · VALIDATION (Tab 05)"]
        S11["11. RUN APP / SMOKE TEST<br/>(Khởi chạy app mới: Web Zero-Install / Android AVD)"]
        S12["12. HARD VERIFY<br/>(Đối chiếu 1-1 với app gốc: Khớp / Khác biệt / Nâng cấp)"]
        G5{"CỔNG 05: Hard Verify Passed?"}
        S13["13. RELEASE & HANDOFF<br/>(Đóng gói, Explainer đời thường, HOAN_TAC.bat)"]
        G6{"CỔNG 06: Handoff Signed?"}
    end

    S00 --> S01 --> S02 --> G1
    G1 -- Đạt --> S03 --> S04 --> S05 --> G2
    G2 -- Đạt / Bỏ qua hợp lệ --> S06 --> EX
    EX -- SUFFICIENT --> S07 --> S08 --> G3
    EX -- BLOCKED / NEEDS_INPUT --> S06
    G3 -- Duyệt --> S09 --> S10 --> G4
    G4 -- Đạt --> S11 --> S12 --> G5
    G5 -- Đạt --> S13 --> G6

    %% Reject / Retry Loops
    G3 -. Sửa Spec .->|Tạo v2| S06
    G4 -. Lỗi cú pháp / Vượt 2 vòng .->|Sửa code| S09
    G5 -. Chưa khớp app gốc .->|Bản vá bổ sung| S09
```

---

## 2. Bảng Ma Trận 6 Cổng Kiểm Soát Chất Lượng & Interview Exit Gate

| Cổng Kiểm Soát | Vị Trí Vòng Đời | Điều Kiện Vượt Qua (Passing Criteria) | Hành Động Khi Bị Từ Chối (Reject Loop) |
| :--- | :--- | :--- | :--- |
| **GATE 01** (`gate_01_baseline_verified`) | Sau Bước 02 | Có ảnh chụp baseline thực tế HOẶC đã bóc tách tài nguyên tĩnh dự phòng. | Bổ sung file vào `01_` hoặc chạy lại chế độ Static Fallback. |
| **GATE 02** (`gate_02_audit_passed`) | Sau Bước 05 | Hoàn thành kiểm toán tĩnh; che mờ API Keys `[REDACTED]`; đưa điểm mù vào Sổ Unknowns. *(Cho phép trạng thái `SKIPPED`/`NOT_APPLICABLE` trong WF03)*. | Điều tra bổ sung các file nghi vấn tại Bước 04. |
| **INTERVIEW EXIT GATE** (`evaluate-sufficiency`) | Sau Bước 06 | Lệnh `interview.ps1 evaluate-sufficiency` đạt **`SUFFICIENT`**; 0 mâu thuẫn (`CRITICAL`/`MAJOR`); 0 giả định rủi ro cao chưa duyệt. | Trả lời tiếp các câu hỏi làm rõ hoặc xử lý mâu thuẫn kiến trúc. |
| **GATE 03** (`gate_03_spec_frozen`) | Sau Bước 08 | Người dùng phê duyệt `APPROVE UI SPEC` và `FREEZE UI SPEC` trên `dac-ta-yeu-cau-da-chot.md` và `KE_HOACH_TRIEN_KHAI.md`. | Tạo bản `SPEC_v2.md`, lùi về Bước 06/07 để phỏng vấn lại. Không xóa bản cũ. |
| **GATE 04** (`gate_04_build_qa_passed`) | Sau Bước 10 | Syntax check 100% OK (`verify_code.ps1`), 0 cờ nguy hiểm chưa duyệt, Independent Reviewer PASS. | Lùi về Bước 09 tối đa 2 lần. Nếu vẫn lỗi, dừng lại xin ý kiến người dùng. |
| **GATE 05** (`gate_05_hard_verify_passed`) | Sau Bước 12 | Người dùng xác nhận bảng đối chiếu Hard Verify đạt yêu cầu. | Tạo `FIX_PLAN_v2.md`, lùi về Bước 09 để sửa code cục bộ. |
| **GATE 06** (`gate_06_handoff_signed`) | Sau Bước 13 | Người dùng ký nhận bàn giao, đã kiểm tra `HOAN_TAC.bat` sẵn sàng. | Hoàn tất dự án, lưu hồ sơ bàn giao đóng case. |

---

## 3. Cấu Trúc Thư Mục Chuẩn v1.1 (Self-Explanatory Tree)

```text
REA-kit-agy/
├── 01_THA_APP_VAO_DAY/             # [Phase 01]: Nơi thả APK, ASAR, zip, web link & ảnh baseline
├── 02_YEU_CAU_CUA_TOI/            # [Phase 03]: ho-so-va-muc-tieu.md, design.md (Tokens 3 tầng)
├── 03_KET_QUA_KIEM_TRA/           # [Phase 02-05]: Báo cáo, Unknowns, Spec chốt, Kế hoạch & Nghiệm thu
├── 04_SAO_LUU_AN_TOAN/            # [Bảo vệ]: Bản sao lưu gốc bất khả xâm phạm (Chỉ đọc)
├── 05_MA_NGUON_PHAT_TRIEN/        # [Phase 04-05]: Mã nguồn phát triển, preview, bàn giao & .backup/
├── AGENTS.md                      # Não bộ & luật vận hành 6 Giai đoạn · 14 Bước
├── CLAUDE.md                      # Tương thích Claude Code (@AGENTS.md)
├── REVIEW.md                      # Hợp đồng thẩm định độc lập & bộ lọc dẹp nhiễu
├── UPSTREAMS.md                   # Đăng ký chuẩn nguồn gốc morluto/rea v62
├── HUONG_DAN_SU_DUNG.md           # Hướng dẫn sử dụng 1 trang kèm câu lệnh copy-paste
├── KIEM_TRA.bat                   # 1-click kiểm tra sức khỏe workspace & tự động cô lập JADX TEMP
├── HOAN_TAC.bat                   # 1-click hoàn tác về bản chạy tốt gần nhất (Rollback an toàn ReparsePoint)
├── .gitignore                     # Bảo vệ bản quyền, secrets và chống rò rỉ dữ liệu cá nhân
├── prompts/                       # Bộ câu lệnh dán theo từng Phase & Điều phối DAG
│   ├── 00-WORKFLOW-ROUTER.md      # Định tuyến luồng điều phối (RWO v2) & Lập Execution Plan
│   ├── 00-SESSION-CONTINUITY.md   # Phục hồi phiên & Auto-Resume
│   ├── 01-TAB-DISCOVERY.md        # Phase 01: Intake & Baseline
│   ├── 02-TAB-REVERSE-ENGINEERING.md # Phase 02: Scan & Audit
│   ├── 03-TAB-PRODUCT-DEFINITION.md  # Phase 03: Phỏng vấn thích ứng, Spec Freeze & Mobile Matrix
│   ├── 04-TAB-IMPLEMENTATION.md   # Phase 04: Build & Build QA / Review
│   ├── 05-TAB-VALIDATION.md       # Phase 05: Smoke Test, Hard Verify & Handoff
│   ├── 06-CONSOLIDATION-AND-MEMORY.md # Tầng Dreaming: Tổng hợp bộ nhớ đa phiên
│   ├── 07-CHANGE-REQUEST.md       # Quản trị yêu cầu thay đổi, Impact Analysis & Rejoin
│   ├── 08-SKIP-WAIVER-POLICY.md   # Chính sách Skip, Waiver & Công bố rủi ro
│   └── BOOTSTRAP_KIT.md           # Siêu lệnh nhân bản bộ kit
├── templates/                     # Khung mẫu tài liệu hợp đồng chuẩn (01 đến 14)
│   ├── 01-REPORT-TEMPLATE.md      # Báo cáo hiện trạng
│   ├── 02-SPEC-TEMPLATE.md        # Đặc tả yêu cầu đóng băng (kèm Mobile Display Compatibility Matrix)
│   ├── 03-RUN-GUIDE-TEMPLATE.md   # Hướng dẫn chạy 1 trang
│   ├── 04-TEST-RESULT-TEMPLATE.md # Chứng chỉ kiểm thử & QA
│   ├── 05-DESIGN-TOKEN-TEMPLATE.md# Hợp đồng Design Tokens 3 tầng
│   ├── 06-UNKNOWNS-AND-COVERAGE-TEMPLATE.md # Sổ theo dõi điểm mù & độ phủ
│   ├── 07-IMPLEMENTATION-PLAN-TEMPLATE.md   # Kế hoạch chia task nguyên tử
│   ├── 08-HARD-VERIFY-TEMPLATE.md # Bảng đối chiếu 1-1 với app gốc
│   ├── 09-HANDOFF-BUNDLE-TEMPLATE.md # Biên bản bàn giao sản phẩm
│   ├── 10-CASE-MANIFEST-TEMPLATE.json # Canonical schema cho active_case.json v2
│   ├── 11-HANDOFF-CONTRACT-TEMPLATE.json # Hợp đồng bàn giao pha kèm SHA-256
│   ├── 12-ART-DIRECTION-TEMPLATE.md # Định hướng nghệ thuật & 3 Chế độ thiết kế
│   ├── 13-COPY-DECK-TEMPLATE.md   # Hồ sơ nội dung văn bản thực tế (cấm placeholder slop)
│   └── 14-INTERVIEW-STATE-TEMPLATE.json # Schema JSON chuẩn cho interview_state.json v1.1
├── docs/                          # Hệ thống quản lý ngữ cảnh đa phiên (Context Docs)
│   ├── WORKFLOW_LIFECYCLE.md      # Đặc tả chuẩn hóa 6 Giai đoạn · 14 Bước
│   ├── INTAKE_QUESTION_LOGIC.md   # Quy chuẩn động cơ sàng lọc câu hỏi & Exit Gate
│   ├── ADAPTIVE_INTERVIEW_FRAMEWORK.md # Khung phỏng vấn thích ứng & chống UI Slop
│   ├── APP_REVIEW_WORKFLOW.md     # Quy trình rà soát ứng dụng tích hợp 10 Domain
│   ├── WORKFLOW_DEPENDENCIES.md   # Đồ thị phụ thuộc DAG & Ma trận thu hồi thác đổ
│   ├── PROGRESS.md                # Bảng tiến độ 14 bước tự động đồng bộ
│   ├── HANDOFF.md                 # Hồ sơ bàn giao dự án
│   ├── ARCHITECTURE.md            # Kiến trúc hệ thống & Traceability 1-1
│   ├── adrs/                      # 7 Bản ghi quyết định kiến trúc chuẩn MADR
│   │   ├── 0001-multi-target-architecture.md
│   │   ├── 0002-skill-first-delivery.md
│   │   ├── 0003-hybrid-memory-architecture.md
│   │   ├── 0004-single-coordinator-agent-model.md
│   │   ├── 0005-android-apk-first-target-via-android-cli.md
│   │   ├── 0006-cli-adr-management.md
│   │   └── 0007-conditional-workflow-orchestration.md
│   └── PRD.md, RULES.md, PLAN.md, TASKS.md, SOURCE_AUDIT.md...
└── .agents/                       # Phân hệ kỹ thuật điều phối (Technical Workspace)
    ├── mcp_config.json            # Cấu hình MCP phạm vi workspace (pin rea-agents@6.9.0)
    ├── rules/rea-workflow.md      # Luật an toàn REA (trigger: always_on)
    ├── skills/                    # Kỹ năng lõi REA v62 + 6 Skills điều phối tiếng Việt
    │   ├── reverse-engineer-anything/ # Upstream REA v62 (229 tools, 8 references)
    │   ├── rea-scan/              # Điều phối Intake & Scan (Steps 01-04)
    │   ├── rea-audit/             # Kiểm toán bằng chứng độc lập & Coverage (Step 05)
    │   ├── rea-interview/         # Phỏng vấn thích ứng & Hợp đồng giao diện (Steps 06-07)
    │   │   ├── SKILL.md           # Hợp đồng 12 bước, Question Necessity & Exit Gate
    │   │   └── domains/           # 10 Cẩm nang chuyên môn + 5 Aliases tương thích ngược
    │   │       ├── bug-fix.md (alias: application-diagnosis.md)
    │   │       ├── app-optimization.md (alias: performance-optimization.md)
    │   │       ├── security-hardening.md (alias: security-privacy.md)
    │   │       ├── feature-addition.md (alias: feature-discovery.md)
    │   │       ├── ux-ui-improvement.md (alias: ux-workflows.md)
    │   │       ├── feature-optimization.md
    │   │       ├── architecture-maintainability.md
    │   │       ├── platform-compatibility.md
    │   │       ├── requirements-prioritization.md
    │   │       └── acceptance-criteria.md
    │   ├── rea-plan/              # Lập kiến trúc & chia 6 Vertical Slices (Step 08)
    │   ├── rea-build/             # Triển khai mã nguồn theo lát cắt & bàn giao (Steps 09-13)
    │   └── memory-consolidation/  # Nuôi dưỡng bộ nhớ Anthropic Dreaming
    ├── state/                     # Bộ nhớ 4 tầng & Máy trạng thái
    │   ├── active_case.json       # Trạng thái tổng quát của ca làm việc
    │   ├── interview_state.json   # Trạng thái phỏng vấn có cấu trúc (Sessions, Goals, Q&A, Decisions, Conflicts)
    │   ├── events.jsonl           # Nhật ký sự kiện append-only bất biến
    │   ├── learned_rules.json     # Bộ nhớ học từ sự cố
    │   ├── MEMORY.md              # Bảng chỉ mục tri thức bền vững
    │   └── cases/                 # Nhật ký phiên cô lập
    └── scripts/                   # Bộ công cụ thực thi xác định
        ├── health_check.ps1       # Kiểm tra sức khỏe môi trường (6/6 OK)
        ├── gate.ps1               # Quản trị máy trạng thái 6 cổng & tự động thu hồi
        ├── interview.ps1          # CLI quản lý trạng thái phỏng vấn & Exit Gate (v1.1)
        ├── test_interview.ps1     # Bộ kiểm định tự động 35 test cases cho interview system (v1.1)
        ├── context.ps1            # Phân bổ ngân sách & đóng gói ngữ cảnh L0-L5
        ├── verify_code.ps1        # Kiểm tra cú pháp & phân tầng rủi ro
        ├── rollback.ps1           # Hoàn tác an toàn ReparsePoint & xoay vòng 10 snapshots
        └── adr.ps1                # Quản lý ADR chuẩn MADR không phụ thuộc thư viện ngoài
```

---

## 4. Điểm Đột Phá Của Bản Nâng Cấp v1.1 (Adaptive Interview & Mobile Display)

### 4.1 Động Cơ Phỏng Vấn Thích Ứng Định Hướng Quyết Định (Decision-Driven Interview Engine)
- **Hợp đồng 12 bước**: Vận hành khép kín từ `Context Ingestion` ➔ `Goal Decomposition` ➔ `Question Selection` ➔ `Answer Interpretation` ➔ `State Update` ➔ `Sufficiency Evaluation`.
- **Triệt tiêu câu hỏi thừa**: Áp dụng 8 bộ lọc `Question Necessity Engine`. Tự đọc mã nguồn/manifest trước khi mở câu hỏi; chỉ hỏi những câu trực tiếp thay đổi kiến trúc.
- **Quản lý mâu thuẫn (Contradiction Resolution Protocol)**: Khi câu trả lời sau trái ngược câu trả lời trước, hệ thống tự động ghi nhận `record-conflict`, khóa cổng ở trạng thái `BLOCKED`, và đề xuất 3 phương án đánh đổi A/B/C kèm trade-offs rõ ràng.
- **Chống lặp câu hỏi (Repetition Prevention)**: Tự động cảnh báo nếu đặt lại câu hỏi đã có câu trả lời mà không có lý do nghiệp vụ chính đáng.
- **Bảo toàn khi đổi phạm vi (Scope Change Handling)**: Giữ nguyên 100% các quyết định không bị ảnh hưởng khi người dùng đổi ý giữa chừng.

### 4.2 Ma Trận Tương Thích Màn Hình Di Động (Mobile Display Compatibility Matrix)
Bắt buộc khóa trong bản đặc tả trước Cổng 03:
- **Dải tỷ lệ khung hình thực tế**: 16:9, 18:9, 19.5:9, 20:9, 21:9, màn hình gập (8:7.1) và máy tính bảng (16:10).
- **Phân biệt rõ ràng**: Physical Resolution (Pixels) vs Logical Viewport Dimensions (`dp`).
- **Cổng hiển thị tối thiểu (Minimum Viewport)**: 320 dp width × 568 dp height.
- **Quy chuẩn bố cục**: Bắt buộc container cuộn dọc (`verticalScroll`) chống tràn; đệm vùng an toàn Edge-to-Edge (`WindowInsetsCompat`); xử lý tai thỏ/cutout; bọc chữ và cắt chữ có kiểm soát (`maxLines` + `TextOverflow.Ellipsis`).

---

## 5. Bốn Phương Án Phát Triển Phần Mềm (4 Build Routes)

Tại Bước 06 & 07, người dùng quyết định 1 trong 4 phương án:
1. **Route 1 — Tiếp tục phát triển trên source hiện tại (Extend)**: Nâng cấp trực tiếp trên codebase gốc của ứng dụng.
2. **Route 2 — Tạo nhánh riêng để phát triển tính năng (Feature Branch)**: Thêm chức năng mới cô lập trên nhánh riêng.
3. **Route 3 — Xây dựng implementation tương thích mới (Compatible)**: Tái tạo bản mới tương thích (Android Native via `Android CLI` hoặc Web App Zero-Install).
4. **Route 4 — Viết lại hoàn toàn (Full Rewrite)**: Thiết kế lại toàn bộ từ đầu theo đặc tả đã chốt.

---

## 6. Bắt Đầu Nhanh Trong 3 Bước

1. Kéo thả file ứng dụng vào thư mục `01_THA_APP_VAO_DAY`.
2. Mở file [HUONG_DAN_SU_DUNG.md](HUONG_DAN_SU_DUNG.md) hoặc [prompts/01-TAB-DISCOVERY.md](prompts/01-TAB-DISCOVERY.md), copy câu lệnh mẫu và dán vào chat với AI.
3. Trả lời các câu hỏi làm rõ từ AI, kiểm tra app mới và nhận bàn giao hoàn tất tại `05_MA_NGUON_PHAT_TRIEN`.

---

## 7. Tải Về Bản Phát Hành (Download v1.1)

- **Trực tuyến (GitHub Release)**: [https://github.com/kimducanh27-cpu/REA-kit-agy/releases/tag/v1.1](https://github.com/kimducanh27-cpu/REA-kit-agy/releases/tag/v1.1)
- **Tải trực tiếp file zip**: [REA-kit-agy-v1.1.zip](https://github.com/kimducanh27-cpu/REA-kit-agy/releases/download/v1.1/REA-kit-agy-v1.1.zip)
