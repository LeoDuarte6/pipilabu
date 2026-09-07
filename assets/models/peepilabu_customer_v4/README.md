# Peepilabu Customer V4

**Superseded technical evidence:** Leo's 2026-08-09 market-video frames supersede both this top-ear asset and the later v4 side-ear candidate. Preserve this import only as rig/action/recovery evidence. Customers now target the tiny, belly-low quadrupedal Shiba/loaf line in the video, with swallowed/no readable top ears and natural face/fur. Current v5 work lives under `assets/models/pipilabu_market_video_customer_v5/` and remains unapproved until Blender and Studio match the video at gameplay distance.

Small queue-customer counterpart to the approved Peepilabu owner v4. It deliberately keeps the owner's warm round silhouette, living catchlights, urajiro muzzle/chest pattern, curved smile, cream paws, short-fur treatment, and non-player custom-rig contract at the `customer` scale multiplier (`1.0` versus the owner's `1.65`).

## Generated asset

- `pipilabu_shiba_customer_v4.blend` — authored Blender source.
- `pipilabu_shiba_customer_v4.fbx` — Roblox-import candidate with armature, attachments, and baked actions.
- `pipilabu_shiba_customer_v4.{colormap,normal,roughness,metalness}.png` — 1024 px SurfaceAppearance map set.
- `pipilabu_shiba_customer_v4.{preview,front,side,back}.png` — neutral silhouette review.
- `pipilabu_shiba_customer_v4.{receive,hold,happy,run}.png` — deformation review at meaningful action frames.
- `pipilabu_shiba_customer_v4.metrics.json` — generator and structural metrics.

The six authored actions are `Pipilabu_Idle`, `Pipilabu_Receive`, `Pipilabu_Hold`, `Pipilabu_Happy`, `Pipilabu_TurnLeave`, and the in-place bouncy `Pipilabu_Run`. Fruit, mouth, back, order-billboard, and shopkeeper-prop seams remain available through the six standard `ATTACH_*` markers.

## Reproduce

Run Blender 4.5 LTS from the repository root:

```powershell
blender-launcher.exe --background --python scripts/generate-pipilabu-shiba.py -- --variant customer --model-version v4 --output-dir assets/models/peepilabu_customer_v4
```

Verify the generated source and FBX contract:

```powershell
blender-launcher.exe assets/models/peepilabu_customer_v4/pipilabu_shiba_customer_v4.blend --background --python scripts/verify-pipilabu-shiba.py -- --expected-variant customer --expected-model-version v4 --sentinel .local/peepilabu-customer-v4.verify.json
```

## Validation status

Headless validation passes for the exact customer identity, nine-bone contract, six non-empty actions, six attachment seams, one connected watertight fused body, no more than three influences per fused-body vertex, the body triangle budget, FBX presence, and all four PBR maps.

The neutral, front, side, back, receive, hold, happy, and run renders were visually inspected. The approved face stays intact; the paws remain clear of the muzzle/body; the receive and hold silhouettes read cleanly; and the run pose produces the intended compact waddle without clipping. This is a local candidate only: it has not been uploaded, inserted into Studio, or substituted for an active customer.
