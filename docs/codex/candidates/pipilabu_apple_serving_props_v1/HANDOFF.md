# ART-003 — Pipi Labu apple and serving-prop kit v1

Date: 2026-08-08
State: `REVIEW_CANDIDATE` / local-only / no human approval recorded

## Outcome

Created the isolated candidate at `assets/candidates/pipilabu_apple_serving_props_v1/` with:

- authored Ruby and Honeygold lobed apples with stem and muted leaf;
- matching 6×2.5×5-stud Ruby/Honeygold crate frames;
- a shallow 3.2×0.32×1.6-stud counter tray with 0.65-stud front clearance;
- small Ruby/Honeygold display markers;
- one exact full-size crate collision proxy;
- an assembly layout and a rendered board showing `carry -> contact -> customer hold`.

The ordinary Ruby apple remains the baseline. Honeygold is the only current color contrast. The board deliberately makes contact the largest and clearest visual beat; pickup stays quiet, and the customer-held apple remains visible. This is a prop-family decision surface, not gameplay implementation or approval of a Roblox import.

## Source reconciliation

Read-only context was taken from `src/shared/AppleCatalog.luau`, `src/server/GameService.luau`, `scripts/build-doge-shop-world.luau`, `docs/HUD_DIRECTION.md`, `docs/CHARACTER_ART_DIRECTION.md`, `docs/GAME_CONCEPT.md`, `docs/IDEA_LEDGER.md`, `docs/codex/HANDOFF.md`, `docs/art/OVERNIGHT_ART_LEDGER.md`, and the existing market/baby-cast candidate handoffs.

The contract preserves the current source values: 1.3-stud held apple, transient receive target `[1.42, 1.16, 1.42]`, settle size `[1.3, 1.3, 1.3]`, 0.16-second handoff, 0.28-stud arc, 18-degree tilt, 0.08-second settle, `RightHand`/`Paw_R` attachment preference, and 6×2.5×5-stud crates. The approved HUD/character language contributes warm wood/gold/vermilion hierarchy, clear world-first service, and the existing v4 Paw_R/customer material source; no HUD or character asset was modified.

## Production contract

- Units: Roblox studs; `+Y` up, `+Z` toward the service front, `+X` right.
- Apple modules: 1.3×1.32×1.3 studs, contact-center pivot, `+Y` stem-up, `CanCollide/CanTouch/CanQuery=false`.
- Crate modules: exact ground-center bounds `[-3,0,-2.5]` to `[3,2.5,2.5]`; only the separate 12-triangle proxy collides.
- Tray: surface-center pivot, display-only; its open front protects hand/Paw_R sightlines.
- Marker: display-only current-state label; no price, economy, prompt, or rarity behavior.
- Materials: AppleSkin Ruby/Honeygold, warm/dark wood, muted leaf, cream tray/paper; metalness zero. Future PBR must preserve these roles.
- Import: OBJ/MTL review artifacts now; later Blender 4.x LTS → applied transforms → FBX → isolated Roblox importer. No asset IDs or moderation state are claimed.

Rarity is a reserved, omitted material seam/marker slot only. It has no v1 geometry, glow, particle, economy, inventory, prompt, or HUD behavior.

## Verification evidence

Ran:

```text
py -3 -m py_compile assets/candidates/pipilabu_apple_serving_props_v1/scripts/generate_apple_serving_props.py assets/candidates/pipilabu_apple_serving_props_v1/scripts/verify_apple_serving_props.py
PIPILABU_APPLE_PROPS_VERIFY_OK
PIPILABU_APPLE_PROPS_DETERMINISTIC_OK files=23
```

The verifier passed module bounds/pivots/materials, triangle budgets, display/collision flags, crate proxy bounds, current handoff constants, assembly order, reserved rarity seam, PNG dimensions/detail, and all-false approval/import flags. The board was visually inspected: Ruby/Honeygold modules are separated, paw gaps remain visible, contact is dominant, and customer receipt is legible.

Current review PNG SHA-256:

`9101ea506e30139ed1487b999fb4d4f2cbb192bfb4788d8f3def97f8ad92241d`

No Studio, Rojo mapping, gameplay source, cloud asset, upload, publish, message, market candidate, or baby-cast candidate was changed.

## Risks still open

- OBJ/MTL geometry is not Blender/Roblox import validation. Pivots, mesh fidelity, SurfaceAppearance wiring, attachment offsets, and mobile camera scale still require a sandbox pass.
- The rendered board is visual-direction evidence, not proof that real hand/paw animation or customer receipt reads at gameplay distance.
- The full crate proxy is intentionally structural; a later placement test must confirm it does not steal the service prompt or block the approach.
- No new timing, audio, HUD, order, queue, patience, reward, rarity, or inventory behavior is included.

## Exact future private-play integration gate

1. Record or explicitly defer the open v0.9.3 human service-loop gate. ART-003 is not gameplay evidence.
2. Leo and Jon review the board and a mobile-sized thumbnail. Reject if pickup feels more rewarding than contact, the apple disappears against either hand/paw, the tray/crate blocks Paw_R or the ready customer, or rarity/marker detail creates clutter.
3. In a disposable local `PlaceId=0 / GameId=0` sandbox, import exactly one Ruby apple, one crate plus `COLLISION_CRATE_6X2_5`, and the tray. Validate stud bounds, pivots, material slots, `RightHand`/`Paw_R` alignment, and collision/touch/query flags before loading Honeygold or markers.
4. For any later private test, list Studio instances and assert exact `PlaceId=133099029551440`, `GameId=10646495069`, and `Edit` inside the bounded mutation. Place only under `ServerStorage.PipilabuCandidateAssets.AppleServingPropsV1`.
5. Keep `AppleCatalog`, `GameService`, prompts, queue membership, order sequence, patience, rewards, audio, HUD, Rojo mappings, and existing candidates unchanged. Test Ruby and Honeygold through pickup, visible carry, toss, contact, and customer-held receipt on mobile and desktop camera distances; contact/receipt must remain the sensory peak.
6. Remove the candidate root if it hides the hand, obscures the customer, weakens contact, creates collision ambiguity, or makes pickup feel like the reward. Only an explicit later Leo/Jon decision after sandbox/private validation may approve promotion; no upload, publish, or mechanic is implied.
