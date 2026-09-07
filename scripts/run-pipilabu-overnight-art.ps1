[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$IgnoreTimeWindow,
    [ValidateRange(5, 120)]
    [int]$MaxRuntimeMinutes = 90,
    [ValidateRange(1, 6)]
    [int]$MaxBatchesPerNight = 3,
    [ValidateRange(30, 360)]
    [int]$MaxRuntimePerNightMinutes = 240,
    [string[]]$DryRunCompletedBatchIds = @()
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$runtimeRoot = Join-Path $repoRoot '.local\overnight-art'
$controlPath = Join-Path $runtimeRoot 'control.json'
$statePath = Join-Path $runtimeRoot 'state.json'
$lockPath = Join-Path $runtimeRoot 'runner.lock'
$ledgerMarkdownPath = Join-Path $repoRoot 'docs\art\OVERNIGHT_ART_LEDGER.md'
$ledgerJsonPath = Join-Path $repoRoot 'docs\art\overnight-art-ledger.json'
$playtestQueuePath = Join-Path $repoRoot 'docs\codex\PLAYTEST_QUEUE.md'
$outputRoot = Join-Path $repoRoot 'outputs\overnight-art'

New-Item -ItemType Directory -Path $runtimeRoot -Force | Out-Null
try {
    $lockStream = [System.IO.File]::Open($lockPath, [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
}
catch [System.IO.IOException] {
    Write-Output '{"status":"skipped","reason":"runner_locked"}'
    exit 0
}

try {
    function Read-JsonFailClosed([string]$Path, [hashtable]$Fallback) {
        if (-not (Test-Path -LiteralPath $Path)) { return [pscustomobject]$Fallback }
        try { return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json }
        catch { return [pscustomobject]$Fallback }
    }

    function Write-JsonAtomic([string]$Path, [object]$Value) {
        $tempPath = "$Path.tmp-$PID"
        $Value | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $tempPath -Encoding utf8
        Move-Item -LiteralPath $tempPath -Destination $Path -Force
    }

    function Get-GateDisposition([object]$Control, [string]$GateId) {
        if ([string]::IsNullOrWhiteSpace($GateId)) { return 'NotRequired' }
        if ($null -eq $Control.gameplayGates) { return 'Blocked' }
        $property = $Control.gameplayGates.PSObject.Properties[$GateId]
        if ($null -eq $property) { return 'Blocked' }
        return [string]$property.Value.disposition
    }

    $control = Read-JsonFailClosed $controlPath @{
        schemaVersion = 2; mode = 'Paused'; preferredBatchId = $null; gameplayGates = [pscustomobject]@{}; reason = 'Fail-closed control state.'
    }
    $ledger = Read-JsonFailClosed $ledgerJsonPath @{ schemaVersion = 1; batches = @() }
    $loadedState = Read-JsonFailClosed $statePath @{
        schemaVersion = 2; laneState = 'idle'; completedBatchIds = @(); failedBatchIds = @(); pendingCheckins = @(); activeRun = $null; nightlyUsage = $null; lastStatus = $null; lastUpdatedAt = $null
    }
    # Normalize schema-v1 and partially written state before any assignment.
    $state = [pscustomobject]@{
        schemaVersion = 2
        laneState = if ([string]$loadedState.laneState) { [string]$loadedState.laneState } else { 'idle' }
        completedBatchIds = @($loadedState.completedBatchIds)
        failedBatchIds = @($loadedState.failedBatchIds)
        pendingCheckins = @($loadedState.pendingCheckins)
        activeRun = $loadedState.activeRun
        nightlyUsage = $loadedState.nightlyUsage
        lastStatus = [string]$loadedState.lastStatus
        lastUpdatedAt = [string]$loadedState.lastUpdatedAt
    }

    $completedBatchIds = @($state.completedBatchIds | ForEach-Object { [string]$_ })
    foreach ($ledgerCompleted in @($ledger.batches | Where-Object { [string]$_.status -eq 'completed' })) {
        $completedId = [string]$ledgerCompleted.id
        if ($completedId -and $completedBatchIds -notcontains $completedId) { $completedBatchIds += $completedId }
    }
    if ($DryRun) {
        foreach ($simulatedId in $DryRunCompletedBatchIds) {
            if ($simulatedId -match '^ART-[0-9]{3}$' -and $completedBatchIds -notcontains $simulatedId) { $completedBatchIds += $simulatedId }
        }
    }
    $failedBatchIds = @($state.failedBatchIds | ForEach-Object { [string]$_ })
    $pendingCheckins = @($state.pendingCheckins)

    $eastern = [System.TimeZoneInfo]::FindSystemTimeZoneById('Eastern Standard Time')
    $nowEastern = [System.TimeZoneInfo]::ConvertTime((Get-Date), $eastern)
    $nightKey = if ($nowEastern.Hour -lt 8) { $nowEastern.AddDays(-1).ToString('yyyy-MM-dd') } else { $nowEastern.ToString('yyyy-MM-dd') }
    $insideWindow = ($nowEastern.Hour -ge 23 -or $nowEastern.Hour -lt 8)

    if ($null -eq $state.nightlyUsage -or [string]$state.nightlyUsage.nightKey -ne $nightKey) {
        $nightlyUsage = [pscustomobject]@{ nightKey = $nightKey; batchCount = 0; runtimeMinutes = 0.0 }
    }
    else {
        $nightlyUsage = $state.nightlyUsage
    }

    # Holding the exclusive lock proves no other runner owns this repo. Any
    # persisted activeRun is therefore stale evidence from an interrupted host.
    if ($null -ne $state.activeRun) {
        $interruptedId = [string]$state.activeRun.batchId
        if ($interruptedId -and $failedBatchIds -notcontains $interruptedId) { $failedBatchIds += $interruptedId }
        $state.activeRun = $null
    }

    $eligible = @()
    $blocked = @()
    foreach ($batch in @($ledger.batches)) {
        $id = [string]$batch.id
        $reasons = @()
        if ([string]$batch.status -ne 'ready') { $reasons += 'ledger_status' }
        if ($completedBatchIds -contains $id) { $reasons += 'already_completed' }
        if ($failedBatchIds -contains $id) { $reasons += 'failed_requires_review' }
        foreach ($dependency in @($batch.dependsOnBatches)) {
            if ($completedBatchIds -notcontains [string]$dependency) { $reasons += "dependency:$dependency" }
        }
        $gateId = [string]$batch.requiresGameplayGate
        if ($gateId) {
            $disposition = Get-GateDisposition $control $gateId
            if ($disposition -notin @('Recorded', 'Deferred')) { $reasons += "gameplay_gate:$gateId" }
        }
        if ($reasons.Count -eq 0) { $eligible += $batch }
        else { $blocked += [pscustomobject]@{ id = $id; reasons = $reasons } }
    }

    $selectedBatch = $null
    $preferredId = [string]$control.preferredBatchId
    if ($preferredId) { $selectedBatch = @($eligible | Where-Object { [string]$_.id -eq $preferredId }) | Select-Object -First 1 }
    if ($null -eq $selectedBatch) { $selectedBatch = @($eligible | Sort-Object {[int]$_.priority}, {[string]$_.id}) | Select-Object -First 1 }
    $batchId = if ($null -ne $selectedBatch) { [string]$selectedBatch.id } else { $null }

    $remainingNightMinutes = $MaxRuntimePerNightMinutes - [double]$nightlyUsage.runtimeMinutes
    $effectiveRuntimeMinutes = [int][Math]::Floor([Math]::Min($MaxRuntimeMinutes, $remainingNightMinutes))
    $checks = [ordered]@{
        modePermitsIsolatedWork = ([string]$control.mode -in @('Live', 'AFK'))
        ledgerPresent = ((Test-Path -LiteralPath $ledgerMarkdownPath) -and (Test-Path -LiteralPath $ledgerJsonPath))
        playtestQueuePresent = (Test-Path -LiteralPath $playtestQueuePath)
        insideOvernightWindow = ($IgnoreTimeWindow -or $insideWindow)
        nightlyBatchBudget = ([int]$nightlyUsage.batchCount -lt $MaxBatchesPerNight)
        nightlyRuntimeBudget = ($effectiveRuntimeMinutes -ge 5)
        eligibleIndependentBatch = ($null -ne $selectedBatch)
        lunaProfilePresent = (Test-Path -LiteralPath (Join-Path $env:USERPROFILE '.codex\luna-max.config.toml'))
        codexPresent = ($null -ne (Get-Command codex -ErrorAction SilentlyContinue))
    }
    $failedChecks = @($checks.GetEnumerator() | Where-Object { -not $_.Value } | ForEach-Object { $_.Key })

    if ($DryRun) {
        [pscustomobject]@{
            status = if ($failedChecks.Count -eq 0) { 'ready' } else { 'blocked' }
            selectedBatchId = $batchId
            eligibleBatchIds = @($eligible | ForEach-Object { [string]$_.id })
            blockedBatches = $blocked
            pendingCheckins = $pendingCheckins
            nightKey = $nightKey
            nightlyUsage = $nightlyUsage
            effectiveRuntimeMinutes = $effectiveRuntimeMinutes
            checks = $checks
            failedChecks = $failedChecks
        } | ConvertTo-Json -Depth 12
        exit 0
    }
    if ($failedChecks.Count -gt 0) {
        [pscustomobject]@{ status = 'skipped'; reason = 'no_eligible_work'; failedChecks = $failedChecks; blockedBatches = $blocked } | ConvertTo-Json -Depth 8 -Compress
        exit 0
    }

    $runId = "$($nowEastern.ToString('yyyyMMdd-HHmmss'))-$batchId"
    $runRoot = Join-Path $runtimeRoot "runs\$runId"
    $inputRoot = Join-Path $runRoot 'inputs'
    New-Item -ItemType Directory -Path $inputRoot, (Join-Path $runRoot 'deliverables') -Force | Out-Null
    $inputFiles = @('AGENTS.md','README.md','docs\GAME_CONCEPT.md','docs\IDEA_LEDGER.md','docs\CHARACTER_ART_DIRECTION.md','docs\ROBLOX_ASSET_PIPELINE.md','docs\art\OVERNIGHT_ART_LEDGER.md','docs\art\overnight-art-ledger.json','docs\codex\PLAYTEST_QUEUE.md')
    foreach ($relativePath in $inputFiles) {
        $source = Join-Path $repoRoot $relativePath
        if (Test-Path -LiteralPath $source) {
            $destination = Join-Path $inputRoot $relativePath
            New-Item -ItemType Directory -Path (Split-Path $destination -Parent) -Force | Out-Null
            Copy-Item -LiteralPath $source -Destination $destination -Force
        }
    }
    foreach ($relativePath in @('assets\models\peepilabu_owner_v4\pipilabu_shiba_owner_v4.front.png','assets\models\peepilabu_owner_v4\pipilabu_shiba_owner_v4.preview.png','assets\models\peepilabu_owner_v4\pipilabu_shiba_owner_v4.side.png','assets\reference\peepilabu-market-reference.mp4')) {
        $source = Join-Path $repoRoot $relativePath
        if (Test-Path -LiteralPath $source) {
            $destination = Join-Path $inputRoot $relativePath
            New-Item -ItemType Directory -Path (Split-Path $destination -Parent) -Force | Out-Null
            Copy-Item -LiteralPath $source -Destination $destination -Force
        }
    }

    $batchJson = $selectedBatch | ConvertTo-Json -Depth 8 -Compress
    @"
# Pipilabu Luna Max Overnight Art Batch

Selected ledger item: $batchJson
Read its full creative brief in inputs/docs/art/OVERNIGHT_ART_LEDGER.md and inspect the supplied evidence. Produce one cohesive, reviewable visual batch under deliverables/ only.

Hard boundaries:
- Work only inside this isolated run directory; never edit inputs/.
- Do not edit gameplay source, Luau, Roblox Studio, Rojo, place files, canonical assets, Git configuration, or external services.
- Do not upload, publish, deploy, message anyone, or use credentials.
- Do not claim any human/gameplay gate passed. A pending check-in blocks only its declared dependents; independent ledger work remains valid.
- Preserve the approved cute rendered Peepilabu essence. Make decisions specific enough for modeling, rigging, animation, props, camera distance, and gameplay readability.
- AAA character-sheet clarity is inspiration only; do not copy proprietary logos, fonts, layouts, characters, or protected art.

Required at run root: deliverables/, HANDOFF.md, and PLAYTEST_CHECKIN.md. The check-in must name checkin ID $([string]$selectedBatch.checkinId), the visual hypothesis, future private-place integration, and concrete pass/fail gameplay questions.
Finish within $effectiveRuntimeMinutes minutes. Favor excellence over volume.
"@ | Set-Content -LiteralPath (Join-Path $runRoot 'prompt.md') -Encoding utf8

    $state.schemaVersion = 2
    $state.laneState = 'running'
    $state.activeRun = [pscustomobject]@{ runId = $runId; batchId = $batchId; runnerPid = $PID; startedAt = (Get-Date).ToString('o') }
    $state.completedBatchIds = $completedBatchIds
    $state.failedBatchIds = $failedBatchIds
    $state.pendingCheckins = $pendingCheckins
    $state.nightlyUsage = $nightlyUsage
    $state.lastStatus = 'running'
    $state.lastUpdatedAt = (Get-Date).ToString('o')
    Write-JsonAtomic $statePath $state

    $startedAt = Get-Date
    $codexPath = (Get-Command codex).Source
    $eventsPath = Join-Path $runRoot 'events.jsonl'
    $stderrPath = Join-Path $runRoot 'stderr.log'
    $finalPath = Join-Path $runRoot 'final.md'
    $arguments = @('exec','-p','luna-max','--sandbox','workspace-write','--ephemeral','--skip-git-repo-check','--json','--color','never','-C',$runRoot,'--output-last-message',$finalPath,'-')
    $process = Start-Process -FilePath $codexPath -ArgumentList $arguments -RedirectStandardInput (Join-Path $runRoot 'prompt.md') -RedirectStandardOutput $eventsPath -RedirectStandardError $stderrPath -PassThru -WindowStyle Hidden
    $completed = $process.WaitForExit($effectiveRuntimeMinutes * 60 * 1000)
    if (-not $completed) { & taskkill.exe /PID $process.Id /T /F | Out-Null; $exitCode = 124; $status = 'timed_out' }
    else { $exitCode = $process.ExitCode; $status = if ($exitCode -eq 0 -and (Test-Path (Join-Path $runRoot 'HANDOFF.md')) -and (Test-Path (Join-Path $runRoot 'PLAYTEST_CHECKIN.md'))) { 'completed' } else { 'failed' } }
    $runtimeMinutes = [Math]::Round(((Get-Date) - $startedAt).TotalMinutes, 2)

    [pscustomobject]@{ schemaVersion=2; runId=$runId; batchId=$batchId; checkinId=[string]$selectedBatch.checkinId; status=$status; exitCode=$exitCode; nightKey=$nightKey; runtimeMinutes=$runtimeMinutes; maxRuntimeMinutes=$effectiveRuntimeMinutes; publicPublish=$false; gameplayMutation=$false } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $runRoot 'runner.json') -Encoding utf8
    $destination = Join-Path $outputRoot "$batchId\$runId"
    New-Item -ItemType Directory -Path (Split-Path $destination -Parent) -Force | Out-Null
    Copy-Item -LiteralPath $runRoot -Destination $destination -Recurse -Force

    $nightlyUsage.batchCount = [int]$nightlyUsage.batchCount + 1
    $nightlyUsage.runtimeMinutes = [Math]::Round([double]$nightlyUsage.runtimeMinutes + $runtimeMinutes, 2)
    if ($status -eq 'completed') {
        if ($completedBatchIds -notcontains $batchId) { $completedBatchIds += $batchId }
        $pendingCheckins += [pscustomobject]@{ id=[string]$selectedBatch.checkinId; batchId=$batchId; status='Awaiting'; createdAt=(Get-Date).ToString('o'); output=$destination }
    }
    elseif ($failedBatchIds -notcontains $batchId) { $failedBatchIds += $batchId }
    $state.laneState = 'idle'
    $state.activeRun = $null
    $state.completedBatchIds = $completedBatchIds
    $state.failedBatchIds = $failedBatchIds
    $state.pendingCheckins = $pendingCheckins
    $state.nightlyUsage = $nightlyUsage
    $state.lastStatus = $status
    $state.lastUpdatedAt = (Get-Date).ToString('o')
    Write-JsonAtomic $statePath $state
    [pscustomobject]@{ status=$status; batchId=$batchId; runId=$runId; pendingCheckin=[string]$selectedBatch.checkinId; nextTickMaySelectIndependentWork=$true; output=$destination } | ConvertTo-Json -Compress
}
finally {
    if ($null -ne $lockStream) { $lockStream.Dispose() }
}
