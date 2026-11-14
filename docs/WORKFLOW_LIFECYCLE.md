# QUY TRÌNH VÒNG ĐỜI DỰ ÁN (WORKFLOW LIFECYCLE) — REA-KIT-AGY
## Khung Chuẩn 6 Stage · 14 Bước & 6 Cổng Kiểm Soát Chất Lượng (Quality Gates)

> [!IMPORTANT]
> **Tách Bạch Hệ Thống Phân Loại (Taxonomy Decoupling)**:
> - **Lộ trình Phát triển Kho (Repo Development Roadmap — P00 đến P05)**: Theo dõi tiến độ xây dựng công cụ, kiến trúc và kỹ năng của bản thân kho REA-kit-agy (P00 đã hoàn tất, P01 đang thực hiện).
> - **Quy trình Điều phối Ca Phân tích (End-User Case Workflow — STAGE_00 đến STAGE_05)**: 6 giai đoạn chuẩn hóa (`STAGE_00_BOOTSTRAP` đến `STAGE_05_VALIDATION`), 14 bước nguyên tử và 6 cổng kiểm soát chất lượng dưới đây, do AI Agent thực hiện trên từng ứng dụng mục tiêu (`active_case.json`).

Tài liệu này là đặc tả chuẩn hóa kiến trúc điều phối ca phân tích của **REA-kit-agy**. Mọi AI Agent (Antigravity, Claude Code, Cursor) và con người tham gia dự án đều phải tuân thủ nghiêm ngặt từng bước và các cổng kiểm soát (Gates) dưới đây.

---

## 1. Sơ đồ Luồng Tổng Thể (Master Lifecycle Flow)

```mermaid
flowchart TD
    subgraph S0["STAGE 00 · FOUNDATION / BOOTSTRAP"]
        S00["00. PROJECT BOOTSTRAP<br/>(Khởi tạo Git, Workspace, Cấu hình Agent, Context Docs)"]
    end

    subgraph S1["STAGE 01 · DISCOVERY (Tab 01)"]
        S01["01. APP INTAKE / PREFLIGHT<br/>(Nhận app, kiểm tra file, phân loại định dạng)"]
        S02["02. REFERENCE BASELINE<br/>(Android CLI / AVD / Device Hub / REA ADB hoặc Fallback tĩnh)"]
        G1{"CỔNG 01: Baseline Verified?<br/>(Có ảnh giao diện hoặc Fallback tĩnh)"}
    end

    subgraph S2["STAGE 02 · REVERSE ENGINEERING (Tab 02)"]
        S03["03. REA SCAN<br/>(Phân tích cấu trúc, mã nguồn, tài nguyên, Evidence)"]
        S04["04. REA INVESTIGATE<br/>(Truy vết hàm, khảo sát runtime & hành vi)"]
        S05["05. REA AUDIT<br/>(Kiểm toán Scoped Static Audit, Coverage, Sổ Unknowns)"]
        G2{"CỔNG 02: Scoped Audit Passed?<br/>(Scoped Static Audit đạt, che mờ secrets, Unknowns rõ ràng)"}
    end

    subgraph S3["STAGE 03 · PRODUCT DEFINITION (Tab 03)"]
        S06["06. REA INTERVIEW<br/>(Phỏng vấn người dùng: mục tiêu, tính năng, cải tiến)"]
        S07["07. SPEC & DESIGN GATE<br/>(Đặc tả sản phẩm, Design Tokens 3 tầng, 4 UI States)"]
        S08["08. IMPLEMENTATION PLAN<br/>(Chia task nguyên tử, xác định phụ thuộc & thứ tự)"]
        G3{"CỔNG 03: Spec Frozen?<br/>(Người dùng duyệt đặc tả & kế hoạch chia task)"}
    end

    subgraph S4["STAGE 04 · IMPLEMENTATION (Tab 04)"]
        S09["09. REA BUILD<br/>(Build Routes: Web Zero-Install / Android Native `android create` / Patch APK)"]
        S10["10. BUILD QA / CODE REVIEW<br/>(Independent Reviewer: Standards vs Spec, Syntax, Risk Classifier)"]
        G4{"CỔNG 04: Build QA Passed?<br/>(Syntax 100% OK, không lỗi, Risk được kiểm soát)"}
    end

    subgraph S5["STAGE 05 · VALIDATION (Tab 05)"]
        S11["11. RUN APP / SMOKE TEST<br/>(Khởi chạy Web hoặc AVD/Device Hub qua Android CLI / start_adb_app)"]
        S12["12. HARD VERIFY<br/>(Đối chiếu 1-1: android layout, android screen capture, Khớp 100% / Khác biệt / Nâng cấp)"]
        G5{"CỔNG 05: Hard Verify Passed?<br/>(Người dùng xác nhận app mới đạt yêu cầu)"}
        S13["13. RELEASE & HANDOFF<br/>(Đóng gói, Explainer đời thường, Hướng dẫn HOAN_TAC.bat)"]
        G6{"CỔNG 06: Handoff Signed?<br/>(Ký nhận trách nhiệm, bàn giao mã nguồn hoàn tất)"}
    end

    S00 --> S01 --> S02 --> G1
    G1 -- Hợp lệ --> S03 --> S04 --> S05 --> G2
    G2 -- Đạt chuẩn --> S06 --> S07 --> S08 --> G3
    G3 -- Đã duyệt --> S09 --> S10 --> G4
    G4 -- Vượt qua --> S11 --> S12 --> G5
    G5 -- Đạt chuẩn --> S13 --> G6

    %% Retry / Reject Loops
    G3 -. Từ chối / Sửa spec .->|Tạo v2| S06
    G4 -. Lỗi cú pháp / Vượt 2 vòng .->|Sửa code| S09
    G5 -. Chưa khớp app gốc .->|Bản vá bổ sung| S09
```

---

## 2. Chi Tiết Từng Stage & 14 Bước Thực Hiện

### STAGE 00 · FOUNDATION / BOOTSTRAP — Khởi Tạo Nền Móng
- **Thời điểm thực hiện**: Duy nhất một lần khi bắt đầu dự án.
- **Nhiệm vụ**: Khởi tạo cấu trúc thư mục chuẩn, Git, cấu hình Agent (`AGENTS.md`, `REVIEW.md`), bộ nhớ trạng thái (`active_case.json`), bộ nhớ học sự cố (`learned_rules.json`) và tài liệu ngữ cảnh (`docs/`).
- **Lệnh thực hiện**: Chạy siêu lệnh tại `prompts/BOOTSTRAP_KIT.md` hoặc kiểm tra bằng `KIEM_TRA.bat`.

---

### STAGE 01 · DISCOVERY — Khám Phá & Thiết Lập Chuẩn Đối Chiếu
*Tương ứng Tab Prompt: `prompts/01-TAB-DISCOVERY.md`*

#### Bước 01: App Intake / Preflight (Tiếp nhận & Kiểm tra)
- **Đầu vào**: Tệp người dùng thả vào `01_THA_APP_VAO_DAY/` (APK, ASAR, ZIP, URL web).
- **Hành động Agent**:
  1. Tự động sao lưu nguyên vẹn tệp gốc vào `04_SAO_LUU_AN_TOAN/` (Bất khả xâm phạm).
  2. Xác định định dạng tệp, cấu trúc bao gói, tính toàn vẹn (checksum).
  3. Kiểm tra quyền truy cập, các biến môi trường và công cụ dịch ngược sẵn có trên máy (Android CLI, REA MCP, ADB, JADX).
- **Đầu ra**: Ghi nhận thông tin tệp vào `.agents/state/active_case.json`.

#### Bước 02: Reference Baseline (Đo kiểm Ứng dụng Gốc)
- **Hành động Agent**:
  1. **Quy trình với Android APK (Mục tiêu cốt lõi V1)**:
     - Tận dụng plugin **Android CLI** của Antigravity kết hợp cùng công cụ **REA ADB** và phân tích tĩnh JADX:
       * Khởi chạy ứng dụng trên máy ảo AVD hoặc thiết bị thật qua Antigravity Device Hub bằng lệnh `start_adb_app` (tham số bắt buộc: `serial`, `package`) hoặc lệnh `android`.
       * Chụp ảnh màn hình giao diện thực tế bằng `android screen capture -o <file_path>` hoặc lệnh REA ADB `capture_adb_screen` (tham số bắt buộc: `serial`, `output-directory`) và lưu vào `01_THA_APP_VAO_DAY/baseline/`.
       * Trích xuất phân cấp giao diện (UI Hierarchy) trực tiếp bằng `android layout` để lập danh mục màn hình sống (Live Screen Inventory).
  2. **Quy trình với ứng dụng khác (Web, Electron ASAR, Desktop)**:
     - Chạy thử app gốc trên trình duyệt hoặc runtime cục bộ, chụp ảnh giao diện và ghi nhận luồng thao tác mẫu.
  3. **Cơ chế Fallback (Nếu không có máy ảo/thiết bị thật/không chạy được runtime)**:
     - Tự động chuyển sang bóc tách tài nguyên tĩnh với REA MCP `inspect_android_package` (lưu ý: `inspect_android_package` là công cụ phân tích tĩnh cục bộ dựa trên JADX decompiler, KHÔNG PHẢI lệnh ADB) để trích xuất layout XML, drawables, strings, AndroidManifest.xml đối với APK hoặc bóc tách assets/HTML tĩnh.
     - Đánh dấu runtime là `SKIPPED (Tĩnh)`. Tuyệt đối không dừng lại hay báo lỗi crash terminal.
- **CỔNG 01 (`gate_01_baseline_verified`)**: Đã có đủ ảnh giao diện hoặc đã trích xuất toàn bộ tài nguyên tĩnh dự phòng.

---

### STAGE 02 · REVERSE ENGINEERING — Bóc Tách & Dịch Ngược Chuyên Sâu
*Tương ứng Tab Prompt: `prompts/02-TAB-REVERSE-ENGINEERING.md`*

#### Bước 03: REA Scan (Quét Cấu Trúc & Tài Nguyên)
- **Hành động Agent**:
  1. Sử dụng công cụ MCP từ `reverse-engineer-anything` để giải mã cấu trúc gói (đối với APK: `inspect_android_package` — công cụ phân tích tĩnh cục bộ bằng JADX decompiler, không phải lệnh ADB; giải mã AndroidManifest.xml, permissions, activities, services; đối với ASAR: `analyze_javascript_application`).
  2. Tự động che mờ toàn bộ API Keys, Secret Tokens thành `[REDACTED]` để chống rò rỉ dữ liệu.
  3. Lập danh mục màn hình và bảng trạng thái giao diện (Screen Inventory & State Matrix).

#### Bước 04: REA Investigate (Điều Tra Hành Vi & Logic Nghiệp Vụ)
- **Hành động Agent**:
  1. Phân tích luồng dữ liệu (Data flow), các API endpoint, cách lưu trữ dữ liệu (SQLite, SharedPreferences, LocalStorage).
  2. Truy vết các hàm nghiệp vụ trọng yếu (Xác thực, tính toán, giỏ hàng, mã hóa).
  3. Đánh dấu các khối code obfuscated hoặc native libraries chưa rõ bản chất.

#### Bước 05: REA Audit (Kiểm Toán Bằng Chứng & Độ Phủ)
- **Hành động Agent**:
  1. Đối chiếu bằng chứng tĩnh với bằng chứng động (Static vs Dynamic Evidence).
  2. Đo lường tỷ lệ bao phủ bằng chứng (Coverage Score: ví dụ 85% chức năng đã được giải mã rõ ràng).
  3. **Kiểm toán tĩnh có giới hạn phạm vi (Scoped Static Audit)**:
     - Nhận diện các pattern bất thường, quyền hạn nhạy cảm, network endpoints gọi ra ngoài, không đưa ra tuyên bố tuyệt đối về "quét sạch 100% mã độc" (tránh ngộ nhận an ninh).
  4. **Xuất Sổ Theo Dõi Unknowns**: Ghi toàn bộ các điểm chưa giải mã được, các vùng code chưa xác thực vào file:
     `03_KET_QUA_KIEM_TRA/UNKNOWNS_AND_COVERAGE.md`.
- **CỔNG 02 (`gate_02_audit_passed`)**: Đạt kiểm toán tĩnh Scoped Static Audit, che mờ 100% secrets `[REDACTED]`, và mọi điểm mù đều được đưa vào sổ Unknowns.

---

### STAGE 03 · PRODUCT DEFINITION — Định Hình Sản Phẩm & Kế Hoạch
*Tương ứng Tab Prompt: `prompts/03-TAB-PRODUCT-DEFINITION.md`*

#### Bước 06: REA Interview (Phỏng Vấn Người Dùng Thân Thiện)
- **Hành động Agent**:
  1. Đọc `02_YEU_CAU_CUA_TOI/ho-so-va-muc-tieu.md` và `UNKNOWNS_AND_COVERAGE.md`.
  2. Đặt từ 3 đến 5 câu hỏi tiếng Việt đời thường, tập trung vào:
     - Giữ lại chức năng nào của app gốc?
     - Bỏ qua hoặc sửa đổi chức năng nào?
     - Cần bổ sung tính năng mới hoặc đổi giao diện ra sao?
     - Chọn 1 trong 4 hướng phát triển: (1) Tiếp tục phát triển trên source hiện tại, (2) Tạo nhánh riêng cô lập tính năng, (3) Xây dựng bản tương thích mới (Android Native via Android CLI hoặc Web App Zero-Install), (4) Viết lại hoàn toàn.
     - Xử lý các điểm mù (Unknowns) bằng phương án nào?

#### Bước 07: Spec & Design Gate (Đóng Băng Đặc Tả & Thiết Kế)
- **Hành động Agent**:
  1. Chốt hợp đồng thiết kế **Design System 3 tầng** trong `02_YEU_CAU_CUA_TOI/design.md` (Tokens ➔ Components ➔ 4 Trạng thái: Loading, Empty, Success, Error).
  2. Xuất bản tài liệu đặc tả sản phẩm chính thức vào `03_KET_QUA_KIEM_TRA/dac-ta-yeu-cau-da-chot.md`.
  3. Xác định rõ Tiêu chí Hoàn thành (Acceptance Criteria) cho từng màn hình.

#### Bước 08: Implementation Plan (Kế Hoạch Triển Khai Nguyên Tử)
- **Hành động Agent**:
  1. Chia nhỏ toàn bộ dự án thành các nhiệm vụ nguyên tử (Atomic Tasks, mỗi task làm 1 việc cụ thể).
  2. Xác định thứ tự thực hiện, phụ thuộc giữa các task (Dependencies).
  3. Xuất file kế hoạch vào:
     `03_KET_QUA_KIEM_TRA/KE_HOACH_TRIEN_KHAI.md`.
- **CỔNG 03 (`gate_03_spec_frozen`)**: Người dùng xác nhận "Đồng ý" với Đặc tả sản phẩm, Design System và Kế hoạch chia task.

---

### STAGE 04 · IMPLEMENTATION — Triển Khai & Kiểm Toán Mã Nguồn
*Tương ứng Tab Prompt: `prompts/04-TAB-IMPLEMENTATION.md`*

#### Bước 09: REA Build (Viết Mã Nguồn Theo Các Build Routes Linh Hoạt)
- **Hành động Agent**:
  1. Tự động lưu snapshot vào `05_MA_NGUON_PHAT_TRIEN/.backup/` trước khi viết code.
  2. **Lựa chọn Build Route theo đặc tả đã chốt**:
     - **Route A (Mặc định — Zero-Install Web App)**: Triển khai Web App độc lập (`index.html`, `styles.css`, `app.js`) chạy trực tiếp trên trình duyệt, không bắt người dùng cài môi trường.
     - **Route B (Android Native Project)**: Sử dụng plugin **Android CLI** của Antigravity (`android create` hoặc template Android Gradle với Kotlin/Java) để tạo project Android chuẩn, tái tạo UI bằng Jetpack Compose / XML Layouts và logic nghiệp vụ. Hỗ trợ biên dịch và chạy trực tiếp trên AVD/thiết bị qua Android SDK.
     - **Route C (Patch APK / Resources hoặc Web/Hybrid)**: Thực hiện vá tài nguyên/smali trực tiếp trên gói APK gốc, hoặc đóng gói ứng dụng Hybrid (Capacitor/PWA) nếu người dùng yêu cầu môi trường lai.
  3. Tuân thủ 100% token màu sắc, typography và 4 trạng thái UI từ `design.md`.
  4. Nếu là bản sửa đổi/nâng cấp: Xuất file xem trước (`preview.html` hoặc build preview APK) trước khi hoàn thiện bản chính thức.

#### Bước 10: Build QA / Code Review (Thẩm Định Độc Lập & Phân Tầng Rủi Ro)
- **Hành động Agent**:
  1. **Thẩm định 2 trục độc lập** theo `REVIEW.md`:
     - Trục Tiêu chuẩn (Standards): Đối chiếu Design Tokens và 4 trạng thái UI.
     - Trục Đặc tả (Spec): Đối chiếu từng tiêu chí hoàn thành trong `dac-ta-yeu-cau-da-chot.md`.
  2. **Bộ lọc dẹp nhiễu (High-Signal Filter)**: Không bắt bẻ phong cách viết mã râu ria, chỉ tập trung vào lỗi thật.
  3. **Khống chế vòng lặp tự sửa (Review Convergence Cap)**: Tự động chạy `verify_code.ps1` tối đa 2 vòng.
  4. **Chốt chặn phân tầng rủi ro**:
     - `LOW RISK`: UI/Text tĩnh ➔ Tự động thông qua sau kiểm tra cú pháp.
     - `MEDIUM RISK`: Logic form, dữ liệu local ➔ Kiểm tra theo checklist.
     - `HIGH RISK` / `SYNTAX ERROR`: Lỗi cú pháp hoặc gọi mạng ngoài không báo trước ➔ **CHẶN ĐỨNG**. Không cho phép chuyển sang Stage 05.
  5. Xuất báo cáo kiểm thử vào `03_KET_QUA_KIEM_TRA/KET_QUA_KIEM_THU.md`.
- **CỔNG 04 (`gate_04_build_qa_passed`)**: Mã nguồn vượt qua kiểm tra cú pháp, không có cờ HIGH RISK chưa giải trình.

---

### STAGE 05 · VALIDATION — Nghiệm Thu Đối Chiếu & Bàn Giao
*Tương ứng Tab Prompt: `prompts/05-TAB-VALIDATION.md`*

#### Bước 11: Run App / Smoke Test (Khởi Chạy & Kiểm Tra Nhanh)
- **Hành động Agent**:
  1. **Với Web App**: Hướng dẫn người dùng nhấp đúp mở `05_MA_NGUON_PHAT_TRIEN/index.html` trên trình duyệt.
  2. **Với Android Native / APK**: Cài đặt và khởi chạy app mới trên máy ảo AVD hoặc thiết bị thật kết nối qua Device Hub bằng lệnh REA ADB `start_adb_app` (tham số bắt buộc: `serial`, `package`) hoặc Android CLI.
  3. Kiểm tra các luồng đi cơ bản (Happy path): tải trang/màn hình chính, hiển thị dữ liệu mẫu, điều hướng các màn hình.

#### Bước 12: Hard Verify (Đối Chiếu 1-1 Với App Gốc)
- **Hành động Agent**:
  1. Đặt app mới cạnh app gốc để đối chiếu từng tính năng và giao diện:
     - **Với Android**: Sử dụng `android screen capture -o <file_path>` hoặc REA ADB `capture_adb_screen` (tham số bắt buộc: `serial`, `output-directory`) để ghi lại hình ảnh app mới; chạy `android layout` để trích xuất cây cấu trúc component và so sánh 1-1 với layout baseline thu được tại Bước 02.
     - **Với Web**: So sánh trực tiếp trên trình duyệt hoặc đối chiếu với ảnh chụp màn hình trong `01_THA_APP_VAO_DAY/baseline/`.
  2. Lập bảng đối chiếu trực quan 3 cột:
     - **Cột 1: Khớp 100%**: Các chức năng và UI chuẩn xác như bản gốc.
     - **Cột 2: Khác biệt có chủ đích**: Các điểm thay đổi đã được thống nhất tại Bước 06.
     - **Cột 3: Nâng cấp mới**: Các tính năng cải tiến hoặc giao diện hiện đại hơn.
  3. Xuất file nghiệm thu vào:
     `03_KET_QUA_KIEM_TRA/BAO_CAO_NGHIEM_THU_HARD_VERIFY.md`.
- **CỔNG 05 (`gate_05_hard_verify_passed`)**: Người dùng xác nhận ứng dụng mới đạt toàn bộ tiêu chí so sánh.

#### Bước 13: Release & Handoff (Đóng Gói & Bàn Giao Trọn Gói)
- **Hành động Agent**:
  1. Đóng gói mã nguồn sạch sẽ, loại bỏ tệp rác.
  2. Viết bản giải thích đời thường (Plain-Language Explainer): trả lời rõ 3 câu hỏi (Làm gì, Tại sao, Cách dùng).
  3. Hướng dẫn sử dụng nút `HOAN_TAC.bat` nếu phát sinh sự cố sau bàn giao.
  4. Xuất gói bàn giao chính thức vào:
     `05_MA_NGUON_PHAT_TRIEN/BAN_GIAO_SAN_PHAM.md`.
- **CỔNG 06 (`gate_06_handoff_signed`)**: Người dùng xác nhận bàn giao hoàn tất ("You Land It, You Own It").

---

## 3. Bảng Ma Trận 6 Cổng Kiểm Soát (Quality Gates Matrix)

| Cổng Kiểm Soát | Vị Trí Vòng Đời | Điều Kiện Vượt Qua (Passing Criteria) | Hành Động Khi Bị Từ Chối (Reject Loop) |
| :--- | :--- | :--- | :--- |
| **GATE 01** (`gate_01_baseline_verified`) | Sau Bước 02 | Có ảnh chụp app gốc (từ AVD/Device Hub qua `android screen capture -o <file_path>`/`capture_adb_screen` [yêu cầu `serial`, `output-directory`] hoặc browser) hoặc đã bóc tách tài nguyên tĩnh dự phòng (`inspect_android_package` qua JADX tĩnh). | Bổ sung file vào `01_` hoặc chạy lại chế độ Static Fallback. |
| **GATE 02** (`gate_02_audit_passed`) | Sau Bước 05 | Đạt Scoped Static Audit (kiểm toán tĩnh có giới hạn phạm vi, phát hiện patterns nghi vấn, che mờ API Keys `[REDACTED]`, không over-claim quét sạch mã độc, xuất đủ `UNKNOWNS_AND_COVERAGE.md`). | Điều tra bổ sung các file nghi vấn tại Bước 04. |
| **GATE 03** (`gate_03_spec_frozen`) | Sau Bước 08 | Người dùng duyệt `dac-ta-yeu-cau-da-chot.md` (bao gồm lựa chọn Build Route) và `KE_HOACH_TRIEN_KHAI.md`. | Tạo bản `SPEC_v2.md`, lùi về Bước 06 để phỏng vấn lại. Không xóa bản cũ. |
| **GATE 04** (`gate_04_build_qa_passed`) | Sau Bước 10 | Syntax check 100% OK, không có HIGH RISK chưa duyệt, Independent Reviewer PASS. | Lùi về Bước 09 tối đa 2 lần. Nếu vẫn lỗi, dừng lại báo cáo người dùng. |
| **GATE 05** (`gate_05_hard_verify_passed`) | Sau Bước 12 | Người dùng xác nhận bảng đối chiếu Hard Verify đạt yêu cầu (so sánh UI/layout qua `android layout` hoặc đối chiếu visual). | Tạo `FIX_PLAN_v2.md`, lùi về Bước 09 để sửa code cục bộ. |
| **GATE 06** (`gate_06_handoff_signed`) | Sau Bước 13 | Người dùng ký nhận bàn giao, đã kiểm tra `HOAN_TAC.bat` sẵn sàng. | Hoàn tất dự án, lưu trạng thái hoàn thành vào `active_case.json`. |

---

## 4. Quy Chuẩn Ánh Xạ Thư Mục Lưu Trữ (Artifact Mapping)

Để đảm bảo người non-tech luôn tìm thấy file dễ dàng, toàn bộ sản phẩm của 14 bước được phân định cứng cáp:

```text
REA-kit-agy/
├── 01_THA_APP_VAO_DAY/             # [Stage 01]: File ứng dụng gốc cần phân tích & baseline/ (ảnh màn hình, layout dump)
├── 02_YEU_CAU_CUA_TOI/            # [Stage 03]: ho-so-va-muc-tieu.md, design.md (Tokens 3 tầng)
├── 03_KET_QUA_KIEM_TRA/           # [Stage 02, 03, 04, 05]:
│   ├── UNKNOWNS_AND_COVERAGE.md   # Sản phẩm Bước 05 (Sổ theo dõi điểm mù & độ phủ Scoped Audit)
│   ├── dac-ta-yeu-cau-da-chot.md   # Sản phẩm Bước 07 (Đặc tả đóng băng & Build Route)
│   ├── KE_HOACH_TRIEN_KHAI.md     # Sản phẩm Bước 08 (Kế hoạch chia task nguyên tử)
│   ├── KET_QUA_KIEM_THU.md        # Sản phẩm Bước 10 (Chứng chỉ QA & Review độc lập)
│   └── BAO_CAO_NGHIEM_THU_HARD_VERIFY.md # Sản phẩm Bước 12 (Bảng đối chiếu 1-1 qua android layout / visual)
├── 04_SAO_LUU_AN_TOAN/            # [Bảo vệ]: Bản sao lưu nguyên vẹn gốc (Chỉ đọc, bất khả xâm phạm)
└── 05_MA_NGUON_PHAT_TRIEN/        # [Stage 04 & 05]:
    ├── index.html, styles.css, app.js # Mã nguồn Route A (Zero-Install Web App)
    ├── android/                       # Mã nguồn Route B (Android Native Project tạo qua `android create`)
    ├── preview.html                   # Bản xem trước theo giai đoạn trước khi ghi đè
    ├── BAN_GIAO_SAN_PHAM.md           # Sản phẩm Bước 13 (Gói bàn giao & Explainer đời thường)
    └── .backup/                       # Snapshot tự động phục vụ HOAN_TAC.bat
```

---

## 5. Quy Tắc Đồng Bộ Tài Liệu Sống (Living Docs Sync)

1. **Sau mỗi cổng Gate thành công**:
   - Agent bắt buộc cập nhật bảng checklist trong `docs/PROGRESS.md`.
   - Cập nhật trường `current_phase` (theo Stage taxonomy: `STAGE_00_BOOTSTRAP` .. `STAGE_05_VALIDATION`), `current_step`, `current_gate_status` trong `.agents/state/active_case.json`.
2. **Khi phát sinh sự cố hoặc hoàn tác**:
   - Agent tự động nạp nguyên nhân vào `.agents/state/learned_rules.json` để không lặp lại sai lầm trong các lượt build tiếp theo.
3. **Khi kết thúc dự án (Gate 06)**:
   - Toàn bộ thông tin phiên bản, known issues và hướng dẫn chạy được đồng bộ trọn vẹn vào `docs/HANDOFF.md`.


