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

## 3. ĐÁNH GIÁ BẢO MẬT CÓ PHẠM VI (SCOPED SECURITY REVIEW)
*Lưu ý: Phân tích tĩnh có giới hạn, không chứng nhận an toàn 100%*

| Hạng mục | Hiện trạng phát hiện | Đánh giá rủi ro |
| :--- | :--- | :--- |
| **Quyền hạn hệ thống** | [Liệt kê các quyền yêu cầu] | [Thấp / Trung bình / Cao] |
| **Bảo vệ dữ liệu & API** | [Đường dẫn API, tokens tìm thấy (đã che mờ [REDACTED])] | [An toàn / Cần khắc phục] |
| **Kết nối mạng** | [HTTPS / HTTP không an toàn] | [Đánh giá] |

---

## 4. GIỚI HẠN & CÁC ĐIỂM CHƯA RÕ (UNKNOWNS)
- [Các thành phần cần môi trường chạy thật (runtime/ADB) mới kiểm tra được]
- [Các thư viện mã hóa hoặc dịch ngược chưa giải mã được]
