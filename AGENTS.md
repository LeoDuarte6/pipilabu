# AGENTS.md — Jon and Leo Development

Read `README.md`, then `docs/codex/HANDOFF.md`, before substantive work.

## Owners and scope

- Leo Duarte (`LeoDuarte6`; Roblox `thegreatwizardrock2`)
- Jon Walworth (`jawnwalworth-tech`; Roblox `jwallyguy` and `Awchism`)
- The private cloud experience is `Pipilabu` (`GameId 10646495069`, `PlaceId 133099029551440`). Both Jon accounts have Edit access.
- Keep Git source local unless Leo explicitly requests a remote. Do not make the experience public or upload assets without Leo's explicit instruction.

## The three-channel development loop

1. **Filesystem + Git are code truth.** Edit `.luau` under `src/`.
2. **Rojo is the live code bridge.** One Rojo server owns `localhost:34872` and syncs disk code into Studio.
   `default.project.json` allowlists only the local fallback (`0`) and the shared cloud place (`133099029551440`).
3. **Studio MCP is the observation/test bridge.** Use it only after verifying the active instance's PlaceId. The older unrelated `Pipilabu` (`PlaceId 104936800417970`) must never receive Jon-and-Leo mutations.

Never edit Rojo-owned scripts through Studio or MCP `multi_edit`. Those edits do not become Git state and can be clobbered by Rojo.

## Operating modes

- **Live voice mode:** Leo and Jon are present. Favor one bounded playable change, keep commentary short, and announce `READY TO PLAYTEST` only when the exact build and test script are recorded in `docs/codex/PLAYTEST_QUEUE.md`.
- **AFK mode:** Leo and Jon have explicitly left Codex working. Continue useful work that does not require subjective human judgment: implementation behind reversible config, deterministic tests, performance/reliability passes, local art/audio tooling, research, docs, safe automation design, and isolated worktree experiments. Never pretend a human gate passed; queue it and move to the next independent lane.
- Do not sit idle because one gate needs humans. Update the playtest queue, then advance a non-overlapping AFK lane.

## Playtest signaling

`docs/codex/PLAYTEST_QUEUE.md` is the only current playtest status surface. Keep it short and current:

- state: `BUILDING`, `READY`, `IN TEST`, or `RECORDED`
- exact development version and place identity
- estimated minutes
- setup steps and controls
- observable pass/fail questions
- what Codex may continue doing while humans test

The boot skill must read this file and report it. Historical gates remain in `docs/codex/PLAYTEST_GATES.md`; they do not override the current queue.

## Safety

- Preserve local place files under `places/`; they are gitignored binary/XML world state.
- Do not destroy or bulk-reparent world instances without inspecting the exact targets first.
- Do not run a second Rojo server on port `34872`.
- Do not publish the place or create a GitHub remote without explicit approval. Leo explicitly authorized private Pipilabu asset uploads on 2026-08-07, but every upload must still be scoped, rights-safe, recorded, and kept private unless separately authorized for release.
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
