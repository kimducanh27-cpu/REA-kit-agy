# Script Kiểm Tra Xác Định Mã Nguồn, Báo Cáo & Phân Loại Rủi Ro Tự Động (Deterministic Verification & Risk Classifier v1.1)
# Triết lý: Dùng công cụ xác định cho lỗi xác định; phân tầng rủi ro theo chuẩn Anthropic Code Review Pipeline.
param (
    [string]$TargetDir = "05_MA_NGUON_PHAT_TRIEN",
    [string]$ReportDir = "03_KET_QUA_KIEM_TRA",
    [switch]$AllowHighRisk
)

$ErrorActionPreference = "Continue"
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Tree-climbing từ $PSScriptRoot để tìm docs/WORKFLOW_LIFECYCLE.md và xác định $repoRoot
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$current = $scriptDir
$repoRoot = $null
while ($current) {
    if (Test-Path (Join-Path $current "docs/WORKFLOW_LIFECYCLE.md")) {
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

$resolvedTarget = if ([System.IO.Path]::IsPathRooted($TargetDir)) { $TargetDir } else { Join-Path $repoRoot $TargetDir }
$resolvedReport = if ([System.IO.Path]::IsPathRooted($ReportDir)) { $ReportDir } else { Join-Path $repoRoot $ReportDir }
$backupPathRegex = '[\\\/]\.backup[\\\/]'

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   KIỂM TRA XÁC ĐỊNH MÃ NGUỒN (DETERMINISTIC VERIFY v1.1) " -ForegroundColor Cyan
Write-Host "   Repo Root : $repoRoot" -ForegroundColor DarkCyan
Write-Host "   Mã nguồn  : $resolvedTarget" -ForegroundColor Cyan
Write-Host "   Báo cáo   : $resolvedReport" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

if (-not (Test-Path -LiteralPath $resolvedTarget)) {
    Write-Host "[FAIL] Không tìm thấy thư mục mục tiêu: $resolvedTarget" -ForegroundColor Red
    exit 1
}

$allFilesInTarget = @(Get-ChildItem -LiteralPath $resolvedTarget -Recurse -File -Force | Where-Object {
    $_.FullName -notmatch $backupPathRegex -and $_.Name -ne ".gitkeep"
})
if ($allFilesInTarget.Count -eq 0) {
    Write-Host "[FAIL] Thư mục mục tiêu rỗng hoàn toàn hoặc chỉ có .gitkeep (TargetDir is empty): $resolvedTarget" -ForegroundColor Red
    exit 1
}

$hasError = $false

# Single-Pass Alternation Regex: Khớp chuỗi ký tự VÀ comment trong cùng 1 lượt quét trái sang phải.
# Ngăn chặn lỗi xóa nhầm 'https://...' bên trong chuỗi làm mất dấu nháy đóng và lệch cặp ngoặc nhọn {}.
function Remove-CommentsAndStrings {
    param([string]$Code)
    if ([string]::IsNullOrEmpty($Code)) { return "" }
    $pattern = '(?s)(/\*.*?\*/)|(?m)(//[^\r\n]*)|("(?:\\.|[^"\\\r\n])*")|(''(?:\\.|[^''\\\r\n])*'')|(`(?:\\.|[^`\\])*`)'
    return [regex]::Replace($Code, $pattern, {
        param($m)
        if ($m.Groups[1].Success -or $m.Groups[2].Success) {
            return ""
        }
        return '""'
    })
}

# Single-Pass Alternation Regex: Khớp comment VÀ chuỗi ký tự, nhưng CHỈ xóa comment, GIỮ NGUYÊN chuỗi ký tự.
# Ngăn chặn lỗi regex vô tình xóa 'http://...' hoặc '//' bên trong chuỗi string.
function Remove-CommentsOnly {
    param([string]$Code)
    if ([string]::IsNullOrEmpty($Code)) { return "" }
    $pattern = '(?s)(/\*.*?\*/)|(?m)(//[^\r\n]*)|(<!--.*?-->)|("(?:\\.|[^"\\\r\n])*")|(''(?:\\.|[^''\\\r\n])*'')|(`(?:\\.|[^`\\])*`)'
    return [regex]::Replace($Code, $pattern, {
        param($m)
        if ($m.Groups[1].Success -or $m.Groups[2].Success -or $m.Groups[3].Success) {
            return ""
        }
        return $m.Value
    })
}

# 1. Kiểm tra kiến trúc & file khởi động (Route A Web Zero-Install vs Route B/C Android)
Write-Host "`n[1. KIẾN TRÚC & FILE ENTRY]" -ForegroundColor Yellow
$htmlFiles = @(Get-ChildItem -LiteralPath $resolvedTarget -Filter "*.html" -Recurse | Where-Object { $_.FullName -notmatch $backupPathRegex })
$androidManifests = @(Get-ChildItem -LiteralPath $resolvedTarget -Filter "AndroidManifest.xml" -Recurse | Where-Object { $_.FullName -notmatch $backupPathRegex })
$gradleFiles = @(Get-ChildItem -LiteralPath $resolvedTarget -Filter "*build.gradle*" -Recurse | Where-Object { $_.FullName -notmatch $backupPathRegex })
$isAndroidProject = ($androidManifests.Count -gt 0 -or $gradleFiles.Count -gt 0)

if ($htmlFiles.Count -gt 0) {
    Write-Host " [PASS] Đã phát hiện $($htmlFiles.Count) file HTML (sẵn sàng cho Route A Zero-Install Web)." -ForegroundColor Green
} elseif ($isAndroidProject) {
    Write-Host " [PASS] Đã phát hiện cấu trúc dự án Android Native ($($androidManifests.Count) AndroidManifest.xml, $($gradleFiles.Count) build.gradle*)." -ForegroundColor Green
} else {
    Write-Host " [CẢNH BÁO] Không tìm thấy file .html hoặc cấu trúc dự án Android để thực thi trực tiếp." -ForegroundColor Yellow
}

# 2. Kiểm tra cú pháp HTML & Cặp thẻ cơ bản
Write-Host "`n[2. KIỂM TRA CÚ PHÁP TÀI NGUYÊN WEB]" -ForegroundColor Yellow
foreach ($file in $htmlFiles) {
    $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    $basicTags = @("html", "head", "body")
    foreach ($tag in $basicTags) {
        if ($content -match "(?i)<$tag\b" -and -not ($content -match "(?i)</$tag\s*>")) {
            Write-Host " [FAIL] File $($file.Name) thiếu thẻ đóng </$tag>" -ForegroundColor Red
            $hasError = $true
        }
    }
}
if ($htmlFiles.Count -eq 0) {
    Write-Host " [INFO] Không có file HTML cần kiểm tra cặp thẻ." -ForegroundColor Gray
} elseif (-not $hasError) {
    Write-Host " [PASS] Cấu trúc các file HTML hợp lệ (đủ cặp thẻ đóng/mở)." -ForegroundColor Green
}

# 3. Kiểm tra cú pháp JavaScript (Cả file .js độc lập VÀ khối <script> inline trong .html)
Write-Host "`n[3. KIỂM TRA CÚ PHÁP JAVASCRIPT (EXTERNAL & INLINE <SCRIPT>)]" -ForegroundColor Yellow
$jsFiles = @(Get-ChildItem -LiteralPath $resolvedTarget -Filter "*.js" -Recurse | Where-Object { $_.FullName -notmatch $backupPathRegex })
$nodeCmd = Get-Command "node" -ErrorAction SilentlyContinue

function Test-JsCodeBlock {
    param([string]$JsContent, [string]$SourceLabel, [string]$FilePathForNode)
    if ([string]::IsNullOrWhiteSpace($JsContent)) { return $true }
    if ($nodeCmd) {
        $targetNodeFile = $FilePathForNode
        $cleanupTemp = $false
        if (-not $targetNodeFile) {
            $targetNodeFile = Join-Path ([System.IO.Path]::GetTempPath()) ("rea_inline_" + [guid]::NewGuid().ToString("N") + ".js")
            Set-Content -LiteralPath $targetNodeFile -Value $JsContent -Encoding UTF8
            $cleanupTemp = $true
        }
        try {
            $checkOutput = & node --check $targetNodeFile 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Host " [FAIL] Cú pháp JS lỗi tại ${SourceLabel}: $checkOutput" -ForegroundColor Red
                return $false
            } else {
                Write-Host " [PASS] ${SourceLabel}: Cú pháp JavaScript hợp lệ (node --check)." -ForegroundColor Green
                return $true
            }
        } finally {
            if ($cleanupTemp -and (Test-Path -LiteralPath $targetNodeFile)) {
                Remove-Item -LiteralPath $targetNodeFile -Force -ErrorAction SilentlyContinue
            }
        }
    } else {
        $clean = Remove-CommentsAndStrings -Code $JsContent
        $openBraces = ($clean.ToCharArray() | Where-Object { $_ -eq '{' }).Count
        $closeBraces = ($clean.ToCharArray() | Where-Object { $_ -eq '}' }).Count
        if ($openBraces -ne $closeBraces) {
            Write-Host " [FAIL] ${SourceLabel} không cân bằng ngoặc nhọn: {$openBraces mở, $closeBraces đóng}" -ForegroundColor Red
            return $false
        } else {
            Write-Host " [WARN - HEURISTIC ONLY] ${SourceLabel}: Node.js không khả dụng; chỉ kiểm tra cân bằng ngoặc nhọn ($openBraces cặp, chưa qua AST compiler)." -ForegroundColor Yellow
            $script:hasHeuristicJs = $true
            return $true
        }
    }
}

$checkedAnyJs = $false
foreach ($js in $jsFiles) {
    $checkedAnyJs = $true
    $rawJs = Get-Content -LiteralPath $js.FullName -Raw -Encoding UTF8
    if (-not (Test-JsCodeBlock -JsContent $rawJs -SourceLabel $js.Name -FilePathForNode $js.FullName)) {
        $hasError = $true
    }
}

foreach ($html in $htmlFiles) {
    $rawHtml = Get-Content -LiteralPath $html.FullName -Raw -Encoding UTF8
    $scriptBlocks = [regex]::Matches($rawHtml, '(?is)<script(?![^>]*\bsrc\s*=)(?![^>]*\btype\s*=\s*["''](?:application/json|application/ld\+json|importmap|text/template)["''])[^>]*>(.*?)</script>')
    $blockIdx = 0
    foreach ($blk in $scriptBlocks) {
        $blockIdx++
        $inlineJs = $blk.Groups[1].Value
        if (-not [string]::IsNullOrWhiteSpace($inlineJs)) {
            $checkedAnyJs = $true
            if (-not (Test-JsCodeBlock -JsContent $inlineJs -SourceLabel "$($html.Name) [inline <script #$blockIdx>]" -FilePathForNode "")) {
                $hasError = $true
            }
        }
    }
}

if (-not $checkedAnyJs) {
    Write-Host " [INFO] Không có file .js hoặc khối <script> inline cần kiểm tra." -ForegroundColor Gray
}

# 4. Quét phát hiện rò rỉ Secret / API Key thô (Quét cả Mã nguồn 05_ và Báo cáo 03_; loại trừ [REDACTED])
Write-Host "`n[4. QUÉT RÒ RỈ SECRET & API KEY (MÃ NGUỒN & BÁO CÁO)]" -ForegroundColor Yellow
$leakPatterns = @(
    'sk-[a-zA-Z0-9_-]{20,}',
    'sk-ant-[a-zA-Z0-9_-]{20,}',
    '(?:ghp|gho|ghu|ghs|ghr|github_pat)_[0-9a-zA-Z_]{36,}',
    'AIza[0-9A-Za-z\-_]{35}',
    'AKIA[0-9A-Z]{16}',
    '-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----',
    'eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}',
    '(?i)(?:password|passwd|pwd|api[_-]?key|secret[_-]?key|access[_-]?token|auth[_-]?token|storePassword|keyPassword)\s*[:=]\s*["'']?(?!\[REDACTED\]|YOUR_|REPLACE_|TODO|EXAMPLE|<|\$\{|null|false|true|\*\*\*)[^"''\s,;]{6,}["'']?'
)

$checkExts = @(".html", ".js", ".ts", ".json", ".py", ".env", ".kt", ".kts", ".java", ".xml", ".gradle", ".properties", ".toml", ".yaml", ".yml", ".smali", ".md")
$filesToScanSecrets = @(Get-ChildItem -LiteralPath $resolvedTarget -Recurse -File -Force | Where-Object {
    $_.FullName -notmatch $backupPathRegex -and ($checkExts -contains $_.Extension.ToLower() -or $_.Name -like "*.gradle*" -or $_.Name -like ".env*")
})
if (Test-Path -LiteralPath $resolvedReport) {
    $filesToScanSecrets += @(Get-ChildItem -LiteralPath $resolvedReport -Recurse -File -Force | Where-Object {
        $_.Name -ne ".gitkeep" -and ($checkExts -contains $_.Extension.ToLower())
    })
}

$secretFound = $false
foreach ($f in $filesToScanSecrets) {
    $text = Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8
    if ([string]::IsNullOrEmpty($text)) { continue }
    foreach ($pat in $leakPatterns) {
        if ($text -match $pat) {
            Write-Host " [FAIL] Phát hiện chuỗi nhạy cảm chưa che mờ [REDACTED] tại: $($f.FullName)" -ForegroundColor Red
            $secretFound = $true
            $hasError = $true
        }
    }
}
if (-not $secretFound) {
    Write-Host " [PASS] Không phát hiện API key hoặc mật khẩu thô ($($filesToScanSecrets.Count) files đã quét trên cả mã nguồn và báo cáo)." -ForegroundColor Green
}

# 5. Phân loại rủi ro tự động (Automated Risk Classifier — Anthropic Model cho Web & Android)
Write-Host "`n[5. PHÂN LOẠI RỦI RO TỰ ĐỘNG (AUTOMATED RISK CLASSIFIER)]" -ForegroundColor Yellow
$riskLevel = "LOW"
$highRiskIndicators = @()
$mediumRiskIndicators = @()

$codeFilesToCheck = @(Get-ChildItem -LiteralPath $resolvedTarget -Recurse -File -Force | Where-Object {
    $_.FullName -notmatch $backupPathRegex -and $_.Name -ne ".gitkeep" -and $_.Extension.ToLower() -ne ".md"
})

foreach ($f in $codeFilesToCheck) {
    $rawCode = Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8
    if ([string]::IsNullOrEmpty($rawCode)) { continue }
    # Loại bỏ comment dòng/khối, GIỮ NGUYÊN chuỗi string để không làm đứt đoạn URL http://
    $codeNoComments = Remove-CommentsOnly -Code $rawCode

    # Chỉ dấu HIGH RISK (Web & Android Native: Outbound Network, Dynamic Code Eval, Shell Exec, Insecure Cleartext HTTP)
    if ($codeNoComments -match '\bfetch\s*\(') { $highRiskIndicators += "$($f.Name): Gọi mạng fetch()" }
    if ($codeNoComments -match '\bXMLHttpRequest\b') { $highRiskIndicators += "$($f.Name): Gọi AJAX XMLHttpRequest" }
    if ($codeNoComments -match '\bWebSocket\b') { $highRiskIndicators += "$($f.Name): Mở kết nối WebSocket" }
    if ($codeNoComments -match '\b(?:eval|Function)\s*\(') { $highRiskIndicators += "$($f.Name): Thực thi mã động eval()/Function()" }
    if ($codeNoComments -match '\b(?:OkHttpClient|Retrofit|HttpURLConnection)\b') { $highRiskIndicators += "$($f.Name): Kết nối mạng Android (OkHttp/Retrofit/HttpURLConnection)" }
    if ($codeNoComments -match '\b(?:Runtime\.getRuntime\(\)\.exec|ProcessBuilder|DexClassLoader)\b') { $highRiskIndicators += "$($f.Name): Thực thi tiến trình/nạp mã động Android (exec/ProcessBuilder/DexClassLoader)" }
    if ($codeNoComments -match 'http://(?!www\.w3\.org/|schemas\.android\.com/|schemas\.openxmlformats\.org/|localhost|127\.0\.0\.1)') {
        $highRiskIndicators += "$($f.Name): Kết nối HTTP không mã hóa (Cleartext HTTP)"
    }

    # Chỉ dấu MEDIUM RISK (Local Storage, Database, SharedPreferences, Form handling)
    if ($codeNoComments -match '\blocalStorage\b') { $mediumRiskIndicators += "$($f.Name): Đọc/ghi LocalStorage" }
    if ($codeNoComments -match '\bsessionStorage\b') { $mediumRiskIndicators += "$($f.Name): Đọc/ghi SessionStorage" }
    if ($codeNoComments -match '\bindexedDB\b') { $mediumRiskIndicators += "$($f.Name): Truy xuất IndexedDB" }
    if ($codeNoComments -match '\b(?:SharedPreferences|Room\.databaseBuilder|SQLiteOpenHelper)\b') { $mediumRiskIndicators += "$($f.Name): Lưu trữ cục bộ Android (SharedPreferences/Room/SQLite)" }
    if ($codeNoComments -match 'addEventListener\s*\(\s*[''"]submit[''"]') { $mediumRiskIndicators += "$($f.Name): Xử lý submit form" }
}

if ($highRiskIndicators.Count -gt 0) {
    $riskLevel = "HIGH"
    Write-Host " [CẢNH BÁO] CẤP ĐỘ RỦI RO: CAO (HIGH RISK)" -ForegroundColor Red
    foreach ($ind in $highRiskIndicators) { Write-Host "     - $ind" -ForegroundColor Red }
    if (-not $AllowHighRisk) {
        Write-Host "   -> [CHẶN CỔNG 04]: Phát hiện hành vi HIGH RISK chưa được phê duyệt. Nếu người dùng đã duyệt trong đặc tả, chạy lại kèm cờ -AllowHighRisk." -ForegroundColor Yellow
        $hasError = $true
    } else {
        Write-Host "   -> [ĐÃ PHÊ DUYỆT]: Cờ -AllowHighRisk được bật theo đặc tả người dùng." -ForegroundColor Yellow
    }
} elseif ($mediumRiskIndicators.Count -gt 0) {
    $riskLevel = "MEDIUM"
    Write-Host " [THÔNG TIN] CẤP ĐỘ RỦI RO: VỪA (MEDIUM RISK)" -ForegroundColor Yellow
    foreach ($ind in $mediumRiskIndicators) { Write-Host "     - $ind" -ForegroundColor Gray }
    Write-Host "   -> YÊU CẦU: Kiểm tra theo checklist tính năng lưu trữ cục bộ và biểu mẫu." -ForegroundColor Gray
} else {
    $riskLevel = "LOW"
    Write-Host " [AN TOÀN] CẤP ĐỘ RỦI RO: THẤP (LOW RISK)" -ForegroundColor Green
    Write-Host "   Mã nguồn thuần giao diện hiển thị nội dung, không có tác động mạng ngoài." -ForegroundColor Green
}

# 6. Kiểm tra cấu trúc dự án Android (Android Project Structure Verification)
if ($isAndroidProject) {
    Write-Host "`n[6. KIỂM TRA DỰ ÁN ANDROID (ANDROID PROJECT VERIFICATION)]" -ForegroundColor Yellow
    foreach ($m in $androidManifests) {
        $mContent = Get-Content -LiteralPath $m.FullName -Raw -Encoding UTF8
        if ($mContent -match "<manifest\b" -and -not ($mContent -match "</manifest\s*>")) {
            Write-Host " [FAIL] AndroidManifest ($($m.Name)) thiếu thẻ đóng </manifest>" -ForegroundColor Red
            $hasError = $true
        } else {
            Write-Host " [PASS] $($m.Name): Thẻ <manifest> hợp lệ." -ForegroundColor Green
        }
        if ($mContent -match "<application\b" -and -not ($mContent -match "</application\s*>")) {
            Write-Host " [FAIL] AndroidManifest ($($m.Name)) thiếu thẻ đóng </application>" -ForegroundColor Red
            $hasError = $true
        }
    }

    foreach ($g in $gradleFiles) {
        $gContent = Get-Content -LiteralPath $g.FullName -Raw -Encoding UTF8
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

    $sourceFiles = @(Get-ChildItem -LiteralPath $resolvedTarget -Recurse -File | Where-Object {
        $_.FullName -notmatch $backupPathRegex -and ($_.Extension -eq ".kt" -or $_.Extension -eq ".java")
    })
    if ($sourceFiles.Count -gt 0) {
        Write-Host " [PASS] Đã phát hiện $($sourceFiles.Count) file mã nguồn Android (.kt / .java)." -ForegroundColor Green
    }
}

Write-Host "`n==========================================================" -ForegroundColor Cyan
if ($hasError) {
    Write-Host " KẾT QUẢ: KIỂM CHỨNG XÁC ĐỊNH THẤT BẠI (FAILED - EXIT 1)   " -ForegroundColor Red
    Write-Host " Yêu cầu Agent khắc phục lỗi trước khi mở Cổng 04!" -ForegroundColor Red
    Write-Host "==========================================================" -ForegroundColor Cyan
    exit 1
} else {
    Write-Host " KẾT QUẢ: KIỂM CHỨNG XÁC ĐỊNH THÀNH CÔNG (PASSED - EXIT 0)" -ForegroundColor Green
    Write-Host " Phân loại rủi ro: [$riskLevel] | Sẵn sàng cho nghiệm thu người dùng." -ForegroundColor Green
    if ($script:hasHeuristicJs) {
        Write-Host " [LƯU Ý]: Kiểm tra JS chạy ở chế độ HEURISTIC do thiếu Node.js runtime." -ForegroundColor Yellow
    }
    Write-Host "==========================================================" -ForegroundColor Cyan
    exit 0
}
