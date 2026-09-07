# Jon and Leo Development

Local-first Roblox Studio workspace for Leo Duarte and Jon Walworth, connected to the private `Pipilabu` Roblox experience.

This repository is the durable code layer. Roblox Studio is the live world editor. Rojo synchronizes `.luau` files into Studio, while Studio MCP lets Codex inspect the DataModel, execute bounded Luau, read Output, capture the viewport, and playtest.

## Start a development session

1. Ask Codex to run the repo-owned `boot-jon-leo-roblox` skill. It opens the private `Pipilabu` experience (`PlaceId 133099029551440`), reconciles disposable duplicate Studio windows, enables Studio Assistant MCP, verifies the exact live IDs, and foregrounds the correct editor.
2. The skill runs the bounded boot helper, which starts or reuses the one Rojo server on `localhost:34872`.
3. Use `places/JonAndLeoDevelopment.rbxlx` only as the local fallback; normal sessions use the verified private cloud place.

## Clone on a new development computer

1. Accept the private GitHub invitation for <https://github.com/LeoDuarte6/pipilabu>.
2. Install Git LFS and run `git lfs install` before cloning.
3. Clone with `git clone https://github.com/LeoDuarte6/pipilabu.git`.
4. Read `AGENTS.md`, this README, `docs/codex/HANDOFF.md`, and `docs/codex/PLAYTEST_QUEUE.md` before changing code.

## Optional Leo-only shared voice session

Jon does not need this. The preserved XSplit route was built for Leo's older HyperX setup and must be reverified against Leo's current QuadCast before reuse.

1. Run `scripts/start-voice-bridge.ps1` only after the current hardware route is verified.
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

- Private GitHub repository: <https://github.com/LeoDuarte6/pipilabu>. Large binary art/model/audio files are stored through Git LFS. The private Roblox experience is `Pipilabu` (`GameId 10646495069`, `PlaceId 133099029551440`).
- Jon's `jwallyguy` and `Awchism` accounts have Edit access.
- Jon is recorded as `jawnwalworth-tech` in `CONTRIBUTORS.md` and `.github/CODEOWNERS`; see `docs/codex/JON_ONBOARDING.md`. A write-access GitHub invitation has been issued.
- Rojo is connected to the correct Studio window at `localhost:34872`; always verify PlaceId before using Studio MCP because an older unrelated `Pipilabu` may also be open.
- Rojo 7.6.1, Lune 0.10.4, and Wally 0.3.2 are pinned through Rokit.
- The first playable is **Doge Apple Shop**: take one visible apple, toss it to the ready small Doge, earn a coin, and cycle the queue.
- Player-facing copy is centralized in `src/shared/Copy.luau` and mirrored to the private shared Google Doc documented in `docs/COPY_WORKFLOW.md`.
- The audited model-sourcing and original Blender-to-Roblox rig workflow is in `docs/ROBLOX_ASSET_PIPELINE.md`.
- `places/JonAndLeoDevelopment.rbxlx` contains the local shop world and one native procedural Doge experiment.
- `scripts/build-doge-shop-world.luau` is the guarded, repeatable world-layer builder.
- `scripts/build-market-village-prototype.luau` is a separate local-only additive builder for the compact market-village presentation lane; see `docs/MARKET_VILLAGE_PROTOTYPE.md`.
- Reusable lessons from the previous Claude workflow are in `docs/legacy/CLAUDE_WORKFLOW_RECOVERY.md`.
