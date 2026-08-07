# Handoff

## Current verified state

- Project root: `C:\Users\fricc\Documents\Roblox\jon-and-leo-development`
- Local-only Git repository; no remote.
- Rojo toolchain pinned in `rokit.toml`.
- Studio MCP uses the Windows-local dynamic Roblox launcher.
- Fresh local place: `places/JonAndLeoDevelopment.rbxlx`.
- Rojo 7.6.1 serves this project on `localhost:34872` and is connected in Studio.
- Studio MCP active instance: `JonAndLeoDevelopment`.
- The place contains a 512x512 grass baseplate and a neutral neon spawn, both tagged `Owner = "Jon and Leo Development"`.
- Playtest verified both `[JonAndLeo] server online` and `[JonAndLeo] client online` at version `0.1.0`.
- Shared voice is configured through XSplit; see `docs/codex/VOICE_WORKFLOW.md`.
- The legacy Tung project remains untouched and is referenced from `docs/legacy/CLAUDE_WORKFLOW_RECOVERY.md`.

## Session startup

1. Open `places/JonAndLeoDevelopment.rbxlx`.
2. Run `scripts/dev.ps1` and connect Rojo to `localhost:34872`.
3. Confirm Studio Assistant > Manage MCP Servers has both the server and Codex enabled.
4. For shared speech, run `scripts/start-voice-bridge.ps1` and leave XSplit running.

## Next gate

Leo and Jon choose the first game concept. Before feature implementation, write the one-sentence fantasy, repeatable core loop, player count, camera perspective, and first five-minute playable slice.
