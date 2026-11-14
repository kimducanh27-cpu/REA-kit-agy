# HƯỚNG DẪN PHỎNG VẤN CHUYÊN BIỆT: KHẮC PHỤC LỖI & SỰ CỐ (BUG FIX)
> **Domain**: `BUG_FIX`  
> **Áp dụng cho**: Bước 06 (`06_REA_INTERVIEW`) & Bước 07 (`07_SPEC_AND_DESIGN`) thuộc STAGE_03 · PRODUCT DEFINITION  
> **Quy chuẩn**: REA Adaptive Interview Framework · Defect Triage & Root-Cause Elimination  

---

## 1. Mục Tiêu & Phạm Vi Phỏng Vấn

Hướng dẫn này kích hoạt khi mục tiêu chính là **sửa lỗi (bug fix), triệt tiêu sự cố treo ứng dụng (crash), khắc phục lỗi rò rỉ dữ liệu hoặc sai lệch hiển thị**.

Khác với việc xây dựng mới, quy trình sửa lỗi đòi hỏi tính chính xác pháp y (forensic precision) cao:
- **Tái hiện xác thực (Deterministic Reproduction)** trước khi sửa.
- **Xác định nguyên nhân gốc rễ (Root Cause)**, không chỉ che đậy triệu chứng (symptom masking).
- **Rào chắn chống tái phát (Regression Defense)** bằng bài kiểm thử tự động.

---

## 2. Năm Trụ Cột Khắc Phục Lỗi (5 Diagnostic Pillars)

```
┌────────────────────────────────────────────────────────────────────────┐
│                        5 TRỤ CỘT KHẮC PHỤC LỖI TRIỆT ĐỂ                │
├───────────────────┬───────────────────┬────────────────────────────────┤
│ 1. REPRODUCTION   │ 2. ROOT CAUSE     │ 3. IMPACT & BLAST RADIUS       │
│ - Steps to repro  │ - Stack trace     │ - Severity rating              │
│ - Device matrix   │ - Race condition  │ - Affected user journeys       │
│ - Minimal case    │ - Lifecycle leak  │ - Secondary damage risks       │
├───────────────────┴───────────────────┴────────────────────────────────┤
│ 4. FIX BOUNDARY & STRATEGY                                             │
│    - Localized patch vs Refactoring                                    │
│    - Defensive null-safety & Graceful degradation                     │
│    - Data protection invariance                                        │
├────────────────────────────────────────────────────────────────────────┤
│ 5. VERIFICATION & REGRESSION DEFENSE                                   │
│    - Automated regression test                                         │
│    - Verification checklist for Stage 05 Hard Verify                   │
└────────────────────────────────────────────────────────────────────────┘
```

### 2.1 Tái Hiện Xác Thực (Deterministic Reproduction)
- **Trình Tự Từng Bước (Step-by-step Steps to Reproduce - STR)**:
  1. Trạng thái bắt đầu (Pre-conditions: ví dụ: tài khoản mới, chưa có dữ liệu hoặc đang tắt Wi-Fi).
  2. Hành động thực hiện (Actions).
  3. Kết quả thực tế quan sát được (Actual Result).
  4. Kết quả mong đợi đúng chuẩn (Expected Result).
- **Môi Trường Xảy Ra Lỗi**: Phiên bản OS (Android 12/13/14), dòng thiết bị (Samsung, Xiaomi, Pixel), kích thước màn hình, hoặc trạng thái mạng.

### 2.2 Phân Tích Nguyên Nhân Gốc Rễ (Root Cause Analysis - RCA)
Agent phân loại lỗi theo bản chất kỹ thuật:
- **Lỗi Vòng Đời (Lifecycle & State Invalidation)**: Gọi cập nhật UI khi Fragment/Activity đã bị destroy; Coroutine chạy trên `GlobalScope` thay vì `lifecycleScope`.
- **Lỗi Đua Điều Kiện (Race Condition / Concurrency)**: Hai luồng cùng đọc ghi vào một danh sách không đồng bộ (ConcurrentModificationException).
- **Lỗi Kiểu Dữ Liệu & Nullability**: Trường dữ liệu từ API bất ngờ trả về `null` hoặc sai kiểu (String thay vì Int).
- **Lỗi Bộ Nhớ & Rò Rỉ (Memory Leak / Out of Memory)**: Giữ tham chiếu Context lâu dài trong Singletons.
- **Lỗi Logic Nghiệp Vụ (Off-by-one, Edge Condition)**: Điều kiện vòng lặp sai, so sánh chuỗi bằng `==` thay vì `equals()`.

### 2.3 Đánh Giá Mức Độ Ảnh Hưởng & Bán Kính Tác Động (Impact & Blast Radius)
- **Phân Loại Mức Độ Nghiêm Trọng (Severity Rating)**:
  * `P0 - CRITICAL`: Treo app ngay khi mở (Crash on launch), mất dữ liệu người dùng, lỗ hổng bảo mật nghiêm trọng.
  * `P1 - HIGH`: Tính năng cốt lõi bị chặn, người dùng không thể hoàn thành thanh toán hoặc đặt hàng.
  * `P2 - MEDIUM`: Tính năng phụ bị lỗi, có giải pháp thay thế tạm thời (workaround).
  * `P3 - LOW`: Lỗi giao diện nhỏ, lệch pixel, sai lỗi chính tả nhưng không chặn luồng thao tác.
- **Bán Kính Lan Truyền (Blast Radius)**: Việc sửa lỗi ở module này có nguy cơ làm lỗi các module phụ thuộc không?

### 2.4 Ranh Giới Sửa Lỗi & Chiến Lược Khắc Phục (Fix Boundary & Strategy)
- **Quy Tắc Chống "Che Giấu Lỗi" (No Symptom Masking)**:
  * ❌ *CẤM*: Bọc toàn bộ code trong `try { ... } catch (e: Exception) { /* swallow */ }` mà không xử lý hoặc không hiển thị thông báo.
  * ✅ *BẮT BUỘC*: Sửa tận gốc điều kiện gây lỗi; bổ sung cơ chế phục hồi mềm (Graceful Recovery) kèm logging rõ ràng.
- **Bảo Vệ Dữ Liệu**: Tuyệt đối không xóa dữ liệu người dùng cũ để "chữa cháy" lỗi.

### 2.5 Rào Chắn Kiểm Thử Chống Tái Phát (Regression Defense)
- Viết ít nhất một bài kiểm thử tự động (Unit Test hoặc Integration Test) chứng minh lỗi đã được tái hiện trước khi sửa và vượt qua sau khi sửa.
- Bổ sung bước kiểm tra vào tài liệu nghiệm thu `03_KET_QUA_KIEM_TRA/BAO_CAO_NGHIEM_THU_HARD_VERIFY.md`.

---

## 3. Quy Trình Vận Hành Bộ Lọc Câu Hỏi (Question Necessity Engine)

### 3.1 Những Gì KHÔNG ĐƯỢC Hỏi
- ❌ **CẤM HỎI**: "Call stack báo lỗi ở dòng code nào?" (Vi phạm Inspectable - Agent tự đọc file logcat hoặc stack trace).
- ❌ **CẤM HỎI**: "Bạn có thể tự debug trong IDE để gửi log không?" (Vi phạm Ownership - Agent tự phân tích tĩnh và dựng kịch bản tái hiện).
- ❌ **CẤM HỎI**: "Nên bắt NullPointerException hay check null trước?" (Vi phạm Ownership - Agent tự áp dụng Kotlin Null Safety).

### 3.2 Những Gì ĐƯỢC Hỏi (Thu Thập Dấu Hiệu Tái Hiện Chưa Rõ)
1. **Trình tự thao tác người dùng dẫn đến lỗi**:
   - *Ví dụ*: "Sự cố này xảy ra ngay khi bạn vừa nhấn nút 'Thanh Toán' hay sau khi hộp thoại ngân hàng xuất hiện và bạn nhấn 'Hủy'?"
2. **Tần suất xuất hiện (Reproduction Frequency)**:
   - *Ví dụ*: "Lỗi này xảy ra 100% mọi lần bạn thao tác, hay chỉ thỉnh thoảng xuất hiện khi kết nối mạng 4G không ổn định?"
3. **Kỳ vọng hành vi đúng đắn (Expected Behavior Clarification)**:
   - *Ví dụ*: "Khi thẻ tín dụng hết hạn hoặc không đủ tiền, app nên hiển thị thông báo lỗi cụ thể để người dùng đổi thẻ khác, hay tự động chuyển về trang giỏ hàng?"

---

## 4. Bảng Giả Định Mặc Định Khi Sửa Lỗi (Safe Bug Fix Defaults)

| Tình Huống Lỗi | Giả Định Mặc Định An Toàn | Cơ Sở Kỹ Thuật | Tính Thuận Nghịch |
| :--- | :--- | :--- | :--- |
| **API trả về Null bất ngờ** | Hiển thị Empty State hoặc giá trị fallback an toàn | Chống Crash ứng dụng (NPE) | Cao |
| **Mất kết nối giữa chừng** | Lưu draft dữ liệu và hiện nút "Thử lại" | Giữ nguyên dữ liệu theo `RULE-INIT-001` | Cao |
| **Xung đột phiên bản DB** | Fallback với Migration schema bảo toàn cột | Tuyệt đối không `fallbackToDestructiveMigration` | Trung bình |
| **Bấm nút nhanh nhiều lần** | Debounce nút bấm 500ms | Chống duplicate transaction | Cao |

---

## 5. Mẫu Ghi Hồ Sơ Quyết Định & Giả Định (Bug Fix Records)

### Mẫu Ghi Quyết Định Sửa Lỗi (Decision Record)
```markdown
### DECISION-BUG-[STT]
- **Mã Lỗi / Tên Sự Cố**: [Ví dụ: Crash khi bấm Back lúc đang tải ảnh]
- **Mức Độ Nghiêm Trọng**: `P0 - CRITICAL`
- **Nguyên Nhân Gốc Rễ (RCA)**: [Ví dụ: Fragment view bị hủy nhưng callback Glide vẫn gọi gán bitmap vào view rỗng]
- **Chiến Lược Khắc Phục**: [Ví dụ: Bọc callback trong viewLifecycleOwner và kiểm tra isAdded]
- **Bài Kiểm Thử Hồi Quy**: [Tên hàm test tự động kiểm chứng]
- **Trạng Thái**: `CLOSED`
```

### Mẫu Ghi Giả Định Sửa Lỗi (Assumption Record)
```markdown
### ASSUMPTION-BUG-[STT]
- **Mã giả định**: `ASSUMPTION-BUG-[STT]`
- **Mã Lỗi**: [Ví dụ: BUG-002: Sai định dạng ngày tháng]
- **Mức Độ Rủi Ro (risk_level)**: `BENIGN` | `CRITICAL`
- **Giả Định Áp Dụng**: Sử dụng Locale mặc định của thiết bị kèm định dạng ISO-8601 dự phòng.
- **Lý Do Áp Dụng**: Người dùng không cung cấp định dạng ngày cụ thể; ISO-8601 là chuẩn quốc tế.
- **Tính Thuận Nghịch**: `HIGH`
- **Nhiệm Vụ Kiểm Chứng (Verification Task)**: Chạy test case với 5 Locale khác nhau (vi_VN, en_US, ja_JP...) ở Bước 10.
- **Trạng Thái (status)**: `ACTIVE` | `INVALIDATED` | `SUPERSEDED`
- **Thời Điểm Thu Hồi (invalidated_at)**: null
- **Lý Do Thu Hồi (revocation_reason)**: null
- **Các Phụ Thuộc Hạ Nguồn (downstream_dependencies)**: []
```

---

## 6. Tiêu Chí Hoàn Tất Phỏng Vấn (Exit Gate Criteria)

Agent chỉ được chuyển sang Bước 07 khi:
1. Đã có kịch bản tái hiện lỗi rõ ràng (STR) và xác định được nguyên nhân gốc rễ.
2. Đã xác định mức độ nghiêm trọng (Severity) và khoanh vùng bán kính tác động.
3. Có cam kết phương án kiểm thử tự động ngăn chặn lỗi tái phát.
4. Sẵn sàng tích hợp kịch bản kiểm thử vào `03_KET_QUA_KIEM_TRA/dac-ta-yeu-cau-da-chot.md`.
