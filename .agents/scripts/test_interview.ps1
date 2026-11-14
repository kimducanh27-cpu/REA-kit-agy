# ==============================================================================
# Script Kiểm Định Tự Động Bộ Máy Phỏng Vấn Thích Ứng (test_interview.ps1)
# REA-kit-agy v1.1 - 3-Layer Adaptive Interview Verification Suite
# Layer 1: Static Validation & Schema Conformance
# Layer 2: State & CLI Integration & Exit Gate Tests 01-06 + Regression Tests
# Layer 3: Realistic Adaptive Behavior Scenarios A through J (Real CLI & State)
# ==============================================================================
[CmdletBinding()]
param(
    [switch]$VerboseOutput
)

$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$repoRoot = $scriptDir
while ($repoRoot -and -not (Test-Path (Join-Path $repoRoot "docs/WORKFLOW_LIFECYCLE.md"))) {
    $parent = Split-Path $repoRoot -Parent
    if ($parent -eq $repoRoot -or [string]::IsNullOrEmpty($parent)) { break }
    $repoRoot = $parent
}
if (-not $repoRoot) { $repoRoot = (Get-Location).Path }

$interviewScript = Join-Path $repoRoot ".agents/scripts/interview.ps1"
$gateScript      = Join-Path $repoRoot ".agents/scripts/gate.ps1"
$contextScript   = Join-Path $repoRoot ".agents/scripts/context.ps1"
$stateFile       = Join-Path $repoRoot ".agents/state/interview_state.json"
$caseFile        = Join-Path $repoRoot ".agents/state/active_case.json"
$templateFile    = Join-Path $repoRoot "templates/14-INTERVIEW-STATE-TEMPLATE.json"
$specTemplate    = Join-Path $repoRoot "templates/02-SPEC-TEMPLATE.md"
$domainsDir      = Join-Path $repoRoot ".agents/skills/rea-interview/domains"
$skillFile       = Join-Path $repoRoot ".agents/skills/rea-interview/SKILL.md"

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "   REA-KIT-AGY v1.1 — BỘ KIỂM ĐỊNH ADAPTIVE INTERVIEW 3-LAYER    " -ForegroundColor Cyan
Write-Host "   Repo Root: $repoRoot" -ForegroundColor DarkCyan
Write-Host "==================================================================" -ForegroundColor Cyan

$testCount = 0
$passCount = 0
$failCount = 0

function Assert-Test([string]$testName, [bool]$condition, [string]$failureDetails = "") {
    $script:testCount++
    if ($condition) {
        $script:passCount++
        Write-Host " [PASS] $testName" -ForegroundColor Green
    } else {
        $script:failCount++
        Write-Host " [FAIL] $testName" -ForegroundColor Red
        if ($failureDetails) {
            Write-Host "        Chi tiết: $failureDetails" -ForegroundColor Yellow
        }
    }
}

function Save-Utf8NoBom([string]$path, [string]$content) {
    for ($attempt = 1; $attempt -le 10; $attempt++) {
        try {
            [System.IO.File]::WriteAllText($path, $content, (New-Object System.Text.UTF8Encoding($false)))
            break
        } catch [System.IO.IOException], [System.UnauthorizedAccessException] {
            if ($attempt -eq 10) { throw }
            Start-Sleep -Milliseconds 50
        }
    }
}

function Get-StateWithRetry {
    for ($attempt = 1; $attempt -le 10; $attempt++) {
        try {
            return (Get-Content -LiteralPath $stateFile -Raw -Encoding UTF8 | ConvertFrom-Json)
        } catch [System.IO.IOException], [System.UnauthorizedAccessException] {
            if ($attempt -eq 10) { throw }
            Start-Sleep -Milliseconds 50
        }
    }
}

# DIFF-03 Test Safety Tracking: lưu vết để chỉ dọn dẹp các tệp sinh ra bởi bài test
$createdPlanIds = [System.Collections.Generic.List[string]]::new()
$casesDir = Join-Path $repoRoot ".agents/state/cases"
$initialCaseBackups = if (Test-Path -LiteralPath $casesDir) {
    @(Get-ChildItem -Path $casesDir -Filter "*.json" -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
} else { @() }
$initialCaseDirs = if (Test-Path -LiteralPath $casesDir) {
    @(Get-ChildItem -Path $casesDir -Directory -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
} else { @() }

# Wrapper chạy context.ps1 plan có ghi nhận Plan ID phục vụ dọn dẹp an toàn (DIFF-03)
function Invoke-ContextPlanSafe([string]$taskText) {
    $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $contextScript plan -Task $taskText 2>&1
    $outStr = $out -join "`n"
    if ($outStr -match 'Plan ID\s*:\s*(PLAN-[^\s\r\n]+)') {
        $matchedPlanId = $Matches[1].Trim()
        if (-not $createdPlanIds.Contains($matchedPlanId)) {
            $createdPlanIds.Add($matchedPlanId)
        }
    }
    return $out
}

# Sao lưu state ban đầu để khôi phục sau kiểm thử
$stateBackup = $null
$caseBackup = $null
if (Test-Path -LiteralPath $stateFile) { $stateBackup = Get-Content -LiteralPath $stateFile -Raw -Encoding UTF8 }
if (Test-Path -LiteralPath $caseFile)  { $caseBackup  = Get-Content -LiteralPath $caseFile -Raw -Encoding UTF8 }

try {
    # ======================================================================
    # LAYER 1: STATIC VALIDATION & SCHEMA CONFORMANCE
    # ======================================================================
    Write-Host "`n>>> LAYER 1: STATIC VALIDATION & SCHEMA CONFORMANCE" -ForegroundColor Cyan

    Assert-Test "File interview.ps1 tồn tại" (Test-Path -LiteralPath $interviewScript)
    Assert-Test "File 14-INTERVIEW-STATE-TEMPLATE.json tồn tại" (Test-Path -LiteralPath $templateFile)
    Assert-Test "File interview_state.json tồn tại" (Test-Path -LiteralPath $stateFile)
    Assert-Test "File context.ps1 tồn tại" (Test-Path -LiteralPath $contextScript)

    # 1.1 JSON Schema Validation & Enum Checks
    $tpl = Get-Content -LiteralPath $templateFile -Raw -Encoding UTF8 | ConvertFrom-Json
    $st  = Get-Content -LiteralPath $stateFile -Raw -Encoding UTF8 | ConvertFrom-Json

    $hasDraft7 = ($tpl.'$schema' -match "draft-07")
    Assert-Test "Template tuân thủ chuẩn JSON Schema Draft-07" $hasDraft7

    # DIFF-01: Goal status enums must include NEEDS_INPUT to match runtime state
    $goalEnum = $tpl.properties.goals.items.properties.status.enum
    $hasAllGoalEnums = ($goalEnum -contains "RESOLVED") -and ($goalEnum -contains "APPROVED") -and ($goalEnum -contains "DEFERRED") -and ($goalEnum -contains "BLOCKED") -and ($goalEnum -contains "NEEDS_INPUT")
    Assert-Test "DIFF-01: Goal status enums đầy đủ trạng thái đánh giá bao gồm NEEDS_INPUT" $hasAllGoalEnums

    $ansTypeEnum = $tpl.properties.answers.items.properties.answer_type.enum
    $hasSpontType = ($ansTypeEnum -contains "SPONTANEOUS_INFO")
    Assert-Test "Answer type enums bao gồm SPONTANEOUS_INFO" $hasSpontType

    $unkPrioEnum = $tpl.properties.unknowns.items.properties.priority.enum
    $unkStatusEnum = $tpl.properties.unknowns.items.properties.status.enum
    $hasUnkEnums = ($unkPrioEnum -contains "CRITICAL") -and ($unkPrioEnum -contains "HIGH") -and ($unkStatusEnum -contains "OPEN") -and ($unkStatusEnum -contains "DEFERRED")
    Assert-Test "Unknown schema có phân loại độ ưu tiên (CRITICAL, HIGH) và trạng thái (OPEN, RESOLVED, DEFERRED)" $hasUnkEnums

    # 1.2 UTF-8 No BOM Checks
    $bytes = [System.IO.File]::ReadAllBytes($stateFile)
    $hasBOM = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    Assert-Test "interview_state.json được ghi chuẩn UTF-8 No BOM" (-not $hasBOM)

    # 1.3 Phase 1 Schema Conformance Checks (MULTIPLE_CHOICE, topic_key, session limits)
    $qProps = $tpl.properties.questions.items.properties
    $sessProps = $tpl.properties.session.properties
    $hasTopicKey = ($null -ne $qProps.topic_key)
    $hasSessLimits = ($null -ne $sessProps.max_clarification_per_goal -and $null -ne $sessProps.max_total_questions)
    $ansTypeEnum = $tpl.properties.answers.items.properties.answer_type.enum
    $hasMultChoice = ($ansTypeEnum -contains "MULTIPLE_CHOICE" -and $ansTypeEnum -notcontains "MULTIPLE_CHOICES")
    Assert-Test "Phase 1: Template có topic_key, MULTIPLE_CHOICE enum và session limits (max_clarification_per_goal, max_total_questions)" ($hasTopicKey -and $hasSessLimits -and $hasMultChoice)

    # 1.4 Mobile Display Compatibility Matrix in Template
    $specTplContent = Get-Content -LiteralPath $specTemplate -Raw -Encoding UTF8
    $hasMatrixCols = $specTplContent -match '\|\s*Device class\s*\|\s*Aspect ratio\s*\|\s*Viewport \(dp\)\s*\|\s*Orientation\s*\|\s*Support status\s*\|\s*Verification\s*\|'
    $hasEvidenceModel = ($specTplContent -match "NOT_ASSESSED") -and ($specTplContent -match "IN_SCOPE") -and ($specTplContent -match "NOT_VERIFIED")
    Assert-Test "Spec Template có Mobile Display Compatibility Matrix chuẩn 6 cột với mô hình dựa trên bằng chứng" ($hasMatrixCols -and $hasEvidenceModel)

    # ======================================================================
    # LAYER 2: STATE & CLI INTEGRATION & EXIT GATE TESTS
    # ======================================================================
    Write-Host "`n>>> LAYER 2: STATE & CLI INTEGRATION & EXIT GATE TESTS" -ForegroundColor Cyan

    # 2.1 Destructive Init Prevention (DIFF-02)
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript init -CaseId "CASE-INITIAL" -Force | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-goal -GoalId "G-INIT-TEST" -Description "Goal to protect" | Out-Null
    
    $destructiveBlocked = $false
    try {
        $initErr = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript init 2>&1
        if ($initErr -match "DESTRUCTIVE_INIT_REFUSED") { $destructiveBlocked = $true }
    } catch {
        $destructiveBlocked = $true
    }
    Assert-Test "CLI init từ chối ghi đè session đang hoạt động khi không có -Force (DIFF-02)" $destructiveBlocked

    # 2.2 Force Init with Backup
    $forceInitOut = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript init -Force
    $backupCreated = ($forceInitOut -join "`n") -match "BACKUP"
    Assert-Test "CLI init -Force tạo bản sao lưu an toàn trước khi khởi tạo lại (DIFF-02)" $backupCreated

    # 2.3 Repetition Prevention & Warning Stream Detection (DIFF-03 / DIFF-06)
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-question -QuestionId "Q-REP-1" -Text "Hệ quản trị CSDL dự kiến là gì?" -Reason "Xác định storage engine" | Out-Null
    
    $repeatRejected = $false
    try {
        $repErr = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-question -QuestionId "Q-REP-2" -Text "Hệ quản trị CSDL dự kiến là gì?" -Reason "Hỏi lại mà không có cờ" 2>&1
        if ($repErr -match "REPETITION_REJECTED") { $repeatRejected = $true }
    } catch {
        $repeatRejected = $true
    }
    Assert-Test "CLI record-question chặn câu hỏi trùng lặp khi không có -AllowRepeat (DIFF-03)" $repeatRejected

    # DIFF-06: Fix warning stream detection for REPETITION_ALLOWED (capture 3>&1 or check question JSON state repetition.is_repeated -eq $true)
    $repAllowedOut = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-question -QuestionId "Q-REP-2" -Text "Hệ quản trị CSDL dự kiến là gì?" -Reason "Đánh giá lại sau khi kiểm toán phát hiện SQLite chưa mã hóa" -AllowRepeat 3>&1
    $stAfterRep = Get-StateWithRetry
    $qRepObj = @($stAfterRep.questions | Where-Object { $_.question_id -eq "Q-REP-2" })
    $repeatAllowedState = ($qRepObj.Count -ge 1 -and $qRepObj[0].repetition -and $qRepObj[0].repetition.is_repeated -eq $true)
    $repeatAllowedOutput = ($repAllowedOut -join "`n") -match "REPETITION_ALLOWED"
    Assert-Test "DIFF-06: CLI record-question cho phép hỏi lại khi có -AllowRepeat kèm stream 3>&1 hoặc kiểm tra state" ($repeatAllowedOutput -or $repeatAllowedState)

    # 2.4 Duplicate QuestionId Protection (DIFF-05)
    $dupIdRejected = $false
    try {
        $dupErr = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-question -QuestionId "Q-REP-1" -Text "Nội dung câu hỏi hoàn toàn khác nhưng bị trùng ID" -Reason "Cố tình ghi đè ID" 2>&1
        if ($dupErr -match "DUPLICATE_QUESTION_ID_REJECTED") { $dupIdRejected = $true }
    } catch {
        $dupIdRejected = $true
    }
    Assert-Test "DIFF-05: CLI record-question từ chối QuestionId trùng lặp với text khác khi không có -Force/-Supersede" $dupIdRejected

    # With -Supersede, QuestionId override is permitted
    $dupOverridden = $false
    try {
        $overrideOut = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-question -QuestionId "Q-REP-1" -Text "Nội dung câu hỏi sửa đổi đã được duyệt ghi đè" -Reason "Ghi đè hợp lệ có chủ đích" -Supersede 3>&1
        $stDup = Get-StateWithRetry
        $qDup = @($stDup.questions | Where-Object { $_.question_id -eq "Q-REP-1" })
        if ($qDup.Count -ge 1 -and $qDup[0].question_text -match "đã được duyệt ghi đè") {
            $dupOverridden = $true
        }
    } catch { }
    Assert-Test "DIFF-05: CLI record-question cho phép ghi đè QuestionId khi có cờ -Supersede" $dupOverridden

    # 2.5 Orphan Answer Prevention (DIFF-04)
    $orphanRejected = $false
    try {
        $orphErr = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-answer -AnswerId "ANS-ORPH-1" -QuestionId "Q-NONEXISTENT" -Answer "Câu trả lời mồ côi" 2>&1
        if ($orphErr -match "ORPHAN_ANSWER_REJECTED") { $orphanRejected = $true }
    } catch {
        $orphanRejected = $true
    }
    Assert-Test "CLI record-answer từ chối câu trả lời mồ côi không có câu hỏi tương ứng (DIFF-04)" $orphanRejected

    $spontOut = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-answer -AnswerId "ANS-SPONT-1" -Answer "Người dùng chủ động báo cần hỗ trợ đăng nhập sinh trắc học" -Spontaneous
    $spontAccepted = ($spontOut -join "`n") -match "USER_SPONTANEOUS"
    Assert-Test "CLI record-answer cho phép ghi nhận thông tin tự phát với cờ -Spontaneous (DIFF-04)" $spontAccepted

    # 2.6 Record Unknown Action
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-unknown -UnknownId "UNK-TEST-01" -Description "Tài liệu API chưa hoàn thiện" -Priority "HIGH" -Status "OPEN" | Out-Null
    $stUnk = Get-StateWithRetry
    $unkStored = ($stUnk.unknowns.Count -ge 1 -and $stUnk.unknowns[0].unknown_id -eq "UNK-TEST-01" -and $stUnk.unknowns[0].priority -eq "HIGH")
    Assert-Test "CLI record-unknown lưu trữ thành công điểm mù với độ ưu tiên và trạng thái" $unkStored

    # 2.7 Referential Integrity Validation
    $valOut = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript validate
    $valPassed = ($valOut -join "`n") -match "PASS"
    Assert-Test "CLI validate kiểm tra thành công tính toàn vẹn tham chiếu" $valPassed

    # ----------------------------------------------------------------------
    # EXIT GATE REGRESSION TESTS (DIFF-01 TESTS 01 - 06 + DIFF-02 + DIFF-04)
    # ----------------------------------------------------------------------
    Write-Host "`n>>> EXIT GATE REGRESSION TESTS (DIFF-01 TESTS 01 - 06 + DIFF-02 + DIFF-04)" -ForegroundColor Cyan

    # TEST 01: Goal without Decision & without Questions must NOT pass (NEEDS_INPUT)
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript init -Force | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-goal -GoalId "G-REG-01" -Description "Mục tiêu chưa có quyết định xử lý" | Out-Null
    $evalT1 = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript evaluate-sufficiency 2>&1
    $stT1 = Get-StateWithRetry
    $gT1Obj = @($stT1.goals | Where-Object { $_.goal_id -eq "G-REG-01" })
    $gT1Eval = @($stT1.sufficiency_evaluation.goal_evaluations | Where-Object { $_.goal_id -eq "G-REG-01" })
    $gT1StatusActive = ($gT1Obj.Count -ge 1 -and ($gT1Obj[0].status -eq "ACTIVE" -or $gT1Obj[0].status -eq "PROPOSED"))
    $gT1EvalNeedsInput = ($gT1Eval.Count -ge 1 -and $gT1Eval[0].status -eq "NEEDS_INPUT")
    Assert-Test "Test 01: Goal không có Decision đưa verdict về NEEDS_INPUT, giữ status mục tiêu là ACTIVE và gán goal_evaluations status là NEEDS_INPUT" ($stT1.sufficiency_evaluation.verdict -eq "NEEDS_INPUT" -and $gT1StatusActive -and $gT1EvalNeedsInput)

    # TEST 02: PROPOSED Decision must not count as approved
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-decision -DecisionId "DEC-REG-01" -Description "G-REG-01: Giải pháp đề xuất" -SelectedOption "Option A" -ApprovalStatus "PROPOSED" -RelatedRequirements "G-REG-01" | Out-Null
    $evalT2 = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript evaluate-sufficiency 2>&1
    $stT2 = Get-StateWithRetry
    Assert-Test "Test 02: Quyết định ở trạng thái PROPOSED không được coi là đã duyệt (NEEDS_INPUT)" ($stT2.sufficiency_evaluation.verdict -eq "NEEDS_INPUT")

    # TEST 03: Important unresolved Unknown must prevent completion (BLOCKED)
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-decision -DecisionId "DEC-REG-01" -Description "G-REG-01: Đã duyệt" -SelectedOption "Option A" -ApprovalStatus "APPROVED" -RelatedRequirements "G-REG-01" | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-unknown -UnknownId "UNK-CRIT-01" -Description "Chưa rõ cơ chế ký số APK" -Priority "CRITICAL" -Status "OPEN" | Out-Null
    $evalT3 = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript evaluate-sufficiency 2>&1
    $stT3 = Get-StateWithRetry
    Assert-Test "Test 03: Điểm mù quan trọng (CRITICAL/HIGH) OPEN ngăn chặn hoàn tất (BLOCKED)" ($stT3.sufficiency_evaluation.verdict -eq "BLOCKED")

    # DIFF-02 REGRESSION: Unapproved DEFERRED CRITICAL unknown blocks Exit Gate
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-unknown -UnknownId "UNK-CRIT-01" -Description "Chưa rõ cơ chế ký số APK" -Priority "CRITICAL" -Status "DEFERRED" | Out-Null
    $evalT3b = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript evaluate-sufficiency 2>&1
    $stT3b = Get-StateWithRetry
    $hasCritBlocker = ($stT3b.sufficiency_evaluation.blocking_reasons -match "Deferred critical unknown requires").Length -gt 0
    Assert-Test "DIFF-02: Điểm mù CRITICAL chuyển sang DEFERRED nhưng chưa có justification và approval vẫn bị CHẶN (BLOCKED)" ($stT3b.sufficiency_evaluation.verdict -eq "BLOCKED" -and $hasCritBlocker)

    # DIFF-02 REGRESSION (Approved deferral): Now provide explicit justification and approval
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-unknown -UnknownId "UNK-CRIT-01" -Description "Chưa rõ cơ chế ký số APK" -Priority "CRITICAL" -Status "DEFERRED" -Justification "Được phép hoãn vì sử dụng debug keystore trong giai đoạn dev" -Approval "APPROVED" | Out-Null
    $evalT3c = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript evaluate-sufficiency 2>&1
    $stT3c = Get-StateWithRetry
    $hasDeferredUnk = ($stT3c.sufficiency_evaluation.deferred_decisions -match "DEFERRED CRITICAL UNKNOWN UNK-CRIT-01").Length -gt 0
    Assert-Test "DIFF-02: Điểm mù CRITICAL DEFERRED có đầy đủ giải trình và phê duyệt vượt qua Exit Gate (SUFFICIENT)" ($stT3c.sufficiency_evaluation.verdict -eq "SUFFICIENT" -and $hasDeferredUnk)

    # TEST 04: Properly deferred non-critical decision must not unnecessarily block completion
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript init -Force | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-goal -GoalId "G-CORE" -Description "Tính năng chính" | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-decision -DecisionId "DEC-CORE" -Description "G-CORE: Triển khai Room DB" -SelectedOption "Room" -ApprovalStatus "APPROVED" -RelatedRequirements "G-CORE" | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-goal -GoalId "G-NICE" -Description "Tính năng mở rộng" | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-decision -DecisionId "DEC-NICE" -Description "G-NICE: Chủ đề tối nâng cao" -SelectedOption "Hoãn sang v1.2" -ApprovalStatus "DEFERRED" -RelatedRequirements "G-NICE" | Out-Null
    $evalT4 = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript evaluate-sufficiency 2>&1
    $stT4 = Get-StateWithRetry
    $hasDeferred = $stT4.sufficiency_evaluation.deferred_decisions.Count -ge 1
    Assert-Test "Test 04: Quyết định hoãn hợp lệ có lý do giải trình không chặn Exit Gate (SUFFICIENT)" ($stT4.sufficiency_evaluation.verdict -eq "SUFFICIENT" -and $hasDeferred)

    # DIFF-04 REGRESSION: Goal resolved by Approved Assumption passes without false blocker
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript init -Force | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-goal -GoalId "G-ASSUMP-01" -Description "Bảo mật lưu trữ access token người dùng" | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-assumption -AssumptionId "ASM-DATASTORE" -Description "G-ASSUMP-01: Sử dụng Jetpack DataStore mã hóa qua Google Tink Aead" -Rationale "Khuyến nghị bảo mật chính thức của Android" -RiskLevel "BENIGN" -ApprovalStatus "APPROVED" -DownstreamDeps "G-ASSUMP-01" | Out-Null
    $evalDiff04 = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript evaluate-sufficiency 2>&1
    $stDiff04 = Get-StateWithRetry
    $gDiff04 = @($stDiff04.sufficiency_evaluation.goal_evaluations | Where-Object { $_.goal_id -eq "G-ASSUMP-01" })
    $noFalseBlocker = ($stDiff04.sufficiency_evaluation.blocking_reasons -match "Goal G-ASSUMP-01 has no resolving decision recorded").Length -eq 0
    Assert-Test "DIFF-04: Approved Assumption giải quyết Goal vượt qua Exit Gate mà không bị báo lỗi chặn giả" ($stDiff04.sufficiency_evaluation.verdict -eq "SUFFICIENT" -and $gDiff04.Count -ge 1 -and $gDiff04[0].status -eq "ASSUMED_WITH_APPROVAL" -and $noFalseBlocker)

    # TEST 05: Conflicting decisions must prevent silent completion (BLOCKED)
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-conflict -ConflictId "CONF-T5" -Explanation "Xung đột giữa yêu cầu bảo mật cao và lưu mật khẩu văn bản rõ" -Severity "CRITICAL" | Out-Null
    $evalT5 = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript evaluate-sufficiency 2>&1
    $stT5 = Get-StateWithRetry
    Assert-Test "Test 05: Mâu thuẫn CRITICAL chưa giải quyết đưa verdict về BLOCKED" ($stT5.sufficiency_evaluation.verdict -eq "BLOCKED")

    # TEST 06: Fully resolved Goal can legitimately pass
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript resolve-conflict -ConflictId "CONF-T5" -ResolutionStrategy "Sử dụng Android KeyStore Cipher" | Out-Null
    $evalT6 = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript evaluate-sufficiency 2>&1
    $stT6 = Get-StateWithRetry
    Assert-Test "Test 06: Toàn bộ mục tiêu có quyết định APPROVED và conflict RESOLVED vượt qua Exit Gate (SUFFICIENT)" ($stT6.sufficiency_evaluation.verdict -eq "SUFFICIENT")
    Assert-Test "Test 06: Toàn bộ mục tiêu có quyết định APPROVED và conflict RESOLVED vượt qua Exit Gate (SUFFICIENT)" ($stT6.sufficiency_evaluation.verdict -eq "SUFFICIENT")

    # ----------------------------------------------------------------------
    # PHASE 1 REGRESSION TESTS: STATE PRESERVATION, AMBIGUITY, TOPIC KEY & LIMITS
    # ----------------------------------------------------------------------
    Write-Host "`n>>> PHASE 1 REGRESSION TESTS: STATE PRESERVATION, AMBIGUITY, TOPIC KEY & LIMITS" -ForegroundColor Cyan

    # P1-01: evaluate-sufficiency keeping goal.status ACTIVE/PROPOSED and reporting verdict NEEDS_INPUT
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript init -Force | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-goal -GoalId "G-ACTIVE-01" -Description "Goal dang ACTIVE" | Out-Null
    $stP1a = Get-StateWithRetry
    $newPropGoal = [PSCustomObject]@{
        goal_id = "G-PROP-01"
        description = "Goal dang PROPOSED"
        category = "GENERAL"
        priority = "P1_HIGH"
        status = "PROPOSED"
        related_requirements = @()
    }
    $stP1a.goals = @($stP1a.goals) + $newPropGoal
    Save-Utf8NoBom $stateFile ($stP1a | ConvertTo-Json -Depth 10)
    
    $evalP1a = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript evaluate-sufficiency 2>&1
    $stP1aAfter = Get-StateWithRetry
    $gActiveObj = @($stP1aAfter.goals | Where-Object { $_.goal_id -eq "G-ACTIVE-01" })[0]
    $gPropObj = @($stP1aAfter.goals | Where-Object { $_.goal_id -eq "G-PROP-01" })[0]
    $gActiveEval = @($stP1aAfter.sufficiency_evaluation.goal_evaluations | Where-Object { $_.goal_id -eq "G-ACTIVE-01" })[0]
    $gPropEval = @($stP1aAfter.sufficiency_evaluation.goal_evaluations | Where-Object { $_.goal_id -eq "G-PROP-01" })[0]

    $p1StatusPreserved = ($gActiveObj.status -eq "ACTIVE" -and $gPropObj.status -eq "PROPOSED" -and
                          $gActiveEval.status -eq "NEEDS_INPUT" -and $gPropEval.status -eq "NEEDS_INPUT" -and
                          $stP1aAfter.sufficiency_evaluation.verdict -eq "NEEDS_INPUT")
    Assert-Test "Phase 1: evaluate-sufficiency giữ nguyên status ACTIVE/PROPOSED của goal trong state và báo cáo verdict NEEDS_INPUT" $p1StatusPreserved

    # P1-02: Goal covered by approved assumption passing without false decision blocker
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript init -Force | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-goal -GoalId "G-ASM-COVERED" -Description "Bảo vệ thông tin định danh" | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-assumption -AssumptionId "ASM-COV-01" -Description "G-ASM-COVERED: Tự động mã hóa AES-GCM" -Rationale "Khuyến nghị chuẩn bảo mật" -RiskLevel "BENIGN" -ApprovalStatus "APPROVED" -DownstreamDeps "G-ASM-COVERED" | Out-Null
    $evalP1b = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript evaluate-sufficiency 2>&1
    $stP1b = Get-StateWithRetry
    $gP1b = @($stP1b.sufficiency_evaluation.goal_evaluations | Where-Object { $_.goal_id -eq "G-ASM-COVERED" })[0]
    $noFalseBlockerP1 = ($stP1b.sufficiency_evaluation.blocking_reasons -match "Goal G-ASM-COVERED has no resolving decision recorded").Length -eq 0
    Assert-Test "Phase 1: Goal được giải quyết bởi Approved Assumption đạt SUFFICIENT và không có lỗi chặn giả decision" ($stP1b.sufficiency_evaluation.verdict -eq "SUFFICIENT" -and $gP1b.status -eq "ASSUMED_WITH_APPROVAL" -and $noFalseBlockerP1)

    # P1-03: AMBIGUOUS answer keeping question status uncompleted (NEEDS_CLARIFICATION) and blocking Exit Gate (NEEDS_INPUT)
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript init -Force | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-goal -GoalId "G-AMB-TEST" -Description "Tối ưu hóa bộ nhớ" | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-question -QuestionId "Q-AMB-01" -Text "Mục tiêu dung lượng RAM tối đa là bao nhiêu MB?" -Reason "Xác định giới hạn bộ nhớ" -GoalIds "G-AMB-TEST" | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-answer -AnswerId "ANS-AMB-01" -QuestionId "Q-AMB-01" -Answer "Càng nhẹ càng tốt, tầm vài chục hoặc vài trăm MB gì đó" -Type "AMBIGUOUS" | Out-Null
    $stP1c = Get-StateWithRetry
    $qAmbObj = @($stP1c.questions | Where-Object { $_.question_id -eq "Q-AMB-01" })[0]
    $evalP1c = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript evaluate-sufficiency 2>&1
    $stP1cAfter = Get-StateWithRetry
    $ambUncompleted = ($qAmbObj.status -eq "NEEDS_CLARIFICATION" -and $stP1cAfter.sufficiency_evaluation.verdict -eq "NEEDS_INPUT")
    Assert-Test "Phase 1: AMBIGUOUS answer giữ question status là NEEDS_CLARIFICATION và đưa verdict về NEEDS_INPUT" $ambUncompleted

    # P1-04: CONFLICTING answer keeping question status uncompleted and blocking Exit Gate (BLOCKED)
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-question -QuestionId "Q-CONF-01" -Text "Có cho phép lưu mật khẩu người dùng dạng cleartext không?" -Reason "Kiểm tra chính sách bảo mật" -GoalIds "G-AMB-TEST" | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-answer -AnswerId "ANS-CONF-01" -QuestionId "Q-CONF-01" -Answer "Cần lưu cleartext để debug nhưng yêu cầu phải đạt chuẩn PCI-DSS không lưu cleartext" -Type "CONFLICTING" | Out-Null
    $stP1d = Get-StateWithRetry
    $qConfObj = @($stP1d.questions | Where-Object { $_.question_id -eq "Q-CONF-01" })[0]
    $evalP1d = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript evaluate-sufficiency 2>&1
    $stP1dAfter = Get-StateWithRetry
    $confBlocked = ($qConfObj.status -eq "NEEDS_CLARIFICATION" -and $stP1dAfter.sufficiency_evaluation.verdict -eq "BLOCKED")
    Assert-Test "Phase 1: CONFLICTING answer giữ question status là NEEDS_CLARIFICATION và chặn Exit Gate với verdict BLOCKED" $confBlocked

    # P1-05: -TopicKey duplicate prevention
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript init -Force | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-question -QuestionId "Q-TOPIC-1" -Text "Hệ quản trị CSDL dự kiến dùng là gì?" -Reason "Xác định storage engine" -Domain "DATABASE" -TopicKey "db_engine" | Out-Null
    
    $topicDupBlocked = $false
    try {
        $topicDupErr = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-question -QuestionId "Q-TOPIC-2" -Text "Bạn muốn dùng SQLite hay Room DB?" -Reason "Hỏi lại cùng topic trong cùng domain" -Domain "DATABASE" -TopicKey "db_engine" 2>&1
        if ($topicDupErr -match "DUPLICATE_TOPIC_KEY_REJECTED") { $topicDupBlocked = $true }
    } catch {
        $topicDupBlocked = $true
    }
    Assert-Test "Phase 1: -TopicKey ngăn chặn câu hỏi trùng lặp topic trong cùng domain khi không có cờ -Supersede" $topicDupBlocked

    # P1-06: -TopicKey cho phép ghi đè khi có -Supersede
    $topicSuperseded = $false
    try {
        & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-question -QuestionId "Q-TOPIC-2" -Text "Bạn muốn dùng SQLite hay Room DB?" -Reason "Ghi đè topic có chủ đích" -Domain "DATABASE" -TopicKey "db_engine" -Supersede | Out-Null
        $stTopic = Get-StateWithRetry
        $qTopic = @($stTopic.questions | Where-Object { $_.question_id -eq "Q-TOPIC-2" })
        if ($qTopic.Count -ge 1 -and $qTopic[0].topic_key -eq "db_engine") { $topicSuperseded = $true }
    } catch {}
    Assert-Test "Phase 1: -TopicKey cho phép ghi đè topic khi có cờ -Supersede" $topicSuperseded

    # P1-07: max_clarification_per_goal limit (limit = 2 questions per goal)
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript init -Force | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-goal -GoalId "G-LIMIT-CLAR" -Description "Tích hợp cổng thanh toán MoMo" | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-question -QuestionId "Q-CLAR-1" -Text "Môi trường MoMo là sandbox hay production?" -Reason "Xác định endpoint" -GoalIds "G-LIMIT-CLAR" | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-question -QuestionId "Q-CLAR-2" -Text "Phương thức thanh toán MoMo là QR hay App-to-App?" -Reason "Xác định SDK flow" -GoalIds "G-LIMIT-CLAR" | Out-Null

    $clarLimitExceeded = $false
    try {
        $clarErr = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-question -QuestionId "Q-CLAR-3" -Text "Có cần lưu lịch sử giao dịch MoMo vào Room không?" -Reason "Câu hỏi vượt quá giới hạn làm rõ" -GoalIds "G-LIMIT-CLAR" 2>&1
        if ($clarErr -match "GOAL_CLARIFICATION_LIMIT_EXCEEDED") { $clarLimitExceeded = $true }
    } catch {
        $clarLimitExceeded = $true
    }
    Assert-Test "Phase 1: max_clarification_per_goal từ chối câu hỏi thứ 3 vượt hạn mức làm rõ của Goal khi không có -Force" $clarLimitExceeded

    # P1-08: max_total_questions limit (tested with reduced session limit)
    $stTotalQ = Get-StateWithRetry
    $stTotalQ.session.max_total_questions = 2
    Save-Utf8NoBom $stateFile ($stTotalQ | ConvertTo-Json -Depth 10)

    $totalQLimitExceeded = $false
    try {
        $totalQErr = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-question -QuestionId "Q-TOTAL-OVER" -Text "Câu hỏi vượt tổng hạn mức session?" -Reason "Kiểm tra max_total_questions" 2>&1
        if ($totalQErr -match "SESSION_LIMIT_EXCEEDED") { $totalQLimitExceeded = $true }
    } catch {
        $totalQLimitExceeded = $true
    }
    Assert-Test "Phase 1: max_total_questions từ chối ghi nhận thêm câu hỏi khi đạt trần tổng số câu hỏi session" $totalQLimitExceeded

    # ======================================================================
    # LAYER 3: ADAPTIVE BEHAVIOR SCENARIOS (A THROUGH J) - REAL CLI & STATE
    # ======================================================================
    Write-Host "`n>>> LAYER 3: REALISTIC ADAPTIVE BEHAVIOR SCENARIOS (A THROUGH J)" -ForegroundColor Cyan

    # Scenario A: Bug fix / Minimal scope (RCA & STR, no bloated questions)
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript init -Force | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-goal -GoalId "G-BUG-A" -Description "Sửa lỗi crash NullPointerException khi mở màn hình chi tiết" -Domain "APPLICATION_DIAGNOSIS" -Priority "P0_CRITICAL" | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-question -QuestionId "Q-BUG-STR" -Text "Các bước tái hiện lỗi (STR) và điều kiện mạng khi xảy ra crash là gì?" -Reason "Thu thập Steps to Reproduce để khoanh vùng Root Cause" -Domain "APPLICATION_DIAGNOSIS" -GoalIds "G-BUG-A" | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-answer -AnswerId "ANS-BUG-STR" -QuestionId "Q-BUG-STR" -Answer "Bấm nút Xem chi tiết khi thiết bị mất kết nối mạng thì ứng dụng văng ngay lập tức" -Type "CLEAR" | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-decision -DecisionId "DEC-BUG-FIX" -Description "Bổ sung kiểm tra null an toàn và khối fallback hiển thị offline banner" -SelectedOption "Safe null check & Offline UI" -ApprovalStatus "APPROVED" -RelatedRequirements "G-BUG-A" | Out-Null
    $evalScenA = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript evaluate-sufficiency
    $stScenA = Get-StateWithRetry $stateFile
    $scenAPass = ($stScenA.sufficiency_evaluation.verdict -eq "SUFFICIENT" -and $stScenA.questions.Count -eq 1 -and $stScenA.questions[0].status -eq "ANSWERED")
    Assert-Test "Scenario A: Bug fix xử lý tinh gọn qua CLI với đúng 1 câu hỏi RCA/STR và đạt SUFFICIENT" $scenAPass

    # Scenario B: Binary obfuscated / Evidence-based assumptions
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript init -Force | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-goal -GoalId "G-OBF-B" -Description "Khôi phục API Client từ APK bị obfuscate ProGuard" | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-assumption -AssumptionId "ASM-OBF-NET" -Description "G-OBF-B: Sử dụng OkHttp với TLS 1.3 dựa trên string dump network traffic" -Rationale "Mã nguồn lớp model bị obfuscate, suy luận từ evidence chuỗi URL" -RiskLevel "BENIGN" -ApprovalStatus "APPROVED" -DownstreamDeps "G-OBF-B" -VerificationTask "Kiểm chứng logcat khi gửi request thực tế" | Out-Null
    $evalScenB = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript evaluate-sufficiency
    $stScenB = Get-StateWithRetry $stateFile
    $scenBPass = ($stScenB.sufficiency_evaluation.verdict -eq "SUFFICIENT" -and $stScenB.assumptions.Count -ge 1 -and $stScenB.assumptions[0].verification_task -ne "")
    Assert-Test "Scenario B: APK obfuscate thiết lập giả định kỹ thuật dựa trên bằng chứng có nhiệm vụ kiểm chứng" $scenBPass

    # Scenario C: Delegated choice ("Anh chọn giúp" -> Safe default assumption)
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript init -Force | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-goal -GoalId "G-STORE-C" -Description "Thiết lập cơ sở dữ liệu cục bộ" | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-question -QuestionId "Q-DB-SELECT" -Text "Bạn muốn dùng Room DB hay raw SQLite?" -Reason "Xác định storage engine" -GoalIds "G-STORE-C" | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-answer -AnswerId "ANS-DB-DELEGATE" -QuestionId "Q-DB-SELECT" -Answer "Anh chọn giúp em kiến trúc an toàn và chuẩn nhất" -Type "DELEGATED_CHOICE" | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-assumption -AssumptionId "ASM-SAFE-DEFAULT" -Description "G-STORE-C: Sử dụng Room DB với SQLiteCipher theo Safe Default" -Rationale "Người dùng ủy quyền lựa chọn kỹ thuật; Room DB là chuẩn chính thức của Android" -RiskLevel "BENIGN" -ApprovalStatus "APPROVED" -DownstreamDeps "G-STORE-C" | Out-Null
    $evalScenC = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript evaluate-sufficiency
    $stScenC = Get-StateWithRetry $stateFile
    $scenCPass = ($stScenC.sufficiency_evaluation.verdict -eq "SUFFICIENT" -and $stScenC.answers[0].answer_type -eq "DELEGATED_CHOICE")
    Assert-Test "Scenario C: Xử lý lựa chọn ủy quyền (Delegated Choice) tự áp dụng Safe Default Assumption đạt SUFFICIENT" $scenCPass

    # Scenario D: Feature addition / Scope boundaries & dependencies
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript init -Force | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-goal -GoalId "G-FEAT-QR" -Description "Tích hợp tính năng thanh toán QR code" -Domain "FEATURE_DISCOVERY" -Priority "P1_HIGH" | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-question -QuestionId "Q-FEAT-SCOPE" -Text "Tính năng thanh toán QR có tích hợp cổng thanh toán ngoài (VNPay/Momo) hay quét mã nội bộ?" -Reason "Xác định ranh giới phạm vi (Scope Boundary) và phụ thuộc SDK" -Domain "FEATURE_DISCOVERY" -GoalIds "G-FEAT-QR" | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-answer -AnswerId "ANS-FEAT-SCOPE" -QuestionId "Q-FEAT-SCOPE" -Answer "Chỉ quét mã QR nội bộ chuẩn VietQR, không dùng SDK bên thứ ba" -Type "CLEAR" | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-decision -DecisionId "DEC-FEAT-SCOPE" -Description "Triển khai camera quét ZXing nội bộ chuẩn VietQR, loại trừ phụ thuộc SDK ngoài (Non-Goal)" -SelectedOption "VietQR ZXing Embedded" -ApprovalStatus "APPROVED" -RelatedRequirements "G-FEAT-QR" | Out-Null
    $evalScenD = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript evaluate-sufficiency
    $stScenD = Get-StateWithRetry $stateFile
    $scenDPass = ($stScenD.sufficiency_evaluation.verdict -eq "SUFFICIENT" -and $stScenD.decisions[0].approval_status -eq "APPROVED")
    Assert-Test "Scenario D: Thêm tính năng mới xác lập rõ ranh giới phạm vi và khóa quyết định thành công" $scenDPass

    # Scenario E: Contradiction resolution protocol
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript init -Force | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-goal -GoalId "G-SYNC-E" -Description "Đồng bộ hóa dữ liệu người dùng" | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-conflict -ConflictId "CONF-SYNC-01" -ConflictingItems "Yêu cầu offline 100%, Yêu cầu real-time cloud sync" -Explanation "Không thể đồng bộ thời gian thực khi ứng dụng bắt buộc hoạt động hoàn toàn ngoại tuyến" -Severity "CRITICAL" | Out-Null
    $evalScenE1 = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript evaluate-sufficiency
    $stScenE1 = Get-StateWithRetry $stateFile
    $blockedOnInit = ($stScenE1.sufficiency_evaluation.verdict -eq "BLOCKED")
    
    # Resolve the conflict
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript resolve-conflict -ConflictId "CONF-SYNC-01" -ResolutionStrategy "Kiến trúc Offline-First: Lưu trữ Room cục bộ và đồng bộ nền WorkManager khi có mạng" | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-decision -DecisionId "DEC-SYNC-RES" -Description "Áp dụng kiến trúc Offline-First giải quyết CONF-SYNC-01" -SelectedOption "Offline-First + WorkManager" -ApprovalStatus "APPROVED" -RelatedRequirements "G-SYNC-E" | Out-Null
    $evalScenE2 = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript evaluate-sufficiency
    $stScenE2 = Get-StateWithRetry $stateFile
    $resolvedPass = ($stScenE2.sufficiency_evaluation.verdict -eq "SUFFICIENT" -and $stScenE2.conflicts[0].resolution_status -eq "RESOLVED")
    Assert-Test "Scenario E: Quy trình xử lý mâu thuẫn (Contradiction Resolution) chặn khi xung đột và mở khi giải quyết xong" ($blockedOnInit -and $resolvedPass)

    # Scenario F: Ambiguous response clarification & 3 design modes
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript init -Force | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-goal -GoalId "G-UI-MODE" -Description "Xác định phong cách giao diện và luồng người dùng" | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-question -QuestionId "Q-UI-STYLE" -Text "Bạn muốn thiết kế giao diện theo phong cách nào?" -Reason "Phân định 1 trong 3 Design Modes" -GoalIds "G-UI-MODE" | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-answer -AnswerId "ANS-UI-AMBIG" -QuestionId "Q-UI-STYLE" -Answer "Làm giao diện nhìn hiện đại và giống bản gốc nhưng đẹp hơn một chút" -Type "AMBIGUOUS" | Out-Null
    # Clarified into DESIGN_REUSE_EXACT with Sanitary Ergonomic Lint
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-decision -DecisionId "DEC-UI-MODE" -Description "Chọn chế độ DESIGN_REUSE_EXACT kèm Sanitary Ergonomic Lint (touch target 48dp)" -SelectedOption "DESIGN_REUSE_EXACT" -ApprovalStatus "APPROVED" -RelatedRequirements "G-UI-MODE" | Out-Null
    $evalScenF = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript evaluate-sufficiency
    $stScenF = Get-StateWithRetry $stateFile
    $scenFPass = ($stScenF.sufficiency_evaluation.verdict -eq "SUFFICIENT" -and $stScenF.answers[0].answer_type -eq "AMBIGUOUS" -and $stScenF.decisions[0].selected_option -eq "DESIGN_REUSE_EXACT")
    Assert-Test "Scenario F: Phản hồi mơ hồ kích hoạt điều tiết chế độ DESIGN_REUSE_EXACT và đạt SUFFICIENT" $scenFPass

    # Scenario G: Scope reduction mid-interview
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript init -Force | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-decision -DecisionId "DEC-INDEP" -Description "Kiến trúc module cơ bản" -SelectedOption "MVI Architecture" -ApprovalStatus "APPROVED" | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-scope-change -ChangeId "SC-TEST" -PreviousScope "Bao gồm module Video Player" -NewScope "Bỏ module Video Player" | Out-Null
    $stSG = Get-StateWithRetry $stateFile
    $indepKept = ($stSG.decisions | Where-Object { $_.decision_id -eq "DEC-INDEP" }).selected_option -eq "MVI Architecture"
    Assert-Test "Scenario G: Scope Change ghi nhận thay đổi phạm vi mà không làm mất quyết định độc lập" ($stSG.scope_changes.Count -ge 1 -and $indepKept)

    # Scenario H: Source repository available (Gate 02 cleared states allow Gate 03)
    $gateValOut = & powershell -NoProfile -ExecutionPolicy Bypass -File $gateScript validate 2>&1
    $gateValExitCode = $LASTEXITCODE
    $gateContent = Get-Content -LiteralPath $gateScript -Raw -Encoding UTF8
    $clearedStatesMatch = ($gateContent -match '\$clearedStates\s*=') -and ($gateContent -match '"SKIPPED"') -and ($gateContent -match '"WAIVED"')
    Assert-Test "Scenario H: Gate Engine thực thi lệnh validate thành công (Exit 0) và hỗ trợ SKIPPED/WAIVED cho Gate 02" ($gateValExitCode -eq 0 -and $clearedStatesMatch)

    # Scenario I: Performance-critical app (Quantitative metrics & 5-tier classification)
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript init -Force | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-goal -GoalId "G-PERF-I" -Description "Tối ưu hóa giật lag và tốc độ khởi động" | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-unknown -UnknownId "UNK-PERF-BASE" -Description "Chưa có chỉ số đo lường FPS baseline thực tế trên thiết bị vật lý" -Priority "HIGH" -Status "OPEN" | Out-Null
    $evalScenI1 = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript evaluate-sufficiency
    $stScenI1 = Get-StateWithRetry $stateFile
    $blockedOnPerfUnk = ($stScenI1.sufficiency_evaluation.verdict -eq "BLOCKED")

    # Resolve baseline unknown and record quantitative decision
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-unknown -UnknownId "UNK-PERF-BASE" -Description "Đã thu thập baseline đo lường thực tế" -Priority "HIGH" -Status "RESOLVED" | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-assumption -AssumptionId "ASM-PERF-TARGET" -Description "G-PERF-I: Thiết lập mục tiêu Cold Start < 1.2s và 60 FPS theo REFERENCE_BENCHMARK của Android Vitals" -Rationale "Áp dụng benchmark ngành của Google Play" -RiskLevel "BENIGN" -ApprovalStatus "APPROVED" -DownstreamDeps "G-PERF-I" | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-decision -DecisionId "DEC-PERF-OPT" -Description "Triển khai Baseline Profiles và nạp trước Dex để đạt chỉ tiêu Cold Start" -SelectedOption "Baseline Profiles + Dex Pre-load" -ApprovalStatus "APPROVED" -RelatedRequirements "G-PERF-I" | Out-Null
    $evalScenI2 = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript evaluate-sufficiency
    $stScenI2 = Get-StateWithRetry $stateFile
    $scenIPass = ($blockedOnPerfUnk -and $stScenI2.sufficiency_evaluation.verdict -eq "SUFFICIENT")
    Assert-Test "Scenario I: Ứng dụng tối ưu hiệu năng quản lý điểm mù chỉ số và đạt SUFFICIENT sau khi chốt giải pháp" $scenIPass

    # Scenario J: Multiple competing goals & MoSCoW trade-offs
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript init -Force | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-goal -GoalId "G-MUST" -Description "Xác thực sinh trắc học vân tay" -Priority "P0_CRITICAL" | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-goal -GoalId "G-COULD" -Description "Hiệu ứng hoạt họa chuyển cảnh 3D" -Priority "P3_LOW" | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-decision -DecisionId "DEC-MUST" -Description "Triển khai BiometricPrompt CryptoObject" -SelectedOption "BiometricPrompt" -ApprovalStatus "APPROVED" -RelatedRequirements "G-MUST" | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-decision -DecisionId "DEC-COULD" -Description "Hoãn hiệu ứng chuyển cảnh 3D sang v2 để ưu tiên bảo mật và hiệu năng" -SelectedOption "Hoãn sang v2" -ApprovalStatus "DEFERRED" -RelatedRequirements "G-COULD" | Out-Null
    $evalScenJ = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript evaluate-sufficiency
    $stScenJ = Get-StateWithRetry $stateFile
    $scenJPass = ($stScenJ.sufficiency_evaluation.verdict -eq "SUFFICIENT" -and $stScenJ.sufficiency_evaluation.deferred_decisions.Count -ge 1)
    Assert-Test "Scenario J: Phân định mức độ ưu tiên theo MoSCoW chấp nhận quyết định hoãn và đạt SUFFICIENT" $scenJPass

    # ----------------------------------------------------------------------
    # DIFF-08 REGRESSION TESTS: VIETNAMESE INTENT ROUTING (DESIGN VS OPTIMIZATION)
    # ----------------------------------------------------------------------
    Write-Host "`n>>> DIFF-08 REGRESSION TESTS: VIETNAMESE INTENT ROUTING" -ForegroundColor Cyan

    # Test 1: "tối ưu giao diện" must route to "design" profile
    $planUiOut = Invoke-ContextPlanSafe "tối ưu giao diện và bố cục nút bấm"
    $uiProfileResolved = ($planUiOut -join "`n") -match "Profile\s*:\s*design"
    Assert-Test "DIFF-08: 'tối ưu giao diện' định tuyến chính xác về profile 'design'" $uiProfileResolved

    # Test 2: "tối ưu ram" must route to "optimization" profile
    $planRamOut = Invoke-ContextPlanSafe "tối ưu ram và giảm rò rỉ bộ nhớ"
    $ramProfileResolved = ($planRamOut -join "`n") -match "Profile\s*:\s*optimization"
    Assert-Test "DIFF-08: 'tối ưu ram' định tuyến chính xác về profile 'optimization'" $ramProfileResolved

    # Test 3: "tối ưu hiệu năng" must route to "optimization" profile
    $planPerfOut = Invoke-ContextPlanSafe "tối ưu hiệu năng và fps"
    $perfProfileResolved = ($planPerfOut -join "`n") -match "Profile\s*:\s*optimization"
    Assert-Test "DIFF-08: 'tối ưu hiệu năng' định tuyến chính xác về profile 'optimization'" $perfProfileResolved

} finally {
    # Khôi phục trạng thái chuẩn sạch ban đầu
    if ($stateBackup) {
        Save-Utf8NoBom $stateFile $stateBackup
    }
    if ($caseBackup) {
        Save-Utf8NoBom $caseFile $caseBackup
    }
    # DIFF-03 Test Safety: Dọn dẹp CHỈ các kế hoạch context tạm do test sinh ra (NEVER wipe entire directory)
    foreach ($planIdToDelete in $createdPlanIds) {
        $pPath = Join-Path $repoRoot ".agents/context/plans/$planIdToDelete.json"
        if (Test-Path -LiteralPath $pPath) {
            Remove-Item -LiteralPath $pPath -Force -ErrorAction SilentlyContinue
        }
    }
    # DIFF-03 Test Safety: Dọn dẹp CHỈ các bản sao lưu case state và thư mục case do test sinh ra trong .agents/state/cases/
    if (Test-Path -LiteralPath $casesDir) {
        $currentCaseBackups = @(Get-ChildItem -Path $casesDir -Filter "*.json" -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
        foreach ($bk in $currentCaseBackups) {
            if ($initialCaseBackups -notcontains $bk) {
                Remove-Item -LiteralPath $bk -Force -ErrorAction SilentlyContinue
            }
        }
        $currentCaseDirs = @(Get-ChildItem -Path $casesDir -Directory -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
        foreach ($cd in $currentCaseDirs) {
            if ($initialCaseDirs -notcontains $cd) {
                Remove-Item -LiteralPath $cd -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

Write-Host "`n==================================================================" -ForegroundColor Cyan
Write-Host "   KẾT QUẢ KIỂM ĐỊNH 3-LAYER: $passCount / $testCount PASS ($([math]::Round(($passCount/$testCount)*100, 1))%)" -ForegroundColor $(if ($failCount -eq 0) { "Green" } else { "Red" })
Write-Host "==================================================================" -ForegroundColor Cyan

if ($failCount -gt 0) {
    exit 1
} else {
    exit 0
}
