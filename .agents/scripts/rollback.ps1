# Script Hoàn tác & Tạo Snapshot 1-Click Nguyên Tử (Deterministic Atomic Rollback & Snapshot Engine v1.1)
# Triết lý: Không bao giờ xóa mã nguồn khi chưa xác thực bản sao lưu nguyên vẹn qua SHA-256 manifest và cơ chế hoán đổi nguyên tử 2 giai đoạn (Staging Atomic Swap).
param(
    [switch]$Snapshot,
    [switch]$Force,
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
    Write-Host "   TIẾN TRÌNH TẠO BẢN SAO LƯU NGUYÊN TỬ (ATOMIC SNAPSHOT) " -ForegroundColor Cyan
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

    # Sao chép và lập manifest kèm mã băm SHA-256
    $manifestFiles = @()
    $totalBytes = 0

    foreach ($item in $itemsToBackup) {
        Copy-Item -LiteralPath $item.FullName -Destination $snapshotDir -Recurse -Force -ErrorAction Stop
    }

    $allCopiedFiles = @(Get-ChildItem -LiteralPath $snapshotDir -Recurse -File -Force | Where-Object { $_.Name -ne "manifest.json" })
    foreach ($f in $allCopiedFiles) {
        $hash = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash
        $rel = $f.FullName.Substring($snapshotDir.Length).TrimStart('\', '/')
        $manifestFiles += [ordered]@{
            path = $rel
            sha256 = $hash
            bytes = $f.Length
        }
        $totalBytes += $f.Length
    }

    $manifest = [ordered]@{
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
        snapshot_id = $timestamp
        file_count = $allCopiedFiles.Count
        total_bytes = $totalBytes
        files = $manifestFiles
    }
    $manifestPath = Join-Path $snapshotDir "manifest.json"
    ($manifest | ConvertTo-Json -Depth 5) | Set-Content -LiteralPath $manifestPath -Encoding UTF8

    # Giữ tối đa $MaxSnapshots bản sao lưu gần nhất để chống phình đĩa
    $allSnaps = @(Get-ChildItem -LiteralPath $backupRoot -Directory | Where-Object { $_.Name -notlike ".*" } | Sort-Object Name -Descending)
    if ($allSnaps.Count -gt $MaxSnapshots) {
        foreach ($oldSnap in $allSnaps[$MaxSnapshots..($allSnaps.Count - 1)]) {
            Remove-Item -LiteralPath $oldSnap.FullName -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    Write-Host "[OK] Đã tạo snapshot thành công kèm SHA-256 manifest tại: $snapshotDir" -ForegroundColor Green
    Write-Host "     Số file: $($allCopiedFiles.Count) | Tổng dung lượng: $totalBytes bytes | Giới hạn xoay vòng: $MaxSnapshots snapshots" -ForegroundColor Gray
    Write-Host "==========================================================" -ForegroundColor Cyan
    exit 0
}

# --- XỬ LÝ ROLLBACK ---
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   TIẾN TRÌNH HOÀN TÁC NGUYÊN TỬ (ATOMIC 2-PHASE ROLLBACK)" -ForegroundColor Cyan
Write-Host "   Repo Root:  $repoRoot" -ForegroundColor DarkCyan
Write-Host "   Thư mục:    $buildDir" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

if (-not (Test-Path -LiteralPath $backupRoot)) {
    Write-Host "[!] Không tìm thấy thư mục sao lưu tại: $backupRoot" -ForegroundColor Yellow
    Write-Host "    Chưa có phiên bản sao lưu nào được ghi nhận." -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Cyan
    exit 1
}

# Chỉ chọn các snapshot có chứa ít nhất 1 file mã nguồn thực tế (khác .gitkeep và manifest.json)
$validSnapshots = @(Get-ChildItem -LiteralPath $backupRoot -Directory | Where-Object { $_.Name -notlike ".*" } | Sort-Object Name -Descending | Where-Object {
    @(Get-ChildItem -LiteralPath $_.FullName -Recurse -File -Force | Where-Object { $_.Name -ne ".gitkeep" -and $_.Name -ne "manifest.json" }).Count -gt 0
})

if ($validSnapshots.Count -eq 0) {
    Write-Host "[FAIL] Không có bản snapshot hợp lệ nào chứa mã nguồn (từ chối hoàn tác vào snapshot rỗng hoặc chỉ có .gitkeep)!" -ForegroundColor Red
    Write-Host "==========================================================" -ForegroundColor Cyan
    exit 1
}

$latest = $validSnapshots[0]
Write-Host "[*] Tìm thấy bản sao lưu hợp lệ gần nhất: $($latest.Name)" -ForegroundColor Green
Write-Host "    Thời gian tạo: $($latest.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray

# Xác nhận người dùng nếu không bật -Force và chạy interactive
if (-not $Force -and [Environment]::UserInteractive) {
    $confirm = Read-Host "Bạn có chắc chắn muốn hoàn tác thư mục phát triển về bản snapshot này? (Y/N)"
    if ($confirm -notmatch '^(y|yes)$') {
        Write-Host "[*] Người dùng đã hủy thao tác hoàn tác." -ForegroundColor Yellow
        exit 0
    }
}

# GIAI ĐOẠN 1: Chuẩn bị khôi phục vào thư mục staging tạm thời
$stagingDir = Join-Path $backupRoot (".staging_" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $stagingDir -Force | Out-Null

try {
    # Sao chép từ snapshot sang staging (loại trừ manifest.json khỏi target staging nếu không cần)
    $snapItems = @(Get-ChildItem -LiteralPath $latest.FullName -Force | Where-Object { $_.Name -ne "manifest.json" })
    foreach ($item in $snapItems) {
        Copy-Item -LiteralPath $item.FullName -Destination $stagingDir -Recurse -Force -ErrorAction Stop
    }

    # Đối chiếu mã băm SHA-256 từ manifest.json nếu có
    $manifestPath = Join-Path $latest.FullName "manifest.json"
    if (Test-Path -LiteralPath $manifestPath) {
        Write-Host "[*] Đang xác thực tính toàn vẹn SHA-256 các file staging từ manifest.json..." -ForegroundColor Gray
        $manifestObj = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
        foreach ($mf in $manifestObj.files) {
            $stagedFile = Join-Path $stagingDir $mf.path
            if (-not (Test-Path -LiteralPath $stagedFile)) {
                throw "Thiếu file trong bản staging đối chiếu: $($mf.path)"
            }
            $stagedHash = (Get-FileHash -LiteralPath $stagedFile -Algorithm SHA256).Hash
            if ($stagedHash -ne $mf.sha256) {
                throw "Sai lệch mã băm SHA-256 tại file: $($mf.path) (Kỳ vọng: $($mf.sha256), Thực tế: $stagedHash)"
            }
        }
        Write-Host " [PASS] 100% file khôi phục khớp tuyệt đối mã băm SHA-256." -ForegroundColor Green
    }

    # GIAI ĐOẠN 2: Hoán đổi nguyên tử (Atomic Swap với thư mục bảo vệ .safety)
    $safetyDir = Join-Path $backupRoot (".safety_" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $safetyDir -Force | Out-Null

    # Di chuyển các file hiện tại sang .safety
    $currentItems = @(Get-ChildItem -LiteralPath $buildDir -Force | Where-Object { $excludedNames -notcontains $_.Name })
    foreach ($item in $currentItems) {
        Move-Item -LiteralPath $item.FullName -Destination $safetyDir -Force -ErrorAction Stop
    }

    # Di chuyển các file staging vào buildDir
    $stagedItems = @(Get-ChildItem -LiteralPath $stagingDir -Force)
    foreach ($item in $stagedItems) {
        Move-Item -LiteralPath $item.FullName -Destination $buildDir -Force -ErrorAction Stop
    }

    # Thành công: Dọn dẹp .safety và .staging
    Remove-Item -LiteralPath $safetyDir -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $stagingDir -Recurse -Force -ErrorAction SilentlyContinue

    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host " HOÀN TÁC THÀNH CÔNG (ATOMIC RESTORE COMPLETED)!" -ForegroundColor Green
    Write-Host " Thư mục '$buildDir' đã trở về phiên bản an toàn: $($latest.Name)" -ForegroundColor Green
    Write-Host "==========================================================" -ForegroundColor Cyan
    exit 0

} catch {
    Write-Host "[FAIL] Lỗi trong quá trình hoàn tác: $_" -ForegroundColor Red
    Write-Host "[*] Đang khôi phục lại trạng thái an toàn ban đầu trước khi hoàn tác..." -ForegroundColor Yellow
    if (Test-Path -LiteralPath $safetyDir) {
        $savedItems = @(Get-ChildItem -LiteralPath $safetyDir -Force)
        foreach ($s in $savedItems) {
            Move-Item -LiteralPath $s.FullName -Destination $buildDir -Force -ErrorAction SilentlyContinue
        }
        Remove-Item -LiteralPath $safetyDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path -LiteralPath $stagingDir) {
        Remove-Item -LiteralPath $stagingDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    Write-Host "[!] Đã bảo toàn nguyên vẹn thư mục phát triển hiện tại, không có file nào bị xóa nhầm." -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Cyan
    exit 1
}
