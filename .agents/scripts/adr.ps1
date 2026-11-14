# Script Quan ly va Kiem tra Kien truc ADR (Architecture Decision Records)
# Standard: MADR (Markdown Any Architectural Decision Records)
param(
    [Parameter(Position=0)]
    [ValidateSet("list", "show", "validate", "status", "new", "help")]
    [string]$Action = "list",

    [Parameter(Position=1)]
    [string]$Id = "",

    [Parameter(Position=2)]
    [string]$Title = ""
)

$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Tự động định vị thư mục gốc dự án chứa docs/adrs
$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = (Get-Location).Path }
$repoRoot = $scriptDir
while ($repoRoot -and -not (Test-Path (Join-Path $repoRoot "docs/adrs"))) {
    $parent = Split-Path $repoRoot -Parent
    if ($parent -eq $repoRoot -or [string]::IsNullOrEmpty($parent)) { break }
    $repoRoot = $parent
}
if (-not $repoRoot) {
    $repoRoot = (Get-Location).Path
}

$adrDir = Join-Path $repoRoot "docs/adrs"

if (-not (Test-Path $adrDir)) {
    Write-Host "[!] Không tìm thấy thư mục ADR tại: $adrDir" -ForegroundColor Red
    exit 1
}

function Get-AdrList {
    $files = Get-ChildItem -Path $adrDir -Filter "*.md" | Sort-Object Name
    $adrs = @()
    foreach ($file in $files) {
        $lines = Get-Content -Path $file.FullName -Encoding UTF8
        $title = "Không có tiêu đề"
        $status = "unknown"
        $date = "unknown"

        foreach ($line in $lines) {
            if ($line -match '^#\s+(.+)$' -and $title -eq "Không có tiêu đề") {
                $title = $matches[1].Trim()
            }
            if ($line -match '^-\s*Status:\s*(.+)$') {
                $status = $matches[1].Trim()
            }
            if ($line -match '^-\s*Date:\s*(.+)$') {
                $date = $matches[1].Trim()
            }
        }

        $id = $file.BaseName
        if ($id -match '^(\d+)') {
            $id = $matches[1]
        }

        $adrs += [PSCustomObject]@{
            Id       = $id
            File     = $file.Name
            FullName = $file.FullName
            Title    = $title
            Status   = $status
            Date     = $date
        }
    }
    return $adrs
}

switch ($Action) {
    "list" {
        Write-Host "================================================================================" -ForegroundColor Cyan
        Write-Host "   DANH SÁCH ARCHITECTURE DECISION RECORDS (ADR) — REA-KIT-AGY                  " -ForegroundColor Cyan
        Write-Host "   Thư mục: docs/adrs | Chuẩn: MADR                                             " -ForegroundColor DarkCyan
        Write-Host "================================================================================" -ForegroundColor Cyan
        
        $adrs = Get-AdrList
        if ($adrs.Count -eq 0) {
            Write-Host "Chưa có bản ghi ADR nào trong $adrDir" -ForegroundColor Yellow
            return
        }

        Write-Host ("{0,-6} | {1,-10} | {2,-12} | {3}" -f "ID", "TRẠNG THÁI", "NGÀY", "TIÊU ĐỀ") -ForegroundColor White
        Write-Host ("-" * 80) -ForegroundColor Gray

        foreach ($adr in $adrs) {
            $statusColor = "Gray"
            switch ($adr.Status.ToLower()) {
                "accepted"   { $statusColor = "Green" }
                "proposed"   { $statusColor = "Yellow" }
                "rejected"   { $statusColor = "Red" }
                "deprecated" { $statusColor = "DarkGray" }
                "superseded" { $statusColor = "DarkYellow" }
            }

            Write-Host ("{0,-6} | " -f $adr.Id) -NoNewline -ForegroundColor Cyan
            Write-Host ("{0,-10} | " -f $adr.Status.ToUpper()) -NoNewline -ForegroundColor $statusColor
            Write-Host ("{0,-12} | " -f $adr.Date) -NoNewline -ForegroundColor Gray
            Write-Host $adr.Title -ForegroundColor White
        }
        Write-Host ("-" * 80) -ForegroundColor Gray
        Write-Host ("Tổng cộng: {0} bản ghi ADR." -f $adrs.Count) -ForegroundColor Cyan
        Write-Host "Gợi ý: Chạy '.\.agents\scripts\adr.ps1 show <id>' để xem chi tiết bản ghi." -ForegroundColor DarkGray
    }

    "show" {
        if (-not $Id) {
            Write-Host "[!] Vui lòng cung cấp ID của ADR. Ví dụ: .\.agents\scripts\adr.ps1 show 0001" -ForegroundColor Yellow
            exit 1
        }

        $paddedId = $Id
        if ($Id -match '^\d+$') {
            $paddedId = "{0:D4}" -f [int]$Id
        }

        $targetFile = Get-ChildItem -Path $adrDir -Filter "*$paddedId*.md" | Select-Object -First 1
        if (-not $targetFile) {
            $targetFile = Get-ChildItem -Path $adrDir -Filter "*$Id*.md" | Select-Object -First 1
        }

        if (-not $targetFile) {
            Write-Host "[!] Không tìm thấy ADR nào khớp với ID hoặc tên: '$Id'" -ForegroundColor Red
            exit 1
        }

        Write-Host "================================================================================" -ForegroundColor Cyan
        Write-Host "   CHI TIẾT ADR: $($targetFile.Name)                                           " -ForegroundColor Cyan
        Write-Host "================================================================================" -ForegroundColor Cyan
        Get-Content -Path $targetFile.FullName -Encoding UTF8 | Write-Host
    }

    "validate" {
        Write-Host "================================================================================" -ForegroundColor Cyan
        Write-Host "   KIỂM ĐỊNH TÍNH CHUẨN MỰC MADR CÁC BẢN GHI ADR                                " -ForegroundColor Cyan
        Write-Host "================================================================================" -ForegroundColor Cyan

        $adrs = Get-AdrList
        $requiredSections = @(
            "## Context and Problem Statement",
            "## Decision Drivers",
            "## Considered Options",
            "## Decision Outcome",
            "## Pros and Cons of the Options",
            "## Links"
        )

        $allValid = $true
        $score = 0

        foreach ($adr in $adrs) {
            $content = Get-Content -Path $adr.FullName -Raw -Encoding UTF8
            $missing = @()

            if (-not ($content -match '(?m)^#\s+.+')) {
                $missing += "Tiêu đề chính (# Title)"
            }
            if (-not ($content -match '(?m)^-\s*Status:\s*.+')) {
                $missing += "Trường '- Status:'"
            }

            foreach ($sec in $requiredSections) {
                $escaped = [regex]::Escape($sec)
                if (-not ($content -match $escaped)) {
                    $missing += "Mục '$sec'"
                }
            }

            if ($missing.Count -eq 0) {
                Write-Host ("[OK] ADR {0}: {1} (Chuẩn MADR hợp lệ)" -f $adr.Id, $adr.File) -ForegroundColor Green
                $score++
            } else {
                Write-Host ("[FAIL] ADR {0}: {1}" -f $adr.Id, $adr.File) -ForegroundColor Red
                foreach ($m in $missing) {
                    Write-Host ("       - Thiếu: {0}" -f $m) -ForegroundColor Yellow
                }
                $allValid = $false
            }
        }

        Write-Host ("-" * 80) -ForegroundColor Gray
        if ($allValid) {
            Write-Host ("HOÀN HẢO! Toàn bộ {0}/{1} bản ghi ADR đạt chuẩn cấu trúc MADR." -f $score, $adrs.Count) -ForegroundColor Green
            exit 0
        } else {
            Write-Host ("CẢNH BÁO: Phát hiện bản ghi ADR chưa đạt chuẩn MADR." -f $score, $adrs.Count) -ForegroundColor Red
            exit 1
        }
    }

    "status" {
        Write-Host "================================================================================" -ForegroundColor Cyan
        Write-Host "   THỐNG KÊ TRẠNG THÁI ARCHITECTURE DECISION RECORDS                            " -ForegroundColor Cyan
        Write-Host "================================================================================" -ForegroundColor Cyan

        $adrs = Get-AdrList
        $statusCounts = @{}

        foreach ($adr in $adrs) {
            $st = $adr.Status.ToLower()
            if (-not $statusCounts.ContainsKey($st)) {
                $statusCounts[$st] = 0
            }
            $statusCounts[$st]++
        }

        Write-Host ("Tổng số ADR đã lập: {0}" -f $adrs.Count) -ForegroundColor White
        foreach ($key in $statusCounts.Keys) {
            $color = "Gray"
            if ($key -eq "accepted") { $color = "Green" }
            elseif ($key -eq "proposed") { $color = "Yellow" }
            elseif ($key -eq "rejected") { $color = "Red" }
            Write-Host ("  - {0,-12}: {1}" -f $key.ToUpper(), $statusCounts[$key]) -ForegroundColor $color
        }
    }

    "new" {
        $adrs = Get-AdrList
        $maxNum = 0
        foreach ($adr in $adrs) {
            if ($adr.Id -match '^\d+$') {
                $n = [int]$adr.Id
                if ($n -gt $maxNum) { $maxNum = $n }
            }
        }
        
        $newNum = $maxNum + 1
        $titleText = "New Architectural Decision"
        if ($Title) {
            $titleText = $Title
        } elseif ($Id -and ($Id -notmatch '^\d+$')) {
            $titleText = $Id
        } elseif ($Id -match '^\d+$') {
            $newNum = [int]$Id
            if ($Title) { $titleText = $Title }
        }

        $formattedId = "{0:D4}" -f $newNum
        $normalized = $titleText.Replace('đ', 'd').Replace('Đ', 'D').Normalize([System.Text.NormalizationForm]::FormD)
        $asciiChars = -join ($normalized.ToCharArray() | Where-Object {
            [System.Globalization.CharUnicodeInfo]::GetUnicodeCategory($_) -ne [System.Globalization.UnicodeCategory]::NonSpacingMark
        })
        $slug = $asciiChars.ToLower() -replace '[^a-z0-9]+', '-' -replace '^-+|-+$', ''
        if ([string]::IsNullOrWhiteSpace($slug)) { $slug = "new-record" }

        $fileName = "$formattedId-$slug.md"
        $filePath = Join-Path $adrDir $fileName

        if (Test-Path $filePath) {
            Write-Host "[!] File ADR đã tồn tại: $filePath" -ForegroundColor Red
            exit 1
        }

        $currentDate = (Get-Date).ToString("yyyy-MM-dd")
        $template = @"
# $titleText

- Status: proposed
- Deciders: REA Agent Swarm & Human Architect
- Date: $currentDate

## Context and Problem Statement

[Mô tả bối cảnh và vấn đề kiến trúc cần đưa ra quyết định...]

## Decision Drivers

* [Động lực 1: ví dụ yêu cầu hiệu năng, độ tin cậy]
* [Động lực 2: ví dụ chi phí bảo trì, tính tương thích]

## Considered Options

* Option 1: [Lựa chọn 1]
* Option 2: [Lựa chọn 2]

## Decision Outcome

Chosen option: "[Lựa chọn được chọn]", because [lý do lựa chọn].

### Positive Consequences

* [Hệ quả tích cực 1]
* [Hệ quả tích cực 2]

### Negative Consequences

* [Hệ quả tiêu cực hoặc thỏa hiệp 1]

## Pros and Cons of the Options

### Option 1

* Good, because [lợi ích]
* Bad, because [nhược điểm]

### Option 2

* Good, because [lợi ích]
* Bad, because [nhược điểm]

## Links

* [Link tham khảo hoặc task liên quan]
"@
        Set-Content -Path $filePath -Value $template -Encoding UTF8
        Write-Host "================================================================================" -ForegroundColor Cyan
        Write-Host "   ĐÃ TẠO MỚI ARCHITECTURE DECISION RECORD (ADR)                                " -ForegroundColor Green
        Write-Host "================================================================================" -ForegroundColor Cyan
        Write-Host " ID       : $formattedId" -ForegroundColor Cyan
        Write-Host " File     : $fileName" -ForegroundColor White
        Write-Host " Đường dẫn: $filePath" -ForegroundColor Gray
        Write-Host " Tiêu đề  : $titleText" -ForegroundColor White
        Write-Host " Chuẩn    : MADR (Markdown Any Architectural Decision Records)" -ForegroundColor DarkGray
        Write-Host "================================================================================" -ForegroundColor Cyan
        exit 0
    }

    "help" {
        Write-Host "SỬ DỤNG: .\.agents\scripts\adr.ps1 [Action] [Id/Title] [Title]" -ForegroundColor Cyan
        Write-Host "  list                  : Liệt kê toàn bộ các bản ghi ADR và trạng thái (mặc định)."
        Write-Host "  show <id>             : Xem nội dung đầy đủ của một bản ghi ADR theo mã số hoặc tên."
        Write-Host "  validate              : Kiểm tra tính tuân thủ cấu trúc chuẩn MADR cho tất cả ADR."
        Write-Host "  status                : Thống kê số lượng ADR theo trạng thái (accepted, proposed,...)."
        Write-Host "  new [title]           : Tạo bản ghi ADR mới tiếp theo theo mẫu chuẩn MADR."
        Write-Host "  help                  : Hiển thị hướng dẫn này."
    }
}
