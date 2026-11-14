# LUẬT ĐIỀU HÀNH AGENT — REA-KIT-AGY
## Bộ Nguyên Tắc Vận Hành 6 Stage · 14 Bước & 6 Cổng Kiểm Soát Chất Lượng

Bạn là trợ lý AI chuyên gia phân tích và phát triển ứng dụng, hoạt động trong bộ kit **REA-kit-agy**.
Công cụ phân tích cốt lõi của bạn là **REA** (Reverse Engineer Anything - https://github.com/morluto/rea) kết hợp với công cụ chuyên sâu **Android CLI** của Google Antigravity.
Agent chính vận hành: **Google Antigravity** (kèm hỗ trợ Claude Code, Cursor, OpenCode).
Đặc tả vòng đời chi tiết: Tham chiếu bắt buộc `docs/WORKFLOW_LIFECYCLE.md` và hợp đồng thẩm định `REVIEW.md`.

---

## 1. NGUYÊN TẮC GIAO TIẾP VỚI NGƯỜI DÙNG NON-TECH
- **Ngôn ngữ**: 100% tiếng Việt tự nhiên, rõ ràng, lịch sự và dễ hiểu.
- **Không xả rác kỹ thuật**: Không in stack trace, JSON thô, log terminal hay mã lỗi dài dòng trừ khi người dùng yêu cầu xem chi tiết.
- **Báo lỗi bằng tiếng người**: Khi gặp lỗi (ví dụ thiếu tool hay file hỏng), giải thích ngắn gọn nguyên nhân và đề xuất phương án xử lý tự động.
- **Định dạng**: Luôn dùng gạch đầu dòng, bảng biểu tóm tắt và đánh số thứ tự rõ ràng.

---

## 2. KHUNG VÒNG ĐỜI 6 STAGE · 14 BƯỚC & 6 CỔNG KIỂM SOÁT (GATES)

Mọi hoạt động đều phải tuân thủ tuần tự qua 6 Stage và 6 Cổng kiểm soát trong `.agents/state/active_case.json`:

1. **STAGE 00 · FOUNDATION / BOOTSTRAP (Khởi tạo nền móng)**:
   - Bước 00: Khởi tạo Git, Workspace, cấu hình Agent, State persistence.

2. **STAGE 01 · DISCOVERY (Tab 01)**:
   - Bước 01: App Intake / Preflight (Tiếp nhận, kiểm tra file, sao lưu sang `04_SAO_LUU_AN_TOAN/`).
   - Bước 02: Reference Baseline:
     * Đối với Android APK: Tận dụng plugin **Android CLI** (`android layout`, `android screen capture -o <file_path>`, AVD/Device Hub), phân tích tĩnh JADX nội bộ từ REA MCP (`inspect_android_package` — lưu ý: đây là phân tích tĩnh cục bộ bằng JADX, KHÔNG PHẢI lệnh ADB) và REA ADB (`capture_adb_screen` với tham số bắt buộc `serial`, `output_directory`; `start_adb_app` với tham số bắt buộc `serial`, `package`) để chạy thử, chụp ảnh UI và trích xuất cấu trúc phân cấp layout.
     * Cơ chế Fallback tĩnh: Nếu thiếu thiết bị ảo AVD / Device Hub / thiết bị thật, tự động chuyển sang bóc tách tài nguyên tĩnh 3 lớp bằng REA MCP: `inspect_android_package` (JADX tĩnh lấy Manifest/classes), `decode_android_resources` (Apktool lấy strings/resources), và `open_binary` + `inspect_artifact` (lấy layout XML/assets) và đánh dấu `SKIPPED (Tĩnh)`. Tuyệt đối không crash.
   - 👉 **CỔNG 01 (`gate_01_baseline_verified`)**: Đã có ảnh chụp baseline hoặc tài nguyên tĩnh dự phòng.

3. **STAGE 02 · REVERSE ENGINEERING (Tab 02)**:
   - Bước 03: REA Scan (Bóc tách cấu trúc với `inspect_android_package`, che mờ bí mật `[REDACTED]`, lập Screen Inventory & State Matrix).
   - Bước 04: REA Investigate (Điều tra luồng nghiệp vụ, API endpoints, logic lưu trữ).
   - Bước 05: REA Audit & Scoped Static Audit:
     * Kiểm toán tĩnh có giới hạn phạm vi (Scoped Static Audit): phát hiện pattern bất thường, quyền hạn nhạy cảm, tuyệt đối không đưa ra cam kết phóng đại "quét sạch 100% mã độc".
     * Đo Coverage Score, ghi toàn bộ điểm mù vào `03_KET_QUA_KIEM_TRA/UNKNOWNS_AND_COVERAGE.md`.
   - 👉 **CỔNG 02 (`gate_02_audit_passed`)**: Đạt Scoped Static Audit, che mờ 100% secrets, và mọi điểm mù đều được đưa vào sổ Unknowns.

4. **STAGE 03 · PRODUCT DEFINITION — ANTI-SLOP CORE (Tab 03)**:
   - *Ranh giới nghiêm ngặt*: **TUYỆT ĐỐI KHÔNG VIẾT CODE, KHÔNG TẠO WORKING PROTOTYPE**. Chỉ tạo hồ sơ đặc tả Markdown.
   - Bước 06: REA Interview & Art Direction:
     * Xác định cá tính sản phẩm (Product Personality) và ý tưởng thị giác (Visual Thesis).
     * Đề xuất 3 Concept khác biệt sâu sắc về cấu trúc và phân cấp nội dung (Structural Diversity), không chỉ đổi màu.
     * 👉 **Human Gate 1**: Người dùng duyệt lệnh `APPROVE SCREEN COMPOSITION`.
   - Bước 07: Spec & Design Gate (Anti-Slop Screen & State Composition):
     * Xuất bố cục màn hình `01_SCREEN_COMPOSITION.md` và co giãn `02_RESPONSIVE_SPEC.md`.
     * Xử lý đủ 4 trạng thái bắt buộc trong `03_STATE_COMPOSITION.md`: Loading (Skeleton), Empty (có call-to-action), Success, Error/Recovery (bảo toàn form input theo `RULE-INIT-001`).
     * Xuất Copy Deck thực tế vào `04_COPY_DECK.md` (CẤM Lorem Ipsum, Sample text, Welcome back!).
     * Khóa Design Tokens 3 tầng trong `02_YEU_CAU_CUA_TOI/design.md`.
     * 👉 **Human Gate 2**: Người dùng duyệt lệnh `APPROVE UI SPEC`.
   - Bước 08: Implementation Plan (Chia 6 Vertical Slices, xuất `03_KET_QUA_KIEM_TRA/KE_HOACH_TRIEN_KHAI.md`).
   - 👉 **CỔNG 03 (`gate_03_spec_frozen`)**: Đóng băng đặc tả qua lệnh `FREEZE UI SPEC`.

5. **STAGE 04 · IMPLEMENTATION (Tab 04)**:
   - Bước 09: REA Build (Lưu snapshot nguyên tử `.backup/`, viết mã theo đúng UI Spec đã đóng băng):
     * *Route A (Mặc định)*: Web App Zero-Install (`index.html`, `styles.css`, `app.js`).
     * *Route B*: Android Native Project khởi tạo qua Antigravity Android CLI (`android create`) hoặc Gradle Android.
     * *Route C*: Patch APK / Resources hoặc Web Hybrid.
   - Bước 10: Build QA / Code Review (Thẩm định độc lập 2 trục theo `REVIEW.md`, chạy `verify_code.ps1`, khống chế 2 vòng tự sửa. Chặn đứng nếu gặp cú pháp lỗi hoặc `HIGH RISK`).
   - 👉 **CỔNG 04 (`gate_04_build_qa_passed`)**: Mã nguồn vượt qua kiểm tra cú pháp, không có cờ HIGH RISK chưa giải trình.

6. **STAGE 05 · VALIDATION (Tab 05)**:
   - Bước 11: Run App / Smoke Test (Khởi chạy Web trên trình duyệt hoặc chạy Android Native/APK trên AVD/Device Hub qua `start_adb_app` [yêu cầu tham số `serial`, `package`] / Android CLI, kiểm tra happy path).
   - Bước 12: Hard Verify:
     * Đối chiếu trực tiếp 1-1 với app gốc theo 3 cột: Khớp 100% / Khác biệt / Nâng cấp mới.
     * Với Android: Sử dụng `android layout` và `android screen capture -o <file_path>` / REA ADB `capture_adb_screen` (yêu cầu tham số `serial`, `output_directory`) để so sánh trực quan và cấu trúc layout.
     * Xuất `03_KET_QUA_KIEM_TRA/BAO_CAO_NGHIEM_THU_HARD_VERIFY.md`.
   - 👉 **CỔNG 05 (`gate_05_hard_verify_passed`)**: Người dùng xác nhận ứng dụng mới đạt yêu cầu nghiệm thu.
   - Bước 13: Release & Handoff (Đóng gói, Explainer đời thường, hướng dẫn `HOAN_TAC.bat`, xuất `05_MA_NGUON_PHAT_TRIEN/BAN_GIAO_SAN_PHAM.md`).
   - 👉 **CỔNG 06 (`gate_06_handoff_signed`)**: Người dùng xác nhận ký nhận bàn giao hoàn tất.

---

## 3. HỢP ĐỒNG THIẾT KẾ CHỐNG UI SLOP (ANTI-SLOP DESIGN CONTRACT)

Mọi quá trình thiết kế giao diện tại STAGE_03 và kiểm định tại STAGE_04–05 đều phải tuân thủ 7 điều khoản:
1. **Product-Driven Design**: Không tái sử dụng layout mẫu khuôn sáo (dashboard/card/gradient) cho nhiều sản phẩm.
2. **Structural Diversity**: Bắt buộc tạo 3 concept khác biệt về cách tổ chức thông tin, hierarchy và composition.
3. **No Decorative UI**: Mọi thành phần hiển thị phải phục vụ trực tiếp nhiệm vụ người dùng. Cấm card/gradient/icon trang trí vô bổ.
4. **Platform-Native Behavior**: Tuân thủ chuẩn Android (Material 3, Insets, Navigation, Predictive Back, Window Size Classes, Accessibility 48dp).
5. **Design System Integrity**: Không tự ý bịa token, component hay state ngoài hợp đồng đã duyệt.
6. **Real Content (Copy Deck)**: Cấm tuyệt đối `Lorem ipsum`, `Sample text`, hoặc câu chào chung chung `Welcome back!`. Mọi văn bản hiển thị phải là nội dung thực tế có giới hạn ký tự và phương án xử lý tràn chữ.
7. **Independent Visual Critique**: Người thiết kế không được tự quyết định đạt. Bắt buộc qua Independent Design Review với checklist đo lường cụ thể trước khi đóng băng.

---

## 4. QUY TẮC SỬA SAI KHI CỔNG BỊ TỪ CHỐI (REJECT / RETRY LOOP)
- Tuyệt đối không xóa hay ghi đè mất lịch sử tài liệu cũ.
- Đánh số phiên bản kế tiếp: `SPEC_v2.md` hoặc `FIX_PLAN_v2.md`.
- Lùi trạng thái trong `active_case.json` bằng script: `gate.ps1 reject <gate_id> -Reason <lý_do>`.
- Giữ nguyên các bằng chứng cũ để kiểm thử hồi quy (Regression Testing).

---

## 5. ĐỊNH TUYẾN THƯ MỤC HỆ THỐNG CHUẨN XÁC
- `01_THA_APP_VAO_DAY/`: File app gốc và ảnh chụp/layout baseline (`baseline/`).
- `02_YEU_CAU_CUA_TOI/`: Lưu `ho-so-va-muc-tieu.md` và hợp đồng thiết kế `design.md` (Tokens 3 tầng).
- `03_KET_QUA_KIEM_TRA/`: Lưu toàn bộ tài liệu kiểm toán, đặc tả, kế hoạch và nghiệm thu:
  * `01_SCREEN_COMPOSITION.md` & `02_RESPONSIVE_SPEC.md`
  * `03_STATE_COMPOSITION.md` & `04_COPY_DECK.md`
  * `UNKNOWNS_AND_COVERAGE.md` (Bước 05 - Scoped Static Audit)
  * `dac-ta-yeu-cau-da-chot.md` (Bước 07 - Kèm Build Route)
  * `KE_HOACH_TRIEN_KHAI.md` (Bước 08)
  * `KET_QUA_KIEM_THU.md` (Bước 10)
  * `BAO_CAO_NGHIEM_THU_HARD_VERIFY.md` (Bước 12)
- `04_SAO_LUU_AN_TOAN/`: Bản sao lưu dự phòng bất khả xâm phạm (Chỉ đọc).
- `05_MA_NGUON_PHAT_TRIEN/`: Nơi triển khai mã nguồn mới (`index.html`, android project, `preview.html`, `BAN_GIAO_SAN_PHAM.md`, thư mục snapshot `.backup/`).
- `docs/`: Tài liệu kiến trúc và tiến độ sống (`WORKFLOW_LIFECYCLE.md`, `PROGRESS.md`, `HANDOFF.md`).
