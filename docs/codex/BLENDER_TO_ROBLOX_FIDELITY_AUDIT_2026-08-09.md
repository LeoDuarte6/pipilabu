# Blender-to-Roblox fidelity audit

Date: 2026-08-09
Scope: Pipi Labu owner/customer market-video-faithful replacement pipeline. Research sources are limited to Roblox Creator Hub and the Blender manual. This is a diagnostic/import packet; it does not upload, replace, or publish an asset. Leo's latest 2026-08-09 evidence requires the natural Shiba seller/tiny quadruped family in the supplied video frames, with no readable upright top-ear triangles.

## Verdict

The current Studio character cannot honestly be expected to match the Blender beauty render yet. The source mesh may be intact, but the render and import pipelines are not equivalent:

- `scripts/generate-pipilabu-shiba.py` renders the fused body through a custom matte beauty shader fed by vertex color plus a generated-coordinate fur tile and bump.
- The exported Roblox ColorMap is deliberately **not connected** to the Principled BSDF Base Color and is marked `baked_colormap_review_required`.
- The FBX exporter currently uses `path_mode="AUTO"` and `embed_textures=False`, while Roblox's documented Blender FBX route is Path Mode **Copy** with **Embed Textures** enabled.
- The material stores `roblox_surfaceappearance_*` custom properties, but Roblox documents native import through supported Principled BSDF connections or explicit Studio `SurfaceAppearance` map assignment—not those custom properties.
- The body NormalMap is a separate synthetic map. Blender's beauty render uses the fur tile's Bump node instead, so even a correctly loaded SurfaceAppearance is not displaying the same surface signal.
- The base FBX bakes every action with `bake_anim_use_all_actions=True`. Roblox's current general specification supports one animation track per mesh/model export and directs creators to use separate exports for multiple animations.
- Current candidate metrics report 22 mesh objects and 21,326 total triangles. That total is not itself a violation because Roblox's general cap is **20,000 triangles per individual mesh**, but every imported child must be checked separately.

The fastest reliable fix is a **bake-equivalence pass**, followed by a clean sandbox reimport of the exact side-ear source. Do not try to approximate the render by tinting gray parts or spreading the body atlas across all 22 meshes.

## Supported pipeline to use

### 1. Prepare one deterministic export scene

- Rebuild from Leo's exact supplied market-video frames and `assets/reference/peepilabu-market-reference.mp4`; do not re-create or reshape the silhouette in Studio. Concept sheets are staging evidence only where they agree with the animal in the video.
- Give every mesh and bone a unique, stable name. Reimport matches mesh hierarchy paths and names; a rename creates a new MeshPart rather than updating the old one ([Roblox reimport](https://create.roblox.com/docs/art/modeling/reimport)).
- Apply mesh rotation and scale before export; leave the rig in its bind pose. Roblox requires frozen bone transforms, a root at `0,0,0`, no Root-bone skin influence, and at most four bone influences per vertex ([Roblox general mesh specifications](https://create.roblox.com/docs/art/modeling/specifications)). Blender warns that applying armature transforms should happen before rigging/animation ([Blender Apply transforms](https://docs.blender.org/manual/en/latest/scene_layout/object/editing/apply.html)).
- Recalculate outward-facing normals, retain intentional smooth/sharp boundaries, and inspect the low-poly silhouette with the same normals that will export. Do not use `Make Double Sided` to conceal inverted faces; it costs more and does not repair normals ([Roblox 3D Importer](https://create.roblox.com/docs/studio/importer)).
- Keep each mesh watertight, with volume and no unsupported geometry; keep every individual mesh below 20,000 triangles ([Roblox general mesh specifications](https://create.roblox.com/docs/art/modeling/specifications)).
- Use one UV set per mesh, entirely in `0..1`. Roblox supports overlapping islands but not multiple UV sets ([Roblox texture specifications](https://create.roblox.com/docs/art/modeling/texture-specifications)).

### 2. Make the Blender validation material equal the Roblox material

For `MainFusedBody`, build a duplicate **Roblox-validation** material and render it side-by-side with the beauty material:

- ColorMap image `Color` → Principled BSDF `Base Color`.
- Roughness image `Color` → `Roughness`.
- Metalness image `Color` → `Metallic`.
- OpenGL tangent-space NormalMap image `Color` → Blender `Normal Map` node `Color`; `Normal Map.Normal` → Principled BSDF `Normal`.
- ColorMap uses its color space. Normal, roughness, and metalness are data maps and should be treated as Non-Color data. Blender explicitly requires Non-Color for tangent-space normal images and matching UVs ([Blender Normal Map node](https://docs.blender.org/manual/en/latest/render/shader_nodes/vector/normal_map.html)); Blender's color-management manual says data images must not undergo color-space conversion ([Blender color management](https://docs.blender.org/manual/en/latest/render/color_management.html)).
- Roblox accepts only **OpenGL tangent-space** normal maps; DirectX/Y-inverted normals will shade incorrectly ([Roblox texture specifications](https://create.roblox.com/docs/art/modeling/texture-specifications)).
- Use an albedo map without baked lamp highlights or shadows. Roblox warns that baked lighting in a diffuse map conflicts with engine lighting ([Roblox PBR textures](https://create.roblox.com/docs/art/modeling/surface-appearance)).

The Roblox-validation render is the actual export gate. If it does not closely match the beauty render in Blender under the same camera and neutral lights, the FBX cannot fix that gap. Re-bake the fur/vertex-color signals into the supported Color/Normal/Roughness maps first.

Roblox supports one material per mesh. Keep the body atlas on `MainFusedBody` only; eyes, glints, muzzle, paws, and other authored face pieces must retain their own material/color role. Applying the body atlas to all 22 meshes is structurally wrong, not a moderation problem ([Roblox texture specifications](https://create.roblox.com/docs/art/modeling/texture-specifications)).

### 3. Export geometry/rig FBX

Use these Blender FBX settings for the base character:

- Limit to selected: armature, visible mesh objects, and required attachment empties only.
- Transform: **Apply Scalings = FBX Unit Scale**; all other scale values `1.0`.
- Axis labels: **Z Forward**, **Y Up**, following Roblox's Blender workflow.
- Geometry: export normals/smoothing; use the Tangent Space option for the tangent-space normal workflow, then inspect seams in Studio. Blender documents that FBX can export modifiers and tangent-space data ([Blender FBX exporter](https://docs.blender.org/manual/en/latest/addons/import_export/scene_fbx.html)).
- Armature: **Add Leaf Bones off**; export deform bones. Preserve a zero-influence bone only if it is deliberately required as an imported attachment/control bone.
- Animation: **Bake Animation off** for the base geometry/rig FBX.
- Path Mode: **Copy**; **Embed Textures on** after the exact validation material is connected.

These are Roblox's documented FBX defaults for scale, leaf bones, animation, and embedded media ([Roblox export settings](https://create.roblox.com/docs/art/modeling/export-requirements)). A separate-map path is also valid, but then every approved map must be explicitly uploaded and attached to the correct SurfaceAppearance in Studio; an FBX with `AUTO`/no embedding should not be judged as a render-equivalent material import.

For animations, export one action per FBX with Bake Animation on, a bounded frame range, and only that action active. Do not rely on `bake_anim_use_all_actions=True`; Roblox documents a single animation track per export ([Roblox general mesh specifications](https://create.roblox.com/docs/art/modeling/specifications)).

### 4. Import in the guarded `PlaceId=0` sandbox first

- `Import Only As Model`: on.
- `Upload to Roblox`: off for the first local geometry/material comparison; on only for the already-authorized private upload pass.
- `Add to Workspace`: on.
- `Insert Using Scene Position`: off for the isolated asset test unless world placement is intentionally authored in Blender.
- `Set Pivot to Scene Origin`: on, with the armature/root authored at scene origin.
- `Rig Type`: Custom.
- `Keep Zero Influence Bones`: on only if one of the six attachment/control seams depends on them; otherwise off.
- `World Forward`: Front; `World Up`: Top.
- `Scale Unit`: match the source scene contract and verify the preview dimensions against the recorded owner/customer bounds. Roblox's recommended same-unit workflow is Blender Unit System None plus Studio Studs; the current generator declares Metric `1.0`, so this must be an explicit A/B check, not another by-eye scale correction ([Roblox Blender workflow](https://create.roblox.com/docs/art/blender)).
- `Merge Meshes`: off. The 22 pieces carry different visual/material roles.
- `Invert Negative Faces`: off unless the preview identifies a specific incorrectly oriented source face; repair source normals instead.
- `Make Double Sided`: off.
- `Ignore Vertex Colors`: off for diagnostic import, because the source body uses vertex colors. The final render-equivalent path should nevertheless be proven with the baked ColorMap.
- `Use Imported Pivot`: on for each child.

Expand every importer warning down to the affected child before importing. The Importer explicitly reports per-object geometry, dimensions, polycount, and warnings ([Roblox 3D Importer](https://create.roblox.com/docs/studio/importer)).

### 5. Attach and verify PBR without moderation ambiguity

For explicit SurfaceAppearance assignment, use the recognized suffix family in one directory, for example:

- `PipilabuOwner_Color.png`
- `PipilabuOwner_Normal.png`
- `PipilabuOwner_Rough.png`
- `PipilabuOwner_Metal.png`

Roblox reimport recognizes `color/col/diffuse/albedo`, `normal/nor/nrm`, `rough/roughness/rgh`, and `metal/metallic/metalness/met` suffixes ([Roblox reimport](https://create.roblox.com/docs/art/modeling/reimport)). The present `.colormap/.normal/.roughness/.metalness` filenames are not the clearest documented reimport convention; use explicit recognized suffixes for the diagnostic copy without renaming canonical sources yet.

After private upload, verify all of the following from the correct experience:

1. Every MeshId and image asset resolves—no empty ContentId.
2. `MainFusedBody` owns exactly one complete SurfaceAppearance with non-empty ColorMap, NormalMap, RoughnessMap, and MetalnessMap.
3. No body SurfaceAppearance is attached to face/paw/glint meshes.
4. The imported asset owner and the private experience have access. Restricted assets without permission do not load and produce an Output error ([Roblox asset privacy](https://create.roblox.com/docs/projects/assets/privacy)).
5. Moderation has completed. Roblox says imported assets generally clear within a few hours, and users cannot see assets still in the queue ([Roblox assets and moderation](https://create.roblox.com/docs/projects/assets)).

## Repo-specific diagnostic checklist

- [ ] Generate the market-video-faithful owner/customer replacement. Existing concept, v4, and side-ear files are comparison/rollback evidence, not the target.
- [ ] Capture Blender beauty and Roblox-validation renders from the same camera, pose, neutral lights, and exposure.
- [ ] Diff the two renders before export; record silhouette, albedo, face palette, roughness, and fur-normal differences separately.
- [ ] Confirm the ColorMap is actually connected for the export copy; remove the current `baked_colormap_review_required` gate only after a UV-island visual review.
- [ ] Confirm normal/roughness/metalness images are Non-Color and the normal is OpenGL tangent-space.
- [ ] Confirm every individual mesh is under 20,000 triangles; do not confuse the 21,326-model total with a per-mesh failure.
- [ ] Confirm every vertex has 1–4 non-root influences, bone names are unique, and the root is at origin with unit scale/zero rotation.
- [ ] Export a base FBX with Bake Animation off and Copy+Embed on.
- [ ] Export `Idle`, `Talk`, `Serve`, `Happy`, `Stressed`, `Hold`, `Receive`, `Run`, and `TurnLeave` as separate action FBXs as applicable.
- [ ] Import with Merge Meshes off and record the exact preset, dimensions, child triangle counts, and every warning.
- [ ] Compare Studio under neutral Future lighting first, then under the actual market lighting. PBR should remain coherent across lighting rather than being tuned to one beauty setup.
- [ ] Verify the natural Shiba mass, folded/swallowed ears, owner/customer scale contrast, and low quadruped customer silhouette in front, three-quarter, profile, idle, walk/run, receive/serve, and exit poses.
- [ ] Verify the four PBR IDs from a fresh Studio process after moderation and permission grants; an empty or pending surface is a failed test, not a gray fallback to ship.
- [ ] Promote only if the Studio capture matches the Roblox-validation Blender render closely at gameplay camera distance. Preserve the previous imported candidate as rollback.

## Most likely causes, ranked

1. **Shader contract mismatch:** the beauty shader contains generated-coordinate fur/bump and vertex-color logic that is not represented identically in the exported SurfaceAppearance maps.
2. **Texture export mismatch:** the current generator does not use Copy+Embed and leaves the baked ColorMap disconnected.
3. **Incomplete/pending SurfaceAppearance:** a map with an empty, unmoderated, or unauthorized ContentId makes the result visibly flat, gray, or fallback-colored.
4. **Wrong material scope:** spreading the body atlas across eyes, paws, and face pieces corrupts the authored palette.
5. **Lighting/exposure mismatch:** a Blender beauty rig is not the market's Roblox lighting; compare with a neutral equivalence render before artistic lighting.
6. **Normals/tangent mismatch:** wrong-facing normals, accidental flat shading, or a DirectX normal map makes rounded forms read faceted or dented.
7. **Unsupported animation packing:** all-actions-in-one FBX is outside Roblox's documented one-track export contract and can make the in-game result feel much more primitive even when the mesh is correct.
