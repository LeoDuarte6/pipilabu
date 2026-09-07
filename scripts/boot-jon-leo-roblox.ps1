[CmdletBinding()]
param(
    [switch]$OpenStudio,
    [switch]$UseVoiceBridge,
    [switch]$SkipVoiceBridge,
    [int]$RojoPort = 34872
)

$ErrorActionPreference = 'Stop'
$expectedPlaceId = 133099029551440L
$expectedGameId = 10646495069L
$blockedPlaceId = 104936800417970L
$baselineCommit = '0615886c7841ec02887261248642d0eb6b30c973'
function Find-RepoRoot([string]$startPath) {
    $current = Get-Item -LiteralPath $startPath
    while ($current) {
        if ((Test-Path -LiteralPath (Join-Path $current.FullName '.git')) -and
            (Test-Path -LiteralPath (Join-Path $current.FullName 'default.project.json'))) {
            return $current.FullName
        }
        $current = $current.Parent
    }
    throw "Could not locate the Pipilabu Git root from $startPath"
}

function Get-ListenerPids([int]$port) {
    $pattern = '^\s*TCP\s+\S+:' + [regex]::Escape([string]$port) + '\s+\S+\s+LISTENING\s+(\d+)\s*$'
    return @(netstat -ano -p tcp | ForEach-Object {
        if ($_ -match $pattern) { [int]$Matches[1] }
    } | Select-Object -Unique)
}

$repoRoot = [System.IO.Path]::GetFullPath((Find-RepoRoot $PSScriptRoot))
if ($UseVoiceBridge -and $SkipVoiceBridge) {
    throw 'UseVoiceBridge and SkipVoiceBridge cannot both be set.'
}

Push-Location $repoRoot
try {
    if (-not (Test-Path -LiteralPath '.git')) {
        throw "Canonical repo has no .git directory: $repoRoot"
    }

    $head = (& git -c "safe.directory=$repoRoot" rev-parse HEAD).Trim()
    & git -c "safe.directory=$repoRoot" merge-base --is-ancestor $baselineCommit $head
    if ($LASTEXITCODE -ne 0) {
        throw "HEAD $head does not contain required baseline $baselineCommit"
    }
    $gitStatus = @(& git -c "safe.directory=$repoRoot" status --short)
    $remotes = @(& git -c "safe.directory=$repoRoot" remote -v)

    $playtestQueuePath = Join-Path $repoRoot 'docs\codex\PLAYTEST_QUEUE.md'
    if (-not (Test-Path -LiteralPath $playtestQueuePath)) {
        throw "Missing canonical playtest queue: $playtestQueuePath"
    }
    # Strip PowerShell's file-provider metadata before JSON serialization. Keeping the
    # adapted Get-Content object here makes ConvertTo-Json recursively walk PSDrive and
    # provider type metadata, which can make an otherwise healthy boot appear hung.
    $playtestQueue = (Get-Content -Raw -LiteralPath $playtestQueuePath).ToString()

    $developmentModeScript = Join-Path $repoRoot 'scripts\set-pipilabu-development-mode.ps1'
    if (-not (Test-Path -LiteralPath $developmentModeScript)) {
        throw "Missing development-mode guard: $developmentModeScript"
    }
    & $developmentModeScript -Mode Live -Reason 'Interactive Pipilabu boot: isolated production remains eligible; Studio integration stays human-controlled.' | Out-Null
    $developmentMode = Get-Content -Raw -LiteralPath (Join-Path $repoRoot '.local\overnight-art\control.json') | ConvertFrom-Json

    $voiceAction = 'not-requested'
    $voiceProcess = $null
    if ($UseVoiceBridge -and -not $SkipVoiceBridge) {
        $voiceWasRunning = @(Get-Process -Name 'XSplit.Core' -ErrorAction SilentlyContinue).Count -gt 0
        # Keep the boot helper's stdout valid JSON while the standalone voice helper
        # retains useful operator messages when invoked directly.
        & (Join-Path $repoRoot 'scripts\start-voice-bridge.ps1') 6>$null | Out-Null
        $voiceProcess = Get-Process -Name 'XSplit.Core' -ErrorAction Stop | Select-Object -First 1
        $voiceAction = if ($voiceWasRunning) { 'reused' } else { 'started-minimized' }
    }

    $project = Get-Content -Raw -LiteralPath 'default.project.json' | ConvertFrom-Json
    $allowlist = @($project.servePlaceIds | ForEach-Object { [long]$_ })
    $expectedAllowlist = @(0L, $expectedPlaceId)
    if (($allowlist.Count -ne 2) -or (Compare-Object $allowlist $expectedAllowlist)) {
        throw "Unsafe servePlaceIds: $($allowlist -join ', '); expected only 0 and $expectedPlaceId"
    }
    if ($allowlist -contains $blockedPlaceId) {
        throw "Blocked duplicate PlaceId is allowlisted: $blockedPlaceId"
    }

    $listenerPids = @(Get-ListenerPids $RojoPort)
    if ($listenerPids.Count -gt 1) {
        throw "Multiple processes listen on localhost:${RojoPort}: $($listenerPids -join ', ')"
    }

    $rojoAction = 'reused'
    if ($listenerPids.Count -eq 0) {
        & (Join-Path $repoRoot 'scripts\dev.ps1') -Port $RojoPort
        $rojoAction = 'started'
        $deadline = (Get-Date).AddSeconds(15)
        do {
            Start-Sleep -Milliseconds 250
            $listenerPids = @(Get-ListenerPids $RojoPort)
        } until ($listenerPids.Count -gt 0 -or (Get-Date) -ge $deadline)
        if ($listenerPids.Count -eq 0) {
            throw "Rojo did not listen on localhost:$RojoPort within 15 seconds"
        }
    }

    if ($listenerPids.Count -ne 1) {
        throw "Expected exactly one Rojo listener on localhost:$RojoPort"
    }
    $listenerProcess = Get-Process -Id $listenerPids[0] -ErrorAction Stop
    if ($listenerProcess.ProcessName -notmatch '^rojo$') {
        throw "Port $RojoPort belongs to $($listenerProcess.ProcessName), not Rojo; refusing to kill or replace it"
    }

    $rojoApi = Invoke-RestMethod -Uri "http://127.0.0.1:$RojoPort/api/rojo" -TimeoutSec 3
    $apiText = $rojoApi | ConvertTo-Json -Depth 8 -Compress
    if ($apiText -notmatch [regex]::Escape([string]$expectedPlaceId)) {
        throw "Rojo API does not report the expected cloud PlaceId allowlist"
    }
    if ($apiText -match [regex]::Escape([string]$blockedPlaceId)) {
        throw "Rojo API reports the blocked duplicate PlaceId"
    }

    $studiosBefore = @(Get-Process -Name 'RobloxStudioBeta' -ErrorAction SilentlyContinue)
    $studioAction = 'unchanged'
    if ($OpenStudio) {
        $studioExe = Get-ChildItem -File -LiteralPath "$env:LOCALAPPDATA\Roblox\Versions" -Filter 'RobloxStudioBeta.exe' -Recurse -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1
        if (-not $studioExe) {
            throw 'RobloxStudioBeta.exe was not found; Studio was not opened'
        }
        Start-Process -FilePath $studioExe.FullName -ArgumentList @('-task', 'EditPlace', '-placeId', [string]$expectedPlaceId)
        $studioAction = 'opened-correct-cloud-place'
    }

    [pscustomobject]@{
        readyForMcpVerification = $true
        repo = $repoRoot
        head = $head
        baselinePresent = $true
        gitClean = ($gitStatus.Count -eq 0)
        gitChanges = $gitStatus
        remoteCount = $remotes.Count
        experience = 'Pipilabu'
        placeId = $expectedPlaceId
        gameId = $expectedGameId
        blockedDuplicatePlaceId = $blockedPlaceId
        rojo = [pscustomobject]@{
            action = $rojoAction
            port = $RojoPort
            pid = $listenerPids[0]
            project = $project.name
            allowlist = $allowlist
        }
        studio = [pscustomobject]@{
            action = $studioAction
            existingProcessCount = $studiosBefore.Count
            existingWindows = @($studiosBefore | ForEach-Object {
                [pscustomobject]@{
                    pid = $_.Id
                    started = $_.StartTime
                    title = $_.MainWindowTitle
                }
            })
            note = 'Use Studio MCP plus computer use to assert exact IDs, enable Assistant MCP, close only proven disposable duplicates, and foreground the correct editor.'
        }
        voiceBridge = if (-not $UseVoiceBridge -or $SkipVoiceBridge) {
            [pscustomobject]@{
                action = $voiceAction
                running = $false
                note = 'Voice bridge is optional and was not started. The recorded XSplit/HyperX routing is Leo-specific and must be re-verified before reuse.'
            }
        } else {
            [pscustomobject]@{
                action = $voiceAction
                running = $true
                pid = $voiceProcess.Id
                processPath = $voiceProcess.Path
                discordInput = 'Microphone (HyperX Cloud III)'
                discordOutput = 'Headphones (HyperX Cloud III)'
                codexInput = 'XSplit Audio (Broadcaster)'
                note = 'Keep XSplit running; verify both microphone and system-sound meters before shared dictation.'
            }
        }
        playtestQueue = $playtestQueue
        developmentMode = $developmentMode
    } | ConvertTo-Json -Depth 8
}
finally {
    Pop-Location
}
