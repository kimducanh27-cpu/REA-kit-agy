# PROMPT 06: TỔNG HỢP & NUÔI DƯỠNG BỘ NHỚ 4 TẦNG (DREAMING & MEMORY CONSOLIDATION)

*Dán đoạn lệnh này vào AI Agent sau khi hoàn thành một Stage lớn hoặc khi kết thúc dự án để kích hoạt cơ chế Dreaming chuẩn Anthropic ('The components of agent memory', 06/11/2026).*

---

```markdown
# Session Memory Consolidation (Anthropic 4-Layer Dreaming Protocol)

Read and follow `AGENTS.md`, `docs/ARCHITECTURE.md`, `.agents/state/MEMORY.md`, and `.agents/skills/memory-consolidation/SKILL.md`.

## Active Skills for this Step:
- Local Kit Skills (Bắt buộc): `memory-consolidation`

You are executing **DREAMING & 4-LAYER MEMORY CONSOLIDATION**:

### BƯỚC 1: GHI NHẬT KÝ PHIÊN (LAYER 1 TRANSCRIPTS GROUND-TRUTH)
1. Dùng công cụ ghi file chuẩn của Agent để tạo tệp nhật ký sự kiện phiên tại:
   👉 `.agents/state/cases/session_<YYYYMMDD_HHmmss>.md`
   Ghi rõ: `case_id`, các Stage/Step đã thực hiện, danh sách Evidence IDs, kết quả chạy `verify_code.ps1`, và tóm tắt `git diff --stat`.

### BƯỚC 2: KIỂM CHỨNG NGƯỢC GHI CHÚ CŨ (RETROACTIVE DRIFT CORRECTION)
1. Đọc toàn bộ các mục `MEM-*` trong `.agents/state/MEMORY.md` và đối chiếu với nhật ký thực tế ở Bước 1 cùng các tệp trong `source_refs`.
2. Nếu phát hiện bất kỳ `MEM-*` nào bị sai lệch so với công cụ/mã nguồn thực tế, sửa lại ngay hoặc đánh dấu `DEPRECATED`.

### BƯỚC 3: TRÍCH XUẤT SALIENCE & CẬP NHẬT LAYER 2 (`MEMORY.md` & `learned_rules.json`)
1. Chọn lọc cả **chiến lược thành công (validated strategies)**, **quy tắc kiến trúc (technical rules)** và **cảnh báo bẫy kỹ thuật (trap warnings)** có chứng cứ xác thực (`source_refs`).
2. Cập nhật vào bảng Markdown trong `.agents/state/MEMORY.md` (giữ tổng độ dài tệp **<= 200 dòng hoặc 25 KB** theo chuẩn Layer 4 Injected Index của Anthropic).
3. Nếu có quy tắc phòng ngừa lỗi tái diễn, cập nhật thêm vào `.agents/state/learned_rules.json`.

### BƯỚC 4: KIỂM TRA LIÊN KẾT WIKI (LAYER 3) & ĐỒNG BỘ BÀN GIAO (LAYER 4)
1. Kiểm tra các liên kết tài liệu trong `MEMORY.md` và `docs/` đều trỏ tới tệp hợp lệ.
2. Cập nhật trạng thái mới nhất vào `docs/HANDOFF.md` và `docs/PROGRESS.md`.

### BÁO CÁO CHO NGƯỜI DÙNG:
In ngắn gọn danh sách các `MEM-XXX` vừa được thêm mới hoặc hiệu chỉnh và xác nhận bộ nhớ 4 tầng của workspace đã sẵn sàng cho phiên tiếp theo.
```
