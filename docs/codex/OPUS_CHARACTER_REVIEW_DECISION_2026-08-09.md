# Opus 5 character reconstruction decision — 2026-08-09

## Consultation receipt

- Requested lane: Fable, then exact Opus 5 as fallback.
- Fable: HTTP 429, zero tokens/cost; no Fable review occurred.
- Preliminary review: the `opus` alias resolved to `claude-opus-4-8`; its full read-only pass reported `$2.484231` cost.
- Final review: explicit `claude-opus-5`, authenticated Claude Code `2.1.212`, Max subscription, 27 read-only turns over the packet, all 13 named images, six project documents, the preliminary decision, both v10 images, and the procedural generator source. Claude Code reported `$2.2658845` cost.
- Neither specialist run modified files, ran Blender/Studio, uploaded assets, or published the experience.

## Final diagnosis

1. **There is no single locked owner target.** The room frame is a giant fused-neck orb with large round glossy eyes, short snub muzzle, and no visible ears. The two counter frames are a more naturalistic Shiba with longer pointed muzzle, almond eye, visible shoulder, and forelimb. Averaging those incompatible identities creates the generic uncanny middle that Leo rejected.
2. **The procedural modeling family is structurally incapable of solving the target.** It places scaled spheres/cubes/cones from front-view offsets, so eyes detach in profile and ear pyramids break the crown. Texture or exporter work cannot repair the surface.
3. **Review instrumentation let obvious failures survive.** Beauty-only renders hid detached pieces and broken silhouettes. Every candidate now needs registered orthographic silhouette and neutral-clay views before human review.
4. **The customer reference is an elongated four-limb marmot/Doge quadruped.** “No sausage” must mean no featureless capsule, not no length. A playable customer needs a separate head/neck, four weight-paintable limbs, hind feet, ground clearance, and a readable waddle.
5. **Scale is a core identity feature.** The source owner is approximately 5–6× the customer’s linear scale; the current shared-base 1.15–1.35× relationship cannot reproduce the reference fantasy.
6. **The v6 turnaround is the strongest existing source artifact.** It is the only registered multi-view set with coherent baselines, rear anatomy, ground contact, owner tail/haunch information, and four customer limbs. It should be corrected and re-registered rather than abandoned.
7. **Exact Roblox fur is impossible as a raytraced groom.** Softness must survive through zoned albedo/normal/roughness plus slightly irregular clumped silhouette geometry. A mathematically smooth dome becomes a vinyl toy in Studio.
8. **The counter-anchored owner can be optimized as a high-fidelity bust-and-paws character.** Spend topology/material budget above the counter; use a cheap sealed lower shell for occluded mass.

## Superseded preliminary conclusions

- The v10 owner and customer fronts are **retired as reconstruction conditioning**. Keep them only as face/material mood evidence.
- The v10 owner overcorrected toward narrow stern eyes and uniform short velvet. If the room-orb identity wins, restore large round wet eyes and use zonal fur: short face, medium-plush crown/body, broken rim contour.
- The v10 customer is a legless dome and cannot support queue walking, paw receipt, three-bite eating, or leave animations. Its compact material/face language may inform paint only.
- “Cloud GPU or manual sculpt” was a false binary. TRELLIS can accelerate blockout, but the project still requires roughly 15–30 hours of deliberate character-art work. Cloud compute does not buy the face, coat, topology, or rig.
- The preliminary v9 critique missed the visible pointed ear violations in its side and three-quarter views. Those views fail the highest-priority design rule.

## Accepted production route

- First lock one owner identity: **A, room-frame giant orb** (specialist recommendation and strongest gameplay/meme read), or **B, counter-frame naturalistic Shiba**.
- Correct and re-register v6 into one scale-locked orthographic set per character. Preserve customer limbs/head-neck separation; correct the owner’s chosen eyes/muzzle/fur; remove every readable ear peak.
- Best no-spend route: deliberate Blender multires sculpt from the corrected v6 turnaround.
- Optional paid seed: MIT TRELLIS.2-4B on 24 GB+ Linux GPU, 8–12 owner seeds at 512³ and two finalists at 1024³, with TRELLIS v1 multi-image as a cross-check from the corrected v6 views. Judge output untextured; use only as a sculpt blockout.
- Closed lanes: procedural ellipsoids, generic Roblox GenerateMesh, TripoSR/SF3D final candidates, low-poly deformation, and Hunyuan (license plus measured runtime failure).

## Implemented immediately

- Stopped the exact Hunyuan 40-step process tree after zero recorded steps/output and preserved its directory/logs. GPU load dropped from 100% / ~7.8 GB to idle levels.
- `scripts/inspect-triposr-in-blender.py` now renders registered orthographic front, three-quarter, left, rear, and right sets in beauty, neutral-clay, and black silhouette modes; emits three PNG contact sheets; preserves legacy cardinal renders; and records the camera scale/view list in `mesh-stats.json`.
- A real Blender 4.5.10 smoke pass on the rejected licensed owner produced all 15 registered frames, all three contact sheets, a saved `.blend`, and `PIPILABU_BLENDER_INSPECTION_OK` under `.local/inspection-gate-smoke`. Visual inspection confirmed the silhouette pass exposes the wrong doglike profile immediately.
- Preserved the v10 owner/customer fronts under `assets/concepts/` as rejected conditioning/mood evidence; they are not approved designs or 3D assets.

## Hard pre-Studio acceptance gate

- Pure-black registered orthographic front/side/rear/three-quarter silhouettes first. Any ear peak, detached element, straight synthetic fur boundary, featureless capsule, or inconsistent identity rejects the mesh.
- Registered neutral-clay contact sheet at the exact same camera and scale. Beauty renders cannot overrule it.
- Owner front/side must match the single chosen identity; the customer must expose four separable limbs and pass a readable waddle deformation before Studio import.
- The owner/customer 5–6× hierarchy must read at actual mobile gameplay distance beside the market frames.
- Complete wired PBR maps and legal triangle/influence counts remain necessary but not sufficient.
- Owner Idle/Talk/Serve/Happy/Stressed and customer approach/hold/three-bite/leave must preserve the intended silhouette without nose burial, paw spikes, intersections, or emerging ears.

## Owner identity decision — resolved by Leo

- **Owner target: A, room-frame giant orb.** Keep the monumental fused neck/body, broad rounded crown, swallowed lateral ears, tiny planted forepaws, and room-filling scale.
- **B remains valid, but separate.** Leo also likes the cute counter-frame naturalistic Shiba. Preserve it for another character or as facial/anatomical evidence; do not average its upright shoulder/limb silhouette into the owner.
- The original reel is the owner's facial source of truth: small low-set wet eyes beneath a heavy brow, broad cheek-to-muzzle mask, compact nose, and the odd curved Pipi Labu smile. Generic Doge, puppy, Cheems, and Pomeranian faces remain rejected.
- `assets/concepts/pipi-labu-owner-reconstruction-sheet-v11.png` is the current registered 2D reconstruction target. It is a modeling reference, not an approved mesh or active Studio character.

The next executable art step is one deliberate owner sculpt/blockout against v11 and the reel frames, followed by registered silhouette and neutral-clay rejection gates—not another broad procedural model batch.

### Original alternatives considered

The specialist presented these two alternatives before Leo resolved the decision:

- **A — room-frame giant orb:** fused neck/body, large round glossy eyes, snub muzzle, no visible ears; strongest meme and gameplay-distance identity. Recommended.
- **B — counter-frame naturalistic Shiba:** longer muzzle, almond eye, cheek ruff, readable shoulder/forelimb; more animal-realistic but less orb-like.

After that one sentence, the next executable step is the corrected v6 registered turnaround and one owner sculpt/blockout—not another broad model batch.
