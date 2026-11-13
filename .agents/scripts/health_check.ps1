# Script Kiểm tra Sức khỏe Workspace REA-kit-agy
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   ĐANG KIỂM TRA HỆ THỐNG WORKSPACE REA-KIT-AGY...        " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$score = 0
$total = 5

# 1. Kiểm tra cấu trúc thư mục người dùng
$dirs = @("01_THA_APP_VAO_DAY", "02_YEU_CAU_CUA_TOI", "03_KET_QUA_KIEM_TRA", "04_SAO_LUU_AN_TOAN", "05_MA_NGUON_PHAT_TRIEN")
$allDirsOk = $true
foreach ($d in $dirs) {
    if (-not (Test-Path $d)) { $allDirsOk = $false }
}
if ($allDirsOk) {
    Write-Host "[OK] (1/5) Cấu trúc 5 thư mục giao diện người dùng đầy đủ." -ForegroundColor Green
    $score++
} else {
    Write-Host "[!] (1/5) Thiếu một số thư mục người dùng." -ForegroundColor Red
}

# 2. Kiểm tra tài liệu hướng dẫn và luật chơi cốt lõi
if ((Test-Path "AGENTS.md") -and (Test-Path "HUONG_DAN_SU_DUNG.md")) {
    Write-Host "[OK] (2/5) File luật AGENTS.md và Hướng dẫn sử dụng đã sẵn sàng." -ForegroundColor Green
    $score++
} else {
    Write-Host "[!] (2/5) Thiếu AGENTS.md hoặc HUONG_DAN_SU_DUNG.md." -ForegroundColor Red
}

# 3. Kiểm tra Kỹ năng Antigravity (Skills)
if (Test-Path ".agents\skills\rea-app-inspector\SKILL.md") {
    Write-Host "[OK] (3/5) Kỹ năng REA-app-inspector đã được nạp đúng chuẩn." -ForegroundColor Green
    $score++
} else {
    Write-Host "[!] (3/5) Không tìm thấy kỹ năng trong .agents\skills." -ForegroundColor Red
}

# 4. Kiểm tra Luật an toàn (Rules)
if (Test-Path ".agents\rules\rea-workflow.md") {
    Write-Host "[OK] (4/5) Luật an toàn và bảo vệ dữ liệu đã được kích hoạt." -ForegroundColor Green
    $score++
} else {
    Write-Host "[!] (4/5) Thiếu luật an toàn trong .agents\rules." -ForegroundColor Red
}

# 5. Kiểm tra Bộ nhớ ngữ cảnh (docs/)
$docs = @("docs\PRD.md", "docs\ARCHITECTURE.md", "docs\PROGRESS.md", "docs\HANDOFF.md", "docs\PLAN.md")
$allDocsOk = $true
foreach ($doc in $docs) {
    if (-not (Test-Path $doc)) { $allDocsOk = $false }
}
if ($allDocsOk) {
    Write-Host "[OK] (5/5) Bộ hồ sơ ngữ cảnh (Context Docs) hoàn chỉnh." -ForegroundColor Green
    $score++
} else {
    Write-Host "[!] (5/5) Thiếu một số tài liệu trong thư mục docs/." -ForegroundColor Red
}

Write-Host "==========================================================" -ForegroundColor Cyan
if ($score -eq $total) {
    Write-Host " KẾT QUẢ: WORKSPACE SẴN SÀNG ($score/$total) - BẠN CÓ THỂ BẮT ĐẦU!" -ForegroundColor Green
    Write-Host " Hãy thả app vào '01_THA_APP_VAO_DAY' và giao việc cho AI." -ForegroundColor Yellow
} else {
    Write-Host " KẾT QUẢ: CẦN KIỂM TRA LẠI ($score/$total)" -ForegroundColor Yellow
}
Write-Host "==========================================================" -ForegroundColor Cyan
