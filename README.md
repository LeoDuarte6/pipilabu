# Jon and Leo Development

Local-first Roblox Studio workspace for Leo Duarte and Jon Walworth.

This repository is the durable code layer. Roblox Studio is the live world editor. Rojo synchronizes `.luau` files into Studio, while Studio MCP lets Codex inspect the DataModel, execute bounded Luau, read Output, capture the viewport, and playtest.

## Start a development session

1. Open `places/JonAndLeoDevelopment.rbxlx` in Roblox Studio.
2. Run `powershell -ExecutionPolicy Bypass -File scripts/dev.ps1`.
3. In Studio, open the Rojo plugin and connect to `localhost:34872`.
4. Keep **Enable Studio as MCP server** on in Assistant > Manage MCP Servers.

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

- Local Git repository only; no remote and no Roblox cloud workflow.
- Rojo 7.6.1, Lune 0.10.4, and Wally 0.3.2 are pinned through Rokit.
- The first playable is **Doge Apple Shop**: take one apple, serve the front Doge, earn a coin, and cycle the queue.
- `places/JonAndLeoDevelopment.rbxlx` contains the local shop world and one native procedural Doge experiment.
- `scripts/build-doge-shop-world.luau` is the guarded, repeatable world-layer builder.
- Reusable lessons from the previous Claude workflow are in `docs/legacy/CLAUDE_WORKFLOW_RECOVERY.md`.
