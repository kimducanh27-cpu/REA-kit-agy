---
name: rea-build
description: Lập kế hoạch kiến trúc, triển khai mã nguồn ứng dụng vào thư mục 05_MA_NGUON_PHAT_TRIEN, kiểm thử chức năng và viết tài liệu hướng dẫn chạy app sau khi người dùng đã duyệt đặc tả yêu cầu. Kích hoạt khi người dùng chạy Prompt 4 hoặc yêu cầu phát triển/viết lại app.
---

# KỸ NĂNG: PHÁT TRIỂN & VIẾT LẠI ỨNG DỤNG (REA-BUILD)

Kỹ năng chuyên biệt cho giai đoạn sinh mã nguồn, thẩm định chất lượng và kiểm thử, tuân thủ hợp đồng thẩm định tại `REVIEW.md` và mô hình **Anthropic Code Review Pipeline** (*"How the Claude Code team does code review"*).

---

## 1. QUY TRÌNH TRIỂN KHAI 5 BƯỚC

1. **Kiểm tra điều kiện tiên quyết, Tiêu chuẩn Review & Bài học quá khứ**:
   - Đọc file đặc tả yêu cầu đã chốt trong `03_KET_QUA_KIEM_TRA/`. (Nếu chưa có: Nhắc người dùng chạy `rea-interview` trước).
   - **Bắt buộc đọc `REVIEW.md`**: Nắm vững tiêu chí kiểm toán độc lập 4 tầng, bộ lọc dẹp nhiễu và phân tầng rủi ro.
   - **Đọc `.agents/state/learned_rules.json` (Incidents to Evals)**: Nạp danh sách các quy tắc phòng ngừa từ các lỗi từng xảy ra trong quá khứ để không bao giờ tái phạm.
   - **Áp dụng hợp đồng `02_YEU_CAU_CUA_TOI/design.md` đủ 3 tầng**:
     * *Tầng 1 (Tokens)*: Bảng màu, typography, radius đưa vào CSS `:root` và Tailwind classes.
     * *Tầng 2 (Components)*: Style chuẩn cho nút, thẻ, ô nhập liệu, header.
     * *Tầng 3 (UI States)*: 4 trạng thái bắt buộc: Loading, Empty, Success, Error Recovery.

2. **Tự động sao lưu Snapshot trước khi sửa code (Automated Rollback Snapshot)**:
   - Nếu trong `05_MA_NGUON_PHAT_TRIEN/` đã có file mã nguồn cũ: Tự động copy toàn bộ vào thư mục `05_MA_NGUON_PHAT_TRIEN/.backup/YYYYMMDD_HHmmss/`.
   - Đảm bảo người dùng luôn có thể nhấp đúp file **`HOAN_TAC.bat`** để quay về phiên bản ổn định gần nhất.

3. **Triển khai mã nguồn & Bản xem trước theo giai đoạn (Staged Preview)**:
   - **Khi Viết mới (Rewrite — Lean Build)**: Triển khai trực tiếp vào `05_MA_NGUON_PHAT_TRIEN/index.html`.
   - **Khi Nâng cấp / Sửa lỗi (Staged Preview)**:
     * Xuất ra file `05_MA_NGUON_PHAT_TRIEN/preview.html` để người dùng mở xem thử song song, giữ nguyên `index.html` đang chạy ổn định.
     * Chỉ khi người dùng xác nhận nghiệm thu đạt yêu cầu, AI mới chuyển nội dung từ `preview.html` sang `index.html` chính thức.
   - **Học từ sự cố (Incidents to Evals)**: Khi người dùng yêu cầu sửa lỗi hoặc vừa bấm hoàn tác, AI phân tích nguyên nhân gốc rễ và tự động bổ sung 1 quy tắc mới vào `.agents/state/learned_rules.json`.

4. **Cổng kiểm soát chất lượng 4 tầng & Thẩm định độc lập (Anthropic Model)**:
   - *Triết lý: Dùng công cụ xác định cho lỗi xác định; dùng AI độc lập cho phần suy luận; phân tầng rủi ro để con người nghiệm thu đúng trọng tâm.*
   - **Tầng 1 (Kiến trúc)**: Kiểm tra cấu trúc ranh giới Web độc lập, không phụ thuộc môi trường ngoài.
   - **Tầng 2 (Công cụ xác định)**: Chạy script `powershell -ExecutionPolicy Bypass -File .agents/scripts/verify_code.ps1`. Bắt buộc đạt Exit Code 0.
   - **Tầng 3 (Thẩm định độc lập — Independent AI Reviewer)**:
     * Áp dụng **Bộ lọc dẹp nhiễu (High-Signal Filter)** theo `REVIEW.md`: Chỉ báo cáo vi phạm hợp đồng (Spec, Design Tokens, 4 UI States, rò rỉ secret). Nghiêm cấm bắt bẻ phong cách viết mã râu ria làm phiền người non-tech.
     * **Quy tắc hội tụ (Review Convergence)**: Builder Agent chỉ được phép tự sửa **tối đa 2 vòng**. Nếu sau 2 vòng vẫn lỗi thì dừng lại báo cáo điểm nghẽn, tuyệt đối không lặp vô tận đốt token.
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
