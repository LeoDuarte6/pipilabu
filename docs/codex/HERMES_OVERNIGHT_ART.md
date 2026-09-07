# Hermes Overnight Art Lane

## Purpose

Hermes on `bison-1` may wake one Windows Luna Max Codex worker for a bounded Pipilabu art-direction batch while Leo and Jon are absent. The lane exists to develop the visual world without spending live collaboration time on long renders, Blender iteration, presentation boards, or environment-kit exploration.

Live collaboration remains gameplay-first for Studio and canonical integration. Isolated Luna workers are allowed in both `Live` and `AFK` modes; only explicit `Paused` stops them. Each batch creates a named gameplay check-in, but that check-in blocks only declared dependents and never freezes unrelated production.

## Safety model

- Fail-closed default: missing or malformed local control state means `Paused`, so no worker starts.
- Presence is not a global stop: `Live` permits isolated candidates but forbids Studio/canonical integration; `AFK` permits the same isolated work with no human expected; `Paused` is the sole automation stop.
- Dependency-aware gates: the JSON ledger declares batch dependencies and optional named gameplay gates. Blocked items are skipped while the highest-priority eligible independent item continues.
- Overnight window: 11:00 PM through 8:00 AM America/New_York.
- Continuous-nightly budget: Hermes checks every 15 minutes. While explicitly `AFK`, the next eligible batch begins on the first tick after the prior worker exits. One exclusive worker lock prevents duplicates; defaults allow at most three batches and 240 total worker-minutes per Eastern night, with a 90-minute per-batch ceiling.
- Isolation: each worker receives a copied evidence packet in `.local/overnight-art/runs/`; it cannot write the canonical repo through its workspace sandbox.
- Promotion boundary: review candidates are copied only to `outputs/overnight-art/`. The lane does not modify `src`, canonical model assets, Studio, Rojo, cloud assets, Git remotes, or public Roblox state.
- Delivery: Hermes runs a no-model wake bridge and delivers locally. It sends no email, Telegram, Discord, or other external message.

## Operator commands

Show current mode without changing it:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\set-pipilabu-development-mode.ps1 -Show
```

Start a live Leo/Jon session. This preserves isolated workers while keeping Studio/canonical integration in the human lane:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\set-pipilabu-development-mode.ps1 -Mode Live -Reason "Leo and Jon are present; isolated candidates may continue"
```

Mark that no human is expected while retaining the same isolated worker permissions:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\set-pipilabu-development-mode.ps1 -Mode AFK -Reason "Live session ended"
```

Record or explicitly defer one named gameplay gate without affecting independent work:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\set-pipilabu-development-mode.ps1 -GateId ART-001-CHECKIN -GateDisposition Recorded -Reason "Owner readability playtest passed"
```

Use `Deferred` only for a deliberate human decision. The scheduler will then unlock only ledger items requiring that exact gate.

Pause all isolated automation explicitly:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\set-pipilabu-development-mode.ps1 -Mode Paused -Reason "Manual pause"
```

Dry-run the local gate evaluator:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\run-pipilabu-overnight-art.ps1 -DryRun -IgnoreTimeWindow
```

## Durable outputs

Each accepted batch is copied to `outputs/overnight-art/<batch-id>/<run-id>/` with:

- `HANDOFF.md`: what was produced, evidence used, risks, and recommended promotion step.
- `PLAYTEST_CHECKIN.md`: the exact visual hypothesis and the gameplay questions that must be answered after integration.
- `deliverables/`: concept boards, renders, Blender experiments, diagrams, or art specifications.
- `final.md`, `events.jsonl`, and `runner.json`: bounded worker and orchestration evidence.

These files are review candidates. They do not mean a game gate passed.

## Hermes bridge

The bison-owned no-agent job is named `Pipilabu Overnight Art Wake`. It periodically reaches the already-configured `bison-desktop` SSH target and launches the Windows nightly runner hidden. Repeated ticks are idempotent: the exclusive lock allows one worker, completed/failed IDs prevent duplicate claims, stale active-run evidence is recovered, and the prioritized ledger advances only to an eligible item. The Hermes runner retains its 11 PM-8 AM window. A daytime/native dispatcher may use the same runner state and exclusive lock rather than creating a second independent claim system.

The bridge may be paused or removed with the normal `hermes cron` CLI. No Codex restart, host reboot, public deployment, or external delivery is part of this lane.
