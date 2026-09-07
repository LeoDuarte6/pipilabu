# Pipi Labu apple and serving-prop kit v1

ART-003 isolated `REVIEW_CANDIDATE` for the Ruby/Honeygold apple family and the surfaces that frame service. This folder is removable review evidence only. It does not edit `src/`, Studio, Rojo mappings, cloud assets, existing market/baby-cast candidates, or gameplay behavior.

## Design decision

The ordinary Ruby apple remains the baseline. Honeygold is one clear current color contrast, not a rarity system. The prop family makes the serve beat intentional in this order:

`carry -> contact -> customer hold`

Contact is the largest visual state on the generated board. Apples retain clean silhouettes and visible paw gaps at mobile review scale; pickup remains quiet and functional. The current source contract is preserved: 1.3-stud held apple, transient `[1.42, 1.16, 1.42]` receive target, 0.16-second handoff arc, `Paw_R` preference, and 6×2.5×5-stud crate footprint.

## Modules

- `APPLE_RUBY_HANDOFF_1_3` and `APPLE_HONEYGOLD_HANDOFF_1_3`: authored lobed apple body, stem, and muted leaf; 1.3×1.32×1.3 studs; contact-center pivot; no collision/touch/query.
- `CRATE_RUBY_6X2_5` and `CRATE_HONEYGOLD_6X2_5`: matching grounded 6×2.5×5-stud crate frames with restrained color face; ground-center pivot; separate full-size structural collision proxy.
- `COUNTER_TRAY_3X1_6`: shallow tray with a 0.65-stud open front clearance; surface-center pivot; display-only.
- `PRICE_MARKER_RUBY_1X0_75` and `PRICE_MARKER_HONEYGOLD_1X0_75`: small current-state display markers; no price, economy, prompt, or rarity behavior.

The complete dimensions, pivots, collision flags, material roles, import path, handoff offsets, and future gate are in `apple_serving_props_contract.json`.

## Reproducible artifacts

- `scripts/generate_apple_serving_props.py` — deterministic OBJ/MTL meshes, assembly layout, and Pillow review board.
- `scripts/verify_apple_serving_props.py` — contract-aware OBJ bounds/material/triangle/collision/image verifier.
- `modules/` — reusable visual OBJ/MTL modules.
- `collision/` — only the crate structural proxy.
- `apple_serving_prop_assembly.obj/.mtl` — local review assembly.
- `apple_serving_props_sheet.png` — family and carry/contact/receipt decision board.
- `assembly_layout.json`, `generation_report.json`, and `verification/structural_report.json` — deterministic evidence.

The OBJ/MTL files are inspection and review artifacts. A later Blender 4.x LTS → applied transforms → FBX pass is required before any Roblox import; no FBX, asset ID, moderation state, or canonical material approval is claimed here.

## Rarity seam

The contract reserves one optional material seam or marker accent band for a future one-variable rarity study. It is omitted in v1 and carries no mechanics, glow, particles, economy values, inventory rules, prompt text, or HUD state.

## Quick verification

```text
py -3 -m py_compile assets/candidates/pipilabu_apple_serving_props_v1/scripts/generate_apple_serving_props.py assets/candidates/pipilabu_apple_serving_props_v1/scripts/verify_apple_serving_props.py
py -3 assets/candidates/pipilabu_apple_serving_props_v1/scripts/generate_apple_serving_props.py --candidate-dir assets/candidates/pipilabu_apple_serving_props_v1
py -3 assets/candidates/pipilabu_apple_serving_props_v1/scripts/verify_apple_serving_props.py --candidate-dir assets/candidates/pipilabu_apple_serving_props_v1
```

Human visual verdict, private sandbox import, and exact private-place play remain separate gates.
