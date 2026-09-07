# Pipi Labu pear-cat harvest event v1

Bounded local review candidate for `ART-006`. This folder is additive and does not replace the Pipi Labu owner, player, baby customer cast, market kit, or approved rendered v4 material language. It does not touch Studio, Rojo, gameplay Luau, place files, cloud assets, uploads, or publish state.

## Direction

The ticket nickname is pear-cat, but the authored identity is a warm tan/golden orchard cat-loaf rather than a literal green pear. Its near-spherical heavy hand-squash, extremely tiny lateral folded ear hints, narrow feline eyes, cat nose/mouth, short whiskers, and paws keep it visibly separate from the caramel/cream Pipi Labu dog cast. Apples stay in the tree, basket, and receipt context; no stem or leaf grows from the cat crown, and no top or upright ears are used.

The four decision states are:

- `ORCHARD_REST` - quiet / curious, grounded beside a tree and basket.
- `HARVEST_PEEK` - bright / ready, one reach cue with no new pluck system.
- `CONTACT_DELIGHT` - delight / receives, Ruby receipt fruit visible between paws; this is the sensory peak.
- `BASKET_GOODBYE` - satisfied / leaves, a small carry-away resolution.

The verb chain stays `reach -> carry -> serve -> contact -> hold/receipt`. The sheet adds no sourcing, rarity, queue, patience, reward, economy, HUD, or audio mechanic.

## Files

- `pear_cat_harvest_event_contract.json` - identity, scale, pivot, state, material, source, approval, and future-gate contract.
- `pear_cat_harvest_event_sheet.png` - 1800 x 1120 authored review board with orchard vignette and connected event path.
- `pear_cat_harvest_event_mobile_strip.png` - 960 x 420 mobile-scale silhouette/readability strip with role names and one-line emotions.
- `scripts/generate_pear_cat_harvest_event.py` - reproducible Pillow generator; it does not load or edit canonical art.
- `scripts/verify_pear_cat_harvest_event.py` - deterministic contract, source-hash, image, policy, and mutation-scope verifier.
- `generation_report.json` - source paths, SHA-256 values, artifact hashes, render dimensions, and false approval/mutation flags.
- `verification/structural_report.json` - passing structural evidence.

## Verification from repo root

```powershell
py -3 -m py_compile assets/candidates/pipilabu_pear_cat_harvest_event_v1/scripts/generate_pear_cat_harvest_event.py assets/candidates/pipilabu_pear_cat_harvest_event_v1/scripts/verify_pear_cat_harvest_event.py
py -3 assets/candidates/pipilabu_pear_cat_harvest_event_v1/scripts/generate_pear_cat_harvest_event.py --candidate-dir assets/candidates/pipilabu_pear_cat_harvest_event_v1
py -3 assets/candidates/pipilabu_pear_cat_harvest_event_v1/scripts/verify_pear_cat_harvest_event.py --candidate-dir assets/candidates/pipilabu_pear_cat_harvest_event_v1
```

The local raw attachment scan found no pear-cat image in the isolated worktree, so the corrected supplied ART-006 visual brief is recorded and hashed in `generation_report.json`. The flat images are a cast/pose and mechanic decision surface, not a downgrade of or replacement for the approved rendered v4 Blender material quality. No human approval or Studio import is implied.
