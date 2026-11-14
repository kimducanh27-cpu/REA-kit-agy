# PROMPT 06: TỔNG HỢP & NUÔI DƯỠNG BỘ NHỚ (DREAMING & MEMORY CONSOLIDATION)

*Dán đoạn lệnh này vào AI Agent sau khi hoàn thành một Milestone lớn hoặc khi kết thúc ca làm việc để kích hoạt cơ chế Dreaming của Anthropic: trích xuất bài học kỹ thuật bền vững vào `MEMORY.md`, kiểm tra nguồn gốc và tinh gọn ngữ cảnh cho phiên sau.*

---

```markdown
# Session Memory Consolidation (Anthropic Dreaming Protocol)

Read and follow `AGENTS.md`, `docs/ARCHITECTURE.md`, and `.agents/skills/memory-consolidation/SKILL.md`.

## Active Skills for this Step:
- Local Kit Skills: `memory-consolidation`
- Host Plugin Skills: `agent-chat-export`, `caveman-compress`, `caveman-learn`

You are executing **DREAMING & MEMORY CONSOLIDATION**:

### BƯỚC 1: TRÍCH XUẤT NHẬT KÝ PHIÊN (TRANSCRIPTS EXTRACTION)
1. Sử dụng skill `agent-chat-export` để lưu nhật ký sự kiện của phiên hiện tại vào:
   👉 `.agents/state/cases/session_<TIMESTAMP>.md`.
2. Kiểm tra Git diff của phiên (`git diff --stat`) và kết quả test tại `03_KET_QUA_KIEM_TRA/`.

### BƯỚC 2: RÀ SOÁT & TRÍCH XUẤT BÀI HỌC BỀN VỮNG
1. Nhận diện các tri thức có giá trị tái sử dụng:
   - Các lỗi cú pháp, rào cản môi trường đã khắc phục (Verified Fixes).
   - Quy tắc kỹ thuật và tương thích công cụ (Technical Rules).
   - Quyết định kiến trúc quan trọng đã được kiểm chứng (Architectural Decisions).
2. **Kiểm tra nguồn gốc (Provenance Check)**: Chỉ lưu lại tri thức khi có tệp chứng cứ hoặc commit cụ thể. Tuyệt đối không lưu suy đoán.

### BƯỚC 3: CẬP NHẬT TẦNG BỘ NHỚ DÀI HẠN
1. Cập nhật các bài học mới vào:
   👉 `.agents/state/MEMORY.md` (tuân thủ đúng JSON schema: `memory_id`, `scope`, `type`, `claim`, `status`, `source_refs`).
2. Nếu phát hiện quy tắc từ sự cố lặp lại, cập nhật thêm vào:
   👉 `.agents/state/learned_rules.json`.

### BƯỚC 4: HỢP NHẤT TRÙNG LẶP & TINH GỌN NGỮ CẢNH
1. Hợp nhất các ghi chú tương đồng, đánh dấu `DEPRECATED` cho các bài học đã lỗi thời.
2. Sử dụng `caveman-compress` để nén các bản tóm tắt bàn giao.
3. Cập nhật trạng thái liên tục vào:
   👉 `docs/HANDOFF.md` và `docs/PROGRESS.md`.

### BÁO CÁO CHO NGƯỜI DÙNG:
In ngắn gọn danh sách các `memory_id` mới được lưu và xác nhận bộ nhớ workspace đã được củng cố an toàn cho phiên tiếp theo.
```
