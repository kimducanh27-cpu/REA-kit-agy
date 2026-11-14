# ĐẶC TẢ LUỒNG ỨNG DỤNG & CẤU TRÚC KỸ THUẬT NGUYÊN BẢN (APP FLOW SPECIFICATION)
> **Mã ca làm việc (Case ID)**: [CASE-ID từ active_case.json]  
> **Ứng dụng mục tiêu**: [Tên gói APK / Web SPA / Binary]  
> **Package / Bundle ID**: [ví dụ: com.example.app]  
> **Phiên bản bóc tách**: [vX.Y.Z (VersionCode: N)]  
> **Thời gian tạo lập**: [YYYY-MM-DD HH:mm:ss]  
> **Kiểm toán viên (Auditor)**: [rea-audit / rea-scan]  
> **Quy chuẩn neo bằng chứng (Evidence Anchor Standard)**: Bắt buộc gắn thẻ định danh `[EV: <class_or_file>#<method_or_line>]` cho từng thành phần màn hình, API, cơ sở dữ liệu và tác vụ nền. Cổng 02 sẽ tự động từ chối nếu thiếu các mỏ neo này.

---

## 1. SƠ ĐỒ ĐIỀU HƯỚNG LUỒNG ỨNG DỤNG TOÀN DIỆN (FULL APP NAVIGATION FLOW)

Sơ đồ Mermaid mô tả toàn bộ vòng đời điều hướng từ khi khởi động ứng dụng (`Cold Launch`), qua cổng xác thực (`Auth Gate`), điều hướng đa nhánh tại giao diện chính (`Main Navigation Shell`), các luồng nghiệp vụ chi tiết (`Sub-flows / Modal Flows`) đến khi kết thúc phiên làm việc (`Exit / Termination`):

```mermaid
flowchart TD
    Start([Khởi Động Ứng Dụng / Cold Launch\n[EV: AndroidManifest.xml#LauncherActivity]]) --> Splash[Màn Hình Splash / Khởi Tạo\n[EV: SplashActivity#onCreate]]
    Splash --> CheckAuth{Đã Đăng Nhập / Token Hợp Lệ?\n[EV: SessionManager#isTokenValid]}

    %% Nhánh chưa xác thực
    CheckAuth -- Chưa --> AuthFlow[Luồng Xác Thực / Onboarding\n[EV: AuthActivity#onCreate]]
    AuthFlow --> Login[Màn Hình Đăng Nhập\n[EV: LoginFragment#onViewCreated]]
    Login --> SubmitAuth[Gửi Thông Tin Xác Thực\n[EV: AuthViewModel#login]]
    SubmitAuth --> AuthResult{Xác Thực Thành Công?\n[EV: AuthRepository#handleResponse]}
    AuthResult -- Thất bại --> LoginError[Hiển Thị Lỗi & Giữ Form\n[EV: LoginFragment#showError]]
    LoginError --> Login
    AuthResult -- Thành công --> SaveSession[Lưu Phiên & Khóa Biometric\n[EV: TokenStore#saveAuthTokens]]
    SaveSession --> MainShell

    %% Nhánh đã xác thực
    CheckAuth -- Rồi --> MainShell[Giao Diện Vỏ Chính / Main Shell\n[EV: MainActivity#onCreate]]

    %% Điều hướng màn hình chính
    MainShell --> TabHome[Tab Trang Chủ / Dashboard\n[EV: HomeFragment#setupViews]]
    MainShell --> TabExplore[Tab Khám Phá / Danh Mục\n[EV: ExploreFragment#setupViews]]
    MainShell --> TabOrders[Tab Đơn Hàng / Lịch Sử\n[EV: OrdersFragment#setupViews]]
    MainShell --> TabProfile[Tab Hồ Sơ / Cài Đặt\n[EV: ProfileFragment#setupViews]]

    %% Các luồng thao tác nghiệp vụ con
    TabHome --> ActionCreate[Tạo Mới Giao Dịch\n[EV: HomeFragment#onActionCreate]]
    ActionCreate --> FormInput[Biểu Mẫu Nhập Liệu\n[EV: TransactionActivity#setupForm]]
    FormInput --> SubmitTx[Gửi Giao Dịch\n[EV: TransactionViewModel#submit]]
    SubmitTx --> TxSuccess[Màn Hình Xác Nhận Thành Công\n[EV: TransactionResultActivity#showSuccess]]
    TxSuccess --> TabHome

    TabOrders --> OrderDetail[Màn Hình Chi Tiết Đơn Hàng\n[EV: OrderDetailActivity#onCreate]]
    OrderDetail --> TabOrders

    %% Điểm vào Deep Link
    DeepLink([Deep Link Entry\n[EV: AndroidManifest.xml#intent-filter-deeplink]]) --> DeepLinkRouter{Phân Tuyến URL\n[EV: DeepLinkActivity#handleIntent]}
    DeepLinkRouter -->|myapp://order/{id}| OrderDetail
    DeepLinkRouter -->|myapp://profile| TabProfile

    %% Luồng thoát & Đăng xuất
    TabProfile --> LogoutAction[Hành Động Đăng Xuất\n[EV: ProfileViewModel#logout]]
    LogoutAction --> ClearSession[Xóa Cache & Session\n[EV: SessionManager#clearSession]]
    ClearSession --> Login

    MainShell --> ExitApp([Thoát Ứng Dụng / App Exit\n[EV: MainActivity#onBackPressed]])
```

---

## 2. DANH MỤC KIỂM KÊ MÀN HÌNH (SCREEN INVENTORY)

Mọi màn hình (Activity, Fragment, Composable, hoặc Web Page) phải được lập danh mục kiểm kê đầy đủ, liên kết trực tiếp tới file mã nguồn và hàm thực thi thông qua mỏ neo bằng chứng `[EV: ...]`:

| Mã MH | Tên Màn Hình / Trách Nhiệm | Lớp / Tuyến Điều Hướng (NavRoute) | File Giao Diện (Layout / Composable) | Điểm Kích Hoạt & Tham Số Đầu Vào | Đích Đến Tiếp Theo | Mỏ Neo Bằng Chứng (Evidence Anchor) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `SCR-01` | Splash Screen / Khởi tạo | `com.example.app.ui.SplashActivity` | `res/layout/activity_splash.xml` | Khởi động từ Launcher Icon | `SCR-02` hoặc `SCR-03` | `[EV: SplashActivity.java#onCreate]` |
| `SCR-02` | Màn hình Đăng nhập | `com.example.app.ui.auth.LoginActivity` | `res/layout/activity_login.xml` | Token hết hạn hoặc bấm Đăng xuất | `SCR-03` (Thành công) | `[EV: LoginActivity.java#initViews]` |
| `SCR-03` | Trang Chủ / Dashboard | `com.example.app.ui.main.MainActivity` | `res/layout/activity_main.xml` | Đăng nhập thành công / Cold start có session | `SCR-04`, `SCR-05`, `SCR-06` | `[EV: MainActivity.java#setupBottomNav]` |
| `SCR-04` | Danh Sách Sản Phẩm / Dữ Liệu | `com.example.app.ui.items.ItemListFragment` | `res/layout/fragment_item_list.xml` | Nhấn Tab Danh mục trên BottomNav | `SCR-07` (Chi tiết mục) | `[EV: ItemListFragment.java#onViewCreated]` |
| `SCR-05` | Chi Tiết Đơn Hàng / Bản Ghi | `com.example.app.ui.order.OrderDetailActivity` | `res/layout/activity_order_detail.xml` | Nhấn vào một thẻ đơn hàng; Tham số: `order_id` (String) | `SCR-03` (Quay lại) | `[EV: OrderDetailActivity.java#loadOrderData]` |
| `SCR-06` | Biểu Mẫu Tạo Mới Giao Dịch | `com.example.app.ui.create.CreateItemActivity` | `res/layout/activity_create_item.xml` | Nhấn nút FAB Tạo mới tại Dashboard | `SCR-03` (Sau khi lưu thành công) | `[EV: CreateItemActivity.java#setupForm]` |
| `SCR-07` | Cài Đặt & Hồ Sơ Cá Nhân | `com.example.app.ui.profile.ProfileFragment` | `res/layout/fragment_profile.xml` | Nhấn Tab Hồ sơ trên BottomNav | `SCR-02` (Đăng xuất) | `[EV: ProfileFragment.java#bindUserData]` |

---

## 3. TRÌNH TỰ MẠNG & GIAO TIẾP API (API & NETWORK SEQUENCE)

Danh sách tất cả các điểm kết nối mạng và API máy chủ được phát hiện từ quá trình đảo ngược mã nguồn:

| Mã API | Màn Hình Kích Hoạt | Phương Thức & Endpoint | Header & Tham Số Truyền Đi | Định Dạng Dữ Liệu Phản Hồi | Cơ Chế Xử Lý Lỗi & Khôi Phục | Mỏ Neo Bằng Chứng (Evidence Anchor) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `API-01` | `SCR-02` (Login) | `POST /api/v1/auth/login` | Header: `Content-Type: application/json`<br>Body: `{"username": "...", "password": "..."}` | `200 OK`: `{"token": "JWT...", "expires_in": 3600, "user_id": "U123"}` | Báo lỗi banner đỏ; Giữ nguyên trường tên đăng nhập (`RULE-INIT-001`) | `[EV: AuthService.java#loginCall]` |
| `API-02` | `SCR-03` (Dashboard) | `GET /api/v1/dashboard/summary` | Header: `Authorization: Bearer <token>`<br>Query: `date_range=current_month` | `200 OK`: `{"revenue": 15000000, "active_orders": 12, "alerts": []}` | Fallback đọc dữ liệu từ cache SQLite cục bộ khi offline | `[EV: DashboardRepository.java#getSummary]` |
| `API-03` | `SCR-04` (Item List) | `GET /api/v1/items` | Header: `Authorization: Bearer <token>`<br>Query: `page=1&limit=20&filter=all` | `200 OK`: `{"items": [...], "total": 142, "has_next": true}` | Hiển thị Skeleton loading; Cho phép kéo để làm mới (Pull-to-refresh) | `[EV: ItemRepository.java#fetchItemsPage]` |
| `API-04` | `SCR-06` (Create Item) | `POST /api/v1/items` | Header: `Authorization: Bearer <token>`<br>Body: `{"name": "...", "price": 50000, "category_id": "C01"}` | `201 Created`: `{"id": "ITEM-999", "status": "ACTIVE"}` | 4xx/5xx: Lưu bản nháp vào SharedPreferences/SQLite, hiển thị nút Thử lại | `[EV: CreateItemViewModel.java#submitItem]` |
| `API-05` | `SCR-05` (Order Detail) | `GET /api/v1/orders/{id}` | Header: `Authorization: Bearer <token>`<br>Path: `id=ORD-2026-001` | `200 OK`: `{"id": "ORD-2026-001", "items": [...], "status": "DELIVERED"}` | Exponential backoff retry tối đa 3 lần với mã 503 | `[EV: OrderApiClient.java#fetchOrderDetail]` |

---

## 4. LƯỢC ĐỒ LƯU TRỮ DỮ LIỆU CỤC BỘ (LOCAL STORAGE SCHEMA)

### 4.1 Cơ Sở Dữ Liệu Cục Bộ (SQLite / Room Database)
- **Tên cơ sở dữ liệu**: `app_database.db` [EV: AppDatabase.java#DATABASE_NAME]
- **Phiên bản lược đồ (Schema Version)**: `3` [EV: AppDatabase.java#DATABASE_VERSION]
- **Chiến lược di cư (Migration Strategy)**: Tự động migrate bảo toàn dữ liệu bảng giao dịch [EV: Migration_2_3.java#migrate]

#### Bảng: `items` (Danh mục sản phẩm/mục quản lý)
| Cột | Kiểu Dữ Liệu | Ràng Buộc | Ý Nghĩa Nghiệp Vụ | Mỏ Neo Bằng Chứng |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `TEXT` | `PRIMARY KEY NOT NULL` | Mã định danh duy nhất | `[EV: ItemEntity.java#id]` |
| `name` | `TEXT` | `NOT NULL` | Tên hiển thị của mục | `[EV: ItemEntity.java#name]` |
| `price` | `REAL` | `NOT NULL DEFAULT 0.0` | Đơn giá niêm yết | `[EV: ItemEntity.java#price]` |
| `category_id` | `TEXT` | `NOT NULL` | Khóa ngoại tới danh mục | `[EV: ItemEntity.java#categoryId]` |
| `sync_status` | `INTEGER` | `DEFAULT 0` | 0: Đã đồng bộ, 1: Chờ đẩy server | `[EV: ItemEntity.java#syncStatus]` |
| `updated_at` | `INTEGER` | `NOT NULL` | Unix timestamp cập nhật cuối | `[EV: ItemEntity.java#updatedAt]` |

#### Bảng: `cached_orders` (Bản sao lưu trữ ngoại tuyến của đơn hàng)
| Cột | Kiểu Dữ Liệu | Ràng Buộc | Ý Nghĩa Nghiệp Vụ | Mỏ Neo Bằng Chứng |
| :--- | :--- | :--- | :--- | :--- |
| `order_id` | `TEXT` | `PRIMARY KEY NOT NULL` | Mã đơn hàng nghiệp vụ | `[EV: OrderEntity.java#orderId]` |
| `payload_json` | `TEXT` | `NOT NULL` | Toàn bộ cấu trúc JSON đơn hàng | `[EV: OrderEntity.java#payloadJson]` |
| `cached_time` | `INTEGER` | `NOT NULL` | Thời điểm ghi cache | `[EV: OrderEntity.java#cachedTime]` |

### 4.2 Lưu Trữ Khóa-Giá Trị (SharedPreferences / Jetpack DataStore / KeyStore)
- **Tập tin SharedPreferences chính**: `app_preferences.xml` [EV: PrefsConstants.java#PREFS_NAME]
- **Lưu trữ dữ liệu nhạy cảm**: Google Tink Aead / Android KeyStore bọc mã hóa AES-256-GCM [EV: SecureStorage.java#initKeyStore]

| Khóa Cấu Hình (Key) | Kiểu Dữ Liệu | Giá Trị Mặc Định | Cấp Độ Nhạy Cảm | Mục Đích Lưu Trữ | Mỏ Neo Bằng Chứng |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `key_auth_token` | `String (Encrypted)` | `""` | `CONFIDENTIAL_PII` | JWT Token xác thực phiên đăng nhập | `[EV: SessionManager.java#AUTH_TOKEN_KEY]` |
| `key_user_id` | `String` | `""` | `INTERNAL` | Mã người dùng hiện hành | `[EV: SessionManager.java#USER_ID_KEY]` |
| `key_theme_mode` | `String` | `"LIGHT"` | `PUBLIC` | Tùy chọn giao diện (LIGHT / DARK / SYSTEM) | `[EV: ThemeManager.java#THEME_KEY]` |
| `key_last_sync_timestamp` | `Long` | `0L` | `INTERNAL` | Thời điểm hoàn tất đồng bộ gần nhất | `[EV: SyncManager.java#LAST_SYNC_KEY]` |
| `key_draft_transaction` | `String (JSON)` | `"{}"` | `USER_DATA` | Bản nháp form đang nhập dở (RULE-INIT-001) | `[EV: DraftManager.java#DRAFT_TX_KEY]` |

---

## 5. BẢN ĐỒ TÁC VỤ NGẦM & ĐIỀU HƯỚNG INTENT (BACKGROUND & INTENT MAP)

### 5.1 Dịch Vụ Nền & Bộ Lập Lịch (Services & WorkManager)
| Tên Thành Phần (Class / Service) | Loại Hình Thực Thi | Điều Kiện Kích Hoạt (Constraints) | Chu Kỳ Thực Hiện | Trách Nhiệm Kỹ Thuật | Mỏ Neo Bằng Chứng |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `com.example.app.sync.DataSyncWorker` | `androidx.work.CoroutineWorker` | Mạng khả dụng (`NetworkType.CONNECTED`), Pin không yếu (`BatteryNotLow`) | Mỗi 15 phút hoặc khi mạng khôi phục | Đẩy các bản ghi `sync_status = 1` lên máy chủ | `[EV: SyncWorker.java#doWork]` |
| `com.example.app.fcm.AppFirebaseMessagingService` | `com.google.firebase.messaging.FirebaseMessagingService` | Nhận Push Notification từ FCM | Sự kiện đẩy thời gian thực (Push Event) | Hiển thị thông báo trên Notification Tray & đồng bộ dữ liệu | `[EV: AppFirebaseMessagingService.java#onMessageReceived]` |
| `com.example.app.cleanup.TempCleanupWorker` | `androidx.work.Worker` | Thiết bị đang cắm sạc & Chế độ nghỉ (Idle) | Định kỳ 24 giờ một lần | Xóa các ảnh chụp màn hình tạm và file log quá 7 ngày | `[EV: TempCleanupWorker.java#doWork]` |

### 5.2 Bộ Đón Bắt Sự Kiện Hệ Thống (Broadcast Receivers)
| Tên Bộ Thu (Receiver Class) | Quyền Khai Báo (Permission) | Intent Filter Actions Đăng Ký | Mục Đích Xử Lý | Mỏ Neo Bằng Chứng |
| :--- | :--- | :--- | :--- | :--- |
| `com.example.app.receiver.BootCompleteReceiver` | `android.permission.RECEIVE_BOOT_COMPLETED` | `android.intent.action.BOOT_COMPLETED` | Lên lịch lại WorkManager định kỳ sau khi máy khởi động lại | `[EV: BootCompleteReceiver.java#onReceive]` |
| `com.example.app.receiver.NetworkChangeReceiver` | Không yêu cầu | `android.net.conn.CONNECTIVITY_CHANGE` | Kích hoạt chu kỳ đồng bộ dữ liệu ngoại tuyến khi có kết nối trở lại | `[EV: NetworkChangeReceiver.java#onReceive]` |

### 5.3 Bản Đồ Deep Link & Liên Kết Mở Rộng (Deep Links & Intent Filters)
| Chuỗi URI Scheme / Universal Link | Activity Tiếp Nhận | Tham Số Truy Cập | Hành Động Điều Hướng | Mỏ Neo Bằng Chứng |
| :--- | :--- | :--- | :--- | :--- |
| `myapp://order/{order_id}` | `com.example.app.ui.order.OrderDetailActivity` | `order_id` (String) | Mở trực tiếp màn hình chi tiết đơn hàng tương ứng | `[EV: AndroidManifest.xml#intent-filter-order]` |
| `myapp://payment/callback` | `com.example.app.ui.payment.PaymentCallbackActivity` | `tx_ref`, `status` | Xử lý phản hồi từ cổng thanh toán đối tác | `[EV: AndroidManifest.xml#intent-filter-payment]` |
| `https://app.example.com/item/{id}` | `com.example.app.ui.items.ItemDetailActivity` | `id` (String) | Mở xem chi tiết sản phẩm qua App Links có xác thực SHA-256 | `[EV: AndroidManifest.xml#intent-filter-applinks]` |

---

## 6. KỊCH BẢN VÀNG KIỂM THỬ TỰ ĐỘNG HÓA (3-5 GOLDEN SCENARIOS)
*Trích xuất trực tiếp từ hành vi quan sát được của ứng dụng gốc (`baseline observed behavior`) để phục vụ kiểm thử hồi quy tự động ở Stage 04 và Stage 05:*

### Kịch Bản Vàng 01 (`GOLDEN-01`): Khởi Động Lần Đầu & Khởi Tạo Dữ Liệu Mặc Định
- **Mục tiêu**: Kiểm chứng luồng khởi tạo môi trường sạch khi ứng dụng chạy lần đầu tiên.
- **Tiền điều kiện (Pre-condition)**:
  * Ứng dụng vừa cài đặt hoặc đã xóa trắng dữ liệu (`pm clear com.example.app`).
  * Cơ sở dữ liệu SQLite chưa tồn tại; SharedPreferences trống rỗng.
- **Chuỗi thao tác đầu vào (Input Actions)**:
  1. Khởi chạy ứng dụng qua lệnh `am start -n com.example.app/.ui.SplashActivity`.
  2. Chờ 500ms cho SplashActivity kiểm tra trạng thái xác thực.
- **Kết quả kỳ vọng (Expected Output)**:
  * Khởi tạo file `app_database.db` với đầy đủ các bảng ở Schema version 3.
  * Tự động điều hướng sang màn hình Đăng nhập `com.example.app.ui.auth.LoginActivity`.
  * SharedPreferences lưu `key_theme_mode = "LIGHT"`.
- **Câu lệnh kiểm chứng tự động (Verification Assertion)**:
  ```powershell
  # Kiểm tra Activity hiển thị hiện tại là LoginActivity
  $currentActivity = adb shell "dumpsys window | grep -E 'mCurrentFocus|mFocusedApp'"
  Assert-True ($currentActivity -match "LoginActivity") "Màn hình đích phải là LoginActivity"
  ```
- **Mỏ neo bằng chứng**: `[EV: 03_KET_QUA_KIEM_TRA/baseline/layout_01.json]`, `[EV: SplashActivity.java#checkSessionAndNavigate]`

---

### Kịch Bản Vàng 02 (`GOLDEN-02`): Đăng Nhập & Tải Dashboard Dữ Liệu Thực (Happy Path)
- **Mục tiêu**: Kiểm tra luồng đăng nhập thành công và nạp dữ liệu thống kê bảng điều khiển.
- **Tiền điều kiện (Pre-condition)**:
  * Ứng dụng đang ở màn hình Đăng nhập (`LoginActivity`).
  * Kết nối mạng ổn định; Mock server sẵn sàng trả về `API-01` (200 OK).
- **Chuỗi thao tác đầu vào (Input Actions)**:
  1. Nhập văn bản `"test_user"` vào ô `edt_username` (`id/edt_username`).
  2. Nhập văn bản `"secure_pass123"` vào ô `edt_password` (`id/edt_password`).
  3. Nhấn nút Đăng nhập `btn_login` (`id/btn_login`).
- **Kết quả kỳ vọng (Expected Output)**:
  * Nút `btn_login` chuyển sang trạng thái disabled, hiển thị spinner loading (`UI State 1: Loading`).
  * Gọi API `POST /api/v1/auth/login`.
  * Nhận token JWT hợp lệ, ghi vào Secure Storage `key_auth_token`.
  * Chuyển màn hình sang `MainActivity`, Bottom Navigation chọn Tab Trang Chủ.
  * Hiển thị bảng tổng hợp doanh thu và số lượng đơn hàng thực tế từ `API-02`.
- **Câu lệnh kiểm chứng tự động (Verification Assertion)**:
  ```powershell
  $token = adb shell "cat /data/data/com.example.app/shared_prefs/app_preferences.xml | grep key_auth_token"
  Assert-True (-not [string]::IsNullOrEmpty($token)) "Token xác thực phải được ghi vào SharedPreferences"
  $isMainFocused = adb shell "dumpsys window | grep -E 'mCurrentFocus.*MainActivity'"
  Assert-True ($isMainFocused -ne $null) "Phải điều hướng thành công vào MainActivity"
  ```
- **Mỏ neo bằng chứng**: `[EV: LoginViewModel.java#loginSuccess]`, `[EV: MainActivity.java#loadDashboardData]`

---

### Kịch Bản Vàng 03 (`GOLDEN-03`): Xử Lý Lỗi Mạng & Bảo Toàn Form Nhập Liệu (`RULE-INIT-001`)
- **Mục tiêu**: Đảm bảo khi phát sinh lỗi kết nối mạng trong quá trình tạo mới mục, form nhập liệu được bảo toàn 100% nội dung và hiển thị trạng thái Error Recovery.
- **Tiền điều kiện (Pre-condition)**:
  * Người dùng đang mở màn hình Tạo Mới Giao Dịch (`CreateItemActivity`).
  * Thiết bị bật Chế độ máy bay (`svc data disable` & `svc wifi disable`).
- **Chuỗi thao tác đầu vào (Input Actions)**:
  1. Nhập `"Sản phẩm thử nghiệm A"` vào ô `edt_item_name`.
  2. Nhập đơn giá `"750000"` vào ô `edt_item_price`.
  3. Nhấn nút Lưu `btn_save_item`.
- **Kết quả kỳ vọng (Expected Output)**:
  * Ứng dụng không bị sập (0 crash, 0 ANR).
  * Hiển thị Banner lỗi màu đỏ (`var(--color-danger)`): *"Không có kết nối mạng. Vui lòng kiểm tra lại."*.
  * Dữ liệu trong các ô `edt_item_name` ("Sản phẩm thử nghiệm A") và `edt_item_price` ("750000") được giữ nguyên vẹn 100%.
  * Xuất hiện nút bấm *"Thử lại"* (Retry Button) và tùy chọn *"Lưu bản nháp ngoại tuyến"*.
- **Câu lệnh kiểm chứng tự động (Verification Assertion)**:
  ```powershell
  $nameValue = adb shell "uiautomator dump /sdcard/dump.xml && cat /sdcard/dump.xml | grep -o 'Sản phẩm thử nghiệm A'"
  Assert-Equal "Sản phẩm thử nghiệm A" $nameValue.Trim() "Dữ liệu form đã nhập phải được bảo toàn theo RULE-INIT-001"
  ```
- **Mỏ neo bằng chứng**: `[EV: CreateItemActivity.java#onNetworkError]`, `[EV: draft-policy.md#RULE-INIT-001]`

---

### Kịch Bản Vàng 04 (`GOLDEN-04`): Lưu Bản Ghi Ngoại Tuyến & Đồng Bộ Tự Động Khi Có Mạng
- **Mục tiêu**: Kiểm chứng khả năng lưu trữ cục bộ khi offline và đồng bộ hóa background qua WorkManager khi mạng phục hồi.
- **Tiền điều kiện (Pre-condition)**:
  * Người dùng đăng nhập thành công.
  * Mạng bị ngắt.
- **Chuỗi thao tác đầu vào (Input Actions)**:
  1. Tạo mới 1 bản ghi với tên `"Mục Ngoại Tuyến 123"`.
  2. Nhấn nút *"Lưu Ngoại Tuyến"*.
  3. Bật lại kết nối mạng (`svc data enable` & `svc wifi enable`).
  4. Kích hoạt Worker đồng bộ qua lệnh ADB: `cmd jobscheduler run -f com.example.app 1001`.
- **Kết quả kỳ vọng (Expected Output)**:
  * Bản ghi được chèn vào bảng SQLite `items` với `sync_status = 1`.
  * Sau khi Worker chạy xong, bản ghi chuyển sang `sync_status = 0`.
  * API `POST /api/v1/items` được gọi với payload của mục đã lưu.
- **Câu lệnh kiểm chứng tự động (Verification Assertion)**:
  ```powershell
  $syncStatus = adb shell "sqlite3 /data/data/com.example.app/databases/app_database.db 'SELECT sync_status FROM items WHERE name=\"Mục Ngoại Tuyến 123\";'"
  Assert-Equal "0" $syncStatus.Trim() "Bản ghi phải được chuyển sync_status = 0 sau khi đồng bộ thành công"
  ```
- **Mỏ neo bằng chứng**: `[EV: SyncWorker.java#syncPendingItems]`, `[EV: ItemDao.java#updateSyncStatus]`

---

### Kịch Bản Vàng 05 (`GOLDEN-05`): Khôi Phục Phiên Làm Việc Sau Khi Khởi Động Lại (Cold Restart)
- **Mục tiêu**: Xác thực rằng phiên làm việc của người dùng vẫn tồn tại sau khi hệ điều hành tắt hoặc ứng dụng bị dừng tiến trình (`Process Death`).
- **Tiền điều kiện (Pre-condition)**:
  * Người dùng đã đăng nhập thành công, token lưu trong SharedPreferences còn hạn.
- **Chuỗi thao tác đầu vào (Input Actions)**:
  1. Dừng hoàn toàn tiến trình ứng dụng bằng lệnh: `am force-stop com.example.app`.
  2. Khởi chạy lại ứng dụng: `am start -n com.example.app/.ui.SplashActivity`.
- **Kết quả kỳ vọng (Expected Output)**:
  * SplashActivity đọc token hợp lệ từ `key_auth_token`.
  * Bỏ qua màn hình Đăng nhập `LoginActivity`.
  * Điều hướng trực tiếp vào `MainActivity` trong vòng dưới 1.0 giây (đáp ứng ngân sách Cold Start).
- **Câu lệnh kiểm chứng tự động (Verification Assertion)**:
  ```powershell
  $currentFocus = adb shell "dumpsys window | grep -E 'mCurrentFocus.*MainActivity'"
  Assert-True ($currentFocus -ne $null) "Ứng dụng phải mở trực tiếp vào MainActivity mà không hỏi lại đăng nhập"
  ```
- **Mỏ neo bằng chứng**: `[EV: SplashActivity.java#validateExistingSession]`, `[EV: SessionManager.java#isSessionValid]`
