# Pipilabu Shiba v1

Original, generator-authored low-poly Shiba NPC for Pipilabu. It does not use geometry from Peepilabu, Doge, Cheems, videos, or Creator Store models.

## Variants

- `customer`: compact NPC at the generator's 1.0 scale.
- `owner`: the same topology, materials, bones, action names, and attachment contract at 1.65 scale for an oversized Peepilabu shopkeeper.

Each generated `.blend` and `.fbx` is self-contained. The neutral rig has `root`, `spine`, `head`, `jaw`, a two-bone tail, and upper/lower/end bones for four short limb chains. It includes action stubs for `Pipilabu_Idle`, `Pipilabu_Receive`, `Pipilabu_Hold`, and `Pipilabu_TurnLeave`.

Each variant also has a deterministic `*.preview.png` rendered from the same source. Preview cameras and lights are present in the `.blend` for inspection but excluded from FBX export.

Attachment empties are `ATTACH_Fruit_R`, `ATTACH_Fruit_L`, `ATTACH_Mouth`, `ATTACH_Back`, `ATTACH_ShopkeeperProp`, and `ATTACH_OrderBillboard`. `COLLISION_ROOT` is a non-rendering root/collision guide, not final Roblox collision geometry.

## Rebuild

This workstation uses the Blender 4.5 LTS Microsoft Store package because the Blender CDN returned HTTP 403 to WinGet. Install and select its command alias with:

```powershell
winget install --id 9PM7J9D3G6JQ --source msstore -e --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
$blender = "$env:LOCALAPPDATA\Microsoft\WindowsApps\blender-launcher.exe"
```

From the repository root, run:

```powershell
& $blender --background --factory-startup --python scripts/generate-pipilabu-shiba.py -- --variant customer --output-dir assets/models/pipilabu_shiba_v1
& $blender --background --factory-startup --python scripts/generate-pipilabu-shiba.py -- --variant owner --output-dir assets/models/pipilabu_shiba_v1
```

Headless verification:

```powershell
& $blender --background assets/models/pipilabu_shiba_v1/pipilabu_shiba_customer_v1.blend --python scripts/verify-pipilabu-shiba.py -- --expected-variant customer --sentinel .local/pipilabu-customer-verify.json
& $blender --background assets/models/pipilabu_shiba_v1/pipilabu_shiba_owner_v1.blend --python scripts/verify-pipilabu-shiba.py -- --expected-variant owner --sentinel .local/pipilabu-owner-verify.json
Get-Item assets/models/pipilabu_shiba_v1/*.fbx | Select-Object Name,Length
```

## Import notes

Import the FBX through Roblox Studio's 3D Importer in an isolated sandbox first. The procedural meshes use one rigid bone influence per mesh, so this is a prototype-quality animation base rather than a polished organic skin. Inspect bone and attachment conversion, scale, materials, ground contact, and animation clips before integrating it into gameplay. Build Roblox collision from a simple invisible root part using the `COLLISION_ROOT` guide; do not make the visible meshes collidable.

## Generated metrics (Blender 4.5.12 LTS)

Both variants contain 29 mesh objects, 1,162 vertices, 2,208 triangles, 18 bones, four action stubs, six attachments, and one collision guide. Customer bounds are approximately 1.75 x 2.05 x 3.15 Blender meters; owner bounds are 2.887 x 3.382 x 5.197 meters. Customer and owner differ only by the documented 1.0/1.65 scale multiplier.

Metrics are also written beside each asset as `*.metrics.json` on every rebuild. Use those generated reports as the exact source of truth because Blender/exporter versions can alter serialized sizes and triangle accounting.
