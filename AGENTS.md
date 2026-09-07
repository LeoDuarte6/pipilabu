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

Live Leo + Jon time is gameplay-first for the primary Studio/canonical lane: player action, feel, rules, pressure, replay desire, and recorded playtests. Isolated Luna workers may continue code candidates, art, research, and documentation while Leo and Jon are present, provided they cannot mutate Studio/canonical integration. Only explicit `Paused` mode halts isolated workers. A pending gameplay check-in blocks only work that explicitly depends on it; schedulers skip blocked items and continue with prioritized independent safe work.

Jon shares the visual review plane. Every completed human-reviewable concept sheet, character/model render, pose/animation sheet, UI direction, prop/environment board, or other authored visual must enter the deduplicated Jon visual manifest and the next bounded visual digest with the actual image attached. Batch rather than spam; normally send at most one digest per day unless Leo explicitly orders an immediate send. Exclude secrets, logs, raw transcripts, and irrelevant technical texture/debug maps. Jon's reply is design evidence only and never publish, upload, deploy, spend, delete, or secret authority. A missing reply blocks only the dependent taste decision; production continues elsewhere.

## Playtest signaling

`docs/codex/PLAYTEST_QUEUE.md` is the only current playtest status surface. Keep it short and current:

- state: `BUILDING`, `READY`, `IN TEST`, or `RECORDED`
- exact development version and place identity
- estimated minutes
- setup steps and controls
- observable pass/fail questions
- what Codex may continue doing while humans test

The boot skill must read this file and report it. Historical gates remain in `docs/codex/PLAYTEST_GATES.md`; they do not override the current queue.

## Automatic specialist escalation

- Escalate without waiting for Leo to rescue the task when a hard visual, technical, or strategic problem has produced two materially similar rejected attempts, an iteration stops yielding new diagnostic evidence, or the next local attempt is disproportionately slow/expensive relative to its information value.
- Prepare one curated evidence packet containing the governing founder decisions, current runtime truth, exact references, failed approaches, constraints, and concrete questions. "All context" means all relevant decision-grade context, not raw ambient transcripts or secrets.
- Use the appropriate available specialist lane (Fable/Opus for high-leverage visual, architecture, or strategic critique) as advisory evidence. Codex remains accountable for source inspection, acceptance/rejection of advice, implementation, verification, and the final human taste gate.
- A failed specialist call is an internal recovery event: immediately use the approved fallback model or method. Do not represent an unavailable or credit-exhausted model as having reviewed the work.
- Do not keep a resource-intensive local generation running merely because it already started. Preserve recoverable state, compare measured progress against the specialist recommendation, and stop it when the expected information value no longer justifies the machine time.

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
