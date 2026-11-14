# HƯỚNG DẪN PHỎNG VẤN CHUYÊN BIỆT: TƯƠNG THÍCH NỀN TẢNG (PLATFORM COMPATIBILITY)
> **Domain**: `PLATFORM_COMPATIBILITY`  
> **Áp dụng cho**: Bước 06 (`06_REA_INTERVIEW`) & Bước 07 (`07_SPEC_AND_DESIGN`) thuộc STAGE_03 · PRODUCT DEFINITION  
> **Quy chuẩn**: REA Adaptive Interview Framework · Cross-Device & OS Compliance  

---

## 1. Mục Tiêu & Phạm Vi Phỏng Vấn

Hướng dẫn này kích hoạt khi bài toán yêu cầu **đảm bảo ứng dụng chạy mượt mà, đúng chuẩn trên các phiên bản hệ điều hành đích (Android 14 API 34, Android 15 API 35), đa dạng thiết bị (smartphone, tablet, foldable, Android TV), hoặc môi trường triển khai đa nền tảng (Web, Desktop, Hybrid)**.

Nguyên tắc:
- **Tự động trích xuất thông số trước khi hỏi**: Tự đọc `minSdkVersion`, `targetSdkVersion`, `compileSdk` từ `build.gradle` hoặc `AndroidManifest.xml`. Không hỏi người dùng những gì đã ghi trong file.
- **Tập trung vào ràng buộc phân phối thực tế**: Google Play Store 2024/2026 yêu cầu targetSdk tối thiểu, 16 KB Page-Size trên Android 15, Insets Edge-to-Edge bắt buộc.

---

## 2. Các Trụ Cột Điều Tra Tương Thích Nền Tảng

### 2.1 Phiên Bản OS & Thiết Bị Mục Tiêu (OS & Device Matrix)
- **Min SDK & Target SDK**:
  * Android 15 (API 35): Mặc định kích hoạt Edge-to-Edge toàn màn hình, yêu cầu thư viện native `.so` phải căn chỉnh 16 KB page-size (`zipalign -P 16`, NDK r28).
  * Android 14 (API 34): Kiểm soát chặt chẽ quyền truy cập ảnh/video (Selected Photos Access), Foreground Service types bắt buộc khai báo.
  * Thiết bị cấu hình thấp (Android Go / Low-RAM Devices <= 2GB RAM): Yêu cầu tối ưu bitmap và hạn chế tiến trình ngầm.

### 2.2 Kiểu Dáng Thiết Bị & Màn Hình (Form Factors & Insets)
- Màn hình gập (Foldables / Tablets): Khả năng thích ứng Window Size Classes (Compact < 600dp, Medium 600-840dp, Expanded > 840dp).
- Bố cục Edge-to-Edge: Xử lý Status bar, Navigation bar (Insets) không để nội dung bị che khuất hoặc chạm mép camera cutout.

### 2.3 Phụ Thuộc Phần Cứng (Hardware Dependencies)
- Camera, GPS/Vị trí, Bluetooth LE, NFC, Cảm biến sinh trắc học (Fingerprint / Face Unlock).
- Xử lý tình huống thiết bị không có phần cứng tương ứng (Graceful Fallback / `android.hardware.* required="false"`).

---

## 3. Khung Câu Hỏi Quyết Định Tương Thích (Decision-Driven Question Catalog)

### Q-COMPAT-01: Phạm Vi Hỗ Trợ Thiết Bị & Màn Hình Lớn
- **Câu hỏi**: Ứng dụng này chủ yếu phục vụ người dùng điện thoại thông minh tiêu chuẩn, hay cần tối ưu hóa giao diện chia đôi cột (Two-Pane) cho máy tính bảng / màn hình gập?
- **Intent**: Quyết định có cần lập Responsive Spec theo Window Size Classes (`Expanded`) tại Bước 07 hay không.
- **Related Decision**: `DECISION-COMPAT-01: Form Factor Support Strategy`.
- **Expected Information**: Chỉ cần điện thoại dọc / Bắt buộc hỗ trợ cả Tablet và Foldable.
- **Applicability Conditions**: Ứng dụng có màn hình danh sách - chi tiết (List-Detail).
- **Skip Conditions**: Đã có thông tin trong hồ sơ mục tiêu hoặc ứng dụng là công cụ tiện ích nhỏ.

### Q-COMPAT-02: Ràng Buộc Phân Phối Lên Cửa Hàng Ứng Dụng (Store Distribution Requirements)
- **Câu hỏi**: Ứng dụng sẽ được phát hành chính thức lên Google Play Store (yêu cầu nghiêm ngặt về targetSdk 34+, 16 KB Page-Size, 64-bit binaries) hay chỉ cài đặt nội bộ (Sideload / APK direct)?
- **Intent**: Định hình rào chắn xác thực bản build tại Gate 04 và Gate 05.
- **Related Decision**: `DECISION-COMPAT-02: Distribution Channel & Compliance Target`.
- **Expected Information**: Google Play Store / Phân phối nội bộ APK.
- **Applicability Conditions**: Dự án phát triển mã nguồn native Android.
- **Skip Conditions**: Dự án Route A (Web App Zero-Install).

---

## 4. Bảng Tiêu Chí Nghiệm Thu Đóng Băng Tương Thích

1. Giao diện hiển thị đúng chuẩn Edge-to-Edge không bị đè lên thanh điều hướng hệ thống (Navigation Insets) trên Android 15.
2. Tất cả file native `.so` trong gói APK đạt chuẩn căn chỉnh 16 KB (`zipalign -P 16`).
3. Khai báo đầy đủ thuộc tính `android:required="false"` cho các tính năng phần cứng không bắt buộc.
