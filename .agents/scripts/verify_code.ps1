# Script Kiểm Tra Xác Định Mã Nguồn & Phân Loại Rủi Ro Tự Động (Deterministic Verification & Risk Classifier)
# Triết lý: Dùng công cụ xác định cho lỗi xác định; phân tầng rủi ro theo chuẩn Anthropic Code Review.
param (
    [string]$TargetDir = "05_MA_NGUON_PHAT_TRIEN"
)

$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Tree-climbing từ $PSScriptRoot để tìm docs\WORKFLOW_LIFECYCLE.md và xác định $repoRoot
$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = (Get-Location).Path }
$current = $scriptDir
$repoRoot = $null
while ($current) {
    if (Test-Path (Join-Path $current "docs\WORKFLOW_LIFECYCLE.md")) {
        $repoRoot = $current
        break
    }
    $parent = Split-Path $current -Parent
    if ($parent -eq $current -or [string]::IsNullOrEmpty($parent)) { break }
    $current = $parent
}
if (-not $repoRoot) {
    $repoRoot = (Get-Location).Path
}

# Phân giải đường dẫn $TargetDir so với $repoRoot nếu là đường dẫn tương đối
$resolvedTarget = if ([System.IO.Path]::IsPathRooted($TargetDir)) {
    $TargetDir
} else {
    Join-Path $repoRoot $TargetDir
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   KIỂM TRA XÁC ĐỊNH MÃ NGUỒN (DETERMINISTIC VERIFICATION)  " -ForegroundColor Cyan
Write-Host "   Repo Root:  $repoRoot" -ForegroundColor DarkCyan
Write-Host "   Mục tiêu:   $resolvedTarget" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

if (-not (Test-Path $resolvedTarget)) {
    Write-Host "[FAIL] Không tìm thấy thư mục mục tiêu: $resolvedTarget" -ForegroundColor Red
    exit 1
}

# Kiểm tra thư mục có trống rỗng hoàn toàn không
$allFilesInTarget = Get-ChildItem -Path $resolvedTarget -Recurse -File | Where-Object {
    $_.FullName -notmatch "\\\.backup\\" -and $_.Name -ne ".gitkeep"
}
if ($allFilesInTarget.Count -eq 0) {
    Write-Host "[FAIL] Thư mục mục tiêu rỗng hoàn toàn hoặc chỉ có .gitkeep (TargetDir is empty): $resolvedTarget" -ForegroundColor Red
    exit 1
}

$hasError = $false

# Helper function loại bỏ comment và chuỗi ký tự trước khi đếm ngoặc nhọn {}
function Remove-CommentsAndStrings {
    param([string]$Code)
    if ([string]::IsNullOrEmpty($Code)) { return "" }
    # Loại bỏ comment khối /* ... */
    $c = [regex]::Replace($Code, '/\*[\s\S]*?\*/', '')
    # Loại bỏ comment dòng đơn // ...
    $c = [regex]::Replace($c, '//.*$', '', [System.Text.RegularExpressions.RegexOptions]::Multiline)
    # Loại bỏ chuỗi nháy đơn '...'
    $c = [regex]::Replace($c, "'(?:\\.|[^\\'\r\n])*'", "''")
    # Loại bỏ chuỗi nháy kép "..."
    $c = [regex]::Replace($c, '"(?:\\.|[^\\"\r\n])*"', '""')
    # Loại bỏ template literal `...` (kể cả nhiều dòng)
    $c = [regex]::Replace($c, '`[\s\S]*?`', '``')
    return $c
}

# 1. Kiểm tra kiến trúc & file khởi động (Zero-Install Check & Android Target Check)
Write-Host "`n[1. KIẾN TRÚC & FILE ENTRY]" -ForegroundColor Yellow
$htmlFiles = Get-ChildItem -Path $resolvedTarget -Filter "*.html" -Recurse | Where-Object { $_.FullName -notmatch "\\\.backup\\" }
$androidManifests = Get-ChildItem -Path $resolvedTarget -Filter "AndroidManifest.xml" -Recurse | Where-Object { $_.FullName -notmatch "\\\.backup\\" }
$gradleFiles = Get-ChildItem -Path $resolvedTarget -Filter "*build.gradle*" -Recurse | Where-Object { $_.FullName -notmatch "\\\.backup\\" }
$isAndroidProject = ($androidManifests.Count -gt 0 -or $gradleFiles.Count -gt 0)

if ($htmlFiles.Count -gt 0) {
    Write-Host " [PASS] Đã phát hiện $($htmlFiles.Count) file HTML (sẵn sàng cho Zero-Install Web)." -ForegroundColor Green
} elseif ($isAndroidProject) {
    Write-Host " [PASS] Đã phát hiện cấu trúc dự án Android Native ($($androidManifests.Count) AndroidManifest.xml, $($gradleFiles.Count) build.gradle)." -ForegroundColor Green
} else {
    Write-Host " [CẢNH BÁO] Không tìm thấy file .html hoặc cấu trúc dự án Android để thực thi trực tiếp." -ForegroundColor Yellow
}

# 2. Kiểm tra cú pháp HTML & Cặp thẻ cơ bản (sử dụng word boundary \b tránh false-positive <header> khớp <head>)
Write-Host "`n[2. KIỂM TRA CÚ PHÁP TÀI NGUYÊN WEB]" -ForegroundColor Yellow
foreach ($file in $htmlFiles) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    $basicTags = @("html", "head", "body")
    foreach ($tag in $basicTags) {
        if ($content -match "<$tag\b" -and -not ($content -match "</$tag\b>")) {
            Write-Host " [FAIL] File $($file.Name) thiếu thẻ đóng </$tag>" -ForegroundColor Red
            $hasError = $true
        }
    }
}
if ($htmlFiles.Count -eq 0) {
    Write-Host " [INFO] Không có file HTML cần kiểm tra cặp thẻ." -ForegroundColor Gray
} elseif (-not $hasError) {
    Write-Host " [PASS] Cấu trúc các file HTML hợp lệ (không phát hiện thẻ mở thiếu thẻ đóng)." -ForegroundColor Green
}

# 3. Kiểm tra cú pháp JavaScript
Write-Host "`n[3. KIỂM TRA CÚ PHÁP JAVASCRIPT]" -ForegroundColor Yellow
$jsFiles = Get-ChildItem -Path $resolvedTarget -Filter "*.js" -Recurse | Where-Object { $_.FullName -notmatch "\\\.backup\\" }
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
    Write-Host " [INFO] Kiểm tra token ngoặc nhọn với hàm khử comment và chuỗi ký tự." -ForegroundColor Gray
    foreach ($js in $jsFiles) {
        $raw = Get-Content $js.FullName -Raw -Encoding UTF8
        $clean = Remove-CommentsAndStrings -Code $raw
        $openBraces = ($clean.ToCharArray() | Where-Object { $_ -eq '{' }).Count
        $closeBraces = ($clean.ToCharArray() | Where-Object { $_ -eq '}' }).Count
        if ($openBraces -ne $closeBraces) {
            Write-Host " [FAIL] File $($js.Name) không cân bằng ngoặc nhọn: {$openBraces mở, $closeBraces đóng}" -ForegroundColor Red
            $hasError = $true
        } else {
            Write-Host " [PASS] File $($js.Name) cân bằng ngoặc nhọn ($openBraces cặp)." -ForegroundColor Green
        }
    }
} else {
    Write-Host " [INFO] Không có file .js riêng biệt." -ForegroundColor Gray
}

# 4. Quét phát hiện rò rỉ Secret / API Key thô (Định dạng hiện đại: OpenAI, Anthropic, GitHub PAT, Google)
Write-Host "`n[4. QUÉT RÒ RỈ SECRET & API KEY]" -ForegroundColor Yellow
$leakPatterns = @(
    "sk-[a-zA-Z0-9_-]{20,}",
    "sk-ant-[a-zA-Z0-9_-]{20,}",
    "(?:ghp_|github_pat_)[0-9a-zA-Z_]{36,}",
    "AIza[0-9A-Za-z-_]{35}",
    "password\s*=\s*['`"][^'`"]+['`"]"
)

# Bao gồm các phần mở rộng web, scripts, và Android (*.kt, *.java, *.xml, *.gradle)
$checkExts = @(".html", ".js", ".json", ".py", ".env", ".kt", ".java", ".xml", ".gradle")
$filesToCheck = Get-ChildItem -Path $resolvedTarget -Recurse -File | Where-Object {
    $_.FullName -notmatch "\\\.backup\\" -and (
        $checkExts -contains $_.Extension.ToLower() -or
        $_.Name -like "*.gradle" -or
        $_.Name -like "*.gradle.kts"
    )
}

$secretFound = $false
foreach ($f in $filesToCheck) {
    $text = Get-Content $f.FullName -Raw -Encoding UTF8
    foreach ($pat in $leakPatterns) {
        if ($text -match $pat) {
            Write-Host " [FAIL] Phát hiện chuỗi nhạy cảm khớp mẫu bí mật tại: $($f.Name)" -ForegroundColor Red
            $secretFound = $true
            $hasError = $true
        }
    }
}
if (-not $secretFound) {
    Write-Host " [PASS] Không phát hiện API key hoặc mật khẩu thô trong mã nguồn ($($filesToCheck.Count) files đã quét)." -ForegroundColor Green
}

# 5. Phân loại rủi ro tự động (Automated Risk Classifier — Anthropic Model)
# Whitelist namespace XML: http://(?!www\.w3\.org/) để không cảnh báo nhầm xmlns="http://www.w3.org/2000/svg"
Write-Host "`n[5. PHÂN LOẠI RỦI RO TỰ ĐỘNG (AUTOMATED RISK CLASSIFIER)]" -ForegroundColor Yellow
$riskLevel = "LOW"
$highRiskIndicators = @()
$mediumRiskIndicators = @()

foreach ($f in $filesToCheck) {
    $code = Get-Content $f.FullName -Raw -Encoding UTF8
    
    # Quét chỉ dấu rủi ro cao (Outbound network, APIs, Dynamic code evaluation, Insecure HTTP)
    if ($code -match "fetch\s*\(") { $highRiskIndicators += "$($f.Name): Gọi mạng fetch()" }
    if ($code -match "XMLHttpRequest") { $highRiskIndicators += "$($f.Name): Gọi AJAX XMLHttpRequest" }
    if ($code -match "WebSocket") { $highRiskIndicators += "$($f.Name): Mở kết nối WebSocket" }
    if ($code -match "eval\s*\(") { $highRiskIndicators += "$($f.Name): Sử dụng hàm eval()" }
    if ($code -match "http://(?!www\.w3\.org/)") {
        # Bỏ qua các XML namespace chuẩn của Android (schemas.android.com)
        $cleanedHttp = [regex]::Replace($code, 'http://schemas\.android\.com/[^\s"''<>]+', '')
        if ($cleanedHttp -match "http://(?!www\.w3\.org/)") {
            $highRiskIndicators += "$($f.Name): Kết nối HTTP không bảo mật"
        }
    }
    
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

# 6. Kiểm tra cấu trúc dự án Android (Android Project Structure Verification)
if ($isAndroidProject) {
    Write-Host "`n[6. KIỂM TRA DỰ ÁN ANDROID (ANDROID PROJECT VERIFICATION)]" -ForegroundColor Yellow
    Write-Host " [INFO] Phát hiện dự án Android ($($androidManifests.Count) AndroidManifest.xml, $($gradleFiles.Count) build.gradle)." -ForegroundColor Cyan
    
    foreach ($m in $androidManifests) {
        $mContent = Get-Content $m.FullName -Raw -Encoding UTF8
        if ($mContent -match "<manifest\b" -and -not ($mContent -match "</manifest\b>")) {
            Write-Host " [FAIL] AndroidManifest ($($m.Name)) thiếu thẻ đóng </manifest>" -ForegroundColor Red
            $hasError = $true
        } else {
            Write-Host " [PASS] $($m.Name): Thẻ <manifest> hợp lệ." -ForegroundColor Green
        }
        if ($mContent -match "<application\b" -and -not ($mContent -match "</application\b>")) {
            Write-Host " [FAIL] AndroidManifest ($($m.Name)) thiếu thẻ đóng </application>" -ForegroundColor Red
            $hasError = $true
        }
    }
    
    foreach ($g in $gradleFiles) {
        $gContent = Get-Content $g.FullName -Raw -Encoding UTF8
        $gClean = Remove-CommentsAndStrings -Code $gContent
        $openG = ($gClean.ToCharArray() | Where-Object { $_ -eq '{' }).Count
        $closeG = ($gClean.ToCharArray() | Where-Object { $_ -eq '}' }).Count
        if ($openG -ne $closeG) {
            Write-Host " [FAIL] File $($g.Name) không cân bằng ngoặc nhọn: {$openG mở, $closeG đóng}" -ForegroundColor Red
            $hasError = $true
        } else {
            Write-Host " [PASS] File $($g.Name) cân bằng ngoặc nhọn ($openG cặp)." -ForegroundColor Green
        }
    }

    $sourceFiles = Get-ChildItem -Path $resolvedTarget -Include "*.kt", "*.java" -Recurse | Where-Object { $_.FullName -notmatch "\\\.backup\\" }
    if ($sourceFiles.Count -gt 0) {
        Write-Host " [PASS] Đã phát hiện $($sourceFiles.Count) file mã nguồn Android (.kt / .java)." -ForegroundColor Green
    }
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
