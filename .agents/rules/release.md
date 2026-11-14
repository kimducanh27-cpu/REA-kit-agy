---
description: Quy chuẩn nghiệm thu và bàn giao Stage 05: hợp đồng môi trường kiểm thử, đối chiếu 1-1 Hard Verify, bắt buộc tính sẵn sàng của HOAN_TAC.bat và tài liệu bàn giao đời thường.
globs: "03_KET_QUA_KIEM_TRA/BAO_CAO_NGHIEM_THU_HARD_VERIFY.md, 05_MA_NGUON_PHAT_TRIEN/BAN_GIAO_SAN_PHAM.md, HOAN_TAC.bat, prompts/05-TAB-VALIDATION.md"
trigger: model_decision
---

# QUY TẮC NGHIỆM THU ĐỐI CHIẾU & BÀN GIAO SẢN PHẨM (VALIDATION & RELEASE)

Tài liệu này xác lập các nguyên tắc bắt buộc trong **STAGE 05 · VALIDATION** (Bước 11–13). Mọi sản phẩm trước khi bàn giao cho người dùng đều phải trải qua kiểm thử thực tế, đối chiếu 1-1 với ứng dụng gốc và cam kết an toàn với nút hoàn tác 1-click.

---

## 1. Hợp Đồng Môi Trường Kiểm Thử (Test Environment Contract)

1. **Phân định rõ ràng kịch bản kiểm thử theo môi trường**:
   - **Đối với Web App (Route A)**:
     * Hướng dẫn người dùng mở trực tiếp file `05_MA_NGUON_PHAT_TRIEN/index.html` trong trình duyệt web phổ thông (Chrome, Edge, Firefox).
     * Kiểm tra khả năng hiển thị trên cả máy tính (Desktop) và giả lập màn hình di động (Mobile Viewport).
   - **Đối với Android Native / APK (Route B & C)**:
     * Khởi chạy ứng dụng trên máy ảo AVD hoặc thiết bị thật kết nối qua Antigravity Device Hub.
     * Sử dụng lệnh REA ADB `start_adb_app` (tham số bắt buộc: `serial`, `package`) hoặc Android CLI để kích hoạt ứng dụng.
2. **Khảo sát khói nhanh (Smoke Test Protocol - Bước 11)**:
   - Trước khi thực hiện nghiệm thu chi tiết, Agent phải kiểm tra luồng đi cơ bản (Happy Path):
     * Màn hình chính có khởi động được không? Có bị trắng trang (White screen) hay crash không?
     * Dữ liệu mẫu ban đầu có hiển thị đầy đủ không?
     * Điều hướng qua lại giữa các màn hình có mượt mà không?

---

## 2. Quy Chuẩn Đối Chiếu 1-1 Chuyên Sâu (Hard Verify Protocol - Bước 12)

1. **Đối chiếu thực chứng (Evidence-Based Comparison)**:
   - Đặt app mới xây dựng cạnh app gốc để đối chiếu từng tính năng và thành phần giao diện.
   - **Với Android**:
     * Chụp ảnh màn hình mới bằng `android screen capture -o <file_path>` hoặc `capture_adb_screen`.
     * Sử dụng `android layout` để trích xuất cây cấu trúc component của app mới và so sánh trực tiếp với cây giao diện gốc thu thập từ Bước 02.
   - **Với Web**:
     * So sánh bố cục, bảng màu và typography với các ảnh màn hình lưu tại `01_THA_APP_VAO_DAY/baseline/`.

2. **Bắt buộc xuất bản Bảng Đối Chiếu 3 Cột**:
   - Ghi nhận chi tiết vào tệp `03_KET_QUA_KIEM_TRA/BAO_CAO_NGHIEM_THU_HARD_VERIFY.md` với 3 cột phân định rõ ràng:
     * **Cột 1: Khớp 100%**: Các chức năng và thành phần giao diện tái tạo chuẩn xác như bản gốc.
     * **Cột 2: Khác biệt có chủ đích**: Các điểm thay đổi đã được người dùng phê duyệt tại Bước 06/07.
     * **Cột 3: Nâng cấp mới**: Các cải tiến hiện đại hóa hoặc tính năng bổ sung vượt trội hơn bản gốc.

3. **Điều kiện mở Cổng 05 (`gate_05_hard_verify_passed`)**:
   - Người dùng xem xét Báo cáo Hard Verify và xác nhận bằng văn bản rằng ứng dụng mới đạt toàn bộ tiêu chí so sánh.

---

## 3. Bắt Buộc Tính Sẵn Sàng Của `HOAN_TAC.bat` (Atomic Rollback Readiness)

1. **Bảo vệ người dùng bằng nút hoàn tác 1-click**:
   - Trước khi đề nghị người dùng ký nhận bàn giao, Agent **BẮT BUỘC KIỂM TRA**:
     * Tệp lệnh `HOAN_TAC.bat` tồn tại tại thư mục gốc của repository.
     * Script điều phối nguyên tử `.agents/scripts/rollback.ps1` sẵn sàng hoạt động.
     * Snapshot hợp lệ gần nhất trong `05_MA_NGUON_PHAT_TRIEN/.backup/` còn nguyên vẹn và khớp mã băm SHA-256.
2. **Cam kết an toàn tuyệt đối**:
   - Người dùng luôn giữ quyền kiểm soát tối cao: Nếu sau khi nhận bàn giao mà sản phẩm gặp lỗi hoặc không ưng ý, người dùng chỉ cần nhấp đúp `HOAN_TAC.bat` để khôi phục toàn bộ mã nguồn về trạng thái an toàn trước đó trong tích tắc.

---

## 4. Quy Chuẩn Đóng Gói & Bàn Giao Sản Phẩm (Release & Handoff - Bước 13)

1. **Dọn dẹp không gian làm việc**:
   - Dọn sạch toàn bộ tệp tin rác, tệp tạm thời (`.tmp`), và các thư mục thử nghiệm dở dang trước khi bàn giao.

2. **Bản giải thích đời thường (Plain-Language Explainer)**:
   - Xuất bản tệp bàn giao chính thức tại: `05_MA_NGUON_PHAT_TRIEN/BAN_GIAO_SAN_PHAM.md`.
   - Viết bằng tiếng Việt trong sáng, dễ hiểu cho người dùng phổ thông (không dùng biệt ngữ kỹ thuật khó hiểu), trả lời trọn vẹn 3 câu hỏi:
     1. **Ứng dụng này làm được gì?** (Tổng quan chức năng).
     2. **Tại sao lại chọn cấu trúc này và có gì khác bản gốc?** (Lý do kiến trúc & các điểm cải tiến).
     3. **Cách mở và sử dụng như thế nào?** (Hướng dẫn chạy app từng bước).
   - Đính kèm mục hướng dẫn sử dụng `HOAN_TAC.bat` khi cần khôi phục.

3. **Ký Nhận Bàn Giao & Mở Cổng 06 (`gate_06_handoff_signed`)**:
   - Theo nguyên tắc "You Land It, You Own It": Người dùng kiểm tra sản phẩm lần cuối và xác nhận nghiệm thu.
   - Cập nhật trạng thái hoàn thành vào `.agents/state/active_case.json` và đồng bộ nội dung vào `docs/HANDOFF.md`.
