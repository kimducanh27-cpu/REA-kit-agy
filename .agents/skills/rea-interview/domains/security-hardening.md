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
- **Lưu Trữ Khóa Xác Thực**:
  * Lưu trữ Token trong Android Keystore thông qua `EncryptedSharedPreferences` / `EncryptedFile`.
  * Không bao giờ lưu token dạng text thuần trong `SharedPreferences` hoặc SQLite.
- **Tích Hợp Sinh Trắc Học (Biometrics)**:
  * Sử dụng `BiometricPrompt` chuẩn của AndroidX với cờ bảo mật phần cứng (`BIOMETRIC_STRONG` / CryptoObject).

### 2.3 Data Protection (Bảo Vệ Dữ Liệu Tại Chỗ & Chống Rò Rỉ)
- **Mã Hóa Dữ Liệu Lưu Cục Bộ (At-Rest Encryption)**:
  * Cơ sở dữ liệu SQLite/Room tích hợp SQLCipher với khóa sinh ngẫu nhiên lưu trong Android Keystore.
- **Chống Rò Rỉ Màn Hình & Bộ Nhớ Tạm**:
  * Áp dụng `FLAG_SECURE` trên các Activity / Composable nhạy cảm (thông tin tài khoản, mật khẩu, OTP) để chặn chụp màn hình và hiển thị trong danh sách ứng dụng gần đây (Recent Apps Preview).
  * Xóa sạch bộ nhớ đệm clipboard sau khoảng thời gian ngắn (30s - 60s) nếu app có tính năng sao chép nhạy cảm.
  * Làm sạch mảng ký tự mật khẩu (`char[]` scrubbing) ngay sau khi sử dụng, tránh lưu `String` bất biến trong heap.

### 2.4 Network Security (An Ninh Giao Thức Mạng)
- **Cấm Hoàn Toàn Giao Thức Kém An Toàn (Cleartext Ban)**:
  * Thiết lập `android:usesCleartextTraffic="false"` trong `AndroidManifest.xml`.
  * Cấu hình tường minh `network_security_config.xml` chỉ chấp nhận HTTPS (TLS 1.2 / TLS 1.3).
- **Ghim Chứng Chỉ (Certificate Pinning)**:
  * Đánh giá nhu cầu Certificate Pinning cho các API tối quan trọng để chống tấn công nghe lén (Man-In-The-Middle - MITM).
  * Chuẩn bị sẵn cơ chế chứng chỉ dự phòng (Backup Pin) để tránh brick ứng dụng khi máy chủ đổi chứng chỉ SSL.
- **Xác Thực Đầu Vào & Chống Replay**: Kiểm tra định dạng payload API đầu vào, áp dụng Timestamp / Nonce nếu cần.

### 2.5 Device & Runtime Integrity (Tính Toàn Vẹn Thiết Bị & Thời Gian Chạy)
- **Chính Sách Thiết Bị Đã Bị Can Thiệp (Root / Tamper Policy)**:
  * Xác định chính sách ứng xử khi máy bị Root hoặc cài ROM tùy biến:
    * Phương án A (Nghiêm ngặt): Khóa ứng dụng hoàn toàn.
    * Phương án B (Cảnh báo & Giảm cấp): Cảnh báo người dùng và vô hiệu hóa các tính năng nhạy cảm (sinh trắc học, thanh toán).
    * Phương án C (Chấp nhận): Cho phép hoạt động bình thường, người dùng tự chịu rủi ro.
- **Chống Đính Kèm Debugger & Hooking**: Phát hiện debugger trong bản Release build, phát hiện công cụ hook phổ biến (Frida, Xposed) trong phạm vi an toàn.
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
1. **Chính sách ứng xử với máy Root/Jailbreak**:
   - *Ví dụ*: "Ứng dụng xử lý thế nào khi phát hiện thiết bị đã bị Root: (A) Chặn mở app hoàn toàn, (B) Cảnh báo rủi ro nhưng vẫn cho dùng, hay (C) Tắt tính năng bảo mật sinh trắc học và thanh toán?"
2. **Chính sách chụp ảnh màn hình (Screen Capture Policy)**:
   - *Ví dụ*: "Bạn có muốn áp dụng chế độ chống chụp màn hình (`FLAG_SECURE`) cho toàn bộ app hay chỉ các màn hình nhạy cảm (Cài đặt, Ví, Đăng nhập)?"
3. **Tiêu chuẩn tuân thủ bắt buộc (Compliance Requirements)**:
   - *Ví dụ*: "Ứng dụng có bắt buộc tuân thủ tiêu chuẩn đặc thù nào không (ví dụ: PCI-DSS cho thanh toán, GDPR bảo vệ dữ liệu người dùng EU, hoặc quy chuẩn an ninh nội bộ công ty)?"

---

## 4. Bảng Giả Định Mặc Định An Toàn (Safe Security Defaults)

| Hạng Mục | Giả Định Mặc Định An Toàn | Lý Do Kỹ Thuật | Tính Thuận Nghịch |
| :--- | :--- | :--- | :--- |
| **Cleartext Traffic** | CẤM HOÀN TOÀN (`false`) | Chống nghe lén mật khẩu và dữ liệu trên Wi-Fi công cộng | Trung bình |
| **Sensitive Storage** | `EncryptedSharedPreferences` + Keystore | Chuẩn Android khuyến nghị, khóa phần cứng | Cao |
| **Screen Protection** | Bật `FLAG_SECURE` trên màn hình chứa thông tin nhạy cảm | Chống malware chụp trộm và lộ trong Recent Apps | Cao |
| **Root Policy** | Cảnh báo cảnh giác + tắt sinh trắc học | Cân bằng giữa an toàn và trải nghiệm người dùng | Cao |
| **R8 / Obfuscation** | Bật trong Release build, giữ nguyên mapping file | Làm khó dịch ngược bằng JADX/Apktool | Cao |
| **TLS Minimum** | Bắt buộc TLS 1.2+, ưu tiên TLS 1.3 | Vô hiệu hóa các mã hóa cũ bị phá vỡ (SSLv3, TLS 1.0) | Cao |

---

## 5. Mẫu Ghi Hồ Sơ Quyết Định & Giả Định (Security Records)

### Mẫu Ghi Quyết Định Bảo Mật (Decision Record)
```markdown
### DECISION-SEC-[STT]
- **Hạng Mục**: [Assets / Auth / Data Protection / Network / Device / Supply Chain / Threat]
- **Điểm Rủi Ro (Risk Level)**: [CRITICAL / HIGH / MEDIUM]
- **Quyết Định Được Chọn**: [Chính sách thống nhất]
- **Biện Pháp Kỹ Thuật Triển Khai**: [Ví dụ: Thêm network_security_config.xml, kích hoạt FLAG_SECURE]
- **Trạng Thái**: `CLOSED`
```

### Mẫu Ghi Giả Định Bảo Mật (Assumption Record)
```markdown
### ASSUMPTION-SEC-[STT]
- **Hạng Mục**: [Ví dụ: Rooted Device Policy]
- **Giả Định Áp Dụng**: Cảnh báo rủi ro người dùng và vô hiệu hóa lưu thông tin phiên trên bộ nhớ đệm.
- **Rủi Ro Đánh Đổi**: Người dùng máy root phải đăng nhập lại mỗi phiên mở app.
- **Nhiệm Vụ Kiểm Chứng (Verification Task)**: Kiểm thử trên máy ảo đã cấp quyền root ở Bước 10.
- **Trạng Thái**: `ACCEPTED_BY_DEFAULT`
```

---

## 6. Tiêu Chí Hoàn Tất Phỏng Vấn (Exit Gate Criteria)

Agent chỉ được chuyển sang Bước 07 khi:
1. Đã phân loại và xử lý 100% các phát hiện từ Scoped Static Audit (Bước 05).
2. Không chứa bất kỳ câu hỏi nào đòi hỏi người dùng cung cấp bí mật / credentials thật.
3. Toàn bộ các chính sách bảo mật cốt lõi (Root, Cleartext, Storage, Screen) đã được ghi nhận trong `DECISION RECORD` hoặc `ASSUMPTION RECORD`.
4. Danh sách các vùng chưa thể kiểm toán tĩnh được chuyển giao đầy đủ vào `UNKNOWNS_AND_COVERAGE.md`.
