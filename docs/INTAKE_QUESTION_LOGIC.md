# QUY TẮC PHỎNG VẤN TIẾP NHẬN & CHỌN LỌC CÂU HỎI (INTAKE QUESTION LOGIC)
> **Hệ sinh thái**: REA-kit-agy v1.1  
> **Trạng thái**: Hợp đồng kỹ thuật chuẩn hóa (Authoritative Technical Specification)  
> **Áp dụng cho**: Bước 01 (`01_APP_INTAKE`), Bước 06 (`06_REA_INTERVIEW`) & Kỹ năng `rea-interview`  

---

## 1. Triết Lý Cốt Lõi: Bằng Chứng Trước Câu Hỏi (Evidence Before Questions)

Tuyệt đối không gửi biểu mẫu câu hỏi dài hoặc danh sách khảo sát cố định cho người dùng. 
Mọi lượt tương tác phỏng vấn phải tuân thủ nghiêm ngặt 3 nguyên lý:

1. **Tự Động Trích Xuất Bằng Chứng Tối Đa**: Trước khi hỏi bất kỳ điều gì, Agent phải đọc toàn bộ tài liệu đầu vào (`ho-so-va-muc-tieu.md`, `bao-cao-hien-trang.md`, `UNKNOWNS_AND_COVERAGE.md`, `active_case.json`, manifest, assets, và mã nguồn). Cấm bắt người dùng nhắc lại những thông tin đã có bằng chứng xác thực.
2. **Định Hướng Theo Quyết Định (Decision-Driven Questioning)**: Mỗi câu hỏi đặt ra phải phục vụ trực tiếp cho một quyết định kỹ thuật hoặc nghiệp vụ cụ thể. Nếu không có quyết định nào phụ thuộc vào câu trả lời, câu hỏi đó là vô nghĩa và bị loại bỏ.
3. **Thích Ứng Theo Chiều Sâu & Rủi Ro**: Số lượng câu hỏi không cố định. Một ca sửa lỗi nhỏ có thể cần 0-1 câu làm rõ. Một dự án tái cấu trúc toàn diện có thể cần nhiều vòng phỏng vấn chuyên sâu.

---

## 2. Hợp Đồng Vận Hành 12 Bước (The 12-Step Adaptive Cycle)

```
USER GOAL (Mục tiêu ban đầu của người dùng)
    ↓
1. CONTEXT INGESTION (Nạp hồ sơ, mục tiêu, cấu hình ban đầu)
    ↓
2. EVIDENCE ANALYSIS (Đối chiếu các bằng chứng thực tế từ mã nguồn và hiện trạng)
    ↓
3. GOAL DECOMPOSITION (Bóc tách mục tiêu thành các bài toán cốt lõi)
    ↓
4. MISSING INFORMATION ANALYSIS (Xác định khoảng trống thông tin)
    ↓
5. DECISION IMPACT ANALYSIS (Đánh giá mức độ ảnh hưởng: Cửa 1 chiều hay 2 chiều)
    ↓
6. QUESTION CANDIDATE GENERATION (Sinh ứng viên câu hỏi theo 10 Domain chuyên biệt)
    ↓
7. NEXT BEST QUESTION SELECTION (Chọn câu hỏi giá trị nhất qua Question Necessity Engine)
    ↓
8. ANSWER INTERPRETATION (Diễn giải phản hồi theo 10 loại câu trả lời)
    ↓
9. INTERVIEW STATE UPDATE (Cập nhật .agents/state/interview_state.json qua interview.ps1)
    ↓
10. CONTRADICTION & REPETITION CHECK (Phát hiện mâu thuẫn & chống lặp câu hỏi)
    ↓
11. SUFFICIENCY RE-EVALUATION (Đánh giá tính đầy đủ qua Interview Exit Gate)
    ↓
12. CONTINUE (Hỏi câu tiếp theo) HOẶC COMPLETE (Chuyển sang Bước 07 lập đặc tả)
```

---

## 3. Phân Loại Nguồn Tin & Ranh Giới Dữ Liệu (6 Information Classes)

Mọi dữ liệu tiếp nhận được phân loại vào 6 nhãn tin cậy:
- `VERIFIED_FACT`: Dữ liệu đã kiểm chứng qua mã máy, tệp manifest, layout XML hoặc ảnh baseline. Cấm hỏi lại.
- `USER_STATED`: Yêu cầu người dùng trực tiếp đưa ra. Không hỏi lại trừ khi xuất hiện mâu thuẫn.
- `AI_INFERENCE`: Đề xuất suy luận của Agent. Phải nêu rõ là khuyến nghị, không được đánh đồng với quyết định của người dùng.
- `ASSUMPTION`: Giả định kỹ thuật an toàn của Agent khi người dùng không biết. Phải ghi nhận rủi ro (`BENIGN`/`CRITICAL`) và nhiệm vụ kiểm chứng.
- `UNKNOWN`: Điểm mù kỹ thuật chưa thể giải mã.
- `CONFLICT`: Mâu thuẫn trực tiếp giữa 2 yêu cầu hoặc giữa yêu cầu và bằng chứng thực tế.

---

## 4. Công Thức Ưu Tiên & 8 Bộ Lọc Câu Hỏi (Question Necessity Engine)

### 4.1 Công Thức Ưu Tiên:
$$\text{Priority} = \text{Decision Impact} \times \text{Information Gap} \times \text{Risk Relevance} \times \text{Uncertainty}$$

### 4.2 Tám Bộ Lọc Triệt Tiêu Câu Hỏi Thừa:
1. **Filter 1 - Known (Đã biết)**: Đã có trong hồ sơ hoặc lịch sử? ➔ **HUỶ BỎ**.
2. **Filter 2 - Inspectable (Tự đọc được)**: Xác định được qua phân tích tĩnh mã nguồn / manifest? ➔ **TỰ ĐỌC & HUỶ BỎ**.
3. **Filter 3 - Evidence (Đã có bằng chứng)**: Đã có ảnh chụp baseline hoặc báo cáo kiểm toán? ➔ **TRÍCH DẪN & HUỶ BỎ**.
4. **Filter 4 - Decision Impact (Ảnh hưởng quyết định)**: Có thay đổi trực tiếp kiến trúc hoặc code Stage 04 không? ➔ Nếu không: **HUỶ BỎ**.
5. **Filter 5 & 6 - Risk / Reversibility (Rủi ro & Thuận nghịch)**: Rủi ro thấp và là cửa hai chiều (Two-Way Door)? ➔ **TỰ CHỌN GIẢ ĐỊNH AN TOÀN, LƯU VÀO ASSUMPTION RECORD**.
6. **Filter 7 - Ownership (Thẩm quyền quyết định)**: Người dùng là PO. Khi chi tiết thuộc kỹ thuật cài đặt ($Ownership = \text{FALSE}$) ➔ **AGENT TỰ QUYẾT ĐỊNH KỸ THUẬT & KHÓA VÀO SPEC NỘI BỘ (NHÁNH 5)**.
7. **Filter 8 - Timing (Đúng thời điểm)**: Thông tin có cần ngay trong Stage 03 không? ➔ Nếu chưa cần: **HOÃN SANG GIAI ĐOẠN SAU (DEFER)**.

### 4.3 Tách Bạch Nhu Cầu Sản Phẩm Với Quyền Thực Thi Của Agent (R10):
- Hỏi người dùng về tính năng sản phẩm: "Ứng dụng có cần kết nối máy chủ không hay chạy offline hoàn toàn?"
- **CẤM** hỏi người dùng về các cờ nội bộ kỹ thuật như `-AllowHighRisk`. Quyền hạn công cụ do Coordinator quản trị độc lập.

---

## 5. Diễn Giải 10 Loại Câu Trả Lời & Quản Trị Mâu Thuẫn

| Loại Phản Hồi | Bản Chất Phản Hồi | Hành Động Điều Phối Của Agent |
| :--- | :--- | :--- |
| `CLEAR` | Câu trả lời dứt khoát, rõ ràng | Ghi nhận vào Decision Record (`APPROVED`). Chuyển tiếp. |
| `PARTIAL` | Chỉ trả lời một phần câu hỏi | Ghi nhận phần đã có, chỉ hỏi đúng phần còn thiếu. |
| `AMBIGUOUS` | Câu trả lời mơ hồ ("làm sao cũng được") | Đưa ra 2-3 tùy chọn cụ thể kèm khuyến nghị để người dùng chốt. |
| `UNKNOWN` | "Tôi không biết / Nhờ AI quyết định" | Đề xuất phương án tối ưu, giải thích ngắn gọn, ghi vào `Assumption Record`. |
| `CONDITIONAL`| "Nếu A thì B, nếu C thì D" | Đưa điều kiện logic vào bảng quy tắc nghiệp vụ. |
| `MULTIPLE_CHOICES`| Chọn nhiều phương án cùng lúc | Phân rã thành danh sách ưu tiên theo MoSCoW. |
| `CONFLICTING`| Mâu thuẫn với câu trả lời trước đó | Kích hoạt Contradiction Resolution: giữ nguyên ý cũ, giải thích mâu thuẫn, xin lựa chọn định hướng. |
| `OUT_OF_SCOPE`| Đề xuất tính năng ngoài phạm vi ca | Ghi nhận vào danh mục `Non-Goals` hoặc `Future Backlog`. |
| `NEW_REQUIREMENT`| Bổ sung yêu cầu mới | Ghi nhận Goal mới, tính toán lại thông tin còn thiếu. |
| `SCOPE_CHANGE`| Đổi ý định cốt lõi ban đầu | Ghi nhận Scope Change, giữ nguyên các quyết định không bị ảnh hưởng, chỉ hỏi bổ sung phần mới. |

---

## 6. Quy Tắc Chống Lặp Câu Hỏi (Repetition Prevention)

Agent chỉ được phép lặp lại câu hỏi khi thỏa mãn ít nhất 1 trong 4 điều kiện:
1. Thông tin thu thập trước đó không đủ để giải quyết điểm mù kiến trúc.
2. Bằng chứng mới thu thập được làm vô hiệu hóa câu trả lời cũ.
3. Quyết định đã bị thay đổi do tác động của một module phụ thuộc.
4. Cần sự phê duyệt xác nhận minh thị trước khi đóng băng đặc tả.
*Lý do lặp lại bắt buộc phải được ghi rõ vào bản ghi câu hỏi.*

---

## 7. Cổng Nghiệm Thu Đầy Đủ Thông Tin (Interview Exit Gate)

Trước khi đóng băng đặc tả tại Bước 07/08, Agent bắt buộc chạy kiểm định:
`powershell -NoProfile -ExecutionPolicy Bypass -File .agents/scripts/interview.ps1 evaluate-sufficiency`

### Điều Kiện Đạt Chuẩn (`SUFFICIENT`):
1. Tất cả mục tiêu (`active goals`) đều đã có quyết định hoặc giả định bao phủ.
2. Không còn mâu thuẫn mức `CRITICAL` hoặc `MAJOR` chưa được giải quyết.
3. Không còn giả định rủi ro cao (`CRITICAL`) ở trạng thái chờ phê duyệt (`PENDING_APPROVAL`).
4. Các khía cạnh cốt lõi (Chức năng, Phi chức năng, Bảo mật, Dữ liệu, Nền tảng, Tiêu chí nghiệm thu) đã đạt ngưỡng xác thực.

Nếu chưa đạt chuẩn, hệ thống trả về `NEEDS_INPUT` hoặc `BLOCKED` và chỉ rõ câu hỏi hoặc quyết định cần giải quyết tiếp theo.
