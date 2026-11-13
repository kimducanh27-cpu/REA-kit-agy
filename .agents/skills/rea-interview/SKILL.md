---
name: rea-interview
description: Phỏng vấn làm rõ yêu cầu người dùng sau khi đã có báo cáo phân tích từ rea-scan và file 02_YEU_CAU_CUA_TOI/ho-so-va-muc-tieu.md. Xác định tính năng còn thiếu, nhu cầu nâng cấp, rà soát bảo mật và chốt hướng phát triển (nâng cấp app cũ hay viết lại app mới). Kích hoạt khi người dùng chạy Prompt 3.
---

# KỸ NĂNG: PHỎNG VẤN & LÀM RÕ YÊU CẦU (REA-INTERVIEW)

Kỹ năng chuyên biệt cho giai đoạn đối thoại yêu cầu, đối chiếu chuẩn quy trình `docs/INTAKE_QUESTION_LOGIC.md`.

---

## 1. NGUYÊN TẮC PHỎNG VẤN
- Không hỏi dồn dập nhiều câu cùng lúc; chia thành từng nhóm câu hỏi ngắn.
- Không hỏi những thông tin đã được nêu rõ trong báo cáo hoặc trong file `02_YEU_CAU_CUA_TOI/ho-so-va-muc-tieu.md`.
- Đưa ra gợi ý sẵn (gạch đầu dòng hoặc lựa chọn trắc nghiệm) để người non-tech dễ trả lời.

---

## 2. QUY TRÌNH PHỎNG VẤN 4 BƯỚC

1. **Bước 1: Làm rõ tính năng còn thiếu (Missing Features)**:
   - Đối chiếu tính năng hiện có trong báo cáo với mong muốn của người dùng.
   - Hỏi cụ thể: *"App hiện có [Tính năng A, B]. Bạn muốn bổ sung tính năng nào cụ thể tiếp theo?"*

2. **Bước 2: Nhu cầu nâng cấp công nghệ & giao diện (Upgrade Needs)**:
   - Đánh giá xem công nghệ cũ có cần hiện đại hóa không (ví dụ chuyển từ giao diện cũ sang Web/React/Flutter).
   - Hỏi: *"Giao diện hiện tại có cần làm mới hay giữ nguyên phong cách cũ?"*

3. **Bước 3: Rà soát bảo mật & Ranh giới dữ liệu (Security Scope)**:
   - Hỏi về quyền riêng tư dữ liệu, phân quyền tài khoản (admin/user), và những gì app KHÔNG được phép làm.

4. **Bước 4: Chốt hướng đi phát triển (Build Route Decision)**:
   - Đưa ra 2 lựa chọn rõ ràng kèm ưu/nhược điểm:
     * **Hướng A (Nâng cấp tiếp)**: Giữ nguyên mã nguồn cũ và viết thêm module mới. (Nhanh, tận dụng code cũ).
     * **Hướng B (Viết lại hoàn toàn - Rebuild/Rewrite)**: Viết app mới dựa trên logic đã phân tích từ REA. (Sạch sẽ, công nghệ mới, loại bỏ rác cũ).

---

## 3. KẾT QUẢ ĐẦU RA
1. Ghi nhận toàn bộ quyết định của người dùng vào file:
   `03_KET_QUA_KIEM_TRA/YYYY-MM-DD_HHmm_dac-ta-yeu-cau-da-chot.md`
   để làm căn cứ triển khai cho kỹ năng `rea-build`.
2. Cập nhật file `.agents/state/active_case.json`:
   - `spec_approved`: `true`
   - `current_phase`: `"SPEC_APPROVED"`
   - `last_updated`: Thời gian hiện tại.
