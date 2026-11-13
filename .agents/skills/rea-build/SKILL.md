---
name: rea-build
description: Lập kế hoạch kiến trúc, triển khai mã nguồn ứng dụng vào thư mục 05_MA_NGUON_PHAT_TRIEN, kiểm thử chức năng và viết tài liệu hướng dẫn chạy app sau khi người dùng đã duyệt đặc tả yêu cầu. Kích hoạt khi người dùng chạy Prompt 4 hoặc yêu cầu phát triển/viết lại app.
---

# KỸ NĂNG: PHÁT TRIỂN & VIẾT LẠI ỨNG DỤNG (REA-BUILD)

Kỹ năng chuyên biệt cho giai đoạn sinh mã nguồn, thẩm định chất lượng và kiểm thử, đối chiếu chuẩn quy trình `docs/APP_REVIEW_WORKFLOW.md` và mô hình **Anthropic Code Review Pipeline** (*"How the Claude Code team does code review"*).

---

## 1. QUY TRÌNH TRIỂN KHAI 5 BƯỚC

1. **Kiểm tra điều kiện tiên quyết & Hợp đồng giao diện (Preflight & Design System 3 Tầng)**:
   - Đọc file đặc tả yêu cầu đã chốt trong `03_KET_QUA_KIEM_TRA/`. (Nếu chưa có đặc tả: Nhắc nhở người dùng chạy `rea-interview` trước).
   - **Bắt buộc đọc và áp dụng `02_YEU_CAU_CUA_TOI/design.md` đủ 3 tầng**:
     * *Tầng 1 (Tokens)*: Ánh xạ bảng màu, font chữ, bo góc vào biến `:root` của CSS và Tailwind utility classes. Cấm hardcode mã màu lung tung.
     * *Tầng 2 (Components)*: Tuân thủ quy chuẩn style cho các nút bấm, thẻ card, input, dialog, header.
     * *Tầng 3 (UI States)*: Triển khai bắt buộc 4 trạng thái giao diện: Loading (skeleton/spinner), Empty (biểu tượng + CTA tạo mới), Success (toast thông báo), Error (thông báo lỗi + nút Thử lại). Không để màn hình trắng hoặc đơ trong bất kỳ hoàn cảnh nào.

2. **Tự động sao lưu Snapshot trước khi sửa code (Automated Rollback Snapshot)**:
   - Nếu trong `05_MA_NGUON_PHAT_TRIEN/` đã có file mã nguồn cũ: Tự động copy toàn bộ vào thư mục `05_MA_NGUON_PHAT_TRIEN/.backup/YYYYMMDD_HHmmss/`.
   - Đảm bảo người dùng luôn có thể nhấp đúp file **`HOAN_TAC.bat`** để quay về phiên bản ổn định gần nhất.

3. **Triển khai mã nguồn tại `05_MA_NGUON_PHAT_TRIEN/` (Lean Build & Surgical Patch)**:
   - **Khi Viết mới / Nâng cấp (Build App — Lean Build)**: Chỉ triển khai đúng các tính năng đã chốt trong đặc tả, tuyệt đối không over-engineering. Ưu tiên công nghệ Web độc lập (HTML5 + Tailwind CDN + Alpine/Vanilla JS + Lucide Icons) để người non-tech nhấp đúp chuột mở chạy ngay trên trình duyệt.
   - **Khi Sửa lỗi (Fix App — Surgical Patch)**: Chỉ chỉnh sửa ở phạm vi hẹp nhất có trách nhiệm gây ra lỗi, không xóa ghi đè lan man các hàm đang hoạt động tốt.

4. **Cổng kiểm soát chất lượng 4 tầng & Thẩm định độc lập (Anthropic Governance Pipeline)**:
   - *Triết lý: Dùng công cụ xác định cho lỗi xác định; dùng AI độc lập cho phần suy luận; phân tầng rủi ro để con người nghiệm thu đúng trọng tâm.*
   - **Tầng 1 (Kiến trúc)**: Kiểm tra cấu trúc ranh giới Web độc lập, không phụ thuộc môi trường ngoài.
   - **Tầng 2 (Công cụ xác định)**: Chạy script `powershell -ExecutionPolicy Bypass -File .agents/scripts/verify_code.ps1`. Script này kiểm tra cú pháp HTML/JS và quét leak secret. Bắt buộc phải đạt Exit Code 0.
   - **Tầng 3 (Thẩm định độc lập — Independent AI Reviewer)**:
     * *Trục 1 (Standards)*: Đối chiếu `02_YEU_CAU_CUA_TOI/design.md` (Tokens, Components, 4 UI States).
     * *Trục 2 (Spec)*: Đối chiếu `03_.../dac-ta-yeu-cau-da-chot.md` (Tính năng chốt, bảo toàn logic cũ).
     * **Quy tắc hội tụ (Review Convergence)**: Nếu phát hiện lỗi, Builder Agent chỉ được phép tự sửa **tối đa 2 vòng**. Sau 2 vòng nếu vẫn lỗi thì dừng lại và báo cáo rõ điểm nghẽn cho người dùng, không chạy lặp vô tận đốt token.
   - **Tầng 4 (Phân tầng rủi ro & Nghiệm thu)**:
     * Phân loại rủi ro: **Thấp** (UI/text), **Vừa** (Form/logic local), **Cao** (API ngoài/secret).
     * Xuất file **`05_MA_NGUON_PHAT_TRIEN/KET_QUA_KIEM_THU.md`** theo mẫu `templates/04-TEST-RESULT-TEMPLATE.md`.

5. **Tạo tài liệu hướng dẫn chạy 1 trang & Cập nhật trạng thái**:
   - Tạo file `05_MA_NGUON_PHAT_TRIEN/HUONG_DAN_CHAY_APP.md` đúng 1 trang theo mẫu `templates/03-RUN-GUIDE-TEMPLATE.md`.
   - Cập nhật tiến độ vào `docs/PROGRESS.md` và `docs/HANDOFF.md`.
   - Cập nhật file `.agents/state/active_case.json`:
     * `build_status`: `"SUCCESS"`
     * `current_phase`: `"BUILD_COMPLETED"`
     * `last_updated`: Thời gian hiện tại.
