# Handoff

## Current verified state

- Project root: `C:\Users\fricc\Documents\Roblox\jon-and-leo-development`.
- Local Git repository with no remote; do not publish or enable Team Create.
- Local place: `places/JonAndLeoDevelopment.rbxlx` (`PlaceId = 0`, `GameId = 0`).
- Rojo 7.6.1 serves `localhost:34872`; code is owned by `src/` and synchronized into Studio.
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
- Local place saved after the world and procedural model were added.

## Studio safety lesson

An unrelated Team Create tab named `Pipilabu` was briefly active during setup. The bounded Jon-and-Leo instances were immediately removed from that tab, its prior lighting/name were restored, and Rojo was disconnected. Nothing was published. Every future Studio mutation must first:

1. Call `list_roblox_studios`.
2. Set the local `JonAndLeoDevelopment.rbxlx` instance active.
3. Assert `game.PlaceId == 0` and `game.GameId == 0` inside the mutation itself.

## Session startup

1. Open `places/JonAndLeoDevelopment.rbxlx`.
2. Run `scripts/dev.ps1` and connect Rojo to `localhost:34872`.
3. Confirm Studio Assistant > Manage MCP Servers has the Studio server and Codex enabled.
4. Before mutations, verify the active MCP instance and both local IDs.
5. For shared speech, run `scripts/start-voice-bridge.ps1` and leave XSplit running.

## Next gate

Test the slice with Leo and Jon controlling it normally. Then choose one vertical improvement: player Doge character/animation, a second order type, or the first shop upgrade. Do not build the farmer's-market meta-loop until the one-apple service loop feels good by hand.
