---
name: rea-app-inspector
description: Kiểm tra và phân tích ứng dụng toàn diện bằng REA (Reverse Engineer Anything), xuất báo cáo tính năng và bảo mật, hỏi người dùng nhu cầu nâng cấp/viết lại, và lập kế hoạch phát triển. Kích hoạt khi người dùng yêu cầu kiểm tra app, phân tích file trong 01_THA_APP_VAO_DAY, hoặc muốn nâng cấp/viết lại ứng dụng.
---

# KỸ NĂNG: KIỂM TRA & NÂNG CẤP ỨNG DỤNG BẰNG REA (REA-APP-INSPECTOR)

Kỹ năng này kết hợp sức mạnh phân tích của **REA (morluto/rea)** với quy trình phát triển an toàn, phục vụ người dùng từ tiếp nhận ứng dụng đến hoàn thiện mã nguồn.

---

## 1. QUY TRÌNH THỰC THI CHI TIẾT

```
[01_THA_APP_VAO_DAY]
         │
         ▼
[1. Tiếp nhận & Định tuyến] ──► [Sao lưu vào 04_SAO_LUU_AN_TOAN]
         │
         ▼
[2. Phân tích qua REA / Mã nguồn]
         │
         ▼
[3. Xuất Báo cáo & Đánh giá bảo mật vào 03_KET_QUA_KIEM_TRA]
         │
         ▼
[4. Phỏng vấn người dùng: Thiếu gì? Nâng cấp gì? Viết lại hay giữ?]
         │
         ▼
[5. Triển khai mã nguồn vào 05_MA_NGUON_PHAT_TRIEN & Kiểm thử]
```

---

## 2. BƯỚC 1: TIẾP NHẬN & ĐỊNH TUYẾN MỤC TIÊU (ROUTE TARGET)

Kiểm tra thư mục `01_THA_APP_VAO_DAY/` để nhận diện định dạng:

1. **Gói Electron / JavaScript (`.asar` hoặc thư mục JS):**
   * Sử dụng công cụ REA: `analyze_javascript_application` hoặc lệnh ngầm `npx -y rea-agents analyze-javascript-application <đường_dẫn> --json`.
2. **File cài đặt Android (`.apk`):**
   * Sử dụng công cụ REA: `inspect_android_package`.
3. **File nén / Archive / Nhị phân (`.zip`, `.exe`, PyInstaller):**
   * Sử dụng công cụ REA: `open_binary` và `inspect_artifact`.
4. **Website / Web Application:**
   * Sử dụng REA browser target: `list_browser_targets` hoặc `capture_browser_scenario`.
5. **Thư mục mã nguồn dự án đầy đủ:**
   * Sử dụng công cụ đọc mã nguồn thông thường của Agent (tuân thủ tài liệu gốc REA: không ép REA phân tích mã nguồn thông thường).

> [!IMPORTANT]
> Luôn copy nguyên trạng file đầu vào sang `04_SAO_LUU_AN_TOAN/` trước khi tiến hành giải nén hoặc phân tích sâu.

---

## 3. BƯỚC 2: TỔNG HỢP & XUẤT BÁO CÁO (REPORT)

Ghi kết quả vào file `03_KET_QUA_KIEM_TRA/YYYY-MM-DD_HHmm_bao-cao.md` theo cấu trúc sau:

### Cấu trúc Báo Cáo:
1. **Thông tin chung:** Tên ứng dụng, loại tệp, công nghệ phát hiện, ngày kiểm tra.
2. **Bản đồ tính năng (Feature Map):**
   - Danh sách các màn hình và chức năng cốt lõi đã xác minh.
   - Luồng hoạt động chính của người dùng.
3. **Đánh giá rủi ro bảo mật có phạm vi (Scoped Security Review):**
   - Các quyền hạn yêu cầu (Permissions).
   - Nguy cơ lộ thông tin nhạy cảm, API keys hoặc kết nối không an toàn.
   - *Lưu ý bắt buộc:* Nêu rõ đây là phân tích tĩnh có giới hạn, không phải chứng chỉ an toàn tuyệt đối.
4. **Giới hạn & Điểm chưa rõ (Unknowns):** Các phần chưa thể phân tích nếu thiếu môi trường chạy thử.

---

## 4. BƯỚC 3: PHỎNG VẤN LÀM RÕ YÊU CẦU (ADAPTIVE INTERVIEW)

Dựa trên báo cáo và file `02_YEU_CAU_CUA_TOI/ho-so-va-muc-tieu.md`, trao đổi với người dùng theo các câu hỏi trọng tâm:

1. **Làm rõ tính năng còn thiếu:**
   > *"Tôi nhận thấy app hiện tại có các tính năng [A, B]. Bạn có muốn bổ sung thêm tính năng nào khác không?"*
2. **Nhu cầu nâng cấp giao diện / công nghệ:**
   > *"Giao diện hiện tại đang viết bằng [Công nghệ cũ]. Bạn có muốn nâng cấp lên giao diện hiện đại hơn không?"*
3. **Chốt hướng phát triển:**
   > *"Bạn muốn đi theo hướng nào:*
   > *- Hướng 1: Giữ nguyên ứng dụng hiện tại và viết thêm tính năng.*
   > *- Hướng 2: Viết lại ứng dụng mới hoàn toàn (Rebuild/Rewrite) dựa trên logic đã phân tích."*

---

## 5. BƯỚC 4: PHÁT TRIỂN & KIỂM THỬ (BUILD & VERIFY)

1. Tạo thư mục dự án bên trong `05_MA_NGUON_PHAT_TRIEN/`.
2. Triển khai mã nguồn theo đúng các yêu cầu đã thống nhất ở Bước 3.
3. Chạy kiểm thử chức năng (Unit test / Lệnh build / Syntax check).
4. Viết tài liệu hướng dẫn chạy app cực ngắn (1 trang) đặt tại `05_MA_NGUON_PHAT_TRIEN/HUONG_DAN_CHAY_APP.md`.
5. Cập nhật tiến độ vào `docs/PROGRESS.md` và `docs/HANDOFF.md`.
