# Recovered Claude/Roblox workflow

Recovered on 2026-08-07 from the untouched legacy project at:

`C:\Users\fricc\Documents\Codex\2026-05-03\ok-we-are-going-to-make`

That project remains the canonical archive for Tung Tung Tung Sahur Survival. Its latest local commit is `d5a4351` from 2026-05-10, with a clean `main` tracking its private GitHub origin. No files were moved out of it and its recovered Studio place was not modified.

## Patterns retained

- Three-channel loop: filesystem/Git for code, Rojo for live sync, Studio MCP for inspection and testing.
- Rojo 7.6.1 pinned through Rokit and served on `localhost:34872`.
- Only one Rojo server should own a live Studio session.
- Edit Rojo-owned scripts on disk; do not edit them through Studio or MCP.
- Keep gameplay authority on the server and presentation/input on the client.
- Maintain an operational handoff after meaningful sessions.
- Jon Walworth is the correct spelling and project co-owner.

## Patterns intentionally not carried forward

- No GitHub remote, auto-push hooks, webhook listener, smee channel, Team Create, or asset-upload automation. This project is local-only until Leo explicitly expands it.
- No Tung-specific code, NPC rules, world assets, or game-design assumptions were copied into the neutral starter.
- The old `%LOCALAPPDATA%\Roblox\mcp.bat` entry was stale on this desktop. Codex instead uses the verified dynamic launcher at `%LOCALAPPDATA%\Roblox\codex-studio-mcp.ps1`.

## Useful archived sources

- `CLAUDE.md` — complete old workflow and collaboration contract.
- `docs/HANDOFF.md` — latest operational/gameplay findings.
- `docs/ARCHITECTURE.md` — old system map.
- `docs/JON-OPUS-4.7-ONBOARDING.md` — Jon-specific onboarding.
- `.claude/settings.json` and `.claude/auto-*.ps1` — prior Git automation.
- `C:\Users\fricc\.claude\projects\D--Documents-Buffalo-WebProducts-buffalowebproducts-1\memory\project_roblox_dev.md` — compact legacy environment record.

