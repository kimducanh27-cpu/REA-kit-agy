# MEMORY NOTES — REA-kit-agy
> **Anthropic Layer 2 Durable Memory Notes**: Lưu trữ tri thức kỹ thuật, quyết định kiến trúc và quy tắc đã kiểm chứng.  
> **Nguyên tắc**: Chỉ Control Agent được ghi nhận tri thức sau khi đã đối chiếu nguồn gốc (Provenance Verification). Không lưu dữ liệu tạm thời hoặc suy đoán chưa kiểm chứng.

---

## 1. Danh Mục Tri Thức Kỹ Thuật Đã Xác Minh (Verified Technical Rules)

### MEM-001: Ranh Giới Kiểm Tra Tĩnh vs Runtime Execution
- **memory_id**: `MEM-001`
- **scope**: `REA_INTEGRATION`
- **type**: `TECHNICAL_RULE`
- **claim**: "Kiểm toán tĩnh (Static source/package inspection) không đồng nghĩa với thực thi runtime an toàn. Mọi hành vi runtime, mở cổng mạng, hoặc chạy app trên thiết bị thật đều cần sự phê duyệt riêng của chủ sở hữu."
- **status**: `VERIFIED`
- **source_refs**:
  - `docs/RULES.md`
  - `docs/SOURCE_AUDIT.md`
  - `docs/SECURITY_REVIEW_MODEL.md`
- **created_at**: 2026-11-13
- **last_verified**: 2026-11-14
- **review_required**: false

### MEM-002: Ưu Tiên Android APK Cho V1 Qua Android CLI Plugin
- **memory_id**: `MEM-002`
- **scope**: `TARGET_ROUTING`
- **type**: `ARCHITECTURAL_DECISION`
- **claim**: "Android APK được chọn làm mục tiêu cốt lõi V1 nhờ sự kết hợp giữa plugin Android CLI (`android-cli-plugin`), AVD Device Hub của Google Antigravity và công cụ REA ADB (inspect_android_package / capture_adb_screen). Khi không có máy ảo/thiết bị, kit tự động chuyển sang chế độ Static Fallback XML/Assets mà không crash."
- **status**: `VERIFIED`
- **source_refs**:
  - `docs/adrs/0001-multi-target-architecture.md`
  - `docs/adrs/0005-android-apk-first-target-via-android-cli.md`
- **created_at**: 2026-11-13
- **last_verified**: 2026-11-14
- **review_required**: false

### MEM-003: Phân Định Rõ Ràng Phạm Vi Swarm và Subagents
- **memory_id**: `MEM-003`
- **scope**: `AGENT_COORDINATION`
- **type**: `OPERATIONAL_POLICY`
- **claim**: "Mô hình điều phối mặc định là Single Authoritative Coordinator kết hợp Subagents chạy trong context cô lập. /swarm bị tắt mặc định và chỉ được kích hoạt trong Stage 04 (Build) khi nhiệm vụ được chia thành các vertical slice / module độc lập rõ ràng (UI, Data, Tests) để tránh xung đột ghi đè tệp."
- **status**: `VERIFIED`
- **source_refs**:
  - `docs/adrs/0004-single-coordinator-agent-model.md`
  - `REVIEW.md`
- **created_at**: 2026-11-13
- **last_verified**: 2026-11-14
- **review_required**: false

### MEM-004: Khôi Phục Đệ Quy Toàn Bộ Thư Mục Lồng Nhau (Rollback Safety)
- **memory_id**: `MEM-004`
- **scope**: `ENGINEERING_RECOVERY`
- **type**: `VERIFIED_FIX`
- **claim**: "Script rollback.ps1 bắt buộc phải sử dụng tham số `-Recurse -Force` khi dọn dẹp thư mục phát triển và khôi phục snapshot từ `.backup/` để đảm bảo không bị sót cây thư mục con hoặc file ẩn."
- **status**: `VERIFIED`
- **source_refs**:
  - `.agents/scripts/rollback.ps1`
  - `.agents/state/learned_rules.json`
- **created_at**: 2026-11-13
- **last_verified**: 2026-11-14
- **review_required**: false

---

## 2. Quy Trình Tổng Hợp & Đánh Giá Bộ Nhớ (Consolidation / Dreaming Protocol)

1. **Kích hoạt**: Chạy vào cuối mỗi Stage/Milestone quan trọng.
2. **Trích xuất ứng viên**: Nhận diện các quyết định, lỗi lặp lại, bài học kỹ thuật mới từ Transcripts và Git Diff.
3. **Đối chiếu nguồn gốc (Provenance Check)**: Truy ngược về commit, file spec, hoặc test result thực tế. Nếu không có chứng cứ, đánh dấu `INFERRED` hoặc hủy bỏ.
4. **Hợp nhất & Dọn dẹp**: Ghép các ghi chú trùng lặp, đánh dấu `DEPRECATED` cho các quy tắc lỗi thời.
5. **Ghi nhận đơn quyền**: Duy nhất Control Agent cập nhật file này.
