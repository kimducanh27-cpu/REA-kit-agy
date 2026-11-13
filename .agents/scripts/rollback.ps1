# Script Hoàn tác 1-Click (Automated Rollback Engine)
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$buildDir = "05_MA_NGUON_PHAT_TRIEN"
$backupRoot = Join-Path $buildDir ".backup"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   TIẾN TRÌNH HOÀN TÁC ỨNG DỤNG (1-CLICK ROLLBACK)...    " -ForegroundColor Cyan
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

# Khôi phục các file từ snapshot vào 05_MA_NGUON_PHAT_TRIEN
$files = Get-ChildItem -Path $latest.FullName -File
foreach ($file in $files) {
    $targetPath = Join-Path $buildDir $file.Name
    Copy-Item -Path $file.FullName -Destination $targetPath -Force
    Write-Host "  -> Đã khôi phục: $($file.Name)" -ForegroundColor Gray
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " HOÀN TÁC THÀNH CÔNG!" -ForegroundColor Green
Write-Host " Ứng dụng trong '05_MA_NGUON_PHAT_TRIEN' đã trở về phiên bản ổn định trước đó." -ForegroundColor Green
Write-Host " Bạn có thể mở lại file '05_MA_NGUON_PHAT_TRIEN/index.html' để kiểm tra." -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan
