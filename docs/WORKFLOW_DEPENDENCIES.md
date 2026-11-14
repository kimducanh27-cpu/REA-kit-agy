# ĐỒ THỊ PHỤ THUỘC & QUY TẮC THU HỒI DỮ LIỆU (WORKFLOW DEPENDENCIES & INVALIDATION MATRIX)
*(Tài liệu chuẩn kiến trúc RWO v2 — Single Source of Truth cho cơ chế điều phối DAG và thu hồi có chọn lọc)*

Tài liệu này xác định các quan hệ phụ thuộc giữa Artifacts, Steps, và Gates trong REA-kit-agy, phục vụ cơ chế **Conditional DAG Execution** và nguyên tắc **"Invalidate only the affected dependency closure"** (Chỉ thu hồi những gì thực sự bị ảnh hưởng).

---

## 1. ĐỒ THỊ PHỤ THUỘC NGUYÊN TẮC (CORE DEPENDENCY GRAPH)

```text
[Input Target (APK / Source)]
          │
          ▼
   [01. App Intake]
          │
          ▼
 [02. Baseline Evidence] ────────► [GATE 01: Baseline Verified]
          │
          ▼
   [03. REA Scan]
          │
          ▼
 [04. Investigation]
          │
          ▼
  [05. REA Audit] ───────────────► [GATE 02: Audit Passed]
          │
          ▼
 [06. Interview & Art Direction]
          │
          ▼
  [07. UI Spec & Tokens]
          │
          ▼
[08. Implementation Plan] ───────► [GATE 03: Spec Frozen]
          │
          ▼
    [09. REA Build]
          │
          ▼
   [10. Build QA] ───────────────► [GATE 04: Build QA Passed]
          │
          ▼
  [11. Smoke Test]
          │
          ▼
  [12. Hard Verify] ─────────────► [GATE 05: Hard Verify Passed]
          │
          ▼
[13. Release & Handoff] ─────────► [GATE 06: Handoff Signed]
```

---

## 2. MA TRẬN THU HỒI PHỤ THUỘC (DEPENDENCY INVALIDATION MATRIX)

Khi một Artifact đầu vào hoặc quyết định bị thay đổi, Coordinator bắt buộc phải đối chiếu bảng dưới đây để xác định:
- **Phần BỊ THU HỒI (Invalidated)**: Bắt buộc chạy lại và thu hồi các Cổng liên đới qua `gate.ps1 reject`.
- **Phần ĐƯỢC GIỮ NGUYÊN (Preserved / Reused)**: Tuyệt đối không xóa, không quét lại để tiết kiệm thời gian và token.

| Artifact Bị Thay Đổi | Bằng Chứng & Bước Phải Thu Hồi (Invalidated) | Cổng Bị Thu Hồi | Bằng Chứng & Bước Được Giữ Lại (Preserved) | Điểm Re-entry |
| :--- | :--- | :--- | :--- | :--- |
| **1. APK Fingerprint (Thay file APK mới)** | Baseline, Toàn bộ Evidence REA, Báo cáo kiểm toán, Toàn bộ Spec, Plan, Code và Test. | **Gate 01, 02, 03, 04, 05, 06** | Không giữ lại bằng chứng nào từ APK cũ. | **Stage 01 (Step 01)** |
| **2. Yêu cầu Nghiệp vụ (Business Requirement)** | Bản đặc tả đã chốt (`dac-ta-yeu-cau-da-chot.md`), Kế hoạch 6 Milestones, Mã nguồn logic, Test results. | **Gate 03, 04, 05, 06** | **GIỮ NGUYÊN**: Baseline (Stage 01), Báo cáo hiện trạng & Evidence REA (Stage 02), Báo cáo kiểm toán (Step 05). | **Stage 03 (Step 06)** |
| **3. Bố cục Giao diện (UI Only / Copy Deck)** | `design.md`, `01_SCREEN_COMPOSITION.md`, `04_COPY_DECK.md`, Giao diện CSS/Compose, Visual QA. | **Gate 03, 04, 05, 06** | **GIỮ NGUYÊN**: Baseline, REA Evidence, Logic nghiệp vụ lõi, Backend API mapping. | **Stage 03 (Step 07)** |
| **4. Thiếu Bằng chứng API giữa chừng** | Chỉ thu hồi phần việc Build đang phụ thuộc trực tiếp vào API đó. | Không thu hồi Gate 03 nếu Spec không đổi; tạm hoãn Gate 04. | **GIỮ NGUYÊN**: Toàn bộ Stage 01, Stage 02 hiện có, Toàn bộ Spec Stage 03, Mã nguồn các module khác. | **Stage 02 (Step 04 targeted)** |
| **5. Quyền / Bảo mật (Security / Permission)** | Scoped Audit, Spec an toàn, Manifest declarations, Test results. | **Gate 02, 03, 04, 05, 06** | **GIỮ NGUYÊN**: Baseline, các Evidence tĩnh không liên quan quyền. | **Stage 02 (Step 05)** |
| **6. Lỗi Code QA (`verify_code.ps1` fail)** | Mã nguồn tại `05_MA_NGUON_PHAT_TRIEN/`, Báo cáo QA. | **Gate 04, 05, 06** | **GIỮ NGUYÊN**: Toàn bộ Stage 01, 02, 03 (Bản đặc tả đã đóng băng không bị thay đổi). | **Stage 04 (Step 09)** |
| **7. Lỗi Smoke Test / Hard Verify** | Mã nguồn gây lỗi, Báo cáo nghiệm thu. | **Gate 04, 05, 06** | **GIỮ NGUYÊN**: Toàn bộ Stage 01, 02, 03 và các module đã PASS kiểm thử đơn vị. | **Stage 04 (Step 09)** |

---

## 3. BỘ KIỂM THỬ 12 TÌNH HUỐNG THỰC TẾ (WF01 – WF12)

| Mã Case | Tình Huống Thực Tế | Chiến Lược Điều Phối (RWO Path) | Trạng Thái Cổng Dự Kiến |
| :--- | :--- | :--- | :--- |
| **`WF01`** | Nhận APK mới, có AVD / thiết bị Android đầy đủ. | Chạy Happy Path đầy đủ 14 bước. | Gate 01 → 06: `PASS` |
| **`WF02`** | Nhận APK mới nhưng máy không có AVD / thiết bị thật. | Chạy **Static Fallback 3 lớp** (JADX Manifest + Apktool strings + Binary layouts). | Gate 01: `PASS_WITH_LIMITATIONS`. Gate 05: `SPEC_ACCEPTANCE`. |
| **`WF03`** | Người dùng cung cấp Source Repository (không có file APK). | Chạy **Source Inspection**, bỏ qua các bước REA binary scan. | Gate 01 & 02: `REUSED_VALIDATED` hoặc `PASS`. |
| **`WF04`** | Người dùng CHỈ muốn phân tích APK, không viết mã nguồn. | Hoàn tất Stage 01 & Stage 02. Đóng ca làm việc và bàn giao báo cáo. | Gate 01 & 02: `PASS`. Gate 03-06: `NOT_APPLICABLE`. |
| **`WF05`** | Người dùng CHỈ muốn lập kế hoạch phát triển (Plan-only). | Chạy đến Step 08, đóng băng bản đặc tả và kế hoạch 6 Milestones. | Gate 01, 02, 03: `PASS`. Gate 04-06: `NOT_APPLICABLE`. |
| **`WF06`** | Người dùng đổi yêu cầu sau khi đã đóng băng Spec. | Khởi tạo Change Request qua `prompts/07`. Re-entry tại Stage 03. | Gate 01 & 02: Giữ `PASS`. Gate 03-06: `INVALIDATED`. |
| **`WF07`** | Người dùng đổi giao diện sau khi đã Build xong. | Change Request loại `UI_ONLY`. Re-entry tại Bước 07 (`07_UI_SPEC`). | Gate 01 & 02: Giữ `PASS`. Gate 03: Mở lại sau duyệt. Gate 04-06: `INVALIDATED`. |
| **`WF08`** | Phát hiện lỗi trong quá trình Smoke Test. | Lập `FIX_PLAN_v2.md`. Chạy `gate.ps1 reject 5`. Quay lại Bước 09 sửa mã. | Gate 01-03: Giữ `PASS`. Gate 04 & 05: `INVALIDATED`. |
| **`WF09`** | Người dùng bổ sung tính năng mới sau khi bàn giao. | Tạo Change Request mới. Đánh giá tác động phạm vi trước khi viết code. | Lưu bản bàn giao cũ vào `cases/`. Tạo Run mới độc lập. |
| **`WF10`** | File APK gốc được thay thế bằng phiên bản mới. | Phát hiện sai lệch Fingerprint SHA-256. Thu hồi toàn bộ bằng chứng cũ. | Gate 01-06: `INVALIDATED`. Chạy lại từ Bước 01. |
| **`WF11`** | Tái sử dụng kết quả của Workflow A cho Workflow B. | Kiểm tra tính còn hiệu lực (Provenance, Hash, Approval) trước khi gán. | Cổng tái sử dụng ghi: `REUSED_VALIDATED`. |
| **`WF12`** | Agent bị ngắt phiên hoặc công cụ lỗi giữa chừng. | Đọc `active_case.json` và `manifest.json`. Tiếp tục từ checkpoint gần nhất. | Giữ nguyên các Cổng đã `PASS` trước sự cố. |

---

## 4. QUY TRÌNH NỐI LUỒNG (WORKFLOW REJOIN ALGORITHM)

Khi luồng thực thi chính (như Build - Stage 04) cần quay lại một giai đoạn trước đó (như Điều tra bổ sung - Stage 02) để lấy dữ liệu:
1. **Pause**: Tạm dừng tác vụ hạ nguồn đang thiếu thông tin. Ghi nhận trạng thái vào `events.jsonl`.
2. **Isolate**: Tạo một tác vụ con có phạm vi hẹp (Targeted Task), chỉ định rõ Evidence ID cần bổ sung.
3. **Execute Upstream**: Chạy các bước thượng nguồn tương ứng (ví dụ Step 04 `04_DEEP_INVESTIGATION`).
4. **Audit**: Chạy Bước 05 (`05_REA_AUDIT`) độc lập để kiểm tra an toàn cho bằng chứng mới thu thập.
5. **Rejoin Decision**:
   - *Nếu bằng chứng mới KHÔNG làm đổi Spec*: Giữ nguyên Gate 03, nối thẳng lại Stage 04 (Bước 09) để tiếp tục Build.
   - *Nếu bằng chứng mới LÀM ĐỔI Spec*: Kích hoạt Change Request, cập nhật Spec, xin phê duyệt lại Gate 03 trước khi tiếp tục.
6. **Regression Verification**: Chạy lại các bài kiểm thử liên quan đến vùng nối để bảo đảm tính toàn vẹn hệ thống.
