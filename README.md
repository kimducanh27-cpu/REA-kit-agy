# REA-kit-agy

**Bộ kit dùng REA để kiểm tra ứng dụng, làm rõ yêu cầu và phát triển/nâng cấp app bằng AI.**

REA-kit-agy không phải bộ tạo workspace chung và không thay thế REA. Đây là lớp quy trình tiếng Việt đặt trên REA cùng coding agent: tiếp nhận app được phép kiểm tra, điều tra có bằng chứng, tổng hợp hiện trạng và rủi ro, hỏi người dùng những thông tin còn thiếu, chốt phạm vi, rồi hỗ trợ mở rộng hoặc viết lại app và xác minh kết quả.

## Quy trình

1. **Tiếp nhận app:** xác định ứng dụng, nền tảng, tài liệu/source/artifact được cung cấp, mục tiêu và quyền kiểm tra.
2. **Kiểm tra:** chọn khả năng REA phù hợp; nếu có source repository thì coding agent đọc source trực tiếp.
3. **Báo cáo:** tổng hợp chức năng, luồng, cấu trúc đã xác minh, vấn đề, rủi ro bảo mật, giới hạn và phần chưa biết.
4. **Hỏi phần còn thiếu:** chỉ hỏi quyết định ảnh hưởng đến sản phẩm, kỹ thuật, dữ liệu, bảo mật hoặc triển khai.
5. **Chọn hướng:** cải tiến app hiện tại, thêm tính năng, xây app tương thích hay viết lại; nêu lý do và đánh đổi.
6. **Phát triển:** chốt đặc tả, triển khai trong nhánh/bản sao an toàn.
7. **Xác minh:** kiểm thử, hard review, rà soát bảo mật trong phạm vi cho phép và bàn giao.

## Vai trò của REA

REA cung cấp công cụ reverse engineering qua MCP/CLI và kết quả Evidence có nguồn gốc, coverage, limitations, unknowns. Coding agent dùng kết quả để giải thích, hỏi tiếp, lập kế hoạch, viết và kiểm thử. REA-kit-agy bổ sung quy trình tiếng Việt, báo cáo, phỏng vấn yêu cầu, quyết định hướng phát triển và các cổng an toàn.

REA không phải sandbox và không chứng nhận ứng dụng an toàn. Kit không được biến một lượt phân tích tĩnh thành kết luận bảo mật tuyệt đối.

## Trạng thái

- P00: nghiên cứu REA, workflow app-review và ranh giới bảo mật.
- Chưa triển khai tính năng sản phẩm.
- Chưa kiểm thử tích hợp end-to-end với Antigravity hay agent khác.
- Chưa chốt nền tảng đầu tiên cho v1.

Đọc docs/HANDOFF.md và docs/PLAN.md để tiếp tục.

Nguồn lõi: https://github.com/morluto/rea
