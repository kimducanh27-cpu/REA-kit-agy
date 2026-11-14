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
    [switch]$Supersede,

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
    [string]$Justification,

    [Parameter(Mandatory = $false)]
    [string]$Domain,

    [Parameter(Mandatory = $false)]
    [string]$ExpectedInfo,

    [Parameter(Mandatory = $false)]
    [string]$TopicKey,

    [Parameter(Mandatory = $false)]
    [string]$Answer,

    [Parameter(Mandatory = $false)]
    [string]$Interpreted,

    [Parameter(Mandatory = $false)]
    [ValidateSet("CLEAR", "PARTIAL", "AMBIGUOUS", "UNKNOWN", "CONDITIONAL", "MULTIPLE_CHOICE", "CONFLICTING", "OUT_OF_SCOPE", "NEW_REQUIREMENT", "SCOPE_CHANGE", "SPONTANEOUS_INFO", "DELEGATED_CHOICE")]
    [string]$Type,

    [Parameter(Mandatory = $false)]
    [ValidateSet("USER_EXPLICIT", "REPO_EVIDENCE", "DERIVED", "USER_SPONTANEOUS")]
    [string]$Source = "USER_EXPLICIT",

    [Parameter(Mandatory = $false)]
    [ValidateSet("HIGH", "MEDIUM", "LOW")]
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
    [string]$Approval,

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
    [ValidateSet("P0_CRITICAL", "P1_HIGH", "P2_MEDIUM", "P3_LOW", "CRITICAL", "HIGH", "MEDIUM", "LOW", "BENIGN")]
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
    if (-not (Test-Path -LiteralPath $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    for ($attempt = 1; $attempt -le 10; $attempt++) {
        $tmpFile = [System.IO.Path]::Combine($destDir, ([System.IO.Path]::GetRandomFileName() + ".tmp"))
        try {
            [System.IO.File]::WriteAllText($tmpFile, $Content, $utf8NoBom)
            if (Test-Path -LiteralPath $destFull) {
                try {
                    [System.IO.File]::Replace($tmpFile, $destFull, $null)
                } catch {
                    Move-Item -LiteralPath $tmpFile -Destination $destFull -Force
                }
            } else {
                Move-Item -LiteralPath $tmpFile -Destination $destFull -Force
            }
            break
        } catch [System.IO.IOException], [System.UnauthorizedAccessException] {
            if (Test-Path -LiteralPath $tmpFile) {
                Remove-Item -LiteralPath $tmpFile -Force -ErrorAction SilentlyContinue
            }
            if ($attempt -eq 10) { throw }
            Start-Sleep -Milliseconds (50 * $attempt)
        } finally {
            if (Test-Path -LiteralPath $tmpFile) {
                Remove-Item -LiteralPath $tmpFile -Force -ErrorAction SilentlyContinue
            }
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
                max_clarification_per_goal = 2
                max_total_questions = 15
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

        # Duplicate QuestionId check (DIFF-05)
        $cleanText = $Text.Trim().ToLower() -replace '\s+', ' '
        $existingQ = @($st.questions | Where-Object { $_.question_id -eq $QuestionId })
        if ($existingQ.Count -gt 0) {
            $priorQWithId = $existingQ[0]
            $priorText = $priorQWithId.question_text.Trim().ToLower() -replace '\s+', ' '
            if ($priorText -ne $cleanText) {
                if (-not $Force -and -not $Supersede) {
                    throw "[DUPLICATE_QUESTION_ID_REJECTED] QuestionId '$QuestionId' already exists in interview state with different text ('$($priorQWithId.question_text)'). Overwriting question history is rejected to prevent silent data loss. Pass -Force or -Supersede to override."
                }
                Write-Warning "[QUESTION_SUPERSEDED] Overwriting QuestionId '$QuestionId' (Prior text: '$($priorQWithId.question_text)') due to -Force/-Supersede flag."
            }
        }

        # TopicKey duplicate check on (domain, topic_key)
        $targetDomain = if ($Domain) { $Domain } else { "GENERAL" }
        if (-not [string]::IsNullOrWhiteSpace($TopicKey)) {
            $cleanTopicKey = $TopicKey.Trim().ToLower()
            $matchingTopicQ = @($st.questions | Where-Object {
                $_.question_id -ne $QuestionId -and
                $_.domain -eq $targetDomain -and
                $_.PSObject.Properties['topic_key'] -and
                $_.topic_key -and
                ($_.topic_key.Trim().ToLower() -eq $cleanTopicKey)
            })
            if ($matchingTopicQ.Count -gt 0) {
                if (-not $Force -and -not $Supersede) {
                    throw "[DUPLICATE_TOPIC_KEY_REJECTED] Question with topic_key '$TopicKey' in domain '$targetDomain' already exists in interview state (QuestionId: '$($matchingTopicQ[0].question_id)'). Rejecting duplicate topic to avoid redundancy. Pass -Force or -Supersede to override."
                }
                Write-Warning "[TOPIC_KEY_SUPERSEDED] Overwriting topic '$TopicKey' in domain '$targetDomain' (Prior question: '$($matchingTopicQ[0].question_id)') due to -Force/-Supersede flag."
            }
        }

        # Session limits enforcement
        $maxTotalQ = if ($st.session.PSObject.Properties['max_total_questions'] -and $st.session.max_total_questions) { [int]$st.session.max_total_questions } else { 15 }
        $maxClarification = if ($st.session.PSObject.Properties['max_clarification_per_goal'] -and $st.session.max_clarification_per_goal) { [int]$st.session.max_clarification_per_goal } else { 2 }

        $isNewQuestion = ($existingQ.Count -eq 0)
        if ($isNewQuestion -and @($st.questions).Count -ge $maxTotalQ) {
            if (-not $Force) {
                throw "[SESSION_LIMIT_EXCEEDED] Maximum total questions limit ($maxTotalQ) reached for this interview session. Further questions rejected; auto-delegate Two-Way Door decisions to Assumption Record or mark BLOCKED. Pass -Force to override."
            }
            Write-Warning "[SESSION_LIMIT_OVERRIDE] Exceeding maximum total questions ($maxTotalQ) due to -Force flag."
        }

        # Check clarification per goal limit
        $cleanGoalIds = Convert-ToCleanArray $GoalIds
        foreach ($gid in $cleanGoalIds) {
            $priorGoalQ = @($st.questions | Where-Object {
                $_.question_id -ne $QuestionId -and
                $_.related_goal_ids -contains $gid
            })
            if ($priorGoalQ.Count -ge $maxClarification -and $isNewQuestion) {
                if (-not $Force) {
                    throw "[GOAL_CLARIFICATION_LIMIT_EXCEEDED] Goal '$gid' has already reached the maximum clarification limit of $maxClarification questions (Asked: $($priorGoalQ.Count)). Under R5/R7, Two-Way Door decisions must be auto-delegated to Assumption Record or marked BLOCKED. Pass -Force to override."
                }
                Write-Warning "[GOAL_CLARIFICATION_OVERRIDE] Exceeding clarification limit for goal '$gid' ($($priorGoalQ.Count)/$maxClarification) due to -Force flag."
            }
        }

        # Real repetition check (DIFF-03)
        $matchingQ = @($st.questions | Where-Object {
            $_.question_id -ne $QuestionId -and
            (($_.question_text.Trim().ToLower() -replace '\s+', ' ') -eq $cleanText)
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
            domain = $targetDomain
            topic_key = if (-not [string]::IsNullOrWhiteSpace($TopicKey)) { $TopicKey } else { $null }
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
        if ([string]::IsNullOrWhiteSpace($AnswerId) -or [string]::IsNullOrWhiteSpace($Answer)) {
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
                topic_key = if ($TopicKey) { $TopicKey } else { $null }
                related_goal_ids = Convert-ToCleanArray $GoalIds
                related_decision_ids = Convert-ToCleanArray $DecisionIds
                expected_information = "Unsolicited info"
                priority = "MEDIUM"
                status = "ANSWERED"
                asked_at = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
            }
            $st.questions = @($st.questions | Where-Object { $_.question_id -ne $effQId }) + $synthQ
        } else {
            $ansType = if ($Type) { $Type } else { "CLEAR" }
            $ansSource = if ($Source) { $Source } else { "USER_EXPLICIT" }
            $effQId = $QuestionId

            # State Machine: only set ANSWERED for conclusive types; AMBIGUOUS/PARTIAL/CONFLICTING set NEEDS_CLARIFICATION
            if ($ansType -in @("CLEAR", "CONDITIONAL", "OUT_OF_SCOPE", "SPONTANEOUS_INFO", "DELEGATED_CHOICE")) {
                $q[0].status = "ANSWERED"
            } elseif ($ansType -in @("AMBIGUOUS", "PARTIAL", "CONFLICTING")) {
                $q[0].status = "NEEDS_CLARIFICATION"
            } else {
                $q[0].status = "ANSWERED"
            }
        }

        $newA = [PSCustomObject]@{
            answer_id = $AnswerId
            question_id = $effQId
            original_answer = $Answer
            interpreted_answer = if ($Interpreted) { $Interpreted } else { $Answer }
            answer_type = $ansType
            answer_source = $ansSource
            confidence = if ($Confidence) { $Confidence } else { "HIGH" }
            conflict_id = if ($ConflictId) { $ConflictId } else { $null }
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
        $existingUnk = @($st.unknowns | Where-Object { $_.unknown_id -eq $UnknownId })
        $just = if ($Justification) { $Justification } elseif ($Reason) { $Reason } elseif ($Rationale) { $Rationale } elseif ($existingUnk.Count -gt 0 -and $existingUnk[0].justification) { $existingUnk[0].justification } else { $null }
        $appr = if ($Approval) { $Approval } elseif ($ApprovalStatus) { $ApprovalStatus } elseif ($existingUnk.Count -gt 0 -and $existingUnk[0].approval) { $existingUnk[0].approval } else { $null }

        $newUnk = [PSCustomObject]@{
            unknown_id = $UnknownId
            description = $Description
            impact = if ($Impact) { $Impact } else { "Unassessed" }
            priority = $prio
            status = $unkStatus
            resolution_strategy = if ($ResolutionStrategy) { $ResolutionStrategy } else { "TBD" }
            justification = $just
            approval = $appr
            approval_status = $appr
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

        # 1.1 Check Unresolved Conflicting Answers without resolved conflict_id
        $resolvedConflictIds = @($st.conflicts | Where-Object { $_.resolution_status -eq "RESOLVED" } | ForEach-Object { $_.conflict_id })
        $unresolvedConflictingAnswers = @()
        foreach ($a in @($st.answers | Where-Object { $_.answer_type -eq "CONFLICTING" })) {
            $isResolved = $false
            if ($a.PSObject.Properties['conflict_id'] -and $a.conflict_id -and ($resolvedConflictIds -contains $a.conflict_id)) {
                $isResolved = $true
            } else {
                $matchingResConflict = @($st.conflicts | Where-Object {
                    $_.resolution_status -eq "RESOLVED" -and (
                        $_.conflicting_items -contains $a.answer_id -or
                        $_.conflicting_items -contains $a.question_id -or
                        ($a.conflict_id -and $_.conflict_id -eq $a.conflict_id)
                    )
                })
                if ($matchingResConflict.Count -gt 0) {
                    $isResolved = $true
                }
            }
            if (-not $isResolved) {
                $unresolvedConflictingAnswers += $a
                $blocking += "Unresolved CONFLICTING answer without resolved conflict_id: $($a.answer_id) (Question: $($a.question_id))"
            }
        }

        # 2. Check Critical Assumptions Unapproved
        $criticalAssumptions = @($st.assumptions | Where-Object { $_.status -eq "ACTIVE" -and $_.risk_level -eq "CRITICAL" -and $_.approval_status -ne "APPROVED" })
        if ($criticalAssumptions.Count -gt 0) {
            foreach ($a in $criticalAssumptions) {
                $blocking += "Critical assumption requires user approval: $($a.assumption_id) - $($a.description)"
            }
        }

        # 3. Check Critical/High Unknowns Unresolved & Deferred Critical Unknowns (DIFF-01 Test 03, DIFF-02)
        $openImportantUnknowns = @($st.unknowns | Where-Object { ($_.status -eq "OPEN" -or -not $_.status) -and ($_.priority -eq "CRITICAL" -or $_.priority -eq "HIGH") })
        if ($openImportantUnknowns.Count -gt 0) {
            foreach ($u in $openImportantUnknowns) {
                $blocking += "Important unresolved unknown ($($u.priority)): $($u.unknown_id) - $($u.description)"
            }
        }

        $deferredCriticalUnknowns = @($st.unknowns | Where-Object { $_.priority -eq "CRITICAL" -and $_.status -eq "DEFERRED" })
        $unapprovedDeferredCritical = @()
        foreach ($u in $deferredCriticalUnknowns) {
            # Check for explicit non-empty justification
            $hasJustification = $false
            $justVal = ""
            if ($u.PSObject.Properties['justification'] -and -not [string]::IsNullOrWhiteSpace($u.justification)) {
                $hasJustification = $true
                $justVal = [string]$u.justification
            } elseif ($u.PSObject.Properties['deferral_justification'] -and -not [string]::IsNullOrWhiteSpace($u.deferral_justification)) {
                $hasJustification = $true
                $justVal = [string]$u.deferral_justification
            } elseif ($u.PSObject.Properties['reason'] -and -not [string]::IsNullOrWhiteSpace($u.reason)) {
                $hasJustification = $true
                $justVal = [string]$u.reason
            } elseif ($u.PSObject.Properties['rationale'] -and -not [string]::IsNullOrWhiteSpace($u.rationale)) {
                $hasJustification = $true
                $justVal = [string]$u.rationale
            }

            # Check for approval recorded
            $hasApproval = $false
            $appVal = ""
            if ($u.PSObject.Properties['approval'] -and -not [string]::IsNullOrWhiteSpace([string]$u.approval)) {
                $rawApp = [string]$u.approval
                if ($rawApp.ToUpper() -notin @("REJECTED", "PENDING", "PENDING_APPROVAL", "NO", "FALSE", "UNAPPROVED")) {
                    $hasApproval = $true
                    $appVal = $rawApp
                }
            } elseif ($u.PSObject.Properties['approval_status'] -and -not [string]::IsNullOrWhiteSpace([string]$u.approval_status)) {
                $rawApp = [string]$u.approval_status
                if ($rawApp.ToUpper() -eq "APPROVED") {
                    $hasApproval = $true
                    $appVal = $rawApp
                }
            } elseif ($u.PSObject.Properties['approved'] -and $u.approved -eq $true) {
                $hasApproval = $true
                $appVal = "APPROVED"
            }

            if ($hasJustification -and $hasApproval) {
                $deferred += "DEFERRED CRITICAL UNKNOWN $($u.unknown_id): $($u.description) [Justification: $justVal, Approval: $appVal]"
            } else {
                $unapprovedDeferredCritical += $u
                if (-not $hasJustification -and -not $hasApproval) {
                    $blocking += "Deferred critical unknown requires explicit justification and approval: $($u.unknown_id) - $($u.description)"
                } elseif (-not $hasJustification) {
                    $blocking += "Deferred critical unknown requires explicit justification: $($u.unknown_id) - $($u.description)"
                } else {
                    $blocking += "Deferred critical unknown requires approval: $($u.unknown_id) - $($u.description)"
                }
            }
        }
        $blockingUnknowns = @($openImportantUnknowns) + @($unapprovedDeferredCritical)

        # 4. Check Goals Resolution (DIFF-01 Tests 01, 02, 04, 06, DIFF-04)
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
                    ($g.related_requirements -and $g.related_requirements -contains $_.decision_id)
                })

                # Find matching approved assumptions (DIFF-04)
                $matchingAssumptions = @($st.assumptions | Where-Object {
                    $_.downstream_dependencies -contains $gId -or
                    $_.description -match [regex]::Escape($gId) -or
                    ($g.related_requirements -and $g.related_requirements -contains $_.assumption_id)
                })
                $approvedAssumptions = @($matchingAssumptions | Where-Object {
                    $_.approval_status -eq "APPROVED" -and ($_.status -eq "ACTIVE" -or -not $_.status)
                })

                # Status evaluation for this goal
                $gStatus = "NEEDS_INPUT"
                $approvedDecs = @($matchingDecisions | Where-Object { $_.approval_status -eq "APPROVED" })
                $deferredDecs = @($matchingDecisions | Where-Object { $_.approval_status -eq "DEFERRED" })
                $proposedDecs = @($matchingDecisions | Where-Object { $_.approval_status -eq "PROPOSED" })
                $rejectedDecs = @($matchingDecisions | Where-Object { $_.approval_status -eq "REJECTED" })

                # Find pending questions
                # A question is pending if status is ASKED, or NEEDS_CLARIFICATION without approved decision/assumption
                $pendingQ = @($st.questions | Where-Object {
                    $_.related_goal_ids -contains $gId -and (
                        $_.status -eq "ASKED" -or
                        ($_.status -eq "NEEDS_CLARIFICATION" -and $approvedDecs.Count -eq 0 -and $approvedAssumptions.Count -eq 0)
                    )
                })

                if ($pendingQ.Count -gt 0) {
                    foreach ($pq in $pendingQ) {
                        $gBlockers += "Goal $gId has unanswered question: $($pq.question_id) ('$($pq.question_text)')"
                    }
                }

                # Session limits check for this goal
                $maxClarification = if ($st.session.PSObject.Properties['max_clarification_per_goal'] -and $st.session.max_clarification_per_goal) { [int]$st.session.max_clarification_per_goal } else { 2 }
                $goalQuestions = @($st.questions | Where-Object { $_.related_goal_ids -contains $gId })
                $clarificationLimitReached = ($goalQuestions.Count -ge $maxClarification)
                $isOneWayDoor = ($g.priority -eq "P0_CRITICAL" -or ($matchingAssumptions | Where-Object { $_.risk_level -eq "CRITICAL" }).Count -gt 0)

                if ($rejectedDecs.Count -gt 0) {
                    $gBlockers += "Goal $gId is linked to REJECTED decision $($rejectedDecs[0].decision_id)."
                    $gStatus = "BLOCKED"
                } elseif ($approvedDecs.Count -gt 0) {
                    $gStatus = "RESOLVED"
                } elseif ($approvedAssumptions.Count -gt 0) {
                    # Goal resolved by approved assumption (DIFF-04)
                    $gStatus = "ASSUMED_WITH_APPROVAL"
                } elseif ($clarificationLimitReached -and $proposedDecs.Count -eq 0 -and $deferredDecs.Count -eq 0) {
                    # Limit reached: auto-delegate Two-Way Door or mark BLOCKED
                    if (-not $isOneWayDoor) {
                        $autoAsmId = "ASM-AUTODELEGATE-$gId"
                        $existingAuto = @($st.assumptions | Where-Object { $_.assumption_id -eq $autoAsmId })
                        if ($existingAuto.Count -eq 0) {
                            $autoAsm = [PSCustomObject]@{
                                assumption_id = $autoAsmId
                                description = "$($gId): Tự động ủy quyền lựa chọn kỹ thuật an toàn (Two-Way Door Safe Default)"
                                rationale = "Mục tiêu $($gId) đạt giới hạn làm rõ ($($maxClarification) câu hỏi); tự động áp dụng Safe Default theo R5"
                                impact = "Low"
                                risk_level = "BENIGN"
                                approval_status = "APPROVED"
                                verification_task = "Verify during Step 10 QA"
                                status = "ACTIVE"
                                invalidated_at = $null
                                revocation_reason = $null
                                downstream_dependencies = @($gId)
                            }
                            $st.assumptions = @($st.assumptions) + $autoAsm
                            $approvedAssumptions = @($autoAsm)
                        } else {
                            $approvedAssumptions = @($existingAuto)
                        }
                        $gStatus = "ASSUMED_WITH_APPROVAL"
                    } else {
                        $gBlockers += "Goal $gId reached clarification limit ($maxClarification questions) on a One-Way Door / Critical goal. Marked BLOCKED."
                        $gStatus = "BLOCKED"
                    }
                } elseif ($proposedDecs.Count -gt 0 -and $deferredDecs.Count -eq 0) {
                    # Test 02: PROPOSED Decision must not count as approved
                    $gBlockers += "Goal $gId decision $($proposedDecs[0].decision_id) remains PROPOSED (requires user approval)."
                    $gStatus = "NEEDS_INPUT"
                } elseif ($deferredDecs.Count -gt 0) {
                    # Test 04: Properly deferred non-critical decision
                    $gStatus = "DEFERRED"
                } else {
                    # Goal without decision OR approved assumption must NOT pass
                    $gBlockers += "Goal $gId has no resolving decision recorded."
                    $gStatus = "NEEDS_INPUT"
                }

                if ($gBlockers.Count -gt 0) {
                    $blocking += $gBlockers
                    if ($gStatus -eq "RESOLVED" -or $gStatus -eq "ASSUMED_WITH_APPROVAL") { $gStatus = "BLOCKED" }
                }

                # Update goal status in state:
                # Keep $g.status = 'ACTIVE' (or 'PROPOSED') when goal lacks info; verdict is 'NEEDS_INPUT' and goal_evaluations[].status = 'NEEDS_INPUT'
                if ($gStatus -eq "NEEDS_INPUT") {
                    if ($g.status -ne "PROPOSED") {
                        $g.status = "ACTIVE"
                    }
                } else {
                    $g.status = $gStatus
                }

                $goalEvals += [PSCustomObject]@{
                    goal_id = $gId
                    status = $gStatus
                    decision_ids = @($matchingDecisions | ForEach-Object { $_.decision_id })
                    assumption_ids = @($approvedAssumptions | ForEach-Object { $_.assumption_id })
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
            if ($unresolvedConflicts.Count -gt 0 -or $unresolvedConflictingAnswers.Count -gt 0 -or $criticalAssumptions.Count -gt 0 -or $blockingUnknowns.Count -gt 0 -or (@($goalEvals | Where-Object { $_.status -eq "BLOCKED" }).Count -gt 0)) {
                $verdict = "BLOCKED"
                $summary = "Interview is BLOCKED by unresolved conflicts, critical unknowns, unapproved critical assumptions, or blocked goals."
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
