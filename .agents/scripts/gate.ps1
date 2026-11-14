# Script Quản Trị Cổng Kiểm Soát & Máy Trạng Thái (Deterministic Gate & State Machine Engine v2.0 - RWO)
# Tuân thủ nguyên tắc Single Authoritative Coordinator, Conditional DAG, Cascade Invalidation, và Optimistic Concurrency.

param(
    [Parameter(Position=0)]
    [ValidateSet("status", "validate", "open", "waive", "skip", "reject", "event")]
    [string]$Action = "status",

    [Parameter(Position=1)]
    [string]$Gate,

    [string]$Evidence,
    [string]$ApprovedBy,
    [string]$Reason,
    [string]$Details,
    [ValidateSet("PASS", "PASS_WITH_LIMITATIONS", "SKIPPED", "NOT_APPLICABLE")]
    [string]$Mode = "PASS"
)

class ConcurrencyConflictException : System.Exception {
    ConcurrencyConflictException([string]$message) : base($message) {}
}

$ErrorActionPreference = "Stop"
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Tree-climbing tìm repoRoot
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

$stateFile = Join-Path $repoRoot ".agents/state/active_case.json"
$eventsFile = Join-Path $repoRoot ".agents/state/events.jsonl"
$casesDir = Join-Path $repoRoot ".agents/state/cases"

if (-not (Test-Path -LiteralPath $stateFile)) {
    Write-Host "[FAIL] Không tìm thấy active_case.json tại: $stateFile" -ForegroundColor Red
    exit 1
}

function Get-CaseState {
    return (Get-Content -LiteralPath $stateFile -Raw -Encoding UTF8 | ConvertFrom-Json)
}

function Get-NormalizedFileHash {
    param([string]$FilePath)
    $ext = [System.IO.Path]::GetExtension($FilePath).ToLower()
    $textExts = @(".md", ".json", ".txt", ".xml", ".html", ".js", ".css", ".yaml", ".yml", ".csv")
    if ($textExts -contains $ext) {
        $raw = [System.IO.File]::ReadAllText($FilePath, [System.Text.Encoding]::UTF8)
        $normalized = $raw -replace "\r\n", "`n"
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($normalized)
        $hasher = [System.Security.Cryptography.SHA256]::Create()
        try {
            $hashBytes = $hasher.ComputeHash($bytes)
            return [System.BitConverter]::ToString($hashBytes).Replace("-", "").ToUpper()
        } finally {
            $hasher.Dispose()
        }
    } else {
        return (Get-FileHash -LiteralPath $FilePath -Algorithm SHA256).Hash
    }
}

function Save-CaseStateAtomic {
    param(
        [object]$State,
        [int]$ExpectedRevision = -1
    )

    if ($ExpectedRevision -le 0 -and $State.revision) {
        $ExpectedRevision = [int]$State.revision
    }

    if ($ExpectedRevision -gt 0 -and (Test-Path -LiteralPath $stateFile)) {
        $diskState = Get-CaseState
        if ($diskState.revision -and [int]$diskState.revision -ne $ExpectedRevision) {
            throw [ConcurrencyConflictException]::new("[ConcurrencyConflictException] active_case.json đã bị tiến trình khác cập nhật (Đĩa: Rev $($diskState.revision), Kỳ vọng: Rev $ExpectedRevision). Thao tác bị hủy để tránh mất dữ liệu!")
        }
    }

    $State.last_updated = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
    $currentRev = if ($State.revision) { [int]$State.revision } else { 1 }
    $State.revision = $currentRev + 1

    $json = $State | ConvertTo-Json -Depth 15
    $tmpFile = [System.IO.Path]::GetFullPath("$stateFile.tmp.$([System.Guid]::NewGuid().ToString('N'))")
    $bakFile = [System.IO.Path]::GetFullPath("$stateFile.bak.$([System.Guid]::NewGuid().ToString('N'))")
    $destFull = [System.IO.Path]::GetFullPath($stateFile)

    # Ghi file tạm bằng UTF8 không BOM
    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($tmpFile, $json, $utf8NoBom)

    $maxRetries = 5
    $baseDelayMs = 100
    $saved = $false

    for ($attempt = 1; $attempt -le $maxRetries; $attempt++) {
        try {
            if (Test-Path -LiteralPath $destFull) {
                [System.IO.File]::Replace($tmpFile, $destFull, $bakFile, $true)
                if (Test-Path -LiteralPath $bakFile) {
                    Remove-Item -LiteralPath $bakFile -Force -ErrorAction SilentlyContinue
                }
            } else {
                [System.IO.File]::Move($tmpFile, $destFull)
            }
            $saved = $true
            break
        } catch [System.IO.IOException], [System.UnauthorizedAccessException] {
            if ($attempt -eq $maxRetries) { throw }
            $delay = [int]($baseDelayMs * [Math]::Pow(2, ($attempt - 1)) + (Get-Random -Minimum 10 -Maximum 50))
            Start-Sleep -Milliseconds $delay
        } finally {
            if (Test-Path -LiteralPath $bakFile) {
                Remove-Item -LiteralPath $bakFile -Force -ErrorAction SilentlyContinue
            }
        }
    }

    if (Test-Path -LiteralPath $tmpFile) {
        Remove-Item -LiteralPath $tmpFile -Force -ErrorAction SilentlyContinue
    }
    if (-not $saved) {
        throw "Không thể lưu trạng thái active_case.json sau $maxRetries lần thử do xung đột khóa tệp!"
    }

    # Snapshot lineage lưu trữ
    $caseId = if ($State.case_id) { $State.case_id } else { "CASE-UNKNOWN" }
    $caseFolder = Join-Path $casesDir $caseId
    if (-not (Test-Path -LiteralPath $caseFolder)) {
        New-Item -ItemType Directory -Path $caseFolder -Force | Out-Null
    }
    $caseManifest = Join-Path $caseFolder "manifest.json"
    [System.IO.File]::WriteAllText($caseManifest, $json, $utf8NoBom)

    $runsFolder = Join-Path $caseFolder "runs"
    if (-not (Test-Path -LiteralPath $runsFolder)) {
        New-Item -ItemType Directory -Path $runsFolder -Force | Out-Null
    }
    $runId = if ($State.workflow -and $State.workflow.run_id) { $State.workflow.run_id } else { "RUN-$($State.revision)" }
    $runSnapshot = Join-Path $runsFolder "$runId.json"
    [System.IO.File]::WriteAllText($runSnapshot, $json, $utf8NoBom)
}

function Append-Event {
    param(
        [string]$ActionName,
        [string]$Actor,
        [string]$Phase,
        [string]$Step,
        [string]$EventDetails,
        [string]$EvidenceSha,
        [object]$State = $null
    )
    $timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
    $eventId = "EVT-" + (Get-Date).ToString("yyyyMMdd-HHmmss-fff")
    if (-not $State -and (Test-Path -LiteralPath $stateFile)) {
        $State = Get-CaseState
    }
    $caseId = if ($State -and $State.case_id) { $State.case_id } else { "CASE-UNKNOWN" }
    $rev = if ($State -and $State.revision) { [int]$State.revision } else { $null }

    $eventObj = [ordered]@{
        event_id = $eventId
        timestamp = $timestamp
        case_id = $caseId
        revision = $rev
        actor = if ($Actor) { $Actor } else { "coordinator" }
        action = $ActionName
        phase = $Phase
        step = $Step
        details = $EventDetails
        evidence_sha256 = $EvidenceSha
    }
    $line = ($eventObj | ConvertTo-Json -Compress)

    # Ghi log sự kiện an toàn với FileShare.ReadWrite và retry backoff
    $eventsFolder = Split-Path -Parent $eventsFile
    if (-not (Test-Path -LiteralPath $eventsFolder)) {
        New-Item -ItemType Directory -Path $eventsFolder -Force | Out-Null
    }

    $maxRetries = 5
    $baseDelayMs = 100
    for ($attempt = 1; $attempt -le $maxRetries; $attempt++) {
        try {
            $stream = [System.IO.FileStream]::new(
                $eventsFile,
                [System.IO.FileMode]::Append,
                [System.IO.FileAccess]::Write,
                [System.IO.FileShare]::ReadWrite
            )
            try {
                $writer = [System.IO.StreamWriter]::new($stream, [System.Text.UTF8Encoding]::new($false))
                try {
                    $writer.WriteLine($line)
                } finally {
                    $writer.Dispose()
                }
            } finally {
                $stream.Dispose()
            }
            break
        } catch [System.IO.IOException], [System.UnauthorizedAccessException] {
            if ($attempt -eq $maxRetries) { throw }
            $delay = [int]($baseDelayMs * [Math]::Pow(2, ($attempt - 1)) + (Get-Random -Minimum 10 -Maximum 50))
            Start-Sleep -Milliseconds $delay
        }
    }
}

function Resolve-GateName {
    param([string]$InputGate)
    if ([string]::IsNullOrWhiteSpace($InputGate)) { return $null }
    $g = $InputGate.Trim().ToLower()
    switch -Regex ($g) {
        '^(1|01|gate_?01|baseline)$' { return "gate_01_baseline_verified" }
        '^(2|02|gate_?02|audit)$'    { return "gate_02_audit_passed" }
        '^(3|03|gate_?03|spec)$'     { return "gate_03_spec_frozen" }
        '^(4|04|gate_?04|qa|build)$' { return "gate_04_build_qa_passed" }
        '^(5|05|gate_?05|hard)$'     { return "gate_05_hard_verify_passed" }
        '^(6|06|gate_?06|handoff)$'  { return "gate_06_handoff_signed" }
        default { return $InputGate }
    }
}

$gateOrder = @(
    "gate_01_baseline_verified",
    "gate_02_audit_passed",
    "gate_03_spec_frozen",
    "gate_04_build_qa_passed",
    "gate_05_hard_verify_passed",
    "gate_06_handoff_signed"
)

# 11 trạng thái hợp lệ
$validGateStates = @(
    "NOT_STARTED",
    "IN_PROGRESS",
    "PASS",
    "PASS_WITH_LIMITATIONS",
    "SKIPPED",
    "NOT_APPLICABLE",
    "WAIVED",
    "BLOCKED",
    "FAILED",
    "INVALIDATED",
    "REUSED_VALIDATED"
)

# Trạng thái được coi là "đã thông qua điều kiện tiên quyết" để bước tiếp
$clearedStates = @("PASS", "PASS_WITH_LIMITATIONS", "SKIPPED", "NOT_APPLICABLE", "WAIVED", "REUSED_VALIDATED")

# Bản đồ thu hồi thác đổ (Cascade Invalidation Map) toàn diện
$cascadeMap = @{
    "gate_01_baseline_verified" = @{
        "revoke_gates" = @("gate_01_baseline_verified", "gate_02_audit_passed", "gate_03_spec_frozen", "gate_04_build_qa_passed", "gate_05_hard_verify_passed", "gate_06_handoff_signed")
        "revert_phase" = "STAGE_01_DISCOVERY"
        "revert_step"  = "01_APP_INTAKE"
    }
    "gate_02_audit_passed" = @{
        "revoke_gates" = @("gate_02_audit_passed", "gate_03_spec_frozen", "gate_04_build_qa_passed", "gate_05_hard_verify_passed", "gate_06_handoff_signed")
        "revert_phase" = "STAGE_02_REVERSE_ENGINEERING"
        "revert_step"  = "03_REA_SCAN"
    }
    "gate_03_spec_frozen" = @{
        "revoke_gates" = @("gate_03_spec_frozen", "gate_04_build_qa_passed", "gate_05_hard_verify_passed", "gate_06_handoff_signed")
        "revert_phase" = "STAGE_03_PRODUCT_DEFINITION"
        "revert_step"  = "06_REA_INTERVIEW"
    }
    "gate_04_build_qa_passed" = @{
        "revoke_gates" = @("gate_04_build_qa_passed", "gate_05_hard_verify_passed", "gate_06_handoff_signed")
        "revert_phase" = "STAGE_04_IMPLEMENTATION"
        "revert_step"  = "09_REA_BUILD"
    }
    "gate_05_hard_verify_passed" = @{
        "revoke_gates" = @("gate_04_build_qa_passed", "gate_05_hard_verify_passed", "gate_06_handoff_signed")
        "revert_phase" = "STAGE_04_IMPLEMENTATION"
        "revert_step"  = "09_REA_BUILD"
    }
    "gate_06_handoff_signed" = @{
        "revoke_gates" = @("gate_06_handoff_signed")
        "revert_phase" = "STAGE_05_VALIDATION"
        "revert_step"  = "12_HARD_VERIFY"
    }
}

switch ($Action) {
    "status" {
        $state = Get-CaseState
        Write-Host "================================================================================" -ForegroundColor Cyan
        Write-Host "   BẢNG TRẠNG THÁI CỔNG KIỂM SOÁT RWO v2 (CASE: $($state.case_id) | REV: $($state.revision)) " -ForegroundColor Cyan
        $wfMode = if ($state.workflow -and $state.workflow.mode) { $state.workflow.mode } else { "STANDARD" }
        Write-Host "   Phase: $($state.current_phase) | Step: $($state.current_step) | Mode: $wfMode | Risk: $($state.metrics.risk_level)" -ForegroundColor DarkCyan
        Write-Host "================================================================================" -ForegroundColor Cyan
        Write-Host ("{0,-28} | {1,-22} | {2,-12} | {3}" -f "CỔNG KIỂM SOÁT", "TRẠNG THÁI", "NGƯỜI DUYỆT", "GHI CHÚ / BẰNG CHỨNG") -ForegroundColor Gray
        Write-Host ("-" * 80) -ForegroundColor Gray

        foreach ($g in $gateOrder) {
            $gateObj = $state.gates.$g
            $gState = if ($gateObj.state) { $gateObj.state } elseif ($gateObj -eq $true) { "PASS" } else { "NOT_STARTED" }
            $approver = if ($gateObj.approved_by) { $gateObj.approved_by } else { "-" }
            $note = if ($gateObj.revoked_reason) {
                "[REVOKED]: " + $gateObj.revoked_reason
            } elseif ($gateObj.waived_reason) {
                "[WAIVED]: " + $gateObj.waived_reason
            } elseif ($gateObj.skip_reason) {
                "[SKIPPED]: " + $gateObj.skip_reason
            } elseif ($gateObj.evidence_sha256) {
                "SHA: " + $gateObj.evidence_sha256.Substring(0, [Math]::Min(12, $gateObj.evidence_sha256.Length)) + "..."
            } else { "-" }

            $stateColor = switch ($gState) {
                "PASS"                   { [ConsoleColor]::Green }
                "PASS_WITH_LIMITATIONS"  { [ConsoleColor]::Yellow }
                "REUSED_VALIDATED"       { [ConsoleColor]::Cyan }
                "WAIVED"                 { [ConsoleColor]::DarkYellow }
                "SKIPPED"                { [ConsoleColor]::DarkGray }
                "NOT_APPLICABLE"         { [ConsoleColor]::DarkGray }
                "FAILED"                 { [ConsoleColor]::Red }
                "INVALIDATED"            { [ConsoleColor]::DarkRed }
                "REVOKED"                { [ConsoleColor]::DarkRed }
                "BLOCKED"                { [ConsoleColor]::Magenta }
                "IN_PROGRESS"            { [ConsoleColor]::Blue }
                default                  { [ConsoleColor]::Gray }
            }

            Write-Host ("{0,-28} | " -f $g) -NoNewline -ForegroundColor White
            Write-Host ("{0,-22} | " -f $gState) -NoNewline -ForegroundColor $stateColor
            Write-Host ("{0,-12} | {1}" -f $approver, $note) -ForegroundColor White
        }
        Write-Host ("-" * 80) -ForegroundColor Gray
        Write-Host "Lệnh hỗ trợ: open | waive | skip | reject | status | validate" -ForegroundColor DarkGray
        exit 0
    }

    "validate" {
        $state = Get-CaseState
        Write-Host "================================================================================" -ForegroundColor Cyan
        Write-Host "   KIỂM ĐỊNH MÁY TRẠNG THÁI VÀ HỢP ĐỒNG BẰNG CHỨNG (.agents/state/active_case.json)" -ForegroundColor Cyan
        Write-Host "================================================================================" -ForegroundColor Cyan

        $hasError = $false

        # 1. Kiểm tra trường bắt buộc
        $requiredFields = @("schema_version", "case_id", "target_class", "current_phase", "current_step", "gates", "metrics", "workflow")
        foreach ($rf in $requiredFields) {
            if (-not $state.$rf) {
                Write-Host " [FAIL] Thiếu trường bắt buộc trong active_case.json: $rf" -ForegroundColor Red
                $hasError = $true
            }
        }

        # 2. Kiểm tra risk_level
        $validRisks = @("UNASSESSED", "LOW", "MEDIUM", "HIGH")
        if ($validRisks -notcontains $state.metrics.risk_level) {
            Write-Host " [FAIL] metrics.risk_level không hợp lệ: '$($state.metrics.risk_level)' (phải là UNASSESSED, LOW, MEDIUM, hoặc HIGH)" -ForegroundColor Red
            $hasError = $true
        } else {
            Write-Host " [PASS] metrics.risk_level hợp lệ: $($state.metrics.risk_level)" -ForegroundColor Green
        }

        # 3. Kiểm tra tính toàn vẹn 6 cổng và bằng chứng
        foreach ($g in $gateOrder) {
            $gateObj = $state.gates.$g
            if (-not $gateObj) {
                Write-Host " [FAIL] Thiếu cấu hình cổng: $g" -ForegroundColor Red
                $hasError = $true
                continue
            }
            $gState = if ($gateObj.state) { $gateObj.state } elseif ($gateObj -eq $true) { "PASS" } else { "NOT_STARTED" }
            
            if ($validGateStates -notcontains $gState -and $gState -ne "NOT_RUN" -and $gState -ne "REVOKED") {
                Write-Host " [FAIL] Cổng $g có trạng thái không hợp lệ: '$gState'" -ForegroundColor Red
                $hasError = $true
                continue
            }

            if ($gState -eq "PASS" -or $gState -eq "PASS_WITH_LIMITATIONS" -or $gState -eq "REUSED_VALIDATED") {
                if (-not $gateObj.evidence -or $gateObj.evidence.Count -eq 0) {
                    Write-Host " [FAIL] Cổng $g đạt trạng thái $gState nhưng danh sách evidence bị rỗng!" -ForegroundColor Red
                    $hasError = $true
                } else {
                    foreach ($ev in $gateObj.evidence) {
                        $evPath = if ([System.IO.Path]::IsPathRooted($ev)) { $ev } else { Join-Path $repoRoot $ev }
                        if (-not (Test-Path -LiteralPath $evPath)) {
                            Write-Host " [FAIL] Cổng $g đã $gState nhưng không tìm thấy file bằng chứng: $ev" -ForegroundColor Red
                            $hasError = $true
                        }
                    }
                }
                if (-not $gateObj.evidence_sha256) {
                    Write-Host " [FAIL] Cổng $g đạt $gState nhưng thiếu evidence_sha256!" -ForegroundColor Red
                    $hasError = $true
                } else {
                    # Kiểm tra và tính toán lại SHA-256 từ tệp trên đĩa
                    $primaryEv = if ($gateObj.evidence -and $gateObj.evidence.Count -gt 0) { $gateObj.evidence[0] } else { $null }
                    if ($primaryEv) {
                        $primaryEvPath = if ([System.IO.Path]::IsPathRooted($primaryEv)) { $primaryEv } else { Join-Path $repoRoot $primaryEv }
                        if (Test-Path -LiteralPath $primaryEvPath) {
                            $actualHash = Get-NormalizedFileHash -FilePath $primaryEvPath
                            if ($actualHash -ne $gateObj.evidence_sha256) {
                                Write-Host " [FAIL] Cổng $g bị sai lệch mã băm SHA-256! Kỳ vọng: $($gateObj.evidence_sha256), Thực tế trên đĩa: $actualHash" -ForegroundColor Red
                                $hasError = $true
                            } else {
                                Write-Host " [PASS] Cổng ${g}: Trạng thái $gState và SHA-256 khớp 100% với đĩa." -ForegroundColor Green
                            }
                        } else {
                            Write-Host " [FAIL] Cổng $g không thể kiểm tra SHA-256 vì tệp không tồn tại: $primaryEv" -ForegroundColor Red
                            $hasError = $true
                        }
                    } else {
                        Write-Host " [PASS] Cổng ${g}: Trạng thái $gState và SHA-256 hợp lệ." -ForegroundColor Green
                    }
                }
            } elseif ($gState -eq "WAIVED") {
                if (-not $gateObj.waived_reason) {
                    Write-Host " [FAIL] Cổng $g là WAIVED nhưng thiếu lý do waived_reason!" -ForegroundColor Red
                    $hasError = $true
                } else {
                    Write-Host " [WARN] Cổng ${g}: Miễn trừ (WAIVED) - Lý do: $($gateObj.waived_reason)" -ForegroundColor DarkYellow
                }
            } elseif ($gState -eq "SKIPPED" -or $gState -eq "NOT_APPLICABLE") {
                if ($gState -eq "SKIPPED" -and [string]::IsNullOrWhiteSpace($gateObj.skip_reason)) {
                    Write-Host " [FAIL] Cổng $g là SKIPPED nhưng thiếu lý do skip_reason!" -ForegroundColor Red
                    $hasError = $true
                } else {
                    Write-Host " [INFO] Cổng ${g}: Bỏ qua ($gState) - Lý do: $($gateObj.skip_reason)" -ForegroundColor Gray
                }
            } elseif ($gState -eq "FAILED" -or $gState -eq "BLOCKED") {
                Write-Host " [FAIL] Cổng $g đang ở trạng thái lỗi: $gState!" -ForegroundColor Red
                $hasError = $true
            } elseif ($gState -eq "INVALIDATED") {
                Write-Host " [WARN] Cổng ${g}: Trạng thái INVALIDATED (Cần thực thi lại)." -ForegroundColor Yellow
            } else {
                Write-Host " [INFO] Cổng ${g}: Trạng thái $gState." -ForegroundColor Gray
            }
        }

        Write-Host ("-" * 80) -ForegroundColor Gray
        if ($hasError) {
            Write-Host "[FAIL] Máy trạng thái active_case.json chưa đạt chuẩn hợp đồng!" -ForegroundColor Red
            exit 1
        } else {
            Write-Host "[OK] Máy trạng thái và hợp đồng bằng chứng đạt chuẩn RWO v2 100%." -ForegroundColor Green
            exit 0
        }
    }

    "open" {
        $resolvedGate = Resolve-GateName $Gate
        if (-not $resolvedGate) {
            Write-Host "[!] Vui lòng chỉ định cổng cần mở (ví dụ: gate.ps1 open 1 hoặc gate.ps1 open gate_01_baseline_verified)" -ForegroundColor Yellow
            exit 1
        }

        $state = Get-CaseState
        $expectedRev = if ($state.revision) { [int]$state.revision } else { -1 }
        $gateIdx = $gateOrder.IndexOf($resolvedGate)
        if ($gateIdx -lt 0) {
            Write-Host "[FAIL] Tên cổng không hợp lệ: $resolvedGate" -ForegroundColor Red
            exit 1
        }

        # 1. Kiểm tra DAG phụ thuộc toàn bộ chuỗi tiền bối
        for ($i = 0; $i -lt $gateIdx; $i++) {
            $ancestorGate = $gateOrder[$i]
            $ancestorObj = $state.gates.$ancestorGate
            $ancestorState = if ($ancestorObj.state) { $ancestorObj.state } elseif ($ancestorObj -eq $true) { "PASS" } else { "NOT_STARTED" }
            if ($clearedStates -notcontains $ancestorState) {
                Write-Host "[FAIL] Không thể mở $resolvedGate vì cổng tiền bối $ancestorGate chưa hoàn tất hợp lệ (hiện tại: $ancestorState)!" -ForegroundColor Red
                exit 1
            }
        }

        # 2. Bắt buộc tệp bằng chứng tồn tại trên đĩa
        if (-not $Evidence) {
            Write-Host "[FAIL] Lệnh open bắt buộc phải có tham số -Evidence <đường_dẫn_tệp_bằng_chứng>!" -ForegroundColor Red
            exit 1
        }
        $evPath = if ([System.IO.Path]::IsPathRooted($Evidence)) { $Evidence } else { Join-Path $repoRoot $Evidence }
        if (-not (Test-Path -LiteralPath $evPath)) {
            Write-Host "[FAIL] Không tìm thấy file bằng chứng trên ổ đĩa: $Evidence" -ForegroundColor Red
            exit 1
        }

        $sha = Get-NormalizedFileHash -FilePath $evPath
        $relPath = if ($evPath.StartsWith($repoRoot)) { $evPath.Substring($repoRoot.Length).TrimStart('\', '/') } else { $Evidence }
        $evList = @($relPath)

        $approver = if ($ApprovedBy) { $ApprovedBy } else { "coordinator" }
        $now = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
        $finalState = if ($Mode -eq "PASS_WITH_LIMITATIONS") { "PASS_WITH_LIMITATIONS" } else { "PASS" }

        # Cập nhật cổng
        $state.gates.$resolvedGate = [ordered]@{
            state = $finalState
            evidence = $evList
            evidence_sha256 = $sha
            approved_by = $approver
            approved_at = $now
            revoked_reason = $null
            waived_reason = $null
            skip_reason = $null
        }
        $state.current_gate_status = "${resolvedGate}_${finalState}".ToUpper()

        Save-CaseStateAtomic -State $state -ExpectedRevision $expectedRev

        Append-Event -ActionName "GATE_OPEN" -Actor $approver -Phase $state.current_phase -Step $state.current_step -EventDetails "Mở thành công $resolvedGate (Trạng thái: $finalState)" -EvidenceSha $sha -State $state

        Write-Host "================================================================================" -ForegroundColor Cyan
        Write-Host "[OK] ĐÃ MỞ CỔNG THÀNH CÔNG: $resolvedGate ($finalState)" -ForegroundColor Green
        Write-Host "     Người phê duyệt : $approver" -ForegroundColor White
        Write-Host "     Thời gian duyệt : $now" -ForegroundColor White
        Write-Host "     Tệp bằng chứng  : $relPath" -ForegroundColor White
        Write-Host "     Evidence SHA256 : $sha" -ForegroundColor Gray
        Write-Host "================================================================================" -ForegroundColor Cyan
        exit 0
    }

    "waive" {
        $resolvedGate = Resolve-GateName $Gate
        if (-not $resolvedGate) {
            Write-Host "[!] Vui lòng chỉ định cổng cần miễn trừ (ví dụ: gate.ps1 waive 1 -Reason 'Không có thiết bị AVD')" -ForegroundColor Yellow
            exit 1
        }
        if (-not $Reason) {
            Write-Host "[FAIL] Miễn trừ cổng bắt buộc phải có lý do và đánh giá rủi ro (-Reason)!" -ForegroundColor Red
            exit 1
        }

        $state = Get-CaseState
        $expectedRev = if ($state.revision) { [int]$state.revision } else { -1 }
        $gateIdx = $gateOrder.IndexOf($resolvedGate)
        if ($gateIdx -lt 0) {
            Write-Host "[FAIL] Tên cổng không hợp lệ: $resolvedGate" -ForegroundColor Red
            exit 1
        }

        # Kiểm tra toàn bộ chuỗi tiền bối
        for ($i = 0; $i -lt $gateIdx; $i++) {
            $ancestorGate = $gateOrder[$i]
            $ancestorObj = $state.gates.$ancestorGate
            $ancestorState = if ($ancestorObj.state) { $ancestorObj.state } elseif ($ancestorObj -eq $true) { "PASS" } else { "NOT_STARTED" }
            if ($clearedStates -notcontains $ancestorState) {
                Write-Host "[FAIL] Không thể miễn trừ $resolvedGate vì cổng tiền bối $ancestorGate chưa hoàn tất hợp lệ (hiện tại: $ancestorState)!" -ForegroundColor Red
                exit 1
            }
        }

        $approver = if ($ApprovedBy) { $ApprovedBy } else { "human_owner" }
        $now = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")

        $state.gates.$resolvedGate = [ordered]@{
            state = "WAIVED"
            evidence = @()
            evidence_sha256 = $null
            approved_by = $approver
            approved_at = $now
            revoked_reason = $null
            waived_reason = $Reason
            skip_reason = $null
        }
        $state.current_gate_status = "${resolvedGate}_WAIVED".ToUpper()

        Save-CaseStateAtomic -State $state -ExpectedRevision $expectedRev

        Append-Event -ActionName "GATE_WAIVED" -Actor $approver -Phase $state.current_phase -Step $state.current_step -EventDetails "Miễn trừ $resolvedGate. Lý do: $Reason" -EvidenceSha $null -State $state

        Write-Host "================================================================================" -ForegroundColor Yellow
        Write-Host "[WARN] ĐÃ MIỄN TRỪ CỔNG (GATE WAIVED): $resolvedGate" -ForegroundColor Yellow
        Write-Host "       Người quyết định: $approver" -ForegroundColor White
        Write-Host "       Lý do miễn trừ  : $Reason" -ForegroundColor White
        Write-Host "       CẢNH BÁO: Miễn trừ không đồng nghĩa với PASS toàn phần. Rủi ro được lưu trữ." -ForegroundColor DarkYellow
        Write-Host "================================================================================" -ForegroundColor Yellow
        exit 0
    }

    "skip" {
        $resolvedGate = Resolve-GateName $Gate
        if (-not $resolvedGate) {
            Write-Host "[!] Vui lòng chỉ định cổng cần bỏ qua (ví dụ: gate.ps1 skip 4 -Reason 'Analysis-only mode')" -ForegroundColor Yellow
            exit 1
        }
        if (-not $Reason) {
            Write-Host "[FAIL] Bỏ qua cổng bắt buộc phải có lý do (-Reason)!" -ForegroundColor Red
            exit 1
        }

        $state = Get-CaseState
        $expectedRev = if ($state.revision) { [int]$state.revision } else { -1 }
        $gateIdx = $gateOrder.IndexOf($resolvedGate)
        if ($gateIdx -lt 0) {
            Write-Host "[FAIL] Tên cổng không hợp lệ: $resolvedGate" -ForegroundColor Red
            exit 1
        }

        # Kiểm tra toàn bộ chuỗi tiền bối
        for ($i = 0; $i -lt $gateIdx; $i++) {
            $ancestorGate = $gateOrder[$i]
            $ancestorObj = $state.gates.$ancestorGate
            $ancestorState = if ($ancestorObj.state) { $ancestorObj.state } elseif ($ancestorObj -eq $true) { "PASS" } else { "NOT_STARTED" }
            if ($clearedStates -notcontains $ancestorState) {
                Write-Host "[FAIL] Không thể bỏ qua $resolvedGate vì cổng tiền bối $ancestorGate chưa hoàn tất hợp lệ (hiện tại: $ancestorState)!" -ForegroundColor Red
                exit 1
            }
        }

        $approver = if ($ApprovedBy) { $ApprovedBy } else { "coordinator" }
        $now = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
        $targetState = if ($Mode -eq "NOT_APPLICABLE") { "NOT_APPLICABLE" } else { "SKIPPED" }

        $state.gates.$resolvedGate = [ordered]@{
            state = $targetState
            evidence = @()
            evidence_sha256 = $null
            approved_by = $approver
            approved_at = $now
            revoked_reason = $null
            waived_reason = $null
            skip_reason = $Reason
        }
        $state.current_gate_status = "${resolvedGate}_${targetState}".ToUpper()

        Save-CaseStateAtomic -State $state -ExpectedRevision $expectedRev

        Append-Event -ActionName "GATE_SKIPPED" -Actor $approver -Phase $state.current_phase -Step $state.current_step -EventDetails "Bỏ qua $resolvedGate ($targetState). Lý do: $Reason" -EvidenceSha $null -State $state

        Write-Host "================================================================================" -ForegroundColor DarkGray
        Write-Host "[INFO] ĐÃ BỎ QUA CỔNG: $resolvedGate ($targetState)" -ForegroundColor DarkGray
        Write-Host "       Người thực hiện : $approver" -ForegroundColor White
        Write-Host "       Lý do           : $Reason" -ForegroundColor White
        Write-Host "================================================================================" -ForegroundColor DarkGray
        exit 0
    }

    "reject" {
        $resolvedGate = Resolve-GateName $Gate
        if (-not $resolvedGate) {
            Write-Host "[!] Vui lòng chỉ định cổng bị reject (ví dụ: gate.ps1 reject 3 hoặc gate.ps1 reject gate_01_baseline_verified)" -ForegroundColor Yellow
            exit 1
        }

        $state = Get-CaseState
        $expectedRev = if ($state.revision) { [int]$state.revision } else { -1 }
        $rejectReason = if ($Reason) { $Reason } else { "Người dùng hoặc kiểm toán độc lập yêu cầu chỉnh sửa lại (Reject Loop)." }
        $approver = if ($ApprovedBy) { $ApprovedBy } else { "coordinator" }

        # Kiểm soát vòng lặp hội tụ (Review Convergence Limit: max 2 rounds)
        if (-not $state.metrics) {
            $state.metrics = [ordered]@{}
        }
        $currentRounds = if ($state.metrics.review_convergence_rounds) { [int]$state.metrics.review_convergence_rounds } else { 0 }
        $maxRounds = if ($state.metrics.max_convergence_rounds) { [int]$state.metrics.max_convergence_rounds } else { 2 }
        $currentRounds++
        $state.metrics.review_convergence_rounds = $currentRounds

        if ($currentRounds -gt $maxRounds) {
            Write-Host "================================================================================" -ForegroundColor Red
            Write-Host "[BLOCKED] Số vòng reject ($currentRounds) đã vượt quá giới hạn tối đa ($maxRounds vòng)!" -ForegroundColor Red
            Write-Host "          Quy trình chuyển sang trạng thái BLOCKED để xin ý kiến Human Owner." -ForegroundColor Red
            Write-Host "================================================================================" -ForegroundColor Red
            $state.gates.$resolvedGate.state = "BLOCKED"
            $state.gates.$resolvedGate.revoked_reason = "Đã vượt quá số vòng reject tối đa ($maxRounds vòng): $rejectReason"
            $state.current_gate_status = "${resolvedGate}_BLOCKED".ToUpper()

            Save-CaseStateAtomic -State $state -ExpectedRevision $expectedRev
            Append-Event -ActionName "GATE_BLOCKED" -Actor $approver -Phase $state.current_phase -Step $state.current_step -EventDetails "Cổng $resolvedGate bị BLOCKED do vượt quá $maxRounds vòng reject. Lý do: $rejectReason" -EvidenceSha $null -State $state
            exit 1
        }

        # Thu hồi thác đổ dựa trên cascadeMap
        if (-not $cascadeMap.ContainsKey($resolvedGate)) {
            Write-Host "[FAIL] Không tìm thấy quy tắc thác đổ cho cổng: $resolvedGate" -ForegroundColor Red
            exit 1
        }

        $rule = $cascadeMap[$resolvedGate]
        $gatesToRevoke = $rule.revoke_gates
        $revertPhase = $rule.revert_phase
        $revertStep = $rule.revert_step

        $now = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")

        foreach ($rg in $gatesToRevoke) {
            $state.gates.$rg = [ordered]@{
                state = "INVALIDATED"
                evidence = @()
                evidence_sha256 = $null
                approved_by = $approver
                approved_at = $now
                revoked_reason = "Cascade Invalidation từ việc reject cổng ${resolvedGate}: $rejectReason"
                waived_reason = $null
                skip_reason = $null
            }
        }

        $state.current_phase = $revertPhase
        $state.current_step = $revertStep
        $state.current_gate_status = "${resolvedGate}_INVALIDATED".ToUpper()

        Save-CaseStateAtomic -State $state -ExpectedRevision $expectedRev

        Append-Event -ActionName "GATE_CASCADE_REJECT" -Actor $approver -Phase $revertPhase -Step $revertStep -EventDetails "Reject $resolvedGate (Vòng $currentRounds/$maxRounds). Thu hồi toàn bộ hạ nguồn: $($gatesToRevoke -join ', '). Lý do: $rejectReason" -EvidenceSha $null -State $state

        Write-Host "================================================================================" -ForegroundColor DarkRed
        Write-Host "[!] THU HỒI THÁC ĐỔ THÀNH CÔNG (CASCADE INVALIDATION): $resolvedGate (Vòng $currentRounds/$maxRounds)" -ForegroundColor Red
        Write-Host "    Các cổng bị vô hiệu hóa : $($gatesToRevoke -join ', ')" -ForegroundColor Yellow
        Write-Host "    Trở về điểm an toàn     : Phase=$revertPhase | Step=$revertStep" -ForegroundColor White
        Write-Host "    Lý do thu hồi           : $rejectReason" -ForegroundColor Gray
        Write-Host "================================================================================" -ForegroundColor DarkRed
        exit 0
    }

    "event" {
        if (-not $Details) {
            Write-Host "[!] Vui lòng nhập chi tiết sự kiện bằng tham số -Details." -ForegroundColor Yellow
            exit 1
        }
        $state = Get-CaseState
        $actor = if ($ApprovedBy) { $ApprovedBy } else { "coordinator" }
        Append-Event -ActionName "CUSTOM_LOG" -Actor $actor -Phase $state.current_phase -Step $state.current_step -EventDetails $Details -EvidenceSha $null -State $state
        Write-Host "[OK] Đã ghi sự kiện vào .agents/state/events.jsonl" -ForegroundColor Green
        exit 0
    }
}
