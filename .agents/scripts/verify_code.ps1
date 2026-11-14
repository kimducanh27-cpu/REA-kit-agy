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
    $pattern = '(?s)(/\*.*?\*/)|(?m)(//[^\r\n]*)|("""[\s\S]*?""")|("(?:\\.|[^"\\\r\n])*")|(''(?:\\.|[^''\\\r\n])*'')|(`(?:\\.|[^`\\])*`)'
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
    $pattern = '(?s)(/\*.*?\*/)|(?m)(//[^\r\n]*)|(<!--.*?-->)|("""[\s\S]*?""")|("(?:\\.|[^"\\\r\n])*")|(''(?:\\.|[^''\\\r\n])*'')|(`(?:\\.|[^`\\])*`)'
    return [regex]::Replace($Code, $pattern, {
        param($m)
        if ($m.Groups[1].Success -or $m.Groups[2].Success -or $m.Groups[3].Success) {
            return ""
        }
        return $m.Value
    })
}

function Get-ShannonEntropy {
    param([string]$String)
    if ([string]::IsNullOrEmpty($String)) { return 0.0 }
    $len = $String.Length
    $freq = @{}
    foreach ($char in $String.ToCharArray()) {
        if ($freq.ContainsKey($char)) { $freq[$char]++ } else { $freq[$char] = 1 }
    }
    $entropy = 0.0
    foreach ($count in $freq.Values) {
        $p = [double]$count / $len
        $entropy -= $p * [Math]::Log($p, 2)
    }
    return $entropy
}

function Convert-HexToRgb {
    param([string]$Hex)
    if ([string]::IsNullOrWhiteSpace($Hex)) { return $null }
    $clean = $Hex.Trim().TrimStart('#')
    if ($clean.Length -eq 3) {
        $r = [Convert]::ToInt32("$($clean[0])$($clean[0])", 16)
        $g = [Convert]::ToInt32("$($clean[1])$($clean[1])", 16)
        $b = [Convert]::ToInt32("$($clean[2])$($clean[2])", 16)
        return @{ R = $r; G = $g; B = $b }
    } elseif ($clean.Length -ge 6) {
        $r = [Convert]::ToInt32($clean.Substring(0, 2), 16)
        $g = [Convert]::ToInt32($clean.Substring(2, 2), 16)
        $b = [Convert]::ToInt32($clean.Substring(4, 2), 16)
        return @{ R = $r; G = $g; B = $b }
    }
    return $null
}

function Get-RelativeLuminance {
    param($Rgb)
    if (-not $Rgb) { return 0.0 }
    $channels = @($Rgb.R, $Rgb.G, $Rgb.B)
    $linear = @()
    foreach ($c in $channels) {
        $s = [double]$c / 255.0
        if ($s -le 0.03928) {
            $linear += ($s / 12.92)
        } else {
            $linear += [Math]::Pow((($s + 0.055) / 1.055), 2.4)
        }
    }
    return (0.2126 * $linear[0]) + (0.7152 * $linear[1]) + (0.0722 * $linear[2])
}

function Get-WcagContrastRatio {
    param([string]$Hex1, [string]$Hex2)
    $rgb1 = Convert-HexToRgb -Hex $Hex1
    $rgb2 = Convert-HexToRgb -Hex $Hex2
    if (-not $rgb1 -or -not $rgb2) { return 0.0 }
    $l1 = Get-RelativeLuminance -Rgb $rgb1
    $l2 = Get-RelativeLuminance -Rgb $rgb2
    $lighter = [Math]::Max($l1, $l2)
    $darker = [Math]::Min($l1, $l2)
    return [Math]::Round((($lighter + 0.05) / ($darker + 0.05)), 2)
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
    '(?i)(?:password|passwd|pwd|api[_-]?key|secret[_-]?key|access[_-]?token|auth[_-]?token|storePassword|keyPassword)\s*[:=]\s*["''](?!\[REDACTED\]|YOUR_|REPLACE_|TODO|EXAMPLE|<|\$\{)[^"''\r\n]{6,}["'']'
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

    # 4.1 Quét regex rò rỉ chuỗi thô
    foreach ($pat in $leakPatterns) {
        if ($text -match $pat) {
            Write-Host " [FAIL] Phát hiện chuỗi nhạy cảm chưa che mờ [REDACTED] tại: $($f.FullName)" -ForegroundColor Red
            $secretFound = $true
            $hasError = $true
        }
    }

    # 4.2 Quét Base64-encoded secrets: Giải mã các token base64 dài >= 24 ký tự và kiểm tra chuỗi giải mã
    $base64Candidates = [regex]::Matches($text, '\b[A-Za-z0-9+/]{24,}={0,2}\b')
    foreach ($candMatch in $base64Candidates) {
        $cand = $candMatch.Value
        try {
            $bytes = [System.Convert]::FromBase64String($cand)
            if ($bytes -and $bytes.Length -ge 16) {
                $decoded = [System.Text.Encoding]::UTF8.GetString($bytes)
                foreach ($pat in $leakPatterns) {
                    if ($decoded -match $pat) {
                        Write-Host " [FAIL] Phát hiện Secret mã hóa Base64 ($cand -> $pat) tại: $($f.FullName)" -ForegroundColor Red
                        $secretFound = $true
                        $hasError = $true
                        break
                    }
                }
            }
        } catch {}
    }

    # 4.3 Quét chuỗi có Entropy cao (Shannon Entropy >= 4.5) được gán cho các biến nhạy cảm
    $assignedSecretMatches = [regex]::Matches($text, '(?i)(?:password|passwd|pwd|api[_-]?key|secret[_-]?key|access[_-]?token|auth[_-]?token)\s*[:=]\s*["''](?<val>[^"''\r\n]{16,})["'']')
    foreach ($asm in $assignedSecretMatches) {
        $val = $asm.Groups['val'].Value
        if ($val -notmatch '(?i)\[REDACTED\]|YOUR_|REPLACE_|TODO|EXAMPLE|<|\$\{|null|false|true|\*\*\*') {
            $entropy = Get-ShannonEntropy -String $val
            if ($entropy -ge 4.5) {
                Write-Host " [FAIL] Phát hiện bí mật có độ hỗn loạn cao (Shannon Entropy: $([Math]::Round($entropy, 2))) tại: $($f.FullName)" -ForegroundColor Red
                $secretFound = $true
                $hasError = $true
            }
        }
    }

    # 4.4 Quét mảng byte Hex bí mật (16 bytes trở lên)
    if ($text -match '(?i)(?:key|secret|token|aes|cipher)\w*\s*[:=]\s*(?:new\s+byte\[\]\s*)?\{\s*(?:0x[0-9a-f]{1,2}\s*,\s*){15,}0x[0-9a-f]{1,2}\s*\}') {
        Write-Host " [FAIL] Phát hiện mảng Hex byte nhạy cảm nghi là khóa mã hóa tại: $($f.FullName)" -ForegroundColor Red
        $secretFound = $true
        $hasError = $true
    }
}
if (-not $secretFound) {
    Write-Host " [PASS] Không phát hiện API key, mật khẩu thô hoặc token mã hóa Base64/High-Entropy ($($filesToScanSecrets.Count) files đã quét trên cả mã nguồn và báo cáo)." -ForegroundColor Green
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
    if ($codeNoComments -cmatch '\beval\s*\(' -or $codeNoComments -cmatch '\bnew\s+Function\s*\(' -or $codeNoComments -cmatch '\bwindow\.Function\s*\(') { $highRiskIndicators += "$($f.Name): Thực thi mã động eval()/Function()" }
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
        try {
            [xml]$xmlDoc = Get-Content -LiteralPath $m.FullName -Raw -Encoding UTF8
            if (-not $xmlDoc.manifest) {
                Write-Host " [FAIL] AndroidManifest ($($m.Name)) thiếu thẻ gốc <manifest>." -ForegroundColor Red
                $hasError = $true
            } else {
                Write-Host " [PASS] $($m.Name): Cú pháp XML và thẻ <manifest> hợp lệ ([xml] parser)." -ForegroundColor Green
            }
        } catch {
            Write-Host " [FAIL] $($m.Name): Lỗi cú pháp XML không hợp lệ: $_" -ForegroundColor Red
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

# 7. Kiểm tra Token Drift & CDN Bên Ngoài trong Route A (Token Drift & Route A Offline Check)
Write-Host "`n[7. KIỂM TRA ĐỘ LỆCH TOKEN & OFFLINE ROUTE A (TOKEN DRIFT CHECK)]" -ForegroundColor Yellow

$tokenFileNames = @("tokens.css", "tokens.json", "color.kt", "colors.xml", "dimens.xml", "type.kt", "shape.kt", "design.md")
$isTokenFile = {
    param([System.IO.FileInfo]$FileInfo)
    $name = $FileInfo.Name.ToLower()
    if ($tokenFileNames -contains $name) { return $true }
    if ($name -match 'token') { return $true }
    return $false
}

$tokenDriftFound = $false
$cdnFound = $false

$uiFiles = @(Get-ChildItem -LiteralPath $resolvedTarget -Recurse -File -Force | Where-Object {
    $_.FullName -notmatch $backupPathRegex -and
    @(".html", ".css", ".js", ".ts", ".kt", ".java", ".xml") -contains $_.Extension.ToLower()
})

foreach ($f in $uiFiles) {
    $rawContent = Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8
    if ([string]::IsNullOrWhiteSpace($rawContent)) { continue }
    $codeClean = Remove-CommentsOnly -Code $rawContent

    # 7.1 Kiểm tra nhúng external CDN trong Route A (bắt buộc 100% offline-first)
    if ($htmlFiles.Count -gt 0 -and ($f.Extension.ToLower() -eq ".html" -or $f.Extension.ToLower() -eq ".css" -or $f.Extension.ToLower() -eq ".js")) {
        $cdnPatterns = @(
            'https?://(?:cdn\.|cdnjs\.|unpkg\.|cdn\.jsdelivr\.net|maxcdn\.|stackpath\.|fonts\.googleapis\.com|cdn\.tailwindcss\.com)',
            '(?i)<(?:script|link)\b[^>]*(?:src|href)\s*=\s*["'']https?://'
        )
        foreach ($cp in $cdnPatterns) {
            $cdnMatches = [regex]::Matches($codeClean, $cp)
            foreach ($cm in $cdnMatches) {
                Write-Host " [FAIL] Tuyến Route A phát hiện nhúng CDN bên ngoài tại $($f.Name): $($cm.Value)" -ForegroundColor Red
                Write-Host "        -> Route A bắt buộc 100% offline-first zero-install, cấm nhúng CDN mạng ngoài." -ForegroundColor Red
                $cdnFound = $true
                $hasError = $true
            }
        }
    }

    # 7.2 Kiểm tra gán cứng mã màu hex / rgb ngoài file compiled tokens
    if (-not (& $isTokenFile $f)) {
        if ($f.Extension.ToLower() -in @(".css", ".html", ".js", ".ts")) {
            $hexMatches = [regex]::Matches($codeClean, '(?i)(?:color|background|border|fill|stroke)\s*:\s*(#[0-9a-fA-F]{3,8})\b')
            foreach ($hm in $hexMatches) {
                $colorVal = $hm.Groups[1].Value
                Write-Host " [FAIL] Token Drift tại $($f.Name): Phát hiện mã màu hex gán cứng '$colorVal'" -ForegroundColor Red
                Write-Host "        -> Bắt buộc sử dụng CSS variable token (ví dụ: var(--color-primary)) thay vì hex cứng." -ForegroundColor Red
                $tokenDriftFound = $true
                $hasError = $true
            }
            $rgbMatches = [regex]::Matches($codeClean, '(?i)(?:color|background|border|fill|stroke)\s*:\s*(rgba?\s*\([^)]+\))')
            foreach ($rm in $rgbMatches) {
                $colorVal = $rm.Groups[1].Value
                Write-Host " [FAIL] Token Drift tại $($f.Name): Phát hiện màu rgb/rgba gán cứng '$colorVal'" -ForegroundColor Red
                Write-Host "        -> Bắt buộc sử dụng CSS variable token thay vì rgb() cứng." -ForegroundColor Red
                $tokenDriftFound = $true
                $hasError = $true
            }
        } elseif ($f.Extension.ToLower() -in @(".kt", ".java")) {
            $colorNativeMatches = [regex]::Matches($codeClean, '(?i)\b(?:Color\s*\(\s*0x[0-9a-fA-F]{6,8}\b|Color\s*\.\s*(?:parseColor|rgb|argb)\s*\()')
            foreach ($cnm in $colorNativeMatches) {
                Write-Host " [FAIL] Token Drift tại $($f.Name): Phát hiện gán cứng $($cnm.Value)" -ForegroundColor Red
                Write-Host "        -> Bắt buộc sử dụng ColorTokens từ Design Token compiled file." -ForegroundColor Red
                $tokenDriftFound = $true
                $hasError = $true
            }
        } elseif ($f.Extension.ToLower() -eq ".xml" -and $f.Name -ne "colors.xml") {
            $xmlColorMatches = [regex]::Matches($codeClean, '(?i)(?:android:(?:textColor|background|tint|color)|app:(?:tint|backgroundTint))\s*=\s*["''](#[0-9a-fA-F]{3,8})["'']')
            foreach ($xcm in $xmlColorMatches) {
                $colorVal = $xcm.Groups[1].Value
                Write-Host " [FAIL] Token Drift tại $($f.Name): Phát hiện mã màu gán cứng '$colorVal'" -ForegroundColor Red
                Write-Host "        -> Bắt buộc tham chiếu @color/... từ colors.xml thay vì gán trực tiếp." -ForegroundColor Red
                $tokenDriftFound = $true
                $hasError = $true
            }
        }
    }
}

if (-not $cdnFound) {
    if ($htmlFiles.Count -gt 0) {
        Write-Host " [PASS] Tuyến Route A đạt chuẩn 100% Offline-First: Không phát hiện nhúng CDN bên ngoài." -ForegroundColor Green
    }
}
if (-not $tokenDriftFound) {
    Write-Host " [PASS] Token Drift Check: Toàn bộ mã màu UI đều tuân thủ Design Tokens hợp lệ." -ForegroundColor Green
}

# 8. Kiểm tra Độ Tương Phản WCAG AA (WCAG AA Contrast Check >= 4.5:1)
Write-Host "`n[8. KIỂM TRA ĐỘ TƯƠNG PHẢN WCAG AA (>= 4.5:1 TEXT/BG CONTRAST)]" -ForegroundColor Yellow
$contrastFailures = @()
$pairsChecked = 0

$tokenFiles = @(Get-ChildItem -LiteralPath $resolvedTarget -Recurse -File -Force | Where-Object {
    $_.FullName -notmatch $backupPathRegex -and (& $isTokenFile $_)
})
$specTokenDir = Join-Path $repoRoot "02_YEU_CAU_CUA_TOI"
if (Test-Path -LiteralPath $specTokenDir) {
    $tokenFiles += @(Get-ChildItem -LiteralPath $specTokenDir -File | Where-Object {
        $_.Name -match 'token' -or $_.Name -eq "design.md"
    })
}

$colorMap = @{}
foreach ($tf in $tokenFiles) {
    $tText = Get-Content -LiteralPath $tf.FullName -Raw -Encoding UTF8
    if ([string]::IsNullOrWhiteSpace($tText)) { continue }
    $cssVarMatches = [regex]::Matches($tText, '(?m)--([a-zA-Z0-9_-]+)\s*:\s*(#[0-9a-fA-F]{3,8})')
    foreach ($m in $cssVarMatches) {
        $varName = $m.Groups[1].Value.ToLower()
        $varVal = $m.Groups[2].Value
        $colorMap[$varName] = $varVal
    }
    $jsonValMatches = [regex]::Matches($tText, '(?i)"(?:color[_-])?([a-zA-Z0-9_-]+)"\s*:\s*\{\s*"value"\s*:\s*"(#[0-9a-fA-F]{3,8})"')
    foreach ($m in $jsonValMatches) {
        $varName = $m.Groups[1].Value.ToLower()
        $varVal = $m.Groups[2].Value
        $colorMap[$varName] = $varVal
    }
    $xmlValMatches = [regex]::Matches($tText, '(?i)<color\s+name=["'']([^"'']+)["'']>(#[0-9a-fA-F]{3,8})</color>')
    foreach ($m in $xmlValMatches) {
        $varName = $m.Groups[1].Value.ToLower()
        $varVal = $m.Groups[2].Value
        $colorMap[$varName] = $varVal
    }
}

$textKeyPatterns = @("text", "foreground", "on-background", "on-surface", "on-primary", "content")
$bgKeyPatterns   = @("background", "surface", "bg", "container", "card")

$textKeys = @($colorMap.Keys | Where-Object {
    $k = $_
    $matched = $false
    foreach ($tp in $textKeyPatterns) { if ($k -match $tp) { $matched = $true; break } }
    $matched
})
$bgKeys = @($colorMap.Keys | Where-Object {
    $k = $_
    $matched = $false
    foreach ($bp in $bgKeyPatterns) { if ($k -match $bp) { $matched = $true; break } }
    $matched
})

foreach ($tk in $textKeys) {
    foreach ($bk in $bgKeys) {
        $textColor = $colorMap[$tk]
        $bgColor = $colorMap[$bk]
        if ($textColor -and $bgColor -and $textColor -ne $bgColor) {
            $ratio = Get-WcagContrastRatio -Hex1 $textColor -Hex2 $bgColor
            if ($ratio -gt 0) {
                $pairsChecked++
                if ($ratio -lt 4.5) {
                    $contrastFailures += "Cặp [$tk ($textColor) / $bk ($bgColor)]: Tỷ lệ ${ratio}:1 (< 4.5:1)"
                }
            }
        }
    }
}

$cssFiles = @(Get-ChildItem -LiteralPath $resolvedTarget -Filter "*.css" -Recurse | Where-Object { $_.FullName -notmatch $backupPathRegex })
foreach ($cf in $cssFiles) {
    $cssRaw = Get-Content -LiteralPath $cf.FullName -Raw -Encoding UTF8
    $ruleMatches = [regex]::Matches($cssRaw, '(?s)([^{}]+)\{([^}]+)\}')
    foreach ($rm in $ruleMatches) {
        $body = $rm.Groups[2].Value
        $fgM = [regex]::Match($body, '(?i)(?<![a-zA-Z-])color\s*:\s*(#[0-9a-fA-F]{3,8})')
        $bgM = [regex]::Match($body, '(?i)background(?:-color)?\s*:\s*(#[0-9a-fA-F]{3,8})')
        if ($fgM.Success -and $bgM.Success) {
            $fgVal = $fgM.Groups[1].Value
            $bgVal = $bgM.Groups[1].Value
            $ratio = Get-WcagContrastRatio -Hex1 $fgVal -Hex2 $bgVal
            if ($ratio -gt 0) {
                $pairsChecked++
                if ($ratio -lt 4.5) {
                    $contrastFailures += "$($cf.Name) [selector: $($rm.Groups[1].Value.Trim())]: $fgVal trên $bgVal tỷ lệ ${ratio}:1 (< 4.5:1)"
                }
            }
        }
    }
}

if ($contrastFailures.Count -gt 0) {
    Write-Host " [FAIL] Phát hiện $($contrastFailures.Count) trường hợp vi phạm độ tương phản WCAG AA (< 4.5:1):" -ForegroundColor Red
    foreach ($cfMsg in $contrastFailures) {
        Write-Host "     - $cfMsg" -ForegroundColor Red
    }
    $hasError = $true
} elseif ($pairsChecked -gt 0) {
    Write-Host " [PASS] Đã kiểm tra $pairsChecked cặp màu text/bg; toàn bộ đều đạt độ tương phản WCAG AA (>= 4.5:1)." -ForegroundColor Green
} else {
    Write-Host " [INFO] Không tìm thấy cặp màu tĩnh text/bg trực tiếp trong mã nguồn để đo tương phản." -ForegroundColor Gray
}

# 9. Kiểm tra Nguồn Gốc Tài Nguyên (Asset Provenance Check)
Write-Host "`n[9. KIỂM TRA NGUỒN GỐC TÀI NGUYÊN (ASSET PROVENANCE CHECK)]" -ForegroundColor Yellow
$assetExtensions = @(".png", ".jpg", ".jpeg", ".svg", ".webp", ".gif", ".ico", ".bmp", ".ttf", ".otf", ".woff", ".woff2")
$assetsInTarget = @(Get-ChildItem -LiteralPath $resolvedTarget -Recurse -File -Force | Where-Object {
    $_.FullName -notmatch $backupPathRegex -and $assetExtensions -contains $_.Extension.ToLower()
})

if ($assetsInTarget.Count -eq 0) {
    Write-Host " [INFO] Không có tệp hình ảnh/font/icon trong $resolvedTarget cần kiểm tra nguồn gốc." -ForegroundColor Gray
} else {
    $provenanceDirs = @(
        (Join-Path $repoRoot "01_THA_APP_VAO_DAY"),
        (Join-Path $repoRoot "04_SAO_LUU_AN_TOAN")
    )
    $knownAssetNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $knownAssetHashes = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    foreach ($pDir in $provenanceDirs) {
        if (Test-Path -LiteralPath $pDir) {
            $pFiles = @(Get-ChildItem -LiteralPath $pDir -Recurse -File -Force -ErrorAction SilentlyContinue | Where-Object {
                $assetExtensions -contains $_.Extension.ToLower()
            })
            foreach ($pf in $pFiles) {
                [void]$knownAssetNames.Add($pf.Name)
                try {
                    $hash = (Get-FileHash -LiteralPath $pf.FullName -Algorithm SHA256).Hash
                    [void]$knownAssetHashes.Add($hash)
                } catch {}
            }
        }
    }

    $allowlistLocations = @(
        (Join-Path $repoRoot "ASSET_ALLOWLIST.md"),
        (Join-Path $repoRoot "02_YEU_CAU_CUA_TOI/ASSET_ALLOWLIST.md"),
        (Join-Path $repoRoot "05_MA_NGUON_PHAT_TRIEN/ASSET_ALLOWLIST.md"),
        (Join-Path $repoRoot "docs/ASSET_ALLOWLIST.md")
    )
    $allowlistContent = ""
    foreach ($alLoc in $allowlistLocations) {
        if (Test-Path -LiteralPath $alLoc) {
            $allowlistContent += "`n" + (Get-Content -LiteralPath $alLoc -Raw -Encoding UTF8)
        }
    }

    $unauthorizedAssets = @()
    foreach ($af in $assetsInTarget) {
        $matched = $false
        if ($knownAssetNames.Contains($af.Name)) { $matched = $true }
        if (-not $matched) {
            try {
                $afHash = (Get-FileHash -LiteralPath $af.FullName -Algorithm SHA256).Hash
                if ($knownAssetHashes.Contains($afHash)) { $matched = $true }
            } catch {}
        }
        if (-not $matched -and -not [string]::IsNullOrWhiteSpace($allowlistContent)) {
            if ($allowlistContent -match [regex]::Escape($af.Name)) {
                $matched = $true
            }
        }

        if (-not $matched) {
            $unauthorizedAssets += $af
        }
    }

    if ($unauthorizedAssets.Count -gt 0) {
        Write-Host " [FAIL] Phát hiện $($unauthorizedAssets.Count) tài nguyên không rõ nguồn gốc (Asset Provenance Violation):" -ForegroundColor Red
        foreach ($ua in $unauthorizedAssets) {
            Write-Host "     - $($ua.Name) ($($ua.FullName))" -ForegroundColor Red
            Write-Host "       -> Tài nguyên này không có trong 01_THA_APP_VAO_DAY/, 04_SAO_LUU_AN_TOAN/ và chưa được khai báo trong ASSET_ALLOWLIST.md!" -ForegroundColor Red
        }
        $hasError = $true
    } else {
        Write-Host " [PASS] Toàn bộ $($assetsInTarget.Count) tài nguyên (ảnh, font, icon) đều có nguồn gốc hợp lệ từ ứng dụng gốc hoặc ASSET_ALLOWLIST.md." -ForegroundColor Green
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
