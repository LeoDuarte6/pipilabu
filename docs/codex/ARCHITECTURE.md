# Architecture

```text
Codex edits local .luau files
           |
           v
    Git working tree
           |
           v
 Rojo localhost:34872  ------>  Roblox Studio DataModel
                                      ^
                                      |
                           Studio MCP observation,
                           bounded mutation, playtest
```

The code layer and world layer are intentionally separate:

- `src/` is reproducible, reviewable, and versioned.
- `places/JonAndLeoDevelopment.rbxlx` is local world state and gitignored.
- MCP validates the combined live result but does not replace Rojo as the code path.

## Doge Apple Shop slice

- `src/server/GameService.luau` owns queue membership, prompt validation, carried-apple state, rewards, and deterministic primitive Doge customers.
- `src/client/Bootstrap.client.luau` owns the GOOD FRUIT HUD and reacts to replicated player attributes and leaderstats.
- `src/shared/Config.luau` owns gameplay distances, timings, queue size, and rewards.
- `Workspace.DogeAppleShop` is the bounded world contract consumed by `GameService`.
- `scripts/build-doge-shop-world.luau` can recreate that contract only in a local `PlaceId = 0`, `GameId = 0` file.
- `Workspace.DogeAppleShop.MascotExperiments.DogeShopkeeper` is a native `ProceduralModel` experiment and is deliberately not required by gameplay.

Before any Studio mutation, list connected Studio instances, select `JonAndLeoDevelopment.rbxlx`, and assert `PlaceId = 0` and `GameId = 0`.
