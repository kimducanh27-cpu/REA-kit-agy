# HƯỚNG DẪN PHỎNG VẤN CHUYÊN BIỆT: KIẾN TRÚC & KHẢ NĂNG BẢO TRÌ (ARCHITECTURE & MAINTAINABILITY)
> **Domain**: `ARCHITECTURE_MAINTAINABILITY`  
> **Áp dụng cho**: Bước 06 (`06_REA_INTERVIEW`) & Bước 07 (`07_SPEC_AND_DESIGN`) thuộc STAGE_03 · PRODUCT DEFINITION  
> **Quy chuẩn**: REA Adaptive Interview Framework · Clean Architecture & Safe Refactoring  

---

## 1. Mục Tiêu & Phạm Vi Phỏng Vấn

Hướng dẫn này kích hoạt khi mục tiêu của ca làm việc là **tái cấu trúc hệ thống (refactoring), phân tách module (decoupling), nâng cao khả năng kiểm thử (testability), hoặc chuẩn bị nền tảng cho việc bảo trì lâu dài**.

Nguyên tắc bất biến:
- **Bảo toàn hành vi người dùng (Behavior Preservation)**: Refactoring cấu trúc bên trong nhưng không làm thay đổi hành vi quan sát được ở giao diện hoặc API.
- **Ranh giới tác động rõ ràng (Blast Radius Containment)**: Cô lập thay đổi trong các module cụ thể, tránh hiệu ứng dây chuyền (ripple effect).
- **Tránh tối ưu hóa sớm (YAGNI & Anti-Overengineering)**: Không áp đặt kiến trúc phức tạp (như Clean Architecture 5 tầng, micro-frontends) khi bài toán chỉ là ứng dụng đơn giản.

---

## 2. Các Trụ Cột Điều Tra Kiến Trúc

### 2.1 Điểm Nóng & Module Có Vấn Đề (Problematic Modules & Hotspots)
- Xác định các lớp "God Object" (Activity/Class dài > 1500 dòng ôm đồm UI, Data, Network).
- Xác định sự gắn kết lỏng lẻo (Tight Coupling) khiến việc sửa đổi 1 tính năng làm gãy 3 tính năng khác.
- Kiểm tra mã nguồn có unit test bảo vệ hay không.

### 2.2 Tương Thích API & Cơ Sở Dữ Liệu (API & Schema Compatibility)
- Schema database (Room, SQLite, Realm) có cần di chuyển (migration) hay giữ nguyên?
- Hợp đồng API backend có được phép thay đổi không, hay phải tuân thủ nghiêm ngặt định dạng JSON hiện hành?
- Khả năng tương thích ngược (Backward Compatibility) với các phiên bản client cũ.

### 2.3 Mức Độ Chấp Nhận Tái Cấu Trúc (Refactoring Tolerance)
- Người dùng muốn:
  * **Surgical Refactoring**: Chỉ tách nhỏ hàm/lớp ở vùng thường xuyên bị lỗi.
  * **Module Extraction**: Tách logic nghiệp vụ sang UseCase / Repository độc lập.
  * **Framework / Language Upgrade**: Nâng cấp Kotlin version, Gradle version, hoặc chuyển từ View sang Jetpack Compose.
- Giới hạn thời gian và chi phí kiểm thử hồi quy.

---

## 3. Khung Câu Hỏi Quyết Định Kiến Trúc (Decision-Driven Question Catalog)

### Q-ARCH-01: Mức Độ Tương Thích Dữ Liệu Cũ
- **Câu hỏi**: Dữ liệu cục bộ của người dùng trên thiết bị (SQLite/Room) có cần giữ nguyên khi cập nhật mã nguồn mới không, hay có thể xóa tạo lại trong môi trường thử nghiệm?
- **Intent**: Xác định có cần viết script Database Migration (`Migration(x, y)`) hay chỉ cần `fallbackToDestructiveMigration()`.
- **Related Decision**: `DECISION-ARCH-01: Database Migration Strategy`.
- **Expected Information**: Bắt buộc giữ dữ liệu người dùng / Được phép reset trong bản dev.
- **Applicability Conditions**: Ứng dụng có lưu trữ dữ liệu local (Room/SQLite/DataStore).
- **Skip Conditions**: Ứng dụng Stateless hoặc không có cơ sở dữ liệu trên đĩa.
- **Evidence Alternatives**: Kiểm tra `schemas/` hoặc `Room.databaseBuilder` trong mã nguồn.

### Q-ARCH-02: Ranh Giới Chuyển Đổi Công Nghệ (Tech Stack Modernization Scope)
- **Câu hỏi**: Bạn muốn giữ nguyên cách tổ chức hiện tại hay nâng cấp lên cấu trúc chuẩn (ví dụ: MVVM + StateFlow + Repository Pattern)?
- **Intent**: Định hình phạm vi ảnh hưởng của việc tái cấu trúc mã nguồn ở Stage 04.
- **Related Decision**: `DECISION-ARCH-02: Target Architecture Pattern`.
- **Expected Information**: Giữ nguyên kiến trúc cũ tối giản / Chuẩn hóa MVVM.
- **Applicability Conditions**: Mã nguồn có sự lộn xộn kiến trúc (Fat Activity, Spaghetti).
- **Skip Conditions**: Dự án đã áp dụng Clean Architecture hoặc chỉ sửa lỗi nhỏ.

---

## 4. Bảng Tiêu Chí Nghiệm Thu Đóng Băng Kiến Trúc (Architectural Invariants)

1. Tách biệt hoàn toàn tầng Giao diện (UI State / View) và tầng Dữ liệu (Repository / DataSource).
2. Không import trực tiếp `android.content.Context` vào các lớp nghiệp vụ thuần (Domain UseCases / ViewModels).
3. Vượt qua kiểm tra phân tích tĩnh `verify_code.ps1` với 0 cảnh báo về chu kỳ phụ thuộc (Circular Dependencies).
