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
    [ValidateSet("init", "status", "record-goal", "record-question", "record-answer", "record-decision", "record-assumption", "record-conflict", "resolve-conflict", "record-scope-change", "evaluate-sufficiency", "validate")]
    [string]$Action,

    [Parameter(Mandatory = $false)]
    [string]$CaseId,

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
    [string]$ApprovalStatus = "PROPOSED",

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
    [string]$Priority = "MEDIUM"
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
    if ($null -eq $inputVal) { return @() }
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
    return $result
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
            $caseObj.interview.active_goals_count = @($State.goals | Where-Object { $_.status -eq "ACTIVE" }).Count
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
        $cId = if ($CaseId) { $CaseId } else { "CASE-INITIAL" }
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
        Write-Host "Status:               $($st.session.status)"
        Write-Host "Active Domain:        $(if ($st.session.active_domain) { $st.session.active_domain } else { 'NONE' })"
        Write-Host "Design Mode:          $(if ($st.session.design_mode) { $st.session.design_mode } else { 'UNSET' })"
        Write-Host "Sufficiency Verdict:  $($st.sufficiency_evaluation.verdict)"
        Write-Host "------------------------------------------------------------"
        Write-Host "Goals Total:          $(@($st.goals).Count) (Active: $(@($st.goals | Where-Object { $_.status -eq 'ACTIVE' }).Count))"
        Write-Host "Questions Total:      $(@($st.questions).Count) (Asked: $(@($st.questions | Where-Object { $_.status -eq 'ASKED' }).Count), Answered: $(@($st.questions | Where-Object { $_.status -eq 'ANSWERED' }).Count))"
        Write-Host "Decisions Total:      $(@($st.decisions).Count) (Approved: $(@($st.decisions | Where-Object { $_.approval_status -eq 'APPROVED' }).Count))"
        Write-Host "Assumptions Total:    $(@($st.assumptions).Count) (Critical: $(@($st.assumptions | Where-Object { $_.risk_level -eq 'CRITICAL' -and $_.status -eq 'ACTIVE' }).Count))"
        Write-Host "Conflicts Total:      $(@($st.conflicts).Count) (Unresolved: $(@($st.conflicts | Where-Object { $_.resolution_status -ne 'RESOLVED' }).Count))"
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

        # Repetition check (R7)
        $sameText = @($st.questions | Where-Object { $_.question_text.Trim().ToLower() -eq $Text.Trim().ToLower() })
        if ($sameText.Count -gt 0 -and $sameText[0].status -eq "ANSWERED") {
            Write-Warning "[REPETITION_ALERT] Question identical to $($sameText[0].question_id) was already answered. Ensure this repetition meets R7 criteria (recorded in Reason)."
            Write-Host "[REPETITION_ALERT] Question identical to $($sameText[0].question_id) was already answered." -ForegroundColor Yellow
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
        }
        $st.questions = @($st.questions | Where-Object { $_.question_id -ne $QuestionId }) + $newQ
        Save-InterviewState -State $st
        Write-Host "[OK] Recorded Question: $QuestionId" -ForegroundColor Green
    }

    "record-answer" {
        if (-not $AnswerId -or -not $QuestionId -or -not $Answer) {
            throw "AnswerId, QuestionId, and Answer are mandatory."
        }
        $st = Get-InterviewState

        # Update question status
        $q = @($st.questions | Where-Object { $_.question_id -eq $QuestionId })
        if ($q.Count -gt 0) {
            $q[0].status = "ANSWERED"
        }

        $ansType = if ($Type) { $Type } else { "CLEAR" }
        $newA = [PSCustomObject]@{
            answer_id = $AnswerId
            question_id = $QuestionId
            original_answer = $Answer
            interpreted_answer = if ($Interpreted) { $Interpreted } else { $Answer }
            answer_type = $ansType
            answer_source = if ($Source) { $Source } else { "USER_EXPLICIT" }
            confidence = if ($Confidence) { $Confidence } else { "HIGH" }
            recorded_at = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
        }
        $st.answers = @($st.answers | Where-Object { $_.answer_id -ne $AnswerId }) + $newA
        Save-InterviewState -State $st
        Write-Host "[OK] Recorded Answer: $AnswerId (Type: $ansType)" -ForegroundColor Green
    }

    "record-decision" {
        if (-not $DecisionId -or -not $Description -or -not $SelectedOption) {
            throw "DecisionId, Description, and SelectedOption are mandatory."
        }
        $st = Get-InterviewState
        $newD = [PSCustomObject]@{
            decision_id = $DecisionId
            description = $Description
            available_options = if ($Options) { Convert-ToCleanArray $Options } else { @($SelectedOption) }
            selected_option = $SelectedOption
            decision_owner = if ($Owner) { $Owner } else { "USER_PO" }
            approval_status = if ($ApprovalStatus) { $ApprovalStatus } else { "PROPOSED" }
            evidence_refs = Convert-ToCleanArray $EvidenceRefs
            related_requirements = Convert-ToCleanArray $RelatedRequirements
        }
        $st.decisions = @($st.decisions | Where-Object { $_.decision_id -ne $DecisionId }) + $newD
        Save-InterviewState -State $st
        Write-Host "[OK] Recorded Decision: $DecisionId (Status: $($newD.approval_status))" -ForegroundColor Green
    }

    "record-assumption" {
        if (-not $AssumptionId -or -not $Description -or -not $Rationale) {
            throw "AssumptionId, Description, and Rationale are mandatory."
        }
        $st = Get-InterviewState
        $newAs = [PSCustomObject]@{
            assumption_id = $AssumptionId
            description = $Description
            rationale = $Rationale
            impact = if ($Impact) { $Impact } else { "Low" }
            risk_level = if ($RiskLevel) { $RiskLevel } else { "BENIGN" }
            approval_status = if ($ApprovalStatus) { $ApprovalStatus } else { "APPROVED" }
            verification_task = if ($VerificationTask) { $VerificationTask } else { "Verify during Step 10 QA" }
            status = "ACTIVE"
            invalidated_at = $null
            revocation_reason = $null
            downstream_dependencies = Convert-ToCleanArray $DownstreamDeps
        }
        $st.assumptions = @($st.assumptions | Where-Object { $_.assumption_id -ne $AssumptionId }) + $newAs
        Save-InterviewState -State $st
        Write-Host "[OK] Recorded Assumption: $AssumptionId (Risk: $($newAs.risk_level))" -ForegroundColor Green
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

        # 1. Check Unresolved Conflicts
        $unresolvedConflicts = @($st.conflicts | Where-Object { $_.resolution_status -eq "UNRESOLVED" -and ($_.severity -eq "CRITICAL" -or $_.severity -eq "MAJOR") })
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

        # 3. Check Goals Resolution
        $activeGoals = @($st.goals | Where-Object { $_.status -eq "ACTIVE" })
        if ($activeGoals.Count -eq 0) {
            $blocking += "No active goals recorded in interview state."
        } else {
            foreach ($g in $activeGoals) {
                # Find matching decisions
                $matchingDecisions = @($st.decisions | Where-Object {
                    $_.related_requirements -contains $g.goal_id -or $_.description -match [regex]::Escape($g.goal_id)
                })
                if ($matchingDecisions.Count -eq 0) {
                    # Check if questions are pending
                    $pendingQ = @($st.questions | Where-Object { $_.related_goal_ids -contains $g.goal_id -and $_.status -ne "ANSWERED" })
                    if ($pendingQ.Count -gt 0) {
                        $blocking += "Goal $($g.goal_id) has unanswered question: $($pendingQ[0].question_id)"
                    }
                }
            }
        }

        # 4. Check Decisions Approval Status
        $unapprovedDecisions = @($st.decisions | Where-Object { $_.approval_status -eq "REJECTED" })
        if ($unapprovedDecisions.Count -gt 0) {
            foreach ($d in $unapprovedDecisions) {
                $blocking += "Rejected decision requires resolution: $($d.decision_id)"
            }
        }
        $deferredDecisions = @($st.decisions | Where-Object { $_.approval_status -eq "DEFERRED" })
        foreach ($dd in $deferredDecisions) {
            $deferred += "$($dd.decision_id): $($dd.description)"
        }

        # Calculate Verdict
        $verdict = "SUFFICIENT"
        $summary = "All active goals, decisions, and assumptions meet the Exit Gate criteria. Ready for Spec Freeze."

        if ($blocking.Count -gt 0) {
            # Check if blocked by conflicts or unapproved critical items
            if ($unresolvedConflicts.Count -gt 0 -or $criticalAssumptions.Count -gt 0) {
                $verdict = "BLOCKED"
                $summary = "Interview is BLOCKED by unresolved conflicts or unapproved critical assumptions."
            } else {
                $verdict = "NEEDS_INPUT"
                $summary = "Interview requires additional input or decision resolution before Gate 03."
            }
        }

        $now = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
        $benignCount = @($st.assumptions | Where-Object { $_.status -eq "ACTIVE" -and $_.risk_level -eq "BENIGN" }).Count
        $critCount = @($st.assumptions | Where-Object { $_.status -eq "ACTIVE" -and $_.risk_level -eq "CRITICAL" }).Count
        $pendingAppr = @($st.assumptions | Where-Object { $_.status -eq "ACTIVE" -and $_.approval_status -eq "PENDING_APPROVAL" }).Count

        $st.sufficiency_evaluation = [PSCustomObject]@{
            verdict = $verdict
            evaluated_at = $now
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
        Write-Host "[PASS] Interview state is structurally valid." -ForegroundColor Green
        exit 0
    }
}
