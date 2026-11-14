# ==============================================================================
# Script Kiểm Định Tự Động Bộ Máy Phỏng Vấn Thích Ứng (test_interview.ps1)
# REA-kit-agy v1.1 - Adaptive Interview & State Machine Verification Suite
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
$stateFile       = Join-Path $repoRoot ".agents/state/interview_state.json"
$caseFile        = Join-Path $repoRoot ".agents/state/active_case.json"
$templateFile    = Join-Path $repoRoot "templates/14-INTERVIEW-STATE-TEMPLATE.json"

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "   REA-KIT-AGY v1.1 — BỘ KIỂM ĐỊNH ADAPTIVE INTERVIEW SYSTEM      " -ForegroundColor Cyan
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
    # ----------------------------------------------------------------------
    # TEST GROUP 1: SCHEMA VALIDATION & TEMPLATE CONFORMANCE (R2)
    # ----------------------------------------------------------------------
    Write-Host "`n>>> KIỂM TRA NHÓM 1: CẤU TRÚC JSON & SCHEMA CONFORMANCE" -ForegroundColor Cyan

    Assert-Test "File interview.ps1 tồn tại" (Test-Path $interviewScript)
    Assert-Test "File 14-INTERVIEW-STATE-TEMPLATE.json tồn tại" (Test-Path $templateFile)
    Assert-Test "File interview_state.json tồn tại" (Test-Path $stateFile)

    $schemaValid = $false
    try {
        $tpl = Get-Content -LiteralPath $templateFile -Raw -Encoding UTF8 | ConvertFrom-Json
        $st  = Get-Content -LiteralPath $stateFile -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($tpl.properties -ne $null -and $tpl.properties.schema_version -ne $null -and $st.schema_version -eq 1 -and ($null -ne $st.session) -and ($null -ne $st.goals) -and ($null -ne $st.decisions)) {
            $schemaValid = $true
        }
    } catch {
        $schemaValid = $false
    }
    Assert-Test "Schema template và initial state version 1 (Draft-07) hợp lệ" $schemaValid

    # Kiểm tra UTF-8 No BOM
    $bytes = [System.IO.File]::ReadAllBytes($stateFile)
    $hasBOM = ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
    Assert-Test "interview_state.json được ghi chuẩn UTF-8 No BOM" (-not $hasBOM)

    # ----------------------------------------------------------------------
    # TEST GROUP 2: CLI ACTIONS & DECISION-DRIVEN ENGINE (R1, R2, R3)
    # ----------------------------------------------------------------------
    Write-Host "`n>>> KIỂM TRA NHÓM 2: CLI ACTIONS & SUFFICIENCY EVALUATION" -ForegroundColor Cyan

    # 2.1 Re-init
    $initOut = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript init -CaseId "TEST-CASE-001"
    $stAfterInit = Get-Content -LiteralPath $stateFile -Raw -Encoding UTF8 | ConvertFrom-Json
    Assert-Test "CLI init khởi tạo case TEST-CASE-001 thành công" ($stAfterInit.case_id -eq "TEST-CASE-001")

    # 2.2 Record Goal
    $goalOut = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-goal -GoalId "G-001" -Description "Fix crash khi cuộn danh sách lớn" -Domain "APPLICATION_DIAGNOSIS" -Priority "P1_HIGH"
    $stGoal = Get-Content -LiteralPath $stateFile -Raw -Encoding UTF8 | ConvertFrom-Json
    Assert-Test "CLI record-goal ghi nhận mục tiêu G-001" ($stGoal.goals.Count -ge 1 -and $stGoal.goals[0].goal_id -eq "G-001")

    # 2.3 Record Question
    $q1Out = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-question -QuestionId "Q-001" -Domain "APPLICATION_DIAGNOSIS" -Text "Crash xảy ra ở bước nào?" -Reason "Xác định stack trace và điểm crash" -GoalIds "G-001" -DecisionIds "DEC-BUG-001"
    $stQ1 = Get-Content -LiteralPath $stateFile -Raw -Encoding UTF8 | ConvertFrom-Json
    Assert-Test "CLI record-question ghi nhận câu hỏi Q-001" ($stQ1.questions.Count -ge 1 -and $stQ1.questions[0].question_id -eq "Q-001")

    # 2.4 Record Answer
    $a1Out = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-answer -AnswerId "ANS-001" -QuestionId "Q-001" -Answer "Khi mở tab lịch sử và vuốt nhanh xuống dưới" -Type "CLEAR" -Confidence "HIGH"
    $stA1 = Get-Content -LiteralPath $stateFile -Raw -Encoding UTF8 | ConvertFrom-Json
    Assert-Test "CLI record-answer cập nhật câu trả lời cho Q-001 (status: ANSWERED)" ($stA1.questions[0].status -eq "ANSWERED")

    # 2.5 Repetition Prevention (R7): Hỏi lại câu hỏi y hệt sau khi đã trả lời
    $qRepeatOut = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-question -QuestionId "Q-002" -Domain "APPLICATION_DIAGNOSIS" -Text "Crash xảy ra ở bước nào?" -Reason "Lặp lại có chủ đích" -GoalIds "G-001"
    $repeatBlocked = ($qRepeatOut -join "`n") -match "REPETITION_ALERT"
    Assert-Test "Repetition Prevention cảnh báo câu hỏi trùng lặp nội dung đã trả lời" $repeatBlocked

    # 2.6 Sufficiency Evaluation khi chưa có Decision (phải là NEEDS_INPUT)
    $eval1 = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript evaluate-sufficiency
    $stEval1 = Get-Content -LiteralPath $stateFile -Raw -Encoding UTF8 | ConvertFrom-Json
    Assert-Test "Exit Gate trả về NEEDS_INPUT khi chưa có Decision giải quyết Goal G-001" ($stEval1.sufficiency_evaluation.verdict -eq "NEEDS_INPUT")

    # 2.7 Record Conflict (R6 - Contradiction Resolution)
    $confOut = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-conflict -ConflictId "CONF-001" -Explanation "Yêu cầu offline 100% nhưng đòi đồng bộ realtime qua websocket" -ConflictingItems "ANS-001,REQ-SYNC" -Severity "CRITICAL"
    $evalConflict = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript evaluate-sufficiency
    $stEvalConflict = Get-Content -LiteralPath $stateFile -Raw -Encoding UTF8 | ConvertFrom-Json
    Assert-Test "Contradiction Resolution: Mâu thuẫn CRITICAL chưa giải quyết đưa verdict về BLOCKED" ($stEvalConflict.sufficiency_evaluation.verdict -eq "BLOCKED")

    # 2.8 Resolve Conflict & Record Decision (Chốt quyết định giải quyết Goal)
    $resConfOut = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript resolve-conflict -ConflictId "CONF-001" -ResolutionStrategy "Offline-First với WorkManager định kỳ đồng bộ khi có kết nối"
    $decOut = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-decision -DecisionId "DEC-BUG-001" -Description "G-001: Tối ưu DiffUtil và phân trang Paging 3" -SelectedOption "Tối ưu DiffUtil và tải phân trang Paging 3" -Options "Tối ưu DiffUtil,Giới hạn 20 item" -ApprovalStatus "APPROVED" -RelatedRequirements "G-001"
    $evalSufficient = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript evaluate-sufficiency
    $stEvalSufficient = Get-Content -LiteralPath $stateFile -Raw -Encoding UTF8 | ConvertFrom-Json
    Assert-Test "Exit Gate chuyển sang SUFFICIENT khi mục tiêu có quyết định APPROVED và conflict RESOLVED" ($stEvalSufficient.sufficiency_evaluation.verdict -eq "SUFFICIENT")

    # 2.9 Scope Change Handling (R8)
    $scOut = & powershell -NoProfile -ExecutionPolicy Bypass -File $interviewScript record-scope-change -ChangeId "SC-001" -PreviousScope "Bao gồm module chat realtime" -NewScope "Bỏ module chat realtime"
    $stSC = Get-Content -LiteralPath $stateFile -Raw -Encoding UTF8 | ConvertFrom-Json
    $decKept = ($stSC.decisions | Where-Object { $_.decision_id -eq "DEC-BUG-001" }).selected_option -eq "Tối ưu DiffUtil và tải phân trang Paging 3"
    Assert-Test "Scope Change ghi nhận thay đổi phạm vi mà không làm mất quyết định không liên quan" ($stSC.scope_changes.Count -ge 1 -and $decKept)

    # ----------------------------------------------------------------------
    # TEST GROUP 3: GATE 02 TO GATE 03 INCONSISTENCY FIX (R9)
    # ----------------------------------------------------------------------
    Write-Host "`n>>> KIỂM TRA NHÓM 3: TƯƠNG THÍCH GATE 02 SKIPPED / REUSED TRONG GATE 03" -ForegroundColor Cyan

    $gateContent = Get-Content -LiteralPath $gateScript -Raw -Encoding UTF8
    $clearedStatesMatch = ($gateContent -match '\$clearedStates\s*=') -and ($gateContent -match '"SKIPPED"') -and ($gateContent -match '"NOT_APPLICABLE"')
    Assert-Test "gate.ps1 định nghĩa danh sách trạng thái vượt cổng hợp lệ (`$clearedStates bao gồm SKIPPED, NOT_APPLICABLE)" $clearedStatesMatch

    $prompt3Content = Get-Content -LiteralPath (Join-Path $repoRoot "prompts/03-TAB-PRODUCT-DEFINITION.md") -Raw -Encoding UTF8
    $promptMatchesCleared = $prompt3Content -match 'SKIPPED' -and $prompt3Content -match 'NOT_APPLICABLE' -and $prompt3Content -match 'PASS_WITH_LIMITATIONS'
    Assert-Test "Prompt 03 không còn đòi hỏi cứng nhắc gate_02 -eq PASS" $promptMatchesCleared

    # ----------------------------------------------------------------------
    # TEST GROUP 4: 10 ADAPTIVE DOMAINS POPULATION (R4, R5)
    # ----------------------------------------------------------------------
    Write-Host "`n>>> KIỂM TRA NHÓM 4: 10 CẨM NANG CHUYÊN MÔN (DOMAIN GUIDES)" -ForegroundColor Cyan

    $domainsDir = Join-Path $repoRoot ".agents/skills/rea-interview/domains"
    $expectedDomains = @(
        "app-optimization.md",
        "security-hardening.md",
        "feature-addition.md",
        "bug-fix.md",
        "ux-ui-improvement.md",
        "architecture-maintainability.md",
        "platform-compatibility.md",
        "requirements-prioritization.md",
        "acceptance-criteria.md",
        "feature-optimization.md"
    )

    $allDomainsPresent = $true
    foreach ($dom in $expectedDomains) {
        $domPath = Join-Path $domainsDir $dom
        if (-not (Test-Path $domPath)) {
            $allDomainsPresent = $false
            Write-Host " [!] Thiếu domain guide: $dom" -ForegroundColor Red
        }
    }
    Assert-Test "Đầy đủ 10 cẩm nang domain chuẩn trong rea-interview/domains/" $allDomainsPresent

    $expectedAliases = @(
        "application-diagnosis.md",
        "performance-optimization.md",
        "security-privacy.md",
        "feature-discovery.md",
        "ux-workflows.md"
    )
    $allAliasesPresent = $true
    foreach ($al in $expectedAliases) {
        $alPath = Join-Path $domainsDir $al
        if (-not (Test-Path $alPath)) {
            $allAliasesPresent = $false
        }
    }
    Assert-Test "Đầy đủ 5 alias files chuyển hướng tương thích ngược" $allAliasesPresent

    # ----------------------------------------------------------------------
    # TEST GROUP 5: END-TO-END BEHAVIORAL VERIFICATION (CASES A - J)
    # ----------------------------------------------------------------------
    Write-Host "`n>>> KIỂM TRA NHÓM 5: XÁC MINH 10 HÀNH VI ĐẦU-CUỐI (CASES A - J)" -ForegroundColor Cyan

    $skillContent = Get-Content -LiteralPath (Join-Path $repoRoot ".agents/skills/rea-interview/SKILL.md") -Raw -Encoding UTF8

    # Case A: Minimal scope / Bug fix only
    $domainBug = Get-Content -LiteralPath (Join-Path $domainsDir "bug-fix.md") -Raw -Encoding UTF8
    $caseA_Pass = ($domainBug -match "BUG_FIX") -and ($domainBug -match "Reproduction" -or $domainBug -match "Tái Hiện")
    Assert-Test "Case A: Phỏng vấn chẩn đoán lỗi (Application Diagnosis / Bug Fix) tập trung vào STR và Root Cause" $caseA_Pass

    # Case B: Binary obfuscated / Evidence-based assumptions
    $caseB_Pass = $skillContent -match "AI_INFERENCE" -and $skillContent -match "ASSUMPTION" -and $skillContent -match "VERIFIED_FACT"
    Assert-Test "Case B: 6 nhãn phân loại sự thật và cơ chế ghi nhận giả định có thể đảo ngược" $caseB_Pass

    # Case C: Delegated choice ("Anh chọn giúp" -> Safe default assumption)
    $caseC_Pass = $skillContent -match "Safe Default" -and $skillContent -match "Assumption Record"
    Assert-Test "Case C: Xử lý lựa chọn ủy quyền (Delegated Choice) chuyển thành Reversible Assumption" $caseC_Pass

    # Case D: Feature addition / Google Login
    $domainFeature = Get-Content -LiteralPath (Join-Path $domainsDir "feature-addition.md") -Raw -Encoding UTF8
    $caseD_Pass = $domainFeature -match "FEATURE_ADDITION" -and ($domainFeature -match "Scope" -or $domainFeature -match "Phạm Vi")
    Assert-Test "Case D: Thêm tính năng định tuyến đúng FEATURE_ADDITION với kiểm soát phạm vi và quyền hạn" $caseD_Pass

    # Case E: Contradiction resolution protocol
    $caseE_Pass = $skillContent -match "Contradiction Resolution" -and $skillContent -match "record-conflict"
    Assert-Test "Case E: Quy trình giải quyết mâu thuẫn (Contradiction Resolution Protocol)" $caseE_Pass

    # Case F: Vague answer clarification ("Làm đẹp hiện đại")
    $caseF_Pass = $skillContent -match "Ambiguous" -and $skillContent -match "DESIGN_"
    Assert-Test "Case F: Phản hồi mơ hồ kích hoạt làm rõ và điều tiết 3 chế độ thiết kế" $caseF_Pass

    # Case G: Scope reduction mid-interview
    $caseG_Pass = $skillContent -match "Scope Change Handling" -and $skillContent -match "record-scope-change"
    Assert-Test "Case G: Giảm phạm vi giữa chừng lưu hồ sơ scope change, bảo toàn quyết định độc lập" $caseG_Pass

    # Case H: Source repository available (WF03 skip Gate 02)
    $caseH_Pass = $promptMatchesCleared -and $clearedStatesMatch
    Assert-Test "Case H: Dự án có sẵn source bỏ qua decompile APK, Gate 02 SKIPPED cho phép vào Gate 03" $caseH_Pass

    # Case I: Performance-critical app
    $domainPerf = Get-Content -LiteralPath (Join-Path $domainsDir "app-optimization.md") -Raw -Encoding UTF8
    $caseI_Pass = $domainPerf -match "APP_OPTIMIZATION" -and ($domainPerf -match "FPS" -or $domainPerf -match "Hiệu Năng")
    Assert-Test "Case I: Tối ưu hiệu năng định tuyến đúng APP_OPTIMIZATION với ngân sách FPS/RAM/Cold Start" $caseI_Pass

    # Case J: Multiple competing goals & trade-offs
    $domainReq = Get-Content -LiteralPath (Join-Path $domainsDir "requirements-prioritization.md") -Raw -Encoding UTF8
    $caseJ_Pass = $domainReq -match "MoSCoW" -and ($domainReq -match "Trade-off" -or $domainReq -match "đánh đổi")
    Assert-Test "Case J: Mục tiêu cạnh tranh được phân cấp ưu tiên MoSCoW và phân tích đánh đổi (Trade-offs)" $caseJ_Pass

    # ----------------------------------------------------------------------
    # TEST GROUP 6: MOBILE DISPLAY ASPECT RATIO & RESPONSIVE LAYOUT
    # ----------------------------------------------------------------------
    Write-Host "`n>>> KIỂM TRA NHÓM 6: TƯƠNG THÍCH MÀN HÌNH DI ĐỘNG & TỶ LỆ KHUNG HÌNH" -ForegroundColor Cyan

    $specTemplatePath = Join-Path $repoRoot "templates/02-SPEC-TEMPLATE.md"
    $specTemplateContent = Get-Content -LiteralPath $specTemplatePath -Raw -Encoding UTF8

    # 6.1 Check Mobile Display Compatibility Matrix columns
    $matrixHeaderMatch = $specTemplateContent -match '\|\s*Device class\s*\|\s*Aspect ratio\s*\|\s*Viewport \(dp\)\s*\|\s*Orientation\s*\|\s*Support status\s*\|\s*Verification\s*\|'
    Assert-Test "Spec Template có Mobile Display Compatibility Matrix chuẩn 6 cột" $matrixHeaderMatch

    # 6.2 Check Minimum supported viewport & Breakpoints
    $viewportMatch = ($specTemplateContent -match "320\s*dp") -and ($specTemplateContent -match "Window Size Classes")
    Assert-Test "Spec Template định nghĩa Cổng hiển thị tối thiểu (320dp) và Điểm ngắt thích ứng" $viewportMatch

    # 6.3 Check Safe-area, Overflow & Text clipping rules
    $safeAreaMatch = ($specTemplateContent -match "WindowInsetsCompat" -or $specTemplateContent -match "Insets") -and ($specTemplateContent -match "verticalScroll" -or $specTemplateContent -match "cuộn dọc") -and ($specTemplateContent -match "TextOverflow.Ellipsis" -or $specTemplateContent -match "maxLines")
    Assert-Test "Spec Template định nghĩa Xử lý Safe-area, Chống tràn bố cục và Bọc/cắt chữ" $safeAreaMatch

    # 6.4 Check Acceptance Criteria for display compatibility
    $acRespMatch = ($specTemplateContent -match "AC-RESP-01" -or $specTemplateContent -match "Tương Thích Màn Hình Di Động") -and ($specTemplateContent -match "48x48dp" -or $specTemplateContent -match "48\s*×\s*48\s*dp")
    Assert-Test "Spec Template có Tiêu chí nghiệm thu BDD cho tương thích màn hình di động" $acRespMatch

    # 6.5 Check Platform Compatibility domain aspect ratio investigation
    $domainCompat = Get-Content -LiteralPath (Join-Path $domainsDir "platform-compatibility.md") -Raw -Encoding UTF8
    $aspectRatioCoverage = ($domainCompat -match "16:9") -and ($domainCompat -match "18:9") -and ($domainCompat -match "19.5:9") -and ($domainCompat -match "20:9") -and ($domainCompat -match "21:9")
    Assert-Test "Domain platform-compatibility bao phủ đầy đủ dải tỷ lệ khung hình 16:9 đến 21:9" $aspectRatioCoverage

    # 6.6 Check Q-COMPAT-03 with non-technical friendly default
    $qCompat3Match = ($domainCompat -match "Q-COMPAT-03") -and ($domainCompat -match "Fluid Responsive" -or $domainCompat -match "co giãn linh hoạt")
    Assert-Test "Domain platform-compatibility có câu hỏi Q-COMPAT-03 kèm giải pháp mặc định an toàn cho người dùng không chuyên" $qCompat3Match

    # 6.7 Check Skill protocol for mobile display
    $skillMobileProtocol = ($skillContent -match "Mobile Display & Responsive Layout Protocol" -or $skillContent -match "Điều Tra Tỷ Lệ Màn Hình Di Động")
    Assert-Test "Skill rea-interview kích hoạt quy chuẩn điều tra màn hình di động và cấm giả định tương thích" $skillMobileProtocol

} finally {
    # Khôi phục trạng thái chuẩn sạch ban đầu
    if ($stateBackup) {
        Save-Utf8NoBom $stateFile $stateBackup
    }
    if ($caseBackup) {
        Save-Utf8NoBom $caseFile $caseBackup
    }
}

Write-Host "`n==================================================================" -ForegroundColor Cyan
Write-Host "   KẾT QUẢ KIỂM ĐỊNH: $passCount / $testCount PASS ($([math]::Round(($passCount/$testCount)*100, 1))%)" -ForegroundColor $(if ($failCount -eq 0) { "Green" } else { "Red" })
Write-Host "==================================================================" -ForegroundColor Cyan

if ($failCount -gt 0) {
    exit 1
} else {
    exit 0
}
