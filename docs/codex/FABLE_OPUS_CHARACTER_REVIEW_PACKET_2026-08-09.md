# Fable / Opus specialist packet: Pipi Labu character reconstruction

## Assignment and authority

You are the independent specialist critic for one hard production decision. Be candid. Do not modify files, invoke Blender, deploy, upload, publish, or widen scope. Codex remains the implementation owner and will reconcile your advice against runtime evidence.

The goal is not to make a generic cute Shiba. The goal is to produce a Roblox-ready owner/shopkeeper and a line of tiny customers that feel as though they came directly from the specific Pipi Labu / AI-Doge market videos Leo and Jon supplied.

## Founder correction that governs this review

Multiple technically valid 3D candidates failed the taste gate. Leo explicitly said the models are terrible, look like ordinary Roblox dogs/bears/seals, and do not resemble the reference videos. He also corrected the operating process: when a problem repeatedly exceeds Codex's current visual/craft capability and iterations stop producing useful information, Codex must automatically escalate to Fable/Opus instead of burning cycles or asking Leo to rescue it.

## Non-negotiable visual target

- The owner is an enormous, almost room-filling, rounded Shiba-like shopkeeper with a natural animal face and short planted forepaws.
- The customer is a tiny, low, rounded dog orb/loaf. A long clean line of them is part of the game's comfort fantasy.
- Crown: one broad, uninterrupted rounded skull/body silhouette.
- Ears: no readable top triangles. Only tiny, soft, laterally placed ear remnants visually swallowed by fur and crown mass. Front, side, three-quarter, animation, and Roblox gameplay views must all preserve this.
- Face: natural Shiba/Doge proportions, black wet-looking eyes and nose, short muzzle, restrained familiar smile. Avoid mascot, teddy-bear, seal, hamster, bulldog, or generic Roblox-pet facial language.
- Owner body: huge soft egg/loaf volume, cheek/neck mass, cream chest, very short legs/paws, no human torso or biped silhouette.
- Customer body: small rotund waddling orb with tiny feet; no sausage body, erect standard-Shiba ears, or plush-toy abstraction.
- Fur/material: warm caramel outer coat, cream lower muzzle/chest/belly, dense soft directional fur. It must still read at gameplay distance and under Roblox lighting; not plastic, flat orange, or noisy PBR.
- The target is comforting, funny, and alive rather than difficult, frantic, or blocky. Handoffs, eating, rejection, queue behavior, and animations ultimately need character life, but this review is specifically about securing the correct model foundation.
- No half measures: recognizable breed plus superficial recoloring is failure. The silhouette, face, proportions, and material response have to survive the full Blender-to-Roblox path.

## Images to inspect directly

Primary generated reconstruction sheet:

- `assets/concepts/pipi-labu-owner-reconstruction-sheet-v9.png`

Primary market-video frames supplied by Leo:

- `assets/reference/fable-review/market-video-owner-room.jpg`
- `assets/reference/fable-review/market-video-owner-counter.jpg`
- `assets/reference/fable-review/market-video-owner-customer-line.jpg`

Earlier concept/evolution evidence:

- `assets/concepts/pipi-labu-video-turnaround-v6.png`
- `assets/reference/fable-review/concept-evolution-archive.jpg`
- `assets/reference/fable-review/concept-direction-email.jpg`

Failed procedural model evidence (inspect enough to understand why it was rejected):

- `assets/models/pipilabu_video_turnaround_owner_v8/pipilabu_shiba_owner_v8.front.png`
- `assets/models/pipilabu_video_turnaround_owner_v8/pipilabu_shiba_owner_v8.side.png`
- `assets/models/pipilabu_video_turnaround_owner_v8/pipilabu_shiba_owner_v8.back.png`
- `assets/models/pipilabu_video_turnaround_owner_v8/pipilabu_shiba_owner_v8.preview.png`
- `assets/models/pipilabu_video_turnaround_customer_v8/pipilabu_shiba_customer_v8.front.png`
- `assets/models/pipilabu_video_turnaround_customer_v8/pipilabu_shiba_customer_v8.side.png`

## What has already failed

1. Procedural Blender v5-v8: technically rigged/exported, but visually primitive. Large or still-readable top ears, assembled primitives, weak natural anatomy, and surfaces far below the rendered concepts. Rejected/quarantined; never gameplay-promoted.
2. TripoSR single-view control: front was somewhat recognizable, but the side/back became wedge-like impostor geometry and exceeded budget. Rejected.
3. Roblox GenerateMesh: produced a generic upright large-eared Shiba. Rejected and quarantined in ServerStorage.
4. Licensed low-poly base deformation: honest geometry but owner read as bear/ordinary dog and customer as seal/sausage. Rejected before Studio import.
5. Texture-only/PBR iteration: incapable of repairing the wrong silhouette. Prior adapter even mistook empty SurfaceAppearance IDs for success; this was corrected.
6. Local Hunyuan3D-2mv experiment: official multi-view geometry control fits the GTX 1080 only with offloading. The first 40-step/octree-320 attempt occupied the GPU for roughly 142 minutes then exited without a GLB or retained error. The hardened retry records progress and preserves the latent before VAE/export, but after more than fifteen minutes had not completed its first reported diffusion step. This is a private geometry experiment only: Tencent's license has territory restrictions that make it unsafe for a globally shippable Roblox asset.

## Current machine and pipeline facts

- Windows desktop: GTX 1080 8 GB VRAM, 32 GB system RAM.
- C: is storage-constrained; D: has hundreds of GB free and holds the model cache/runtime.
- Blender can be driven programmatically and is available locally. Programmatic Blender is not the conceptual problem; the earlier procedural modeling strategy was.
- Best researched shippable candidate: MIT-licensed TRELLIS.2-4B on a 24 GB+ Linux GPU for full PBR GLB, paired where useful with MIT TRELLIS v1 multi-image control on 16 GB+. That likely requires a paid cloud GPU, which Codex cannot purchase without Leo's explicit spend approval.
- Free local fallbacks such as TripoSR/SF3D are single-view and already look inadequate for final hero characters.
- Hunyuan3D-2mv can be a no-spend local shape experiment but cannot be assumed release-safe and is extremely slow here.
- Research evidence is in `docs/codex/IMAGE_TO_3D_PIPELINE_RESEARCH_2026-08-09.md` and `docs/codex/BLENDER_TO_ROBLOX_FIDELITY_AUDIT_2026-08-09.md`.

## Roblox delivery constraints

- Private experience: GameId `10646495069`, PlaceId `133099029551440`.
- Prefer <=20,000 triangles per imported MeshPart; if a visual needs more, segment deliberately rather than relying on accidental importer reduction.
- Skinned meshes must respect Roblox bone/influence constraints and remain animation-friendly.
- Deliver separate visual/render mesh and simple collision/hit geometry.
- PBR maps must be complete and validated after upload; material presence is not proof of active PBR.
- Source art and textures must be rights-safe. The supplied AI-video frames are private inspiration/reference, not automatically redistributable source assets.
- Nothing should enter Studio or gameplay until orthographic and three-quarter likeness passes against the reference.

## Existing project truth to consult selectively

- `docs/codex/DICTATION_REQUIREMENT_AUDIT_2026-08-09.md`
- `docs/codex/HANDOFF.md`
- `docs/CHARACTER_ART_DIRECTION.md`
- `docs/codex/PLAYTEST_QUEUE.md`
- `docs/codex/IMAGE_TO_3D_PIPELINE_RESEARCH_2026-08-09.md`
- `docs/codex/BLENDER_TO_ROBLOX_FIDELITY_AUDIT_2026-08-09.md`

## Questions you must answer

1. Diagnose the actual failure. Is the bottleneck reference preparation, reconstruction-model selection, topology/material transfer, Blender craft, Roblox constraints, or a bad overall workflow? Rank causes.
2. Critique the v9 reconstruction sheet against the three market-video frames. Is it actually a trustworthy modeling target? Call out exact anatomical or stylistic drift, especially ears, crown, eyes, muzzle, paws, side profile, rear mass, and fur.
3. Decide whether Codex should stop the current GTX-1080 Hunyuan 40-step retry. Explain the evidence threshold rather than giving generic advice.
4. Give the most realistic route to a final game-ready likeness from the available evidence. Distinguish no-spend local work from the best paid-cloud route.
5. State what can be automated reliably and what requires deliberate artist-like sculpt/retopo/material judgment. Do not pretend an image-to-3D model is a finished asset.
6. If recommending TRELLIS or another remote model, specify the exact source-view preparation, model/version, approximate VRAM tier, output type, and how the result should be used as a sculpt/base rather than blindly shipped.
7. Give an exact Blender production recipe: base cleanup or sculpt steps, silhouette landmarks, topology/part segmentation, UV/material/fur strategy, rig/weights, LOD/collision strategy, export settings, and Roblox validation order.
8. Define visual acceptance criteria that would reject another technically valid but ugly model before Studio import. Include front, side, rear, three-quarter, animation-deformation, and gameplay-distance checks.
9. Recommend the next 3-5 actions in priority order. Be decisive. If professional/manual character modeling or a paid GPU is honestly required, say so and explain why.
10. Identify anything in the broader Pipi Labu direction that the model strategy must preserve: owner/customer scale contrast, comforting queue, natural creature animation, apple handoff/eating, and the desire for an alive town rather than a generic Roblox tycoon.

Return a compact but technically specific report. Separate observations, diagnosis, recommendation, acceptance gate, and immediate next actions. Do not flatter the existing work.
