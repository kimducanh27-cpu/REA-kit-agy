# PROMPT 03: PHỎNG VẤN & LÀM RÕ YÊU CẦU (TAB INTERVIEW)

*Dán đoạn lệnh này để kích hoạt AI phỏng vấn nhu cầu và chốt đặc tả yêu cầu.*

```markdown
Kích hoạt kỹ năng `rea-interview`:
1. Đọc báo cáo hiện trạng trong `03_KET_QUA_KIEM_TRA/` và hồ sơ cá nhân trong `02_YEU_CAU_CUA_TOI/ho-so-va-muc-tieu.md`.
2. Phỏng vấn tôi lần lượt theo 4 nhóm câu hỏi (mỗi lần hỏi 1 câu ngắn, có gợi ý trắc nghiệm để tôi dễ chọn):
   - Câu 1: App còn thiếu những tính năng cốt lõi nào mà tôi muốn bổ sung?
   - Câu 2: Nhu cầu nâng cấp giao diện hoặc công nghệ ra sao?
   - Câu 3: Yêu cầu bảo mật dữ liệu và phân quyền người dùng thế nào?
   - Câu 4: Đề xuất hướng đi: Giữ nguyên app cũ (Nâng cấp) hay Viết lại hoàn toàn (Rewrite)?
3. Sau khi tôi trả lời xong, xuất file đặc tả đã chốt vào `03_KET_QUA_KIEM_TRA/YYYY-MM-DD_HHmm_dac-ta-yeu-cau-da-chot.md` theo mẫu `templates/02-SPEC-TEMPLATE.md`.
4. Cập nhật `.agents/state/active_case.json` sang `spec_approved: true` và `current_phase: "SPEC_APPROVED"`.
```
