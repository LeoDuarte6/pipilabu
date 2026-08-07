# Handoff

## Current verified state

- Canonical project root: `C:\Users\fricc\Documents\Codex\2026-08-07\pipilabu`.
- Local Git repository with no remote.
- Private cloud experience: `Pipilabu` (`PlaceId = 133099029551440`, `GameId = 10646495069`).
- Jon's Roblox accounts `jwallyguy` and `Awchism` are verified collaborators with Edit access.
- The older unrelated `Pipilabu` is `PlaceId = 104936800417970`, `GameId = 10646407271`; never mutate it.
- Local fallback place: `places/JonAndLeoDevelopment.rbxlx` (`PlaceId = 0`, `GameId = 0`).
- Rojo 7.6.1 serves `localhost:34872`; code is owned by `src/` and synchronized into Studio.
- Rojo's `servePlaceIds` allowlist accepts only `0` and `133099029551440`, preventing accidental sync into the older unrelated place.
- Shared voice is configured through XSplit; see `docs/codex/VOICE_WORKFLOW.md`.
- The old Tung/Claude setup remains untouched; recovered notes are in `docs/legacy/CLAUDE_WORKFLOW_RECOVERY.md`.
- Codex Desktop now registers this canonical root as the local `pipilabu` project (`projectId 4f25ae78-74e2-4aab-b34b-5d56e1a866de`).
- The trusted project's machine-local `.codex/config.toml` repeats `approval_policy = "never"` and `sandbox_mode = "danger-full-access"`, matching Leo's global Codex profile so routine local commands and MCP checks do not request manual approval. The file is intentionally gitignored and affects only this desktop.

## First playable: Doge Apple Shop

- Concept and future layers: `docs/GAME_CONCEPT.md`.
- Player takes one visible apple from the crate, physically tosses it to only the ready small Doge, earns one coin and one served point on catch, and watches a three-customer queue cycle.
- Server-authoritative gameplay: `src/server/GameService.luau`.
- PIPILABU HUD: `src/client/Bootstrap.client.luau`.
- World contract: `Workspace.DogeAppleShop`; guarded rebuild source: `scripts/build-doge-shop-world.luau`.
- Native Studio generation experiment: `Workspace.DogeAppleShop.MascotExperiments.DogeShopkeeper`, a 51-descendant `ProceduralModel` with editable color attributes. Gameplay does not depend on it.

## Verification evidence

- `rojo build default.project.json --output .local/doge-mvp-verify.rbxlx` passed.
- Clean play boot logged server and client v0.2.0 with `Doge Apple Shop ready with 3 customers` and no Luau errors.
- Fresh player state verified as `Coins 0`, `Served 0`, `Waiting 3`.
- One controlled loop verified: pickup produced `HasApple = true` plus `HeldApple`; serving produced `Coins 1`, `Served 1`, `Waiting 3`, `HasApple = false`, and removed `HeldApple`.
- Pickup and serve prompts are each limited to six studs so they cannot overlap into a hold-to-farm loop.
- Pickup and serve explicitly use `ButtonX` on gamepad, the HUD respects device-safe insets, and successful service produces a short controller pulse.
- Gate A v0.4 failed subjectively: the functional serve loop felt like turning a cog rather than causing a satisfying event.
- Gate A v0.5 keeps only red apples and replaces instant apple disappearance with a visible 0.35-second magnetic underhand toss, contact squash, then reward/celebration.
- The v0.5 presentation pass squares all kiosk architecture, removes the crooked canopy and asymmetric wall signage, hides debug-like queue/spawn markers, narrows the path, preserves grass, uses a neutral HUD palette, fixes third-person spawn framing, and reduces the customer request to one compact card.
- The live cloud counter top is now 1.55 studs high for Leo's small avatar. The builder matches it.
- The oversized `DogeShopkeeper` procedural experiment is preserved under `ServerStorage.JonAndLeoVisualExperiments`; it no longer blocks the shop or camera.
- Local place saved after the world and procedural model were added.
- The 12.12-second market-Doge inspiration video is preserved at `assets/reference/peepilabu-market-reference.mp4`. Five isolated, normalized voice clips plus timestamps and playback policy live under `assets/audio/peepilabu/`; they have not been uploaded to Roblox.
- Gate A v0.6 grounds the shop on a centered 256-stud grass Baseplate, turns the queue parallel to the counter so customers advance left-to-right, moves the HUD below Roblox Core UI, allows optional first-person zoom while preserving Classic third-person, removes `GOOD FRUIT`/`Front Doge` copy, and makes the served Doge visibly carry a welded apple through celebration and exit.
- All player-facing text is centralized in `src/shared/Copy.luau`. The private Google Doc `Pipilabu — Game Copy (Jon + Leo)` mirrors stable keys and grants `jawn.walworth@gmail.com` writer access; see `docs/COPY_WORKFLOW.md`.
- Roblox Creator Store research found no credible exact Peepilabu character. The final recommended path is an original shiba-inspired Blender rig; candidate placeholders and the audited isolation/import/test workflow are in `docs/ROBLOX_ASSET_PIPELINE.md`. No asset was inserted or uploaded.

## Studio safety lesson

An unrelated older tab is also named `Pipilabu`. Every future Studio mutation must first:

1. Call `list_roblox_studios`.
2. Set the intended instance active.
3. Assert either the local IDs are both zero or the cloud IDs exactly match `133099029551440` / `10646495069` inside the mutation itself.

The redundant local/recovery Studio sessions were closed on August 7. The correct cloud place was reopened and its current MCP instance is `85034bdf-7f2f-499e-bdb3-70b8097f1c04`, verified in Edit mode as `PlaceId 133099029551440`, `GameId 10646495069`, with `Workspace.DogeAppleShop`. Reverify the IDs every session because instance IDs are ephemeral.

## Session startup

1. Run `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts\boot-jon-leo-roblox.ps1` from the canonical root.
2. The command validates baseline ancestry, local-only Git state, the exact allowlist, and exactly one Rojo listener on `localhost:34872`.
3. If Studio MCP lists no correct instance, the boot skill reruns the command once with `-OpenStudio`; it opens exact PlaceId `133099029551440` and never launches the blocked duplicate.
4. The boot skill uses computer control to enable Studio Assistant > Manage MCP Servers and Codex itself when the correct editor is not connected. This is not a manual Leo step.
5. Before mutations, list Studio instances, select the correct cloud instance, assert both exact IDs, and confirm Edit mode plus live Config v0.6.
6. For shared speech only when explicitly wanted, run `scripts/start-voice-bridge.ps1`; voice stays off by default.
7. The boot skill closes proven generic/blocked duplicate Studio windows, preserves any window that raises an unsaved-data prompt, and leaves the verified correct editor foregrounded in Edit mode.

## Canonical workspace boot — August 7, 2026

- Mechanically copied the complete tracked repository and `.git` history from the former workspace without mutating it. New HEAD is the clean baseline `0615886` before this setup work; no Git remote exists.
- The former workspace's ignored `places/JonAndLeoDevelopment.rbxlx` could not be read by the Codex sandbox, so the new workspace relies on the correct cloud place and retains the previously built `.local` verification places. No source file was deleted or changed.
- Added the gated idea ledger at `docs/IDEA_LEDGER.md`; future mechanics remain deferred behind Gate A.
- Created the skill through the official skill-creator scaffold. Because `.codex` and `.agents` are protected in this desktop task, the complete validated repo-owned package is at `docs/codex/skills/boot-jon-leo-roblox/`, with the executable entry point at `scripts/boot-jon-leo-roblox.ps1`.
- Official `quick_validate.py` passed against the durable package, the helper passed PowerShell parsing, and the packaged/helper script copies matched by SHA-256. Automatic `$skill` discovery requires a future allowed install into a protected skill root; the executable boot command works now.
- Rojo 7.6.1 build passed. Exactly one verified Rojo process (`PID 25136` during this setup) serves `localhost:34872` from this workspace. `/api/rojo` reported project `JonAndLeoDevelopment`, server `7.6.1`, and expected PlaceIds exactly `[0, 133099029551440]`.
- The final boot command reused that listener and launched cloud PlaceId `133099029551440` without starting Play. Studio MCP still listed zero connected instances because the desktop Studio process is in the interactive Windows user session while this task's MCP bridge cannot see it.
- Resolved later on August 7: Studio MCP connected to the single visible `Pipilabu`, live server assertions matched PlaceId `133099029551440` and GameId `10646495069`, Config reported `0.5.0`, and the stale Play session was stopped cleanly. Studio is now in Edit mode. Reverify these ephemeral facts at every boot.
- Voice bridge remains off. No experience publish, Git remote, push, gameplay change, or Play session occurred.

## Next gate

Leo and Jon should now rerun Gate A from `docs/codex/PLAYTEST_GATES.md` by hand against v0.6. Ask: “Were you still looking forward to seeing and causing the handoff itself, or were you pressing Serve only to make it finish?” Do not implement the 90-second Dandori mode, potions, robberies, farmer's market, or town until they voluntarily serve an eleventh plain red apple after serving ten.

For the next bounded sound pass, upload or replace only the three `baby_serve_reaction` clips after Leo explicitly authorizes asset upload, then connect them to successful apple contact with the manifest's shuffle-bag rule. Keep the `player_callout` clips reserved for the separate pre-handoff talk experiment.

## Gate A v0.6 verification — August 7, 2026

- `rojo build default.project.json --output .local/pipilabu-v0.6-verify.rbxlx` passed.
- Live Studio identity was reasserted as PlaceId `133099029551440`, GameId `10646495069`; the blocked duplicate was not mutated.
- Live Baseplate top is exactly `Y = 0`; queue spots share `Z = 1` and advance from `X = -7.5` toward the serving spot at `X = 7.5`; customer spawn/exit are `X = -15/+15`.
- Clean Play boot logged server/client v0.6.0 with one player, zero coins, zero served, and three customers.
- A controlled pickup produced one `HeldApple`. One controlled serve produced exactly one coin and one served point, removed `HeldApple`, created an unanchored `ReceivedApple` with `CustomerAppleWeld`, preserved it during the 0.9-second celebration, and destroyed it naturally with the departing customer while returning the queue to three.
- Client readback confirmed `Classic`, zoom `0.5–20`, and `CoreUISafeInsets`. Studio screen capture confirmed the grounded horizontal presentation and `PIPILABU` HUD.

## AFK additive market-village presentation slice — local worktree

- Added `src/shared/Presentation.luau`, `MarketVillage.luau`, and pure `Stewardship.luau` contracts. The presentation palette is shared by the optional prototype HUD/server readback and the local builder.
- Added `scripts/build-market-village-prototype.luau`. It asserts local `PlaceId = 0` / `GameId = 0`, preserves `Workspace.DogeAppleShop`, and replaces only its own `Workspace.PipilabuMarketVillagePrototype` folder.
- The prototype adds a narrow market street/plaza grid, four authored primitive stalls with shelves, awnings, fruit displays, warm lanterns, four reserved future shop plots, four neighbor lanes, an inactive Peepilabu owner/quest-anchor placeholder, and named inactive seams for reputation, economy, controlled random events, and neighbor helping.
- Added `StewardshipService` plus `MarketPresentation.client.luau`. They remain completely silent when the prototype folder is absent. In prototype mode, ordinary `Served` increments expose positive-only `Goodwill`/`CareMarks` and light the board at 3, 6, and 10 serves; no timer, loss condition, DataStore, multiplayer ownership, or active quest/event behavior was added.
- `lune run scripts/test-stewardship.luau` passed eight boundary cases. The full build/test procedure and integration seams are in `docs/MARKET_VILLAGE_PROTOTYPE.md`.
- This lane is presentation/readback scaffolding only and is ready for primary-task integration after the canonical timed-shift/loss-condition and Blender-rig work is reconciled. No live Studio place, asset upload, publish, or Git remote was touched.
