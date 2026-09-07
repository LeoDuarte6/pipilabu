#!/usr/bin/env python3
"""Hermes no-agent bridge for the guarded Windows Pipilabu art runner.

This script is installed under ~/.hermes/scripts/ on bison-1. It contains no
credentials and relies on the already-configured bison-desktop SSH target.
"""

from __future__ import annotations

import argparse
import base64
import json
import subprocess
import sys


DESKTOP_TARGET = "bison-desktop"
REPO_ROOT = r"C:\Users\fricc\Documents\Codex\2026-08-07\pipilabu"
RUNNER_PATH = REPO_ROOT + r"\scripts\run-pipilabu-overnight-art.ps1"


def encoded_powershell(script: str) -> str:
    return base64.b64encode(script.encode("utf-16le")).decode("ascii")


def run_remote(script: str, timeout: int = 30) -> subprocess.CompletedProcess[str]:
    encoded = encoded_powershell(script)
    return subprocess.run(
        [
            "ssh",
            "-o",
            "BatchMode=yes",
            "-o",
            "ConnectTimeout=8",
            DESKTOP_TARGET,
            "powershell.exe",
            "-NoProfile",
            "-NonInteractive",
            "-EncodedCommand",
            encoded,
        ],
        text=True,
        capture_output=True,
        timeout=timeout,
        check=False,
    )


def self_test() -> int:
    result = run_remote(
        f"""
$runner = '{RUNNER_PATH.replace("'", "''")}'
$codex = Get-Command codex -ErrorAction SilentlyContinue
[pscustomobject]@{{
    runnerPresent = Test-Path -LiteralPath $runner
    codexPresent = $null -ne $codex
    computer = $env:COMPUTERNAME
}} | ConvertTo-Json -Compress
"""
    )
    if result.returncode != 0:
        print(json.dumps({"status": "error", "reason": "desktop_unreachable"}))
        return 1
    try:
        payload = json.loads(result.stdout.strip().splitlines()[-1])
    except (IndexError, json.JSONDecodeError):
        print(json.dumps({"status": "error", "reason": "invalid_desktop_probe"}))
        return 1
    ok = payload.get("runnerPresent") is True and payload.get("codexPresent") is True
    print(json.dumps({"status": "ok" if ok else "blocked", **payload}))
    return 0 if ok else 1


def launch() -> int:
    # The Windows runner owns the exclusive lock, AFK/gate/window checks,
    # per-night budget, timeout, and durable handoff. The bridge returns before
    # the Luna worker completes so Hermes' cron script timeout is never held.
    result = run_remote(
        f"""
$runner = '{RUNNER_PATH.replace("'", "''")}'
if (-not (Test-Path -LiteralPath $runner)) {{
    [pscustomobject]@{{ status = 'blocked'; reason = 'runner_missing' }} | ConvertTo-Json -Compress
    exit 3
}}
$quotedRunner = '"' + $runner + '"'
$process = Start-Process -FilePath 'powershell.exe' -ArgumentList @(
    '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', $quotedRunner
) -WindowStyle Hidden -PassThru
[pscustomobject]@{{ status = 'dispatched'; pid = $process.Id }} | ConvertTo-Json -Compress
"""
    )
    if result.returncode != 0:
        # Local-only cron output: concise classification, never raw SSH stderr.
        print(json.dumps({"status": "error", "reason": "desktop_dispatch_failed"}))
        return 1
    try:
        payload = json.loads(result.stdout.strip().splitlines()[-1])
    except (IndexError, json.JSONDecodeError):
        print(json.dumps({"status": "error", "reason": "invalid_dispatch_response"}))
        return 1
    if payload.get("status") == "dispatched":
        # Empty stdout keeps the healthy 15-minute watchdog silent. Durable
        # evidence belongs to the Windows runner state and batch output.
        return 0
    print(json.dumps(payload, separators=(",", ":")))
    return 1


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    return self_test() if args.self_test else launch()


if __name__ == "__main__":
    sys.exit(main())
