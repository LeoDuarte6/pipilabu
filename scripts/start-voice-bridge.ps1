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

# XSplit is an audio bridge during development, not the foreground workspace.
# Minimize an already-running window too so the verified Studio editor can own focus.
if (-not ('XSplitVoiceBridge.WindowState' -as [type])) {
    Add-Type @'
using System;
using System.Runtime.InteropServices;
namespace XSplitVoiceBridge {
    public static class WindowState {
        [DllImport("user32.dll")]
        public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
    }
}
'@
}
foreach ($process in @($running)) {
    if ($process.MainWindowHandle -ne [IntPtr]::Zero) {
        [XSplitVoiceBridge.WindowState]::ShowWindowAsync($process.MainWindowHandle, 6) | Out-Null
    }
}

Write-Host "[voice] XSplit bridge is running (PID $($running.Id))."
Write-Host '[voice] Discord input: Microphone (HyperX Cloud III)'
Write-Host '[voice] Discord output: Headphones (HyperX Cloud III)'
Write-Host '[voice] Codex input: XSplit Audio (Broadcaster)'
Write-Host '[voice] XSplit must remain running while Leo and Jon speak to Codex.'
