# Script Hoàn tác & Tạo Snapshot 1-Click (Automated Rollback & Snapshot Engine)
param(
    [switch]$Snapshot
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

$buildDir = Join-Path $repoRoot "05_MA_NGUON_PHAT_TRIEN"
$backupRoot = Join-Path $buildDir ".backup"

if (-not (Test-Path $buildDir)) {
    New-Item -ItemType Directory -Path $buildDir -Force | Out-Null
}

# --- XỬ LÝ SNAPSHOT ---
if ($Snapshot) {
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "   TIẾN TRÌNH TẠO BẢN SAO LƯU (CREATE SNAPSHOT)...        " -ForegroundColor Cyan
    Write-Host "   Repo Root:  $repoRoot" -ForegroundColor DarkCyan
    Write-Host "   Thư mục:    $buildDir" -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan

    if (-not (Test-Path $backupRoot)) {
        New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
    }

    $timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
    $snapshotDir = Join-Path $backupRoot $timestamp
    New-Item -ItemType Directory -Path $snapshotDir -Force | Out-Null

    $itemsToBackup = Get-ChildItem -Path $buildDir -Force | Where-Object { $_.Name -ne ".backup" }
    
    if ($itemsToBackup.Count -eq 0) {
        Write-Host "[!] Không có dữ liệu trong $buildDir để sao lưu." -ForegroundColor Yellow
    } else {
        foreach ($item in $itemsToBackup) {
            Copy-Item -Path $item.FullName -Destination $snapshotDir -Recurse -Force
        }
        Write-Host "[OK] Đã tạo snapshot thành công tại: $snapshotDir" -ForegroundColor Green
        Write-Host "     Số đối tượng sao lưu: $($itemsToBackup.Count)" -ForegroundColor Gray
    }

    Write-Host "==========================================================" -ForegroundColor Cyan
    exit 0
}

# --- XỬ LÝ ROLLBACK ---
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   TIẾN TRÌNH HOÀN TÁC ỨNG DỤNG (1-CLICK ROLLBACK)...    " -ForegroundColor Cyan
Write-Host "   Repo Root:  $repoRoot" -ForegroundColor DarkCyan
Write-Host "   Thư mục:    $buildDir" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

if (-not (Test-Path $backupRoot)) {
    Write-Host "[!] Không tìm thấy thư mục sao lưu tại: $backupRoot" -ForegroundColor Yellow
    Write-Host "    Chưa có phiên bản sao lưu nào được ghi nhận." -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Cyan
    exit 1
}

$snapshots = Get-ChildItem -Path $backupRoot -Directory | Sort-Object LastWriteTime -Descending

if ($snapshots.Count -eq 0) {
    Write-Host "[!] Không có bản snapshot nào trong thư mục sao lưu." -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Cyan
    exit 1
}

$latest = $snapshots[0]
Write-Host "[*] Tìm thấy bản sao lưu gần nhất: $($latest.Name)" -ForegroundColor Green
Write-Host "    Thời gian tạo: $($latest.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray

# Dọn sạch các file/thư mục hiện tại trong $buildDir (loại trừ .backup)
Write-Host "[*] Đang xóa các file hiện tại trong thư mục phát triển..." -ForegroundColor Gray
$currentItems = Get-ChildItem -Path $buildDir -Force | Where-Object { $_.Name -ne ".backup" }
foreach ($item in $currentItems) {
    Remove-Item -Path $item.FullName -Recurse -Force
}

# Khôi phục đệ quy toàn bộ nội dung từ snapshot
Write-Host "[*] Đang khôi phục toàn bộ nội dung từ snapshot $($latest.Name)..." -ForegroundColor Gray
$snapshotItems = Get-ChildItem -Path $latest.FullName -Force
foreach ($item in $snapshotItems) {
    Copy-Item -Path $item.FullName -Destination $buildDir -Recurse -Force
    Write-Host "  -> Đã khôi phục: $($item.Name)" -ForegroundColor Gray
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " HOÀN TÁC THÀNH CÔNG!" -ForegroundColor Green
Write-Host " Ứng dụng trong '$buildDir' đã trở về phiên bản ổn định trước đó." -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan
exit 0
