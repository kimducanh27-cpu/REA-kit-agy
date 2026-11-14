# REA-kit-agy

**Bộ kit giao diện thư mục trực quan dành cho người dùng non-tech: Kiểm tra ứng dụng, bóc tách cấu trúc, làm rõ yêu cầu và phát triển/viết lại app bằng AI (Google Antigravity & REA Engine) theo chuẩn 6 Phase · 14 Bước.**

---

## 1. Sơ đồ Luồng Vòng Đời 6 Phase · 14 Bước (Master Lifecycle)

```mermaid
flowchart TD
    subgraph P0["PHASE 00 · FOUNDATION"]
        S00["00. PROJECT BOOTSTRAP<br/>(Git, Workspace, Agent Config, Context Docs)"]
    end

    subgraph P1["PHASE 01 · DISCOVERY (Tab 01)"]
        S01["01. APP INTAKE / PREFLIGHT<br/>(Nhận app, kiểm tra file, sao lưu an toàn)"]
        S02["02. REFERENCE BASELINE<br/>(Chạy thử app gốc, chụp màn hình UI / Fallback tĩnh)"]
        G1{"CỔNG 01: Baseline Verified?"}
    end

    subgraph P2["PHASE 02 · REVERSE ENGINEERING (Tab 02)"]
        S03["03. REA SCAN<br/>(Bóc tách cấu trúc, che mờ [REDACTED], State Matrix)"]
        S04["04. REA INVESTIGATE<br/>(Truy vết hàm nghiệp vụ, API, Data Flow)"]
        S05["05. REA AUDIT<br/>(Kiểm toán bằng chứng, đo Coverage, Sổ Unknowns)"]
        G2{"CỔNG 02: Audit Passed?"}
    end

    subgraph P3["PHASE 03 · PRODUCT DEFINITION (Tab 03)"]
        S06["06. REA INTERVIEW<br/>(Phỏng vấn người dùng tiếng Việt: mục tiêu, cải tiến)"]
        S07["07. SPEC & DESIGN GATE<br/>(Đóng băng đặc tả, Design Tokens 3 tầng, 4 UI States)"]
        S08["08. IMPLEMENTATION PLAN<br/>(Chia task nguyên tử, thứ tự & phụ thuộc)"]
        G3{"CỔNG 03: Spec Frozen?"}
    end

    subgraph P4["PHASE 04 · IMPLEMENTATION (Tab 04)"]
        S09["09. REA BUILD<br/>(4 Routes: Extend / Feature Branch / Compatible / Rewrite)"]
        S10["10. BUILD QA / CODE REVIEW<br/>(Thẩm định độc lập Standards vs Spec, verify_code.ps1)"]
        G4{"CỔNG 04: Build QA Passed?"}
    end

    subgraph P5["PHASE 05 · VALIDATION (Tab 05)"]
        S11["11. RUN APP / SMOKE TEST<br/>(Khởi chạy app mới: Web Browser / Android AVD Device Hub)"]
        S12["12. HARD VERIFY<br/>(Đối chiếu 1-1 với app gốc: Khớp 100% / Khác biệt / Nâng cấp)"]
        G5{"CỔNG 05: Hard Verify Passed?"}
        S13["13. RELEASE & HANDOFF<br/>(Đóng gói, Explainer đời thường, HOAN_TAC.bat)"]
        G6{"CỔNG 06: Handoff Signed?"}
    end

    S00 --> S01 --> S02 --> G1
    G1 -- Đạt --> S03 --> S04 --> S05 --> G2
    G2 -- Đạt --> S06 --> S07 --> S08 --> G3
    G3 -- Duyệt --> S09 --> S10 --> G4
    G4 -- Đạt --> S11 --> S12 --> G5
    G5 -- Đạt --> S13 --> G6

    %% Reject / Retry Loops
    G3 -. Sửa Spec .->|Tạo v2| S06
    G4 -. Lỗi cú pháp / Vượt 2 vòng .->|Sửa code| S09
    G5 -. Chưa khớp app gốc .->|Bản vá bổ sung| S09
```

---

## 2. Bảng Ma Trận 6 Cổng Kiểm Soát Chất Lượng (Quality Gates)

| Cổng Kiểm Soát | Vị Trí Vòng Đời | Điều Kiện Vượt Qua (Passing Criteria) | Hành Động Khi Bị Từ Chối (Reject Loop) |
| :--- | :--- | :--- | :--- |
| **GATE 01** (`gate_01_baseline_verified`) | Sau Bước 02 | Có ảnh chụp baseline thực tế HOẶC đã bóc tách tài nguyên tĩnh dự phòng. | Bổ sung file vào `01_` hoặc chạy lại chế độ Static Fallback. |
| **GATE 02** (`gate_02_audit_passed`) | Sau Bước 05 | Hoàn thành kiểm tra tĩnh có giới hạn; không phát hiện rủi ro trong phạm vi quét; vùng chưa kiểm toán đưa vào Sổ Unknowns; che mờ API Keys `[REDACTED]`. | Điều tra bổ sung các file nghi vấn tại Bước 04. |
| **GATE 03** (`gate_03_spec_frozen`) | Sau Bước 08 | Người dùng duyệt `dac-ta-yeu-cau-da-chot.md` và `KE_HOACH_TRIEN_KHAI.md`. | Tạo bản `SPEC_v2.md`, lùi về Bước 06 để phỏng vấn lại. Không xóa bản cũ. |
| **GATE 04** (`gate_04_build_qa_passed`) | Sau Bước 10 | Syntax check 100% OK, không có HIGH RISK chưa duyệt, Independent Reviewer PASS. | Lùi về Bước 09 tối đa 2 lần. Nếu vẫn lỗi, dừng lại báo cáo người dùng. |
| **GATE 05** (`gate_05_hard_verify_passed`) | Sau Bước 12 | Người dùng xác nhận bảng đối chiếu Hard Verify đạt yêu cầu. | Tạo `FIX_PLAN_v2.md`, lùi về Bước 09 để sửa code cục bộ. |
| **GATE 06** (`gate_06_handoff_signed`) | Sau Bước 13 | Người dùng ký nhận bàn giao, đã kiểm tra `HOAN_TAC.bat` sẵn sàng. | Hoàn tất dự án, lưu trạng thái hoàn thành vào `active_case.json`. |

---

## 3. Cấu Trúc Thư Mục Chuẩn (Self-Explanatory Tree)

```text
REA-kit-agy/
├── 01_THA_APP_VAO_DAY/             # [Phase 01]: Nơi thả APK, ASAR, zip, web link & ảnh baseline
├── 02_YEU_CAU_CUA_TOI/            # [Phase 03]: ho-so-va-muc-tieu.md, design.md (Tokens 3 tầng)
├── 03_KET_QUA_KIEM_TRA/           # [Phase 02-05]: Báo cáo, Unknowns, Spec chốt, Kế hoạch & Nghiệm thu
├── 04_SAO_LUU_AN_TOAN/            # [Bảo vệ]: Bản sao lưu gốc bất khả xâm phạm (Chỉ đọc)
├── 05_MA_NGUON_PHAT_TRIEN/        # [Phase 04-05]: Web App mới, preview.html, bàn giao & .backup/
├── AGENTS.md                      # Não bộ & luật vận hành 6 Phase 14 Bước
├── CLAUDE.md                      # Tương thích Claude Code (@AGENTS.md)
├── REVIEW.md                      # Hợp đồng thẩm định độc lập & bộ lọc dẹp nhiễu
├── UPSTREAMS.md                   # Đăng ký chuẩn nguồn gốc morluto/rea
├── HUONG_DAN_SU_DUNG.md           # Hướng dẫn sử dụng 1 trang kèm câu lệnh copy-paste
├── KIEM_TRA.bat                   # 1-click kiểm tra sức khỏe workspace & runtime (6/6)
├── HOAN_TAC.bat                   # 1-click hoàn tác về bản chạy tốt gần nhất (Rollback)
├── .gitignore                     # Bảo vệ bản quyền và chống rò rỉ dữ liệu cá nhân
├── prompts/                       # Bộ câu lệnh dán theo từng Phase (00 đến 05)
│   ├── 00-SESSION-CONTINUITY.md   # Phục hồi phiên & Auto-Resume
│   ├── 01-TAB-DISCOVERY.md        # Phase 01: Intake & Baseline
│   ├── 02-TAB-REVERSE-ENGINEERING.md # Phase 02: Scan, Investigate & Audit
│   ├── 03-TAB-PRODUCT-DEFINITION.md  # Phase 03: Interview, Spec & Plan
│   ├── 04-TAB-IMPLEMENTATION.md   # Phase 04: Build & Build QA / Review
│   ├── 05-TAB-VALIDATION.md       # Phase 05: Smoke Test, Hard Verify & Handoff
│   └── BOOTSTRAP_KIT.md           # Siêu lệnh nhân bản bộ kit
├── templates/                     # Khung mẫu tài liệu hợp đồng chuẩn (01 đến 09)
│   ├── 01-REPORT-TEMPLATE.md      # Báo cáo hiện trạng
│   ├── 02-SPEC-TEMPLATE.md        # Đặc tả yêu cầu đóng băng
│   ├── 03-RUN-GUIDE-TEMPLATE.md   # Hướng dẫn chạy 1 trang
│   ├── 04-TEST-RESULT-TEMPLATE.md # Chứng chỉ kiểm thử & QA
│   ├── 05-DESIGN-TOKEN-TEMPLATE.md# Hợp đồng Design Tokens 3 tầng
│   ├── 06-UNKNOWNS-AND-COVERAGE-TEMPLATE.md # Sổ theo dõi điểm mù & độ phủ
│   ├── 07-IMPLEMENTATION-PLAN-TEMPLATE.md   # Kế hoạch chia task nguyên tử
│   ├── 08-HARD-VERIFY-TEMPLATE.md # Bảng đối chiếu 1-1 với app gốc
│   └── 09-HANDOFF-BUNDLE-TEMPLATE.md # Biên bản bàn giao sản phẩm
├── docs/                          # Hệ thống quản lý ngữ cảnh đa phiên (Context Docs)
│   ├── WORKFLOW_LIFECYCLE.md      # Đặc tả chuẩn hóa 6 Phase · 14 Bước
│   ├── PROGRESS.md                # Bảng tiến độ 14 bước tự động đồng bộ
│   └── HANDOFF.md                 # Hồ sơ bàn giao dự án
└── .agents/                       # Khu vực kỹ thuật (ẩn trên Windows)
    ├── rules/rea-workflow.md      # Luật an toàn REA
    ├── skills/                    # Kỹ năng lõi REA gốc + Bộ 3 skills điều phối tiếng Việt
    ├── state/active_case.json     # Bộ nhớ máy trạng thái 6 Gates & 14 Steps
    ├── state/learned_rules.json   # Bộ nhớ học từ sự cố (Incidents to Evals)
    └── scripts/health_check.ps1   # Script kiểm tra môi trường và Auto-Resume (6/6)
```

---

## 4. Bốn Hệ Thống Phối Hợp & Kiến Trúc Bộ Nhớ 4 Lớp (Anthropic Research)

REA-kit-agy được tổ chức thành 4 hệ thống nội bộ chặt chẽ nhưng giữ nguyên giao diện 5 thư mục đơn giản cho người dùng non-tech:

1. **01 — PROCESS ORCHESTRATOR**:
   - Single Authoritative Coordinator điều phối ca làm việc qua `active_case.json` (máy trạng thái 6 Gates & 14 Steps).
   - Bộ 3 Kỹ năng điều phối tiếng Việt (`rea-scan`, `rea-interview`, `rea-build`).
2. **02 — AGENT & SKILL SYSTEM**:
   - Tầng 1: Kỹ năng lõi Upstream `reverse-engineer-anything` (morluto/rea, 229 MCP tools, định tuyến APK / Electron / Binary).
   - Tầng 2: Host Plugin Skills từ Antigravity (`android-cli`, `android-device-hub`, `ui-styling`, `surgical-patch`, `code-review`).
   - Hỗ trợ Subagents phân tích độc lập; Swarm chỉ kích hoạt khi Build chia module độc lập; không bắt buộc phụ thuộc Swarm/Teamwork.
3. **03 — MEMORY & KNOWLEDGE SYSTEM (Chuẩn 4 Lớp Anthropic)**:
   - **Layer 1 (Transcripts / Event Logs)**: Nhật ký gốc từng phiên lưu tại `.agents/state/cases/`.
   - **Layer 2 (Memory Notes)**: Ghi chú bền vững, bài học kiểm chứng tại `.agents/state/learned_rules.json` và `.agents/state/MEMORY.md`.
   - **Layer 3 (Memory Representations)**: Bản đồ tri thức, wiki liên kết tại `docs/` (`ARCHITECTURE.md`, `RULES.md`, `WORKFLOW_LIFECYCLE.md`).
   - **Layer 4 (Injected Context)**: Ngữ cảnh nạp đầu phiên gồm `active_case.json`, `AGENTS.md` và `docs/HANDOFF.md`.
   - *Cơ chế Consolidation*: Chạy cuối milestone để đối chiếu nguồn gốc, dọn ghi chú trùng lặp, chống nhiều agent ghi đè tri thức.
4. **04 — VERIFICATION & REVIEW ENGINE**:
   - Kiểm tra 2 trục độc lập Standards vs Spec theo `REVIEW.md`.
   - Hệ thống script kiểm định (`health_check.ps1`, `verify_code.ps1`, `rollback.ps1` hỗ trợ đệ quy thư mục lồng).
   - Truy vết 1-1 (Traceability 100%): `App Gốc` ➔ `REA Evidence` ➔ `Feature` ➔ `Quyết Định` ➔ `Spec Chốt` ➔ `Task` ➔ `Mã Nguồn` ➔ `Test Case` ➔ `Nghiệm Thu`.

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

## 7. Khởi Tạo Bộ Kit Vào Thư Mục Mới (Meta-Bootstrap)

Muốn nhân bản toàn bộ bộ kit này sang một thư mục rỗng bất kỳ chỉ bằng 1 câu lệnh cho AI:
👉 Mở file **[prompts/BOOTSTRAP_KIT.md](prompts/BOOTSTRAP_KIT.md)**, copy khối siêu lệnh và dán vào Agent trong thư mục mới. Agent sẽ tự động tạo đủ cấu trúc, kiểm tra sức khỏe và báo kết quả `6/6 PASSED`.
