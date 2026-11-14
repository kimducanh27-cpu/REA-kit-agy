---
name: rea-scan
description: Phụ trách độc quyền STAGE_01 (Bước 01 App Intake & Bước 02 Reference Baseline) và STAGE_02 phần điều tra (Bước 03 REA Scan & Bước 04 REA Investigate). Tự động sao lưu nguyên vẹn vào 04_SAO_LUU_AN_TOAN, cài đặt & đo kiểm baseline qua Android CLI ('android run', 'android layout --full', 'android screen capture -o') hoặc REA ADB ('capture_adb_screen' với 'output_directory'), fallback tĩnh 3 lớp (JADX + Apktool + Artifact Inventory), áp dụng quy trình duyệt lát cắt APK (AndroidManifest -> Application/Launcher -> NavGraph -> inspect_android_method), ma trận Framework-Aware Fallback Matrix (Flutter, React Native, Unity/IL2CPP, ProGuard/R8), che mờ [REDACTED], tạo 03_KET_QUA_KIEM_TRA/APP_FLOW_SPEC.md và xuất báo cáo hiện trạng vào 03_KET_QUA_KIEM_TRA/bao-cao-hien-trang.md.
---

# KỸ NĂNG: KHÁM PHÁ, ĐO BASELINE & ĐIỀU TRA DỊCH NGƯỢC (REA-SCAN)

Kỹ năng chuyên biệt cho **STAGE_01 (Bước 01 & 02)** và **STAGE_02 (Bước 03 & 04)** theo `docs/WORKFLOW_LIFECYCLE.md`.
*(Lưu ý ranh giới: Bước 05 Kiểm toán độc lập & mở Cổng 02 do kỹ năng `rea-audit` đảm nhiệm riêng biệt).*

---

## 1. GIAI ĐOẠN 1: STAGE_01 · DISCOVERY (Bước 01 & 02)

### Bước 01: App Intake / Preflight
1. Quét thư mục `01_THA_APP_VAO_DAY/`. Nếu có nhiều hơn 1 file ứng dụng, liệt kê bảng kiểm kê và hỏi người dùng chọn mục tiêu.
2. **Sao lưu bất khả xâm phạm**: Sao chép nguyên vẹn 100% file gốc sang `04_SAO_LUU_AN_TOAN/` và kiểm tra khớp mã băm SHA-256.
3. Cập nhật `.agents/state/active_case.json`:
   - Gán `case_id` (ví dụ `"CASE-001"`), `target_name`, `target_class` (`"ANDROID_APK"`, `"WEB_SPA"`, `"ELECTRON_DESKTOP"`, `"NATIVE_BINARY"`, hoặc `"SOURCE_REPO"`).
   - Đặt `backup_verified = true`, `artifacts.backup_file = "04_SAO_LUU_AN_TOAN/<tên_file>"`.
   - Đặt `current_phase = "STAGE_01_DISCOVERY"`, `current_step = "01_APP_INTAKE"`.

### Bước 02: Reference Baseline (Đo kiểm Ứng dụng Gốc)
1. **Quy trình Runtime với Android APK (Khi có AVD / Thiết bị qua Antigravity Device Hub)**:
   - **Cài đặt & Khởi chạy**: Dùng lệnh Android CLI `android run <đường_dẫn_apk>` (tự động cài đặt APK và mở Main Activity) hoặc chạy `adb install -r <đường_dẫn_apk>` trước khi gọi REA MCP `start_adb_app` (tham số JSON bắt buộc: `serial`, `package`).
     * *Cảnh báo Known Bug (morluto/rea Issue #2225 & #6528)*: Không gọi `start_adb_app` khi APK chưa được cài lên thiết bị; kiểm tra kỹ trường output vì `am start -W` báo `Status: timeout` có thể bị đánh dấu nhầm là `observed`.
   - **Chụp ảnh màn hình Baseline**: Dùng `android screen capture -o 03_KET_QUA_KIEM_TRA/baseline/screen_01.png` hoặc REA MCP `capture_adb_screen` (tham số JSON bắt buộc: `serial` và `output_directory` — lưu ý dùng đúng `output_directory` dạng snake_case với đường dẫn tuyệt đối tới thư mục chưa có file trùng tên theo *morluto/rea Issue #7550 & #7437*).
   - **Trích xuất cây phân cấp UI**: Chạy `android layout --full` để lưu JSON hierarchy vào `03_KET_QUA_KIEM_TRA/baseline/layout_01.json`.
     * *Lưu ý giới hạn (Issue #5033)*: Với màn hình viết bằng Jetpack Compose, `uiautomator` / `android layout` chỉ trả về các node có khai báo semantics.
2. **Phân loại Baseline: Runtime vs Static Fallback (P2-13)**:
   - **Nhánh A — Runtime Baseline (`BASELINE_RUNTIME_VERIFIED`)**: Khi có AVD / thiết bị thật, chụp ảnh màn hình và trích xuất `android layout --full`. Lưu `baseline_type = "BASELINE_RUNTIME_VERIFIED"`.
   - **Nhánh B — Static Baseline (`BASELINE_STATIC_ONLY`)**: Khi không có AVD / thiết bị, đánh dấu runtime là `SKIPPED (Static Fallback)` và bóc tách tĩnh 3 lớp:
     * **Lớp 1 — Cấu trúc Package, Manifest & Classes (JADX)**: Gọi `inspect_android_package` với đường dẫn tuyệt đối của APK. *(Lưu ý: `inspect_android_package` chỉ trả về package identity, permissions, class inventory và raw `AndroidManifest.xml` text; KHÔNG trả về `res/layout/*.xml` hay `drawables`)*.
     * **Lớp 2 — Bảng chuỗi & Tài nguyên (Apktool)**: Gọi `decode_android_resources` (yêu cầu `apktool >= 2.9.2` chống CVE-2024-21633) để lấy `strings.xml` và resource tables.
     * **Lớp 3 — Danh mục File & Assets (`res/layout/*.xml`, `assets/`)**: Gọi `open_binary` + `inspect_artifact` / `extract_artifact` để lấy cây file vật lý trong gói APK.
     * *(Lưu ý quan trọng: Toàn bộ các nhận định phụ thuộc runtime lúc này phải đánh dấu là `UNKNOWN`, không dùng tài nguyên tĩnh làm baseline pixel cho Gate 05)*.
3. **Báo cáo Hoàn tất Bước 02 & Đề nghị Coordinator Mở CỔNG 01**:
   - Chạy lệnh: `powershell -NoProfile -ExecutionPolicy Bypass -File .\.agents\scripts\gate.ps1 open 1 -Evidence 03_KET_QUA_KIEM_TRA/baseline/layout_01.json` (hoặc manifest tĩnh).
   - Đồng bộ bảng tiến độ trong `docs/PROGRESS.md`.

---

## 2. GIAI ĐOẠN 2: STAGE_02 · REVERSE ENGINEERING (Bước 03 & 04)

### Bước 03: REA Scan (Bóc Tách Cấu Trúc & Tài Nguyên)
1. Cập nhật `active_case.json`: `current_phase = "STAGE_02_REVERSE_ENGINEERING"`, `current_step = "03_REA_SCAN"`.
2. Định tuyến công cụ REA MCP theo loại mục tiêu:
   - **Android (`.apk`)**: Kết hợp `inspect_android_package`, `search_android_classes`, `inspect_apk_signature`, và `decode_android_resources`.
     * *Rào chắn Known Bugs trên Windows & APK lớn*:
       - Nếu gặp `provider_timeout` ở 120.000 ms trên APK multidex lớn (*Issue #3918*): Gọi `update_analysis_settings` nâng `jadx.operation_timeout_ms` lên `300000` rồi mới chạy lại.
       - Nếu gặp lỗi `Private DACL contains unexpected trustees (Win32 5)` trên Windows x64 (*Issue #5237*): Hướng dẫn đặt biến môi trường `TEMP`/`TMP` vào một thư mục riêng tư chỉ cấp quyền cho user hiện tại, đồng thời sử dụng `open_binary` + `inspect_artifact` để không làm gián đoạn phiên.
   - **Electron / JS (`.asar`, JS tree)**: `analyze_javascript_application` với `"detail": "summary"`, sau đó phân trang qua `inspect_analysis_view`.
   - **Nhị phân / File nén**: `open_binary` + `inspect_artifact` (`detail: "summary"`).
   - **Mã nguồn đầy đủ**: Dùng công cụ đọc file trực tiếp của Agent (bỏ qua REA theo chuẩn upstream).
3. **Khử trùng dữ liệu nhạy cảm**: Che mờ 100% API keys, tokens, passwords cứng thành `[REDACTED]`.

---

### QUY TRÌNH DUYỆT LÁT CẮT APK BẮT BUỘC (SLICE-BY-SLICE APK TRAVERSAL PROTOCOL)

Khi phân tích gói APK Android, Agent **BẮT BUỘC** tuân thủ tuần tự 4 lát cắt (slices) sau để đảm bảo không bỏ sót bất kỳ luồng ngầm nào:

```
+---------------------------------------------------------------------------------------------------+
| Lát cắt 1: AndroidManifest.xml (Package, Permissions, Components, Launcher & Deep Links)          |
+---------------------------------------------------------------------------------------------------+
                                                  │
                                                  ▼
+---------------------------------------------------------------------------------------------------+
| Lát cắt 2: Application Subclass & Launcher Activity (DI Graph, SDK Init, Entry Routing)           |
+---------------------------------------------------------------------------------------------------+
                                                  │
                                                  ▼
+---------------------------------------------------------------------------------------------------+
| Lát cắt 3: Navigation Graph & Route Map (NavGraph XML, Compose NavHost, Intent Routers)           |
+---------------------------------------------------------------------------------------------------+
                                                  │
                                                  ▼
+---------------------------------------------------------------------------------------------------+
| Lát cắt 4: inspect_android_method (Khoan sâu từng hàm nghiệp vụ, DAO, API Repo, Storage)          |
+---------------------------------------------------------------------------------------------------+
```

#### Lát cắt 1: Khảo sát AndroidManifest.xml
- Đọc thông tin căn bản: `package`, `versionCode`, `versionName`, `minSdkVersion`, `targetSdkVersion`.
- Xác định lớp `Application` tùy biến (thẻ `<application android:name="...">`).
- Xác định **Launcher Activity**: tìm thẻ `<activity>` chứa `<intent-filter>` có:
  * `<action android:name="android.intent.action.MAIN" />`
  * `<category android:name="android.intent.category.LAUNCHER" />`
- Trích xuất toàn bộ danh mục Components: Activities, Services, Broadcast Receivers, Content Providers.
- Bóc tách Intent Filters phục vụ Deep Link: tìm các scheme (`myapp://`), host, pathPrefix và gán neo `[EV: AndroidManifest.xml#L...]`.

#### Lát cắt 2: Application Subclass & Launcher Activity
- **Lớp Application**:
  * Kiểm tra `onCreate()`: tìm các framework khởi tạo như Dagger/Hilt, Koin, Firebase, Retrofit/OkHttp, Room Database, Timber, SDK quảng cáo hoặc Crashlytics.
  * Ghi nhận các Service Locator hoặc Singleton được lưu trữ toàn cục.
- **Launcher Activity**:
  * Kiểm tra chu trình `onCreate()`, `onStart()`, `onResume()`.
  * Xác định logic phân nhánh khởi động: kiểm tra token phiên làm việc, trạng thái onboard, quyền hạn runtime (Runtime Permissions).
  * Gắn mỏ neo bằng chứng: `[EV: <LauncherActivity>#onCreate]`.

#### Lát cắt 3: Navigation Graph & Tuyến Điều Hướng (NavGraph Traversal)
- **Jetpack Navigation XML**:
  * Quét thư mục `res/navigation/*.xml` tìm các thẻ `<navigation>`, `<fragment>`, `<activity>`, `<action>`, `<argument>`, `<deepLink>`.
  * Ánh xạ các transition ID và màn hình đích.
- **Jetpack Compose Navigation**:
  * Tìm các hàm Composable gọi `NavHost(navController = ..., startDestination = ...)`.
  * Bóc tách các chuỗi route: `composable("home")`, `composable("detail/{id}")`.
- **Điều hướng Fragment truyền thống**:
  * Tìm các lệnh gọi `supportFragmentManager.beginTransaction().replace(...)` hoặc `addToBackStack(...)`.
- **Router / Intent Dispatcher tùy biến**:
  * Truy vết các Activity hoặc Router trung gian chuyên điều hướng Deep Link (ví dụ: `DeepLinkActivity`, `RouterActivity`).

#### Lát cắt 4: Khoan Sâu Cấp Phương Thức (inspect_android_method)
- Sử dụng `inspect_android_method` để phân tích chi tiết thân hàm của các điểm chốt nghiệp vụ:
  * Hàm xử lý nút bấm đăng nhập / xác thực (Auth Handlers).
  * Hàm truy vấn dữ liệu cục bộ: Room DAO (`@Query`, `@Insert`), SharedPreferences (`edit().putString()`).
  * Hàm gọi API mạng: Retrofit interfaces, OkHttp `enqueue()`, `execute()`.
  * Hàm xử lý mã hóa: `KeyStore`, `Cipher`, `MasterKeys`.
- Ghi nhận chính xác mỏ neo bằng chứng cú pháp: `[EV: <FullClassName>#<methodName>]`.

---

### MA TRẬN NHẬN DIỆN & PHƯƠNG ÁN DỰ PHÒNG THEO FRAMEWORK (FRAMEWORK-AWARE FALLBACK MATRIX)

Trước khi thực hiện phân tích sâu, Agent phải quét nhanh cấu trúc thư viện `.so`, `assets/`, và mã bytecode để xác định nền tảng phát triển ứng dụng và kích hoạt chiến lược dự phòng phù hợp:

| Framework / Dạng Mã | Dấu Hiệu Nhận Biết Cốt Lõi (Signature) | Giới Hạn Của JADX / Dịch Ngược Chuẩn | Chiến Lược Bóc Tách & Phương Án Dự Phòng (Fallback Protocol) |
| :--- | :--- | :--- | :--- |
| **Flutter** | • `libflutter.so`, `libapp.so`<br>• Thư mục `assets/flutter_assets/`<br>• `io.flutter.app.FlutterApplication` | JADX chỉ thấy vỏ bọc C++ và `FlutterActivity` rỗng. Toàn bộ mã Dart bị biên dịch AOT thành mã máy nhị phân trong `libapp.so`. | 1. Dùng `extract_artifact` trích xuất `assets/flutter_assets/` (phân tích `FontManifest.json`, `AssetManifest.json` để lấy danh mục màn hình, icon, ảnh).<br>2. Dùng lệnh `strings` hoặc `readelf -s` trên `libapp.so` trích xuất chuỗi URL, API endpoint, routing names.<br>3. Kiểm tra `res/xml/network_security_config.xml` để lấy domain backend.<br>4. Kích hoạt kỹ năng `design-extract` trích xuất bảng màu trực quan từ ảnh chụp baseline `03_KET_QUA_KIEM_TRA/baseline/`. |
| **React Native** | • `assets/index.android.bundle`<br>• `libhermes.so` hoặc `libjsc.so`<br>• `com.facebook.react.ReactActivity` | Mã logic không nằm trong Dalvik `.dex` mà nằm trong JavaScript bundle hoặc bytecode của Hermes. | 1. Dùng `extract_artifact` trích xuất `assets/index.android.bundle`.<br>2. Nếu là Plain JS Bundle: Đọc và tìm kiếm từ khóa `createStackNavigator`, `NavigationContainer`, action types của Redux, endpoint `fetch`/`axios`.<br>3. Nếu là Hermes Bytecode (`libhermes.so`): Dùng công cụ dịch ngược Hermes (`hbctool`/`hermes-dec`) hoặc bóc tách chuỗi literals từ bundle.<br>4. Quét các lớp Java kế thừa `ReactPackage` hoặc `@ReactMethod` để xác định các native bridge functions. |
| **Unity / IL2CPP** | • `libil2cpp.so`<br>• `assets/bin/Data/Managed/Metadata/global-metadata.dat`<br>• `com.unity3d.player.UnityPlayerActivity` | Mã C# đã chuyển thành C++ và biên dịch nhị phân. JADX hoàn toàn không thấy logic trò chơi / UI. | 1. Kiểm tra sự tồn tại của `global-metadata.dat` và `libil2cpp.so`.<br>2. Bóc tách Metadata chuỗi qua công cụ Il2CppDumper hoặc phân tích string literals.<br>3. Trích xuất tài nguyên đồ họa (UI textures, sprites, audio clips) trực tiếp từ thư mục `assets/bin/Data/`.<br>4. Dựa vào ảnh baseline và nhật ký tương tác người dùng để tái dựng kịch bản UI. |
| **Mã Bị Obfuscated (ProGuard / R8)** | • Tên class/method bị đổi thành ký tự vô nghĩa: `a.b.c`, `f123a`<br>• Bảng biến cục bộ bị xóa<br>• Các lớp nhỏ bị gộp (Class inlining) | Mất hoàn toàn tên hàm/biến có nghĩa, khó đọc luồng logic theo cách thông thường. | 1. **Neo vào Manifest**: Các thành phần khai báo trong `AndroidManifest.xml` thường không bị đổi tên (do keep rules).<br>2. **Neo vào Hằng Số Chuỗi**: Tìm kiếm chuỗi literal (URL API, key SharedPreferences, câu SQL, mã thông báo lỗi).<br>3. **Neo vào Android SDK Calls**: Tìm lời gọi API hệ thống (`getSharedPreferences`, `openOrCreateDatabase`, `findViewById`, `setOnClickListener`, `NotificationManager`).<br>4. **Neo vào Resource IDs**: Đối chiếu mã hex resource trong `res/values/public.xml` với các trường `R.id.*` trong mã dex.<br>5. Bắt buộc ghi nhận mỏ neo kèm giá trị neo: `[EV: a.b.c#d (Anchor: "api/v1/auth")]`. |

---

### Bước 04: REA Investigate (Điều Tra Luồng Nghiệp Vụ & Tạo APP_FLOW_SPEC.md)
1. Cập nhật `active_case.json`: `current_step = "04_REA_INVESTIGATE"`.
2. Áp dụng tuần tự **Quy Trình Duyệt Lát Cắt APK** và **Ma Trận Dự Phòng Framework** ở trên.
3. Phân tích chi tiết:
   - Toàn bộ luồng điều hướng màn hình.
   - Các bảng cơ sở dữ liệu cục bộ (`SQLite`, `Room`, `SharedPreferences`, `DataStore`).
   - Danh sách endpoints kết nối máy chủ và chuỗi tuần tự mạng.
   - Các dịch vụ chạy ngầm (`WorkManager`, `Services`, `Receivers`, `Deep Links`).
4. **BẮT BUỘC TẠO TỆP ĐẶC TẢ LUỒNG ỨNG DỤNG**:
   - Sử dụng khuôn mẫu `templates/15-APP-FLOW-SPEC-TEMPLATE.md`.
   - Xuất ra tệp:
     👉 `03_KET_QUA_KIEM_TRA/APP_FLOW_SPEC.md`.
   - **Yêu cầu bất khả xâm phạm**:
     * Phải có sơ đồ Mermaid điều hướng đầy đủ (`Launch -> Auth -> Main -> Exit`).
     * Phải có danh mục `Screen Inventory` với mỏ neo `[EV: <class_or_file>#<method_or_line>]`.
     * Phải có bảng `API & Network Sequence` và lược đồ `Local Storage Schema`.
     * Phải có `Background & Intent Map`.
     * Phải có 3-5 `Golden Input/Output Scenarios` trích xuất từ baseline phục vụ kiểm thử hồi quy.
5. Xuất báo cáo hiện trạng theo `templates/01-REPORT-TEMPLATE.md` vào:
   👉 `03_KET_QUA_KIEM_TRA/bao-cao-hien-trang.md`.
6. Chuyển giao toàn bộ Evidence IDs, `APP_FLOW_SPEC.md` và danh sách điểm mù cho kỹ năng **`rea-audit`** để thực hiện Bước 05.
