# HƯỚNG DẪN PHỎNG VẤN CHUYÊN BIỆT: TỐI ƯU HÓA TOÀN DIỆN ỨNG DỤNG (APP OPTIMIZATION)
> **Domain**: `APP_OPTIMIZATION`  
> **Áp dụng cho**: Bước 06 (`06_REA_INTERVIEW`) & Bước 07 (`07_SPEC_AND_DESIGN`) thuộc STAGE_03 · PRODUCT DEFINITION  
> **Quy chuẩn**: REA Adaptive Interview Framework · Anti-Slop Architecture  

---

## 1. Mục Tiêu & Phạm Vi Phỏng Vấn

Hướng dẫn này kích hoạt khi mục tiêu dự án tập trung vào việc **nâng cấp hiệu năng, giảm tiêu hao tài nguyên, triệt tiêu giật lag, tăng cường độ ổn định và cải thiện trải nghiệm phản hồi** của toàn bộ ứng dụng (system-wide hoặc multi-screen) mà không thay đổi cốt lõi nghiệp vụ.

Ranh giới tuyệt đối:
- **Tập trung vào chỉ số đo lường thực tế** (Quantitative Metrics).
- **Không suy diễn mơ hồ**: Mọi tối ưu hóa phải bắt đầu từ việc đo lường Baseline (Điểm chuẩn ban đầu).
- **Không làm vỡ hành vi đang hoạt động** (Behavior Preservation).

---

## 2. Sáu Trụ Cột Tối Ưu Hóa (6 Optimization Pillars)

```
┌────────────────────────────────────────────────────────────────────────┐
│                      6 TRỤ CỘT TỐI ƯU HÓA ỨNG DỤNG                     │
├───────────────────┬───────────────────┬────────────────────────────────┤
│ 1. PERFORMANCE    │ 2. RESOURCE       │ 3. STABILITY                   │
│ - Frame rate/Jank │ - RAM / Heap Leaks│ - Crash-free target            │
│ - Startup latency │ - Battery / Wake  │ - ANR elimination              │
│ - Render pass     │ - Bandwidth & Disk│ - Background survival          │
├───────────────────┼───────────────────┼────────────────────────────────┤
│ 4. UX RESPONSIVE  │ 5. COMPATIBILITY  │ 6. BASELINE & MEASUREMENT      │
│ - Input lag <100ms│ - Low-RAM devices │ - Pre-profile (Perfetto)       │
│ - Scroll fluidity │ - minSdk / Fold   │ - Target benchmarks            │
│ - Non-block async │ - Thermal bounds  │ - Regression guards            │
└───────────────────┴───────────────────┴────────────────────────────────┘
```

### 2.1 Performance (Hiệu Năng Xử Lý & Hiển Thị)
- **Frame Rate & Jank**: Mục tiêu duy trì ổn định 60fps hoặc 120fps (màn hình tần số quét cao). Tỷ lệ khung hình rơi rụng (Dropped frames / Janky frames) < 1%.
- **Startup Time (Thời gian khởi động)**:
  * Cold Start: Khởi động nguội từ 0 (Mục tiêu < 1.2s trên thiết bị trung bình).
  * Warm Start: Khởi động ấm (Mục tiêu < 0.8s).
  * Hot Start: Mở lại từ nền (Mục tiêu < 0.3s).
- **Render Pass Latency**: Thời gian layout và draw không vượt quá 16ms (chuẩn 60fps) hoặc 8ms (chuẩn 120fps). Loại bỏ hiện tượng overdraw (vẽ đè nhiều tầng màu).

### 2.2 Resource (Tiêu Hao Tài Nguyên Hệ Thống)
- **RAM & Bộ Nhớ Heap**: 
  * Giới hạn trần RAM phân bổ cho app; triệt tiêu hoàn toàn rò rỉ bộ nhớ (Memory Leaks do Static References, Context Leak, Unregistered Observers).
  * Quản lý Bitmap và Media: Dùng pooling, downsampling, nén đúng định dạng (WebP/AVIF).
- **Battery Drain (Năng Lượng Pin)**:
  * Hạn chế tối đa WakeLocks kéo dài; gộp các tác vụ chạy nền thông qua `WorkManager` với các điều kiện ràng buộc (sạc pin, có Wi-Fi).
  * Giảm tần suất GPS polling; thay thế bằng Geofencing hoặc Passive Location Provider khi không thực sự cần độ chính xác cao liên tục.
- **Network Bandwidth (Lưu Lượng Mạng)**:
  * Nén payload (GZIP, Brotli); áp dụng HTTP Caching (ETag, Cache-Control).
  * Triển khai phân trang (Pagination/Infinite Scroll), nạp lười (Lazy Loading) hình ảnh và dữ liệu ngoài tầm nhìn.
- **Disk I/O & Storage**:
  * Chuyển toàn bộ thao tác ghi đọc file/database ra Background Thread (Dispatchers.IO).
  * Tối ưu hóa chỉ mục (Indices) của Database SQLite/Room, tránh `SELECT *` toàn bảng.

### 2.3 Stability (Độ Ổn Định & Tự Khắc Phục)
- **Tỷ Lệ Phiên Không Lỗi (Crash-Free Sessions)**: Mục tiêu tối thiểu 99.9%.
- **Triệt Tiêu ANR (Application Not Responding)**: Tuyệt đối không bao giờ thực hiện tác vụ nặng, IPC đồng bộ, parse JSON lớn hoặc mã hóa/giải mã trên Main/UI Thread.
- **Tombstone & Native Crash**: Giám sát lỗi bộ nhớ tầng Native (C/C++ NDK nếu có), bắt trọn vẹn ngoại lệ chưa được xử lý (`UncaughtExceptionHandler`).
- **Background Lifecycle**: Xử lý mượt mà khi ứng dụng bị OS giải phóng bộ nhớ (Process Death); lưu và khôi phục trạng thái bằng `SavedStateHandle`.

### 2.4 UX Responsiveness (Độ Mượt & Phản Hồi Trải Nghiệm)
- **Độ Trễ Tương Tác (Input-to-Response Latency)**: Người dùng chạm vào màn hình phải nhận được phản hồi thị giác ngay lập tức (<100ms) như ripple effect, loading indicator.
- **Scroll Fluidity**: Cuộn danh sách mượt mà, không giật đứng do khởi tạo view phức tạp lúc cuộn (sử dụng view recycling, item prefetching).
- **Optimistic UI Updates**: Cập nhật giao diện ngay lập tức trước khi server phản hồi, tự động rollback mềm nếu mạng thất bại kèm thông báo rõ ràng.

### 2.5 Compatibility (Khả Năng Tương Thích Môi Trường)
- **Phân Hạng Thiết Bị**: Định rõ phân khúc hỗ trợ: Flagship, Tầm trung (Mid-tier), hoặc Thiết bị cấu hình thấp (Android Go / Low-RAM < 2GB RAM).
- **Chính Sách Giảm Tải Cấu Hình Thấp (Graceful Degradation)**:
  * Tự động tắt hiệu ứng làm mờ (Blur), đổ bóng nặng (Complex Shadows) trên thiết bị yếu.
  * Giảm kích thước cache bộ nhớ và độ phân giải ảnh hiển thị.
- **Màn Hình Đa Dạng & Foldable**: Tự thích ứng khi xoay ngang/dọc, mở rộng màn hình gập (Foldables) mà không gây reload layout giật cục.

### 2.6 Baseline & Measurement (Thiết Lập Điểm Chuẩn Đo Lường)
- **Nguyên Tắc**: *Nếu không đo lường được, không được tuyên bố đã tối ưu*.
- **Công Cụ Thu Thập Baseline**:
  * Android: Android Studio Profiler, Perfetto / Systrace, Macrobenchmark, LeakCanary, `dumpsys meminfo`, `dumpsys gfxinfo`.
  * Web: Lighthouse, Chrome DevTools Performance Trace, Core Web Vitals (LCP, FID/INP, CLS).
- **Hồ Sơ Điểm Chuẩn Bắt Buộc**: Phải lưu lại thông số trước khi tối ưu (Current Baseline) và mục tiêu sau khi tối ưu (Target KPI).

---

## 3. Quy Trình Vận Hành Bộ Lọc Câu Hỏi (Question Necessity Engine)

Trước khi gửi bất kỳ câu hỏi nào cho người dùng, Agent phải chạy qua 8 bộ lọc:

```
[Câu hỏi tiềm năng] ──► [1. Known?] ──► [2. Inspectable?] ──► [3. Evidence?] ──► ...
                                                                                  │
  ┌───────────────────────────────────────────────────────────────────────────────┘
  ▼
[4. Impact?] ──► [5. Risk?] ──► [6. Reversibility?] ──► [7. Ownership?] ──► [8. Timing?]
                                                                                  │
  ┌───────────────────────────────────────────────────────────────────────────────┘
  ▼
ĐẠT 8 BỘ LỌC ──► ĐẶT CÂU HỎI CHO NGƯỜI DÙNG
KHÔNG ĐẠT    ──► LOẠI BỎ / TỰ PHÂN TÍCH / ÁP DỤNG GIẢ ĐỊNH MẶC ĐỊNH
```

### 3.1 Những Gì KHÔNG ĐƯỢC Hỏi (Bị Triệt Tiêu Bởi Bộ Lọc)
1. **Lọc Inspectable/Evidence**:
   - ❌ *CẤM HỎI*: "App hiện tại tiêu tốn bao nhiêu MB RAM?" (Agent phải tự chạy `dumpsys meminfo` hoặc đọc báo cáo hiện trạng Bước 04).
   - ❌ *CẤM HỎI*: "Trong code có database indices không?" (Agent tự inspect schema Room/SQLite).
   - ❌ *CẤM HỎI*: "Phiên bản Android tối thiểu của app là bao nhiêu?" (Agent tự đọc `build.gradle` hoặc `AndroidManifest.xml`).
2. **Lọc Ownership**:
   - ❌ *CẤM HỎI*: "Bạn muốn dùng Coroutines hay RxJava để chạy nền?" (Đây là thẩm quyền kỹ thuật của Agent, người dùng quan tâm kết quả độ mượt, không phải thư viện).
3. **Lọc Reversibility**:
   - ❌ *CẤM HỎI*: "Có nên dùng bộ đệm LRU Cache 50MB cho ảnh không?" (Đây là quyết định hai chiều dễ đảo ngược; Agent tự chọn mặc định an toàn).

### 3.2 Những Gì ĐƯỢC Hỏi (Vượt Qua 8 Bộ Lọc)
1. **Mục tiêu ưu tiên cốt lõi khi có xung đột (Trade-off Decision)**:
   - *Ví dụ*: "Để tối ưu tốc độ phản hồi tối đa (<100ms), app có thể tải trước dữ liệu và tiêu tốn thêm khoảng 30MB bộ nhớ đệm, hoặc ưu tiên dung lượng RAM thấp nhất và chấp nhận trễ 300ms khi mở mục mới. Bạn ưu tiên phương án nào?"
2. **Thiết bị và môi trường người dùng mục tiêu**:
   - *Ví dụ*: "Sản phẩm của bạn có cần cam kết hoạt động mượt mà trên thiết bị Android Go (RAM dưới 2GB) không, hay nhắm vào thiết bị tầm trung trở lên?"
3. **Chính sách đánh đổi tính năng (Graceful Degradation Policy)**:
   - *Ví dụ*: "Khi thiết bị bật chế độ Tiết kiệm pin (Battery Saver), ứng dụng có được phép tạm dừng đồng bộ dữ liệu thời gian thực không?"

---

## 4. Bảng Giả Định Mặc Định An Toàn (Safe Default Assumptions)

Khi người dùng không nêu rõ hoặc không có câu trả lời kỹ thuật, Agent tự động áp dụng các giả định an toàn sau và ghi vào `Assumption Record`:

| Hạng Mục | Giả Định Mặc Định | Cơ Sở Kỹ Thuật | Tính Thuận Nghịch |
| :--- | :--- | :--- | :--- |
| **FPS Target** | 60 FPS cố định | Phù hợp mọi màn hình, cân bằng tiêu thụ pin | Cao (Dễ nâng lên 120Hz qua flags) |
| **Cold Start** | < 1.2s trên Mid-tier | Tránh timeout hệ điều hành, tuân thủ Android Vitals | Cao |
| **Memory Policy** | Giới hạn cache ảnh ở 20% heap | Tránh OOM trên máy yếu | Cao (Cấu hình bằng tham số) |
| **Network Sync** | Gộp batch qua WorkManager khi sạc/Wi-Fi | Tiết kiệm tối đa pin và 4G/5G | Cao |
| **Offline Cache** | Lưu trữ tạm thời 7 ngày gần nhất | Đảm bảo app vẫn xem được khi mất mạng | Cao |
| **Low-End Mode** | Tự động hạ thấp visual shadow/blur | Giữ scroll 60fps trên GPU yếu | Cao |

---

## 5. Mẫu Ghi Hồ Sơ Quyết Định & Giả Định (Engine Records)

### Mẫu Ghi Quyết Định (Decision Record)
```markdown
### DECISION-OPT-[STT]
- **Hạng Mục**: [Performance / Resource / Stability / UX / Compatibility / Baseline]
- **Vấn Đề Cần Chốt**: [Mô tả ngắn gọn]
- **Quyết Định Được Chọn**: [Lựa chọn của người dùng hoặc giải pháp thống nhất]
- **Chỉ Số Định Lượng (KPI Target)**: [Ví dụ: Cold start < 1.2s, RAM peak < 90MB]
- **Hệ Quả Kiến Trúc**: [Tác động tới module nào trong Stage 04]
- **Trạng Thái**: `CLOSED`
```

### Mẫu Ghi Giả Định Mặc Định (Assumption Record)
```markdown
### ASSUMPTION-OPT-[STT]
- **Mã giả định**: `ASSUMPTION-OPT-[STT]`
- **Hạng Mục**: [Ví dụ: Memory Cache Size]
- **Mức Độ Rủi Ro (risk_level)**: `BENIGN` | `CRITICAL`
- **Giả Định Mặc Định Đã Áp Dụng**: [Ví dụ: Giới hạn 30MB Disk Cache, 15MB Memory Cache]
- **Lý Do Áp Dụng**: Người dùng không có yêu cầu đặc thù; tuân thủ best-practice Android/Web.
- **Rủi Ro Đánh Đổi**: Nếu thiết bị quá tải cache sẽ bị dọn dẹp sớm hơn.
- **Tính Thuận Nghịch**: `HIGH`
- **Nhiệm Vụ Kiểm Chứng (Verification Task)**: Chạy Macrobenchmark trên Profile build ở Bước 10.
- **Trạng Thái (status)**: `ACTIVE` | `INVALIDATED` | `SUPERSEDED`
- **Thời Điểm Thu Hồi (invalidated_at)**: null
- **Lý Do Thu Hồi (revocation_reason)**: null
- **Các Phụ Thuộc Hạ Nguồn (downstream_dependencies)**: []
```

---

## 6. Tiêu Chí Hoàn Tất Phỏng Vấn (Exit Gate Criteria)

Agent chỉ được phép chuyển từ Bước 06 sang Bước 07 khi:
1. Đã lập đầy đủ bảng đối chiếu **Baseline Hiện Tại ➔ KPI Mục Tiêu Sau Tối Ưu**.
2. 100% các câu hỏi rủi ro cao hoặc đánh đổi tài nguyên đã có `DECISION RECORD` hoặc `ASSUMPTION RECORD`.
3. Không còn bất kỳ câu hỏi nào vi phạm 8 bộ lọc của Question Necessity Engine.
4. Đã sẵn sàng xuất bản `03_KET_QUA_KIEM_TRA/01_SCREEN_COMPOSITION.md` (hoặc Performance Spec tương đương) mà không có mâu thuẫn kiến trúc.
