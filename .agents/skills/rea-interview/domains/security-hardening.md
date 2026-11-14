# HƯỚNG DẪN PHỎNG VẤN CHUYÊN BIỆT: GIA CỐ BẢO MẬT ỨNG DỤNG (SECURITY HARDENING)
> **Domain**: `SECURITY_HARDENING`  
> **Áp dụng cho**: Bước 06 (`06_REA_INTERVIEW`) & Bước 07 (`07_SPEC_AND_DESIGN`) thuộc STAGE_03 · PRODUCT DEFINITION  
> **Quy chuẩn**: REA Adaptive Interview Framework · Scoped Static Audit & Defense-in-Depth  

---

## 1. Mục Tiêu & Phạm Vi Phỏng Vấn

Hướng dẫn này kích hoạt khi mục tiêu dự án tập trung vào **khắc phục lỗ hổng bảo mật, gia cố phòng thủ ứng dụng, tuân thủ tiêu chuẩn an toàn dữ liệu, chống dịch ngược và bảo vệ tài sản số** (dựa trên kết quả Scoped Static Audit từ Bước 04 & 05).

> ⚠️ **ĐIỀU KHOẢN AN TOÀN BẤT KHẢ XÂM PHẠM**:
> 1. **TUYỆT ĐỐI KHÔNG HỎI MẬT KHẨU HOẶC API KEY THẬT**: Mọi thông tin khóa bí mật phải được thay thế bằng placeholder `[REDACTED]` hoặc hướng dẫn người dùng tự đưa vào biến môi trường / Keystore an toàn.
> 2. **SCOPED STATIC AUDIT**: Không hứa hẹn "quét sạch 100% mã độc", mà xác định rõ phạm vi kiểm toán tĩnh có giới hạn và ghi nhận các vùng chưa rõ vào `UNKNOWNS_AND_COVERAGE.md`.

---

## 2. Bảy Trụ Cột Gia Cố Bảo Mật (7 Security Pillars)

```
┌────────────────────────────────────────────────────────────────────────┐
│                      7 TRỤ CỘT GIA CỐ BẢO MẬT ỨNG DỤNG                 │
├───────────────────┬───────────────────┬────────────────────────────────┤
│ 1. ASSETS & KEYS  │ 2. AUTH & SESSION │ 3. DATA PROTECTION             │
│ - Secret hygiene  │ - Token lifecycle │ - At-rest encryption           │
│ - Code obfuscation│ - Keystore storage│ - Room/SQLCipher               │
│ - ProGuard / R8   │ - BiometricPrompt │ - Screen leak (FLAG_SECURE)    │
├───────────────────┼───────────────────┼────────────────────────────────┤
│ 4. NETWORK DEFENSE│ 5. DEVICE & RUNTIME│ 6. SUPPLY CHAIN & PERMISSIONS │
│ - TLS 1.3 / ETag  │ - Root/Integrity  │ - Least privilege manifest     │
│ - Pinning policy  │ - Anti-debug/hook │ - Dependency CVE audit         │
│ - Cleartext ban   │ - Emulator policy │ - Transitive library licenses  │
├───────────────────┴───────────────────┴────────────────────────────────┤
│ 7. THREAT MODELING & RISK SCORING (STRIDE / OWASP Mobile Top 10)       │
└────────────────────────────────────────────────────────────────────────┘
```

### 2.1 Assets & Code Protection (Bảo Vệ Tài Sản Mã Nguồn & Khóa)
- **Vệ Sinh Khóa & Bí Mật (Secret Hygiene)**: 
  * Che mờ hoàn toàn các secret phát hiện được; di dời API keys cứng trong source code sang BuildConfig/Secrets Gradle Plugin hoặc Backend Proxy.
  * Tách biệt cấu hình Development, Staging và Production.
- **Làm Rối Mã Nguồn (Code Obfuscation & Shrinking)**:
  * Kích hoạt R8 / ProGuard với cấu hình chặt chẽ (`minifyEnabled true`, `shrinkResources true`).
  * Giữ lại (keep) các quy tắc tối thiểu cho Serialization / Reflection để không vỡ app.
- **Bảo Vệ Tài Nguyên Tĩnh**: Mã hóa hoặc bọc các file nhạy cảm trong `assets/` (database mẫu, mô hình ML cục bộ).

### 2.2 Auth & Session Management (Xác Thực & Quản Lý Phiên)
- **Vòng Đời Token (Token Lifecycle)**:
  * Cơ chế làm mới token tự động (Silent Refresh với Refresh Token ngắn hạn).
  * Hủy phiên lập tức (Server-side & Client-side logout) khi phát hiện dấu hiệu bất thường.
- **Lưu Trữ Khóa Xác Thực & Dữ Liệu Nhạy Cảm**:
  * Sử dụng **Jetpack DataStore** (Preferences hoặc Proto DataStore) kết hợp **Google Tink (`Aead` primitive)** hoặc mã hóa trực tiếp payload bằng khóa đối xứng tạo từ **Android KeyStore** (`Cipher` AES-256-GCM) trước khi lưu trữ. Đối với cơ sở dữ liệu quan hệ lớn, sử dụng **SQLCipher for Android** với khóa 256-bit sinh từ Android KeyStore.
  * ⚠️ **LƯU Ý BỎ DÙNG (DEPRECATION NOTICE)**: Tuyệt đối **KHÔNG SỬ DỤNG** thư viện đã bị Google deprecated và đóng băng hoàn toàn: `androidx.security.crypto.EncryptedSharedPreferences` / `EncryptedFile`. Thư viện này có các lỗi nghiêm trọng không thể khắc phục: gây deadlock/ANR trên Main Thread, hỏng khóa KeyStore (`KeyStore corrupted / key unrecoverable`) sau khi khởi động lại thiết bị trên nhiều dòng máy OEM (Samsung, Xiaomi...), dẫn đến việc ứng dụng crash liên tục và mất sạch dữ liệu người dùng.
  * Không bao giờ lưu token hoặc secret dạng text thuần trong `SharedPreferences` thông thường hoặc SQLite unencrypted.
- **Tích Hợp Sinh Trắc Học Đạt Chuẩn Phần Cứng (Biometrics & Auth-Per-Use)**:
  * Sử dụng `BiometricPrompt` chuẩn của AndroidX bắt buộc bọc `BiometricPrompt.CryptoObject` (chứa `Cipher` hoặc `Signature` khởi tạo từ Keystore). Tuyệt đối không chỉ dùng callback boolean UI vì rất dễ bị bypass bằng hook Frida (`onAuthenticationSucceeded`).
  * Khóa KeyStore phải được cấu hình bằng `KeyGenParameterSpec.Builder`:
    ```kotlin
    builder.setUserAuthenticationParameters(
        0, // 0 giây = BẮT BUỘC AUTH-PER-OPERATION (Mỗi lần dùng phải quét sinh trắc học mới)
        KeyProperties.AUTH_BIOMETRIC_STRONG
    )
    ```
    Đặt tham số timeout = 0 đảm bảo chuẩn Auth-Per-Use nghiêm ngặt nhất, chống tấn công replay hoặc chiếm quyền phiên khi app mở ở background.

### 2.3 Data Protection (Bảo Vệ Dữ Liệu Tại Chỗ & Chống Rò Rỉ)
- **Mã Hóa Dữ Liệu Lưu Cục Bộ (At-Rest Encryption)**:
  * Cơ sở dữ liệu SQLite/Room tích hợp SQLCipher với khóa sinh ngẫu nhiên lưu trong Android KeyStore.
- **Chống Rò Rỉ Màn Hình & Bộ Nhớ Tạm**:
  * Áp dụng `FLAG_SECURE` trên các Activity / Composable nhạy cảm (thông tin tài khoản, mật khẩu, OTP) để chặn chụp màn hình và hiển thị trong danh sách ứng dụng gần đây (Recent Apps Preview).
  * **Hỗ trợ API mới của Android 15 (API 35)**: Bổ sung lắng nghe sự kiện ghi màn hình qua `WindowManager.addScreenRecordingCallback` để nhận diện ngay khi màn hình bị quay video hoặc truyền qua màn hình ngoài, chủ động che mờ các trường dữ liệu mật.
  * Xóa sạch bộ nhớ đệm clipboard sau khoảng thời gian ngắn (30s - 60s) nếu app có tính năng sao chép nhạy cảm.
  * Làm sạch mảng ký tự mật khẩu (`char[]` scrubbing) ngay sau khi sử dụng, tránh lưu `String` bất biến trong heap.

### 2.4 Network Security (An Ninh Giao Thức Mạng)
- **Cấm Hoàn Toàn Giao Thức Kém An Toàn (Cleartext Ban) & Ép Buộc TLS 1.3**:
  * Thiết lập `android:usesCleartextTraffic="false"` trong `AndroidManifest.xml`.
  * Cấu hình `network_security_config.xml` với `cleartextTrafficPermitted="false"` để cấm tuyệt đối kết nối HTTP không mã hóa ở cấp hệ điều hành.
  * ⚠️ **LƯU Ý ĐẶC TẢ XML**: Schema XML `network_security_config.xml` của Android **KHÔNG HỖ TRỢ** thuộc tính hay thẻ quy định phiên bản TLS (không có thẻ `<min-tls-version>` hay `<tls-version>`). Việc ép buộc phiên bản TLS (TLS 1.2 / TLS 1.3) **bắt buộc phải được cấu hình ở tầng Socket / HTTP Client trong mã nguồn** (ví dụ OkHttp `ConnectionSpec.MODERN_TLS` hoặc `RESTRICTED_TLS` chỉ cho phép `TlsVersion.TLS_1_3, TlsVersion.TLS_1_2`). Lưu ý trên Android 15 (API 35), hệ điều hành đã chặn hoàn toàn TLS 1.0 và TLS 1.1 ở tầng socket.
- **Ghim Chứng Chỉ (Certificate Pinning)**:
  * Đánh giá nhu cầu Certificate Pinning cho các API tối quan trọng để chống tấn công nghe lén (Man-In-The-Middle - MITM).
  * Chuẩn bị sẵn cơ chế chứng chỉ dự phòng (Backup Pin) để tránh brick ứng dụng khi máy chủ đổi chứng chỉ SSL.
- **Xác Thực Đầu Vào & Chống Replay**: Kiểm tra định dạng payload API đầu vào, áp dụng Timestamp / Nonce nếu cần.

### 2.5 Device & Runtime Integrity (Tính Toàn Vẹn Thiết Bị & Thời Gian Chạy)
- **Chính Sách Toàn Vẹn Thiết Bị & Ứng Dụng (Play Integrity API & Root/Tamper Policy)**:
  * **Thay thế hoàn toàn SafetyNet & Root Heuristics cục bộ**: SafetyNet Attestation API đã chính thức ngừng hoạt động hoàn toàn từ tháng 01/2025. Các thư viện kiểm tra Root chỉ chạy ở client-side (như RootBeer) sử dụng kiểm tra file tĩnh (`su`, `busybox`, `test-keys`) đã bị vô hiệu hóa 100% (blinded) bởi các kỹ thuật can thiệp kernel hiện đại (Magisk với Zygisk/Shamiko, KernelSU, APatch).
  * **Chuẩn OWASP MASVS-RESILIENCE v2.0**: Bắt buộc tích hợp **Google Play Integrity API** với cơ chế xác thực chứng thực token (Attestation Token) tại máy chủ backend:
    * `Device Integrity verdict`: Xác thực thiết bị chạy Android chuẩn Google, chưa bị can thiệp (MEETS_DEVICE_INTEGRITY / MEETS_STRONG_INTEGRITY).
    * `App Integrity verdict`: Xác thực APK/AAB khớp với bản ký phát hành trên Google Play, chưa bị repackage hoặc tiêm mã độc.
  * **Chính Sách Xử Lý Khi Phán Quyết Không Đạt (Verdict Failure Policy)**:
    * Phương án A (Nghiêm ngặt - FinTech/Banking): Khóa ứng dụng hoàn toàn khi phát hiện thiết bị hoặc app bị tampered.
    * Phương án B (Cảnh báo & Giảm cấp - Safe Default): Cảnh báo rủi ro người dùng, khóa các tính năng nhạy cảm (sinh trắc học, thanh toán, lưu phiên).
    * Phương án C (Chấp nhận có giám sát): Cho phép hoạt động bình thường nhưng ghi nhận cờ rủi ro (risk flag) lên máy chủ backend.
- **Chống Đính Kèm Debugger & Hooking**: Bổ sung rào chắn chống debug (`android:debuggable="false"` trong release build, ptrace checks) và phát hiện framework hook (Frida, Xposed) phối hợp cùng Play Integrity.
- **Chính Sách Môi Trường Giả Lập (Emulator Detection)**: Có cho phép chạy trên máy ảo Android không (phục vụ người dùng dùng LDPlayer/Nox/AVD hay cấm).

### 2.6 Supply Chain & Permissions (Chuỗi Cung Ứng & Quyền Hạn Tối Thiểu)
- **Kiểm Toán Quyền Hạn (Least Privilege Principle)**:
  * Rà soát `AndroidManifest.xml`: Loại bỏ triệt để các quyền không cần thiết (như `READ_EXTERNAL_STORAGE`, `ACCESS_FINE_LOCATION` nếu app chỉ cần coarse location).
  * Chuyển sang Photo Picker của Android thay vì yêu cầu quyền truy cập toàn bộ thư viện ảnh.
- **Rà Soát Thư Viện Bên Thứ Ba (Dependencies Audit)**:
  * Kiểm tra các thư viện có chứa CVE đã biết hoặc thư viện bị bỏ hoang (unmaintained).
  * Loại bỏ các SDK quảng cáo hoặc phân tích dữ liệu mờ ám gửi telemetries về máy chủ không rõ nguồn gốc.

### 2.7 Threat Modeling & Risk Scoring (Mô Hình Đe Dọa)
- Đánh giá theo ma trận STRIDE (Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege) và OWASP Mobile Top 10.
- Xác định điểm rủi ro: `CRITICAL`, `HIGH`, `MEDIUM`, `LOW`.

---

## 3. Quy Trình Vận Hành Bộ Lọc Câu Hỏi (Question Necessity Engine)

```
[Câu hỏi bảo mật] ──► [Lọc 1..8] ──► [Có vi phạm Secret Hygiene?] ──► BỊ LOẠI BỎ NGAY
                                  ──► [Có tự inspect được mã nguồn?]  ──► TỰ ĐỌC VÀ KẾT LUẬN
                                  ──► [Liên quan chính sách cốt lõi?]  ──► ĐƯỢC PHÉP HỎI
```

### 3.1 Những Gì KHÔNG ĐƯỢC Hỏi
- ❌ **CẤM HỎI**: "Mật khẩu database hoặc API secret của bạn là gì?" (Vi phạm quy định an toàn).
- ❌ **CẤM HỎI**: "App có bật usesCleartextTraffic không?" (Agent tự kiểm tra `AndroidManifest.xml`).
- ❌ **CẤM HỎI**: "Thư viện Retrofit trong app đang là bản nào?" (Agent tự đọc `build.gradle`).
- ❌ **CẤM HỎI**: "Nên dùng thuật toán AES-GCM hay CBC?" (Agent tự quyết định chuẩn an toàn cao nhất là AES-256-GCM).

### 3.2 Những Gì ĐƯỢC Hỏi (Quyết Định Cấp Sản Phẩm/Chính Sách)
1. **Chính sách ứng xử với phán quyết toàn vẹn thiết bị (Google Play Integrity Policy)**:
   - *Ví dụ*: "Khi Google Play Integrity API trả về phán quyết thiết bị không đạt chuẩn (không đạt MEETS_DEVICE_INTEGRITY hoặc phát hiện rooted/tampered), ứng dụng nên: (A) Chặn mở app hoàn toàn, (B) Cảnh báo rủi ro người dùng và vô hiệu hóa các tính năng sinh trắc học và thanh toán, hay (C) Cho phép dùng nhưng ghi nhận cảnh báo lên hệ thống giám sát gian lận phía backend?"
2. **Chính sách chụp ảnh màn hình (Screen Capture Policy)**:
   - *Ví dụ*: "Bạn có muốn áp dụng chế độ chống chụp màn hình (`FLAG_SECURE`) cho toàn bộ app hay chỉ các màn hình nhạy cảm (Cài đặt, Ví, Đăng nhập)?"
3. **Tiêu chuẩn tuân thủ bắt buộc (Compliance Requirements)**:
   - *Ví dụ*: "Ứng dụng có bắt buộc tuân thủ tiêu chuẩn đặc thù nào không (ví dụ: PCI-DSS cho thanh toán, GDPR bảo vệ dữ liệu người dùng EU, hoặc quy chuẩn an ninh nội bộ công ty)?"

---

## 4. Bảng Giả Định Mặc Định An Toàn (Safe Security Defaults)

| Hạng Mục | Giả Định Mặc Định An Toàn | Lý Do Kỹ Thuật | Tính Thuận Nghịch |
| :--- | :--- | :--- | :--- |
| **Cleartext Traffic** | CẤM HOÀN TOÀN (`false`) | Chống nghe lén mật khẩu và dữ liệu trên Wi-Fi công cộng | Trung bình |
| **Sensitive Storage** | Jetpack DataStore + Google Tink (`Aead`) / KeyStore Cipher | Chuẩn Jetpack hiện đại (thay thế `EncryptedSharedPreferences` đã deprecated do lỗi deadlock/hỏng khóa trên OEM) | Cao |
| **Screen Protection** | Bật `FLAG_SECURE` trên màn hình nhạy cảm + phát hiện Screen Recording trên Android 15 | Chống malware chụp trộm, lộ trong Recent Apps và quay lén màn hình | Cao |
| **Root / Tamper Policy** | Play Integrity API (Device + App verdict) + Cảnh báo rủi ro + tắt sinh trắc học / thanh toán | Chuẩn OWASP MASVS-RESILIENCE v2.0 (thay thế SafetyNet/RootBeer đã lỗi thời), cân bằng an toàn và trải nghiệm | Cao |
| **R8 / Obfuscation** | Bật trong Release build, giữ nguyên mapping file | Làm khó dịch ngược bằng JADX/Apktool | Cao |
| **TLS Minimum** | Bắt buộc TLS 1.2+, ưu tiên TLS 1.3 (cấu hình qua OkHttp `ConnectionSpec`, cấm cleartext qua `network_security_config.xml`) | Vô hiệu hóa các mã hóa cũ; Android 15 chặn sẵn TLS 1.0/1.1 ở socket | Cao |

---

## 5. Mẫu Ghi Hồ Sơ Quyết Định & Giả Định (Security Records)

### Mẫu Ghi Quyết Định Bảo Mật (Decision Record)
```markdown
### DECISION-SEC-[STT]
- **Hạng Mục**: [Assets / Auth / Data Protection / Network / Device / Supply Chain / Threat]
- **Điểm Rủi Ro (Risk Level)**: [CRITICAL / HIGH / MEDIUM]
- **Quyết Định Được Chọn**: [Chính sách thống nhất]
- **Biện Pháp Kỹ Thuật Triển Khai**: [Ví dụ: Thêm network_security_config.xml, OkHttp ConnectionSpec TLS 1.3, Play Integrity API, kích hoạt FLAG_SECURE]
- **Trạng Thái**: `CLOSED`
```

### Mẫu Ghi Giả Định Bảo Mật (Assumption Record)
```markdown
### ASSUMPTION-SEC-[STT]
- **Mã giả định**: `ASSUMPTION-SEC-[STT]`
- **Hạng Mục**: [Ví dụ: Rooted Device Policy / Play Integrity Verdict]
- **Mức Độ Rủi Ro (risk_level)**: `BENIGN` | `CRITICAL`
- **Giả Định Áp Dụng**: Cảnh báo rủi ro người dùng và vô hiệu hóa lưu thông tin phiên trên bộ nhớ đệm khi verdict không đạt chuẩn.
- **Rủi Ro Đánh Đổi**: Người dùng máy can thiệp phải đăng nhập lại mỗi phiên mở app.
- **Tính Thuận Nghịch**: `HIGH`
- **Nhiệm Vụ Kiểm Chứng (Verification Task)**: Kiểm thử với Play Integrity test token trên thiết bị thử nghiệm ở Bước 10.
- **Trạng Thái (status)**: `ACTIVE` | `INVALIDATED` | `SUPERSEDED`
- **Thời Điểm Thu Hồi (invalidated_at)**: null
- **Lý Do Thu Hồi (revocation_reason)**: null
- **Các Phụ Thuộc Hạ Nguồn (downstream_dependencies)**: []
```

---

## 6. Tiêu Chí Hoàn Tất Phỏng Vấn (Exit Gate Criteria)

Agent chỉ được chuyển sang Bước 07 khi:
1. Đã phân loại và xử lý 100% các phát hiện từ Scoped Static Audit (Bước 05).
2. Không chứa bất kỳ câu hỏi nào đòi hỏi người dùng cung cấp bí mật / credentials thật.
3. Toàn bộ các chính sách bảo mật cốt lõi (Root, Cleartext, Storage, Screen) đã được ghi nhận trong `DECISION RECORD` hoặc `ASSUMPTION RECORD`.
4. Danh sách các vùng chưa thể kiểm toán tĩnh được chuyển giao đầy đủ vào `UNKNOWNS_AND_COVERAGE.md`.
