# BÁO CÁO PHÂN TÍCH HIỆN TRẠNG & BẢO MẬT ỨNG DỤNG
*Ngày lập: [YYYY-MM-DD HH:mm] | Mã phân tích: [CASE_ID]*

---

## 1. THÔNG TIN CHUNG
- **Tên tệp / Ứng dụng:** [Tên ứng dụng]
- **Định dạng nhận diện:** [APK / Electron ASAR / Web / Binary / Mã nguồn]
- **Công nghệ / Ngôn ngữ:** [JavaScript / Java / C++ / Python...]
- **Công cụ REA sử dụng:** [inspect_android_package / analyze_javascript_application...]
- **Trạng thái sao lưu gốc:** [Đã sao lưu an toàn sang 04_SAO_LUU_AN_TOAN]

---

## 2. BẢN ĐỒ TÍNH NĂNG ĐÃ XÁC MINH (FEATURE MAP)
*Chỉ liệt kê các chức năng có bằng chứng thực tế từ mã nguồn hoặc phân tích tĩnh*

- [x] **Tính năng 1:** [Mô tả chi tiết và luồng hoạt động]
- [x] **Tính năng 2:** [Mô tả chi tiết và luồng hoạt động]
- [ ] **Tính năng chưa hoàn thiện:** [Mô tả các phần mã nguồn còn dở dang]

---

## 3. DANH MỤC MÀN HÌNH (SCREEN INVENTORY) & MA TRẬN TRẠNG THÁI (STATE MATRIX)
*(Quy chuẩn từ app-adr-ui: Cơ sở kiến trúc luồng để tái tạo chính xác giao diện)*

### 3.1. Danh mục màn hình chức năng (Functional Screen Inventory)
| Mã màn hình | Tên màn hình / Node | Mục đích / Chức năng chính | Điều kiện vào (Entry) | Hành động người dùng (Buttons/Inputs) | Đích chuyển tiếp (Exit) |
|---|---|---|---|---|---|
| `SCR-01` | [Màn hình chính / Trang chủ] | [Mô tả mục đích chính] | [Khởi động ứng dụng] | [Bấm nút Xem, Tạo mới, Lọc] | `SCR-02`, `SCR-03` |
| `SCR-02` | [Màn hình chi tiết / Form] | [Nhập liệu hoặc hiển thị] | [Bấm từ SCR-01] | [Lưu, Hủy, Quay lại] | `SCR-01` |

### 3.2. Ma trận trạng thái & Xử lý ngoại lệ (State & Exception Matrix)
| Mã MH | Trạng thái (State) | Kích hoạt (Trigger) | Hành vi giao diện (UI Behavior) | Luồng phục hồi (Recovery Path) |
|---|---|---|---|---|
| `SCR-01` | **Loading** | Khi bắt đầu tải dữ liệu | Hiện khung xương xám nhấp nháy (Skeleton) | Chờ tối đa 10s chuyển sang Error |
| `SCR-01` | **Empty** | Khi chưa có mục nào | Hiện biểu tượng rỗng + nút "Tạo mới" | Nhấp nút chuyển sang `SCR-02` |
| `SCR-01` | **Error** | Mất mạng hoặc lỗi đọc | Banner đỏ thông báo lỗi dễ hiểu | Nút "Thử lại" nạp lại dữ liệu |
| `SCR-01` | **Success** | Tải dữ liệu thành công | Hiển thị bảng danh sách đầy đủ | Hoạt động bình thường |

---

## 4. ĐÁNH GIÁ BẢO MẬT CÓ PHẠM VI (SCOPED SECURITY REVIEW)
*Lưu ý: Phân tích tĩnh có giới hạn, không chứng nhận an toàn 100%*

| Hạng mục | Hiện trạng phát hiện | Đánh giá rủi ro |
| :--- | :--- | :--- |
| **Quyền hạn hệ thống** | [Liệt kê các quyền yêu cầu] | [Thấp / Trung bình / Cao] |
| **Bảo vệ dữ liệu & API** | [Đường dẫn API, tokens tìm thấy (đã che mờ [REDACTED])] | [An toàn / Cần khắc phục] |
| **Kết nối mạng** | [HTTPS / HTTP không an toàn] | [Đánh giá] |

---

## 5. GIỚI HẠN & CÁC ĐIỂM CHƯA RÕ (UNKNOWNS)
- [Các thành phần cần môi trường chạy thật (runtime/ADB) mới kiểm tra được]
- [Các thư viện mã hóa hoặc dịch ngược chưa giải mã được]
