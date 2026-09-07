# Pipi Labu baby customer cast v1

Bounded review candidate for overnight ticket `ART-002`. This folder does not replace the existing v4 side-ear customer candidate, does not create a new canonical rig, and does not touch Studio, Rojo, gameplay source, cloud assets, uploads, or publish state.

## Candidate intent

Show one shared baby customer base with four controlled, queue-readable role studies:

- `RubySprout` — curious newcomer, one paw asking, Ruby order visible.
- `HoneygoldHugger` — warm receiver, eyes softened, both paws holding a Honeygold apple.
- `ShyLoaf` — lower, tucked, bashful gaze; a quiet customer without a new species.
- `HurryWaddle` — forward-leaning eager regular, one lifted paw and restrained motion cue.

All four preserve the existing Pipi Labu face/material language: caramel crown/back, cream urajiro lower face/belly/paws, low dark oval eyes, compact black nose, small curved mouth, matte fur, and glossy eyes/nose. The crown is an uninterrupted circle. Ear hints are tiny lateral embedded shapes only; no role may introduce an upright or top ear.

## Artifacts

- `baby_customer_cast_contract.json` — shared silhouette/material/role contract and exact future review gate.
- `baby_customer_cast_sheet.png` — deterministic 1600 x 1000 review board generated from the contract.
- `scripts/generate_baby_customer_cast.py` — dependency-light Pillow generator; does not read or modify canonical assets.
- `scripts/verify_baby_customer_cast.py` — deterministic contract, image, copy, and silhouette-policy verifier.
- `verification/structural_report.json` — generated evidence.
- `generation_report.json` — generator output metadata and hashes.

The existing technical base remains the local reference at `assets/models/pipi_labu_customer_v4_side_ear_candidate/`. This candidate intentionally references that source; it does not copy, overwrite, or alter its `.blend`, `.fbx`, maps, or renders.

## Verification

From the repository root:

```powershell
py -3 assets/candidates/pipilabu_baby_customer_cast_v1/scripts/generate_baby_customer_cast.py `
  --candidate-dir assets/candidates/pipilabu_baby_customer_cast_v1

py -3 assets/candidates/pipilabu_baby_customer_cast_v1/scripts/verify_baby_customer_cast.py `
  --candidate-dir assets/candidates/pipilabu_baby_customer_cast_v1
```

The image is a review study, not a claim that the four roles are approved, rigged, imported, or ready for the live queue.
