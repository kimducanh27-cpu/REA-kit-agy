# ĐẶC TẢ YÊU CẦU PHÁT TRIỂN ỨNG DỤNG (FROZEN PRODUCT & ENGINEERING SPECIFICATION)
> **Dự án**: [Tên dự án / Ứng dụng]  
> **Mã ca làm việc (Case ID)**: [CASE-ID từ active_case.json]  
> **Thời gian đóng băng**: YYYY-MM-DD HH:mm  
> **Trạng thái Cổng**: ĐÃ ĐÓNG BĂNG (FROZEN SPEC — CỔNG 03)  
> **Quy chuẩn**: REA Adaptive Interview Architecture & Anti-Slop Governance · v1.1  

---

## 1. Mục Tiêu Tổng Thể & Định Tuyến Triển Khai (Executive Goals & Strategy)

- **Mục tiêu sản phẩm cốt lõi (Core Product Goals)**:
  * [Mục tiêu 1: Giá trị nghiệp vụ mang lại cho người dùng]
  * [Mục tiêu 2: Vấn đề cụ thể cần giải quyết triệt để]
- **Nhóm người dùng mục tiêu (User Personas & Target Audience)**:
  * *Nhóm chính*: [Đối tượng người dùng thường xuyên, bối cảnh sử dụng]
  * *Nhóm phụ*: [Quản trị viên, kiểm toán viên, người dùng vãng lai]
- **Chiến lược phát triển mã nguồn (`development_strategy`)**:
  * `[ ] STRATEGY_1_EXTEND`: Mở rộng trực tiếp trên codebase hiện có
  * `[ ] STRATEGY_2_FEATURE_BRANCH`: Phát triển tính năng trên nhánh độc lập
  * `[ ] STRATEGY_3_COMPATIBLE_CLEANROOM`: Tái triển khai tương thích phòng sạch
  * `[ ] STRATEGY_4_FULL_REWRITE`: Viết lại toàn diện với kiến trúc mới
- **Nền tảng bàn giao (`delivery_platform`)**:
  * `[ ] ROUTE_A_WEB_ZERO_INSTALL`: Ứng dụng Web SPA không cần cài đặt
  * `[ ] ROUTE_B_ANDROID_NATIVE`: Dự án mã nguồn Android Native (Kotlin/Compose)
  * `[ ] ROUTE_C_PATCH_HYBRID`: Bản vá APK nhị phân kết hợp
- **Lý do lựa chọn định tuyến**: [Giải trình cơ sở kỹ thuật, thời gian và chi phí bảo trì]

---

## 2. Đặc Tả Yêu Cầu Chức Năng (Functional Requirements)

### 2.1 Danh Mục Tính Năng Cốt Lõi (Core Feature Inventory)
| Mã Tính Năng | Tên Tính Năng | Mô Tả Nghiệp Vụ | Nguồn Gốc | Mức Độ Ưu Tiên |
| :--- | :--- | :--- | :--- | :--- |
| `FEAT-01` | [Ví dụ: Đăng nhập & Xác thực] | Xác thực sinh trắc học hoặc mã PIN cục bộ | Giữ nguyên từ app gốc | `MUST_HAVE` |
| `FEAT-02` | [Ví dụ: Quản lý Danh mục] | Thêm, sửa, xóa, tìm kiếm danh mục dữ liệu | Tối ưu hóa luồng thao tác | `MUST_HAVE` |
| `FEAT-03` | [Ví dụ: Xuất Báo Cáo Excel] | Lọc giao dịch và xuất file `.xlsx` | Tính năng mới bổ sung | `SHOULD_HAVE` |

### 2.2 Quy Chuẩn Xử Lý Luồng Nghiệp Vụ & Quy Tắc Dữ Liệu (Business Rules)
- **Quy tắc 1**: [Ví dụ: Dữ liệu nhập vào form luôn được tự động lưu tạm (Auto-save) sau mỗi 500ms].
- **Quy tắc 2 (Bảo Toàn Form Lỗi - `RULE-INIT-001`)**: Khi người dùng nhấn gửi nhưng gặp lỗi mạng hoặc lỗi xác thực máy chủ, toàn bộ thông tin đã nhập trên form phải được bảo toàn 100%, tuyệt đối không xóa trắng dữ liệu của người dùng.
- **Quy tắc 3**: [Ví dụ: Giới hạn tìm kiếm tối đa 100 kết quả trên một trang, hỗ trợ phân trang vô tận].

---

## 3. Đặc Tả Phi Chức Năng & Ngân Sách Hiệu Năng (Non-Functional Requirements & Performance Budgets)

| Tiêu Chí Kỹ Thuật | Chỉ Số Mục Tiêu (Target Metric) | Ngưỡng Tối Đa (Hard Limit) | Phương Pháp Đo Kiểm |
| :--- | :--- | :--- | :--- |
| **Thời gian khởi động lạnh (Cold Start)** | < 1.0 giây (Mid-tier device) | <= 1.2 giây | Android Vitals / Traceview |
| **Thời gian khởi động ấm (Warm Start)** | < 400 mili-giây | <= 600 mili-giây | Android Vitals |
| **Tỷ lệ khung hình (Frame Rate / Jank)** | 60 FPS (99% khung hình mượt) | Jank Rate < 2.0% | Macrobenchmark / Profile GPU |
| **Mức tiêu thụ RAM đỉnh (Peak Memory)** | < 80 MB (Chế độ thường) | <= 150 MB (Xử lý nặng) | Android Studio Memory Profiler |
| **Mức tiêu thụ Pin (Battery Impact)** | < 1.5% pin / giờ sử dụng | Không giữ WakeLock ngầm | Battery Historian |
| **Dung lượng gói cài đặt (APK Size)** | < 15 MB (Universal APK) | <= 25 MB | APK Analyzer / R8 Minification |

---

## 4. Ma Trận Tương Thích & Môi Trường Nền Tảng (Platform & Compatibility Matrix)

- **Môi trường Android Mục Tiêu**:
  * `minSdkVersion`: 26 (Android 8.0 Oreo)
  * `targetSdkVersion`: 34 hoặc 35 (Android 14 / Android 15)
  * `compileSdkVersion`: 35
- **Chuẩn Căn Chỉnh Trang Bộ Nhớ 16 KB (Android 15 Compliance)**:
  * Toàn bộ thư viện native `.so` biên dịch với NDK r28 (`-Wl,-z,max-page-size=16384`).
  * Gói APK đóng gói với `zipalign -P 16 -f -v 4`.
- **Thích Ứng Màn Hình & Insets (Edge-to-Edge)**:
  * Hỗ trợ đầy đủ Window Size Classes (Compact, Medium, Expanded).
  * Xử lý padding Insets cho thanh trạng thái, thanh điều hướng và camera cutout.

---

## 5. Vòng Đời Dữ Liệu, An Ninh & Quyền Riêng Tư (Data Lifecycle, Security & Privacy)

- **Phân Loại Dữ Liệu**:
  * *Dữ liệu cá nhân (PII)*: Họ tên, email, số điện thoại -> Mã hóa lưu trữ cục bộ.
  * *Dữ liệu phiên*: Token truy cập -> Lưu trữ trong Android KeyStore / Encrypted DataStore.
- **Lưu Trữ An Toàn Tại Chỗ (Storage at Rest)**:
  * Tuyệt đối không dùng `EncryptedSharedPreferences` (đã deprecated).
  * Sử dụng **Jetpack DataStore** kết hợp Google Tink (`Aead`) hoặc trực tiếp Android KeyStore Cipher.
- **Bảo Vệ Kênh Truyền Thông (Transmission Security)**:
  * 100% kết nối mạng sử dụng giao thức TLS 1.3 (cưỡng chế qua OkHttp `ConnectionSpec.MODERN_TLS`).
  * Cấm hoàn toàn lưu lượng văn bản rõ (`cleartextTrafficPermitted="false"` trong `network_security_config.xml`).
- **Phát Hiện Can Thiệp Hệ Thống (Device Integrity)**:
  * Tích hợp Google Play Integrity API (Device + App Integrity verdict) với kiểm chứng token ở máy chủ theo chuẩn OWASP MASVS-RESILIENCE v2.0.
  * Không chỉ dựa vào thư viện RootBeer cục bộ.
- **Thu Hồi & Xóa Bỏ Dữ Liệu**:
  * Cung cấp nút "Xóa toàn bộ dữ liệu ứng dụng" thực thi xóa sạch database và giải phóng khóa KeyStore.

---

## 6. Hợp Đồng Giao Diện Chống UI Slop Đã Khóa (Frozen Anti-Slop UI/UX Contract)

Toàn bộ các tài liệu thiết kế sau đã được thẩm định độc lập và đóng băng đính kèm đặc tả này:
1. **Chế độ thiết kế áp dụng**: `[ ] DESIGN_REUSE_EXACT` | `[ ] DESIGN_STYLE_SPECIFIED` | `[ ] DESIGN_STRUCTURAL_EXPLORATION`
2. **Hồ sơ Art Direction**: Đã chốt theo `templates/12-ART-DIRECTION-TEMPLATE.md` (Product Personality, Visual Thesis, Layout Philosophy, Typography, Spacing, Signature Element, Forbidden Patterns).
3. **Bố cục màn hình đã duyệt**: `03_KET_QUA_KIEM_TRA/01_SCREEN_COMPOSITION.md` (Phê duyệt qua lệnh `APPROVE SCREEN COMPOSITION`).
4. **Quy chuẩn Responsive & Insets**: `03_KET_QUA_KIEM_TRA/02_RESPONSIVE_SPEC.md`.
5. **4 Trạng thái giao diện bắt buộc**: `03_KET_QUA_KIEM_TRA/03_STATE_COMPOSITION.md` (Loading Skeleton, Empty State CTA, Success Feedback, Error Recovery bảo toàn dữ liệu form).
6. **Hợp đồng Copy Deck thực tế**: `03_KET_QUA_KIEM_TRA/04_COPY_DECK.md` (CẤM 100% Lorem Ipsum và placeholder slop).
7. **Hợp đồng Design Tokens 3 tầng**: `02_YEU_CAU_CUA_TOI/design.md` (Primitive -> Semantic -> Platform Native).

---

## 7. Phân Hạng Ưu Tiên MoSCoW & Ranh Giới Phạm Vi (Prioritization & Scope Boundaries)

### 7.1 Ma Trận Phân Kỳ Tính Năng:
- **MUST-HAVE (Milestone 1-3 — Bắt buộc phải có trong bản giao đầu tiên)**:
  * [Tính năng bắt buộc 1]
  * [Tính năng bắt buộc 2]
- **SHOULD-HAVE (Milestone 4-5 — Rất nên có, có thể triển khai sau MVP)**:
  * [Tính năng quan trọng 1]
- **COULD-HAVE (Milestone 6 — Tiện ích bổ sung nếu còn ngân sách)**:
  * [Tiện ích mở rộng 1]
- **WON'T-HAVE / EXPLICIT NON-GOALS (Rõ ràng KHÔNG làm trong đợt này)**:
  * *Non-Goal 1*: [Ví dụ: Không hỗ trợ Android TV hoặc WearOS trong đợt này].
  * *Non-Goal 2*: [Ví dụ: Không xây dựng cổng thanh toán trực tiếp trong app, chỉ hiển thị QR].

### 7.2 Các Quyết Định Đánh Đổi Đã Thống Nhất (Trade-Off Agreements):
- **Đánh đổi 1**: [Ví dụ: Ưu tiên mã hóa toàn diện dữ liệu cục bộ thay vì rút ngắn thêm 100ms thời gian khởi động].
- **Đánh đổi 2**: [Ví dụ: Ưu tiên chuẩn hóa touch target >= 48dp thay vì giữ nguyên bố cục chữ siêu nhỏ của app cũ].

---

## 8. Danh Mục Giả Định & Quyết Định Trì Hoãn (Assumptions & Deferred Decisions)

### 8.1 Hồ Sơ Giả Định Đã Được Chấp Thuận (Approved Assumptions):
| Mã Giả Định | Hạng Mục & Nội Dung Giả Định | Cơ Sở / Rationale | Mức Độ Rủi Ro | Nhiệm Vụ Kiểm Chứng (Tại Bước 10 / 12) |
| :--- | :--- | :--- | :--- | :--- |
| `ASM-01` | [Ví dụ: Dung lượng bộ đệm ảnh tối đa 50 MB] | Khuyến nghị chuẩn của Coil/Glide | `BENIGN` | Kiểm thử stress-test bộ nhớ với 500 ảnh |
| `ASM-02` | [Ví dụ: Timeout kết nối mạng mặc định 15 giây] | Chuẩn kết nối di động 4G/5G | `BENIGN` | Kiểm thử ngắt kết nối giả lập |

### 8.2 Danh Mục Quyết Định Trì Hoãn Hợp Lệ (Deferred Decisions):
- `DEC-DEF-01`: [Ví dụ: Quyết định tích hợp Analytics chi tiết hoãn lại đến sau khi hoàn tất kiểm thử cốt lõi].

---

## 9. Tiêu Chí Nghiệm Thu Có Thể Kiểm Chứng (Verifiable Acceptance Criteria)

*Mọi tính năng phải có kịch bản Given / When / Then có thể kiểm chứng được:*

```gherkin
Kịch bản 1: [Tên kịch bản tính năng chính]
GIVEN [Trạng thái tiền đề của hệ thống / ứng dụng]
WHEN  [Người dùng thực hiện hành động cụ thể]
THEN  [Kết quả hiển thị chính xác trên giao diện]
AND   [Dữ liệu được cập nhật hoặc bảo toàn tương ứng]

Kịch bản 2: [Kịch bản xử lý lỗi / Ngoại lệ]
GIVEN [Trạng thái lỗi giả lập: Mất mạng / Nhập sai thông tin]
WHEN  [Người dùng kích hoạt hành động]
THEN  [Thông báo lỗi rõ ràng bằng tiếng Việt đời thường kèm nút thử lại]
AND   [Dữ liệu trên form không bị xóa mất theo RULE-INIT-001]
```

---

## 10. Chữ Ký Phê Duyệt & Đóng Băng Cổng 03 (Gate 03 Verification Sign-off)

- [ ] Đã vượt qua đánh giá tính đầy đủ thông tin: `powershell -File .agents/scripts/interview.ps1 evaluate-sufficiency` đạt **`SUFFICIENT`**.
- [ ] Đã được người dùng phê duyệt bằng lệnh: **`FREEZE UI SPEC`**.
- [ ] Đã mở Cổng 03 qua lệnh: `powershell -File .agents/scripts/gate.ps1 open 3 -Evidence 03_KET_QUA_KIEM_TRA/dac-ta-yeu-cau-da-chot.md -ApprovedBy "user"`.
- [ ] Sẵn sàng chuyển giao cho Kỹ năng `rea-plan` tại Bước 08 để lập kế hoạch 6 Milestones.
