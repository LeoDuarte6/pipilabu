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

The neutral starter has one shared `Config` module and server/client bootstrap scripts. Gameplay architecture will be added only after Leo and Jon select the first concept and define the core loop.

