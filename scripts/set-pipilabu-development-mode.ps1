[CmdletBinding(DefaultParameterSetName = 'Set')]
param(
    [Parameter(ParameterSetName = 'Set')]
    [ValidateSet('Live', 'AFK', 'Paused')]
    [string]$Mode,

    [Parameter(ParameterSetName = 'Set')]
    [ValidatePattern('^[A-Z0-9][A-Z0-9._-]{1,63}$')]
    [string]$GateId,

    [Parameter(ParameterSetName = 'Set')]
    [ValidateSet('Blocked', 'Recorded', 'Deferred')]
    [string]$GateDisposition,

    [Parameter(ParameterSetName = 'Set')]
    [Alias('NextBatchId')]
    [ValidatePattern('^ART-[0-9]{3}$')]
    [string]$PreferredBatchId,

    [Parameter(ParameterSetName = 'Set')]
    [string]$Reason,

    [Parameter(ParameterSetName = 'Show', Mandatory = $true)]
    [switch]$Show
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$stateDir = Join-Path $repoRoot '.local\overnight-art'
$controlPath = Join-Path $stateDir 'control.json'

function New-DefaultState([string]$ReasonText) {
    return [ordered]@{
        schemaVersion = 2
        mode = 'Paused'
        preferredBatchId = $null
        gameplayGates = [ordered]@{}
        reason = $ReasonText
        changedAt = $null
        changedBy = $null
    }
}

function Read-ControlState {
    if (-not (Test-Path -LiteralPath $controlPath)) {
        return New-DefaultState 'Fail-closed default; isolated automation has not been explicitly enabled by a valid control file.'
    }

    try {
        $raw = Get-Content -LiteralPath $controlPath -Raw | ConvertFrom-Json
        $state = New-DefaultState ([string]$raw.reason)
        $state.mode = if ($raw.mode -in @('Live', 'AFK', 'Paused')) { [string]$raw.mode } else { 'Paused' }
        if ([string]$raw.preferredBatchId -match '^ART-[0-9]{3}$') {
            $state.preferredBatchId = [string]$raw.preferredBatchId
        }
        elseif ([string]$raw.nextBatchId -match '^ART-[0-9]{3}$') {
            $state.preferredBatchId = [string]$raw.nextBatchId
        }
        if ($null -ne $raw.gameplayGates) {
            foreach ($property in $raw.gameplayGates.PSObject.Properties) {
                $state.gameplayGates[$property.Name] = $property.Value
            }
        }
        $state.changedAt = [string]$raw.changedAt
        $state.changedBy = [string]$raw.changedBy
        return $state
    }
    catch {
        return New-DefaultState 'Fail-closed default; control state was malformed.'
    }
}

$state = Read-ControlState
if ($Show) {
    [pscustomobject]$state | ConvertTo-Json -Depth 8
    exit 0
}

if (-not $PSBoundParameters.ContainsKey('Mode') -and -not $PSBoundParameters.ContainsKey('GateDisposition') -and -not $PSBoundParameters.ContainsKey('PreferredBatchId')) {
    throw 'Specify -Mode, a named -GateId with -GateDisposition, or -PreferredBatchId, or use -Show.'
}
if ($PSBoundParameters.ContainsKey('GateDisposition') -and -not $PSBoundParameters.ContainsKey('GateId')) {
    # Backward-compatible boot behavior: a global Blocked value is recorded as
    # operator metadata but never blocks independent ledger items.
    $GateId = 'LEGACY-GLOBAL'
}

if ($PSBoundParameters.ContainsKey('Mode')) {
    $state.mode = $Mode
    # Global human-gate state was an early compatibility mechanism. Presence is
    # never a project-wide blocker; interactive boots remove the stale record.
    if ($state.gameplayGates.Contains('LEGACY-GLOBAL')) {
        $state.gameplayGates.Remove('LEGACY-GLOBAL')
    }
}
if ($PSBoundParameters.ContainsKey('PreferredBatchId')) { $state.preferredBatchId = $PreferredBatchId }
if ($PSBoundParameters.ContainsKey('GateDisposition')) {
    $state.gameplayGates[$GateId] = [ordered]@{
        disposition = $GateDisposition
        reason = if ($PSBoundParameters.ContainsKey('Reason')) { $Reason } else { '' }
        changedAt = (Get-Date).ToString('o')
        changedBy = "$env:COMPUTERNAME\$env:USERNAME"
    }
}
if ($PSBoundParameters.ContainsKey('Reason')) { $state.reason = $Reason }
$state.changedAt = (Get-Date).ToString('o')
$state.changedBy = "$env:COMPUTERNAME\$env:USERNAME"

New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
$tempPath = "$controlPath.tmp-$PID"
[pscustomobject]$state | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $tempPath -Encoding utf8
Move-Item -LiteralPath $tempPath -Destination $controlPath -Force
[pscustomobject]$state | ConvertTo-Json -Depth 8
