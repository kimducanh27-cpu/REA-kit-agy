#Requires -Version 5.1
<#
.SYNOPSIS
    Adaptive Interview Engine CLI for REA-kit-agy v1.1.
.DESCRIPTION
    Provides deterministic operations for managing structured interview state:
    goals, questions, answers, decisions, assumptions, conflicts, unknowns,
    scope changes, and sufficiency evaluation (Exit Gate).
.EXAMPLE
    powershell -File .agents/scripts/interview.ps1 status
    powershell -File .agents/scripts/interview.ps1 evaluate-sufficiency
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateSet("init", "status", "record-goal", "record-question", "record-answer", "record-decision", "record-assumption", "record-unknown", "record-conflict", "resolve-conflict", "record-scope-change", "evaluate-sufficiency", "validate")]
    [string]$Action,

    [Parameter(Mandatory = $false)]
    [string]$CaseId,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [switch]$AllowRepeat,

    [Parameter(Mandatory = $false)]
    [switch]$Spontaneous,

    [Parameter(Mandatory = $false)]
    [string]$GoalId,

    [Parameter(Mandatory = $false)]
    [string]$QuestionId,

    [Parameter(Mandatory = $false)]
    [string]$AnswerId,

    [Parameter(Mandatory = $false)]
    [string]$DecisionId,

    [Parameter(Mandatory = $false)]
    [string]$AssumptionId,

    [Parameter(Mandatory = $false)]
    [string]$UnknownId,

    [Parameter(Mandatory = $false)]
    [string]$ConflictId,

    [Parameter(Mandatory = $false)]
    [string]$ChangeId,

    [Parameter(Mandatory = $false)]
    [string]$Description,

    [Parameter(Mandatory = $false)]
    [string]$Text,

    [Parameter(Mandatory = $false)]
    [string]$Reason,

    [Parameter(Mandatory = $false)]
    [string]$Domain,

    [Parameter(Mandatory = $false)]
    [string]$ExpectedInfo,

    [Parameter(Mandatory = $false)]
    [string]$Answer,

    [Parameter(Mandatory = $false)]
    [string]$Interpreted,

    [Parameter(Mandatory = $false)]
    [string]$Type,

    [Parameter(Mandatory = $false)]
    [string]$Source = "USER_EXPLICIT",

    [Parameter(Mandatory = $false)]
    [string]$Confidence = "HIGH",

    [Parameter(Mandatory = $false)]
    [string]$SelectedOption,

    [Parameter(Mandatory = $false)]
    [string[]]$Options,

    [Parameter(Mandatory = $false)]
    [string]$Owner = "USER_PO",

    [Parameter(Mandatory = $false)]
    [string]$ApprovalStatus,

    [Parameter(Mandatory = $false)]
    [string]$Rationale,

    [Parameter(Mandatory = $false)]
    [string]$Impact,

    [Parameter(Mandatory = $false)]
    [ValidateSet("BENIGN", "CRITICAL")]
    [string]$RiskLevel = "BENIGN",

    [Parameter(Mandatory = $false)]
    [string]$VerificationTask,

    [Parameter(Mandatory = $false)]
    [string[]]$ConflictingItems,

    [Parameter(Mandatory = $false)]
    [string]$Explanation,

    [Parameter(Mandatory = $false)]
    [ValidateSet("CRITICAL", "MAJOR", "MINOR")]
    [string]$Severity = "MAJOR",

    [Parameter(Mandatory = $false)]
    [string]$ResolutionStrategy,

    [Parameter(Mandatory = $false)]
    [string]$PreviousScope,

    [Parameter(Mandatory = $false)]
    [string]$NewScope,

    [Parameter(Mandatory = $false)]
    [string[]]$GoalIds,

    [Parameter(Mandatory = $false)]
    [string[]]$DecisionIds,

    [Parameter(Mandatory = $false)]
    [string[]]$EvidenceRefs,

    [Parameter(Mandatory = $false)]
    [string[]]$RelatedRequirements,

    [Parameter(Mandatory = $false)]
    [string[]]$DownstreamDeps,

    [Parameter(Mandatory = $false)]
    [string]$Priority = "MEDIUM",

    [Parameter(Mandatory = $false)]
    [string]$Status = "OPEN"
)

$ErrorActionPreference = "Stop"

function Find-RepoRoot {
    $current = (Get-Item -LiteralPath $PSScriptRoot).Parent.Parent.FullName
    if (Test-Path -LiteralPath (Join-Path $current "docs/WORKFLOW_LIFECYCLE.md")) {
        return $current
    }
    throw "Cannot locate repository root from: $PSScriptRoot"
}

$repoRoot = Find-RepoRoot
$interviewStateFile = Join-Path $repoRoot ".agents/state/interview_state.json"
$activeCaseFile = Join-Path $repoRoot ".agents/state/active_case.json"
$schemaTemplateFile = Join-Path $repoRoot "templates/14-INTERVIEW-STATE-TEMPLATE.json"

function Convert-ToCleanArray($inputVal) {
    if ($null -eq $inputVal) { return ,@() }
    $result = @()
    foreach ($item in @($inputVal)) {
        if ($null -ne $item) {
            $str = [string]$item
            if ($str.Contains(",")) {
                $parts = $str.Split(",")
                foreach ($p in $parts) {
                    $trimmed = $p.Trim()
                    if ($trimmed.Length -gt 0) { $result += $trimmed }
                }
            } else {
                $trimmed = $str.Trim()
                if ($trimmed.Length -gt 0) { $result += $trimmed }
            }
        }
    }
    return ,$result
}

function Write-Utf8NoBom {
    param(
        [string]$Path,
        [string]$Content
    )
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    $destFull = [System.IO.Path]::GetFullPath($Path)
    $destDir = [System.IO.Path]::GetDirectoryName($destFull)
    $tmpFile = Join-Path $destDir (".tmp_" + [System.Guid]::NewGuid().ToString("N") + ".tmp")
    $bakFile = Join-Path $destDir (".tmp_" + [System.Guid]::NewGuid().ToString("N") + ".bak")

    [System.IO.File]::WriteAllText($tmpFile, $Content, $utf8NoBom)
    try {
        for ($attempt = 1; $attempt -le 5; $attempt++) {
            try {
                if (Test-Path -LiteralPath $destFull) {
                    [System.IO.File]::Replace($tmpFile, $destFull, $bakFile, $true)
                } else {
                    [System.IO.File]::Move($tmpFile, $destFull)
                }
                break
            } catch [System.IO.IOException], [System.UnauthorizedAccessException] {
                if ($attempt -eq 5) { throw }
                Start-Sleep -Milliseconds (100 * [Math]::Pow(2, $attempt - 1))
            } finally {
                if (Test-Path -LiteralPath $bakFile) {
                    Remove-Item -LiteralPath $bakFile -Force -ErrorAction SilentlyContinue
                }
            }
        }
    } finally {
        if (Test-Path -LiteralPath $tmpFile) {
            Remove-Item -LiteralPath $tmpFile -Force -ErrorAction SilentlyContinue
        }
    }
}

function Get-InterviewState {
    if (-not (Test-Path -LiteralPath $interviewStateFile)) {
        throw "Interview state file does not exist: $interviewStateFile. Run 'interview.ps1 init' first."
    }
    $raw = Get-Content -LiteralPath $interviewStateFile -Raw -Encoding UTF8
    return ($raw | ConvertFrom-Json)
}

function Save-InterviewState {
    param([PSCustomObject]$State)
    $now = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
    $State.last_updated = $now
    if ($State.session) {
        $State.session.updated_at = $now
    }
    $json = $State | ConvertTo-Json -Depth 10
    Write-Utf8NoBom -Path $interviewStateFile -Content $json

    # Synchronize interview summary in active_case.json if active_case exists
    if (Test-Path -LiteralPath $activeCaseFile) {
        try {
            $rawCase = Get-Content -LiteralPath $activeCaseFile -Raw -Encoding UTF8
            $caseObj = $rawCase | ConvertFrom-Json
            if (-not $caseObj.interview) {
                $caseObj | Add-Member -NotePropertyName "interview" -NotePropertyValue ([PSCustomObject]@{})
            }
            $caseObj.interview.state_file = ".agents/state/interview_state.json"
            $caseObj.interview.status = $State.session.status
            $caseObj.interview.session_id = $State.session.session_id
            $caseObj.interview.active_goals_count = @($State.goals | Where-Object { $_.status -eq "ACTIVE" -or $_.status -eq "PROPOSED" -or $_.status -eq "NEEDS_INPUT" }).Count
            $caseObj.interview.decisions_count = @($State.decisions).Count
            $caseObj.interview.unresolved_conflicts_count = @($State.conflicts | Where-Object { $_.resolution_status -ne "RESOLVED" }).Count
            $caseObj.interview.critical_assumptions_count = @($State.assumptions | Where-Object { $_.risk_level -eq "CRITICAL" -and $_.status -eq "ACTIVE" }).Count
            $caseObj.interview.sufficiency_verdict = $State.sufficiency_evaluation.verdict

            $caseJson = $caseObj | ConvertTo-Json -Depth 10
            Write-Utf8NoBom -Path $activeCaseFile -Content $caseJson
        } catch {
            Write-Warning "Could not synchronize active_case.json: $_"
        }
    }
}

switch ($Action) {
    "init" {
        $authoritativeCaseId = "CASE-INITIAL"
        if (Test-Path -LiteralPath $activeCaseFile) {
            try {
                $rawCase = Get-Content -LiteralPath $activeCaseFile -Raw -Encoding UTF8 | ConvertFrom-Json
                if ($rawCase.case_id) { $authoritativeCaseId = $rawCase.case_id }
            } catch { }
        }

        $cId = if ($CaseId) { $CaseId } else { $authoritativeCaseId }
        if ($CaseId -and $CaseId -ne $authoritativeCaseId -and -not $Force) {
            throw "[CASE_MISMATCH] Requested CaseId '$CaseId' does not match active_case.json authoritative CaseId '$authoritativeCaseId'. Pass -Force to override."
        }

        # Check existing interview state for destructive overwrite prevention (DIFF-02)
        if (Test-Path -LiteralPath $interviewStateFile) {
            $existing = $null
            try {
                $existing = Get-Content -LiteralPath $interviewStateFile -Raw -Encoding UTF8 | ConvertFrom-Json
            } catch { }

            if ($existing -and $existing.session) {
                $hasContent = (@($existing.goals).Count -gt 0 -or @($existing.questions).Count -gt 0 -or @($existing.decisions).Count -gt 0)
                if ($hasContent -and -not $Force) {
                    throw "[DESTRUCTIVE_INIT_REFUSED] Active interview session exists with ID '$($existing.session.session_id)' and existing goals/questions/decisions. Refusing destructive overwrite without -Force."
                }
                # Create backup
                $backupDir = Join-Path $repoRoot ".agents/state/cases"
                if (-not (Test-Path -LiteralPath $backupDir)) {
                    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
                }
                $ts = (Get-Date).ToString("yyyyMMdd_HHmmss")
                $backupFile = Join-Path $backupDir "interview_backup_$ts.json"
                Copy-Item -LiteralPath $interviewStateFile -Destination $backupFile -Force
                Write-Host "[BACKUP] Prior interview state backed up to: $backupFile" -ForegroundColor DarkGray
            }
        }

        $now = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
        $initState = [PSCustomObject]@{
            schema_version = 1
            case_id = $cId
            session = [PSCustomObject]@{
                session_id = "INT-SESSION-" + (Get-Date).ToString("yyyyMMdd-HHmmss")
                status = "IN_PROGRESS"
                current_goal = $null
                current_stage = "STAGE_03_PRODUCT_DEFINITION"
                active_domain = $null
                design_mode = $null
                created_at = $now
                updated_at = $now
            }
            goals = @()
            questions = @()
            answers = @()
            decisions = @()
            assumptions = @()
            conflicts = @()
            unknowns = @()
            scope_changes = @()
            sufficiency_evaluation = [PSCustomObject]@{
                verdict = "PENDING"
                evaluated_at = $null
                goal_evaluations = @()
                blocking_reasons = @()
                deferred_decisions = @()
                assumptions_summary = [PSCustomObject]@{
                    total = 0
                    benign = 0
                    critical = 0
                    pending_approval = 0
                }
                summary = "Interview session initialized. Ready for context ingestion."
            }
            last_updated = $now
        }
        Save-InterviewState -State $initState
        Write-Host "[OK] Interview state initialized: $($initState.session.session_id) (Case: $cId)" -ForegroundColor Green
    }

    "status" {
        $st = Get-InterviewState
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host "  REA ADAPTIVE INTERVIEW STATE: $($st.session.session_id)" -ForegroundColor Cyan
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host "Case ID:              $($st.case_id)"
        Write-Host "Status:               $($st.session.status)"
        Write-Host "Active Domain:        $(if ($st.session.active_domain) { $st.session.active_domain } else { 'NONE' })"
        Write-Host "Design Mode:          $(if ($st.session.design_mode) { $st.session.design_mode } else { 'UNSET' })"
        Write-Host "Sufficiency Verdict:  $($st.sufficiency_evaluation.verdict)"
        Write-Host "------------------------------------------------------------"
        Write-Host "Goals Total:          $(@($st.goals).Count)"
        Write-Host "Questions Total:      $(@($st.questions).Count) (Asked: $(@($st.questions | Where-Object { $_.status -eq 'ASKED' }).Count), Answered: $(@($st.questions | Where-Object { $_.status -eq 'ANSWERED' }).Count))"
        Write-Host "Decisions Total:      $(@($st.decisions).Count) (Approved: $(@($st.decisions | Where-Object { $_.approval_status -eq 'APPROVED' }).Count))"
        Write-Host "Assumptions Total:    $(@($st.assumptions).Count) (Critical: $(@($st.assumptions | Where-Object { $_.risk_level -eq 'CRITICAL' -and $_.status -eq 'ACTIVE' }).Count))"
        Write-Host "Conflicts Total:      $(@($st.conflicts).Count) (Unresolved: $(@($st.conflicts | Where-Object { $_.resolution_status -ne 'RESOLVED' }).Count))"
        Write-Host "Unknowns Total:       $(@($st.unknowns).Count) (Open: $(@($st.unknowns | Where-Object { $_.status -eq 'OPEN' -or -not $_.status }).Count))"
        Write-Host "Scope Changes:        $(@($st.scope_changes).Count)"
        Write-Host "------------------------------------------------------------"
        if ($st.sufficiency_evaluation.blocking_reasons.Count -gt 0) {
            Write-Host "BLOCKING REASONS:" -ForegroundColor Red
            foreach ($b in $st.sufficiency_evaluation.blocking_reasons) {
                Write-Host "  [!] $b" -ForegroundColor Yellow
            }
        }
        Write-Host "Summary: $($st.sufficiency_evaluation.summary)"
        Write-Host "============================================================" -ForegroundColor Cyan
    }

    "record-goal" {
        if (-not $GoalId -or -not $Description) {
            throw "GoalId and Description are mandatory."
        }
        $st = Get-InterviewState
        $existing = @($st.goals | Where-Object { $_.goal_id -eq $GoalId })
        if ($existing.Count -gt 0) {
            $existing[0].description = $Description
            if ($Priority) { $existing[0].priority = $Priority }
            if ($RelatedRequirements) { $existing[0].related_requirements = Convert-ToCleanArray $RelatedRequirements }
        } else {
            $newG = [PSCustomObject]@{
                goal_id = $GoalId
                description = $Description
                category = if ($Domain) { $Domain } else { "GENERAL" }
                priority = if ($Priority) { $Priority } else { "P1_HIGH" }
                status = "ACTIVE"
                related_requirements = Convert-ToCleanArray $RelatedRequirements
            }
            $st.goals = @($st.goals) + $newG
        }
        $st.session.current_goal = $GoalId
        $st.session.status = "IN_PROGRESS"
        Save-InterviewState -State $st
        Write-Host "[OK] Recorded Goal: $GoalId" -ForegroundColor Green
    }

    "record-question" {
        if (-not $QuestionId -or -not $Text -or -not $Reason) {
            throw "QuestionId, Text, and Reason are mandatory."
        }
        $st = Get-InterviewState

        # Real repetition check (DIFF-03)
        $cleanText = $Text.Trim().ToLower() -replace '\s+', ' '
        $matchingQ = @($st.questions | Where-Object {
            $existingText = $_.question_text.Trim().ToLower() -replace '\s+', ' '
            $existingText -eq $cleanText
        })

        if ($matchingQ.Count -gt 0) {
            $priorQ = $matchingQ[0]
            if (-not $AllowRepeat) {
                throw "[REPETITION_REJECTED] Question identical to '$($priorQ.question_id)' was already recorded (Status: $($priorQ.status)). Repeating questions requires explicit justification under R7. Pass -AllowRepeat -Reason '<detailed reason>'."
            }
            if ([string]::IsNullOrWhiteSpace($Reason)) {
                throw "[REPETITION_REJECTED] -AllowRepeat requires a valid non-empty -Reason explaining why repetition is necessary under R7."
            }
            Write-Warning "[REPETITION_ALLOWED] Question '$QuestionId' re-asking '$($priorQ.question_id)' with justification: $Reason"
        }

        $newQ = [PSCustomObject]@{
            question_id = $QuestionId
            question_text = $Text
            question_reason = $Reason
            domain = if ($Domain) { $Domain } else { "GENERAL" }
            related_goal_ids = Convert-ToCleanArray $GoalIds
            related_decision_ids = Convert-ToCleanArray $DecisionIds
            expected_information = if ($ExpectedInfo) { $ExpectedInfo } else { "" }
            priority = if ($Priority) { $Priority } else { "MEDIUM" }
            status = "ASKED"
            asked_at = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
            repetition = if ($matchingQ.Count -gt 0) {
                [PSCustomObject]@{
                    is_repeated = $true
                    prior_question_id = $matchingQ[0].question_id
                    justification = $Reason
                }
            } else { $null }
        }
        $st.questions = @($st.questions | Where-Object { $_.question_id -ne $QuestionId }) + $newQ
        Save-InterviewState -State $st
        Write-Host "[OK] Recorded Question: $QuestionId" -ForegroundColor Green
    }

    "record-answer" {
        if (-not $AnswerId -or -not $Answer) {
            throw "AnswerId and Answer are mandatory."
        }
        $st = Get-InterviewState

        $q = @()
        if ($QuestionId) {
            $q = @($st.questions | Where-Object { $_.question_id -eq $QuestionId })
        }

        # Orphan Answer Prevention (DIFF-04)
        if ($q.Count -eq 0) {
            if (-not $Spontaneous -and $Type -ne "SPONTANEOUS_INFO") {
                throw "[ORPHAN_ANSWER_REJECTED] QuestionId '$QuestionId' does not exist in interview state. To record unsolicited user information, pass -Spontaneous."
            }
            $ansType = "SPONTANEOUS_INFO"
            $ansSource = "USER_SPONTANEOUS"
            $effQId = if ($QuestionId) { $QuestionId } else { "SPONTANEOUS-$AnswerId" }

            # Create synthetic question to prevent referential breakage
            $synthQ = [PSCustomObject]@{
                question_id = $effQId
                question_text = "[Spontaneous user contribution] $Answer"
                question_reason = "Unsolicited user input captured spontaneously"
                domain = if ($Domain) { $Domain } else { "GENERAL" }
                related_goal_ids = Convert-ToCleanArray $GoalIds
                related_decision_ids = Convert-ToCleanArray $DecisionIds
                expected_information = "Unsolicited info"
                priority = "MEDIUM"
                status = "ANSWERED"
                asked_at = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
            }
            $st.questions = @($st.questions | Where-Object { $_.question_id -ne $effQId }) + $synthQ
        } else {
            $q[0].status = "ANSWERED"
            $ansType = if ($Type) { $Type } else { "CLEAR" }
            $ansSource = if ($Source) { $Source } else { "USER_EXPLICIT" }
            $effQId = $QuestionId
        }

        $newA = [PSCustomObject]@{
            answer_id = $AnswerId
            question_id = $effQId
            original_answer = $Answer
            interpreted_answer = if ($Interpreted) { $Interpreted } else { $Answer }
            answer_type = $ansType
            answer_source = $ansSource
            confidence = if ($Confidence) { $Confidence } else { "HIGH" }
            recorded_at = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
        }
        $st.answers = @($st.answers | Where-Object { $_.answer_id -ne $AnswerId }) + $newA
        Save-InterviewState -State $st
        Write-Host "[OK] Recorded Answer: $AnswerId (Type: $ansType, Source: $ansSource)" -ForegroundColor Green
    }

    "record-decision" {
        if (-not $DecisionId -or -not $Description -or -not $SelectedOption) {
            throw "DecisionId, Description, and SelectedOption are mandatory."
        }
        $validStatuses = @("PROPOSED", "APPROVED", "REJECTED", "DEFERRED")
        $appStatus = if ($ApprovalStatus) { $ApprovalStatus.ToUpper() } else { "PROPOSED" }
        if ($validStatuses -notcontains $appStatus) {
            throw "Invalid decision ApprovalStatus '$ApprovalStatus'. Valid: $($validStatuses -join ', ')"
        }

        $st = Get-InterviewState
        $newD = [PSCustomObject]@{
            decision_id = $DecisionId
            description = $Description
            available_options = if ($Options) { Convert-ToCleanArray $Options } else { @($SelectedOption) }
            selected_option = $SelectedOption
            decision_owner = if ($Owner) { $Owner } else { "USER_PO" }
            approval_status = $appStatus
            evidence_refs = Convert-ToCleanArray $EvidenceRefs
            related_requirements = Convert-ToCleanArray $RelatedRequirements
        }
        $st.decisions = @($st.decisions | Where-Object { $_.decision_id -ne $DecisionId }) + $newD
        Save-InterviewState -State $st
        Write-Host "[OK] Recorded Decision: $DecisionId (Status: $appStatus)" -ForegroundColor Green
    }

    "record-assumption" {
        if (-not $AssumptionId -or -not $Description -or -not $Rationale) {
            throw "AssumptionId, Description, and Rationale are mandatory."
        }
        $validStatuses = @("PENDING_APPROVAL", "APPROVED", "REJECTED")
        $appStatus = if ($ApprovalStatus) { $ApprovalStatus.ToUpper() } else { "PENDING_APPROVAL" }
        if ($appStatus -eq "PROPOSED") {
            $appStatus = "PENDING_APPROVAL"
        }
        if ($validStatuses -notcontains $appStatus) {
            throw "Invalid assumption ApprovalStatus '$ApprovalStatus'. Valid: $($validStatuses -join ', ')"
        }

        $st = Get-InterviewState
        $newAs = [PSCustomObject]@{
            assumption_id = $AssumptionId
            description = $Description
            rationale = $Rationale
            impact = if ($Impact) { $Impact } else { "Low" }
            risk_level = if ($RiskLevel) { $RiskLevel } else { "BENIGN" }
            approval_status = $appStatus
            verification_task = if ($VerificationTask) { $VerificationTask } else { "Verify during Step 10 QA" }
            status = "ACTIVE"
            invalidated_at = $null
            revocation_reason = $null
            downstream_dependencies = Convert-ToCleanArray $DownstreamDeps
        }
        $st.assumptions = @($st.assumptions | Where-Object { $_.assumption_id -ne $AssumptionId }) + $newAs
        Save-InterviewState -State $st
        Write-Host "[OK] Recorded Assumption: $AssumptionId (Status: $appStatus, Risk: $($newAs.risk_level))" -ForegroundColor Green
    }

    "record-unknown" {
        if (-not $UnknownId -or -not $Description) {
            throw "UnknownId and Description are mandatory."
        }
        $validPriorities = @("CRITICAL", "HIGH", "MEDIUM", "LOW", "BENIGN")
        $prio = if ($Priority) { $Priority.ToUpper() } else { "MEDIUM" }
        if ($validPriorities -notcontains $prio) {
            throw "Invalid unknown Priority '$Priority'. Valid: $($validPriorities -join ', ')"
        }
        $validStatuses = @("OPEN", "RESOLVED", "DEFERRED")
        $unkStatus = if ($Status) { $Status.ToUpper() } else { "OPEN" }
        if ($validStatuses -notcontains $unkStatus) {
            throw "Invalid unknown Status '$Status'. Valid: $($validStatuses -join ', ')"
        }

        $st = Get-InterviewState
        $newUnk = [PSCustomObject]@{
            unknown_id = $UnknownId
            description = $Description
            impact = if ($Impact) { $Impact } else { "Unassessed" }
            priority = $prio
            status = $unkStatus
            resolution_strategy = if ($ResolutionStrategy) { $ResolutionStrategy } else { "TBD" }
        }
        $st.unknowns = @($st.unknowns | Where-Object { $_.unknown_id -ne $UnknownId }) + $newUnk
        Save-InterviewState -State $st
        Write-Host "[OK] Recorded Unknown: $UnknownId (Priority: $prio, Status: $unkStatus)" -ForegroundColor Green
    }

    "record-conflict" {
        if (-not $ConflictId -or -not $Explanation) {
            throw "ConflictId and Explanation are mandatory."
        }
        $st = Get-InterviewState
        $newC = [PSCustomObject]@{
            conflict_id = $ConflictId
            conflicting_items = Convert-ToCleanArray $ConflictingItems
            explanation = $Explanation
            severity = if ($Severity) { $Severity } else { "MAJOR" }
            resolution_status = "UNRESOLVED"
            resolution_strategy = if ($ResolutionStrategy) { $ResolutionStrategy } else { $null }
            resolved_at = $null
        }
        $st.conflicts = @($st.conflicts | Where-Object { $_.conflict_id -ne $ConflictId }) + $newC
        Save-InterviewState -State $st
        Write-Host "[!] Recorded Conflict: $ConflictId (Severity: $($newC.severity))" -ForegroundColor Yellow
    }

    "resolve-conflict" {
        if (-not $ConflictId -or -not $ResolutionStrategy) {
            throw "ConflictId and ResolutionStrategy are mandatory."
        }
        $st = Get-InterviewState
        $c = @($st.conflicts | Where-Object { $_.conflict_id -eq $ConflictId })
        if ($c.Count -gt 0) {
            $c[0].resolution_status = "RESOLVED"
            $c[0].resolution_strategy = $ResolutionStrategy
            $c[0].resolved_at = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
            Save-InterviewState -State $st
            Write-Host "[OK] Resolved Conflict: $ConflictId" -ForegroundColor Green
        } else {
            Write-Warning "Conflict $ConflictId not found."
        }
    }

    "record-scope-change" {
        if (-not $ChangeId -or -not $PreviousScope -or -not $NewScope) {
            throw "ChangeId, PreviousScope, and NewScope are mandatory."
        }
        $st = Get-InterviewState
        $newSC = [PSCustomObject]@{
            change_id = $ChangeId
            previous_scope = $PreviousScope
            new_scope = $NewScope
            affected_decisions = Convert-ToCleanArray $DecisionIds
            affected_requirements = Convert-ToCleanArray $RelatedRequirements
            recorded_at = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
        }
        $st.scope_changes = @($st.scope_changes | Where-Object { $_.change_id -ne $ChangeId }) + $newSC
        Save-InterviewState -State $st
        Write-Host "[OK] Recorded Scope Change: $ChangeId" -ForegroundColor Green
    }

    "evaluate-sufficiency" {
        $st = Get-InterviewState
        $blocking = @()
        $deferred = @()
        $goalEvals = @()

        # 1. Check Unresolved Conflicts (DIFF-01 Test 05)
        $unresolvedConflicts = @($st.conflicts | Where-Object { $_.resolution_status -ne "RESOLVED" -and ($_.severity -eq "CRITICAL" -or $_.severity -eq "MAJOR") })
        if ($unresolvedConflicts.Count -gt 0) {
            foreach ($c in $unresolvedConflicts) {
                $blocking += "Unresolved $($c.severity) Conflict: $($c.conflict_id) - $($c.explanation)"
            }
        }

        # 2. Check Critical Assumptions Unapproved
        $criticalAssumptions = @($st.assumptions | Where-Object { $_.status -eq "ACTIVE" -and $_.risk_level -eq "CRITICAL" -and $_.approval_status -ne "APPROVED" })
        if ($criticalAssumptions.Count -gt 0) {
            foreach ($a in $criticalAssumptions) {
                $blocking += "Critical assumption requires user approval: $($a.assumption_id) - $($a.description)"
            }
        }

        # 3. Check Critical/High Unknowns Unresolved (DIFF-01 Test 03)
        $blockingUnknowns = @($st.unknowns | Where-Object { ($_.status -eq "OPEN" -or -not $_.status) -and ($_.priority -eq "CRITICAL" -or $_.priority -eq "HIGH") })
        if ($blockingUnknowns.Count -gt 0) {
            foreach ($u in $blockingUnknowns) {
                $blocking += "Important unresolved unknown ($($u.priority)): $($u.unknown_id) - $($u.description)"
            }
        }

        # 4. Check Goals Resolution (DIFF-01 Tests 01, 02, 04, 06)
        $activeGoals = @($st.goals | Where-Object { $_.status -ne "ACHIEVED" -and $_.status -ne "ABANDONED" })
        if ($activeGoals.Count -eq 0) {
            $blocking += "No active goals recorded in interview state."
        } else {
            foreach ($g in $activeGoals) {
                $gId = $g.goal_id
                $gBlockers = @()

                # Check Goal clarity
                if ([string]::IsNullOrWhiteSpace($g.description)) {
                    $gBlockers += "Goal $gId has empty description."
                }

                # Find matching decisions
                $matchingDecisions = @($st.decisions | Where-Object {
                    $_.related_requirements -contains $gId -or
                    $_.description -match [regex]::Escape($gId) -or
                    $g.related_requirements -contains $_.decision_id
                })

                # Find pending questions
                $pendingQ = @($st.questions | Where-Object {
                    $_.related_goal_ids -contains $gId -and $_.status -ne "ANSWERED"
                })

                if ($pendingQ.Count -gt 0) {
                    foreach ($pq in $pendingQ) {
                        $gBlockers += "Goal $gId has unanswered question: $($pq.question_id) ('$($pq.question_text)')"
                    }
                }

                # Status evaluation for this goal
                $gStatus = "NEEDS_INPUT"
                $approvedDecs = @($matchingDecisions | Where-Object { $_.approval_status -eq "APPROVED" })
                $deferredDecs = @($matchingDecisions | Where-Object { $_.approval_status -eq "DEFERRED" })
                $proposedDecs = @($matchingDecisions | Where-Object { $_.approval_status -eq "PROPOSED" })
                $rejectedDecs = @($matchingDecisions | Where-Object { $_.approval_status -eq "REJECTED" })

                if ($matchingDecisions.Count -eq 0) {
                    # Test 01: Goal without decision and without questions must NOT pass
                    $gBlockers += "Goal $gId has no resolving decision recorded."
                    $gStatus = "NEEDS_INPUT"
                } elseif ($rejectedDecs.Count -gt 0) {
                    $gBlockers += "Goal $gId is linked to REJECTED decision $($rejectedDecs[0].decision_id)."
                    $gStatus = "BLOCKED"
                } elseif ($proposedDecs.Count -gt 0 -and $approvedDecs.Count -eq 0 -and $deferredDecs.Count -eq 0) {
                    # Test 02: PROPOSED Decision must not count as approved
                    $gBlockers += "Goal $gId decision $($proposedDecs[0].decision_id) remains PROPOSED (requires user approval)."
                    $gStatus = "NEEDS_INPUT"
                } elseif ($deferredDecs.Count -gt 0 -and $approvedDecs.Count -eq 0) {
                    # Test 04: Properly deferred non-critical decision
                    $gStatus = "DEFERRED"
                } elseif ($approvedDecs.Count -gt 0) {
                    $gStatus = "RESOLVED"
                }

                # Check if resolved by approved assumption
                $matchingAssumptions = @($st.assumptions | Where-Object {
                    $_.downstream_dependencies -contains $gId -or $_.description -match [regex]::Escape($gId)
                })
                $approvedAssumptions = @($matchingAssumptions | Where-Object { $_.approval_status -eq "APPROVED" })
                if ($approvedAssumptions.Count -gt 0 -and $gStatus -ne "RESOLVED") {
                    $gStatus = "ASSUMED_WITH_APPROVAL"
                }

                if ($gBlockers.Count -gt 0) {
                    $blocking += $gBlockers
                    if ($gStatus -eq "RESOLVED") { $gStatus = "BLOCKED" }
                }

                # Update goal status in state
                $g.status = $gStatus

                $goalEvals += [PSCustomObject]@{
                    goal_id = $gId
                    status = $gStatus
                    decision_ids = @($matchingDecisions | ForEach-Object { $_.decision_id })
                    pending_questions = @($pendingQ | ForEach-Object { $_.question_id })
                    blocking_reasons = $gBlockers
                }
            }
        }

        # 5. Check Decisions Approval Status
        $unapprovedDecisions = @($st.decisions | Where-Object { $_.approval_status -eq "REJECTED" })
        if ($unapprovedDecisions.Count -gt 0) {
            foreach ($d in $unapprovedDecisions) {
                $blocking += "Rejected decision requires resolution: $($d.decision_id)"
            }
        }

        # 6. Collect Deferred Decisions
        $deferredDecisions = @($st.decisions | Where-Object { $_.approval_status -eq "DEFERRED" })
        foreach ($dd in $deferredDecisions) {
            $deferred += "$($dd.decision_id): $($dd.description)"
        }

        # Calculate Final Verdict
        $verdict = "SUFFICIENT"
        $summary = "All active goals, decisions, and assumptions meet the Exit Gate criteria. Ready for Spec Freeze."

        if ($blocking.Count -gt 0) {
            if ($unresolvedConflicts.Count -gt 0 -or $criticalAssumptions.Count -gt 0 -or $blockingUnknowns.Count -gt 0 -or (@($goalEvals | Where-Object { $_.status -eq "BLOCKED" }).Count -gt 0)) {
                $verdict = "BLOCKED"
                $summary = "Interview is BLOCKED by unresolved conflicts, critical unknowns, or unapproved critical assumptions."
            } else {
                $verdict = "NEEDS_INPUT"
                $summary = "Interview requires additional input, question responses, or decision approval before Gate 03."
            }
        }

        $now = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
        $benignCount = @($st.assumptions | Where-Object { $_.status -eq "ACTIVE" -and $_.risk_level -eq "BENIGN" }).Count
        $critCount = @($st.assumptions | Where-Object { $_.status -eq "ACTIVE" -and $_.risk_level -eq "CRITICAL" }).Count
        $pendingAppr = @($st.assumptions | Where-Object { $_.status -eq "ACTIVE" -and $_.approval_status -eq "PENDING_APPROVAL" }).Count

        $st.sufficiency_evaluation = [PSCustomObject]@{
            verdict = $verdict
            evaluated_at = $now
            goal_evaluations = $goalEvals
            blocking_reasons = $blocking
            deferred_decisions = $deferred
            assumptions_summary = [PSCustomObject]@{
                total = @($st.assumptions | Where-Object { $_.status -eq "ACTIVE" }).Count
                benign = $benignCount
                critical = $critCount
                pending_approval = $pendingAppr
            }
            summary = $summary
        }

        if ($verdict -eq "SUFFICIENT") {
            $st.session.status = "SUFFICIENT"
        } elseif ($verdict -eq "BLOCKED") {
            $st.session.status = "BLOCKED"
        } else {
            $st.session.status = "IN_PROGRESS"
        }

        Save-InterviewState -State $st

        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host "  INTERVIEW EXIT GATE SUFFICIENCY EVALUATION" -ForegroundColor Cyan
        Write-Host "============================================================" -ForegroundColor Cyan
        $color = if ($verdict -eq "SUFFICIENT") { "Green" } elseif ($verdict -eq "BLOCKED") { "Red" } else { "Yellow" }
        Write-Host "VERDICT: $verdict" -ForegroundColor $color
        Write-Host "Summary: $summary"
        if ($blocking.Count -gt 0) {
            Write-Host "Blocking items ($($blocking.Count)):" -ForegroundColor Yellow
            foreach ($b in $blocking) {
                Write-Host "  - $b"
            }
        }
        if ($deferred.Count -gt 0) {
            Write-Host "Deferred items ($($deferred.Count)):" -ForegroundColor Cyan
            foreach ($d in $deferred) {
                Write-Host "  - $d"
            }
        }
        Write-Host "============================================================" -ForegroundColor Cyan

        if ($verdict -eq "SUFFICIENT") {
            exit 0
        } elseif ($verdict -eq "NEEDS_INPUT") {
            exit 1
        } else {
            exit 2
        }
    }

    "validate" {
        $st = Get-InterviewState
        if (-not $st.session -or -not $st.session.session_id) {
            throw "Invalid interview state: missing session"
        }

        $errors = @()
        $gIds = @($st.goals | ForEach-Object { $_.goal_id })
        $qIds = @($st.questions | ForEach-Object { $_.question_id })
        $dIds = @($st.decisions | ForEach-Object { $_.decision_id })

        # Questions referential integrity
        foreach ($q in $st.questions) {
            if ($q.related_goal_ids) {
                foreach ($gid in @($q.related_goal_ids)) {
                    if (-not [string]::IsNullOrWhiteSpace($gid) -and $gIds -notcontains $gid) {
                        $errors += "Question '$($q.question_id)' references non-existent goal '$gid'."
                    }
                }
            }
            if ($q.related_decision_ids) {
                foreach ($did in @($q.related_decision_ids)) {
                    if (-not [string]::IsNullOrWhiteSpace($did) -and $dIds -notcontains $did) {
                        $errors += "Question '$($q.question_id)' references non-existent decision '$did'."
                    }
                }
            }
        }

        # Answers referential integrity
        foreach ($a in $st.answers) {
            if ($a.question_id -and -not [string]::IsNullOrWhiteSpace($a.question_id) -and $qIds -notcontains $a.question_id -and $a.answer_type -ne "SPONTANEOUS_INFO") {
                $errors += "Answer '$($a.answer_id)' references non-existent question '$($a.question_id)'."
            }
        }

        # Decisions referential integrity
        foreach ($d in $st.decisions) {
            if ($d.related_requirements) {
                foreach ($req in @($d.related_requirements)) {
                    if (-not [string]::IsNullOrWhiteSpace($req) -and $gIds -notcontains $req -and -not ($req -match '^(REQ-|NF-|G-)')) {
                        # Non-fatal notice for external req tags
                    }
                }
            }
        }

        if ($errors.Count -gt 0) {
            Write-Host "============================================================" -ForegroundColor Red
            Write-Host "  INTERVIEW STATE REFERENTIAL INTEGRITY ERRORS ($($errors.Count))" -ForegroundColor Red
            Write-Host "============================================================" -ForegroundColor Red
            foreach ($err in $errors) {
                Write-Host "  [X] $err" -ForegroundColor Red
            }
            exit 1
        }

        Write-Host "[PASS] Interview state is structurally valid and referentially intact." -ForegroundColor Green
        exit 0
    }
}
