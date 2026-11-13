# Script Kiểm Tra Xác Định Mã Nguồn & Phân Loại Rủi Ro Tự Động (Deterministic Verification & Risk Classifier)
# Triết lý: Dùng công cụ xác định cho lỗi xác định; phân tầng rủi ro theo chuẩn Anthropic Code Review.
param (
    [string]$TargetDir = "05_MA_NGUON_PHAT_TRIEN"
)

$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   KIỂM TRA XÁC ĐỊNH MÃ NGUỒN (DETERMINISTIC VERIFICATION)  " -ForegroundColor Cyan
Write-Host "   Mục tiêu: $TargetDir                                  " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

if (-not (Test-Path $TargetDir)) {
    Write-Host "[FAIL] Không tìm thấy thư mục mục tiêu: $TargetDir" -ForegroundColor Red
    exit 1
}

$hasError = $false

# 1. Kiểm tra kiến trúc & file khởi động (Zero-Install Check)
Write-Host "`n[1. KIẾN TRÚC & FILE ENTRY]" -ForegroundColor Yellow
$htmlFiles = Get-ChildItem -Path $TargetDir -Filter "*.html" -Recurse | Where-Object { $_.FullName -notmatch "\\\.backup\\" }
if ($htmlFiles.Count -eq 0) {
    Write-Host " [CẢNH BÁO] Không tìm thấy file .html để chạy trực tiếp trên trình duyệt." -ForegroundColor Yellow
} else {
    Write-Host " [PASS] Đã phát hiện $($htmlFiles.Count) file HTML (sẵn sàng cho Zero-Install)." -ForegroundColor Green
}

# 2. Kiểm tra cú pháp HTML & Cặp thẻ cơ bản
Write-Host "`n[2. KIỂM TRA CÚ PHÁP TÀI NGUYÊN WEB]" -ForegroundColor Yellow
foreach ($file in $htmlFiles) {
    $content = Get-Content $file.FullName -Raw
    $basicTags = @("html", "head", "body")
    foreach ($tag in $basicTags) {
        if ($content -match "<$tag" -and -not ($content -match "</$tag>")) {
            Write-Host " [FAIL] File $($file.Name) thiếu thẻ đóng </$tag>" -ForegroundColor Red
            $hasError = $true
        }
    }
}
if (-not $hasError) {
    Write-Host " [PASS] Cấu trúc các file HTML hợp lệ." -ForegroundColor Green
}

# 3. Kiểm tra cú pháp JavaScript
Write-Host "`n[3. KIỂM TRA CÚ PHÁP JAVASCRIPT]" -ForegroundColor Yellow
$jsFiles = Get-ChildItem -Path $TargetDir -Filter "*.js" -Recurse | Where-Object { $_.FullName -notmatch "\\\.backup\\" }
$nodeCmd = Get-Command "node" -ErrorAction SilentlyContinue
if ($nodeCmd -and $jsFiles.Count -gt 0) {
    foreach ($js in $jsFiles) {
        $checkOutput = & node --check $js.FullName 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host " [FAIL] Cú pháp JS lỗi tại $($js.Name): $checkOutput" -ForegroundColor Red
            $hasError = $true
        } else {
            Write-Host " [PASS] $($js.Name): Cú pháp JavaScript hợp lệ (node --check)." -ForegroundColor Green
        }
    }
} elseif ($jsFiles.Count -gt 0) {
    Write-Host " [INFO] Không có Node.js trên máy, kiểm tra token ngoặc đóng/mở thủ công." -ForegroundColor Gray
    foreach ($js in $jsFiles) {
        $raw = Get-Content $js.FullName -Raw
        $openBraces = ($raw.ToCharArray() | Where-Object { $_ -eq '{' }).Count
        $closeBraces = ($raw.ToCharArray() | Where-Object { $_ -eq '}' }).Count
        if ($openBraces -ne $closeBraces) {
            Write-Host " [FAIL] File $($js.Name) không cân bằng ngoặc nhọn: {$openBraces mở, $closeBraces đóng}" -ForegroundColor Red
            $hasError = $true
        } else {
            Write-Host " [PASS] File $($js.Name) cân bằng ngoặc nhọn ($openBraces cặp)." -ForegroundColor Green
        }
    }
} else {
    Write-Host " [INFO] Không có file .js riêng biệt (mã có thể nhúng trực tiếp trong HTML)." -ForegroundColor Gray
}

# 4. Quét phát hiện rò rỉ Secret / API Key thô
Write-Host "`n[4. QUÉT RÒ RỈ SECRET & API KEY]" -ForegroundColor Yellow
$leakPatterns = @("sk-[a-zA-Z0-9]{20,}", "AIza[0-9A-Za-z-_]{35}", "ghp_[0-9a-zA-Z]{36}", "password\s*=\s*['`"][^'`"]+['`"]")
$filesToCheck = Get-ChildItem -Path $TargetDir -Include "*.html","*.js","*.json","*.py","*.env" -Recurse | Where-Object { $_.FullName -notmatch "\\\.backup\\" }
$secretFound = $false
foreach ($f in $filesToCheck) {
    $text = Get-Content $f.FullName -Raw
    foreach ($pat in $leakPatterns) {
        if ($text -match $pat) {
            Write-Host " [FAIL] Phát hiện chuỗi nhạy cảm khớp mẫu bí mật tại: $($f.Name)" -ForegroundColor Red
            $secretFound = $true
            $hasError = $true
        }
    }
}
if (-not $secretFound) {
    Write-Host " [PASS] Không phát hiện API key hoặc mật khẩu thô trong mã nguồn." -ForegroundColor Green
}

# 5. Phân loại rủi ro tự động (Automated Risk Classifier — Anthropic Model)
Write-Host "`n[5. PHÂN LOẠI RỦI RO TỰ ĐỘNG (AUTOMATED RISK CLASSIFIER)]" -ForegroundColor Yellow
$riskLevel = "LOW"
$highRiskIndicators = @()
$mediumRiskIndicators = @()

foreach ($f in $filesToCheck) {
    $code = Get-Content $f.FullName -Raw
    
    # Quét chỉ dấu rủi ro cao (Outbound network, APIs, Dynamic code evaluation)
    if ($code -match "fetch\s*\(") { $highRiskIndicators += "$($f.Name): Gọi mạng fetch()" }
    if ($code -match "XMLHttpRequest") { $highRiskIndicators += "$($f.Name): Gọi AJAX XMLHttpRequest" }
    if ($code -match "WebSocket") { $highRiskIndicators += "$($f.Name): Mở kết nối WebSocket" }
    if ($code -match "eval\s*\(") { $highRiskIndicators += "$($f.Name): Sử dụng hàm eval()" }
    if ($code -match "http://") { $highRiskIndicators += "$($f.Name): Kết nối HTTP không bảo mật" }
    
    # Quét chỉ dấu rủi ro trung bình (Local Storage, State persistence, Form handling)
    if ($code -match "localStorage") { $mediumRiskIndicators += "$($f.Name): Đọc/ghi LocalStorage" }
    if ($code -match "sessionStorage") { $mediumRiskIndicators += "$($f.Name): Đọc/ghi SessionStorage" }
    if ($code -match "indexedDB") { $mediumRiskIndicators += "$($f.Name): Truy xuất IndexedDB" }
    if ($code -match "addEventListener\s*\(\s*['`"]submit['`"]") { $mediumRiskIndicators += "$($f.Name): Xử lý submit form" }
}

if ($highRiskIndicators.Count -gt 0) {
    $riskLevel = "HIGH"
    Write-Host " [CẢNH BÁO] CẤP ĐỘ RỦI RO: CAO (HIGH RISK)" -ForegroundColor Red
    Write-Host "   Phát hiện các hành vi tác động ra mạng ngoài hoặc thực thi động:" -ForegroundColor Red
    foreach ($ind in $highRiskIndicators) { Write-Host "     - $ind" -ForegroundColor Red }
    Write-Host "   -> YÊU CẦU: Bắt buộc người dùng kiểm tra địa chỉ API trước khi nghiệm thu." -ForegroundColor Yellow
} elseif ($mediumRiskIndicators.Count -gt 0) {
    $riskLevel = "MEDIUM"
    Write-Host " [THÔNG TIN] CẤP ĐỘ RỦI RO: VỪA (MEDIUM RISK)" -ForegroundColor Yellow
    Write-Host "   Phát hiện logic lưu trữ dữ liệu cục bộ hoặc biểu mẫu:" -ForegroundColor Yellow
    foreach ($ind in $mediumRiskIndicators) { Write-Host "     - $ind" -ForegroundColor Gray }
    Write-Host "   -> YÊU CẦU: Người dùng nên nhấp thử các form và kiểm tra dữ liệu lưu đúng." -ForegroundColor Gray
} else {
    $riskLevel = "LOW"
    Write-Host " [AN TOÀN] CẤP ĐỘ RỦI RO: THẤP (LOW RISK)" -ForegroundColor Green
    Write-Host "   Mã nguồn thuần giao diện hiển thị nội dung, không có tác động mạng hay lưu trữ." -ForegroundColor Green
    Write-Host "   -> Tự động phê duyệt sau khi kiểm tra cú pháp đạt." -ForegroundColor Gray
}

Write-Host "`n==========================================================" -ForegroundColor Cyan
if ($hasError) {
    Write-Host " KẾT QUẢ: KIỂM CHỨNG XÁC ĐỊNH THẤT BẠI (FAILED)            " -ForegroundColor Red
    Write-Host " Yêu cầu Agent sửa lại lỗi xác định trước khi báo hoàn thành!" -ForegroundColor Red
    Write-Host "==========================================================" -ForegroundColor Cyan
    exit 1
} else {
    Write-Host " KẾT QUẢ: KIỂM CHỨNG XÁC ĐỊNH THÀNH CÔNG (PASSED - EXIT 0)" -ForegroundColor Green
    Write-Host " Phân loại rủi ro: [$riskLevel] | Sẵn sàng cho nghiệm thu người dùng." -ForegroundColor Green
    Write-Host "==========================================================" -ForegroundColor Cyan
    exit 0
}
