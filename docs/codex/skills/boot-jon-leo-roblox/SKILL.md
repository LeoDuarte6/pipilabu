---
name: boot-jon-leo-roblox
description: Safely boot and verify Leo Duarte and Jon Walworth's local Pipilabu Roblox workspace, single Rojo server, correct private cloud Studio place, and Roblox Studio MCP connection. Use when starting or recovering a Pipilabu development or playtest session from a verified clone; never use it for the older duplicate Pipilabu place.
---

# Boot Pipilabu

Prepare the current Pipilabu build for Leo and Jon without starting Play, editing gameplay, publishing, or touching the older duplicate.

## Fixed identity and safety boundary

- Canonical repository identity: the Git root containing this skill, `default.project.json`, and baseline commit `0615886`; Leo's current checkout is `C:\Users\fricc\Documents\Codex\2026-08-07\pipilabu`, while Jon's clone may live elsewhere.
- Correct cloud experience: `Pipilabu`, PlaceId `133099029551440`, GameId/UniverseId `10646495069`
- Blocked duplicate: PlaceId `104936800417970`, GameId/UniverseId `10646407271`
- Rojo endpoint: `localhost:34872`; allow only PlaceIds `0` and `133099029551440`
- Expected baseline: commit `0615886` must be HEAD or an ancestor of a legitimate newer HEAD

Never add or modify a remote, push, publish, deploy, upload assets, start Play, kill Studio blindly, or mutate the blocked duplicate as part of boot. Do close a Studio launcher, blank start window, or duplicate place session after its identity and disposable state are proven. Never discard an unsaved-place prompt. The old XSplit bridge is optional and Leo-only; do not start it for Jon. Its recorded HyperX routing is stale until Leo's current QuadCast path is re-verified.

## Boot workflow

1. Change to the canonical repo and read `AGENTS.md`, `docs/codex/HANDOFF.md`, `docs/IDEA_LEDGER.md`, and `docs/codex/PLAYTEST_GATES.md`.
2. Call `memory_bootstrap(project: "pipilabu", task: "Boot the current Pipilabu build for Leo and Jon")`. Reconcile memory with Git and live Studio; Git owns code truth and the selected live Studio owns current world truth.
3. Call Studio MCP `list_roblox_studios` before launching anything. In parallel, enumerate visible Roblox Studio windows/processes with computer use. Build an identity table: MCP instance ID, window title, PID when available, PlaceId, GameId, mode, and whether the window is a generic launcher/start page.
4. Run `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts\boot-jon-leo-roblox.ps1`. This resolves the current clone from the script path, validates baseline ancestry and the Rojo allowlist, reports rather than rejects configured remotes, and requires exactly one Rojo listener. It starts Rojo through `scripts/dev.ps1` only when the port is free. Voice is skipped by default; `-UseVoiceBridge` is a separate Leo-only option after the QuadCast/XSplit route is re-verified. An interactive boot sets the worker lane to `Live`: isolated candidates may continue, but Studio/canonical integration remains exclusively in Leo and Jon's gameplay lane. Only explicit `Paused` halts isolated workers.
5. Inspect the listed Studio instances. If none is the correct cloud PlaceId, rerun the helper with `-OpenStudio` exactly once. The skill—not Leo—owns opening PlaceId `133099029551440`. Wait for the `Pipilabu - Roblox Studio` editor window; do not launch again when a correct instance or verified editor window already exists.
6. Own Studio Assistant/MCP setup. If `list_roblox_studios` does not expose the newly opened correct window, use computer use in that exact `Pipilabu` window to open **Assistant → Manage MCP Servers**, turn on **Enable Studio as MCP server**, and enable the Codex client entry if the dialog exposes a separate client toggle. Never ask Leo to do this routine setup. Re-list Studio instances after the UI change. Do not toggle an already connected server off.
7. Reconcile duplicates automatically and conservatively:
   - keep the exact correct cloud editor;
   - close generic `Roblox Studio` launcher/start windows that have no place and no unsaved work;
   - identify the blocked duplicate only with a read-only PlaceId/GameId query, then close its window without mutation;
   - if closing any editor produces a save/recovery prompt, cancel the close and report that exact prompt rather than discarding data;
   - if two correct-place sessions exist, keep the MCP-verified Edit session with `Workspace.DogeAppleShop` and close the other only when it closes without a save prompt.
8. Call `set_active_studio` with the correct instance ID, then `get_studio_state`. Require Edit mode and an available Edit DataModel. If the verified correct place is stuck in a stale Play session and no human is actively testing, stop that exact session and recheck Edit mode; never stop an unidentified instance.
9. Use Edit-mode `execute_luau` only for the read-only assertion below. It returns `game.Name`, `game.PlaceId`, `game.GameId`, the live `ReplicatedStorage.JonAndLeoDevelopment.Config` version, and whether `Workspace.DogeAppleShop` exists. Assert the exact cloud IDs before accepting the result.
10. Confirm the live Config/version matches disk and therefore proves Rojo sync. If it does not, report the mismatch; do not edit Rojo-owned scripts through Studio MCP.
11. Do not configure or start a voice bridge for Jon. If Leo explicitly uses `-UseVoiceBridge` later, verify the current QuadCast/Discord/Codex routing from live meters before treating the historical HyperX notes as valid.
12. Read `docs/codex/PLAYTEST_QUEUE.md`, use computer use to activate and foreground the verified `Pipilabu - Roblox Studio` window, and leave it open in Edit mode with no generic/blocked duplicate window. Report the compact readiness result plus the exact queued playtest; report voice as not requested unless Leo explicitly enabled it.

## Read-only Studio assertion

Use an equivalent bounded query after selecting the exact Studio instance:

```luau
assert(game.PlaceId == 133099029551440 and game.GameId == 10646495069, "wrong Pipilabu")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local root = ReplicatedStorage:FindFirstChild("JonAndLeoDevelopment")
local config = root and root:FindFirstChild("Config")
return {
    name = game.Name,
    placeId = game.PlaceId,
    gameId = game.GameId,
    configSource = config and config.Source or nil,
    hasShop = workspace:FindFirstChild("DogeAppleShop") ~= nil,
}
```

Read the version from `configSource`; do not modify the source.

## Ready result

Ready means: the current clone contains baseline `0615886`; allowlist is exactly `0` plus the correct cloud PlaceId; one verified Rojo process owns port `34872`; the correct cloud editor is open; Studio Assistant MCP is enabled; Studio MCP has the correct instance active; exact cloud IDs pass; state is Edit; live Config source matches disk's current development version; the shop exists; generic/blocked duplicate windows are closed unless an unsaved-data prompt prevents safe closure; the correct Studio window is foregrounded; and Play is stopped. XSplit is not a readiness requirement.

Always finish with the state and exact test currently recorded in `docs/codex/PLAYTEST_QUEUE.md`. Never repeat a stale hard-coded gate.
