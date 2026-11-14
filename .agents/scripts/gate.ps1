# Script Quản Trị Cổng Kiểm Soát & Máy Trạng Thái (Deterministic Gate & State Machine Engine v1.1)
# Bắt buộc tuân thủ nguyên tắc Single Authoritative Coordinator và bảo toàn Gate Invalidation Invariant.
param(
    [Parameter(Position=0)]
    [ValidateSet("status", "validate", "open", "reject", "event")]
    [string]$Action = "status",

    [Parameter(Position=1)]
    [string]$Gate,

    [string]$Evidence,
    [string]$ApprovedBy,
    [string]$Reason,
    [string]$Details
)

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

if (-not (Test-Path -LiteralPath $stateFile)) {
    Write-Host "[FAIL] Không tìm thấy active_case.json tại: $stateFile" -ForegroundColor Red
    exit 1
}

function Get-CaseState {
    return (Get-Content -LiteralPath $stateFile -Raw -Encoding UTF8 | ConvertFrom-Json)
}

function Save-CaseState {
    param([object]$State)
    $State.last_updated = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
    $json = $State | ConvertTo-Json -Depth 10
    Set-Content -LiteralPath $stateFile -Value $json -Encoding UTF8
}

function Append-Event {
    param(
        [string]$ActionName,
        [string]$Actor,
        [string]$Phase,
        [string]$Step,
        [string]$EventDetails,
        [string]$EvidenceSha
    )
    $timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
    $eventId = "EVT-" + (Get-Date).ToString("yyyyMMdd-HHmmss-fff")
    $state = Get-CaseState
    $caseId = if ($state.case_id) { $state.case_id } else { "CASE-UNKNOWN" }
    
    $eventObj = [ordered]@{
        event_id = $eventId
        timestamp = $timestamp
        case_id = $caseId
        actor = if ($Actor) { $Actor } else { "coordinator" }
        action = $ActionName
        phase = $Phase
        step = $Step
        details = $EventDetails
        evidence_sha256 = $EvidenceSha
    }
    $line = ($eventObj | ConvertTo-Json -Compress)
    Add-Content -LiteralPath $eventsFile -Value $line -Encoding UTF8
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

switch ($Action) {
    "status" {
        $state = Get-CaseState
        Write-Host "================================================================================" -ForegroundColor Cyan
        Write-Host "   BẢNG TRẠNG THÁI 6 CỔNG KIỂM SOÁT (CASE: $($state.case_id) | REV: $($state.revision)) " -ForegroundColor Cyan
        Write-Host "   Phase: $($state.current_phase) | Step: $($state.current_step) | Risk: $($state.metrics.risk_level)" -ForegroundColor DarkCyan
        Write-Host "================================================================================" -ForegroundColor Cyan
        Write-Host ("{0,-28} | {1,-10} | {2,-12} | {3,-15} | {4}" -f "CỔNG KIỂM SOÁT", "TRẠNG THÁI", "NGƯỜI DUYỆT", "NGÀY DUYỆT", "GHI CHÚ / BẰNG CHỨNG") -ForegroundColor Gray
        Write-Host ("-" * 80) -ForegroundColor Gray

        foreach ($g in $gateOrder) {
            $gateObj = $state.gates.$g
            $gState = if ($gateObj.state) { $gateObj.state } elseif ($gateObj -eq $true) { "PASS" } else { "NOT_RUN" }
            $approver = if ($gateObj.approved_by) { $gateObj.approved_by } else { "-" }
            $approvedDate = if ($gateObj.approved_at) { $gateObj.approved_at.Substring(0, 10) } else { "-" }
            $note = if ($gateObj.revoked_reason) { "[REVOKED]: " + $gateObj.revoked_reason } elseif ($gateObj.evidence_sha256) { "SHA: " + $gateObj.evidence_sha256.Substring(0, 8) + "..." } else { "-" }

            $stateColor = switch ($gState) {
                "PASS"    { [ConsoleColor]::Green }
                "FAIL"    { [ConsoleColor]::Red }
                "REVOKED" { [ConsoleColor]::Yellow }
                "BLOCKED" { [ConsoleColor]::DarkYellow }
                default   { [ConsoleColor]::Gray }
            }

            Write-Host ("{0,-28} | " -f $g) -NoNewline -ForegroundColor White
            Write-Host ("{0,-10} | " -f $gState) -NoNewline -ForegroundColor $stateColor
            Write-Host ("{0,-12} | {1,-15} | {2}" -f $approver, $approvedDate, $note) -ForegroundColor White
        }
        Write-Host ("-" * 80) -ForegroundColor Gray
        Write-Host "Gợi ý: Dùng 'gate.ps1 open <gate_id> -Evidence <path>' hoặc 'gate.ps1 reject <gate_id> -Reason <lý_do>'" -ForegroundColor DarkGray
        exit 0
    }

    "validate" {
        $state = Get-CaseState
        Write-Host "================================================================================" -ForegroundColor Cyan
        Write-Host "   KIỂM ĐỊNH MÁY TRẠNG THÁI VÀ HỢP ĐỒNG BẰNG CHỨNG (.agents/state/active_case.json)" -ForegroundColor Cyan
        Write-Host "================================================================================" -ForegroundColor Cyan

        $hasError = $false

        # 1. Kiểm tra trường bắt buộc
        $requiredFields = @("schema_version", "case_id", "target_class", "current_phase", "current_step", "gates", "metrics")
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

        # 3. Kiểm tra tính toàn vẹn 6 cổng
        foreach ($g in $gateOrder) {
            $gateObj = $state.gates.$g
            if (-not $gateObj) {
                Write-Host " [FAIL] Thiếu cấu hình cổng: $g" -ForegroundColor Red
                $hasError = $true
                continue
            }
            $gState = if ($gateObj.state) { $gateObj.state } elseif ($gateObj -eq $true) { "PASS" } else { "NOT_RUN" }
            if ($gState -eq "PASS") {
                if ($gateObj.evidence) {
                    foreach ($ev in $gateObj.evidence) {
                        $evPath = if ([System.IO.Path]::IsPathRooted($ev)) { $ev } else { Join-Path $repoRoot $ev }
                        if (-not (Test-Path -LiteralPath $evPath)) {
                            Write-Host " [FAIL] Cổng $g đã PASS nhưng không tìm thấy file bằng chứng: $ev" -ForegroundColor Red
                            $hasError = $true
                        }
                    }
                }
                Write-Host " [PASS] Cổng ${g}: Trạng thái PASS hợp lệ." -ForegroundColor Green
            } else {
                Write-Host " [INFO] Cổng ${g}: Trạng thái $gState." -ForegroundColor Gray
            }
        }

        Write-Host ("-" * 80) -ForegroundColor Gray
        if ($hasError) {
            Write-Host "[FAIL] Máy trạng thái active_case.json chưa đạt chuẩn hợp đồng!" -ForegroundColor Red
            exit 1
        } else {
            Write-Host "[OK] Máy trạng thái và hợp đồng bằng chứng đạt chuẩn 100%." -ForegroundColor Green
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
        $gateIdx = $gateOrder.IndexOf($resolvedGate)
        if ($gateIdx -lt 0) {
            Write-Host "[FAIL] Tên cổng không hợp lệ: $resolvedGate" -ForegroundColor Red
            exit 1
        }

        # Kiểm tra thứ tự tuần tự của các cổng
        if ($gateIdx -gt 0) {
            $prevGate = $gateOrder[$gateIdx - 1]
            $prevState = if ($state.gates.$prevGate.state) { $state.gates.$prevGate.state } elseif ($state.gates.$prevGate -eq $true) { "PASS" } else { "NOT_RUN" }
            if ($prevState -ne "PASS") {
                Write-Host "[FAIL] Không thể mở $resolvedGate vì cổng liền trước ($prevGate) chưa PASS (hiện tại: $prevState)!" -ForegroundColor Red
                exit 1
            }
        }

        # Tính toán SHA-256 bằng chứng nếu có
        $sha = $null
        $evList = @()
        if ($Evidence) {
            $evPath = if ([System.IO.Path]::IsPathRooted($Evidence)) { $Evidence } else { Join-Path $repoRoot $Evidence }
            if (-not (Test-Path -LiteralPath $evPath)) {
                Write-Host "[FAIL] Không tìm thấy file bằng chứng: $Evidence" -ForegroundColor Red
                exit 1
            }
            $sha = (Get-FileHash -LiteralPath $evPath -Algorithm SHA256).Hash
            $relPath = if ($evPath.StartsWith($repoRoot)) { $evPath.Substring($repoRoot.Length).TrimStart('\', '/') } else { $Evidence }
            $evList += $relPath
        }

        $approver = if ($ApprovedBy) { $ApprovedBy } else { "coordinator" }
        $now = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")

        # Cập nhật đối tượng cổng
        $state.gates.$resolvedGate = [ordered]@{
            state = "PASS"
            evidence = $evList
            evidence_sha256 = $sha
            approved_by = $approver
            approved_at = $now
            revoked_reason = $null
        }
        $state.current_gate_status = "${resolvedGate}_PASSED".ToUpper()

        Save-CaseState -State $state

        # Ghi nhật ký sự kiện
        Append-Event -ActionName "GATE_OPEN" -Actor $approver -Phase $state.current_phase -Step $state.current_step -EventDetails "Mở thành công cổng $resolvedGate" -EvidenceSha $sha

        Write-Host "================================================================================" -ForegroundColor Cyan
        Write-Host "[OK] ĐÃ MỞ CỔNG THÀNH CÔNG: $resolvedGate (PASS)" -ForegroundColor Green
        Write-Host "     Người phê duyệt: $approver" -ForegroundColor White
        Write-Host "     Thời gian duyệt: $now" -ForegroundColor White
        if ($sha) { Write-Host "     Evidence SHA256: $sha" -ForegroundColor Gray }
        Write-Host "================================================================================" -ForegroundColor Cyan
        exit 0
    }

    "reject" {
        $resolvedGate = Resolve-GateName $Gate
        if (-not $resolvedGate) {
            Write-Host "[!] Vui lòng chỉ định cổng bị reject (ví dụ: gate.ps1 reject 3 hoặc gate.ps1 reject gate_05_hard_verify_passed)" -ForegroundColor Yellow
            exit 1
        }

        $state = Get-CaseState
        $rejectReason = if ($Reason) { $Reason } else { "Người dùng hoặc kiểm toán độc lập yêu cầu chỉnh sửa lại (Reject Loop)." }
        $approver = if ($ApprovedBy) { $ApprovedBy } else { "coordinator" }

        # Xử lý theo gate_invalidation_map
        $mapKey = switch ($resolvedGate) {
            "gate_03_spec_frozen"        { "REJECT_GATE_03" }
            "gate_04_build_qa_passed"    { "REJECT_GATE_04" }
            "gate_05_hard_verify_passed" { "REJECT_GATE_05" }
            default { "REJECT_GENERIC" }
        }

        $gatesToRevoke = @($resolvedGate)
        if ($mapKey -eq "REJECT_GATE_03") {
            $gatesToRevoke = @("gate_03_spec_frozen", "gate_04_build_qa_passed", "gate_05_hard_verify_passed", "gate_06_handoff_signed")
            $state.current_phase = "STAGE_03_PRODUCT_DEFINITION"
            $state.current_step = "06_REA_INTERVIEW"
            $state.revision = [int]$state.revision + 1
        } elseif ($mapKey -eq "REJECT_GATE_04" -or $mapKey -eq "REJECT_GATE_05") {
            $gatesToRevoke = @("gate_04_build_qa_passed", "gate_05_hard_verify_passed", "gate_06_handoff_signed")
            $state.current_phase = "STAGE_04_IMPLEMENTATION"
            $state.current_step = "09_REA_BUILD"
        }

        foreach ($rg in $gatesToRevoke) {
            $state.gates.$rg = [ordered]@{
                state = "REVOKED"
                evidence = @()
                evidence_sha256 = $null
                approved_by = $approver
                approved_at = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
                revoked_reason = $rejectReason
            }
        }

        $state.current_gate_status = "${resolvedGate}_REVOKED".ToUpper()
        Save-CaseState -State $state

        Append-Event -ActionName "GATE_REJECT" -Actor $approver -Phase $state.current_phase -Step $state.current_step -EventDetails "Reject $resolvedGate. Thu hồi các cổng: $($gatesToRevoke -join ', '). Lý do: $rejectReason" -EvidenceSha $null

        Write-Host "================================================================================" -ForegroundColor Cyan
        Write-Host "[!] ĐÃ THU HỒI CỔNG THÀNH CÔNG (GATE REVOKED): $resolvedGate" -ForegroundColor Yellow
        Write-Host "    Các cổng bị thu hồi tự động: $($gatesToRevoke -join ', ')" -ForegroundColor Yellow
        Write-Host "    Trở về: Phase=$($state.current_phase), Step=$($state.current_step)" -ForegroundColor White
        Write-Host "    Lý do thu hồi: $rejectReason" -ForegroundColor Gray
        Write-Host "================================================================================" -ForegroundColor Cyan
        exit 0
    }

    "event" {
        if (-not $Details) {
            Write-Host "[!] Vui lòng nhập chi tiết sự kiện bằng tham số -Details." -ForegroundColor Yellow
            exit 1
        }
        $state = Get-CaseState
        $actor = if ($ApprovedBy) { $ApprovedBy } else { "coordinator" }
        Append-Event -ActionName "CUSTOM_LOG" -Actor $actor -Phase $state.current_phase -Step $state.current_step -EventDetails $Details -EvidenceSha $null
        Write-Host "[OK] Đã ghi sự kiện vào .agents/state/events.jsonl" -ForegroundColor Green
        exit 0
    }
}
