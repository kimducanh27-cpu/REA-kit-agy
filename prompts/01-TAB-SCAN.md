# PROMPT 01: QUÉT & KIỂM TRA ỨNG DỤNG (TAB SCAN)

*Dán đoạn lệnh này sau khi đã thả file vào thư mục `01_THA_APP_VAO_DAY/`.*

```markdown
Kích hoạt kỹ năng `rea-scan` để tiếp nhận ứng dụng:
1. Kiểm tra thư mục `01_THA_APP_VAO_DAY/`:
   - Nếu có nhiều hơn 1 file: In bảng kiểm kê và hỏi tôi muốn ưu tiên file nào trước.
   - Nếu có 1 file: Tiến hành tự động sao lưu nguyên vẹn sang `04_SAO_LUU_AN_TOAN/`.
2. Định tuyến công cụ REA phù hợp với định dạng ứng dụng (APK, Electron ASAR, Web, Binary, hoặc mã nguồn). Nếu thiếu công cụ dịch ngược (Java/Ghidra), tự động chuyển sang đọc tài nguyên tĩnh và giải thích ngắn gọn.
3. Xuất báo cáo tính năng đã xác minh (Feature Map) vào `03_KET_QUA_KIEM_TRA/` theo mẫu `templates/01-REPORT-TEMPLATE.md`.
4. Che mờ toàn bộ API keys/tokens bí mật thành `[REDACTED]`.
5. Cập nhật file `.agents/state/active_case.json` sang phase `SCAN_COMPLETED`.
```
