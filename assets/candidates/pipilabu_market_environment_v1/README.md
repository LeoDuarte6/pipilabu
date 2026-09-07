# Pipi Labu market environment kit v1

Isolated review candidate for the compact Japanese market / farmers-market direction. This folder is deliberately separate from `src/`, `scripts/build-market-village-prototype.luau`, the imported character candidates, Studio, Rojo, and cloud assets.

## What this candidate is

`PipilabuMarketEnvironmentV1` is a small, reusable prop kit built around one readable stall frontage:

- a 12 x 8 stud stall bay with an honest structural shell;
- a striped awning that mounts to the bay without growing into the camera lane;
- a two-tier display shelf, shallow fruit tray, and stackable apple crates;
- a warm lantern post, signboard, planter, curb, drain, and edge bollard;
- separate visual and simplified collision meshes so display detail does not become movement noise.

The kit translates the supplied market video into composition rules: one oversized focal seller, a clear line / service lane, fruit at hand height, dense but legible display layers, and a warm canopy rhythm. The video pixels, watermark, logos, skyline, and social UI are not included in any mesh or material.

## Status

`REVIEW_CANDIDATE` only.

- `ApprovedForPresentation = false`
- `StudioImported = false`
- `CloudTouched = false`
- no live source, Rojo mapping, Studio place, upload, publish, or remote was changed for this candidate.

## Files

- `market_kit_contract.json` — source-of-truth units, axes, pivots, dimensions, collision policy, material roles, import contract, and layout rules.
- `assembly_layout.json` — one review vignette and a corridor-safe placement example; it is not a live map layout.
- `modules/` — reusable low-poly OBJ meshes, one importable module per file.
- `collision/` — simplified structural proxies, one bounded proxy file per module.
- `market_kit_assembly.obj/.mtl` — assembled review vignette containing every visual module.
- `scripts/generate_pipilabu_market_kit.py` — deterministic standalone OBJ generator with an optional Blender-native scene branch.
- `scripts/verify_pipilabu_market_kit.py` — deterministic contract/mesh/collision verifier.
- `verification/structural_report.json` — generated verifier evidence; regenerate after changing the contract or generator.

## Quick verification

From the repository root:

```powershell
py -3 assets/candidates/pipilabu_market_environment_v1/scripts/generate_pipilabu_market_kit.py `
  --output-dir assets/candidates/pipilabu_market_environment_v1

py -3 assets/candidates/pipilabu_market_environment_v1/scripts/verify_pipilabu_market_kit.py `
  --candidate-dir assets/candidates/pipilabu_market_environment_v1
```

The generator is intentionally dependency-free in ordinary Python. When run inside Blender 4.x with the same `--output-dir`, it also creates a native scene under `blender/PipilabuMarketKitV1.blend`; that branch is included for the future FBX / Roblox importer pass but was not claimed as run in this worktree unless the report says so.

## Promotion boundary

Do not copy these modules into `Workspace.DogeAppleShop` or the existing `Workspace.PipilabuMarketVillagePrototype` from this folder. The future integration gate is recorded in `docs/codex/candidates/pipilabu_market_environment_v1/HANDOFF.md` and requires a sandbox import, a mobile-scale sightline/collision review, an exact private-place identity assertion, and a named human playtest before any promotion decision.
