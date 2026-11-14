# HƯỚNG DẪN PHỎNG VẤN CHUYÊN BIỆT: TỐI ƯU HÓA TÍNH NĂNG HIỆN HỮU (FEATURE OPTIMIZATION)
> **Domain**: `FEATURE_OPTIMIZATION`  
> **Áp dụng cho**: Bước 06 (`06_REA_INTERVIEW`) & Bước 07 (`07_SPEC_AND_DESIGN`) thuộc STAGE_03 · PRODUCT DEFINITION  
> **Quy chuẩn**: REA Adaptive Interview Framework · Behavior-Invariant Optimization  

---

## 1. Mục Tiêu & Nguyên Tắc Bất Biến

Hướng dẫn này kích hoạt khi người dùng yêu cầu **tối ưu hóa một tính năng hoặc màn hình cụ thể đang hoạt động** (ví dụ: "Tối ưu hóa màn hình lịch sử giao dịch bị chậm", "Giảm giật lag khi tải giỏ hàng", "Tăng tốc độ tìm kiếm sản phẩm").

Khác với việc viết lại tính năng mới, tối ưu hóa tính năng hiện hữu đòi hỏi **nguyên tắc bảo toàn hành vi tuyệt đối**:
1. **Bảo Toàn Hợp Đồng Nghiệp Vụ (Behavior Invariance)**: Đầu vào (Input) và đầu ra (Output) của tính năng đối với người dùng cuối phải giữ nguyên vẹn 100%; không làm thay đổi logic kinh doanh.
2. **Khoanh Vùng Tác Động Tối Thiểu (Minimal Blast Radius)**: Can thiệp phẫu thuật chính xác tại điểm nghẽn; không gây hiệu ứng gợn sóng (ripple effects) sang các module khác.
3. **Mục Tiêu Định Lượng Cụ Thể (Target Metrics)**: Phải xác định rõ chỉ số đo lường trước và sau khi tối ưu.

---

## 2. Bốn Trụ Cột Tối Ưu Hóa Tính Năng (4 Core Pillars)

```
┌────────────────────────────────────────────────────────────────────────┐
│               4 TRỤ CỘT TỐI ƯU HÓA TÍNH NĂNG HIỆN HỮU                  │
├───────────────────────────────────┬────────────────────────────────────┤
│ 1. PHÂN TÍCH NGUYÊN NHÂN GỐC RỄ   │ 2. BẢO TOÀN HÀNH VI TUYỆT ĐỐI      │
│    (Root Cause Identification)    │    (Strict Behavior Preservation)  │
│    - DB query không index         │    - Giữ nguyên luồng UI           │
│    - Recomposition thừa thãi      │    - Giữ nguyên hợp đồng dữ liệu   │
│    - Xử lý nặng trên UI thread    │    - Kiểm thử hồi quy không trượt  │
├───────────────────────────────────┼────────────────────────────────────┤
│ 3. CHỈ SỐ MỤC TIÊU & RÀO CHẮN     │ 4. PHẠM VI CAN THIỆP PHẪU THUẬT    │
│    (Metric Targets & Guardrails)  │    (Surgical Fix & Blast Radius)   │
│    - Đo lường trước (Before)      │    - Refactor cục bộ               │
│    - Cam kết sau (After KPI)      │    - Cơ chế Fallback an toàn       │
│    - Ngưỡng suy thoái cho phép    │    - Giữ nguyên API công khai      │
└───────────────────────────────────┴────────────────────────────────────┘
```

### 2.1 Phân Tích Nguyên Nhân Gốc Rễ (Root Cause Analysis)
Agent phải tự xác định điểm nghẽn thông qua mã nguồn và profile, rơi vào 5 nhóm nguyên nhân phổ biến:
1. **Nghẽn Luồng Giao Diện (Main Thread Blocking)**: Đọc file, giải mã JSON lớn, tính toán vòng lặp lớn trực tiếp trên UI thread.
2. **Lạm Dụng Tái Dựng Hình (Excessive Recompositions / Layout Passes)**: Trong Jetpack Compose hoặc React, State bị kích hoạt vô tội vạ dẫn đến recompose toàn bộ màn hình thay vì chỉ component con.
3. **Truy Vấn Dữ Liệu Thiếu Hiệu Quả (Database Inefficiencies)**: Thiếu Index trên các cột tìm kiếm thường xuyên; hiện tượng N+1 query khi hiển thị danh sách quan hệ.
4. **Tải Trước Quá Mức (Over-fetching & Memory Hogging)**: Nạp toàn bộ 1.000 bản ghi lên bộ nhớ thay vì phân trang; nạp ảnh kích thước gốc 4K vào ImageView 48dp.
5. **Rò Rỉ Luồng Bất Đồng Bộ (Leaked Coroutines / Subscriptions)**: Đăng ký lắng nghe sự kiện mà không hủy khi màn hình bị đóng.

### 2.2 Bảo Toàn Hành Vi Tuyệt Đối (Behavior Preservation)
- Mọi validation rules cũ (ví dụ: độ dài mật khẩu, định dạng số điện thoại) phải được giữ nguyên.
- Danh sách trạng thái (Loading, Empty, Success, Error) phải hiển thị đúng thời điểm như người dùng quen thuộc.
- Không tự ý bỏ bớt các nút bấm, bộ lọc hoặc thông tin phụ mà người dùng đang sử dụng.

### 2.3 Thiết Lập Chỉ Số Mục Tiêu & Rào Chắn (Metric Targets & Guardrails)
Phải thiết lập bảng cam kết chỉ số trước khi bắt tay vào sửa code:
- *Ví dụ*:
  * Thời gian tải dữ liệu màn hình: Giảm từ **1.800ms ➔ < 250ms**.
  * Tỷ lệ khung hình giật khi cuộn danh sách: Giảm từ **18% janky frames ➔ < 1%**.
  * Dung lượng bộ nhớ đỉnh điểm (Peak RAM): Giảm từ **140MB ➔ < 45MB**.

### 2.4 Ranh Giới Can Thiệp Phẫu Thuật (Surgical Blast Radius)
- Giữ nguyên chữ ký hàm (Function Signature) và ViewModel Interface để các màn hình phụ thuộc không bị vỡ.
- Nếu phải thay đổi cấu trúc bảng cục bộ, phải viết migration tự động hoặc adapter trung gian.

---

## 3. Quy Trình Vận Hành Bộ Lọc Câu Hỏi (Question Necessity Engine)

### 3.1 Những Gì KHÔNG ĐƯỢC Hỏi
- ❌ **CẤM HỎI**: "Code tính năng này bị nghẽn ở hàm nào?" (Vi phạm Inspectable - Agent tự phân tích code và call graph).
- ❌ **CẤM HỎI**: "Có nên thêm Index vào bảng SQLite không?" (Vi phạm Reversibility & Ownership - Đây là việc hiển nhiên Agent phải tự làm).
- ❌ **CẤM HỎI**: "Bạn có muốn chuyển từ LiveData sang StateFlow không?" (Vi phạm Ownership - Người dùng không quan tâm framework reactive nội bộ).

### 3.2 Những Gì ĐƯỢC Hỏi (Xác Nhận Hiện Tượng & Ranh Giới Đánh Đổi)
1. **Xác nhận hiện tượng lỗi/chậm thực tế**:
   - *Ví dụ*: "Bạn thấy màn hình này bị chậm nhất ở thời điểm nào: Lúc vừa bấm mở màn hình, khi gõ từ khóa vào ô tìm kiếm, hay khi cuộn danh sách xuống dưới?"
2. **Đánh đổi giữa bộ nhớ đệm và tính tức thời của dữ liệu**:
   - *Ví dụ*: "Để màn hình hiển thị tức thì (<100ms), chúng tôi sẽ lưu bản sao dữ liệu trong 5 phút. Khi có cập nhật mới, dữ liệu có thể trễ tối đa 5 phút trừ khi người dùng vuốt xuống để làm mới (Pull-to-Refresh). Bạn có đồng ý phương án này không?"
3. **Giới hạn số lượng hiển thị ban đầu**:
   - *Ví dụ*: "Hiện tại app đang cố nạp tất cả dữ liệu một lúc gây đứng hình. Chúng tôi sẽ chuyển sang hiển thị 20 mục đầu tiên và tự động tải tiếp khi cuộn. Điều này có đáp ứng đúng nhu cầu của bạn không?"

---

## 4. Bảng Giả Định Mặc Định An Toàn (Safe Optimization Defaults)

| Vấn Đề Gặp Phải | Giả Định Mặc Định An Toàn | Cơ Sở Kỹ Thuật | Tính Thuận Nghịch |
| :--- | :--- | :--- | :--- |
| **Tìm kiếm bị giật** | Áp dụng Debounce 300ms + DistinctUntilChanged | Ngăn chặn gọi API / Query liên tục mỗi phím gõ | Cao |
| **Màn hình tải chậm** | Nạp dữ liệu trong cache cục bộ trước, gọi mạng ngầm | Pattern Stale-While-Revalidate (SWR) | Cao |
| **Danh sách cuộn lag** | Tái cấu trúc View Recycling + Prefetch 5 items | Đảm bảo mượt mà 60fps khi cuộn nhanh | Cao |
| **Memory Spike ảnh** | Downsample ảnh theo đúng kích thước khung View hiển thị | Tiết kiệm 70-80% RAM đồ họa | Cao |
| **Truy vấn DB chậm** | Thêm composite index cho các cột WHERE/ORDER BY | Tăng tốc truy vấn lên 10-50 lần | Cao |

---

## 5. Mẫu Ghi Hồ Sơ Quyết Định & Giả Định (Optimization Records)

### Mẫu Ghi Quyết Định Tối Ưu (Decision Record)
```markdown
### DECISION-FEAT-OPT-[STT]
- **Tính Năng / Màn Hình**: [Tên tính năng đang tối ưu]
- **Điểm Nghẽn Đã Xác Định (Bottleneck)**: [Ví dụ: UI Thread bị block 800ms khi parse JSON]
- **Giải Pháp Tối Ưu Thống Nhất**: [Ví dụ: Chuyển sang Kotlinx Serialization với Dispatchers.Default]
- **Cam Kết Chỉ Số (KPI Before -> After)**: [Ví dụ: Freeze time từ 800ms -> 12ms]
- **Bảo Đảm Bất Biến (Invariance Guarantee)**: Không thay đổi bất kỳ trường dữ liệu nào hiển thị ra màn hình.
- **Trạng Thái**: `CLOSED`
```

### Mẫu Ghi Giả Định Tối Ưu (Assumption Record)
```markdown
### ASSUMPTION-FEAT-OPT-[STT]
- **Mã giả định**: `ASSUMPTION-FEAT-OPT-[STT]`
- **Tính Năng**: [Tên tính năng]
- **Mức Độ Rủi Ro (risk_level)**: `BENIGN` | `CRITICAL`
- **Giả Định Áp Dụng**: Giữ thời gian đệm debounce ở 300ms cho ô tìm kiếm.
- **Lý Do Áp Dụng**: Cân bằng tối ưu giữa cảm giác gõ mượt và số lượng truy vấn CPU.
- **Tính Thuận Nghịch**: `HIGH`
- **Nhiệm Vụ Kiểm Chứng (Verification Task)**: Thử nghiệm nhập văn bản nhanh trên máy ảo ở Bước 10.
- **Trạng Thái (status)**: `ACTIVE` | `INVALIDATED` | `SUPERSEDED`
- **Thời Điểm Thu Hồi (invalidated_at)**: null
- **Lý Do Thu Hồi (revocation_reason)**: null
- **Các Phụ Thuộc Hạ Nguồn (downstream_dependencies)**: []
```

---

## 6. Tiêu Chí Hoàn Tất Phỏng Vấn (Exit Gate Criteria)

Agent chỉ được chuyển sang Bước 07 khi:
1. Đã chốt danh sách các chỉ số định lượng Before/After.
2. Cam kết 100% không làm thay đổi các quy tắc nghiệp vụ hiện hữu của tính năng.
3. Toàn bộ các giải pháp kỹ thuật đã khoanh vùng được phạm vi can thiệp cục bộ (Surgical Scope), không ảnh hưởng lan truyền.
