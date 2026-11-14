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
11. `.agents/skills/rea-scan` (Kỹ năng điều phối Stage 01 & 02)
12. `.agents/skills/rea-interview` (Kỹ năng điều phối Stage 03)
13. `.agents/skills/rea-build` (Kỹ năng điều phối Stage 04 & 05)
14. `.agents/scripts` (Script kiểm tra sức khỏe, verify code và rollback)
15. `.agents/state` (Bộ nhớ máy trạng thái 6 Gates và học sự cố)

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
2. `.agents/skills/rea-scan/SKILL.md`: Điều phối Stage 01 (Intake, Baseline, Fallback) và Stage 02 (Scan, Investigate, Audit, Sổ Unknowns). Mở Cổng 01 & 02.
3. `.agents/skills/rea-interview/SKILL.md`: Điều phối Stage 03 (Interview, Design Tokens, Spec frozen, Implementation plan). Mở Cổng 03.
4. `.agents/skills/rea-build/SKILL.md`: Điều phối Stage 04 (Build Zero-Install, Snapshot, Build QA & Review) và Stage 05 (Smoke test, Hard Verify đối chiếu 1-1, Handoff trọn gói). Mở Cổng 04, 05, 06.

---

### BƯỚC 4: TẠO BỘ PROMPTS/ VÀ TEMPLATES/ (6 STAGE · 14 BƯỚC)
1. Trong `prompts/`:
   - `00-SESSION-CONTINUITY.md` (Phục hồi phiên & Auto-Resume)
   - `01-TAB-DISCOVERY.md` (Stage 01: Intake & Baseline — STAGE_01_DISCOVERY — Active Skills: `rea-scan`, `reverse-engineer-anything`, `android-cli`, `android-device-hub`)
   - `02-TAB-REVERSE-ENGINEERING.md` (Stage 02: Scan, Investigate & Audit — STAGE_02_REVERSE_ENGINEERING — Active Skills: `rea-scan`, `reverse-engineer-anything`, `android-cli`)
   - `03-TAB-PRODUCT-DEFINITION.md` (Stage 03: Interview, Spec & Plan — STAGE_03_PRODUCT_DEFINITION — Active Skills: `rea-interview`, `ui-styling`, `design-system`)
   - `04-TAB-IMPLEMENTATION.md` (Stage 04: Build & Build QA — STAGE_04_IMPLEMENTATION — Active Skills: `rea-build`, `surgical-patch`, `lean-build`, `ui-styling`)
   - `05-TAB-VALIDATION.md` (Stage 05: Smoke Test, Hard Verify & Handoff — STAGE_05_VALIDATION — Active Skills: `rea-build`, `code-review`, `android-cli`, `android-device-hub`)
   *(Lưu ý: Mọi prompt 01-05 đều khai báo tường minh khối `## Active Skills for this Tab` để AI Agent kích hoạt chính xác kỹ năng cần dùng).*
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
