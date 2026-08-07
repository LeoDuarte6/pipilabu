param(
    [int]$Port = 34872,
    [switch]$Foreground
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$localState = Join-Path $projectRoot '.local'
$pidFile = Join-Path $localState 'rojo.pid'
$stdoutLog = Join-Path $localState 'rojo.stdout.log'
$stderrLog = Join-Path $localState 'rojo.stderr.log'

New-Item -ItemType Directory -Path $localState -Force | Out-Null

$listener = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
if ($listener) {
    Write-Host "[dev] port $Port is already serving (PID $($listener.OwningProcess)); not starting a second Rojo."
    exit 0
}

$rojo = Get-Command rojo -ErrorAction Stop

if ($Foreground) {
    Set-Location $projectRoot
    & $rojo.Source serve default.project.json --port $Port
    exit $LASTEXITCODE
}

$process = Start-Process -FilePath $rojo.Source `
    -ArgumentList @('serve', 'default.project.json', '--port', $Port) `
    -WorkingDirectory $projectRoot `
    -WindowStyle Hidden `
    -RedirectStandardOutput $stdoutLog `
    -RedirectStandardError $stderrLog `
    -PassThru

$process.Id | Set-Content -LiteralPath $pidFile
Write-Host "[dev] Rojo started on localhost:$Port (PID $($process.Id))."
Write-Host "[dev] Logs: $stdoutLog"

