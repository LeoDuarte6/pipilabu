$ErrorActionPreference = 'Stop'

$xsplit = 'C:\Program Files\XSplit\Broadcaster\XSplit.Core.exe'

if (-not (Test-Path -LiteralPath $xsplit)) {
    throw "XSplit Broadcaster was not found at $xsplit"
}

$running = Get-Process -Name 'XSplit.Core' -ErrorAction SilentlyContinue
if (-not $running) {
    Start-Process -FilePath $xsplit -WindowStyle Minimized
    Start-Sleep -Seconds 3
    $running = Get-Process -Name 'XSplit.Core' -ErrorAction Stop
}

Write-Host "[voice] XSplit bridge is running (PID $($running.Id))."
Write-Host '[voice] Discord input: Microphone (HyperX Cloud III)'
Write-Host '[voice] Discord output: Headphones (HyperX Cloud III)'
Write-Host '[voice] Codex input: XSplit Audio (Broadcaster)'
Write-Host '[voice] XSplit must remain running while Leo and Jon speak to Codex.'
