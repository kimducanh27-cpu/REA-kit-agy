# BỘ CÂU LỆNH TỰ DÁN THEO QUY TRÌNH (PROMPTS PLAYBOOK)
*(Dành cho người dùng tự copy và dán vào chat với AI)*

---

## 📌 PROMPT 1: KIỂM TRA & BÁO CÁO HIỆN TRẠNG ỨNG DỤNG
*Sử dụng sau khi bạn đã kéo-thả ứng dụng vào thư mục `01_THA_APP_VAO_DAY`.*

```markdown
Hãy kích hoạt kỹ năng `rea-scan` để kiểm tra ứng dụng trong thư mục `01_THA_APP_VAO_DAY`:
1. Tự động sao lưu file gốc sang `04_SAO_LUU_AN_TOAN/`.
2. Nhận diện định dạng tệp (APK, Electron ASAR, Web, hay mã nguồn) và gọi công cụ phân tích phù hợp từ REA.
3. Xuất báo cáo tính năng đã xác minh (Feature Map) vào `03_KET_QUA_KIEM_TRA/`.
4. Trình bày tóm tắt cho tôi bằng tiếng Việt dễ hiểu, dạng gạch đầu dòng, không xả log kỹ thuật.
```

---

## 📌 PROMPT 2: ĐÁNH GIÁ BẢO MẬT CÓ PHẠM VI (SCOPED SECURITY REVIEW)
*Sử dụng khi bạn muốn kiểm tra xem ứng dụng có lỗ hổng, rò rỉ dữ liệu hoặc quyền nguy hiểm không.*

```markdown
Dựa trên kết quả phân tích ứng dụng trong thư mục `01_THA_APP_VAO_DAY`:
1. Rà soát các quyền hạn hệ thống (Permissions) mà app yêu cầu xem có quyền nào bất thường không.
2. Kiểm tra xem có API keys, đường dẫn máy chủ không an toàn (HTTP) hay rò rỉ thông tin cá nhân trong mã nguồn/tài nguyên không.
3. Liệt kê rõ: Các điểm an toàn, các điểm rủi ro cần khắc phục, và những phần chưa thể kiểm tra nếu không chạy thử runtime.
4. Ghi nhớ: Nêu rõ đây là đánh giá tĩnh có phạm vi, không phải chứng chỉ an toàn tuyệt đối.
```

---

## 📌 PROMPT 3: PHỎNG VẤN LÀM RÕ YÊU CẦU NÂNG CẤP / VIẾT LẠI
*Sử dụng để AI đối chiếu mong muốn của bạn và hỏi các câu hỏi còn thiếu.*

```markdown
Hãy kích hoạt kỹ năng `rea-interview`:
1. Đọc báo cáo hiện trạng trong `03_KET_QUA_KIEM_TRA/` và mục tiêu của tôi trong `02_YEU_CAU_CUA_TOI/ho-so-va-muc-tieu.md`.
2. Phỏng vấn tôi lần lượt theo 4 nhóm câu hỏi:
   - App hiện tại còn thiếu những tính năng gì mà tôi muốn bổ sung?
   - Cần nâng cấp giao diện hoặc công nghệ ra sao?
   - Yêu cầu bảo vệ dữ liệu và phân quyền người dùng như thế nào?
   - Đề xuất cho tôi: Nên giữ nguyên app cũ để phát triển tiếp hay Viết lại hoàn toàn (Rewrite)?
3. Hỏi ngắn gọn từng câu một, có gợi ý sẵn để tôi dễ chọn.
```

---

## 📌 PROMPT 4: PHÁT TRIỂN HOẶC VIẾT LẠI ỨNG DỤNG
*Sử dụng sau khi bạn và AI đã thống nhất xong đặc tả yêu cầu ở Prompt 3.*

```markdown
Hãy kích hoạt kỹ năng `rea-build` để tiến hành phát triển ứng dụng:
1. Đọc các yêu cầu và hướng đi đã chốt trong `03_KET_QUA_KIEM_TRA/`.
2. Khởi tạo mã nguồn và viết code sạch vào thư mục `05_MA_NGUON_PHAT_TRIEN/`.
3. Chạy kiểm tra cú pháp và kiểm thử các tính năng mới được thêm.
4. Viết file `05_MA_NGUON_PHAT_TRIEN/HUONG_DAN_CHAY_APP.md` (đúng 1 trang) hướng dẫn tôi cách mở và chạy thử app trên máy.
5. Cập nhật tiến độ vào `docs/PROGRESS.md` và `docs/HANDOFF.md`.
```

---

## 📌 PROMPT 5: TIẾP QUẢN PHIÊN CHAT MỚI (SESSION CONTINUITY)
*Copy đoạn này và dán vào đầu bất kỳ cửa sổ chat mới nào để AI tiếp tục làm việc mà không bị mất bối cảnh.*

```markdown
BẠN ĐANG LÀM VIỆC TRONG DỰ ÁN: REA-kit-agy (https://github.com/kimducanh27-cpu/REA-kit-agy)

NHIỆM VỤ BẮT BUỘC TRƯỚC KHI THỰC HIỆN BẤT KỲ LỆNH NÀO:
1. Đọc và tuân thủ: `AGENTS.md` và `docs/RULES.md`.
2. Đọc trạng thái bàn giao từ phiên trước:
   - `docs/HANDOFF.md` (Vị trí đang dừng và nhiệm vụ tiếp theo).
   - `docs/PROGRESS.md` và `docs/PLAN.md` (Tiến độ tổng thể).
   - `docs/ARCHITECTURE.md` (Kiến trúc và chuẩn tham chiếu từ morluto/rea).

BÁO CÁO ĐẦU PHIÊN:
- Đã đọc xong tài liệu: [Có / Chưa]
- Nhiệm vụ tiếp theo cần làm: [Nêu rõ bước lấy từ docs/HANDOFF.md]
- Chờ lệnh tiếp tục.
```
