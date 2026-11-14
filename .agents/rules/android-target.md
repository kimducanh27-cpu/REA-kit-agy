---
description: Quy chuẩn chuyên biệt cho đối tượng Android APK: cô lập thư mục tạm JADX, tiêu chuẩn Apktool, thẩm quyền ADB, tích hợp Android CLI và cơ chế Static Fallback.
globs: "01_THA_APP_VAO_DAY/**/*.apk, 05_MA_NGUON_PHAT_TRIEN/android/**, **/*.apk, **/*.smali, **/*.gradle*, **/*.kt, **/*.java"
trigger: model_decision
---

# QUY TẮC PHÂN TÍCH & PHÁT TRIỂN MỤC TIÊU ANDROID APK (ANDROID TARGET RULES)

Tài liệu này xác lập các quy chuẩn kỹ thuật bắt buộc khi xử lý đối tượng ứng dụng Android APK trong `REA-kit-agy` (theo quyết định kiến trúc [ADR-0005](../docs/adrs/0005-android-apk-first-target-via-android-cli.md)).

---

## 1. Cô Lập Môi Trường Tạm JADX Trên Windows (JADX Temp Isolation)

1. **Khắc phục lỗi treo/xung đột JADX (morluto/rea Issue #5237)**:
   - Trên hệ điều hành Windows x64, trình dịch ngược JADX có thể gặp xung đột đường dẫn hoặc khóa file khi sử dụng thư mục tạm mặc định của hệ thống.
   - **Quy tắc bắt buộc**:
     * Mọi lệnh tiền xử lý hoặc script gọi JADX phải cô lập biến môi trường `TEMP` và `TMP` trỏ về `%LOCALAPPDATA%\Temp` (như đã thiết lập trong `KIEM_TRA.bat`).
     * Không bao giờ trỏ thư mục làm việc tạm của JADX vào các đường dẫn chứa khoảng trắng không được bao nháy hoặc thư mục chia sẻ mạng.
     * Tự động dọn dẹp các tệp tạm do JADX sinh ra sau khi kết thúc phiên quét để giải phóng dung lượng đĩa.

---

## 2. Tiêu Chuẩn Bóc Tách Tài Nguyên Bằng Apktool (Apktool Resource Standards)

1. **Phiên bản & Tham số giải mã**:
   - Sử dụng Apktool phiên bản `>= 2.9.2` hoặc công cụ tương thích trong hệ sinh thái REA.
   - Ưu tiên giải mã định dạng tài nguyên XML rõ ràng (`res/values/strings.xml`, `res/layout/*.xml`, `AndroidManifest.xml`).

2. **Xử lý tài nguyên phức tạp & Bị Obfuscate**:
   - Nếu APK bị làm rối tài nguyên (Resource Obfuscation) dẫn đến Apktool báo lỗi biên dịch lại, Agent không được dừng quy trình:
     * Chuyển sang cờ `--no-res` hoặc giải mã có chọn lọc.
     * Sử dụng REA MCP `open_binary` và `extract_artifact` để trích xuất trực tiếp tài nguyên thô từ gói APK.
     * Ghi nhận rõ các tài nguyên không giải mã được vào sổ `03_KET_QUA_KIEM_TRA/UNKNOWNS_AND_COVERAGE.md`.

---

## 3. Thẩm Quyền ADB & Tích Hợp Android CLI (ADB Permissions & Device Hub)

1. **Phân biệt rạch ròi Phân tích tĩnh vs Thao tác ADB**:
   - Công cụ REA MCP `inspect_android_package`: **Là công cụ phân tích tĩnh cục bộ dựa trên JADX**, KHÔNG PHẢI lệnh ADB, không yêu cầu kết nối thiết bị hay quyền can thiệp phần cứng.
   - Các công cụ REA ADB (`capture_adb_screen`, `start_adb_app`): **Là thao tác động trên thiết bị**.

2. **Quy chuẩn tham số bắt buộc cho REA ADB**:
   - Lệnh `capture_adb_screen` bắt buộc truyền đủ tham số:
     * `serial`: Mã định danh thiết bị/AVD đang hoạt động.
     * `output_directory`: Thư mục lưu ảnh (trỏ về `01_THA_APP_VAO_DAY/baseline/` hoặc `03_KET_QUA_KIEM_TRA/`).
   - Lệnh `start_adb_app` bắt buộc truyền đủ tham số:
     * `serial`: Mã định danh thiết bị/AVD.
     * `package`: Package name chính thức của ứng dụng (lấy từ `AndroidManifest.xml`).

3. **Tích hợp Android CLI Plugin**:
   - Tận dụng tối đa bộ lệnh chính thức của plugin Antigravity `Android CLI`:
     * `android layout`: Trích xuất cây phân cấp giao diện (UI Hierarchy) trực tiếp từ màn hình đang hiển thị để làm baseline đối chiếu 1-1.
     * `android screen capture -o <file_path>`: Chụp ảnh màn hình định dạng chuẩn PNG.
     * Quản lý vòng đời máy ảo qua danh sách AVD và Antigravity Device Hub.

4. **Thẩm quyền thiết bị vật lý (Physical Device Protection)**:
   - Tuyệt đối **KHÔNG TỰ Ý** cài đặt gói APK, chạy lệnh shell, hoặc trích xuất dữ liệu trên thiết bị Android vật lý cá nhân của người dùng nếu chưa có sự xác nhận chấp thuận rõ ràng bằng văn bản trong phiên chat.

5. **Cơ chế Fallback Tĩnh 3 Lớp (3-Layer Static Fallback)**:
   - Khi môi trường máy trạm không có máy ảo AVD, không có kết nối thiết bị thật, hoặc ADB không khả dụng:
     * **CẤM**: Báo lỗi crash script hoặc ngắt phiên làm việc.
     * **BẮT BUỘC**: Kích hoạt Fallback tĩnh 3 lớp:
       1. Lớp 1: Trích xuất `AndroidManifest.xml`, permissions, activities qua `inspect_android_package`.
       2. Lớp 2: Giải mã `strings.xml` và layout XML tĩnh qua Apktool / REA tools.
       3. Lớp 3: Trích xuất assets, drawables, fonts thô để làm tư liệu thiết kế.
     * Đánh dấu Cổng 01 là `PASS_WITH_LIMITATIONS (Tĩnh)` và ghi nhận lý do vào `active_case.json`.

---

## 4. Quy Chuẩn Dự Án Android Native (Route B Implementation)

Khi đặc tả chốt lựa chọn Build Route B (Android Native Project):

1. **Cấu trúc mã nguồn chuẩn**:
   - Khởi tạo dự án chuẩn hóa bằng `android create` hoặc cấu trúc Android Gradle tiêu chuẩn trong `05_MA_NGUON_PHAT_TRIEN/android/`:
     * `app/src/main/java/` (hoặc `kotlin/`)
     * `app/src/main/res/layout/`, `values/strings.xml`, `values/colors.xml`
     * `build.gradle.kts` (hoặc `build.gradle`), `settings.gradle.kts`
     * `AndroidManifest.xml` đầy đủ thẻ đóng `<manifest>` và `<application>` hợp lệ.

2. **Quy chuẩn giao diện nền tảng (Platform-Native Standards)**:
   - Tuân thủ hướng dẫn Material Design 3.
   - Hỗ trợ xử lý viền màn hình (Edge-to-Edge WindowInsets) và cử chỉ vuốt lùi (Predictive Back).
   - Đảm bảo kích thước vùng bấm tối thiểu đạt `48x48 dp` cho khả năng tiếp cận (Accessibility).
