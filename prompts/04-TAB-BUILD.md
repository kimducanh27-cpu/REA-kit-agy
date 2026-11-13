# PROMPT 04: PHÁT TRIỂN & VIẾT LẠI ỨNG DỤNG (TAB BUILD)

*Dán đoạn lệnh này sau khi bạn đã duyệt file đặc tả yêu cầu ở Prompt 03.*

```markdown
Kích hoạt kỹ năng `rea-build` để tiến hành phát triển ứng dụng:
1. Đọc file đặc tả yêu cầu đã chốt trong `03_KET_QUA_KIEM_TRA/` và file giao diện `02_YEU_CAU_CUA_TOI/design.md`. (Nếu chưa có đặc tả, hãy từ chối và nhắc tôi chạy Prompt 03 trước).
2. Triển khai mã nguồn vào `05_MA_NGUON_PHAT_TRIEN/`:
   - Bắt buộc ánh xạ Design Tokens từ `design.md` thành các biến CSS Variables (`:root`) và Tailwind utility classes, cấm hardcode mã màu tùy tiện.
   - Nếu là viết lại (Rewrite — Lean Build): Ưu tiên Web độc lập (HTML5 + Tailwind CDN + Alpine/Vanilla JS) để người non-tech chỉ cần nhấp đúp chuột mở chạy ngay.
   - Nếu là sửa lỗi (Fix App — Surgical Patch): Chỉ sửa đúng vị trí hẹp nhất gây lỗi, bảo toàn code cũ.
3. Chạy kiểm tra cú pháp (Syntax Check / Build Test) và bắt buộc xuất file `05_MA_NGUON_PHAT_TRIEN/KET_QUA_KIEM_THU.md` theo mẫu `templates/04-TEST-RESULT-TEMPLATE.md`.
4. Viết file `05_MA_NGUON_PHAT_TRIEN/HUONG_DAN_CHAY_APP.md` đúng 1 trang theo mẫu `templates/03-RUN-GUIDE-TEMPLATE.md`.
5. Cập nhật `.agents/state/active_case.json` sang `build_status: "SUCCESS"` và `current_phase: "BUILD_COMPLETED"`.
6. Cập nhật tiến độ vào `docs/PROGRESS.md` và `docs/HANDOFF.md`.
```
