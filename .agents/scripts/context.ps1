# Script Quản Trị Ngữ Cảnh Tác Vụ (Context Engineering & Packet Assembly Engine v1.0)
# Tuân thủ tiêu chuẩn 6 tầng ngữ cảnh L0-L5, Cache Prefix Optimization, và Deterministic Verification.

param(
    [Parameter(Position=0, Mandatory=$true)]
    [ValidateSet("plan", "inspect", "pack", "verify")]
    [string]$Action,

    [string]$Task,
    [string]$Stage,
    [string]$PlanId,
    [string]$PackId,
    [string]$Profile
)

$ErrorActionPreference = "Stop"
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Tree-climbing tìm repoRoot bằng anchor docs/WORKFLOW_LIFECYCLE.md
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$current = $scriptDir
$repoRoot = $null
while ($current) {
    if (Test-Path -LiteralPath (Join-Path $current "docs/WORKFLOW_LIFECYCLE.md")) {
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

$contextDir = Join-Path $repoRoot ".agents/context"
$manifestFile = Join-Path $contextDir "context-manifest.json"
$profilesDir = Join-Path $contextDir "profiles"
$plansDir = Join-Path $contextDir "plans"
$packetsDir = Join-Path $contextDir "packets"
$receiptsDir = Join-Path $contextDir "receipts"
$stateFile = Join-Path $repoRoot ".agents/state/active_case.json"

# Đảm bảo các thư mục làm việc tồn tại
foreach ($d in @($plansDir, $packetsDir, $receiptsDir)) {
    if (-not (Test-Path -LiteralPath $d)) {
        New-Item -ItemType Directory -Path $d -Force | Out-Null
    }
}

function Write-Utf8NoBom {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        [Parameter(Mandatory=$true)]
        [string]$Content
    )
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function Estimate-Tokens {
    param([string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return 0 }
    $vnRegex = '[àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđĐ]'
    $vnMatches = [regex]::Matches($Text, $vnRegex, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    $vnRatio = [double]$vnMatches.Count / [double]$Text.Length
    $divisor = if ($vnRatio -gt 0.02) { 2.0 } else { 3.2 }
    return [int][Math]::Ceiling($Text.Length / $divisor)
}

function Extract-MarkdownSections {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Content,
        [string[]]$Sections
    )
    if (-not $Sections -or $Sections.Count -eq 0) {
        return $Content
    }

    $lines = $Content -split "\r?\n"
    $extractedBlocks = @()

    $headings = @()
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^(#{1,6})\s+(.*)$') {
            $headings += [PSCustomObject]@{
                Index = $i
                Level = $Matches[1].Length
                Title = $Matches[2].Trim()
                Raw = $lines[$i]
            }
        }
    }

    foreach ($sec in $Sections) {
        $secClean = $sec.Trim()
        if ([string]::IsNullOrEmpty($secClean)) { continue }

        $words = ($secClean -replace '[_·\-]+', ' ').Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries) | ForEach-Object { [regex]::Escape($_) }
        $secRegex = ($words -join '.*')

        $foundHeadingIndex = -1
        for ($h = 0; $h -lt $headings.Count; $h++) {
            $hTitle = $headings[$h].Title
            if ($hTitle -match $secRegex -or $hTitle -like "*$secClean*") {
                $foundHeadingIndex = $h
                break
            }
        }

        if ($foundHeadingIndex -ne -1) {
            $matchedH = $headings[$foundHeadingIndex]
            $startLine = $matchedH.Index
            $endLine = $lines.Count - 1
            for ($k = $foundHeadingIndex + 1; $k -lt $headings.Count; $k++) {
                if ($headings[$k].Level -le $matchedH.Level) {
                    $endLine = $headings[$k].Index - 1
                    break
                }
            }
            $blockLines = $lines[$startLine..$endLine]
            $extractedBlocks += ($blockLines -join "`n")
        } else {
            $matchingLineIdx = -1
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -match $secRegex) {
                    $matchingLineIdx = $i
                    break
                }
            }
            if ($matchingLineIdx -ne -1) {
                $wStart = [Math]::Max(0, $matchingLineIdx - 2)
                $wEnd = [Math]::Min($lines.Count - 1, $matchingLineIdx + 10)
                $extractedBlocks += ($lines[$wStart..$wEnd] -join "`n")
            }
        }
    }

    if ($extractedBlocks.Count -gt 0) {
        return ($extractedBlocks -join "`n`n---`n`n")
    }

    if ($Content.Length -gt 8000) {
        return $Content.Substring(0, 8000) + "`n... [Truncated: requested sections not found]"
    }
    return $Content
}

function Resolve-StageFromState {
    if (Test-Path -LiteralPath $stateFile) {
        try {
            $state = Get-Content -LiteralPath $stateFile -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($state.current_phase) {
                return $state.current_phase
            }
        } catch { }
    }
    return "STAGE_01_DISCOVERY"
}

function Resolve-ProfileName {
    param([string]$TaskText, [string]$StageName, [string]$RequestedProfile)
    if (-not [string]::IsNullOrEmpty($RequestedProfile)) {
        return $RequestedProfile.ToLower()
    }

    $t = if ($TaskText) { $TaskText.ToLower() } else { "" }
    if ($t -match "\b(secur|audit|vulnerab|cve|secret|hardcod|permiss)\b") { return "security" }
    if ($t -match "\b(optim|perf|speed|memory|battery|leak|profil)\b") { return "optimization" }
    if ($t -match "\b(design|ui|ux|token|layout|copy|anti-slop)\b") { return "design" }
    if ($t -match "\b(validat|smoke|hard-verify|matrix|handoff|release)\b") { return "validation" }
    if ($t -match "\b(feature|rebuild|implement|build|code|add|screen)\b") { return "feature-addition" }
    if ($t -match "\b(discover|intake|scan|explore|baseline|investigat)\b") { return "discovery" }

    switch ($StageName) {
        "STAGE_00_BOOTSTRAP" { return "discovery" }
        "STAGE_01_DISCOVERY" { return "discovery" }
        "STAGE_02_REVERSE_ENGINEERING" { return "discovery" }
        "STAGE_03_PRODUCT_DEFINITION" { return "design" }
        "STAGE_04_IMPLEMENTATION" { return "feature-addition" }
        "STAGE_05_VALIDATION" { return "validation" }
        Default { return "discovery" }
    }
}

# ==========================================
# ACTION: PLAN
# ==========================================
if ($Action -eq "plan") {
    if ([string]::IsNullOrEmpty($Task)) {
        Write-Host "[ERROR] Tham số -Task bắt buộc cho lệnh plan." -ForegroundColor Red
        exit 1
    }

    $resolvedStage = if ([string]::IsNullOrEmpty($Stage)) { Resolve-StageFromState } else { $Stage }
    $resolvedProfile = Resolve-ProfileName -TaskText $Task -StageName $resolvedStage -RequestedProfile $Profile

    $profileFile = Join-Path $profilesDir "$resolvedProfile.json"
    if (-not (Test-Path -LiteralPath $profileFile)) {
        Write-Host "[WARN] Không tìm thấy profile '$resolvedProfile.json', fallback về 'discovery.json'" -ForegroundColor Yellow
        $resolvedProfile = "discovery"
        $profileFile = Join-Path $profilesDir "discovery.json"
    }

    $manifest = Get-Content -LiteralPath $manifestFile -Raw -Encoding UTF8 | ConvertFrom-Json
    $profileData = Get-Content -LiteralPath $profileFile -Raw -Encoding UTF8 | ConvertFrom-Json

    $bModel = [int]$manifest.default_budget.model_capacity
    $bOutput = [int]$manifest.default_budget.reserved_output
    $bTools = [int]$manifest.default_budget.reserved_tools
    $bSafety = [int]$manifest.default_budget.reserved_safety
    $bUsable = $bModel - $bOutput - $bTools - $bSafety

    if ($profileData.context_budget_target -and [int]$profileData.context_budget_target -gt 0) {
        $bUsable = [int]$profileData.context_budget_target
    }

    # Lựa chọn tài liệu phù hợp
    $selectedDocs = @()
    $totalTokens = 0

    foreach ($doc in $manifest.documents) {
        $shouldInclude = $false
        $loadMode = $doc.load_mode
        $docSections = $null

        if ($doc.load_policy -eq "ALWAYS") {
            $shouldInclude = $true
        } elseif ($doc.load_policy -eq "CONDITIONAL") {
            if ($doc.condition) {
                $condStage = $doc.condition.stages
                $condProfiles = $doc.condition.profiles
                if ($condStage -and ($condStage -contains $resolvedStage)) { $shouldInclude = $true }
                if ($condProfiles -and ($condProfiles -contains $resolvedProfile)) { $shouldInclude = $true }
            }
        }

        # Kiểm tra nếu profile có chỉ định explicitly
        if ($profileData.included_documents) {
            foreach ($inc in $profileData.included_documents) {
                if ($inc.id -eq $doc.id) {
                    $shouldInclude = $true
                    if ($inc.mode) { $loadMode = $inc.mode }
                    if ($inc.sections) { $docSections = $inc.sections }
                }
            }
        }
        if (-not $docSections -and $doc.sections) {
            $docSections = $doc.sections
        }

        # Loại bỏ nếu nằm trong forbidden_contexts của profile
        if ($profileData.forbidden_contexts) {
            foreach ($forbid in $profileData.forbidden_contexts) {
                if ($doc.path -like "$forbid*" -or $doc.id -eq $forbid) {
                    $shouldInclude = $false
                }
            }
        }

        if ($shouldInclude -and $doc.load_policy -ne "DEPRECATED") {
            $estTok = [int]$doc.estimated_tokens
            $isUntrusted = ($doc.layer -eq "L5" -or $doc.tags -contains "untrusted")
            $docObj = [ordered]@{
                id = $doc.id
                path = $doc.path
                layer = $doc.layer
                load_mode = $loadMode
                estimated_tokens = $estTok
                untrusted = $isUntrusted
            }
            if ($docSections) {
                $docObj["sections"] = $docSections
            }
            $selectedDocs += [PSCustomObject]$docObj
            $totalTokens += $estTok
        }
    }

    $planTimestamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
    $randSuffix = (-join ((48..57) + (97..102) | Get-Random -Count 4 | ForEach-Object { [char]$_ }))
    $newPlanId = "PLAN-$planTimestamp-$randSuffix"

    $planObject = [PSCustomObject]@{
        schema_version = 1
        plan_id = $newPlanId
        task = $Task
        stage = $resolvedStage
        profile = $resolvedProfile
        created_at = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
        budget = [PSCustomObject]@{
            model_capacity = $bModel
            reserved_output = $bOutput
            reserved_tools = $bTools
            reserved_safety = $bSafety
            usable_budget = $bUsable
            allocated_tokens = $totalTokens
            utilization_pct = [Math]::Round(($totalTokens / $bUsable) * 100, 2)
        }
        selected_documents = $selectedDocs
    }

    $planFilePath = Join-Path $plansDir "$newPlanId.json"
    Write-Utf8NoBom -Path $planFilePath -Content ($planObject | ConvertTo-Json -Depth 10)

    Write-Host "=================================================================" -ForegroundColor Cyan
    Write-Host " [CONTEXT PLANNER] Kế hoạch phân bổ ngữ cảnh tạo thành công" -ForegroundColor Green
    Write-Host "=================================================================" -ForegroundColor Cyan
    Write-Host " Plan ID      : $newPlanId" -ForegroundColor White
    Write-Host " Task         : $Task" -ForegroundColor Gray
    Write-Host " Stage        : $resolvedStage" -ForegroundColor Gray
    Write-Host " Profile      : $resolvedProfile" -ForegroundColor Gray
    Write-Host " Documents    : $($selectedDocs.Count) tài liệu được chọn" -ForegroundColor Gray
    Write-Host " Est. Tokens  : $totalTokens / $bUsable tokens ($([Math]::Round(($totalTokens / $bUsable) * 100, 2))% budget)" -ForegroundColor Yellow
    Write-Host " Lưu tại      : $planFilePath" -ForegroundColor Gray
    Write-Host "-----------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host " Bước tiếp theo: Chạy lệnh đóng gói Context Packet:" -ForegroundColor White
    Write-Host " .\.agents\scripts\context.ps1 pack -PlanId `"$newPlanId`"" -ForegroundColor Cyan
    exit 0
}

# ==========================================
# ACTION: INSPECT
# ==========================================
if ($Action -eq "inspect") {
    if ([string]::IsNullOrEmpty($PlanId)) {
        Write-Host "[ERROR] Tham số -PlanId bắt buộc cho lệnh inspect." -ForegroundColor Red
        exit 1
    }

    $targetFile = if ($PlanId.EndsWith(".json")) { Join-Path $plansDir $PlanId } else { Join-Path $plansDir "$PlanId.json" }
    if (-not (Test-Path -LiteralPath $targetFile)) {
        Write-Host "[ERROR] Không tìm thấy plan tại: $targetFile" -ForegroundColor Red
        exit 1
    }

    $plan = Get-Content -LiteralPath $targetFile -Raw -Encoding UTF8 | ConvertFrom-Json
    Write-Host "=================================================================" -ForegroundColor Cyan
    Write-Host " [INSPECT PLAN] Chi tiết phân bổ ngữ cảnh: $($plan.plan_id)" -ForegroundColor Green
    Write-Host "=================================================================" -ForegroundColor Cyan
    Write-Host " Task      : $($plan.task)" -ForegroundColor White
    Write-Host " Stage     : $($plan.stage)" -ForegroundColor Gray
    Write-Host " Profile   : $($plan.profile)" -ForegroundColor Gray
    Write-Host " Budget    : Usable $($plan.budget.usable_budget) | Allocated $($plan.budget.allocated_tokens) ($($plan.budget.utilization_pct)%)" -ForegroundColor Yellow
    Write-Host "-----------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host " Danh sách tài liệu và phân tầng (L0 -> L5):" -ForegroundColor White

    $layers = @("L0", "L3", "L2", "L1", "L4", "L5")
    foreach ($ly in $layers) {
        $docsInLayer = @($plan.selected_documents | Where-Object { $_.layer -eq $ly })
        if ($docsInLayer.Count -gt 0) {
            Write-Host " [$ly] ($($docsInLayer.Count) files):" -ForegroundColor Cyan
            foreach ($d in $docsInLayer) {
                Write-Host "   - $($d.id) [Mode: $($d.load_mode)] (~$($d.estimated_tokens) tok) -> $($d.path)" -ForegroundColor Gray
            }
        }
    }
    exit 0
}

# ==========================================
# ACTION: PACK
# ==========================================
if ($Action -eq "pack") {
    if ([string]::IsNullOrEmpty($PlanId)) {
        Write-Host "[ERROR] Tham số -PlanId bắt buộc cho lệnh pack." -ForegroundColor Red
        exit 1
    }

    $planFile = if ($PlanId.EndsWith(".json")) { Join-Path $plansDir $PlanId } else { Join-Path $plansDir "$PlanId.json" }
    if (-not (Test-Path -LiteralPath $planFile)) {
        Write-Host "[ERROR] Không tìm thấy plan tại: $planFile" -ForegroundColor Red
        exit 1
    }

    $plan = Get-Content -LiteralPath $planFile -Raw -Encoding UTF8 | ConvertFrom-Json

    $layerNames = @{
        "L0" = "Operating Contract & Safety Invariants"
        "L1" = "Active Case State & Gate Controller"
        "L2" = "Domain Knowledge & Execution Profiles"
        "L3" = "Project Architecture & Durable Wiki"
        "L4" = "Task Packet & Working Memory"
        "L5" = "Evidence & Ephemeral Tool I/O"
    }

    $orderedLayers = @("L0", "L3", "L2", "L1", "L4", "L5")
    $packedLayers = @()
    $totalActualTokens = 0

    foreach ($ly in $orderedLayers) {
        $docsInLayer = $plan.selected_documents | Where-Object { $_.layer -eq $ly }
        $layerItems = @()

        if ($docsInLayer) {
            foreach ($doc in $docsInLayer) {
                $filePath = Join-Path $repoRoot $doc.path
                $content = $null
                $tok = [int]$doc.estimated_tokens

                if (Test-Path -LiteralPath $filePath) {
                    try {
                        if ($doc.load_mode -eq "FULL") {
                            $rawContent = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)
                            $content = [string]$rawContent
                        } elseif ($doc.load_mode -eq "SUMMARY") {
                            $rawContent = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)
                            $lines = $rawContent -split "\r?\n"
                            if ($doc.id -eq "STATE-MEMORY" -or $filePath -like "*MEMORY.md*") {
                                $tableLines = @()
                                $inTable = $false
                                foreach ($line in $lines) {
                                    if ($line -match '^##\s+1\.\s+Bảng\s+Chỉ\s+Mục' -or $line -match '^\|\s*ID\s*\|') {
                                        $inTable = $true
                                    }
                                    if ($inTable) {
                                        if ($line -match '^---' -and $tableLines.Count -gt 2) {
                                            break
                                        }
                                        $tableLines += $line
                                    }
                                }
                                if ($tableLines.Count -gt 0) {
                                    $content = [string]("# [SUMMARY: Memory Notes Index]`n" + ($tableLines -join "`n"))
                                } else {
                                    $summaryLines = $lines | Select-Object -First 60
                                    $content = [string](($summaryLines -join "`n") + "`n... [Condensed memory summary]")
                                }
                            } else {
                                $summaryLines = $lines | Select-Object -First 60
                                $content = [string](($summaryLines -join "`n") + "`n... [Summary digest]")
                            }
                        } elseif ($doc.load_mode -eq "SECTION_RETRIEVAL") {
                            $rawContent = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)
                            $sections = if ($doc.sections) { @($doc.sections) } else { @() }
                            if ($sections.Count -gt 0) {
                                $content = [string](Extract-MarkdownSections -Content $rawContent -Sections $sections)
                            } else {
                                $rawTok = Estimate-Tokens -Text $rawContent
                                if ($rawTok -gt 2500) {
                                    $content = [string]($rawContent.Substring(0, [Math]::Min($rawContent.Length, 8000)) + "`n... [Section slice]")
                                } else {
                                    $content = [string]$rawContent
                                }
                            }
                        } else {
                            # REFERENCE_ONLY
                            $content = $null
                            $tok = 50
                        }
                    } catch {
                        $content = "[Warning: Lỗi khi đọc file $($doc.path)]"
                    }
                } else {
                    $content = "[Notice: File chưa được tạo: $($doc.path)]"
                    $tok = 20
                }

                $itemNonce = $null
                if ($doc.untrusted) {
                    $nonceBytes = New-Object byte[] 16
                    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($nonceBytes)
                    $itemNonce = ($nonceBytes | ForEach-Object { $_.ToString("x2") }) -join ""
                    $escaped = [System.Security.SecurityElement]::Escape($content)
                    $content = [string]("<untrusted_binary_evidence nonce=`"$itemNonce`" path=`"$($doc.path)`">`n$escaped`n</untrusted_binary_evidence>")
                }

                if ($content -ne $null) {
                    $tok = Estimate-Tokens -Text $content
                }

                $totalActualTokens += $tok
                $itemObj = [ordered]@{
                    id = $doc.id
                    path = $doc.path
                    load_mode = $doc.load_mode
                    estimated_tokens = $tok
                    content = $content
                    untrusted = [bool]$doc.untrusted
                }
                if ($doc.untrusted) {
                    $itemObj["nonce"] = $itemNonce
                }
                if ($doc.sections) {
                    $itemObj["sections"] = $doc.sections
                }
                $layerItems += [PSCustomObject]$itemObj
            }
        }

        $packedLayers += [PSCustomObject]@{
            layer_id = $ly
            layer_name = $layerNames[$ly]
            items = $layerItems
        }
    }

    $packTimestamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
    $randSuffix = (-join ((48..57) + (97..102) | Get-Random -Count 4 | ForEach-Object { [char]$_ }))
    $newPackId = "PACK-$packTimestamp-$randSuffix"

    $status = if ($totalActualTokens -le [int]$plan.budget.usable_budget) { "READY" } else { "OVERBUDGET" }

    $metadataTail = [ordered]@{
        packet_id = $newPackId
        plan_id = $plan.plan_id
        created_at = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
        generator = "context.ps1 pack v1.0"
        layer_order = "L0->L3->L2->L1->L4->L5"
    }

    $packetObject = [ordered]@{
        schema_version = 1
        layers = $packedLayers
        stage = $plan.stage
        profile = $plan.profile
        task = $plan.task
        budget = [ordered]@{
            model_capacity = [int]$plan.budget.model_capacity
            reserved_output = [int]$plan.budget.reserved_output
            reserved_tools = [int]$plan.budget.reserved_tools
            reserved_safety = [int]$plan.budget.reserved_safety
            usable_budget = [int]$plan.budget.usable_budget
            allocated_tokens = $totalActualTokens
            utilization_pct = [Math]::Round(($totalActualTokens / [int]$plan.budget.usable_budget) * 100, 2)
        }
        cache_alignment = [ordered]@{
            prefix_stable = $true
            dynamic_suffix_only = $true
            timestamp_in_prefix = $false
        }
        status = $status
        _metadata_tail = $metadataTail
    }

    $packFilePath = Join-Path $packetsDir "$newPackId.json"
    Write-Utf8NoBom -Path $packFilePath -Content ($packetObject | ConvertTo-Json -Depth 10)

    Write-Host "=================================================================" -ForegroundColor Cyan
    Write-Host " [CONTEXT PACKER] Đóng gói Context Packet thành công" -ForegroundColor Green
    Write-Host "=================================================================" -ForegroundColor Cyan
    Write-Host " Pack ID     : $newPackId" -ForegroundColor White
    Write-Host " Plan ID     : $($plan.plan_id)" -ForegroundColor Gray
    Write-Host " Status      : $status" -ForegroundColor $(if ($status -eq "READY") { "Green" } else { "Red" })
    Write-Host " Tokens      : $totalActualTokens / $([int]$plan.budget.usable_budget) ($([Math]::Round(($totalActualTokens / [int]$plan.budget.usable_budget) * 100, 2))%)" -ForegroundColor Yellow
    Write-Host " Cache Order : L0 (Contract) -> L3 (Wiki) -> L2 (Profile) -> L1 (State) -> L4 (Task) -> L5 (Tail)" -ForegroundColor Gray
    Write-Host " Lưu tại     : $packFilePath" -ForegroundColor Gray
    Write-Host "-----------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host " Bước tiếp theo: Xác minh Context Packet và phát hành Receipt:" -ForegroundColor White
    Write-Host " .\.agents\scripts\context.ps1 verify -PackId `"$newPackId`"" -ForegroundColor Cyan
    exit 0
}

# ==========================================
# ACTION: VERIFY
# ==========================================
if ($Action -eq "verify") {
    if ([string]::IsNullOrEmpty($PackId)) {
        Write-Host "[ERROR] Tham số -PackId bắt buộc cho lệnh verify." -ForegroundColor Red
        exit 1
    }

    $packFile = if ($PackId.EndsWith(".json")) { Join-Path $packetsDir $PackId } else { Join-Path $packetsDir "$PackId.json" }
    if (-not (Test-Path -LiteralPath $packFile)) {
        Write-Host "[ERROR] Không tìm thấy packet tại: $packFile" -ForegroundColor Red
        exit 1
    }

    $packet = Get-Content -LiteralPath $packFile -Raw -Encoding UTF8 | ConvertFrom-Json
    $packetId = if ($packet._metadata_tail -and $packet._metadata_tail.packet_id) { $packet._metadata_tail.packet_id } else { $packet.packet_id }
    $planId = if ($packet._metadata_tail -and $packet._metadata_tail.plan_id) { $packet._metadata_tail.plan_id } else { $packet.plan_id }

    $receiptTimestamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
    $randSuffix = (-join ((48..57) + (97..102) | Get-Random -Count 4 | ForEach-Object { [char]$_ }))
    $receiptId = "RCPT-$receiptTimestamp-$randSuffix"

    $totalDocs = 0
    $totalChars = 0
    $layerTokens = [ordered]@{
        "L0" = 0
        "L3" = 0
        "L2" = 0
        "L1" = 0
        "L4" = 0
        "L5" = 0
    }

    $noRawBinaryBloat = $true
    $untrustedSandboxed = $true

    foreach ($layer in $packet.layers) {
        $lyId = $layer.layer_id
        $layerTok = 0
        if ($layer.items) {
            foreach ($it in $layer.items) {
                $totalDocs++
                $layerTok += [int]$it.estimated_tokens
                if ($it.content) {
                    $totalChars += $it.content.Length
                    # Kiểm tra xem có binary thô dump không (ngưỡng 30k ký tự)
                    if ($it.content.Length -gt 30000 -and ($it.path -like "01_THA_APP_VAO_DAY*" -or $it.path -like "04_SAO_LUU_AN_TOAN*")) {
                        $noRawBinaryBloat = $false
                    }
                    # Kiểm tra sandboxing untrusted với cryptographic nonce và thẻ đóng đúng chuẩn
                    if ($it.untrusted) {
                        if ([string]::IsNullOrEmpty($it.content)) {
                            $untrustedSandboxed = $false
                        } else {
                            $trimmed = $it.content.Trim()
                            $noncePattern = '^<untrusted_binary_evidence\s+nonce="([a-f0-9]+)"\s+path="[^"]*">([\s\S]*?)<\/untrusted_binary_evidence>$'
                            $match = [regex]::Match($trimmed, $noncePattern)
                            if ($match.Success) {
                                $extractedNonce = $match.Groups[1].Value
                                if ([string]::IsNullOrWhiteSpace($extractedNonce)) {
                                    $untrustedSandboxed = $false
                                }
                                if ($it.nonce -and $it.nonce -ne $extractedNonce) {
                                    $untrustedSandboxed = $false
                                }
                                if (-not $trimmed.EndsWith("</untrusted_binary_evidence>")) {
                                    $untrustedSandboxed = $false
                                }
                            } else {
                                $untrustedSandboxed = $false
                            }
                        }
                    }
                }
            }
        }
        $layerTokens[$lyId] = $layerTok
    }

    $totalTokens = [int]$packet.budget.allocated_tokens
    $usableBudget = [int]$packet.budget.usable_budget
    $budgetWithinLimit = ($totalTokens -le $usableBudget)

    $verdict = "PASS"
    if (-not $budgetWithinLimit) { $verdict = "WARN" }
    if (-not $noRawBinaryBloat -or -not $packet.schema_version -or -not $untrustedSandboxed) { $verdict = "FAIL" }

    $layerOrderIds = @($packet.layers | ForEach-Object { $_.layer_id })
    $stablePrefixFirst = ($layerOrderIds.Count -eq 6 -and $layerOrderIds[0] -eq "L0" -and $layerOrderIds[1] -eq "L3" -and $layerOrderIds[2] -eq "L2")
    $dynamicSuffixLast = ($layerOrderIds.Count -eq 6 -and $layerOrderIds[3] -eq "L1" -and $layerOrderIds[4] -eq "L4" -and $layerOrderIds[5] -eq "L5" -and $packet._metadata_tail -ne $null)

    $receipt = [ordered]@{
        schema_version = 1
        receipt_id = $receiptId
        packet_id = $packetId
        stage = $packet.stage
        verified_at = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
        verdict = $verdict
        metrics = [ordered]@{
            total_documents = $totalDocs
            total_characters = $totalChars
            total_tokens = $totalTokens
            budget_limit = $usableBudget
            budget_utilization_pct = [Math]::Round(($totalTokens / $usableBudget) * 100, 2)
            layer_tokens = [PSCustomObject]$layerTokens
        }
        compliance = [ordered]@{
            stable_prefix_first = $stablePrefixFirst
            dynamic_suffix_last = $dynamicSuffixLast
            untrusted_data_sandboxed = $untrustedSandboxed
            budget_within_limit = $budgetWithinLimit
            no_raw_binary_bloat = $noRawBinaryBloat
        }
        compaction_applied = $false
        evicted_items = @()
        notes = "Context Packet verified against REA-kit-agy Context Engineering specifications."
    }

    $receiptFilePath = Join-Path $receiptsDir "$receiptId.json"
    Write-Utf8NoBom -Path $receiptFilePath -Content ($receipt | ConvertTo-Json -Depth 10)

    Write-Host "=================================================================" -ForegroundColor Cyan
    Write-Host " [CONTEXT VERIFIER] Báo Cáo Xác Minh Ngữ Cảnh: $receiptId" -ForegroundColor Green
    Write-Host "=================================================================" -ForegroundColor Cyan
    Write-Host " Verdict          : $verdict" -ForegroundColor $(if ($verdict -eq "PASS") { "Green" } elseif ($verdict -eq "WARN") { "Yellow" } else { "Red" })
    Write-Host " Packet ID        : $packetId" -ForegroundColor White
    Write-Host " Stage            : $($packet.stage)" -ForegroundColor Gray
    Write-Host " Documents Loaded : $totalDocs" -ForegroundColor Gray
    Write-Host " Total Characters : $totalChars" -ForegroundColor Gray
    Write-Host " Total Tokens     : $totalTokens / $usableBudget ($([Math]::Round(($totalTokens / $usableBudget) * 100, 2))%)" -ForegroundColor Yellow
    Write-Host " Layer Breakdown  : L0: $($layerTokens['L0']) | L3: $($layerTokens['L3']) | L2: $($layerTokens['L2']) | L1: $($layerTokens['L1']) | L4: $($layerTokens['L4']) | L5: $($layerTokens['L5'])" -ForegroundColor Gray
    Write-Host " Compliance Checks:" -ForegroundColor White
    Write-Host "   - Stable Prefix First      : $(if ($receipt.compliance.stable_prefix_first) { '[OK]' } else { '[FAIL]' })" -ForegroundColor Green
    Write-Host "   - Dynamic Suffix Last      : $(if ($receipt.compliance.dynamic_suffix_last) { '[OK]' } else { '[FAIL]' })" -ForegroundColor Green
    Write-Host "   - Untrusted Data Sandboxed : $(if ($receipt.compliance.untrusted_data_sandboxed) { '[OK]' } else { '[FAIL]' })" -ForegroundColor Green
    Write-Host "   - Budget Within Limit      : $(if ($receipt.compliance.budget_within_limit) { '[OK]' } else { '[FAIL]' })" -ForegroundColor Green
    Write-Host "   - No Raw Binary Bloat      : $(if ($receipt.compliance.no_raw_binary_bloat) { '[OK]' } else { '[FAIL]' })" -ForegroundColor Green
    Write-Host " Receipt Lưu Tại  : $receiptFilePath" -ForegroundColor Gray
    Write-Host "=================================================================" -ForegroundColor Cyan

    if ($verdict -eq "FAIL") {
        exit 1
    } else {
        exit 0
    }
}
