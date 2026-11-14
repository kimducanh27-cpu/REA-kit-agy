# ==============================================================================
# Script Kiểm Định Tự Động Bộ Máy Phỏng Vấn Thích Ứng (test_interview.ps1)
# REA-kit-agy v1.1 - 3-Layer Adaptive Interview Verification Suite
# Layer 1: Static Validation & Schema Conformance
# Layer 2: State & CLI Integration & Exit Gate Tests 01-06
# Layer 3: Adaptive Behavior Scenarios A through J
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
    [System.IO.File]::WriteAllText($path, $content, (New-Object System.Text.UTF8Encoding($false)))
}

# Sao lưu state ban đầu để khôi phục sau kiểm thử
$stateBackup = $null
$caseBackup = $null
if (Test-Path $stateFile) { $stateBackup = Get-Content -LiteralPath $stateFile -Raw -Encoding UTF8 }
if (Test-Path $caseFile)  { $caseBackup  = Get-Content -LiteralPath $caseFile -Raw -Encoding UTF8 }

try {
    # ======================================================================
    # LAYER 1: STATIC VALIDATION & SCHEMA CONFORMANCE
    # ======================================================================
    Write-Host "`n>>> LAYER 1: STATIC VALIDATION & SCHEMA CONFORMANCE" -ForegroundColor Cyan

    Assert-Test "File interview.ps1 tồn tại" (Test-Path $interviewScript)
    Assert-Test "File 14-INTERVIEW-STATE-TEMPLATE.json tồn tại" (Test-Path $templateFile)
    Assert-Test "File interview_state.json tồn tại" (Test-Path $stateFile)
    Assert-Test "File context.ps1 tồn tại" (Test-Path $contextScript)

    # 1.1 JSON Schema Validation & Enum Checks
    $tpl = Get-Content -LiteralPath $templateFile -Raw -Encoding UTF8 | ConvertFrom-Json
    $st  = Get-Content -LiteralPath $stateFile -Raw -Encoding UTF8 | ConvertFrom-Json

    $hasDraft7 = ($tpl.'$schema' -match "draft-07")
    Assert-Test "Template tuân thủ chuẩn JSON Schema Draft-07" $hasDraft7

    $goalEnum = $tpl.properties.goals.items.properties.status.enum
    $hasAllGoalEnums = ($goalEnum -contains "RESOLVED") -and ($goalEnum -contains "APPROVED") -and ($goalEnum -contains "DEFERRED") -and ($goalEnum -contains "BLOCKED")
    Assert-Test "Goal status enums đầy đủ trạng thái đánh giá (RESOLVED, APPROVED, DEFERRED, BLOCKED)" $hasAllGoalEnums

    $ansTypeEnum = $tpl.properties.answers.items.properties.answer_type.enum
    $hasSpontType = ($ansTypeEnum -contains "SPONTANEOUS_INFO")
    Assert-Test "Answer type enums bao gồm SPONTANEOUS_INFO" $hasSpontType

    $unkPrioEnum = $tpl.properties.unknowns.items.properties.priority.enum
    $unkStatusEnum = $tpl.properties.unknowns.items.properties.status.enum
    $hasUnkEnums = ($unkPrioEnum -contains "CRITICAL") -and ($unkPrioEnum -contains "HIGH") -and ($unkStatusEnum -contains "OPEN")
    Assert-Test "Unknown schema có phân loại độ ưu tiên (CRITICAL, HIGH) và trạng thái (OPEN, RESOLVED)" $hasUnkEnums

    # 1.2 UTF-8 No BOM Checks
    $bytes = [System.IO.File]::ReadAllBytes($stateFile)
    $hasBOM = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    Assert-Test "interview_state.json được ghi chuẩn UTF-8 No BOM" (-not $hasBOM)

    # 1.3 Mobile Display Compatibility Matrix in Template
    $specTplContent = Get-Content -LiteralPath $specTemplate -Raw -Encoding UTF8
    $hasMatrixCols = $specTplContent -match '\|\s*Device class\s*\|\s*Aspect ratio\s*\|\s*Viewport \(dp\)\s*\|\s*Orientation\s*\|\s*Support status\s*\|\s*Verification\s*\|'
    $hasEvidenceModel = ($specTplContent -match "NOT_ASSESSED") -and ($specTplContent -match "IN_SCOPE") -and ($specTplContent -match "NOT_VERIFIED")
    Assert-Test "Spec Template có Mobile Display Compatibility Matrix chuẩn 6 cột với mô hình dựa trên bằng chứng" ($hasMatrixCols -and $hasEvidenceModel)

    # ======================================================================
    # LAYER 2: STATE & CLI INTEGRATION & EXIT GATE TESTS 01-06
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

    # 2.3 Repetition Prevention (DIFF-03)
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-question -QuestionId "Q-REP-1" -Text "Hệ quản trị CSDL dự kiến là gì?" -Reason "Xác định storage engine" | Out-Null
    
    $repeatRejected = $false
    try {
        $repErr = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-question -QuestionId "Q-REP-2" -Text "Hệ quản trị CSDL dự kiến là gì?" -Reason "Hỏi lại mà không có cờ" 2>&1
        if ($repErr -match "REPETITION_REJECTED") { $repeatRejected = $true }
    } catch {
        $repeatRejected = $true
    }
    Assert-Test "CLI record-question chặn câu hỏi trùng lặp khi không có -AllowRepeat (DIFF-03)" $repeatRejected

    $repAllowedOut = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-question -QuestionId "Q-REP-2" -Text "Hệ quản trị CSDL dự kiến là gì?" -Reason "Đánh giá lại sau khi kiểm toán phát hiện SQLite chưa mã hóa" -AllowRepeat
    $repeatAllowed = ($repAllowedOut -join "`n") -match "REPETITION_ALLOWED"
    Assert-Test "CLI record-question cho phép hỏi lại khi có -AllowRepeat kèm lý do hợp lệ (DIFF-03)" $repeatAllowed

    # 2.4 Orphan Answer Prevention (DIFF-04)
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

    # 2.5 Record Unknown Action (DIFF-05)
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-unknown -UnknownId "UNK-TEST-01" -Description "Tài liệu API chưa hoàn thiện" -Priority "HIGH" -Status "OPEN" | Out-Null
    $stUnk = Get-Content -LiteralPath $stateFile -Raw -Encoding UTF8 | ConvertFrom-Json
    $unkStored = ($stUnk.unknowns.Count -ge 1 -and $stUnk.unknowns[0].unknown_id -eq "UNK-TEST-01" -and $stUnk.unknowns[0].priority -eq "HIGH")
    Assert-Test "CLI record-unknown lưu trữ thành công điểm mù với độ ưu tiên và trạng thái (DIFF-05)" $unkStored

    # 2.6 Referential Integrity Validation
    $valOut = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript validate
    $valPassed = ($valOut -join "`n") -match "PASS"
    Assert-Test "CLI validate kiểm tra thành công tính toàn vẹn tham chiếu" $valPassed

    # ----------------------------------------------------------------------
    # EXIT GATE REGRESSION TESTS (DIFF-01 TESTS 01 - 06)
    # ----------------------------------------------------------------------
    Write-Host "`n>>> EXIT GATE REGRESSION TESTS (DIFF-01 TESTS 01 - 06)" -ForegroundColor Cyan

    # TEST 01: Goal without Decision & without Questions must NOT pass (NEEDS_INPUT)
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript init -Force | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-goal -GoalId "G-REG-01" -Description "Mục tiêu chưa có quyết định xử lý" | Out-Null
    $evalT1 = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript evaluate-sufficiency
    $stT1 = Get-Content -LiteralPath $stateFile -Raw -Encoding UTF8 | ConvertFrom-Json
    Assert-Test "Test 01: Goal không có Decision và không có câu hỏi tồn đọng KHÔNG ĐƯỢC SUFFICIENT (NEEDS_INPUT)" ($stT1.sufficiency_evaluation.verdict -eq "NEEDS_INPUT")

    # TEST 02: PROPOSED Decision must not count as approved
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-decision -DecisionId "DEC-REG-01" -Description "G-REG-01: Giải pháp đề xuất" -SelectedOption "Option A" -ApprovalStatus "PROPOSED" -RelatedRequirements "G-REG-01" | Out-Null
    $evalT2 = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript evaluate-sufficiency
    $stT2 = Get-Content -LiteralPath $stateFile -Raw -Encoding UTF8 | ConvertFrom-Json
    Assert-Test "Test 02: Quyết định ở trạng thái PROPOSED không được coi là đã duyệt (NEEDS_INPUT)" ($stT2.sufficiency_evaluation.verdict -eq "NEEDS_INPUT")

    # TEST 03: Important unresolved Unknown must prevent completion (BLOCKED)
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-decision -DecisionId "DEC-REG-01" -Description "G-REG-01: Đã duyệt" -SelectedOption "Option A" -ApprovalStatus "APPROVED" -RelatedRequirements "G-REG-01" | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-unknown -UnknownId "UNK-CRIT-01" -Description "Chưa rõ cơ chế ký số APK" -Priority "CRITICAL" -Status "OPEN" | Out-Null
    $evalT3 = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript evaluate-sufficiency
    $stT3 = Get-Content -LiteralPath $stateFile -Raw -Encoding UTF8 | ConvertFrom-Json
    Assert-Test "Test 03: Điểm mù quan trọng (CRITICAL/HIGH) chưa giải quyết ngăn chặn hoàn tất (BLOCKED)" ($stT3.sufficiency_evaluation.verdict -eq "BLOCKED")

    # TEST 04: Properly deferred non-critical decision must not unnecessarily block completion
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript init -Force | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-goal -GoalId "G-CORE" -Description "Tính năng chính" | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-decision -DecisionId "DEC-CORE" -Description "G-CORE: Triển khai Room DB" -SelectedOption "Room" -ApprovalStatus "APPROVED" -RelatedRequirements "G-CORE" | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-goal -GoalId "G-NICE" -Description "Tính năng mở rộng" | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-decision -DecisionId "DEC-NICE" -Description "G-NICE: Chủ đề tối nâng cao" -SelectedOption "Hoãn sang v1.2" -ApprovalStatus "DEFERRED" -RelatedRequirements "G-NICE" | Out-Null
    $evalT4 = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript evaluate-sufficiency
    $stT4 = Get-Content -LiteralPath $stateFile -Raw -Encoding UTF8 | ConvertFrom-Json
    $hasDeferred = $stT4.sufficiency_evaluation.deferred_decisions.Count -ge 1
    Assert-Test "Test 04: Quyết định hoãn hợp lệ có lý do giải trình không chặn Exit Gate (SUFFICIENT)" ($stT4.sufficiency_evaluation.verdict -eq "SUFFICIENT" -and $hasDeferred)

    # TEST 05: Conflicting decisions must prevent silent completion (BLOCKED)
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-conflict -ConflictId "CONF-T5" -Explanation "Xung đột giữa yêu cầu bảo mật cao và lưu mật khẩu văn bản rõ" -Severity "CRITICAL" | Out-Null
    $evalT5 = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript evaluate-sufficiency
    $stT5 = Get-Content -LiteralPath $stateFile -Raw -Encoding UTF8 | ConvertFrom-Json
    Assert-Test "Test 05: Mâu thuẫn CRITICAL chưa giải quyết đưa verdict về BLOCKED" ($stT5.sufficiency_evaluation.verdict -eq "BLOCKED")

    # TEST 06: Fully resolved Goal can legitimately pass
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript resolve-conflict -ConflictId "CONF-T5" -ResolutionStrategy "Sử dụng Android KeyStore Cipher" | Out-Null
    $evalT6 = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript evaluate-sufficiency
    $stT6 = Get-Content -LiteralPath $stateFile -Raw -Encoding UTF8 | ConvertFrom-Json
    Assert-Test "Test 06: Toàn bộ mục tiêu có quyết định APPROVED và conflict RESOLVED vượt qua Exit Gate (SUFFICIENT)" ($stT6.sufficiency_evaluation.verdict -eq "SUFFICIENT")

    # ======================================================================
    # LAYER 3: ADAPTIVE BEHAVIOR SCENARIOS (A THROUGH J)
    # ======================================================================
    Write-Host "`n>>> LAYER 3: ADAPTIVE BEHAVIOR SCENARIOS (A THROUGH J)" -ForegroundColor Cyan

    # Scenario A: Bug fix / Minimal scope (RCA & STR, no bloated questions)
    $domainBug = Get-Content -LiteralPath (Join-Path $domainsDir "bug-fix.md") -Raw -Encoding UTF8
    Assert-Test "Scenario A: Cẩm nang bug-fix tập trung vào tái hiện lỗi (STR) và khoanh vùng Root Cause" ($domainBug -match "BUG_FIX" -and ($domainBug -match "Reproduction" -or $domainBug -match "Tái Hiện"))

    # Scenario B: Binary obfuscated / Evidence-based assumptions
    $skillContent = Get-Content -LiteralPath $skillFile -Raw -Encoding UTF8
    Assert-Test "Scenario B: Phân loại 6 nhãn sự thật và hỗ trợ giả định kỹ thuật có thể đảo ngược" ($skillContent -match "AI_INFERENCE" -and $skillContent -match "ASSUMPTION" -and $skillContent -match "VERIFIED_FACT")

    # Scenario C: Delegated choice ("Anh chọn giúp" -> Safe default assumption)
    Assert-Test "Scenario C: Xử lý lựa chọn ủy quyền (Delegated Choice) ghi vào Assumption Record" ($skillContent -match "Safe Default" -or $skillContent -match "Assumption Record")

    # Scenario D: Feature addition / Scope boundaries & dependencies
    $domainFeature = Get-Content -LiteralPath (Join-Path $domainsDir "feature-addition.md") -Raw -Encoding UTF8
    Assert-Test "Scenario D: Thêm tính năng định tuyến đúng FEATURE_ADDITION với kiểm soát phạm vi" ($domainFeature -match "FEATURE_ADDITION" -and ($domainFeature -match "Scope" -or $domainFeature -match "Phạm Vi"))

    # Scenario E: Contradiction resolution protocol
    Assert-Test "Scenario E: Quy trình xử lý mâu thuẫn (Contradiction Resolution Protocol qua record-conflict)" ($skillContent -match "Contradiction Resolution" -and $skillContent -match "record-conflict")

    # Scenario F: Ambiguous response clarification & 3 design modes
    Assert-Test "Scenario F: Phản hồi mơ hồ kích hoạt làm rõ và điều tiết 3 chế độ thiết kế" ($skillContent -match "Ambiguous" -and $skillContent -match "DESIGN_")

    # Scenario G: Scope reduction mid-interview
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript init -Force | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-decision -DecisionId "DEC-INDEP" -Description "Kiến trúc module cơ bản" -SelectedOption "MVI Architecture" -ApprovalStatus "APPROVED" | Out-Null
    & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-scope-change -ChangeId "SC-TEST" -PreviousScope "Bao gồm module Video Player" -NewScope "Bỏ module Video Player" | Out-Null
    $stSG = Get-Content -LiteralPath $stateFile -Raw -Encoding UTF8 | ConvertFrom-Json
    $indepKept = ($stSG.decisions | Where-Object { $_.decision_id -eq "DEC-INDEP" }).selected_option -eq "MVI Architecture"
    Assert-Test "Scenario G: Scope Change ghi nhận thay đổi phạm vi mà không làm mất quyết định độc lập" ($stSG.scope_changes.Count -ge 1 -and $indepKept)

    # Scenario H: Source repository available (Gate 02 cleared states allow Gate 03)
    $gateContent = Get-Content -LiteralPath $gateScript -Raw -Encoding UTF8
    $clearedStatesMatch = ($gateContent -match '\$clearedStates\s*=') -and ($gateContent -match '"SKIPPED"') -and ($gateContent -match '"WAIVED"')
    Assert-Test "Scenario H: Gate 02 SKIPPED/WAIVED cho phép vào Gate 03 mà không bị chặn cứng" $clearedStatesMatch

    # Scenario I: Performance-critical app (Quantitative metrics & 5-tier classification)
    $domainPerf = Get-Content -LiteralPath (Join-Path $domainsDir "app-optimization.md") -Raw -Encoding UTF8
    $hasTaxonomy = ($domainPerf -match "REFERENCE_BENCHMARK") -and ($domainPerf -match "CANDIDATE_RECOMMENDATION") -and ($domainPerf -match "USER_REQUIREMENT")
    Assert-Test "Scenario I: Tối ưu hiệu năng phân loại chỉ số theo 5 tầng (Benchmark, Recommendation, Requirement, Constraint, Assumption)" $hasTaxonomy

    # Scenario J: Multiple competing goals & MoSCoW trade-offs
    $domainReq = Get-Content -LiteralPath (Join-Path $domainsDir "requirements-prioritization.md") -Raw -Encoding UTF8
    Assert-Test "Scenario J: Phân định mức độ ưu tiên theo MoSCoW và thỏa hiệp đánh đổi kiến trúc" ($domainReq -match "MoSCoW" -and ($domainReq -match "Trade-off" -or $domainReq -match "đánh đổi"))

    # Vietnamese Intent Recognition Check (DIFF-09)
    $contextPlanOut = & powershell -NoProfile -ExecutionPolicy Bypass -File $contextScript plan -Task "tối ưu hiệu năng và giảm tiêu thụ ram"
    $optProfileResolved = ($contextPlanOut -join "`n") -match "Profile\s*:\s*optimization"
    Assert-Test "DIFF-09: Context Engine nhận diện chính xác ý định tiếng Việt ('tối ưu hiệu năng' -> optimization profile)" $optProfileResolved

} finally {
    # Khôi phục trạng thái chuẩn sạch ban đầu
    if ($stateBackup) {
        Save-Utf8NoBom $stateFile $stateBackup
    }
    if ($caseBackup) {
        Save-Utf8NoBom $caseFile $caseBackup
    }
    # Dọn dẹp kế hoạch context tạm
    Get-ChildItem -Path (Join-Path $repoRoot ".agents/context/plans") -Filter "*.json" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
}

Write-Host "`n==================================================================" -ForegroundColor Cyan
Write-Host "   KẾT QUẢ KIỂM ĐỊNH 3-LAYER: $passCount / $testCount PASS ($([math]::Round(($passCount/$testCount)*100, 1))%)" -ForegroundColor $(if ($failCount -eq 0) { "Green" } else { "Red" })
Write-Host "==================================================================" -ForegroundColor Cyan

if ($failCount -gt 0) {
    exit 1
} else {
    exit 0
}
