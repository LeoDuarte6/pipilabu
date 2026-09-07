# Peepilabu Owner v4 — local review candidate

**Superseded technical evidence:** Leo's 2026-08-09 market-video frames supersede both this top-ear asset and the later v4 side-ear candidate. Preserve this import only as rig/action/recovery evidence. The target is a huge natural Shiba seller with swallowed/no readable top ears, low eyes, a real muzzle, tiny counter paws, and video-like plush material. Current v5 work lives under `assets/models/pipilabu_market_video_owner_v5/` and remains unapproved until Blender and Studio match the video at gameplay distance.

This folder contains the first structurally verified Peepilabu hero-owner candidate. It is deliberately scoped to the large counter NPC; it is not a player replacement.

## Files

- `pipilabu_shiba_owner_v4.blend`: authored Blender source with the nine-bone owner rig.
- `pipilabu_shiba_owner_v4.fbx`: Roblox geometry/rig import candidate. The August 7 Studio import created five KeyframeSequences under `ServerStorage.RBX_ANIMSAVES.pipilabu_shiba_owner_v4`; publishing and playing those sequences as Roblox Animation assets remains a separate gate.
- `*.preview.png`, `*.front.png`, `*.side.png`, `*.back.png`: neutral review renders.
- `*.colormap.png`, `*.normal.png`, `*.roughness.png`, `*.metalness.png`: SurfaceAppearance candidate maps.
- `pipilabu_shiba_owner_v4.metrics.json`: generator and asset contract readback.
- `roblox/OwnerShibaV4Candidate.rbxmx`: archival XML snapshot of the private Studio import. Do not map this model into live Rojo: Roblox does not allow Rojo to restore protected `MeshPart.MeshId` values, so live sync turns the model into gray blocks.
- `roblox/OwnerShibaV4Candidate.rbxm`: raw Studio binary recovery snapshot. Keep both snapshots outside the live project tree and use Studio's importer for the FBX when recovery is required.

The coat uses `assets/textures/peepilabu/shiba_short_fur_tile_v1.png` only as restrained strand variation over the authored caramel/urajiro mask. The Blender beauty material is matte diffuse so lighting cannot manufacture false glossy patches; eyes and nose retain separate glossy materials.

## Rig contract

Bones: `root`, `body`, `head`, `muzzle`, `ear_L`, `ear_R`, `paw_L`, `paw_R`, `tail`.

Actions: `Pipilabu_Idle`, `Pipilabu_Talk`, `Pipilabu_Serve`, `Pipilabu_Happy`, `Pipilabu_Stressed`.

Attachments: fruit on either paw, mouth, back, shopkeeper prop, and order/callout.

## Status

`StructurallyVerified = true`. Leo visually approved the front and three-quarter direction on August 7, 2026, then requested slightly livelier eyes; the current asset includes a restrained secondary catchlight and warm lower-eye reflection.

The private Studio geometry import passed with 22 mesh parts, nine bones, a correct roughly `3.47 x 3.58 x 4.85`-stud owner scale, and the separate eye-glint geometry intact. The valid Studio-managed candidate is quarantined at `ServerStorage.PipilabuCandidateAssets.OwnerShibaV4Candidate` and remains `TechnicalValidated = false`. Its five imported action sequences live under `ServerStorage.RBX_ANIMSAVES.pipilabu_shiba_owner_v4`.

The four PBR maps were privately uploaded on August 7 and their IDs are recorded as candidate attributes. On August 8, a bounded private Studio recheck proved the maps were available. The exact Edit DataModel now owns one `PipiLabuBodyPBR` SurfaceAppearance on `MainFusedBody`; Play read back all four content IDs with `RuntimeBodyPBRApplied=true` and `MaterialValidationState=BodyPBRLiveVerified`. Applying the atlas indiscriminately to all 22 meshes visibly corrupted paws and facial parts, so the body alone uses PBR while authored face geometry keeps its controlled palette. Runtime scripts cannot write SurfaceAppearance map properties under normal script capability; Studio-authored content is the correct persistence path.

Material availability is no longer the primary blocker. The prominent upper-ear silhouette is still rejected, and action/fruit-attachment playback plus the side-ear replacement reimport remain validation gates. `TechnicalValidated` and `ApprovedForPresentation` therefore remain false.

The roughness exporter also received a correctness fix: Blender's data colorspace is now selected before pixel population. Verified readback is uniformly `235/255` (approximately `0.92`) rather than the silently black/glossy map produced by the earlier ordering.

The active presentation owner remains v1 at `Workspace.PipilabuMarketVillagePrototype.PeepilabuQuestAnchor.OwnerShibaVisual`. Rojo is intentionally code-only; it must not own imported mesh instances.

Verification:

```powershell
blender pipilabu_shiba_owner_v4.blend --background --python ../../../scripts/verify-pipilabu-shiba.py -- --expected-variant owner --expected-model-version v4 --sentinel ../../../.local/peepilabu-owner-v4.verify.json
```
