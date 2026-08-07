# Doge Asset Pipeline

## Rule

Reference images are for silhouette exploration, not automatic production rigs. The final Doge should be an original Blender-authored model with known rights, predictable topology, stable attachments, and a tested animation contract.

## Pipeline

1. Keep a source-and-rights ledger for every reference and imported asset.
2. Explore three quarantined lanes: Roblox generated mesh, an eight-part procedural silhouette, and a Creator Store candidate with every script removed or disabled before inspection.
3. Choose a silhouette without coupling gameplay to it.
4. Build an original upright low-poly Shiba in Blender: roughly 6–10k triangles for the player, 2–4k for customers, and one 512px atlas.
5. Use R15/Humanoid for the playable Doge. Use a lightweight custom rig with `AnimationController` and `Animator` for customers.
6. Require the model contract `Root`, `Head`, `AppleGrip`, `OrderBillboardAttachment`, and `Animator`, plus `CharacterKind`, `RigVersion`, and `VisualVariant` attributes.
7. Player animations: idle, walk, carry, take, handoff, celebrate. Customer animations: idle, ask, receive/cheer, impatient, leave.
8. Import into a guarded sandbox first. Run moderation, console, collision, pooling, and performance checks before replacing the primitive gameplay models.

## Official Roblox references

- [Intellectual property](https://create.roblox.com/docs/marketplace/intellectual-property)
- [Modeling specifications](https://create.roblox.com/docs/art/modeling/specifications)
- [Rigging](https://create.roblox.com/docs/art/modeling/rigging)
- [Blender workflow](https://create.roblox.com/docs/art/blender)
- [Export requirements](https://create.roblox.com/docs/art/modeling/export-requirements)
- [3D Importer](https://create.roblox.com/docs/studio/importer)
- [Avatar Auto Setup](https://create.roblox.com/docs/avatar-setup)
- [Animation Editor](https://create.roblox.com/docs/animation/editor)
- [Gamepad input](https://create.roblox.com/docs/input/gamepad)

## Prototype audio ledger

These Creator Store sounds are private-prototype placeholders, not final identity audio. Replace them with original/licensed studio sound design before public release.

- Pickup: [`pick_up2`, asset 7381723941, creator thienbao2109](https://create.roblox.com/store/asset/7381723941)
- Serve: [`Audio_jingle_chime_07_positive`, asset 99980076888596, creator Jefersongree](https://create.roblox.com/store/asset/99980076888596)
