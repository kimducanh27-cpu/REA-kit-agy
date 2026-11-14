---
name: rea-verify
description: Kỹ năng kiểm định đầu cuối tự động độc lập (Autonomous End-to-End & Real Verification Gates): E2E Web Playwright, kiểm tra visual regression (pixelmatch đối chiếu baseline 1-1), kiểm định Android Native (gradlew lint, gradlew test), và tái thực thi Golden Scenarios. Quyết định mở hoặc từ chối Cổng 04 (Build QA) và Cổng 05 (Hard Verify).
---

# KỸ NĂNG: KIỂM ĐỊNH ĐẦU CUỐI TỰ ĐỘNG & CỔNG CHẤT LƯỢNG (REA-VERIFY)

Kỹ năng kiểm định độc lập cấp hệ thống cho **STAGE_04 (Bước 10 Build QA)** và **STAGE_05 (Bước 11 Smoke Test & Bước 12 Hard Verify)** theo `docs/WORKFLOW_LIFECYCLE.md` và `REVIEW.md`.

---

## 1. NGUYÊN TẮC KIỂM ĐỊNH THỰC THẾ (REAL VERIFICATION PRINCIPLES)

1. **Kiểm định dựa trên bằng chứng chạy thực (Runtime & Deterministic Evidence)**:
   - Tuyệt đối không chỉ đọc lướt mã nguồn hoặc đưa ra giả định chủ quan.
   - Bắt buộc kiểm định qua công cụ xác định: script kiểm tra tĩnh (`verify_code.ps1`), runner E2E Playwright, đối chiếu pixel thị giác (`pixelmatch`), và Android CLI / Gradle toolchain.
2. **Khách quan & Độc lập (Auditor Separation)**:
   - Vai trò kiểm định tách bạch với vai trò viết mã (`rea-build` / `lean-build`).
   - Mọi kết luận ĐẠT (PASS) hoặc CHẶN (BLOCK/REJECT) phải có log đầu ra, mã thoát lệnh (Exit Code), hoặc ảnh chụp màn hình làm bằng chứng đính kèm.
3. **Phân tầng kiểm định theo 4 Trụ cột**:
   - **Trụ cột 1 — Xác định & An toàn**: `verify_code.ps1` (Cú pháp, Secret Leak, Token Drift, WCAG AA Contrast, Asset Provenance, Risk Classifier).
   - **Trụ cột 2 — Hành vi & Luồng E2E**: Playwright Web E2E Test & Tái thực thi Golden Scenarios.
   - **Trụ cột 3 — Thị giác & Giao diện**: So sánh ảnh chụp màn hình 1-1 với baseline qua `pixelmatch` hoặc `android screen capture`.
   - **Trụ cột 4 — Nền tảng Native (Android)**: `./gradlew lint`, `./gradlew test`, kiểm tra căn chỉnh 16 KB page-size và package ID suffix.

---

## 2. QUY TRÌNH THỰC THI 4 TRỤ CỘT KIỂM ĐỊNH

### Trụ cột 1: Kiểm định Xác định Mã Nguồn (`verify_code.ps1`)
1. Chạy lệnh:
   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\.agents\scripts\verify_code.ps1
   ```
   *(Thêm `-AllowHighRisk` chỉ khi người dùng đã duyệt hành vi mạng trong đặc tả Cổng 03)*.
2. Script kiểm tra toàn diện 9 hạng mục:
   - Cấu trúc thư mục mã nguồn và file khởi động (`index.html` hoặc `AndroidManifest.xml`).
   - Cặp thẻ HTML đóng/mở hợp lệ.
   - Cú pháp JavaScript (qua `node --check` hoặc heuristic brace balance).
   - Quét rò rỉ secret, chuỗi nhạy cảm thô, Base64 secret, và high-entropy tokens.
   - Phân loại rủi ro tự động (LOW / MEDIUM / HIGH RISK).
   - Cấu trúc dự án Android (`AndroidManifest.xml`, `build.gradle*`, cân bằng ngoặc nhọn).
   - **Token Drift Check**: Báo lỗi nếu UI files hardcode màu hex (`#...`, `rgb(...)`, `Color(0x...)`) ngoài file token, hoặc dùng external CDN trong Route A.
   - **WCAG AA Contrast Check**: Kiểm tra tỷ lệ tương phản chữ/nền đạt `>= 4.5:1`.
   - **Asset Provenance Check**: Xác thực nguồn gốc tài nguyên hình ảnh/font/icon đối chiếu với `01_/`, `04_/` và `ASSET_ALLOWLIST.md`.

---

### Trụ cột 2: Kiểm thử Đầu Cuối E2E Web (Playwright)
Áp dụng cho ứng dụng Web Route A (`05_MA_NGUON_PHAT_TRIEN/index.html` hoặc `preview.html`):

1. **Khởi chạy Playwright Test Suite**:
   - Chạy test runner không cần server ngoài (mở trực tiếp `file:///` hoặc local static server):
     ```bash
     npx playwright test
     ```
2. **Kiểm tra 6 Trạng Thái UI Bắt Buộc**:
   - `Loading`: Trạng thái chờ tải dữ liệu, hiển thị skeleton/spinner, không giật layout.
   - `Empty`: Trạng thái danh sách rỗng, có thông điệp hướng dẫn và call-to-action (CTA).
   - `Success`: Trạng thái hiển thị dữ liệu chuẩn, hoạt động đúng tính năng.
   - `Error`: Trạng thái báo lỗi thân thiện, nút thử lại (retry), không sập ứng dụng.
   - `In-Progress / Draft`: Bảo toàn dữ liệu form khi nhập dở dang hoặc gặp sự cố (`RULE-INIT-001`).
   - `Offline / Reconnecting`: Phát hiện mất mạng hoặc chạy offline, có banner trạng thái và không treo tương tác.
3. **Giám sát Console Errors & Network Leaks**:
   - Lắng nghe sự kiện `page.on('console')` và `page.on('pageerror')`.
   - Bắt buộc không có Unhandled Promise Rejection hoặc Exception trên DevTools Console.
   - Xác nhận không có yêu cầu outbound fetch/xhr tới các domain không thuộc phạm vi đặc tả.

---

### Trụ cột 3: Đối Chiếu Thị Giác & Visual Regression (Pixelmatch)
Áp dụng cho cả Web Route A và Android Route B/C:

1. **Thu thập ảnh chụp màn hình thực tế (Actual Screenshots)**:
   - **Với Web**: Playwright `page.screenshot({ path: '03_KET_QUA_KIEM_TRA/actual/screen_01.png' })`.
   - **Với Android**: `android screen capture -o 03_KET_QUA_KIEM_TRA/actual/screen_01.png` hoặc REA MCP `capture_adb_screen`.
2. **So sánh 1-1 với Baseline**:
   - Nguồn baseline: `03_KET_QUA_KIEM_TRA/baseline/` (hoặc `01_THA_APP_VAO_DAY/baseline/`).
   - Chạy công cụ so sánh pixel (`pixelmatch` hoặc thư viện visual regression tương đương):
     * Ngưỡng khác biệt cho phép: Tỷ lệ pixel lệch $< 1\%$ (hoặc `threshold: 0.1` cho các khác biệt khử răng cưa/antialiasing font).
     * Xuất ảnh diff đánh dấu vùng lệch màu đỏ/vàng vào `03_KET_QUA_KIEM_TRA/diff/diff_screen_01.png`.
3. **Phân loại khác biệt 3 cột**:
   - Lập bảng đối chiếu 3 cột theo `templates/08-HARD-VERIFY-TEMPLATE.md`:
     * **Cột 1 — Khớp 100%**: Layout, màu sắc, font chữ, icon tương đồng hoàn toàn với baseline.
     * **Cột 2 — Khác biệt có chủ đích**: Các thay đổi đã được thống nhất tại Bước 06/07 (ví dụ chuyển sang Dark Mode, đổi bố cục đáp ứng).
     * **Cột 3 — Nâng cấp mới**: Các animation mượt mà hơn, responsive window size class mới.

---

### Trụ cột 4: Kiểm định Nền Tảng Native Android (Gradle & CLI)
Áp dụng cho Route B (Android Native) và Route C (Patch APK):

1. **Kiểm định Biên dịch & Lint**:
   - Chạy lệnh Gradle wrapper trong thư mục `05_MA_NGUON_PHAT_TRIEN/android/`:
     ```bash
     ./gradlew lintDebug
     ./gradlew testDebugUnitTest
     ```
   - Xác nhận `BUILD SUCCESSFUL` và không có lỗi nghiêm trọng (Fatal Errors) trong lint report.
2. **Kiểm tra Chuẩn Căn Chỉnh 16 KB Page-Size (Android 15+)**:
   - Với thư viện `.so`:
     ```bash
     readelf -l app/build/intermediates/merged_native_libs/debug/out/lib/*/*.so | grep LOAD
     ```
     *(Xác nhận `p_align = 0x4000` tức 16384 bytes)*.
   - Với gói APK:
     ```bash
     zipalign -c -P 16 -v 4 app/build/outputs/apk/debug/app-debug.apk
     ```
3. **Xác thực Định danh Gói (Application ID Suffix Guard)**:
   - Kiểm tra `applicationId` trong `build.gradle.kts` / `build.gradle`:
     * Bắt buộc có hậu tố `.rebuild` (với Route B) hoặc `.patched` (với Route C).
     * Ngăn chặn hoàn toàn lỗi cài đặt xung đột chữ ký: `INSTALL_FAILED_UPDATE_INCOMPATIBLE`.

---

### Trụ cột 5: Tái Thực Thi Golden Scenarios (Golden Scenario Re-run)
1. Đọc danh sách 3–5 kịch bản vàng (Golden Scenarios) từ `templates/15-APP-FLOW-SPEC-TEMPLATE.md` hoặc `03_KET_QUA_KIEM_TRA/dac-ta-yeu-cau-da-chot.md`.
2. Tái hiện từng bước thao tác:
   - Dữ liệu đầu vào (Input Payload / User Action).
   - Kỳ vọng chuyển đổi trạng thái (State Transition).
   - Kết quả đầu ra (Expected Output / View Rendered).
3. Đánh giá tính toàn vẹn: Toàn bộ Golden Scenarios phải PASS 100%. Nếu có bất kỳ scenario nào sai lệch logic, đánh dấu kết quả FAIL.

---

## 3. ĐIỀU PHỐI CỔNG KIỂM SOÁT & XỬ LÝ LỖI (GATING PROTOCOL)

1. **Điều kiện mở CỔNG 04 (`gate_04_build_qa_passed`)**:
   - `verify_code.ps1` trả về `Exit Code 0`.
   - Không còn lỗi cú pháp hoặc cờ HIGH RISK chưa giải trình.
   - Xuất biên bản vào `03_KET_QUA_KIEM_TRA/KET_QUA_KIEM_THU.md`.
   - Lệnh mở cổng:
     ```powershell
     powershell -NoProfile -ExecutionPolicy Bypass -File .\.agents\scripts\gate.ps1 open 4 -Evidence 03_KET_QUA_KIEM_TRA/KET_QUA_KIEM_THU.md -ApprovedBy "rea-verify"
     ```

2. **Điều kiện mở CỔNG 05 (`gate_05_hard_verify_passed`)**:
   - Smoke test Happy Path thành công.
   - Bảng đối chiếu Hard Verify 1-1 và Visual Diff đạt yêu cầu.
   - Người dùng ký duyệt biên bản `03_KET_QUA_KIEM_TRA/BAO_CAO_NGHIEM_THU_HARD_VERIFY.md`.
   - Lệnh mở cổng:
     ```powershell
     powershell -NoProfile -ExecutionPolicy Bypass -File .\.agents\scripts\gate.ps1 open 5 -Evidence 03_KET_QUA_KIEM_TRA/BAO_CAO_NGHIEM_THU_HARD_VERIFY.md -ApprovedBy "user"
     ```

3. **Khi Kiểm định Thất bại (Reject Loop Integration)**:
   - Ghi nhận chi tiết lỗi vào `03_KET_QUA_KIEM_TRA/VERIFICATION_FAILURES.md`.
   - Tự động chuyển giao cho kỹ năng `surgical-patch` để sửa lỗi cục bộ.
   - Tuân thủ nghiêm ngặt giới hạn hội tụ tối đa 2 vòng (`review_convergence_rounds <= 2`).
   - Nếu vượt quá 2 vòng: Lập tức dừng lại, từ chối cổng qua `gate.ps1 reject` và báo cáo người dùng.
