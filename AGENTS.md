# AGENTS.md — Jon and Leo Development

Read `README.md`, then `docs/codex/HANDOFF.md`, before substantive work.

## Owners and scope

- Leo Duarte (`LeoDuarte6`; Roblox `thegreatwizardrock2`)
- Jon Walworth (`jawnwalworth-tech`; Roblox `jjwally`)
- This checkout and place are local to Leo's Windows desktop. Do not add a remote, publish, deploy, enable Team Create, or upload assets without Leo's explicit instruction.

## The three-channel development loop

1. **Filesystem + Git are code truth.** Edit `.luau` under `src/`.
2. **Rojo is the live code bridge.** One Rojo server owns `localhost:34872` and syncs disk code into Studio.
3. **Studio MCP is the observation/test bridge.** Use it to inspect instances, execute bounded Luau, read Output, capture screenshots, and control playtests.

Never edit Rojo-owned scripts through Studio or MCP `multi_edit`. Those edits do not become Git state and can be clobbered by Rojo.

## Safety

- Preserve local place files under `places/`; they are gitignored binary/XML world state.
- Do not destroy or bulk-reparent world instances without inspecting the exact targets first.
- Do not run a second Rojo server on port `34872`.
- Do not publish the place or create a GitHub remote without explicit approval.
- Prefer small reversible world changes and verify them through MCP and Studio Output.

## Luau conventions

- Use Luau, not legacy Lua.
- Use `--!strict` for modules and typed boundaries.
- `Foo.server.luau` → Script, `Foo.client.luau` → LocalScript, `Foo.luau` → ModuleScript.
- Keep tunables in `src/shared/Config.luau`.
- Keep one concern per module and use explicit errors over silent fallback.
- Server owns authoritative gameplay state. Clients own input, camera, presentation, and prediction only where designed.

## Verification

For meaningful changes:

1. `rojo build default.project.json --output <temporary-place>`
2. Confirm Rojo serves on `localhost:34872`.
3. Confirm Studio MCP sees the intended Studio instance and Edit DataModel.
4. Playtest the changed behavior and inspect Output for errors.
5. Update `docs/codex/HANDOFF.md` with verified state and the next gate.

