# Handoff

## Current verified state

- Project root: `C:\Users\fricc\Documents\Roblox\jon-and-leo-development`.
- Local Git repository with no remote.
- Private cloud experience: `Pipilabu` (`PlaceId = 133099029551440`, `GameId = 10646495069`).
- Jon's Roblox accounts `jwallyguy` and `Awchism` are verified collaborators with Edit access.
- The older unrelated `Pipilabu` is `PlaceId = 104936800417970`, `GameId = 10646407271`; never mutate it.
- Local fallback place: `places/JonAndLeoDevelopment.rbxlx` (`PlaceId = 0`, `GameId = 0`).
- Rojo 7.6.1 serves `localhost:34872`; code is owned by `src/` and synchronized into Studio.
- Rojo's `servePlaceIds` allowlist accepts only `0` and `133099029551440`, preventing accidental sync into the older unrelated place.
- Shared voice is configured through XSplit; see `docs/codex/VOICE_WORKFLOW.md`.
- The old Tung/Claude setup remains untouched; recovered notes are in `docs/legacy/CLAUDE_WORKFLOW_RECOVERY.md`.

## First playable: Doge Apple Shop

- Concept and future layers: `docs/GAME_CONCEPT.md`.
- Player takes one visible apple from the crate, serves only the front Doge, earns one coin and one served point, and watches a three-customer queue cycle.
- Server-authoritative gameplay: `src/server/GameService.luau`.
- GOOD FRUIT HUD: `src/client/Bootstrap.client.luau`.
- World contract: `Workspace.DogeAppleShop`; guarded rebuild source: `scripts/build-doge-shop-world.luau`.
- Native Studio generation experiment: `Workspace.DogeAppleShop.MascotExperiments.DogeShopkeeper`, a 51-descendant `ProceduralModel` with editable color attributes. Gameplay does not depend on it.

## Verification evidence

- `rojo build default.project.json --output .local/doge-mvp-verify.rbxlx` passed.
- Clean play boot logged server and client v0.2.0 with `Doge Apple Shop ready with 3 customers` and no Luau errors.
- Fresh player state verified as `Coins 0`, `Served 0`, `Waiting 3`.
- One controlled loop verified: pickup produced `HasApple = true` plus `HeldApple`; serving produced `Coins 1`, `Served 1`, `Waiting 3`, `HasApple = false`, and removed `HeldApple`.
- Pickup and serve prompts are each limited to six studs so they cannot overlap into a hold-to-farm loop.
- Pickup and serve explicitly use `ButtonX` on gamepad, the HUD respects device-safe insets, and successful service produces a short controller pulse.
- Gate A v0.4 keeps only red apples, constrains the third-person camera to 6–14 studs, moves the HUD top-left, adds a visible front-customer apple marker, draft pickup/serve audio, a thank-you card, customer hop, HUD celebration, and controller feedback.
- The live cloud counter top is now 3.25 studs high, below a standard avatar's chest. The builder matches it.
- The oversized `DogeShopkeeper` procedural experiment is preserved under `ServerStorage.JonAndLeoVisualExperiments`; it no longer blocks the shop or camera.
- Local place saved after the world and procedural model were added.

## Studio safety lesson

An unrelated older tab is also named `Pipilabu`. Every future Studio mutation must first:

1. Call `list_roblox_studios`.
2. Set the intended instance active.
3. Assert either the local IDs are both zero or the cloud IDs exactly match `133099029551440` / `10646495069` inside the mutation itself.

After Studio restarted, MCP exposed both `Pipilabu` instances. The correct active instance is `2ccb68ae-e79a-472f-999f-0881e6d0fec5`, verified in Edit mode as `PlaceId 133099029551440`, `GameId 10646495069`, with `Workspace.DogeAppleShop`. Reverify the IDs every session because instance IDs are ephemeral.

## Session startup

1. Open the private `Pipilabu` experience (`PlaceId 133099029551440`) or the local fallback place.
2. Run `scripts/dev.ps1` and connect Rojo to `localhost:34872`.
3. Confirm Studio Assistant > Manage MCP Servers has the Studio server and Codex enabled.
4. Before mutations, verify the active MCP instance and both local IDs.
5. For shared speech, run `scripts/start-voice-bridge.ps1` and leave XSplit running.

## Next gate

Leo and Jon should now run Gate A from `docs/codex/PLAYTEST_GATES.md` by hand. Do not implement the 90-second Dandori mode, potions, robberies, farmer's market, or town until they voluntarily serve an eleventh plain red apple after serving ten.
