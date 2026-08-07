# Pipilabu Roblox Asset Pipeline

## Direction

Use an original, cute shiba-inspired character rather than tracing a Peepilabu frame or shipping an unaudited free model. The target is an oversized head and muzzle, compact paws and body, a readable curled tail, clean silhouettes at Roblox camera distances, and bespoke idle, receive, hold, react, turn, and leave animations.

## Candidate references — isolate before inspection

Do not insert these into the canonical place. Open a blank local file, inspect every descendant and script, and retain only audited geometry or rigging knowledge.

- Roblox-authored Doge placeholder: asset `257489726`
- Third-party Doge rig lead: asset `14798980192`
- Third-party chubby Shiba lead: asset `10713914356`
- Third-party Cheems NPC lead: asset `13588547668`
- Exact-phrase model lead: asset `82613448975617`
- Third-party fixed Doge derivative: asset `76091554732151`

Creator Store availability is not proof of safe code, rig quality, licensing clarity, or clean meme/IP rights. Free models can contain scripts and runtime loaders.

## Production workflow

1. Model an original R1-style NPC in Blender with root, spine, head/jaw, tail, and four short limb chains.
2. Use simple UVs and hand-painted albedo; keep materials restrained and readable.
3. Parent with automatic weights, then manually repair mouth, shoulder, hip, and tail deformation.
4. Freeze transforms; keep the root at the origin, no more than four bone influences per vertex, and stay comfortably below Roblox mesh limits.
5. Export FBX with Path Mode `Copy` plus embedded textures, `FBX Unit Scale`, no leaf bones, and no baked animation for the base mesh.
6. Import through Studio's 3D Importer. Validate scale, bone hierarchy, materials, and a simple invisible collision/root shape.
7. Author each animation separately in Blender or Roblox Animation Editor.
8. Test solo client/server, then two-client Server & Clients or Team Test, followed by mobile/device emulation.

## Official references

- [Roblox rigging and skinning](https://create.roblox.com/docs/art/modeling/rigging)
- [Roblox modeling specifications](https://create.roblox.com/docs/art/modeling/specifications)
- [Roblox export requirements](https://create.roblox.com/docs/art/modeling/export-requirements)
- [Roblox Animation Editor](https://create.roblox.com/docs/animation/editor)
- [Roblox assets and moderation](https://create.roblox.com/docs/projects/assets)
- [Roblox Creator Store](https://create.roblox.com/docs/production/creator-store)
- [Roblox testing modes](https://create.roblox.com/docs/studio/testing-modes)
- [Blender armature skinning](https://docs.blender.org/manual/en/3.4/animation/armatures/skinning/introduction.html)
- [Blender FBX export](https://docs.blender.org/manual/en/latest/addons/import_export/scene_fbx.html)

Imported assets remain private until explicitly shared and can remain unavailable while moderation runs. Uploads and place permissions require Leo's explicit authorization.
