# HƯỚNG DẪN PHỎNG VẤN CHUYÊN BIỆT: THÊM TÍNH NĂNG MỚI (FEATURE ADDITION)
> **Domain**: `FEATURE_ADDITION`  
> **Áp dụng cho**: Bước 06 (`06_REA_INTERVIEW`) & Bước 07 (`07_SPEC_AND_DESIGN`) thuộc STAGE_03 · PRODUCT DEFINITION  
> **Quy chuẩn**: REA Adaptive Interview Framework · Outcome-Driven Specification  

---

## 1. Mục Tiêu & Phương Pháp Luận Ba Tầng

Hướng dẫn này kích hoạt khi người dùng yêu cầu **bổ sung một hoặc nhiều tính năng mới hoàn toàn** vào ứng dụng hiện hữu hoặc bản sao tái thiết lập.

Để chống tình trạng suy diễn lan man, phình to phạm vi (scope creep) và thiết kế sáo rỗng, Agent bắt buộc tuân thủ phương pháp luận ba tầng:

```
┌────────────────────────────────────────────────────────────────────────┐
│                   PHƯƠNG PHÁP LUẬN BA TẦNG CHO TÍNH NĂNG MỚI           │
├────────────────────────────────────────────────────────────────────────┤
│ 1. TẦNG KẾT QUẢ NGƯỜI DÙNG (USER OUTCOME SPECIFICATION)                │
│    - Job-to-be-done: Người dùng đạt được giá trị gì?                   │
│    - Persona & Bối cảnh sử dụng                                        │
│    - Tiêu chí thành công định lượng (Success Metrics)                  │
├────────────────────────────────────────────────────────────────────────┤
│ 2. TẦNG QUY CHUẨN HÀNH VI (BEHAVIOR SPECIFICATION)                    │
│    - Luồng thao tác chuẩn (Happy Path) & Điểm kích hoạt                │
│    - Trường hợp biên (Edge Cases) & Xử lý lỗi (Error Handling)         │
│    - Trạng thái Offline, Mạng chập chờn, Xung đột dữ liệu             │
├────────────────────────────────────────────────────────────────────────┤
│ 3. TẦNG ĐẶC TẢ TRIỂN KHAI (IMPLEMENTATION SPECIFICATION)               │
│    - Hợp đồng dữ liệu & Lược đồ cơ sở dữ liệu (Data & Schemas)         │
│    - Ranh giới phạm vi (Scope Boundary & Explicit Non-Goals)          │
│    - Tương tác & Khả năng tương thích ngược (Integration & Back-compat)│
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Chi Tiết Ba Tầng Đặc Tả Tính Năng

### 2.1 Tầng 1: Kết Quả Người Dùng (User Outcome)
- **Công việc cần hoàn thành (Job-to-be-done)**: 
  * "Khi [ngữ cảnh cụ thể], người dùng muốn [thực hiện hành động] để họ có thể [đạt được kết quả giá trị]."
  * Không mô tả giao diện ở tầng này; chỉ tập trung vào mong muốn nghiệp vụ.
- **Đối Tượng Người Dùng (Target Persona)**: Ai là người dùng chính của tính năng này (Người dùng vãng lai, Người dùng đã đăng nhập, Quản trị viên)?
- **Tiêu Chí Thành Công Đo Được**:
  * Tỷ lệ hoàn thành tác vụ (Task completion rate).
  * Thời gian trung bình để người dùng đạt kết quả (Time to task).

### 2.2 Tầng 2: Quy Chuẩn Hành Vi (Behavior Spec)
- **Điểm Kích Hoạt (Entry Points)**: Người dùng bắt đầu tính năng từ đâu (Nút nổi FAB trên màn chính, menu phụ, thông báo đẩy, hay deep link)?
- **Luồng Chuẩn (Happy Path)**:
  * Trình tự từng bước: Bước 1 ➔ Bước 2 ➔ Bước 3 ➔ Xác nhận thành công.
- **Các Trường Hợp Biên (Edge Cases & Corner Cases)**:
  * Người dùng đang thao tác thì mất mạng?
  * Người dùng nhập dữ liệu vượt quá độ dài hoặc ký tự đặc biệt?
  * Người dùng nhấn nút liên tiếp nhiều lần (Double-click / Debounce prevention)?
  * Người dùng chuyển app ra màn hình nền hoặc nhận cuộc gọi đến giữa chừng?
- **Khôi Phục Trạng Thái & Bảo Toàn Dữ Liệu (`RULE-INIT-001`)**:
  * Nếu người dùng đang nhập form mà gặp lỗi hệ thống, form phải giữ nguyên 100% dữ liệu đã nhập, tuyệt đối không bắt người dùng nhập lại từ đầu.

### 2.3 Tầng 3: Đặc Tả Triển Khai (Implementation Spec)
- **Ranh Giới Rõ Ràng & Danh Sách Không Làm (Explicit Non-Goals)**:
  * Ghi rõ danh sách các tính năng liên quan nhưng **CỐ Ý KHÔNG LÀM** trong phiên bản này để tránh vượt ngoài tầm kiểm soát (ví dụ: "Chưa hỗ trợ đồng bộ đám mây realtime, chỉ lưu SQLite cục bộ").
- **Hợp Đồng Dữ Liệu & Lược Đồ (Data Schemas)**:
  * Thực thể mới (Entity/Table), các trường bắt buộc, kiểu dữ liệu, quan hệ (1-1, 1-N).
  * Kế hoạch nâng cấp Migration của SQLite/Room (ví dụ: `RoomDatabase Migration(1, 2)`).
- **Tích Hợp Vào Kiến Trúc Hiện Hữu**:
  * Tính năng mới tác động như thế nào đến các module cũ?
  * Có làm vỡ luồng người dùng đang quen thuộc không?

---

## 3. Quy Trình Vận Hành Bộ Lọc Câu Hỏi (Question Necessity Engine)

### 3.1 Những Gì KHÔNG ĐƯỢC Hỏi
- ❌ **CẤM HỎI**: "Bạn muốn dùng RecyclerView hay Compose LazyColumn để hiển thị danh sách?" (Vi phạm lọc Ownership - người dùng không phải kiến trúc sư code).
- ❌ **CẤM HỎI**: "Bảng dữ liệu cũ trong app đang có những cột nào?" (Vi phạm lọc Inspectable - Agent tự đọc file Schema/DAO hiện tại).
- ❌ **CẤM HỎI**: "Khi có lỗi mạng nên hiện Toast hay Dialog?" (Vi phạm lọc Reversibility & Design System - Agent tự tuân theo `templates/05-DESIGN-TOKEN-TEMPLATE.md` và `03_STATE_COMPOSITION.md`).

### 3.2 Những Gì ĐƯỢC Hỏi (Quyết Định Nghiệp Vụ & Ranh Giới)
1. **Ranh giới tính năng (Feature Boundary & Non-Goals)**:
   - *Ví dụ*: "Tính năng 'Ghi chú công việc' này chỉ cần lưu trữ và tìm kiếm trên thiết bị của bạn, hay có cần đồng bộ qua tài khoản đám mây với người khác?"
2. **Quy tắc nghiệp vụ khi xung đột dữ liệu (Business Rule Conflicts)**:
   - *Ví dụ*: "Khi người dùng tạo một mục trùng tên với mục đã có sẵn trong danh mục, ứng dụng nên: (A) Tự động thêm hậu tố (1, 2), (B) Báo lỗi yêu cầu đổi tên, hay (C) Ghi đè lên mục cũ?"
3. **Quyền truy cập và phân quyền (Access Control & Roles)**:
   - *Ví dụ*: "Tính năng này mở cho tất cả người dùng ngay khi cài app, hay bắt buộc phải tạo tài khoản và đăng nhập trước?"

---

## 4. Bảng Giả Định Mặc Định An Toàn (Safe Feature Defaults)

Khi người dùng chỉ yêu cầu một tính năng ngắn gọn ("Hãy thêm tính năng tìm kiếm"), Agent áp dụng các mặc định chuẩn công nghiệp sau:

| Khía Cạnh | Giả Định Mặc Định | Cơ Sở Kỹ Thuật | Tính Thuận Nghịch |
| :--- | :--- | :--- | :--- |
| **Lưu Trữ Dữ Liệu** | Lưu cục bộ SQLite/Room trước | Đảm bảo tính khả dụng ngay, không phụ thuộc server | Cao |
| **Tìm Kiếm / Lọc** | Instant Filter (Debounce 300ms) | Tránh giật UI, tìm kiếm tức thì theo chữ gõ | Cao |
| **Xử Lý Mạng** | Offline-first với hàng đợi Sync | Trải nghiệm không gián đoạn khi mạng kém | Cao |
| **Xóa Dữ Liệu** | Soft-delete hoặc Dialog xác nhận phá hủy | Chống xóa nhầm dữ liệu quan trọng | Cao |
| **Phân Trang** | 20 bản ghi mỗi trang (Pagination) | Tối ưu RAM và hiệu năng danh sách | Cao |
| **Tương Thích Ngược** | Tự động sinh `Migration` giữ nguyên dữ liệu cũ | Tuân thủ bảo vệ dữ liệu người dùng | Trung bình |

---

## 5. Mẫu Ghi Hồ Sơ Quyết Định & Giả Định (Feature Records)

### Mẫu Ghi Quyết Định Tính Năng (Decision Record)
```markdown
### DECISION-FEAT-[STT]
- **Tên Tính Năng**: [Tên tính năng]
- **Vấn Đề / Nghiệp Vụ Cần Chốt**: [Quy tắc nghiệp vụ hoặc phạm vi]
- **Quyết Định Được Chọn**: [Lựa chọn thống nhất]
- **Ranh Giới Non-Goals**: [Những gì cố tình KHÔNG làm]
- **Tác Động Tới Schema/API**: [Thêm bảng mới, sửa API...]
- **Trạng Thái**: `CLOSED`
```

### Mẫu Ghi Giả Định Tính Năng (Assumption Record)
```markdown
### ASSUMPTION-FEAT-[STT]
- **Mã giả định**: `ASSUMPTION-FEAT-[STT]`
- **Tên Tính Năng**: [Tên tính năng]
- **Mức Độ Rủi Ro (risk_level)**: `BENIGN` | `CRITICAL`
- **Giả Định Mặc Định Đã Áp Dụng**: [Ví dụ: Giới hạn tìm kiếm 20 kết quả gần nhất]
- **Lý Do Áp Dụng**: Người dùng không cung cấp giới hạn số lượng; áp dụng chuẩn hiệu năng.
- **Tính Thuận Nghịch**: `HIGH`
- **Nhiệm Vụ Kiểm Chứng (Verification Task)**: Kiểm tra hiệu năng tìm kiếm với 1.000 bản ghi giả lập ở Bước 10.
- **Trạng Thái (status)**: `ACTIVE` | `INVALIDATED` | `SUPERSEDED`
- **Thời Điểm Thu Hồi (invalidated_at)**: null
- **Lý Do Thu Hồi (revocation_reason)**: null
- **Các Phụ Thuộc Hạ Nguồn (downstream_dependencies)**: []
```

---

## 6. Tiêu Chí Hoàn Tất Phỏng Vấn (Exit Gate Criteria)

Agent chỉ được chuyển sang Bước 07 khi:
1. Đã hoàn thành cả 3 tầng: Kết quả người dùng, Quy chuẩn hành vi và Đặc tả triển khai.
2. Đã xác định rõ ràng danh sách Non-Goals (Không làm gì).
3. Hợp đồng dữ liệu (Lược đồ bảng, model dữ liệu) đã được thiết kế không phá vỡ cấu trúc cũ.
4. Đã sẵn sàng xuất bản `03_KET_QUA_KIEM_TRA/dac-ta-yeu-cau-da-chot.md` kèm 4 trạng thái giao diện bắt buộc cho tính năng mới.
