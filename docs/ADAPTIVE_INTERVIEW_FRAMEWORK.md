# KHUNG PHỎNG VẤN THÍCH ỨNG & ĐẶC TẢ SẢN PHẨM KHÔNG KHUÔN SÁO
# (ADAPTIVE INTERVIEW & SPECIFICATION FRAMEWORK)

> **Mã quy chuẩn**: `REA-FRAMEWORK-INT-001`  
> **Phiên bản**: v1.1 (Thích ứng đa miền · Loại bỏ câu hỏi thừa · Chống UI Slop)  
> **Áp dụng cho**: STAGE_03 · PRODUCT DEFINITION (Bước 06 `06_REA_INTERVIEW` & Bước 07 `07_SPEC_AND_DESIGN`)  
> **Tài liệu liên quan**: `docs/WORKFLOW_LIFECYCLE.md`, `docs/INTAKE_QUESTION_LOGIC.md`, `.agents/skills/rea-interview/SKILL.md`  

---

## 1. TỔNG QUAN & TRIẾT LÝ THIẾT KẾ (PHILOSOPHY & OBJECTIVES)

### 1.1 Khủng Hoảng Của Các Bảng Khảo Sát AI Truyền Thống
Trong phần lớn các hệ thống AI coding agent thông thường, quá trình lấy yêu cầu (requirements intake) thường mắc phải 4 căn bệnh trầm kha:
1. **Khảo sát dàn hàng ngang (Questionnaire Dump)**: Đưa ra danh sách 20-30 câu hỏi máy móc bắt người dùng trả lời, trong đó phần lớn là những điều người dùng đã nói hoặc có sẵn trong mã nguồn.
2. **Hỏi những điều hiển nhiên (Inspectable Trivia)**: Hỏi người dùng về phiên bản Android SDK, tên database, cấu trúc bảng, hoặc tên thư viện — những thứ Agent hoàn toàn tự đọc được từ mã nguồn hoặc file cấu hình.
3. **Rập khuôn giao diện sáo mòn (AI UI Slop & Rigid 3 Concepts)**: Tự động vẽ ra các màn hình đầy thẻ Card bo góc kèm Gradient trôi nổi, hoặc ép buộc người dùng phải chọn giữa 3 concept cấu trúc xa lạ ngay cả khi họ chỉ muốn sao chép 1-1 giao diện cũ.
4. **Placeholder vô nghĩa (Lorem Ipsum Slop)**: Sử dụng văn bản mẫu giả lập thay vì nội dung thực tế, dẫn đến giao diện vỡ khi nạp dữ liệu thật.

### 1.2 Triết Lý "Bằng Chứng Trước - Phỏng Vấn Tối Thiểu - Đặc Tả Đóng Băng"
Khung Phỏng Vấn Thích Ứng (Adaptive Interview Framework) của REA-kit-agy được xây dựng trên 4 nguyên tắc sắt:
- **Evidence-First (Bằng chứng đi trước)**: Kiểm tra toàn bộ mã nguồn, tài nguyên tĩnh, ảnh chụp màn hình gốc và báo cáo kiểm toán trước khi mở lời.
- **Zero-Friction Questioning (Tối giản câu hỏi)**: Chỉ đặt câu hỏi khi thông tin đó thay đổi quyết định kiến trúc, có rủi ro cao, không thể đảo ngược, và không thể suy ra bằng giả định an toàn.
- **Adaptive Exploration (Khám phá theo ngữ cảnh)**: Phân biệt rõ giữa yêu cầu sao chép nguyên bản (`DESIGN_REUSE_EXACT`), áp dụng phong cách chỉ định (`DESIGN_STYLE_SPECIFIED`), và sáng tạo cấu trúc (`DESIGN_STRUCTURAL_EXPLORATION`). Chỉ kích hoạt 3 concepts khi người dùng thực sự muốn khám phá cấu trúc.
- **Frozen Contract (Đóng băng hợp đồng)**: Mọi câu hỏi, quyết định và giả định phải được ghi nhận vào hồ sơ có cấu trúc, chuyển hóa thành hợp đồng đặc tả Markdown bất biến trước khi chuyển sang Stage 04 (Lập trình).

---

## 2. KIẾN TRÚC TỔNG THỂ CỦA HỆ THỐNG (SYSTEM ARCHITECTURE)

Hệ thống phỏng vấn thích ứng được hợp thành từ 6 phân hệ động cơ liên hoàn:

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                   HỆ THỐNG PHỎNG VẤN THÍCH ỨNG TOÀN DIỆN                         │
├──────────────────────────────────────────────────────────────────────────────────┤
│ 1. PHÂN HỆ TIẾP NHẬN BỐI CẢNH (CONTEXT INGESTION)                                │
│    Đọc đồng thời:                                                                │
│    - 02_YEU_CAU_CUA_TOI/ho-so-va-muc-tieu.md                                     │
│    - 03_KET_QUA_KIEM_TRA/bao-cao-hien-trang.md                                   │
│    - 03_KET_QUA_KIEM_TRA/UNKNOWNS_AND_COVERAGE.md                                │
│    - Ảnh chụp màn hình ứng dụng gốc (AVD/Browser từ Bước 02)                     │
├──────────────────────────────────────────────────────────────────────────────────┤
│ 2. ĐỘNG CƠ ĐIỀU HƯỚNG TÊN MIỀN (DOMAIN ROUTING ENGINE)                           │
│    Phân loại mục tiêu case vào 1 trong 6 Domain:                                 │
│    [APP_OPT] [SECURITY] [FEAT_ADD] [FEAT_OPT] [BUG_FIX] [UX_UI]                 │
├──────────────────────────────────────────────────────────────────────────────────┤
│ 3. ĐỘNG CƠ SÀNG LỌC CÂU HỎI (QUESTION NECESSITY ENGINE - 8 FILTERS)              │
│    Kiểm tra 8 bộ lọc: Known, Inspectable, Evidence, Impact, Risk,                │
│    Reversibility, Ownership, Timing. Triệt tiêu câu hỏi thừa.                     │
├──────────────────────────────────────────────────────────────────────────────────┤
│ 4. ĐỘNG CƠ THEO DÕI QUYẾT ĐỊNH & GIẢ ĐỊNH (DECISION & CONSTRAINT ENGINE)         │
│    Duy trì 3 sổ cái bất biến: Question Record, Decision Record, Assumption Record│
├──────────────────────────────────────────────────────────────────────────────────┤
│ 5. BỘ ĐIỀU KHIỂN KHÁM PHÁ THIẾT KẾ (DESIGN EXPLORATION CONTROLLER)               │
│    - DESIGN_REUSE_EXACT ────────► Bỏ 3 concepts, clone 1-1                       │
│    - DESIGN_STYLE_SPECIFIED ────► Bỏ 3 concepts, theo phong cách người dùng chọn │
│    - DESIGN_STRUCTURAL_EXPLORATION ► Đề xuất 3 Concepts cấu trúc khác biệt       │
├──────────────────────────────────────────────────────────────────────────────────┤
│ 6. QUY CHUẨN THẨM MỸ ANTI-SLOP & ĐÓNG BĂNG ĐẶC TẢ (SPEC FREEZE GATE)             │
│    - 7 thành phần Art Direction                                                  │
│    - Copy Deck thực tế (Cấm Lorem Ipsum)                                         │
│    - 4 Trạng thái giao diện bắt buộc                                             │
│    - Design Tokens 3 tầng (design.md) ➔ Phê duyệt dac-ta-yeu-cau-da-chot.md      │
└──────────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. ĐỘNG CƠ SÀNG LỌC CÂU HỎI (QUESTION NECESSITY ENGINE)

### 3.1 Công Thức Quyết Định Logic (Decision Logic Formula)
Một câu hỏi tiềm năng $q$ chỉ được phép gửi tới người dùng khi và chỉ khi thỏa mãn biểu thức logic:

$$Ask(q) = \neg Known(q) \land \neg Inspectable(q) \land \neg Evidence(q) \land Impact(q) \land (Risk(q) \lor \neg Reversible(q)) \land Ownership(q) \land Timing(q)$$

Nếu biểu thức trên có giá trị `FALSE`, Agent phân loại và xử lý theo **5 nhánh hành động tường minh**:
1. $\text{Known}(q) \lor \text{Inspectable}(q) \lor \text{Evidence}(q) = \text{TRUE}$: **HỦY BỎ & TỰ TRÍCH XUẤT BẰNG CHỨNG**.
2. $\text{Impact}(q) = \text{FALSE}$: **HỦY BỎ (CÂU HỎI RÂU RIA/TRIVIA)**.
3. $\text{Ownership}(q) = \text{FALSE}$: **TỰ RA QUYẾT ĐỊNH KỸ THUẬT & KHÓA VÀO SPEC NỘI BỘ** (Người dùng là Product Owner, không hỏi về pattern, thư viện nội bộ hay cú pháp; Agent tự quyết định giải pháp kỹ thuật tối ưu).
4. $\text{Reversible}(q) = \text{TRUE} \land \text{Risk}(q) = \text{FALSE}$: **CHỌN MẶC ĐỊNH AN TOÀN & GHI ASSUMPTION RECORD** (Kèm phân hạng `risk_level`: BENIGN hoặc CRITICAL).
5. $\text{Timing}(q) = \text{FALSE}$: **HOÃN LẠI MILESTONE SAU (DEFER)** (Chỉ kích hoạt khi bước vào milestone tương ứng).

### 3.2 Đặc Tả Chi Tiết 8 Bộ Lọc Tuần Tự

```
┌───────────────────────────────────────────────────────────────────────────────────────┐
│                       CHI TIẾT 8 BỘ LỌC CỦA QUESTION NECESSITY ENGINE                 │
├─────────────────┬───────────────────────────────────┬─────────────────────────────────┤
│ Bộ Lọc          │ Điều Kiện Kiểm Tra               │ Hành Động Khi Vi Phạm           │
├─────────────────┼───────────────────────────────────┼─────────────────────────────────┤
│ 1. KNOWN        │ Người dùng đã cung cấp ở          │ HUỶ BỎ CÂU HỎI. Không bao giờ   │
│                 │ ho-so-va-muc-tieu.md hoặc chat?   │ hỏi lại những gì đã biết.       │
├─────────────────┼───────────────────────────────────┼─────────────────────────────────┤
│ 2. INSPECTABLE  │ Có thể tự đọc qua code, config,   │ HUỶ BỎ CÂU HỎI. Agent tự chạy   │
│                 │ manifest, gradle, SQLite schema?  │ lệnh đọc file và lấy kết quả.   │
├─────────────────┼───────────────────────────────────┼─────────────────────────────────┤
│ 3. EVIDENCE     │ Đã có ảnh chụp giao diện gốc      │ TRÍCH DẪN BẰNG CHỨNG. Không     │
│                 │ hoặc logcat/báo cáo chứng minh?   │ hỏi cảm tính khi đã có sự thật. │
├─────────────────┼───────────────────────────────────┼─────────────────────────────────┤
│ 4. IMPACT       │ Câu trả lời có làm đổi kiến trúc, │ LOẠI BỎ NGAY LẬP TỨC. Đây là    │
│                 │ phạm vi, hoặc code ở Stage 04?    │ câu hỏi râu ria, không giá trị. │
├─────────────────┼───────────────────────────────────┼─────────────────────────────────┤
│ 5. RISK         │ Có rủi ro thất thoát dữ liệu, vi  │ Nếu rủi ro cao: BẮT BUỘC HỎI.   │
│                 │ phạm pháp lý, bảo mật, phá hủy?   │ Nếu rủi ro thấp: Tự áp mặc định.│
├─────────────────┼───────────────────────────────────┼─────────────────────────────────┤
│ 6. REVERSIBILITY│ Quyết định có dễ đảo ngược sau    │ CHỌN MẶC ĐỊNH AN TOÀN và ghi    │
│                 │ (Two-Way Door) bằng config không? │ vào Sổ Giả Định (Assumption).   │
├─────────────────┼───────────────────────────────────┼─────────────────────────────────┤
│ 7. OWNERSHIP    │ Người dùng có thẩm quyền nghiệp   │ TỰ RA QUYẾT ĐỊNH KỸ THUẬT.      │
│                 │ vụ, hay câu hỏi thuần kỹ thuật?   │ Không hỏi PO về syntax/pattern. │
├─────────────────┼───────────────────────────────────┼─────────────────────────────────┤
│ 8. TIMING       │ Có cần thiết ngay ở Stage 03 để   │ HOÃN LẠI (DEFER). Chỉ hỏi khi   │
│                 │ đóng băng đặc tả hay để Stage 05? │ bước vào Milestone cần dùng.    │
└─────────────────┴───────────────────────────────────┴─────────────────────────────────┘
```

---

## 4. ĐỘNG CƠ THEO DÕI QUYẾT ĐỊNH & GIẢ ĐỊNH (DECISION & CONSTRAINT ENGINE)

Mọi thỏa thuận, câu hỏi và mặc định kỹ thuật đều được cấu trúc hóa vào 3 loại hồ sơ (Records) và đồng bộ trong tài liệu `dac-ta-yeu-cau-da-chot.md` và `.agents/state/active_case.json`:

### 4.1 Schema Hồ Sơ Câu Hỏi (Question Record)
```json
{
  "question_id": "Q-01",
  "domain": "APP_OPTIMIZATION",
  "topic": "Target device segment",
  "necessity_eval": {
    "known": false,
    "inspectable": false,
    "evidence": false,
    "decision_impact": true,
    "risk": "MEDIUM",
    "reversibility": "LOW",
    "ownership": "PRODUCT_OWNER",
    "timing": "STAGE_03"
  },
  "question_text": "Ứng dụng cần ưu tiên mượt mà trên thiết bị Android Go (RAM < 2GB) hay nhắm tới thiết bị tầm trung trở lên?",
  "status": "ANSWERED",
  "answer_text": "Cần hỗ trợ Android Go mượt mà.",
  "recorded_at": "2026-11-14T10:00:00Z"
}
```

### 4.2 Schema Hồ Sơ Quyết Định (Decision Record)
```json
{
  "decision_id": "DECISION-01",
  "domain": "APP_OPTIMIZATION",
  "context": "Low-RAM performance degradation",
  "decision_made": "Kích hoạt chế độ Low-End Mode: tự động tắt hiệu ứng làm mờ và giảm độ phân giải cache ảnh trên máy < 2GB RAM.",
  "rationale": "Đảm bảo duy trì 60fps trên Android Go theo yêu cầu người dùng.",
  "implications": ["Thêm kiểm tra ActivityManager.isLowRamDevice()", "Tạo 2 profile Design Tokens"],
  "status": "FROZEN",
  "signed_by": "USER"
}
```

### 4.3 Schema Hồ Sơ Giả Định Mặc Định (Assumption Record)
```json
{
  "assumption_id": "ASSUMPTION-01",
  "domain": "UX_UI_IMPROVEMENT",
  "category": "Touch Target Dimension",
  "risk_level": "BENIGN",
  "default_value_chosen": "48x48dp tối thiểu cho mọi clickable view",
  "rationale": "Chuẩn công thái học Android Accessibility Guidelines & WCAG AA.",
  "reversibility": "HIGH",
  "verification_task": "Chạy verify_code.ps1 và kiểm tra layout XML ở Bước 10",
  "status": "ACTIVE",
  "invalidated_at": null,
  "revocation_reason": null,
  "downstream_dependencies": [
    "02_YEU_CAU_CUA_TOI/design.md",
    "03_KET_QUA_KIEM_TRA/01_SCREEN_COMPOSITION.md"
  ]
}
```

### 4.4 Quy Trình Vòng Đời & Quản Lý Giả Định (Assumption Lifecycle Protocol)
1. **Phân Hạng Mức Độ Rủi Ro (Assumption Risk Tiers)**:
   - **`risk_level: BENIGN` (Tier 1 - Vô hại)**: Các giả định về layout, khoảng cách, padding 16dp, touch target 48dp, debounce 300ms. Nếu thay đổi sau này chỉ tốn chi phí nhỏ về cấu hình CSS/Theme.
   - **`risk_level: CRITICAL` (Tier 2 - Nghiêm trọng)**: Các giả định về thời hạn lưu dữ liệu (data retention), chu kỳ đồng bộ mạng, chính sách ứng xử Play Integrity API, phạm vi phân quyền. Các giả định này nếu sai có nguy cơ gây mất dữ liệu hoặc vi phạm an ninh; bắt buộc phải được làm nổi bật trong bản tổng hợp `dac-ta-yeu-cau-da-chot.md` trước khi người dùng phê duyệt Gate 03.
2. **Trạng Thái Vòng Đời Giả Định (Assumption Status Transitions)**:
   - `ACTIVE`: Giả định đang có hiệu lực và được các module thiết kế/kế hoạch tuân thủ.
   - `INVALIDATED`: Giả định bị hủy bỏ do phát hiện mâu thuẫn từ dữ liệu mới, người dùng thay đổi yêu cầu giữa chừng, hoặc phát hiện bằng chứng mới trong mã nguồn APK. Khi chuyển sang `INVALIDATED`, bắt buộc ghi nhận timestamp vào `invalidated_at` và mô tả nguyên nhân vào `revocation_reason`.
   - `SUPERSEDED`: Giả định được nâng cấp hoặc thay thế chính thức bằng một `DECISION RECORD` do người dùng trực tiếp phê duyệt.
3. **Đồ Thị Phụ Thuộc & Lan Truyền Thu Hồi (Cascading Invalidation Blast Radius)**:
   - Mỗi `Assumption Record` duy trì danh sách `downstream_dependencies: []` ghi nhận toàn bộ các tài liệu đặc tả, bảng schema, hoặc decision records phát sinh dựa trên giả định đó.
   - Khi một giả định bị chuyển sang `INVALIDATED`, Agent kích hoạt quy trình quét đồ thị phụ thuộc, đánh dấu cảnh báo toàn bộ các artifact trong `downstream_dependencies`, và yêu cầu tái đánh giá trước khi tiếp tục triển khai.

---

## 5. MA TRẬN TIÊU CHÍ SẴN SÀNG VS BỊ CHẶN (READINESS VS BLOCKED MATRIX)

Tại cổng **Gate 03 (`gate_03_spec_frozen`)**, Agent tiến hành đánh giá tự động dựa trên ma trận sau:

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                     MA TRẬN ĐÁNH GIÁ VƯỢT CỔNG GATE 03 (READINESS VS BLOCKED)           │
├───────────────────────────────┬───────────────────────────────┬─────────────────────────┤
│ TIÊU CHÍ                      │ ĐẠT CHUẨN (READINESS: PASS)   │ BỊ CHẶN (BLOCKED)       │
├───────────────────────────────┼───────────────────────────────┼─────────────────────────┤
│ 1. CÂU HỎI CÒN TỒN ĐỌNG       │ 100% câu hỏi đã CLOSED,       │ Còn câu hỏi PENDING có  │
│    (Pending Questions)        │ hoặc DEFERRED có chủ đích.    │ Impact cao chưa trả lời.│
├───────────────────────────────┼───────────────────────────────┼─────────────────────────┤
│ 2. CỬA MỘT CHIỀU (One-Way)    │ Mọi quyết định One-Way Door   │ Tự tiện đưa ra giả định │
│    & RỦI RO BẢO MẬT           │ đã được người dùng ký duyệt.  │ trên quyết định One-Way.│
├───────────────────────────────┼───────────────────────────────┼─────────────────────────┤
│ 3. SỔ THEO DÕI UNKNOWNS       │ Toàn bộ Unknowns từ Bước 05   │ Bỏ quên Unknowns nghiêm │
│    (Unknowns Ledger)          │ có phương án xử lý/cô lập.    │ trọng mà không cảnh báo.│
├───────────────────────────────┼───────────────────────────────┼─────────────────────────┤
│ 4. HỢP ĐỒNG 4 TRẠNG THÁI UI   │ Đầy đủ Loading, Empty, Success│ Thiếu xử lý lỗi hoặc vi │
│    (4 UI States Specification)│ và Error bảo toàn form.       │ phạm RULE-INIT-001.     │
├───────────────────────────────┼───────────────────────────────┼─────────────────────────┤
│ 5. COPY DECK & TOKENS         │ 100% tiếng Việt ngữ cảnh thật;│ Chứa "Lorem ipsum" hoặc │
│    (Anti-Slop Compliance)     │ design.md đủ 3 tầng tokens.   │ tokens thiếu giá trị cụ thể. │
├───────────────────────────────┼───────────────────────────────┼─────────────────────────┤
│ 6. LỆNH PHÊ DUYỆT NGƯỜI DÙNG  │ Người dùng đã gõ lệnh:        │ Người dùng chưa duyệt   │
│    (Human Approval Command)   │ APPROVE UI SPEC               │ hoặc yêu cầu sửa đổi.   │
└───────────────────────────────┴───────────────────────────────┴─────────────────────────┘
```

- **Quy Tắc Tự Động Hóa Vượt Cổng (Autonomous Progression via Assumptions)**:
  * Nếu các vấn đề còn lại chỉ là quyết định hai chiều (Two-Way Door), Agent được phép tự động áp dụng giả định an toàn trong `Assumption Record` và tiếp tục quy trình, không được phép làm phiền hoặc chặn công việc của người dùng.
- **Quy Tắc Dừng Khẩn Cấp (Hard Block Trigger)**:
  * Khi phát hiện nguy cơ rò rỉ bảo mật nghiêm trọng (Hardcoded credentials), mâu thuẫn trực tiếp giữa mong muốn người dùng và năng lực nền tảng, hoặc hành động xóa dữ liệu không phục hồi được, Agent bắt buộc kích hoạt `BLOCKED`, dừng lại báo cáo người dùng và chờ lệnh.

---

## 6. BỘ KIỂM THỬ TOÀN DIỆN 35 TÌNH HUỐNG (TEST CASES INT-01 TO INT-35)

Bộ kiểm thử 35 test cases được thiết kế để xác thực tính đúng đắn, thông minh và chống suy diễn của Khung Phỏng Vấn Thích Ứng trên 7 nhóm kịch bản:

```
┌────────────────────────────────────────────────────────────────────────┐
│                   DANH MỤC 35 TEST CASES PHỎNG VẤN THÍCH ỨNG           │
├────────────────────────────────────────────────────────────────────────┤
│ NHÓM 1: BỘ LỌC CÂU HỎI & CROSS-CUTTING        (INT-01 đến INT-05)       │
│ NHÓM 2: TỐI ƯU HÓA HỆ THỐNG (APP OPTIMIZATION) (INT-06 đến INT-10)     │
│ NHÓM 3: GIA CỐ BẢO MẬT (SECURITY HARDENING)   (INT-11 đến INT-15)      │
│ NHÓM 4: THÊM TÍNH NĂNG MỚI (FEATURE ADDITION) (INT-16 đến INT-20)      │
│ NHÓM 5: TỐI ƯU TÍNH NĂNG (FEATURE OPTIMIZATION)(INT-21 đến INT-25)     │
│ NHÓM 6: KHẮC PHỤC LỖI (BUG FIX)               (INT-26 đến INT-30)      │
│ NHÓM 7: GIAO DIỆN & TRẢI NGHIỆM (UX/UI MODES) (INT-31 đến INT-35)      │
└────────────────────────────────────────────────────────────────────────┘
```

---

### NHÓM 1: BỘ LỌC CÂU HỎI & CROSS-CUTTING (INT-01 ĐẾN INT-05)

#### INT-01: Triệt Tiêu Câu Hỏi Đã Biết (Known Filter Suppression)
- **Tình Huống**: Người dùng đã ghi rõ trong `ho-so-va-muc-tieu.md`: *"Mục tiêu: Xây dựng lại ứng dụng Ghi Chú Cá Nhân hỗ trợ tiếng Việt hoàn toàn"*.
- **Domain Kích Hoạt**: `FEATURE_ADDITION` / `UX_UI_IMPROVEMENT`
- **Đánh Giá Bộ Lọc**:
  * Ý định hỏi: "Bạn muốn làm ứng dụng về chủ đề gì và ngôn ngữ nào?"
  * `Filter 1 (Known)`: **FAIL** (Đã có trong `ho-so-va-muc-tieu.md`).
- **Hành Động Của Agent**: Triệt tiêu hoàn toàn câu hỏi. Ghi nhận trực tiếp vào hồ sơ phân tích: `AppType = NoteTaking`, `Language = vi-VN`.
- **Đầu Ra Kỳ Vọng**: Không gửi câu hỏi thừa tới người dùng; mở đầu bằng việc xác nhận các nghiệp vụ chi tiết hơn.
- **Tiêu Chí Kiểm Thử**: Số lượng câu hỏi gửi người dùng về thể loại app = 0.

#### INT-02: Tự Đọc Thông Tin Hệ Thống Từ Code (Inspectable Filter Suppression)
- **Tình Huống**: Agent cần biết phiên bản `minSdkVersion` và các quyền hệ thống `uses-permission` của app gốc.
- **Domain Kích Hoạt**: `APP_OPTIMIZATION` / `SECURITY_HARDENING`
- **Đánh Giá Bộ Lọc**:
  * Ý định hỏi: "Ứng dụng gốc yêu cầu Android bao nhiêu và những quyền gì?"
  * `Filter 2 (Inspectable)`: **FAIL** (Có sẵn trong `AndroidManifest.xml` và `build.gradle`).
- **Hành Động Của Agent**: Chạy lệnh đọc trực tiếp file cấu hình; trích xuất `minSdk = 26`, các quyền `INTERNET`, `ACCESS_NETWORK_STATE`.
- **Đầu Ra Kỳ Vọng**: Báo cáo hiện trạng chứa đầy đủ thông số kỹ thuật mà không cần hỏi người dùng 1 từ.
- **Tiêu Chí Kiểm Thử**: Không xuất hiện câu hỏi liên quan đến manifest/gradle trong chat.

#### INT-03: Sử Dụng Bằng Chứng Thị Giác Thực Tế (Evidence Filter Suppression)
- **Tình Huống**: Trong Bước 02, Agent đã chụp được 5 ảnh màn hình thực tế từ thiết bị AVD hiển thị rõ bố cục thanh điều hướng ở đáy màn hình (Bottom Navigation Bar).
- **Domain Kích Hoạt**: `UX_UI_IMPROVEMENT`
- **Đánh Giá Bộ Lọc**:
  * Ý định hỏi: "Ứng dụng gốc có thanh menu ở dưới chân hay ở trên đầu?"
  * `Filter 3 (Evidence)`: **FAIL** (Bằng chứng ảnh chụp `01_screen_main.png` thể hiện rõ BottomNavigationBar).
- **Hành Động Của Agent**: Trích dẫn bằng chứng ảnh chụp, lập hồ sơ hiện trạng xác nhận ứng dụng dùng BottomNavigation.
- **Đầu Ra Kỳ Vọng**: Trích dẫn file ảnh, tự động thiết lập layout tương ứng.
- **Tiêu Chí Kiểm Thử**: Tự động nhận diện thành phần UI từ bằng chứng thực tế.

#### INT-04: Tự Áp Dụng Giả Định Cho Quyết Định Thuận Nghịch (Reversibility & Assumption)
- **Tình Huống**: Agent băn khoăn về dung lượng bộ nhớ đệm (LRU cache) cho thư viện nạp ảnh.
- **Domain Kích Hoạt**: `APP_OPTIMIZATION`
- **Đánh Giá Bộ Lọc**:
  * Ý định hỏi: "Bạn muốn đặt kích thước bộ đệm ảnh là 20MB hay 50MB?"
  * `Filter 6 (Reversibility)`: **TRUE** (Hai chiều, dễ đổi qua config).
  * `Filter 5 (Risk)`: **LOW** (Không gây mất dữ liệu).
- **Hành Động Của Agent**: Không hỏi người dùng. Chọn mặc định 30MB (tương đương 15% heap), tạo `ASSUMPTION-OPT-01`.
- **Đầu Ra Kỳ Vọng**: Xuất hiện `ASSUMPTION-OPT-01` trong hồ sơ đặc tả, tiến trình tiếp tục không bị gián đoạn.
- **Tiêu Chí Kiểm Thử**: Tồn tại bản ghi giả định hợp lệ; không có tin nhắn hỏi người dùng về cache size.

#### INT-05: Từ Chối Hỏi Thẩm Quyền Kỹ Thuật Thuần Túy (Ownership Filter Suppression)
- **Tình Huống**: Cần quyết định dùng Kotlin Coroutines Dispatchers.IO hay Dispatchers.Default để đọc SQLite.
- **Domain Kích Hoạt**: `APP_OPTIMIZATION`
- **Đánh Giá Bộ Lọc**:
  * Ý định hỏi: "Bạn muốn xử lý I/O trên Dispatcher nào?"
  * `Filter 7 (Ownership)`: **FAIL** (Người dùng là Product Owner, đây là thẩm quyền kỹ thuật của Agent).
- **Hành Động Của Agent**: Loại bỏ câu hỏi. Tự động áp dụng chuẩn công nghiệp `Dispatchers.IO` cho database operations.
- **Đầu Ra Kỳ Vọng**: Không làm phiền người dùng bằng thuật ngữ kỹ thuật chuyên sâu.
- **Tiêu Chí Kiểm Thử**: Chat sạch thuật ngữ dispatcher nội bộ.

---

### NHÓM 2: TỐI ƯU HÓA HỆ THỐNG (APP OPTIMIZATION) (INT-06 ĐẾN INT-10)

#### INT-06: Khắc Phục Hiện Tượng Giật Khung Hình (Jank & Frame Drop Triage)
- **Tình Huống**: Người dùng báo ứng dụng bị giật đơ khi cuộn danh sách sản phẩm.
- **Domain Kích Hoạt**: `APP_OPTIMIZATION` (Pillar 1: Performance)
- **Hành Động Của Agent**:
  * Tự kiểm tra code phát hiện item composable đang khởi tạo DateFormatter mới mỗi lần vẽ.
  * Hỏi người dùng duy nhất 1 câu về thiết bị thử nghiệm thực tế nếu cần.
  * Thiết lập mục tiêu KPI: Dropped frames < 1% (chuẩn 60fps).
- **Đầu Ra Kỳ Vọng**: `DECISION-OPT-02`: Tái sử dụng DateFormatter qua static instance, bổ sung item prefetching.
- **Tiêu Chí Kiểm Thử**: Đạt KPI 60fps trên profile test.

#### INT-07: Giảm Độ Trễ Khởi Động Nguội (Cold Start Latency Reduction)
- **Tình Huống**: Ứng dụng mất 3.5 giây để mở màn hình đầu tiên.
- **Domain Kích Hoạt**: `APP_OPTIMIZATION` (Pillar 1: Performance)
- **Hành Động Của Agent**:
  * Phân tích `Application.onCreate()`, phát hiện 6 SDK bên thứ ba đang khởi tạo đồng bộ trên UI Thread.
  * Áp dụng App Startup library / khởi tạo lười (lazy initialization).
  * Thiết lập KPI: Cold Start giảm từ 3.5s xuống < 1.2s.
- **Đầu Ra Kỳ Vọng**: `01_SCREEN_COMPOSITION.md` bổ sung Splash Screen chuẩn Android 12+.
- **Tiêu Chí Kiểm Thử**: Thời gian khởi động đạt mục tiêu cam kết.

#### INT-08: Triệt Tiêu Rò Rỉ Bộ Nhớ & Tối Ưu Bitmap (RAM & Heap Optimization)
- **Tình Huống**: App bị văng (OOM) sau khi người dùng lướt qua 20 trang ảnh.
- **Domain Kích Hoạt**: `APP_OPTIMIZATION` (Pillar 2: Resource)
- **Hành Động Của Agent**:
  * Xác định kích thước ảnh tải về đang là 4000x3000px nạp trực tiếp vào RAM.
  * Tự động áp dụng Downsampling và Bitmap Pool qua Coil/Glide.
  * Tạo `ASSUMPTION-OPT-03`: Giới hạn kích thước decode ảnh khớp kích thước màn hình thiết bị.
- **Đầu Ra Kỳ Vọng**: Peak RAM duy trì dưới 80MB.
- **Tiêu Chí Kiểm Thử**: Không xuất hiện OutOfMemoryError khi lướt liên tục.

#### INT-09: Tối Ưu Tiêu Hao Pin & Đồng Bộ Nền (Battery & Background Sync)
- **Tình Huống**: App chạy service ngầm liên tục hỏi server 10 giây/lần làm nóng máy hao pin.
- **Domain Kích Hoạt**: `APP_OPTIMIZATION` (Pillar 2: Resource)
- **Hành Động Của Agent**:
  * Đặt câu hỏi đánh đổi: "App có cần nhận tin tức thì từng giây không hay chấp nhận đồng bộ ngầm định kỳ 15 phút một lần để tiết kiệm 80% pin?"
  * Người dùng chọn: Tiết kiệm pin.
- **Đầu Ra Kỳ Vọng**: `DECISION-OPT-03`: Chuyển sang `WorkManager` với ràng buộc có mạng và chu kỳ 15 phút.
- **Tiêu Chí Kiểm Thử**: Loại bỏ hoàn toàn Foreground Service vô ích.

#### INT-10: Tương Thích Thiết Bị Cấu Hình Thấp (Low-RAM Android Go Compatibility)
- **Tình Huống**: Cần đảm bảo chạy tốt trên máy Android Go RAM 1GB.
- **Domain Kích Hoạt**: `APP_OPTIMIZATION` (Pillar 5: Compatibility)
- **Hành Động Của Agent**:
  * Thiết lập chính sách Graceful Degradation: Tự động tắt RenderEffect blur và bóng đổ khi phát hiện `ActivityManager.isLowRamDevice()`.
  * Ghi vào `02_RESPONSIVE_SPEC.md`.
- **Đầu Ra Kỳ Vọng**: Hệ thống hoạt động mượt mà không tràn RAM trên thiết bị giả lập 1GB.
- **Tiêu Chí Kiểm Thử**: FPS > 50fps trên thiết bị low-ram profile.

---

### NHÓM 3: GIA CỐ BẢO MẬT (SECURITY HARDENING) (INT-11 ĐẾN INT-15)

#### INT-11: Cấm Lưu Thông Mạng Rõ & Ép Buộc TLS 1.3 (Cleartext HTTP Ban & TLS Enforcement)
- **Tình Huống**: Bước 04 phát hiện app đang gọi API `http://api.example.com` dạng text rõ.
- **Domain Kích Hoạt**: `SECURITY_HARDENING` (Pillar 4: Network Security)
- **Hành Động Của Agent**:
  * Không hỏi người dùng có muốn dùng HTTP không (đây là rủi ro bảo mật nghiêm trọng).
  * Tự động cấu hình `network_security_config.xml` với `cleartextTrafficPermitted="false"` để chặn đứng HTTP không mã hóa ở cấp hệ điều hành.
  * ⚠️ **Chính xác hóa kỹ thuật**: Schema XML của `network_security_config.xml` **không hỗ trợ** thẻ hay thuộc tính quy định phiên bản TLS. Việc ép buộc TLS 1.3 được triển khai tường minh ở tầng HTTP Client (OkHttp `ConnectionSpec.MODERN_TLS` / `RESTRICTED_TLS` chỉ chấp nhận `TLS_1_3, TLS_1_2`). Lưu ý trên Android 15 (API 35), hệ điều hành đã chặn hoàn toàn TLS 1.0 và TLS 1.1 ở tầng socket.
  * Ghi `DECISION-SEC-01`: Bắt buộc TLS 1.3 qua HTTP Client ConnectionSpec, cấm cleartext qua Network Security Config.
- **Đầu Ra Kỳ Vọng**: `AndroidManifest.xml` có `android:usesCleartextTraffic="false"`, OkHttpClient được cấu hình `ConnectionSpec.MODERN_TLS`.
- **Tiêu Chí Kiểm Thử**: Lệnh kiểm tra mạng chặn đứng mọi kết nối HTTP không an toàn; socket đàm phán thành công TLS 1.3.

#### INT-12: Xử Lý Thiết Bị Đã Can Thiệp Hệ Thống (Play Integrity API & Device Tamper Triage)
- **Tình Huống**: Ứng dụng ví điện tử/tài chính chạy trên môi trường có nguy cơ bị can thiệp (Root, Custom ROM, Hooking frameworks).
- **Domain Kích Hoạt**: `SECURITY_HARDENING` (Pillar 5: Device Integrity & Resilience)
- **Hành Động Của Agent**:
  * Loại bỏ các kiểm tra heuristic cục bộ kiểu RootBeer / SafetyNet (SafetyNet đã đóng cửa hoàn toàn tháng 01/2025; các heuristic client-side dễ dàng bị vô hiệu hóa bởi Magisk Zygisk/Shamiko, KernelSU, APatch).
  * Thiết lập kiến trúc **Google Play Integrity API** với quy trình gửi nonce từ máy chủ, lấy attestation token trên client và giải mã verdict tại backend theo chuẩn **OWASP MASVS-RESILIENCE v2.0**:
    * Kiểm tra `MEETS_DEVICE_INTEGRITY` và `MEETS_APP_INTEGRITY`.
  * Đặt câu hỏi chính sách: "Khi Google Play Integrity API trả về phán quyết thiết bị không đạt chuẩn (không đạt MEETS_DEVICE_INTEGRITY), ứng dụng nên: (A) Chặn mở hoàn toàn, (B) Cảnh báo rủi ro người dùng và vô hiệu hóa các tính năng thanh toán/sinh trắc học, hay (C) Ghi nhận cờ rủi ro lên backend và cho phép người dùng tiếp tục?"
  * Người dùng chọn: Phương án B.
- **Đầu Ra Kỳ Vọng**: `DECISION-SEC-02`: Tích hợp Google Play Integrity API kèm xác thực backend, cảnh báo rủi ro và khóa sinh trắc học/thanh toán khi verdict không đạt chuẩn.
- **Tiêu Chí Kiểm Thử**: Client tích hợp Play Integrity SDK gửi token lên backend; mock backend phản hồi verdict failure kích hoạt luồng vô hiệu hóa sinh trắc học và hiển thị cảnh báo an toàn.

#### INT-13: Chống Chụp Trộm Màn Hình Nhạy Cảm (Screen Protection via FLAG_SECURE)
- **Tình Huống**: Màn hình hiển thị mã OTP và số dư tài khoản ngân hàng.
- **Domain Kích Hoạt**: `SECURITY_HARDENING` (Pillar 3: Data Protection)
- **Hành Động Của Agent**:
  * Không hỏi người dùng; tự động kích hoạt `FLAG_SECURE` cho màn hình nhạy cảm theo chuẩn bảo vệ dữ liệu.
  * Ghi `ASSUMPTION-SEC-01`: Bật chống chụp màn hình trên màn hình thanh toán.
- **Đầu Ra Kỳ Vọng**: `03_STATE_COMPOSITION.md` quy định rõ trạng thái hiển thị mờ trong Recent Apps.
- **Tiêu Chí Kiểm Thử**: Ảnh chụp màn hình trên màn hình này trả về màu đen.

#### INT-14: Che Mờ Khóa Bí Mật & Vệ Sinh Mã Nguồn (Secret Hygiene & Redaction)
- **Tình Huống**: Phát hiện API key `AIzaSy...` nằm lộ trong source code Java/Kotlin.
- **Domain Kích Hoạt**: `SECURITY_HARDENING` (Pillar 1: Assets & Keys)
- **Hành Động Của Agent**:
  * TUYỆT ĐỐI KHÔNG hỏi người dùng: "API key thật của bạn là gì?"
  * Che mờ key thành `[REDACTED_API_KEY]`, đưa vào file `local.properties` mẫu không commit lên git.
  * Tạo hướng dẫn nhập key an toàn trong `dac-ta-yeu-cau-da-chot.md`.
- **Đầu Ra Kỳ Vọng**: Toàn bộ repo sạch mã bí mật; bảo vệ người dùng tuyệt đối.
- **Tiêu Chí Kiểm Thử**: `verify_code.ps1` không phát hiện API key trôi nổi.

#### INT-15: Rà Soát Thư Viện Chứa Lỗ Hổng CVE (Supply Chain Vulnerability Audit)
- **Tình Huống**: Thư viện JSON cũ bị cảnh báo dính lỗ hổng Remote Code Execution.
- **Domain Kích Hoạt**: `SECURITY_HARDENING` (Pillar 6: Supply Chain)
- **Hành Động Của Agent**:
  * Tự động nâng cấp phiên bản thư viện an toàn hoặc chuyển sang Kotlinx Serialization.
  * Báo cáo trong `UNKNOWNS_AND_COVERAGE.md`.
- **Đầu Ra Kỳ Vọng**: `DECISION-SEC-03`: Thay thế thư viện nguy hiểm bằng giải pháp an toàn.
- **Tiêu Chí Kiểm Thử**: Danh mục dependencies sạch các CVE nghiêm trọng đã biết.

---

### NHÓM 4: THÊM TÍNH NĂNG MỚI (FEATURE ADDITION) (INT-16 ĐẾN INT-20)

#### INT-16: Thêm Tính Năng Ghi Chú Hoạt Động Ngoại Tuyến (Offline-First Notes)
- **Tình Huống**: Người dùng yêu cầu: *"Thêm tính năng tạo ghi chú có thể hoạt động khi mất mạng"*.
- **Domain Kích Hoạt**: `FEATURE_ADDITION`
- **Hành Động Của Agent**:
  * Tầng 1 (Outcome): Người dùng ghi lại ý tưởng bất cứ lúc nào, không bao giờ mất dữ liệu.
  * Tầng 2 (Behavior): Happy path tạo ghi chú; xử lý khi đang gõ thì tắt máy.
  * Tầng 3 (Implementation): Bảng SQLite `notes (id, title, content, updated_at, sync_status)`.
- **Đầu Ra Kỳ Vọng**: Đặc tả hoàn chỉnh 3 tầng kèm 4 trạng thái UI.
- **Tiêu Chí Kiểm Thử**: Dữ liệu lưu thành công khi thiết bị bật Airplane Mode.

#### INT-17: Tính Năng Tìm Kiếm Tức Thì Với Debounce (Instant Search Debounce)
- **Tình Huống**: Thêm ô tìm kiếm danh bạ / sản phẩm theo thời gian thực.
- **Domain Kích Hoạt**: `FEATURE_ADDITION`
- **Hành Động Của Agent**:
  * Tự động áp dụng cơ chế lọc Debounce 300ms chống nghẽn UI.
  * Hỏi người dùng về hành vi: "Khi không tìm thấy kết quả nào, app nên hiển thị thông báo rỗng hay gợi ý các từ khóa phổ biến?"
- **Đầu Ra Kỳ Vọng**: `03_STATE_COMPOSITION.md` định nghĩa rõ Empty Search State với CTA gợi ý.
- **Tiêu Chí Kiểm Thử**: Tìm kiếm phản hồi mượt mà không gọi query liên tục từng ký tự.

#### INT-18: Phân Quyền Vai Trò Người Dùng (User Roles & Access Boundary)
- **Tình Huống**: Thêm tính năng quản lý nhân viên cho ứng dụng bán hàng.
- **Domain Kích Hoạt**: `FEATURE_ADDITION`
- **Hành Động Của Agent**:
  * Đặt câu hỏi nghiệp vụ: "Nhân viên thu ngân có được quyền xem báo cáo doanh thu tổng và chỉnh sửa giá sản phẩm không, hay chỉ quyền tạo đơn?"
  * Người dùng chốt: Chỉ quyền tạo đơn.
- **Đầu Ra Kỳ Vọng**: `DECISION-FEAT-01`: Thiết lập 2 Role `ADMIN` và `CASHIER` với phân quyền chặt chẽ.
- **Tiêu Chí Kiểm Thử**: Giao diện thu ngân ẩn hoàn toàn mục báo cáo doanh thu.

#### INT-19: Xác Định Ranh Giới Danh Sách Không Làm (Explicit Non-Goals)
- **Tình Huống**: Người dùng yêu cầu tính năng Chat nội bộ cho ứng dụng.
- **Domain Kích Hoạt**: `FEATURE_ADDITION`
- **Hành Động Của Agent**:
  * Xác định nguy cơ phình to phạm vi (Voice call, video call, gửi file nặng).
  * Làm việc với người dùng để chốt rõ: "Phiên bản này chỉ hỗ trợ gửi tin nhắn văn bản; cố tình KHÔNG LÀM gọi video và chia sẻ vị trí realtime (Non-Goals)."
- **Đầu Ra Kỳ Vọng**: Danh sách Non-Goals được đóng băng trong `dac-ta-yeu-cau-da-chot.md`.
- **Tiêu Chí Kiểm Thử**: Ngăn chặn 100% các task phát sinh ngoài phạm vi trong Stage 04.

#### INT-20: Nâng Cấp Lược Đồ Dữ Liệu Bảo Toàn Dữ Liệu Cũ (Backward Compatible Migration)
- **Tình Huống**: Thêm trường `avatar_url` và `phone_number` vào bảng người dùng đã có 10.000 bản ghi.
- **Domain Kích Hoạt**: `FEATURE_ADDITION`
- **Hành Động Của Agent**:
  * Tuyệt đối không xóa database làm lại từ đầu.
  * Thiết kế Room Migration tự động thêm cột mới với giá trị mặc định an toàn.
  * Ghi nhận trong Implementation Spec.
- **Đầu Ra Kỳ Vọng**: Migration script kiểm thử thành công, giữ nguyên 100% dữ liệu cũ.
- **Tiêu Chí Kiểm Thử**: Bản ghi cũ sau nâng cấp vẫn bảo toàn dữ liệu.

---

### NHÓM 5: TỐI ƯU TÍNH NĂNG (FEATURE OPTIMIZATION) (INT-21 ĐẾN INT-25)

#### INT-21: Khắc Phục Hiện Tượng Recomposition Bão Hòa Trong Compose (Recomposition Storm)
- **Tình Huống**: Màn hình giỏ hàng bị đứng 500ms mỗi khi người dùng bấm tăng số lượng sản phẩm (+1).
- **Domain Kích Hoạt**: `FEATURE_OPTIMIZATION`
- **Hành Động Của Agent**:
  * Phân tích mã nguồn phát hiện Composable đang truyền State thô không dùng `@Stable` / `@Immutable`, gây recompose cả 30 items khi chỉ 1 item đổi số.
  * Khoanh vùng can thiệp: Tối ưu State hoisting và sử dụng `derivedStateOf`.
- **Đầu Ra Kỳ Vọng**: `DECISION-FEAT-OPT-01`: Chỉ recompose duy nhất con số hiển thị (+1), độ trễ giảm còn < 16ms.
- **Tiêu Chí Kiểm Thử**: Layout Inspector xác nhận số lần recompose của các item khác = 0.

#### INT-22: Bổ Sung Index Cho Truy Vấn Database Bị Nghẽn (Unindexed DB Query)
- **Tình Huống**: Màn hình lịch sử đơn hàng tải mất 2.4 giây khi danh sách đạt 1.000 đơn.
- **Domain Kích Hoạt**: `FEATURE_OPTIMIZATION`
- **Hành Động Của Agent**:
  * Phân tích Room Entity phát hiện cột `created_at` dùng để sắp xếp nhưng chưa được đánh chỉ mục.
  * Thêm Composite Index `[created_at, user_id]`.
  * Cam kết bảo toàn 100% dữ liệu hiển thị.
- **Đầu Ra Kỳ Vọng**: Thời gian truy vấn giảm từ 2.400ms xuống 45ms.
- **Tiêu Chí Kiểm Thử**: Query benchmark đạt tốc độ mong đợi.

#### INT-23: Tối Ưu Lưới Ảnh Bị Đầy Bộ Nhớ Bằng Downsampling (Grid Memory Optimization)
- **Tình Huống**: Màn hình xem bộ sưu tập ảnh thumbnail bị lag và nóng máy.
- **Domain Kích Hoạt**: `FEATURE_OPTIMIZATION`
- **Hành Động Của Agent**:
  * Phát hiện app đang tải file ảnh gốc kích thước 12MB về rồi tự co nhỏ bằng CSS/Modifier.
  * Tối ưu luồng: Thêm tham số resize hoặc generate thumbnail 200x200px cục bộ.
- **Đầu Ra Kỳ Vọng**: Lưu lượng mạng giảm 90%, bộ nhớ RAM giải phóng 120MB.
- **Tiêu Chí Kiểm Thử**: Cuộn danh sách đạt 60fps mượt mà.

#### INT-24: Cam Kết Bảo Toàn Hành Vi Nghiệp Vụ Tính Toán (Behavior Invariance Guarantee)
- **Tình Huống**: Tối ưu hóa thuật toán tính thuế và mã giảm giá trong luồng Checkout.
- **Domain Kích Hoạt**: `FEATURE_OPTIMIZATION`
- **Hành Động Của Agent**:
  * Xác định nguyên tắc: Tuyệt đối không thay đổi kết quả số tiền dù chỉ 1 đồng.
  * Viết bộ Unit Test với 50 kịch bản mã giảm giá kiểm chứng trước và sau khi refactor.
- **Đầu Ra Kỳ Vọng**: Kết quả tính toán khớp 100% bài test hồi quy.
- **Tiêu Chí Kiểm Thử**: 50/50 unit tests PASSED.

#### INT-25: Xác Lập & Nghiệm Thu Bảng Chỉ Số Before/After (KPI Verification)
- **Tình Huống**: Tối ưu màn hình xuất báo cáo PDF.
- **Domain Kích Hoạt**: `FEATURE_OPTIMIZATION`
- **Hành Động Của Agent**:
  * Thiết lập bảng đối chiếu chỉ số:
    * Thời gian xuất file: Từ 8.5s ➔ < 2.0s.
    * Dung lượng file PDF: Từ 15MB ➔ < 2.5MB.
- **Đầu Ra Kỳ Vọng**: Báo cáo nghiệm thu ghi nhận các chỉ số thực tế sau đo lường.
- **Tiêu Chí Kiểm Thử**: Đạt trọn vẹn cả 2 mục tiêu KPI.

---

### NHÓM 6: KHẮC PHỤC LỖI (BUG FIX) (INT-26 ĐẾN INT-30)

#### INT-26: Khắc Phục Lỗi Sập App Ngay Khi Khởi Động (NullPointerException Crash on Launch)
- **Tình Huống**: Người dùng cập nhật app bị crash ngay lập tức khi mở (Fatal Exception in MainActivity).
- **Domain Kích Hoạt**: `BUG_FIX` (Mức độ: `P0 - CRITICAL`)
- **Hành Động Của Agent**:
  * Đọc logcat thấy `NullPointerException` do trường `user_profile` từ API mới đổi tên thành `profile`.
  * Sửa lỗi: Cấu hình Deserializer hỗ trợ cả 2 tên trường cũ và mới; bổ sung kiểm tra null an toàn.
- **Đầu Ra Kỳ Vọng**: App khởi động bình thường ngay cả khi server trả dữ liệu cũ hoặc mới.
- **Tiêu Chí Kiểm Thử**: Không còn crash trên bản build mới.

#### INT-27: Khắc Phục Rò Rỉ Bộ Nhớ Do Static Context Listener (Context Memory Leak)
- **Tình Huống**: App dùng càng lâu càng chậm, cuối cùng bị hệ điều hành tắt ngắt.
- **Domain Kích Hoạt**: `BUG_FIX` (Mức độ: `P1 - HIGH`)
- **Hành Động Của Agent**:
  * Phân tích heap dump thấy `LocationManagerHelper` lưu giữ tham chiếu static tới `Activity` sau khi màn hình đã đóng.
  * Khắc phục: Chuyển sang `ApplicationContext` và hủy listener trong `onDestroy()`.
- **Đầu Ra Kỳ Vọng**: Bộ nhớ heap được giải phóng hoàn toàn sau khi đóng màn hình.
- **Tiêu Chí Kiểm Thử**: LeakCanary báo cáo 0 leak.

#### INT-28: Khắc Phục Lỗi Xung Đột Luồng Đồng Thời (ConcurrentModificationException)
- **Tình Huống**: App ngẫu nhiên bị văng khi đang nhận tin nhắn trong lúc cuộn danh sách.
- **Domain Kích Hoạt**: `BUG_FIX` (Mức độ: `P1 - HIGH`)
- **Hành Động Của Agent**:
  * Nhận diện nguyên nhân gốc: Vừa duyệt vòng lặp `ArrayList` vừa thêm phần tử mới từ background thread.
  * Khắc phục: Chuyển sang cấu trúc dữ liệu thread-safe hoặc cập nhật state qua immutable list copy.
- **Đầu Ra Kỳ Vọng**: Danh sách hoạt động ổn định khi nhận 100 tin nhắn dồn dập.
- **Tiêu Chí Kiểm Thử**: Stress test mô phỏng 1.000 messages không gây lỗi.

#### INT-29: Bảo Toàn Dữ Liệu Form Khi Xoay Màn Hình Hoặc Bị Lỗi (RULE-INIT-001 Invariance)
- **Tình Huống**: Người dùng đang nhập hồ sơ 10 trường thông tin thì xoay ngang máy, form bị xóa trắng toàn bộ dữ liệu.
- **Domain Kích Hoạt**: `BUG_FIX` (Mức độ: `P1 - HIGH`)
- **Hành Động Của Agent**:
  * Kích hoạt quy chuẩn `RULE-INIT-001`: Bảo toàn 100% dữ liệu form khi có biến động vòng đời.
  * Triển khai `SavedStateHandle` hoặc ViewModel State lưu trữ tức thời giá trị từng ô nhập.
- **Đầu Ra Kỳ Vọng**: Khi xoay ngang/dọc hoặc nhận cuộc gọi, toàn bộ chữ đã nhập được khôi phục nguyên vẹn.
- **Tiêu Chí Kiểm Thử**: Xoay màn hình 10 lần liên tục không mất 1 ký tự nào.

#### INT-30: Thêm Hộp Thoại Xác Nhận Hành Động Phá Hủy (Destructive Confirmation Dialog)
- **Tình Huống**: Người dùng vô tình chạm vào nút "Xóa Toàn Bộ Dữ Liệu" làm mất hết lịch sử mà không có hỏi lại.
- **Domain Kích Hoạt**: `BUG_FIX` / `UX_UI_IMPROVEMENT`
- **Hành Động Của Agent**:
  * Bổ sung hộp thoại cảnh báo nguy hiểm (Destructive Confirmation Dialog) yêu cầu người dùng xác nhận tường minh trước khi xóa.
  * Tích hợp vào `03_STATE_COMPOSITION.md`.
- **Đầu Ra Kỳ Vọng**: Hành động xóa chỉ diễn ra sau khi người dùng bấm xác nhận lần thứ hai.
- **Tiêu Chí Kiểm Thử**: Thao tác chạm vô tình không làm mất dữ liệu.

---

### NHÓM 7: GIAO DIỆN & TRẢI NGHIỆM (UX/UI MODES) (INT-31 ĐẾN INT-35)

#### INT-31: Chế Độ Sao Chép Nguyên Bản Bỏ Qua 3 Concepts (DESIGN_REUSE_EXACT)
- **Tình Huống**: Người dùng yêu cầu: *"Tôi muốn clone lại 100% giao diện của ứng dụng mẫu này, không cần sáng tạo thêm"*.
- **Domain Kích Hoạt**: `UX_UI_IMPROVEMENT` (Track: UI Implementation Refinement)
- **Xác Định Chế Độ Thiết Kế**: `DESIGN_REUSE_EXACT`
- **Hành Động Của Agent**:
  * **TUYỆT ĐỐI BỎ QUA VIỆC ĐỀ XUẤT 3 CONCEPTS CẤU TRÚC**.
  * Trích xuất trực tiếp bảng màu, kích thước từ ảnh chụp app gốc để lập ngay bản đặc tả khớp 1-1 cho Bước 07.
  * **Thực thi Sanitary Ergonomic Lint**:
    * Quét toàn bộ clickable elements trong giao diện gốc: Nếu phát hiện touch target < 48dp, tự động mở rộng padding đạt chuẩn tối thiểu 48x48dp (giữ nguyên kích thước visual của icon/button).
    * Kiểm tra độ tương phản màu chữ: Nếu < 4.5:1 (vi phạm WCAG AA), tự động điều chỉnh sắc độ (shade) cùng tone màu để đạt chuẩn 4.5:1.
    * Bổ sung đầy đủ 4 trạng thái giao diện (Loading, Empty, Success, Error) nếu app cũ còn thiếu, bảo toàn dữ liệu form theo `RULE-INIT-001`.
  * **Thực thi Legal Asset Decoupling Protocol**:
    * Bóc tách toàn bộ tài sản thương hiệu độc quyền (logo công ty, nhãn hiệu đã đăng ký, linh vật, font thương mại độc quyền).
    * Thay thế logo độc quyền bằng placeholder trung tính (`ic_brand_placeholder.xml`) và sử dụng font mã nguồn mở tương đương (Roboto, Inter, Plus Jakarta Sans).
- **Đầu Ra Kỳ Vọng**: Không làm phiền người dùng bằng các concept xa lạ; hoàn thành hồ sơ Art Direction trực diện, sạch rác công thái học và an toàn sở hữu trí tuệ.
- **Tiêu Chí Kiểm Thử**: Số lượng concept đề xuất = 0 (trực tiếp sang thiết kế 1-1); 100% clickable views đạt touch target >= 48x48dp; không chứa logo/font thương quyền chưa cấp phép.

#### INT-32: Chế Độ Áp Dụng Phong Cách Chỉ Định Cụ Thể (DESIGN_STYLE_SPECIFIED)
- **Tình Huống**: Người dùng yêu cầu: *"Hãy thiết kế lại app theo phong cách Material You tông màu tối (Dark Mode) với màu chủ đạo là xanh lục bảo"*.
- **Domain Kích Hoạt**: `UX_UI_IMPROVEMENT` (Track: Visual Redesign)
- **Xác Định Chế Độ Thiết Kế**: `DESIGN_STYLE_SPECIFIED`
- **Hành Động Của Agent**:
  * **TUYỆT ĐỐI BỎ QUA VIỆC ĐỀ XUẤT 3 CONCEPTS CẤU TRÚC**.
  * Khóa ngay bảng màu Emerald Green và Dark Theme trong `02_YEU_CAU_CUA_TOI/design.md`.
  * Phác thảo duy nhất một bố cục chuẩn Material You để người dùng duyệt.
- **Đầu Ra Kỳ Vọng**: Art Direction tuân thủ 100% phong cách Material You Dark Theme đã chọn.
- **Tiêu Chí Kiểm Thử**: Không ép người dùng chọn giữa 3 phương án cấu trúc.

#### INT-33: Chế Độ Khám Phá Cấu Trúc Khác Biệt (DESIGN_STRUCTURAL_EXPLORATION)
- **Tình Huống**: Người dùng yêu cầu: *"Giao diện cũ quá xấu và lộn xộn. Hãy tái thiết kế toàn bộ bố cục sao cho hiện đại, chống lối mòn AI vẽ card tràn lan"*.
- **Domain Kích Hoạt**: `UX_UI_IMPROVEMENT` (Track: Visual Redesign)
- **Xác Định Chế Độ Thiết Kế**: `DESIGN_STRUCTURAL_EXPLORATION`
- **Hành Động Của Agent**:
  * **BẮT BUỘC ĐỀ XUẤT 3 CONCEPTS KHÁC BIỆT HOÀN TOÀN VỀ CẤU TRÚC**:
    * **Concept A (Task-First Focus)**: Mở app ra là vùng nhập tác vụ tức thì; không có thẻ card trang trí.
    * **Concept B (Editorial Workspace)**: Trải nghiệm như trang tạp chí mở, phân cấp chữ mạnh mẽ, không gian thở thoáng.
    * **Concept C (Progressive Flow)**: Màn hình biến đổi linh hoạt thích ứng theo trạng thái hoàn thành của công việc.
  * Chờ người dùng duyệt qua lệnh: `APPROVE SCREEN COMPOSITION`.
- **Đầu Ra Kỳ Vọng**: Người dùng chọn được phương án cấu trúc ưng ý nhất trước khi viết đặc tả chi tiết.
- **Tiêu Chí Kiểm Thử**: Đủ 3 concept cấu trúc phân biệt rõ ràng; có lệnh duyệt Human Gate 1.

#### INT-34: Thực Thi Copy Deck Chống Placeholder Slop (Anti-Lorem Ipsum Compliance)
- **Tình Huống**: Tạo màn hình hồ sơ người dùng và lịch sử đơn hàng.
- **Domain Kích Hoạt**: `UX_UI_IMPROVEMENT`
- **Hành Động Của Agent**:
  * Kiểm tra tài liệu: Tuyệt đối không xuất hiện `Lorem ipsum`, `Sample title`, `Text placeholder`.
  * Soạn thảo nội dung tiếng Việt chuẩn mực: *"Nguyễn Văn An", "Đơn hàng #2026-8921 đã giao thành công", "Cập nhật mật khẩu lần cuối 15 ngày trước"*.
  * Xuất bản `03_KET_QUA_KIEM_TRA/04_COPY_DECK.md`.
- **Đầu Ra Kỳ Vọng**: Copy Deck chứa 100% văn bản thực tế, có quy định giới hạn ký tự cho từng nhãn.
- **Tiêu Chí Kiểm Thử**: `Select-String "Lorem ipsum"` trả về 0 kết quả trên toàn bộ thư mục đặc tả.

#### INT-35: Chuẩn Công Thái Học & Bao Phủ 4 Trạng Thái Giao Diện (Ergonomics & 4 UI States)
- **Tình Huống**: Nghiệm thu tài liệu đặc tả trước khi vượt Cổng Gate 03.
- **Domain Kích Hoạt**: `UX_UI_IMPROVEMENT` / `STAGE_03_GATE`
- **Hành Động Của Agent**:
  * Kiểm tra file `03_STATE_COMPOSITION.md`: Phải có đủ Loading (Skeleton), Empty (CTA), Success (Toast < 100ms), Error (Nút thử lại, giữ form).
  * Kiểm tra file `design.md`: Mọi vùng chạm (button, icon click) đạt chuẩn tối thiểu 48x48dp.
  * Trình bày bản tổng hợp `dac-ta-yeu-cau-da-chot.md` và chờ người dùng ra lệnh: `APPROVE UI SPEC`.
- **Đầu Ra Kỳ Vọng**: Bộ đặc tả đóng băng toàn diện, sẵn sàng bàn giao cho `rea-plan` ở Bước 08.
- **Tiêu Chí Kiểm Thử**: 100% tiêu chí của ma trận Gate 03 Readiness Matrix đạt chuẩn PASS.

---

### NHÓM 8: TÌNH HUỐNG BIÊN NÂNG CAO (ADVANCED EDGE CASES) (INT-36 ĐẾN INT-40)

#### INT-36: Đổi Ý Giữa Chừng Về Chế Độ Thiết Kế & Phạm Vi (Mid-stream Design Mode & Constraint Reversal)
- **Tình Huống**: Giữa Bước 06 và Bước 07, sau khi đã thống nhất chế độ `DESIGN_REUSE_EXACT`, người dùng bất ngờ đổi ý: *"Sau khi xem lại, tôi muốn đổi sang Dark Mode và chuyển các nút bấm lên đầu theo phong cách Material You"*.
- **Domain Kích Hoạt**: `UX_UI_IMPROVEMENT` / `INTERVIEW_CONTROL`
- **Hành Động Của Agent**:
  * Kích hoạt Assumption & Decision Invalidation Protocol (Mục 4.4):
    * Đánh dấu các bản ghi `DECISION` và `ASSUMPTION` liên quan trước đó sang trạng thái `INVALIDATED`, ghi nhận `invalidated_at` và `revocation_reason: "User requested switch to Material You Dark Mode"`.
    * Quét danh sách `downstream_dependencies: []` để hủy bỏ bản nháp `01_SCREEN_COMPOSITION.md` và `design.md` cũ.
  * Điều hướng lại Design Mode sang `DESIGN_STYLE_SPECIFIED` (Material You Dark Theme).
  * Tái tạo hồ sơ đặc tả tương ứng và lập bảng đối chiếu (Diff Summary) để người dùng duyệt lại mà không gây xung đột rác trong repo.
- **Đầu Ra Kỳ Vọng**: Sổ cái hồ sơ phản ánh chính xác lịch sử thu hồi quyết định; bộ đặc tả mới khớp 100% yêu cầu điều chỉnh.
- **Tiêu Chí Kiểm Thử**: Không tồn tại tài liệu mâu thuẫn; các quyết định cũ có trạng thái `INVALIDATED` hoặc `SUPERSEDED`.

#### INT-37: Xung Đột Bất Biến Nền Tảng & Yêu Cầu Bất Khả Thi (Platform Invariant & Policy Conflict Triage)
- **Tình Huống**: Người dùng đưa ra hai yêu cầu xung đột nội tại hoặc bất khả thi về mặt nền tảng Android 14/15: *"Ứng dụng phải cực kỳ tiết kiệm pin, nhưng phải lấy tọa độ GPS chính xác 1 mét liên tục mỗi giây khi tắt màn hình"* (hoặc *"Bảo mật chống dịch ngược tuyệt đối nhưng cấm bật ProGuard/R8"*).
- **Domain Kích Hoạt**: `APP_OPTIMIZATION` / `SECURITY_HARDENING`
- **Hành Động Của Agent**:
  * Nhận diện bất biến hệ điều hành (Platform Invariants): Android 14/15 cấm chạy ngầm polling GPS tần suất cao ở Doze Mode và hạn chế nghiêm ngặt Foreground Service Location.
  * Tuyệt đối không chấp nhận mù quáng cam kết bất khả thi.
  * Đặt câu hỏi đàm phán kỹ thuật (Technical Trade-off Negotiation): Nêu rõ giới hạn của OS và đề xuất giải pháp khả thi (ví dụ: dùng `FusedLocationProviderClient` với khoảng cách dịch chuyển tối thiểu 10m và Foreground Service có thông báo thường trực).
  * Ghi `DECISION-OPT-CONF-01`: Thống nhất giải pháp cân bằng giữa độ chính xác vị trí và mức tiêu thụ pin.
- **Đầu Ra Kỳ Vọng**: Thống nhất giải pháp khả thi tuân thủ 100% quy chuẩn quản lý pin của Android 14/15.
- **Tiêu Chí Kiểm Thử**: Ứng dụng không bị hệ điều hành cảnh báo Bad Behavior hoặc văng crash do vi phạm Foreground Service limits.

#### INT-38: Phân Vùng Miền Lai: Sao Chép 1-1 Kèm Màn Hình Tính Năng Mới (Hybrid Domain Partitioning: Clone 1-1 with New Feature Screen)
- **Tình Huống**: Dự án yêu cầu tái lập ứng dụng cũ nhưng bổ sung màn hình mới hoàn toàn (ví dụ: Màn hình danh sách đơn hàng clone 1-1 từ APK cũ, nhưng màn hình "Ví Voucher Khuyến Mãi" là tính năng mới chưa từng có).
- **Domain Kích Hoạt**: `HYBRID` (`UX_UI_IMPROVEMENT` + `FEATURE_ADDITION`)
- **Hành Động Của Agent**:
  * Thực hiện phân rã theo màn hình (Per-Screen Domain Partitioning):
    * Đối với màn hình cũ: Áp dụng `DESIGN_REUSE_EXACT` kèm Sanitary Ergonomic Lint (48dp touch target) và Legal Asset Decoupling.
    * Đối với màn hình mới: Kế thừa 100% hệ thống Design Tokens vừa trích xuất từ màn hình cũ để đảm bảo tính nhất quán thị giác (Design Consistency), đồng thời áp dụng phương pháp luận 3 tầng của `FEATURE_ADDITION` (Outcome ➔ Behavior ➔ Implementation Spec).
  * Hợp nhất vào cùng một hợp đồng `dac-ta-yeu-cau-da-chot.md`.
- **Đầu Ra Kỳ Vọng**: Bộ đặc tả thống nhất toàn vẹn, màn hình mới có cùng phong cách thẩm mỹ với màn hình tái lập nhưng có đầy đủ đặc tả nghiệp vụ mới.
- **Tiêu Chí Kiểm Thử**: Màn hình mới sử dụng chung Theme Tokens của màn cũ; bao phủ đủ 4 UI states.

#### INT-39: Đàm Phán Đánh Đổi Bảo Mật vs Hiệu Năng Khởi Động (Security vs Performance Trade-off Negotiation)
- **Tình Huống**: Gia cố an ninh cấp cao (kích hoạt mã hóa SQLCipher, xác thực Google Play Integrity API, khởi tạo Keystore Cipher) làm tăng thời gian Cold Start từ 800ms lên 2.2s (vượt trần quy chuẩn < 1.2s của Android Vitals).
- **Domain Kích Hoạt**: `SECURITY_HARDENING` + `APP_OPTIMIZATION`
- **Hành Động Của Agent**:
  * Nhận diện xung đột KPI: Yêu cầu bảo mật cao đối đầu trực diện với trải nghiệm mượt mà khi mở app.
  * Tự động đề xuất kiến trúc dung hòa kỹ thuật:
    * Khởi tạo SQLCipher bất đồng bộ ở background thread thông qua `Dispatchers.IO`.
    * Pre-warm Keystore Cipher ở luồng nền song song với giai đoạn render Splash Screen.
    * Thực hiện Play Integrity attestation theo cơ chế deferred check (xác thực song song sau khi First Frame đã vẽ xong; chỉ chặn lại khi người dùng truy cập giao dịch nhạy cảm đầu tiên).
  * Ghi `DECISION-SEC-PERF-01`: Cấu trúc khởi tạo luồng song song để vừa bảo mật vừa đạt Cold Start < 1.2s.
- **Đầu Ra Kỳ Vọng**: Giữ vững cam kết Cold Start < 1.2s trong khi toàn bộ dữ liệu vẫn được mã hóa SQLCipher và xác thực Play Integrity.
- **Tiêu Chí Kiểm Thử**: Profiler xác nhận Cold Start < 1.2s; dữ liệu database được mã hóa hoàn toàn.

#### INT-40: Tách Rời Tài Sản Thương Hiệu & Làm Sạch Bản Quyền Trong Chế Độ Sao Chép (Asset Decoupling & Brand Sanitization in Exact Clone Mode)
- **Tình Huống**: Người dùng yêu cầu `DESIGN_REUSE_EXACT` trên APK trích xuất từ một ngân hàng hoặc thương hiệu lớn chứa logo, hình ảnh linh vật có bản quyền và font chữ thương mại độc quyền.
- **Domain Kích Hoạt**: `UX_UI_IMPROVEMENT` / `CLEAN_ROOM_RE`
- **Hành Động Của Agent**:
  * Kích hoạt rào chắn Legal Asset Decoupling Protocol:
    * Đưa ra cảnh báo pháp lý về quyền sở hữu trí tuệ và thương hiệu đã đăng ký.
    * Tự động cô lập các tài sản thương hiệu; tuyệt đối không sao chép nguyên xi logo của bên thứ ba vào thư mục `res/drawable/`.
    * Tự động thay thế logo độc quyền bằng placeholder trung tính (`ic_brand_placeholder.xml`) hoặc yêu cầu người dùng đưa asset được cấp quyền vào.
    * Thay thế font chữ thương mại độc quyền bằng font mã nguồn mở tương đương có cùng metric thị giác (Roboto, Inter, Plus Jakarta Sans).
    * Ghi nhận `ASSUMPTION-UI-LEGAL-01`: Bóc tách tài sản nhãn hiệu độc quyền sang placeholder trung tính.
- **Đầu Ra Kỳ Vọng**: Bộ mã nguồn và đặc tả hoàn toàn sạch về mặt pháp lý (Clean-Room Compliant), không chứa nhãn hiệu vi phạm bản quyền.
- **Tiêu Chí Kiểm Thử**: Quét thư mục `res/` và code không phát hiện logo hoặc font độc quyền thương mại của bên thứ ba.

---

## 7. KẾT LUẬN & HƯỚNG DẪN BÀN GIAO TIẾP THEO

Khi quy trình phỏng vấn thích ứng hoàn tất:
1. Trạng thái vụ việc trong `.agents/state/active_case.json` chuyển thành:
   ```json
   {
     "current_phase": "STAGE_03_PRODUCT_DEFINITION",
     "current_step": "07_SPEC_AND_DESIGN",
     "current_gate_status": "GATE_03_SPEC_FROZEN"
   }
   ```
2. Agent chuyển giao hồ sơ đặc tả hoàn chỉnh cho kỹ năng **`rea-plan`** tại Bước 08 để tiến hành phân rã 6 Milestones và lập kế hoạch nguyên tử trong `03_KET_QUA_KIEM_TRA/KE_HOACH_TRIEN_KHAI.md`.
