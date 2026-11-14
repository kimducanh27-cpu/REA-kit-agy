---
description: Quy chuẩn chuyên biệt cho đối tượng Android APK: cô lập thư mục tạm JADX, tiêu chuẩn Apktool, thẩm quyền ADB, tích hợp Android CLI và cơ chế Static Fallback.
globs: "01_THA_APP_VAO_DAY/**/*.apk, 05_MA_NGUON_PHAT_TRIEN/android/**, **/*.apk, **/*.smali, **/*.gradle*, **/*.kt, **/*.java"
trigger: model_decision
---

# QUY TẮC PHÂN TÍCH & PHÁT TRIỂN MỤC TIÊU ANDROID APK (ANDROID TARGET RULES)

Tài liệu này xác lập các quy chuẩn kỹ thuật bắt buộc khi xử lý đối tượng ứng dụng Android APK trong `REA-kit-agy` (theo quyết định kiến trúc [ADR-0005](../docs/adrs/0005-android-apk-first-target-via-android-cli.md)).

---

## 1. Cô Lập Môi Trường Tạm & Quản Trị Bộ Nhớ JADX (JADX Isolation & Memory Governance)

1. **Khắc phục lỗi treo/xung đột JADX (morluto/rea Issue #5237)**:
   - Trên hệ điều hành Windows x64, trình dịch ngược JADX có thể gặp xung đột đường dẫn hoặc khóa file khi sử dụng thư mục tạm mặc định của hệ thống.
   - **Quy tắc bắt buộc**:
     * Mọi lệnh tiền xử lý hoặc script gọi JADX phải cô lập biến môi trường `TEMP` và `TMP` trỏ về `%LOCALAPPDATA%\Temp` (như đã thiết lập trong `KIEM_TRA.bat`).
     * Không bao giờ trỏ thư mục làm việc tạm của JADX vào các đường dẫn chứa khoảng trắng không được bao nháy hoặc thư mục chia sẻ mạng.
     * Tự động dọn dẹp các tệp tạm do JADX sinh ra sau khi kết thúc phiên quét để giải phóng dung lượng đĩa.

2. **Cấu hình RAM & Giới hạn luồng (JADX RAM Allocation & Thread Control)**:
   - `jadx.bat` trên Windows **không nhận trực tiếp cờ `-Xmx` từ dòng lệnh** (sẽ báo lỗi `Unknown option: -Xmx8g`).
   - Để tránh lỗi sập `java.lang.OutOfMemoryError: Java heap space` khi phân tích APK lớn (> 50 MB, nhiều `classes.dex`), Agent **BẮT BUỘC** cấu hình heap qua biến môi trường trước khi gọi JADX CLI:
     * Trong Windows CMD:
       ```cmd
       set JAVA_OPTS=-Xmx8g
       set _JAVA_OPTIONS=-Xmx8g
       ```
     * Trong PowerShell:
       ```powershell
       $env:JAVA_OPTS = "-Xmx8g"
       $env:REA_JADX_HEAP_MIB = "8192"
       ```
   - Khuyến nghị bổ sung cờ giới hạn luồng khi phân tích APK phức tạp để tránh bùng nổ AST:
     ```bash
     jadx -j 2 -d <out_dir> <app.apk>
     ```

---

## 2. Tiêu Chuẩn Bóc Tách Tài Nguyên Bằng Apktool (Apktool Resource Standards)

1. **Phiên bản & Tham số giải mã**:
   - Sử dụng Apktool phiên bản `>= 2.10.0` (khuyến nghị `2.11.0+` hỗ trợ trọn vẹn Android 15 API 35 và cấu trúc `resources.arsc` mới).
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
     * `output_directory`: Thư mục lưu ảnh (trỏ về `03_KET_QUA_KIEM_TRA/baseline/`; bảo đảm nguyên tắc `01_` chỉ đọc tuyệt đối).
   - Lệnh `start_adb_app` bắt buộc truyền đủ tham số:
     * `serial`: Mã định danh thiết bị/AVD.
     * `package`: Package name chính thức của ứng dụng (lấy từ `AndroidManifest.xml`).

3. **Tích hợp Android CLI Plugin**:
   - Tận dụng tối đa bộ lệnh chính thức của plugin Antigravity `Android CLI`:
     * `android layout`: Trích xuất cây phân cấp giao diện (UI Hierarchy) trực tiếp từ màn hình đang hiển thị để làm baseline đối chiếu 1-1.
     * `android screen capture -o <file_path>`: Chụp ảnh màn hình định dạng chuẩn PNG lưu vào `03_KET_QUA_KIEM_TRA/baseline/`.
     * Quản lý vòng đời máy ảo qua danh sách AVD và Antigravity Device Hub.

4. **Thẩm quyền Thiết Bị Thật & Giả Lập AVD (Physical Device & AVD Authorization)**:
   - Tuyệt đối **KHÔNG TỰ Ý** cài đặt gói APK, chạy lệnh shell, hoặc trích xuất dữ liệu trên thiết bị Android vật lý cá nhân HOẶC máy ảo giả lập AVD của người dùng nếu chưa có sự xác nhận chấp thuận rõ ràng bằng văn bản trong phiên chat (đồng bộ chặt chẽ với `core-safety.md`).

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

---

## 5. Chuẩn Căn Chỉnh Bộ Nhớ 16 KB Trên Android 15 (Android 15 16 KB Page-Alignment Standard)

Bắt đầu từ Android 15 (API 35), hệ điều hành hỗ trợ kiến trúc kích thước trang bộ nhớ **16 KB (16384 bytes)** bên cạnh chuẩn cũ 4 KB. Mọi thư viện native (`.so`) không căn chỉnh đạt chuẩn 16 KB sẽ gây crash `SIGSEGV` do lỗi linker hoặc bị từ chối cài đặt `INSTALL_FAILED_INVALID_APK`.

1. **Căn chỉnh ELF Segment trong thư viện Native (`.so`)**:
   - Thư viện native chia sẻ phải được biên dịch với cờ căn chỉnh `PT_LOAD` đạt `p_align = 0x4000` (yêu cầu Android NDK r27+ hoặc NDK r28).
   - Kiểm tra xác thực độ căn chỉnh bằng lệnh:
     ```bash
     readelf -l <lib.so> | grep LOAD
     # Xác nhận p_align phải bằng 0x4000 (16384 bytes)
     ```

2. **Căn chỉnh gói APK bằng `zipalign -P 16`**:
   - Khi đóng gói lại (Repack), vá (Patch Route C) hoặc rebuild APK, bắt buộc căn chỉnh các thư viện `.so` chưa nén theo bội số 16 KiB:
     ```bash
     zipalign -P 16 -f -v 4 input.apk output_aligned.apk
     zipalign -c -P 16 -v 4 output_aligned.apk
     ```
