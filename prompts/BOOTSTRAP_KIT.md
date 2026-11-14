# SIÊU LỆNH KHỞI TẠO BỘ KIT (META-BOOTSTRAP PROMPT)

*Dán toàn bộ khối lệnh dưới đây vào một thư mục trống tinh trong AI Agent (Antigravity, Claude Code, Cursor, OpenCode) để AI tự động dựng 100% bộ kit REA-kit-agy hoàn chỉnh theo chuẩn 6 Stage · 14 Bước.*

---

```markdown
BẠN ĐANG ĐƯỢC GIAO NHIỆM VỤ KHỞI TẠO (BOOTSTRAP) TOÀN BỘ BỘ KIT "REA-KIT-AGY" VÀO THƯ MỤC HIỆN TẠI.

HÃY THỰC HIỆN TUẦN TỰ VÀ ĐẦY ĐỦ CÁC BƯỚC SAU:

### BƯỚC 1: TẠO CẤU TRÚC CÂY THƯ MỤC
Tạo đầy đủ các thư mục sau:
1. `01_THA_APP_VAO_DAY` (Thư mục thả app đầu vào & baseline)
2. `02_YEU_CAU_CUA_TOI` (Thư mục ngữ cảnh cá nhân & design tokens)
3. `03_KET_QUA_KIEM_TRA` (Thư mục xuất báo cáo, unknowns, spec chốt, kế hoạch và nghiệm thu)
4. `04_SAO_LUU_AN_TOAN` (Thư mục sao lưu bất khả xâm phạm)
5. `05_MA_NGUON_PHAT_TRIEN` (Thư mục chứa code mới/viết lại, preview.html, và bàn giao)
6. `prompts` (Bộ câu lệnh dán theo 5 Tab / 6 Stage)
7. `templates` (Khung mẫu tài liệu hợp đồng chuẩn từ 01 đến 09)
8. `docs` (Bộ tài liệu quản trị ngữ cảnh đa phiên)
9. `.agents/rules` (Luật an toàn cho Agent)
10. `.agents/skills/reverse-engineer-anything` (Kỹ năng lõi gốc upstream REA)
11. `.agents/skills/rea-scan` (Kỹ năng điều phối Intake & Scan)
12. `.agents/skills/rea-audit` (Kỹ năng kiểm toán bằng chứng độc lập & Coverage)
13. `.agents/skills/rea-interview` (Kỹ năng phỏng vấn người dùng & 4 Build Routes)
14. `.agents/skills/rea-plan` (Kỹ năng lập kiến trúc & chia Vertical Slices)
15. `.agents/skills/rea-build` (Kỹ năng điều phối viết mã nguồn & bàn giao)
16. `.agents/skills/memory-consolidation` (Kỹ năng nuôi dưỡng bộ nhớ Anthropic)
17. `.agents/scripts` (Script kiểm tra sức khỏe, verify code và rollback)
18. `.agents/state` (Bộ nhớ máy trạng thái 6 Gates, MEMORY.md và cases/)

---

### BƯỚC 2: TẠO CÁC FILE ĐIỀU HÀNH & BẢO MẬT CỐT LÕI
1. Tạo `.gitignore` chặn rò rỉ dữ liệu cá nhân.
2. Tạo `.agents/state/active_case.json` (máy trạng thái 6 Gates & 14 Steps) và `.agents/state/learned_rules.json` (bộ nhớ học từ sự cố).
3. Tạo file đăng ký Upstream `UPSTREAMS.md`:
   - Pinned to morluto/rea commit SHA `5cddc69c51a0fb18d021417199046314581ba9c2`, package `rea-agents@6.9.0`.
4. Tạo `AGENTS.md` (Não bộ điều hành 6 Stage 14 Bước và 6 Cổng kiểm soát).
5. Tạo `CLAUDE.md`: Chứa dòng `@AGENTS.md`.
6. Tạo `REVIEW.md`: Hợp đồng thẩm định độc lập 2 trục, bộ lọc dẹp nhiễu và phân tầng rủi ro.
7. Tạo `HUONG_DAN_SU_DUNG.md`: Hướng dẫn 1 trang kèm sơ đồ Mermaid và 5 mẫu câu lệnh tự dán.
8. Tạo `02_YEU_CAU_CUA_TOI/ho-so-va-muc-tieu.md` và `02_YEU_CAU_CUA_TOI/design.md`.

---

### BƯỚC 3: TẠO BỘ KỸ NĂNG TRONG .agents/skills/
1. `.agents/skills/reverse-engineer-anything/`: Kỹ năng lõi gốc sao chép từ upstream morluto/rea.
2. `.agents/skills/rea-scan/SKILL.md`: Điều phối Intake, Baseline và Scan.
3. `.agents/skills/rea-audit/SKILL.md`: Kiểm toán bằng chứng độc lập, Coverage và Sổ Unknowns. Mở Cổng 02.
4. `.agents/skills/rea-interview/SKILL.md`: Phỏng vấn người dùng, lựa chọn 4 Build Routes và đóng băng đặc tả.
5. `.agents/skills/rea-plan/SKILL.md`: Lập kiến trúc, chia Vertical Slices và Task Dependency Graph. Mở Cổng 03.
6. `.agents/skills/rea-build/SKILL.md`: Triển khai mã nguồn theo lát cắt, quản lý snapshot, Hard Verify và bàn giao. Mở Cổng 04, 05, 06.
7. `.agents/skills/memory-consolidation/SKILL.md`: Cơ chế Dreaming tổng hợp bài học vào MEMORY.md theo chuẩn Anthropic.

---

### BƯỚC 4: TẠO BỘ PROMPTS/ VÀ TEMPLATES/ (6 STAGE · 14 BƯỚC)
1. Trong `prompts/`:
   - `00-SESSION-CONTINUITY.md` (Phục hồi phiên & Auto-Resume)
   - `01-TAB-DISCOVERY.md` (Stage 01: Intake & Baseline — Active Skills: `rea-scan`, `reverse-engineer-anything`, `android-cli`, `android-device-hub`, `investigate-first`)
   - `02-TAB-REVERSE-ENGINEERING.md` (Stage 02: Scan & Audit — Active Skills: `rea-scan`, `rea-audit`, `reverse-engineer-anything`, `android-cli`, `cookie-debugging`, `investigate-first`)
   - `03-TAB-PRODUCT-DEFINITION.md` (Stage 03: Interview & Plan — Active Skills: `rea-interview`, `rea-plan`, `grilling`, `ui-styling`, `design-system`, `ui-ux-pro-max`, `figma-generate-diagram`)
   - `04-TAB-IMPLEMENTATION.md` (Stage 04: Build & Review — Active Skills: `rea-build`, `tdd`, `surgical-patch`, `lean-build`, `safe-refactor`, `compose-preview`, `ui-styling`)
   - `05-TAB-VALIDATION.md` (Stage 05: Smoke Test & Handoff — Active Skills: `rea-build`, `verify-and-stop`, `code-review`, `android-cli`, `android-device-hub`, `compose-preview`, `a11y-debugging`)
   - `06-CONSOLIDATION-AND-MEMORY.md` (Anthropic Dreaming — Active Skills: `memory-consolidation`, `agent-chat-export`, `caveman-compress`, `caveman-learn`)
   *(Lưu ý: Mọi prompt đều khai báo tường minh khối `## Active Skills for this Tab` kết hợp Local Skills + Host Plugins).*
2. Trong `templates/`:
   - `01-REPORT-TEMPLATE.md` (Báo cáo hiện trạng)
   - `02-SPEC-TEMPLATE.md` (Đặc tả đóng băng)
   - `03-RUN-GUIDE-TEMPLATE.md` (Hướng dẫn chạy app)
   - `04-TEST-RESULT-TEMPLATE.md` (Chứng chỉ QA & Review)
   - `05-DESIGN-TOKEN-TEMPLATE.md` (Design Tokens 3 tầng)
   - `06-UNKNOWNS-AND-COVERAGE-TEMPLATE.md` (Sổ theo dõi điểm mù & độ phủ)
   - `07-IMPLEMENTATION-PLAN-TEMPLATE.md` (Kế hoạch chia task nguyên tử)
   - `08-HARD-VERIFY-TEMPLATE.md` (Bảng đối chiếu 1-1 với app gốc)
   - `09-HANDOFF-BUNDLE-TEMPLATE.md` (Biên bản bàn giao sản phẩm)
3. Trong `docs/`:
   - `WORKFLOW_LIFECYCLE.md` (Đặc tả chuẩn 6 Stage · 14 Bước)
   - `PROGRESS.md` (Bảng tiến độ 14 bước tự động đồng bộ)
   - `HANDOFF.md`, `PRD.md`, `ARCHITECTURE.md`, `PLAN.md`, `RULES.md`, `PROMPTS.md`.

---

### BƯỚC 5: CỔNG TỰ KIỂM CHỨNG BẮT BUỘC (SELF-VERIFICATION GATE)
1. Tạo script `.agents/scripts/health_check.ps1` kiểm tra đủ 6 tiêu chí kèm Auto-Resume banner.
2. Tạo script `.agents/scripts/verify_code.ps1` và `.agents/scripts/rollback.ps1`.
3. Tạo file `KIEM_TRA.bat` và `HOAN_TAC.bat`.
4. Chạy lệnh ẩn thư mục kỹ thuật: `attrib +h .agents`.
5. **BẮT BUỘC**: Tự động chạy lệnh kiểm tra `health_check.ps1` ngay trong terminal.
6. Chỉ khi kết quả trả về `6/6 PASSED`, in thông báo:
   "==========================================================
    BOOTSTRAP THÀNH CÔNG: WORKSPACE & RUNTIME SẴN SÀNG (6/6)!
    =========================================================="
```
