# Pipi Labu market environment kit v1 — candidate handoff

Date: 2026-08-07
State: `REVIEW_CANDIDATE`
Scope: isolated environment/prop development only

## Outcome

Created `assets/candidates/pipilabu_market_environment_v1/` as a new, removable candidate lane. It contains a 12 x 8 stud stall bay plus reusable facade, awning, shelf, crate, fruit tray, sign, lantern, planter, curb, drain, and bollard modules. Visual OBJ meshes and simplified collision proxies are separate. A production blueprint is in `review_sheet.svg`.

The kit translates the supplied 12.12-second market video and the existing art doctrine into authored rules: a large focal seller / small customer-line contrast, fruit at the handoff scale, canopy-shelf-crate rhythm, grounded street edges, and a clear approach lane. Video pixels, watermark, logos, skyline, and social UI are not used as texture or geometry. The circular Pipi Labu head / tiny lateral ear correction remains untouched; no character asset was edited or imported.

## Production contract

- Units: Roblox studs; `+Y` up, `+Z` service/front, `+X` right.
- Ground-center modules use origin `(0, 0, 0)`. The awning uses a rear-mount center pivot and extends toward `+Z`.
- Stall bay: exact bounds `[-6, 0, -4]` to `[6, 6.25, 4]`; front clearance is 4 studs.
- Review vignette: central service corridor is 8 studs wide, from `Z=4` to `Z=12`; lantern, planter, bollard, signs, and display detail are outside or behind the focal corridor.
- Structural pieces use separate bounded collision proxies. Fruit, sign faces, fabric stripes, and small display detail are display-only and must not receive collision/touch/query behavior.
- Import target: Blender 4.x LTS → applied transforms → FBX for the Roblox 3D Importer; OBJ is provided for inspection. No scripts are embedded.
- Budgets: 2,500 visual triangles/module, 96 collision triangles/module, 24,000 visual triangles/review assembly, six material roles/module.

The complete exact contract is `assets/candidates/pipilabu_market_environment_v1/market_kit_contract.json`.

## Evidence

- Generator: `assets/candidates/pipilabu_market_environment_v1/scripts/generate_pipilabu_market_kit.py`.
- Verifier: `assets/candidates/pipilabu_market_environment_v1/scripts/verify_pipilabu_market_kit.py`.
- Deterministic verifier result: `PIPILABU_MARKET_KIT_VERIFY_OK`; 12 modules; assembled visual vignette 1,020 triangles.
- Repeatability result: generator run twice; 58 generated OBJ/MTL/JSON files produced identical hashes.
- Syntax result: both Python scripts pass `py -3 -m py_compile` on Python 3.10.6.
- Structural report: `assets/candidates/pipilabu_market_environment_v1/verification/structural_report.json`.
- Blender executable was not available in this worktree. The optional `bpy` branch is present but no `.blend`/FBX output is claimed; the verified artifacts are the dependency-free OBJ meshes, contracts, layout, and report.

## Reference decisions

Accepted: market density as readable rhythm; fruit as the focal prop; warm wood/cream/vermilion/lantern roles; a compact grounded frontage; clear line-of-sight to the service event.

Contextual: Japanese city/farmers-market cadence and repeated stalls. They are expressed through this kit's own dimensions and materials, not copied composition or branding.

Rejected: pasted reference frames, watermark/social UI, generic baseplate sprawl, floating kiosks, decorative obstruction in the service lane, and prominent upright/top ears.

## Risks still open

- OBJ geometry is a review/import artifact, not Roblox technical validation. Pivots, FBX export, MeshPart fidelity, SurfaceAppearance wiring, collision fidelity, and Studio scale still need a sandbox pass.
- Materials are authored role metadata and flat OBJ colors; no final PBR maps, Roblox asset IDs, lighting, or moderation state are claimed.
- The roof/awning proxy is intentionally solid for honest collision. A future camera test may require a local cutaway treatment similar to the current shop, but that must preserve collision and not be solved by making the roof pass-through.
- The kit is deliberately low-poly and modular. Bevels, normals, fabric response, and small asymmetries need human review at the mobile gameplay camera before any presentation approval.
- This candidate has no interaction prompts, ownership, economy, neighbor-help authority, persistence, or gameplay integration.

## Exact future private-play integration gate

1. Record or deliberately defer the open v0.9.3 human service-loop gate. This candidate does not count as gameplay evidence and must not promote P1 or any other mechanic.
2. In a disposable local `PlaceId=0 / GameId=0` sandbox, import one visual module and its proxy through the Roblox 3D Importer. Validate origin, scale, material assignment, collision, touch/query flags, and a classic third-person/mobile sightline before importing the complete vignette.
3. For the bounded private test only, list Studio instances and assert `PlaceId=133099029551440` and `GameId=10646495069` inside the mutation. Work in Edit mode and create only `Workspace.PipilabuMarketEnvironmentCandidateV1` beside the existing world.
4. Do not edit or reparent `Workspace.DogeAppleShop`, do not change Rojo mappings or gameplay source, and do not upload/publish/publicize anything as part of this test.
5. Walk the lane and touch-test the stall bay, awning, shelves, curb, planter, and lantern proxies. Confirm the ready customer, counter, carried apple, and handoff remain readable at the authored approach; confirm display fruit/sign/stripe detail is non-collidable and no prompt is stolen.
6. Leo and Jon record the human verdict against the named questions: authoredness, compact Japanese market read, mobile scale, service sightline, honest collision, obstruction, and whether the environment makes the handoff more desirable. Only an explicit later decision may mark a version approved.

No approval, private integration, upload, publish, or live-place mutation occurred in this task.
