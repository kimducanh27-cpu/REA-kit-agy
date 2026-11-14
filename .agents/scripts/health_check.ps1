# Script Kiểm tra Sức khỏe Toàn diện Workspace & Runtime REA-kit-agy
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

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   ĐANG KIỂM TRA HỆ THỐNG WORKSPACE REA-KIT-AGY...        " -ForegroundColor Cyan
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

# 3. Kiểm tra Kỹ năng: 3 Skills điều phối + 1 Skill lõi Upstream
$skills = @("rea-scan", "rea-interview", "rea-build", "reverse-engineer-anything")
$allSkillsOk = $true
foreach ($sk in $skills) {
    if (-not (Test-Path (Join-Path $repoRoot ".agents\skills\$sk\SKILL.md"))) { $allSkillsOk = $false }
}
if ($allSkillsOk) {
    Write-Host "[OK] (3/6) Bộ kỹ năng đầy đủ (3 skills điều phối + 1 skill lõi REA gốc)." -ForegroundColor Green
    $score++
} else {
    Write-Host "[!] (3/6) Thiếu một trong các kỹ năng trong .agents\skills." -ForegroundColor Red
}

# 4. Kiểm tra Luật an toàn (Rules)
if (Test-Path (Join-Path $repoRoot ".agents\rules\rea-workflow.md")) {
    Write-Host "[OK] (4/6) Luật an toàn và bảo vệ dữ liệu đã được kích hoạt." -ForegroundColor Green
    $score++
} else {
    Write-Host "[!] (4/6) Thiếu luật an toàn trong .agents\rules." -ForegroundColor Red
}

# 5. Kiểm tra Bộ nhớ ngữ cảnh (docs/) & Bộ nhớ sự cố (state/)
$docs = @("docs\PRD.md", "docs\ARCHITECTURE.md", "docs\PROGRESS.md", "docs\HANDOFF.md", "docs\PLAN.md", "docs\WORKFLOW_LIFECYCLE.md")
$allDocsOk = $true
foreach ($doc in $docs) {
    if (-not (Test-Path (Join-Path $repoRoot $doc))) { $allDocsOk = $false }
}
if (-not (Test-Path (Join-Path $repoRoot ".agents\state\learned_rules.json")) -or -not (Test-Path (Join-Path $repoRoot ".agents\state\active_case.json"))) {
    $allDocsOk = $false
}
if ($allDocsOk) {
    Write-Host "[OK] (5/6) Bộ hồ sơ ngữ cảnh (Context Docs) và Bộ nhớ sự cố (State) hoàn chỉnh." -ForegroundColor Green
    $score++
} else {
    Write-Host "[!] (5/6) Thiếu một số tài liệu trong docs/ hoặc file state." -ForegroundColor Red
}

# 6. Kiểm tra REA Engine & MCP Runtime trên máy
$mcpOk = $false
try {
    $npxCmd = Get-Command npx -ErrorAction SilentlyContinue
    if ($npxCmd) {
        $doctorRaw = & npx -y rea-agents doctor --client antigravity --json 2>$null
        if ($doctorRaw) {
            $doctorJson = $doctorRaw | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($doctorJson -and ($doctorJson.healthy -eq $true -or ($doctorJson.registrations | Where-Object { $_.client -eq "antigravity" -and $_.state -eq "aligned" }))) {
                $mcpOk = $true
            }
        }
    }
} catch {
    $mcpOk = $false
}

if ($mcpOk) {
    Write-Host "[OK] (6/6) REA Engine & MCP Server đã kết nối sẵn sàng (Antigravity aligned)." -ForegroundColor Green
    $score++
} else {
    Write-Host "[!] (6/6) REA Engine chưa kết nối hoặc chưa cài đặt vào Antigravity." -ForegroundColor Yellow
    Write-Host "     -> Khắc phục: Chạy lệnh sau để tự động cài đặt REA vào Antigravity:" -ForegroundColor Gray
    Write-Host "        npx -y rea-agents setup --client antigravity --yes" -ForegroundColor Cyan
}

# 7. Kiểm tra Android CLI Tooling & Device Hub Readiness (V1 Target Class: Android APK)
$androidCmd = Get-Command android -ErrorAction SilentlyContinue
$adbCmd = Get-Command adb -ErrorAction SilentlyContinue
if ($androidCmd) {
    Write-Host "[OK] Android CLI khả dụng: Hỗ trợ AVD, Device Hub, android layout, android screen." -ForegroundColor Green
} else {
    Write-Host "[i] Android CLI: Chưa phát hiện trong PATH (REA-kit-agy tự động kích hoạt Static Fallback XML/Assets)." -ForegroundColor Yellow
}

Write-Host "==========================================================" -ForegroundColor Cyan
if ($score -eq $total) {
    Write-Host " KẾT QUẢ: WORKSPACE & RUNTIME SẴN SÀNG ($score/$total) - BẠN CÓ THỂ BẮT ĐẦU!" -ForegroundColor Green
    Write-Host " Hãy thả app vào '01_THA_APP_VAO_DAY' và giao việc cho AI." -ForegroundColor Yellow
} else {
    Write-Host " KẾT QUẢ: CẦN KIỂM TRA LẠI ($score/$total)" -ForegroundColor Yellow
}

# Hiển thị Tự động phục hồi phiên (Auto-Resume Banner)
$activeCasePath = Join-Path $repoRoot ".agents\state\active_case.json"
if (Test-Path $activeCasePath) {
    try {
        $case = Get-Content $activeCasePath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($case) {
            Write-Host ""
            Write-Host "--- TIẾN ĐỘ DỰ ÁN (LIFECYCLE STATUS) ---" -ForegroundColor Yellow
            Write-Host " Stage hiện tại : $($case.current_phase)" -ForegroundColor White
            Write-Host " Target Class   : $($case.target_class)" -ForegroundColor White
            Write-Host " Bước hiện tại  : $($case.current_step)" -ForegroundColor White
            Write-Host " Trạng thái Gate: $($case.current_gate_status)" -ForegroundColor White
            Write-Host " Android CLI    : $(if ($androidCmd) { 'SẴN SÀNG (AVD / Device Hub / layout / screen)' } else { 'STATIC FALLBACK (Bóc tách tài nguyên tĩnh XML/Smali)' })" -ForegroundColor $(if ($androidCmd) { 'Green' } else { 'Yellow' })
            Write-Host " ADB Tool       : $(if ($adbCmd) { 'KHẢ DỤNG' } else { 'Chưa cấu hình trong PATH' })" -ForegroundColor $(if ($adbCmd) { 'Green' } else { 'Gray' })
            Write-Host " Hướng dẫn tiếp : $($case.next_prompt_guide)" -ForegroundColor Cyan
            Write-Host "----------------------------------------" -ForegroundColor Yellow
        }
    } catch {}
}

Write-Host "==========================================================" -ForegroundColor Cyan
if ($score -eq $total) { exit 0 } else { exit 1 }
