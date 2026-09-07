# Pipilabu Character Art Direction

## Current character hierarchy

- **Peepilabu** is the hero owner NPC and the current character-art priority. He is not the player avatar.
- The **player** remains a normal Roblox character during the current gameplay and art gates. A short, color-customizable worker-dog avatar is a later experiment, not a dependency.
- Main **customer NPCs** should read as expressive Shiba/Doge characters performing human social roles. “Anthropomorphic” describes their behavior and posing; it does not require every character to use a human biped skeleton.
- **Baby customers** may use the low four-legged loaf anatomy from the supplied clips when that contrast improves cuteness.
- **Drog/frog hybrids** are reserved for a later special customer or event. They do not define the base cast.

## Peepilabu hero target

Pipi Labu is the huge, warm Shiba seller in Leo's supplied market-video frames: an oversized natural head and upper body behind the counter, tiny planted paws, low dark eyes, compact black nose, heavy cream lower cheeks/muzzle, and a restrained friendly expression. The ears are folded back, swallowed by fur, or outside the visible crown; there must be no readable upright top-ear triangles. The customer line uses the same reference family's tiny, low, quadrupedal Shiba/loaf anatomy. This exact video appearance—not a generic round cartoon dog, not the procedural v4 render, and not the upright-ear concept sheet—is the canonical modeling and material target.

Primary references:

- `assets/reference/peepilabu-market-reference.mp4`
- `.local/peepilabu-material-reference/frame-01.png` through `frame-06.png`
- Leo's attached 2026-08-09 market-video frames and `assets/reference/peepilabu-market-reference.mp4` are the primary owner/customer appearance, proportion, fur, and staging target.
- `assets/concepts/peepilabu_character_sheet_v1.png` is staging and expression evidence only; its visible top ears and stylized sculpt are not model truth.
- `assets/concepts/pipilabu_customer_v2_turnaround.png` is supporting low-silhouette evidence only where it agrees with the video animal.
- `assets/concepts/pipilabu_shopkeeper_player_v1_turnaround.png` is a later standing-role exploration, not the current owner/customer anatomy.
- `docs/codex/ROBLOX_DOG_REFERENCE_AUDIT_2026-08-09.md` records Leo's four Roblox references. Dog Frog is the strongest engine-material benchmark; none is final visual truth.

## Material target

Geometry establishes the large readable silhouette; material work supplies the soft video-rendered finish.

- caramel crown/back with a soft, irregular urajiro transition on the lower cheeks, muzzle, belly, and paws
- no cream forehead mask
- restrained baked ambient occlusion under chin, paw seams, ear roots, and lower belly
- subtle directional plush normal detail that disappears at distance rather than noisy fake fur
- very matte fur (`roughness` about `0.90–0.95`)
- glossy eyes and nose (`roughness` about `0.15–0.30`)
- metalness always zero
- warm key light, soft neutral fill, clean ground contact, and a neutral studio background for review

The supplied video is a palette, softness, and rendering reference. Do not paste compressed video pixels, social UI, logos, or baked lighting directly onto the production mesh.

## Rig and animation contract

The owner rig only needs the bones that make Pipi Labu feel alive: root, squashable body, head, muzzle, optional swallowed/folded ear controls, two paws, and tail. Ear motion must not create top peaks. Required preview actions are `Idle`, `Talk`, `Serve`, `Happy`, and `Stressed`. Walking is not required while Pipi Labu is anchored behind the counter.

Fruit and shop props attach to either paw. The mouth, order/callout, and back attachments remain explicit. Deformation must preserve the round silhouette and avoid visible primitive intersections.

## Art gate

Nothing is imported into the canonical Studio place until all of the following pass:

1. Front, three-quarter, side, and rear renders clearly read as the same character.
2. The caramel forehead, cream lower muzzle, low oval eyes, natural Shiba head mass, absent/swallowed top ears, and tiny paws match Leo's exact video frames.
3. No visible primitive seams, holes, spikes, flat-bar mouth, floating paws, or debug materials remain.
4. Color, normal, roughness, and metalness maps exist and are wired to the review material.
5. The five required actions deform cleanly and fruit attachment remains aligned.
6. The model still reads at a mobile gameplay camera distance.

Rejected iterations remain local evidence and must not be marked `ApprovedForPresentation`.
