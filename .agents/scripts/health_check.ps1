# Script Kiểm tra Sức khỏe Toàn diện Workspace & Runtime REA-kit-agy v1.1
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

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   ĐANG KIỂM TRA HỆ THỐNG WORKSPACE REA-KIT-AGY v1.1...   " -ForegroundColor Cyan
Write-Host "   Repo Root: $repoRoot" -ForegroundColor DarkCyan
Write-Host "==========================================================" -ForegroundColor Cyan

$score = 0
$total = 6

# 1. Kiểm tra cấu trúc thư mục người dùng
$dirs = @("01_THA_APP_VAO_DAY", "02_YEU_CAU_CUA_TOI", "03_KET_QUA_KIEM_TRA", "04_SAO_LUU_AN_TOAN", "05_MA_NGUON_PHAT_TRIEN")
$allDirsOk = $true
foreach ($d in $dirs) {
    if (-not (Test-Path (Join-Path $repoRoot $d))) { $allDirsOk = $false }
}
if ($allDirsOk) {
    Write-Host "[OK] (1/6) Cấu trúc 5 thư mục giao diện người dùng đầy đủ." -ForegroundColor Green
    $score++
} else {
    Write-Host "[!] (1/6) Thiếu một số thư mục người dùng." -ForegroundColor Red
}

# 2. Kiểm tra tài liệu hướng dẫn và luật chơi cốt lõi
$coreDocs = @("AGENTS.md", "HUONG_DAN_SU_DUNG.md", "REVIEW.md")
$allCoreDocsOk = $true
foreach ($cd in $coreDocs) {
    if (-not (Test-Path (Join-Path $repoRoot $cd))) { $allCoreDocsOk = $false }
}
if ($allCoreDocsOk) {
    Write-Host "[OK] (2/6) File luật AGENTS.md, REVIEW.md và Hướng dẫn sử dụng đã sẵn sàng." -ForegroundColor Green
    $score++
} else {
    Write-Host "[!] (2/6) Thiếu AGENTS.md, HUONG_DAN_SU_DUNG.md hoặc REVIEW.md." -ForegroundColor Red
}

# 3. Kiểm tra Kỹ năng: 6 Skills điều phối + 1 Skill lõi Upstream (v62, đủ 8 references)
$skills = @("rea-scan", "rea-audit", "rea-interview", "rea-plan", "rea-build", "memory-consolidation", "reverse-engineer-anything")
$allSkillsOk = $true
foreach ($sk in $skills) {
    if (-not (Test-Path (Join-Path $repoRoot ".agents/skills/$sk/SKILL.md"))) { $allSkillsOk = $false }
}
if ($allSkillsOk) {
    Write-Host "[OK] (3/6) Bộ kỹ năng đầy đủ (6 skills điều phối + 1 skill lõi REA v62)." -ForegroundColor Green
    $score++
} else {
    Write-Host "[!] (3/6) Thiếu một trong các kỹ năng trong .agents/skills." -ForegroundColor Red
}

# 4. Kiểm tra Luật an toàn (Rules)
$rulePath = Join-Path $repoRoot ".agents/rules/rea-workflow.md"
if (Test-Path $rulePath) {
    $ruleContent = Get-Content -LiteralPath $rulePath -Raw -Encoding UTF8
    if ($ruleContent -match '(?m)^trigger:\s*always_on') {
        Write-Host "[OK] (4/6) Luật an toàn và bảo vệ dữ liệu đã kích hoạt (trigger: always_on verified)." -ForegroundColor Green
        $score++
    } else {
        Write-Host "[!] (4/6) Luật an toàn thiếu 'trigger: always_on' trong frontmatter (Antigravity sẽ bỏ qua rule)!" -ForegroundColor Red
    }
} else {
    Write-Host "[!] (4/6) Thiếu luật an toàn trong .agents/rules." -ForegroundColor Red
}

# 5. Kiểm tra Bộ nhớ ngữ cảnh (docs/) & Bộ nhớ 4 tầng (MEMORY.md, active_case.json, learned_rules.json)
$docs = @("docs/PRD.md", "docs/ARCHITECTURE.md", "docs/PROGRESS.md", "docs/HANDOFF.md", "docs/PLAN.md", "docs/WORKFLOW_LIFECYCLE.md")
$allDocsOk = $true
foreach ($doc in $docs) {
    if (-not (Test-Path (Join-Path $repoRoot $doc))) { $allDocsOk = $false }
}
$stateFiles = @(".agents/state/MEMORY.md", ".agents/state/learned_rules.json", ".agents/state/active_case.json")
foreach ($sf in $stateFiles) {
    if (-not (Test-Path (Join-Path $repoRoot $sf))) { $allDocsOk = $false }
}
if ($allDocsOk) {
    Write-Host "[OK] (5/6) Hồ sơ ngữ cảnh (docs/) và Bộ nhớ 4 tầng (MEMORY.md, active_case.json, learned_rules.json) hoàn chỉnh." -ForegroundColor Green
    $score++
} else {
    Write-Host "[!] (5/6) Thiếu tài liệu trong docs/ hoặc file state trong .agents/state/." -ForegroundColor Red
}

# 6. Kiểm tra REA Engine & MCP Runtime trên máy (Ưu tiên binary `rea` cài sẵn trước khi gọi `npx --no-install`)
$mcpOk = $false
try {
    $reaCmd = Get-Command rea -ErrorAction SilentlyContinue
    $doctorRaw = $null
    if ($reaCmd) {
        $doctorRaw = & rea doctor --client antigravity --json 2>$null
    } else {
        $npxCmd = Get-Command npx -ErrorAction SilentlyContinue
        if ($npxCmd) {
            $doctorRaw = & npx --no-install rea-agents doctor --client antigravity --json 2>$null
        }
    }
    if ($doctorRaw) {
        $rawStr = ($doctorRaw -join "`n")
        if ($rawStr -match '(?s)\{.*\}') {
            $doctorJson = $matches[0] | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($doctorJson -and ($doctorJson.healthy -eq $true -or ($doctorJson.registrations | Where-Object { $_.client -eq "antigravity" -and $_.state -eq "aligned" }))) {
                $mcpOk = $true
            }
        }
    }
} catch {
    $mcpOk = $false
}

if ($mcpOk) {
    Write-Host "[OK] (6/6) REA Registration: ALIGNED (Antigravity client configuration verified)." -ForegroundColor Green
    Write-Host "     [i] Lưu ý: Để gọi tool trực tiếp (RUNTIME_CONNECTED), cần có phiên Antigravity đang hoạt động." -ForegroundColor Gray
    $score++
} else {
    Write-Host "[!] (6/6) REA Engine chưa đăng ký hoặc cấu hình chưa khớp với Antigravity." -ForegroundColor Yellow
    Write-Host "     -> Khắc phục: Chạy lệnh sau để tự động cấu hình REA vào Antigravity:" -ForegroundColor Gray
    Write-Host "        npx -y rea-agents@6.9.0 setup --client antigravity --yes" -ForegroundColor Cyan
}

# 7. Kiểm tra Android CLI Tooling & Reverse Engineering Tools (JDK >= 17, JADX, Apktool, zipalign, adb)
$javaCmd = Get-Command java -ErrorAction SilentlyContinue
$javaOk = $false
$javaVerStr = "Không xác định"
if ($javaCmd) {
    try {
        $verOutput = & java -version 2>&1
        $verStr = ($verOutput -join "`n")
        if ($verStr -match 'version\s*"(\d+)(?:\.(\d+))?.*"') {
            $major = [int]$matches[1]
            if ($major -eq 1 -and $matches[2]) {
                $major = [int]$matches[2]
            }
            $javaVerStr = "$major"
            if ($major -ge 17) {
                $javaOk = $true
            }
        }
    } catch {}
}

if ($javaOk) {
    Write-Host "[OK] Java JDK (>= 17): Khả dụng (Phiên bản $javaVerStr - Sẵn sàng cho JADX & Apktool)." -ForegroundColor Green
} elseif ($javaCmd) {
    Write-Host "[!] Java JDK: Phiên bản $javaVerStr (< 17 - Cần nâng cấp lên JDK 17+ để chạy JADX và Apktool)." -ForegroundColor Yellow
} else {
    Write-Host "[i] Java JDK (>= 17): Chưa phát hiện trong PATH (cần thiết cho JADX và Apktool)." -ForegroundColor Yellow
}

$jadxCmd = Get-Command jadx -ErrorAction SilentlyContinue
if (-not $jadxCmd) { $jadxCmd = Get-Command jadx.bat -ErrorAction SilentlyContinue }
if ($jadxCmd) {
    Write-Host "[OK] JADX Decompiler: Khả dụng ($($jadxCmd.Source))." -ForegroundColor Green
} else {
    Write-Host "[i] JADX Decompiler: Chưa phát hiện trong PATH (REA MCP sẽ dùng binary đóng gói hoặc static fallback)." -ForegroundColor Yellow
}

$apktoolCmd = Get-Command apktool -ErrorAction SilentlyContinue
if (-not $apktoolCmd) { $apktoolCmd = Get-Command apktool.bat -ErrorAction SilentlyContinue }
if ($apktoolCmd) {
    Write-Host "[OK] Apktool: Khả dụng ($($apktoolCmd.Source))." -ForegroundColor Green
} else {
    Write-Host "[i] Apktool: Chưa phát hiện trong PATH (cần cho decode_android_resources >= 2.10.0)." -ForegroundColor Yellow
}

$zipalignCmd = Get-Command zipalign -ErrorAction SilentlyContinue
if ($zipalignCmd) {
    Write-Host "[OK] zipalign: Khả dụng ($($zipalignCmd.Source) - Hỗ trợ -P 16 căn chỉnh 16 KB page size)." -ForegroundColor Green
} else {
    Write-Host "[i] zipalign: Chưa phát hiện trong PATH (cần cho Route C repack/patch APK 16 KB page-size)." -ForegroundColor Yellow
}

$androidCmd = Get-Command android -ErrorAction SilentlyContinue
$adbCmd = Get-Command adb -ErrorAction SilentlyContinue
if ($androidCmd) {
    Write-Host "[OK] Android CLI khả dụng: Hỗ trợ AVD, Device Hub, 'android layout --full', 'android screen capture -o <path>', 'android run'." -ForegroundColor Green
} else {
    Write-Host "[i] Android CLI: Chưa phát hiện trong PATH (REA-kit-agy tự động kích hoạt Static Fallback qua JADX/Apktool/Artifact Inventory)." -ForegroundColor Yellow
}
if ($adbCmd) {
    Write-Host "[OK] ADB Tool: Khả dụng ($($adbCmd.Source))." -ForegroundColor Green
} else {
    Write-Host "[i] ADB Tool: Chưa cấu hình trong PATH (yêu cầu cho tương tác thiết bị Android thật / AVD)." -ForegroundColor Yellow
}

Write-Host "==========================================================" -ForegroundColor Cyan
if ($score -eq $total) {
    Write-Host " KẾT QUẢ: WORKSPACE & RUNTIME SẴN SÀNG ($score/$total) - BẠN CÓ THỂ BẮT ĐẦU!" -ForegroundColor Green
    Write-Host " Hãy thả app vào '01_THA_APP_VAO_DAY' và giao việc cho AI." -ForegroundColor Yellow
} else {
    Write-Host " KẾT QUẢ: CẦN KIỂM TRA LẠI ($score/$total)" -ForegroundColor Yellow
}

# Hiển thị Tự động phục hồi phiên (Auto-Resume Banner)
$activeCasePath = Join-Path $repoRoot ".agents/state/active_case.json"
if (Test-Path $activeCasePath) {
    try {
        $case = Get-Content $activeCasePath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($case) {
            Write-Host ""
            Write-Host "--- TIẾN ĐỘ DỰ ÁN (LIFECYCLE STATUS) ---" -ForegroundColor Yellow
            Write-Host " Case ID        : $($case.case_id) (Revision $($case.revision))" -ForegroundColor White
            Write-Host " Stage hiện tại : $($case.current_phase)" -ForegroundColor White
            Write-Host " Target Class   : $($case.target_class)" -ForegroundColor White
            Write-Host " Bước hiện tại  : $($case.current_step)" -ForegroundColor White
            Write-Host " Trạng thái Gate: $($case.current_gate_status)" -ForegroundColor White
            Write-Host " JDK 17+        : $(if ($javaOk) { "KHẢ DỤNG (v$javaVerStr)" } else { "CHƯA SẴN SÀNG" })" -ForegroundColor $(if ($javaOk) { 'Green' } else { 'Yellow' })
            Write-Host " JADX           : $(if ($jadxCmd) { 'KHẢ DỤNG' } else { 'Chưa có trong PATH' })" -ForegroundColor $(if ($jadxCmd) { 'Green' } else { 'Gray' })
            Write-Host " Apktool        : $(if ($apktoolCmd) { 'KHẢ DỤNG' } else { 'Chưa có trong PATH' })" -ForegroundColor $(if ($apktoolCmd) { 'Green' } else { 'Gray' })
            Write-Host " zipalign       : $(if ($zipalignCmd) { 'KHẢ DỤNG (16 KB support)' } else { 'Chưa có trong PATH' })" -ForegroundColor $(if ($zipalignCmd) { 'Green' } else { 'Gray' })
            Write-Host " Android CLI    : $(if ($androidCmd) { 'SẴN SÀNG (AVD / Device Hub / layout / screen capture)' } else { 'STATIC FALLBACK (JADX + Apktool + Artifact Inventory)' })" -ForegroundColor $(if ($androidCmd) { 'Green' } else { 'Yellow' })
            Write-Host " ADB Tool       : $(if ($adbCmd) { 'KHẢ DỤNG' } else { 'Chưa cấu hình trong PATH' })" -ForegroundColor $(if ($adbCmd) { 'Green' } else { 'Gray' })
            Write-Host " Hướng dẫn tiếp : $($case.next_prompt_guide)" -ForegroundColor Cyan
            Write-Host "----------------------------------------" -ForegroundColor Yellow
        }
    } catch {}
}

Write-Host "==========================================================" -ForegroundColor Cyan
if ($score -eq $total) { exit 0 } else { exit 1 }
