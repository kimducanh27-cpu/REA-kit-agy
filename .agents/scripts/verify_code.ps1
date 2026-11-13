# Script Kiểm Tra Xác Định Mã Nguồn (Deterministic Code Verification)
# Triết lý: Dùng công cụ xác định cho lỗi xác định; chỉ dùng AI ở phần cần suy luận.
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
$htmlFiles = Get-ChildItem -Path $TargetDir -Filter "*.html" -Recurse
if ($htmlFiles.Count -eq 0) {
    Write-Host " [CẢNH BÁO] Không tìm thấy file .html để chạy trực tiếp trên trình duyệt." -ForegroundColor Yellow
} else {
    Write-Host " [PASS] Đã phát hiện $($htmlFiles.Count) file HTML (sẵn sàng cho Zero-Install)." -ForegroundColor Green
}

# 2. Kiểm tra cú pháp HTML & Cặp thẻ cơ bản
Write-Host "`n[2. KIỂM TRA CÚ PHÁP TÀI NGUYÊN WEB]" -ForegroundColor Yellow
foreach ($file in $htmlFiles) {
    $content = Get-Content $file.FullName -Raw
    # Kiểm tra các thẻ mở cơ bản
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

# 3. Kiểm tra cú pháp JavaScript (dùng node --check nếu có Node.js)
Write-Host "`n[3. KIỂM TRA CÚ PHÁP JAVASCRIPT]" -ForegroundColor Yellow
$jsFiles = Get-ChildItem -Path $TargetDir -Filter "*.js" -Recurse
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
$filesToCheck = Get-ChildItem -Path $TargetDir -Include "*.html","*.js","*.json","*.py","*.env" -Recurse
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

Write-Host "==========================================================" -ForegroundColor Cyan
if ($hasError) {
    Write-Host " KẾT QUẢ: KIỂM CHỨNG XÁC ĐỊNH THẤT BẠI (FAILED)            " -ForegroundColor Red
    Write-Host " Yêu cầu Agent sửa lại lỗi xác định trước khi báo hoàn thành!" -ForegroundColor Red
    Write-Host "==========================================================" -ForegroundColor Cyan
    exit 1
} else {
    Write-Host " KẾT QUẢ: KIỂM CHỨNG XÁC ĐỊNH THÀNH CÔNG (PASSED - EXIT 0)" -ForegroundColor Green
    Write-Host " Mã nguồn sẵn sàng cho tầng đánh giá ngữ cảnh và nghiệm thu." -ForegroundColor Green
    Write-Host "==========================================================" -ForegroundColor Cyan
    exit 0
}
