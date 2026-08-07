$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$pidFile = Join-Path $projectRoot '.local\rojo.pid'

if (-not (Test-Path -LiteralPath $pidFile)) {
    Write-Host '[stop-dev] no project Rojo PID file exists.'
    exit 0
}

$processId = [int](Get-Content -LiteralPath $pidFile -Raw)
$process = Get-Process -Id $processId -ErrorAction SilentlyContinue

if (-not $process) {
    Remove-Item -LiteralPath $pidFile -Force
    Write-Host '[stop-dev] recorded Rojo process is no longer running.'
    exit 0
}

if ($process.ProcessName -notmatch '^rojo$') {
    throw "PID $processId is $($process.ProcessName), not Rojo; refusing to stop it."
}

Stop-Process -Id $processId
Remove-Item -LiteralPath $pidFile -Force
Write-Host "[stop-dev] stopped Rojo PID $processId."

