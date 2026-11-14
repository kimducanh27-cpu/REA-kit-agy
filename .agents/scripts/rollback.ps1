# Script Hoàn tác & Tạo Snapshot 1-Click (Automated Rollback & Snapshot Engine v1.1)
param(
    [switch]$Snapshot,
    [int]$MaxSnapshots = 10
)

$ErrorActionPreference = "Stop"
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

$buildDir = Join-Path $repoRoot "05_MA_NGUON_PHAT_TRIEN"
$backupRoot = Join-Path $buildDir ".backup"
$excludedNames = @(".backup", ".gitkeep", ".gradle", "node_modules", "build")

if (-not (Test-Path -LiteralPath $buildDir)) {
    New-Item -ItemType Directory -Path $buildDir -Force | Out-Null
}

function Remove-SafeItem {
    param([System.IO.FileSystemInfo]$Item)
    # Bảo vệ chống đi xuyên qua Symlink / Junction (ReparsePoint) xóa nhầm dữ liệu ngoài phạm vi
    if ($Item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
        if ($Item.PSIsContainer) {
            [System.IO.Directory]::Delete($Item.FullName)
        } else {
            [System.IO.File]::Delete($Item.FullName)
        }
    } else {
        Remove-Item -LiteralPath $Item.FullName -Recurse -Force -ErrorAction Stop
    }
}

# --- XỬ LÝ SNAPSHOT ---
if ($Snapshot) {
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "   TIẾN TRÌNH TẠO BẢN SAO LƯU (CREATE SNAPSHOT v1.1)...   " -ForegroundColor Cyan
    Write-Host "   Repo Root:  $repoRoot" -ForegroundColor DarkCyan
    Write-Host "   Thư mục:    $buildDir" -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan

    $itemsToBackup = @(Get-ChildItem -LiteralPath $buildDir -Force | Where-Object {
        $excludedNames -notcontains $_.Name -and -not ($_.Attributes -band [System.IO.FileAttributes]::ReparsePoint)
    })

    if ($itemsToBackup.Count -eq 0) {
        Write-Host "[!] Không có mã nguồn thực tế trong $buildDir để sao lưu (bỏ qua tạo snapshot rỗng)." -ForegroundColor Yellow
        Write-Host "==========================================================" -ForegroundColor Cyan
        exit 0
    }

    if (-not (Test-Path -LiteralPath $backupRoot)) {
        New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
    }

    $timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss_fff")
    $snapshotDir = Join-Path $backupRoot $timestamp
    New-Item -ItemType Directory -Path $snapshotDir -Force | Out-Null

    foreach ($item in $itemsToBackup) {
        Copy-Item -LiteralPath $item.FullName -Destination $snapshotDir -Recurse -Force -ErrorAction Stop
    }

    # Giữ tối đa $MaxSnapshots bản sao lưu gần nhất để chống phình đĩa
    $allSnaps = @(Get-ChildItem -LiteralPath $backupRoot -Directory | Sort-Object Name -Descending)
    if ($allSnaps.Count -gt $MaxSnapshots) {
        foreach ($oldSnap in $allSnaps[$MaxSnapshots..($allSnaps.Count - 1)]) {
            Remove-Item -LiteralPath $oldSnap.FullName -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Write-Host "[OK] Đã tạo snapshot thành công tại: $snapshotDir" -ForegroundColor Green
    Write-Host "     Số đối tượng sao lưu: $($itemsToBackup.Count) (Tối đa lưu trữ: $MaxSnapshots snapshots)" -ForegroundColor Gray
    Write-Host "==========================================================" -ForegroundColor Cyan
    exit 0
}

# --- XỬ LÝ ROLLBACK ---
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   TIẾN TRÌNH HOÀN TÁC ỨNG DỤNG (1-CLICK ROLLBACK v1.1)..." -ForegroundColor Cyan
Write-Host "   Repo Root:  $repoRoot" -ForegroundColor DarkCyan
Write-Host "   Thư mục:    $buildDir" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

if (-not (Test-Path -LiteralPath $backupRoot)) {
    Write-Host "[!] Không tìm thấy thư mục sao lưu tại: $backupRoot" -ForegroundColor Yellow
    Write-Host "    Chưa có phiên bản sao lưu nào được ghi nhận." -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Cyan
    exit 1
}

# Chỉ chọn các snapshot có chứa ít nhất 1 file mã nguồn thực tế (khác .gitkeep)
$validSnapshots = @(Get-ChildItem -LiteralPath $backupRoot -Directory | Sort-Object Name -Descending | Where-Object {
    @(Get-ChildItem -LiteralPath $_.FullName -Recurse -File -Force | Where-Object { $_.Name -ne ".gitkeep" }).Count -gt 0
})

if ($validSnapshots.Count -eq 0) {
    Write-Host "[!] Không có bản snapshot hợp lệ nào chứa mã nguồn trong thư mục sao lưu (đã chặn hoàn tác vào snapshot rỗng)." -ForegroundColor Red
    Write-Host "==========================================================" -ForegroundColor Cyan
    exit 1
}

$latest = $validSnapshots[0]
Write-Host "[*] Tìm thấy bản sao lưu hợp lệ gần nhất: $($latest.Name)" -ForegroundColor Green
Write-Host "    Thời gian tạo: $($latest.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray

# Dọn sạch các file/thư mục hiện tại trong $buildDir (loại trừ .backup và .gitkeep, bảo vệ ReparsePoint)
Write-Host "[*] Đang dọn các file hiện tại trong thư mục phát triển..." -ForegroundColor Gray
$currentItems = @(Get-ChildItem -LiteralPath $buildDir -Force | Where-Object { $_.Name -ne ".backup" -and $_.Name -ne ".gitkeep" })
foreach ($item in $currentItems) {
    Remove-SafeItem -Item $item
}

# Khôi phục đệ quy toàn bộ nội dung từ snapshot
Write-Host "[*] Đang khôi phục toàn bộ nội dung từ snapshot $($latest.Name)..." -ForegroundColor Gray
$snapshotItems = @(Get-ChildItem -LiteralPath $latest.FullName -Force)
foreach ($item in $snapshotItems) {
    Copy-Item -LiteralPath $item.FullName -Destination $buildDir -Recurse -Force -ErrorAction Stop
    Write-Host "  -> Đã khôi phục: $($item.Name)" -ForegroundColor Gray
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " HOÀN TÁC THÀNH CÔNG!" -ForegroundColor Green
Write-Host " Ứng dụng trong '$buildDir' đã trở về phiên bản ổn định trước đó." -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan
exit 0
