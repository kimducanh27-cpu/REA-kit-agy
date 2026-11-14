# HƯỚNG DẪN KHỞI CHẠY ỨNG DỤNG (RUN GUIDE)
*(Dành cho người dùng phổ thông — Độ dài: đúng 1 trang)*

---

## 1. CÁCH MỞ VÀ KHỞI CHẠY ỨNG DỤNG (RUN GUIDE THEO ROUTE)

### A. Đối với Route A — Web App Zero-Install (Mặc định)
👉 **Cách đơn giản nhất:**
- Tìm tệp `index.html` (hoặc `preview.html` nếu đang xem thử) trong thư mục `05_MA_NGUON_PHAT_TRIEN/`.
- **Nhấp đúp chuột** vào file để mở trực tiếp trên trình duyệt web (Google Chrome, Microsoft Edge, Cốc Cốc, Safari).
- Ứng dụng sẽ hoạt động ngay lập tức mà không cần cài đặt Node.js, Python hay Docker!

### B. Đối với Route B — Android Native Project (Gradle / Android CLI)
👉 **Khởi chạy trên máy ảo AVD hoặc thiết bị thật:**
1. **Kiểm tra thiết bị kết nối:**
   - Sử dụng Antigravity Device Hub hoặc chạy lệnh:
     ```powershell
     adb devices
     ```
2. **Biên dịch & Cài đặt qua Gradle:**
   - Mở terminal tại thư mục `05_MA_NGUON_PHAT_TRIEN/android/`:
     ```powershell
     ./gradlew assembleDebug
     ./gradlew installDebug
     ```
3. **Khởi chạy & Kiểm tra giao diện qua Android CLI:**
   - Khởi chạy ứng dụng: gọi REA ADB `start_adb_app` (tham số `serial`, `package`) hoặc mở từ màn hình chính.
   - Chụp ảnh màn hình kiểm chứng: `android screen capture -o baseline/screen.png`.
   - Bóc tách phân cấp giao diện: `android layout`.

---

## 2. 💡 BẢN GIẢI THÍCH CHO NGƯỜI DÙNG (PLAIN-LANGUAGE EXPLAINER)
*(Nguyên tắc Explainers Over Diffs: Hiểu rõ thay đổi mà không cần đọc code)*

1. **Tôi vừa sửa / thêm những gì?**
   - [Tóm tắt ngắn gọn các chức năng mới hoặc lỗi vừa sửa bằng ngôn ngữ đời thường]
2. **Tại sao lại thực hiện thay đổi này?**
   - [Nêu lý do theo mong muốn đã chốt với người dùng]
3. **Khi mở lên, bạn sẽ thấy khác biệt ở đâu?**
   - [Chỉ rõ vị trí nút bấm, màu sắc, thanh điều hướng để người dùng nhận diện ngay]

---

## 3. CÁC THAO TÁC CẦN NHẤP THỬ
1. **[Tên tính năng 1]:** [Hướng dẫn người dùng bấm vào đâu để kiểm tra kết quả]
2. **[Tên tính năng 2]:** [Hướng dẫn người dùng nhập liệu hoặc lưu dữ liệu]

---

## 4. LƯU Ý BẢO MẬT & DỮ LIỆU
- Toàn bộ dữ liệu của bạn được lưu cục bộ trên trình duyệt máy bạn (LocalStorage/IndexedDB).
- Phân loại rủi ro: [LOW / MEDIUM / HIGH] (Kiểm tra tại `KET_QUA_KIEM_THU.md`).

---

## 5. XỬ LÝ KHI GẶP LỖI & HOÀN TÁC 1-CLICK
- Nếu giao diện chưa cập nhật: Nhấn phím `Ctrl + F5` để làm mới bộ nhớ đệm trình duyệt.
- **Nếu không vừa ý hoặc phát sinh lỗi lạ:**
  👉 Nhấp đúp chuột vào file **`HOAN_TAC.bat`** ở thư mục gốc để khôi phục tức thì về phiên bản chạy tốt trước đó!
