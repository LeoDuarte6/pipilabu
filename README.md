# Jon and Leo Development

Local-first Roblox Studio workspace for Leo Duarte and Jon Walworth, connected to the private `Pipilabu` Roblox experience.

This repository is the durable code layer. Roblox Studio is the live world editor. Rojo synchronizes `.luau` files into Studio, while Studio MCP lets Codex inspect the DataModel, execute bounded Luau, read Output, capture the viewport, and playtest.

## Start a development session

1. Ask Codex to run the repo-owned `boot-jon-leo-roblox` skill. It opens the private `Pipilabu` experience (`PlaceId 133099029551440`), reconciles disposable duplicate Studio windows, enables Studio Assistant MCP, verifies the exact live IDs, and foregrounds the correct editor.
2. The skill runs the bounded boot helper, which starts or reuses the one Rojo server on `localhost:34872`.
3. Use `places/JonAndLeoDevelopment.rbxlx` only as the local fallback; normal sessions use the verified private cloud place.

## Start a shared voice session

1. Run `powershell -ExecutionPolicy Bypass -File scripts/start-voice-bridge.ps1`.
2. Leave XSplit Broadcaster running, minimized if preferred.
3. Discord stays on the physical HyperX microphone and headphones.
4. Codex uses `XSplit Audio (Broadcaster)` in Settings > Voice.
5. Start a new Codex voice chat for a live conversation, or use dictation in an existing text task.

This routes Leo's microphone and Jon's Discord audio into Codex while preventing Jon's audio from being sent back into Discord. See `docs/codex/VOICE_WORKFLOW.md` for recovery details.

## Source mapping

| Disk | Studio |
|---|---|
| `src/server/` | `ServerScriptService/JonAndLeoDevelopment` |
| `src/client/` | `StarterPlayer/StarterPlayerScripts/JonAndLeoDevelopment` |
| `src/shared/` | `ReplicatedStorage/JonAndLeoDevelopment` |

Edit scripts on disk. Do not use Studio or MCP script editing for Rojo-owned code, because the next sync can overwrite it and Git will not record the change.

## Current status

- Local Git repository with no remote. The private Roblox experience is `Pipilabu` (`GameId 10646495069`, `PlaceId 133099029551440`).
- Jon's `jwallyguy` and `Awchism` accounts have Edit access.
- Jon is recorded as `jawnwalworth-tech` in `CONTRIBUTORS.md` and `.github/CODEOWNERS`; see `docs/codex/JON_ONBOARDING.md`. A GitHub remote and invitation do not exist yet.
- Rojo is connected to the correct Studio window at `localhost:34872`; always verify PlaceId before using Studio MCP because an older unrelated `Pipilabu` may also be open.
- Rojo 7.6.1, Lune 0.10.4, and Wally 0.3.2 are pinned through Rokit.
- The first playable is **Doge Apple Shop**: take one visible apple, toss it to the ready small Doge, earn a coin, and cycle the queue.
- Player-facing copy is centralized in `src/shared/Copy.luau` and mirrored to the private shared Google Doc documented in `docs/COPY_WORKFLOW.md`.
- The audited model-sourcing and original Blender-to-Roblox rig workflow is in `docs/ROBLOX_ASSET_PIPELINE.md`.
- `places/JonAndLeoDevelopment.rbxlx` contains the local shop world and one native procedural Doge experiment.
- `scripts/build-doge-shop-world.luau` is the guarded, repeatable world-layer builder.
- Reusable lessons from the previous Claude workflow are in `docs/legacy/CLAUDE_WORKFLOW_RECOVERY.md`.
