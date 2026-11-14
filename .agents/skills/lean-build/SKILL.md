---
name: lean-build
description: Kỹ năng phát triển mã nguồn tinh gọn (Lean Implementation & Minimalist Execution): căn chỉnh tuyệt đối theo đặc tả đóng băng tại Cổng 03 (frozen spec alignment), giới hạn phạm vi nghiêm ngặt theo Build Route đã chọn (strict scope), triệt tiêu scope creep, và xác lập điều kiện dừng rõ ràng (explicit stop condition).
---

# KỸ NĂNG: PHÁT TRIỂN MÃ NGUỒN TINH GỌN (LEAN-BUILD)

Kỹ năng chuyên biệt cho giai đoạn triển khai mã nguồn tại **STAGE_04 (Bước 09 REA Build)** theo `docs/WORKFLOW_LIFECYCLE.md` và nguyên tắc phát triển tối giản, triệt tiêu lãng phí tài nguyên và rủi ro trôi dạt phạm vi (Scope Creep).

---

## 1. BA NGUYÊN TẮC TINH GỌN CỐT LÕI (CORE LEAN PRINCIPLES)

1. **Căn Chỉnh Tuyệt Đối Theo Đặc Tả Đóng Băng (Frozen Spec Alignment)**:
   - Chỉ được phép triển khai các chức năng đã được mô tả và phê duyệt bằng văn bản trong:
     👉 `03_KET_QUA_KIEM_TRA/dac-ta-yeu-cau-da-chot.md`.
   - **RÀO CHẮN CỔNG 03**: Không bao giờ bắt đầu viết code khi Cổng 03 (`gate_03_spec_frozen`) chưa ở trạng thái được giải phóng (`PASS`, `REUSED_VALIDATED` hoặc `WAIVED`).
   - Mọi quyết định thiết kế (Design Tokens), bảng phân cấp bố cục, và kiểu dáng giao diện phải khớp 100% với `02_YEU_CAU_CUA_TOI/design.md` hoặc `tokens.json`.

2. **Giới Hạn Phạm Vi Nghiêm Ngặt Theo Build Route (Strict Scope by Route)**:
   - **Route A (`ROUTE_A_WEB_ZERO_INSTALL`)**:
     * Mục tiêu: Chạy ngay trên trình duyệt mà không yêu cầu cài đặt môi trường (`npm`, `node`, `gradle`).
     * Phạm vi: Chỉ bao gồm `index.html`, `styles.css`, `app.js` (hoặc `preview.html` cho bản thử nghiệm).
     * **CẤM**: Nhúng external CDN (Tailwind CDN, Google Fonts CDN, Cloudflare CDN) để đảm bảo 100% chạy offline-first an toàn.
   - **Route B (`ROUTE_B_ANDROID_NATIVE`)**:
     * Mục tiêu: Dự án Android Native chuẩn hóa với Android CLI (`android create`) hoặc cấu trúc Gradle + Kotlin/Java + Jetpack Compose.
     * Phạm vi: Cấu trúc Android tiêu chuẩn tại `05_MA_NGUON_PHAT_TRIEN/android/`.
     * **BẮT BUỘC**: Đặt hậu tố định danh gói ứng dụng `.rebuild` trên `applicationId` (ví dụ `com.example.app.rebuild`) để tránh lỗi `INSTALL_FAILED_UPDATE_INCOMPATIBLE`.
     * Tuân thủ chuẩn căn chỉnh bộ nhớ 16 KB page-size cho Android 15+.
   - **Route C (`ROUTE_C_PATCH_HYBRID`)**:
     * Mục tiêu: Vá tài nguyên, sửa bytecode smali hoặc đóng gói Hybrid cục bộ.
     * Phạm vi: Giới hạn can thiệp ở mức byte code hoặc tài nguyên tối thiểu. Đặt hậu tố `.patched` trên `applicationId`.

3. **Xác Lập Điều Kiện Dừng Rõ Ràng (Explicit Stop Condition)**:
   - Mỗi tác vụ trong `03_KET_QUA_KIEM_TRA/KE_HOACH_TRIEN_KHAI.md` phải có Tiêu chuẩn Hoàn thành (Definition of Done - DoD) có thể đo lường được.
   - **Nguyên tắc Dừng Đúng Lúc (Stop When Done)**:
     * Ngay khi tất cả các tiêu chí nghiệm thu của lát cắt (task) hiện tại được thỏa mãn: **DỪNG VIẾT CODE NGAY LẬP TỨC**.
     * Không "tiện tay" viết thêm các tiện ích râu ria, không "tối ưu hóa sớm" khi chưa có đo lường.
     * Chuyển giao ngay cho Bước 10 để chạy kiểm tra xác thực qua `verify_code.ps1` và `rea-verify`.

---

## 2. BẢO ĐẢM 6 TRẠNG THÁI GIAO DIỆN BẮT BUỘC (6 MANDATORY UI STATES)

Mọi màn hình hoặc luồng người dùng được xây dựng phải hỗ trợ đầy đủ 6 trạng thái giao diện:

| Trạng Thái | Mô Tả Yêu Cầu | Kiểm Chứng Tinh Gọn |
| :--- | :--- | :--- |
| **1. Loading** | Hiển thị hiệu ứng tải hoặc skeleton loading khi đang xử lý dữ liệu. | Không giật cục, không khóa UI vô lý. |
| **2. Empty** | Hiển thị khi danh sách hoặc bảng dữ liệu chưa có bản ghi nào. | Có thông điệp hướng dẫn và nút tạo mới / CTA. |
| **3. Success** | Hiển thị dữ liệu chuẩn xác sau khi tải hoặc hoàn tất tác vụ. | Khớp 100% với Design Tokens và Wireframe. |
| **4. Error** | Hiển thị khi có lỗi mạng, lỗi nhập liệu hoặc ngoại lệ hệ thống. | Thông điệp lỗi đời thường, có nút Thử lại (Retry). |
| **5. In-Progress / Draft** | Bảo toàn dữ liệu người dùng đang nhập dở dang theo `RULE-INIT-001`. | Lưu tạm vào `localStorage` / `DataStore`, tự điền lại khi reload. |
| **6. Offline / Reconnecting** | Phát hiện mất kết nối mạng hoặc hoạt động trong môi trường cô lập. | Hiển thị banner trạng thái offline, chuyển sang bộ nhớ đệm cục bộ. |

---

## 3. QUY TRÌNH THỰC THI PHÁT TRIỂN TINH GỌN (LEAN BUILD PROTOCOL)

### Bước 1: Kiểm Tra Tiên Quyết & Tạo Snapshot An Toàn
1. Xác nhận Cổng 03 đã mở qua lệnh:
   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\.agents\scripts\gate.ps1 status
   ```
2. Tạo snapshot dự phòng trước khi viết bất kỳ dòng mã nào:
   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\.agents\scripts\rollback.ps1 -Snapshot
   ```

### Bước 2: Nạp Design Tokens & Tài Liệu Quy Chuẩn
1. Đọc và nạp các biến token từ `02_YEU_CAU_CUA_TOI/tokens.json` hoặc `02_YEU_CAU_CUA_TOI/design.md`.
2. Khởi tạo tệp token tương ứng theo Route:
   - Route A: `05_MA_NGUON_PHAT_TRIEN/tokens.css`
   - Route B: `05_MA_NGUON_PHAT_TRIEN/android/app/src/main/res/values/colors.xml`, `dimens.xml` hoặc Compose `Color.kt`
3. Cấm tuyệt đối việc gán cứng giá trị mã màu hex `#...` hay `rgb(...)` trong các file logic hoặc view UI.

### Bước 3: Triển Khai Theo Lát Cắt Nguyên Tử (Atomic Slicing)
1. Thực hiện lần lượt từng task theo thứ tự phụ thuộc trong `KE_HOACH_TRIEN_KHAI.md`.
2. Tuân thủ nguyên tắc "Single Responsibility" cho từng tệp mã nguồn.
3. Không thêm thư viện bên ngoài nằm ngoài danh mục đã được phê duyệt trong đặc tả.

### Bước 4: Kiểm Tra Điều Kiện Dừng & Chuyển Giao
1. Rà soát lại bảng kiểm kê tính năng: Tất cả các tiêu chí nghiệm thu đã đạt?
2. Dừng phát triển mã nguồn, cập nhật tiến độ trong `.agents/state/active_case.json` (`current_step = "10_BUILD_QA"`).
3. Bàn giao cho kỹ năng `rea-verify` để thực thi Bước 10 (Build QA & Code Review).
