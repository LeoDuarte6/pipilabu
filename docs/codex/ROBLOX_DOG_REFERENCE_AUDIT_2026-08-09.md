# Roblox dog reference audit — 2026-08-09

Leo supplied four Roblox catalog references as inspiration or possible placeholders. The exact market-video frames remain visual authority; none of these assets independently nails Pipi Labu and none is approved as the final character.

| Reference | Official metadata | Useful evidence | Rejected drift | Safe role |
|---|---|---|---|---|
| [Dog Frog — What the Dog Doing](https://www.roblox.com/bundles/90135622259414/Dog-Frog-What-the-Dog-Doing) | BodyParts bundle by group `Jo.`; six body parts plus dynamic head/default mood | Strongest fur read, glossy low eyes, natural muzzle, swallowed/folded ears | Upright biped torso, long flipper arms, frog-like hands/feet | Best Roblox material/face benchmark and possible isolated temporary rig test |
| [What the dog doin Pipilabu](https://www.roblox.com/catalog/92943054343364/What-the-dog-doin-Pipilabu) | Asset type 8 hat by group `r3birth!` | Low round body, natural Doge muzzle, folded/swallowed ears | Knife/shield and tiny hands are identity-breaking; hat is not an NPC animation rig | Silhouette/face reference only; never insert with weapons into gameplay |
| [doge meme funny 67](https://www.roblox.com/catalog/95046427956515/doge-meme-funny-67) | Asset type 44 shoulder accessory by group `kizazo` | Same low radial anatomy and front face | Faceted mesh, weapons, shoulder-accessory contract, weakest material finish | Topology failure comparison only |
| [Cheems](https://www.roblox.com/bundles/227001796848590/Cheems) | BodyParts bundle by group `TrueYoung Bundle`; six body parts plus dynamic head/default mood | Conventional Roblox bundle anatomy and Shiba markings | Long upright biped body, visible top ears, weaker fur/face match | Bundle/animation compatibility reference, not silhouette truth |

## Private Dog Frog runtime inspection

The official bundle API resolved Dog Frog into creator group `Jo.` (`32405681`), dynamic head `88169437852709`, torso `82937831822382`, arms `107635474634544` / `78039362347276`, and legs `114957716288089` / `111753275541477`. A private local Studio rig was created from those exact IDs, its default `Animate` LocalScript was removed, all parts were made noncolliding, and the model was quarantined at `ServerStorage.PipiLabuReferenceAssets.DogFrogBundleRig_ReferenceOnly` with bundle/creator provenance and `NoGameplayUse=true`.

Play-mode inspection confirmed the face/material value directly: low glossy eyes, natural projected muzzle, soft fur, and lateral swallowed ears are materially closer to Leo's video than the procedural v4/v5 faces. It also confirmed the rejection: upright biped torso plus frog-like hands/feet do not match either the huge counter seller or tiny low customer line. The safe extraction is a face/fur/muzzle/material benchmark, not creator-mesh substitution.

## Decision

- Build an original market-video-faithful owner/customer v5 family.
- Borrow technical lessons, not mesh identity: Dog Frog's fur/eye/muzzle treatment; the two low accessories' face-to-body ratio; Cheems's standard bundle separation only where a Roblox-compatible rig benefits.
- Do not extract, republish, or silently rebrand creator geometry. Any placeholder insertion stays quarantined, script-audited, removable, and explicitly labeled with its creator/asset ID.
- A placeholder cannot satisfy the character gate. Promotion requires a Blender Roblox-equivalence render and a Studio capture that both match Leo's video frames at gameplay distance.
