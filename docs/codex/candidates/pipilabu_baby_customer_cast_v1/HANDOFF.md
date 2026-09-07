# ART-002 — Pipi Labu baby customer cast v1

Date: 2026-08-08
State: `REVIEW_CANDIDATE` / local-only / no human approval recorded

## What changed

Created the isolated candidate at `assets/candidates/pipilabu_baby_customer_cast_v1/` with four differentiated queue roles:

- `RubySprout` — curious newcomer asking for the first Ruby apple.
- `HoneygoldHugger` — relieved receiver visibly holding the Honeygold apple.
- `ShyLoaf` — bashful, patient, tucked low without becoming inert.
- `HurryWaddle` — bright regular leaning toward the next handoff.

Every role shares the approved family rule: an uninterrupted circular crown, tiny lateral ear hints swallowed by the fur contour, no top/upright ear geometry, low dark oval eyes with catchlights, compact black nose, cream lower muzzle/urajiro, and caramel/cream coat language.

The PNG is a flat, deterministic cast/pose decision surface for comparing role readability. It is not a downgrade of, replacement for, or approval of the approved rendered v4 Blender material quality. Future 3D work must continue from the existing v4 side-ear candidate's rendered face/material/PBR/rig language; the board does not replace its Blender mesh, maps, actions, attachments, or collision truth.

## Reconciled source truth

The candidate contract references, but does not edit or overwrite:

`assets/models/pipi_labu_customer_v4_side_ear_candidate/pipilabu_shiba_customer_v4.blend`
`assets/models/pipi_labu_customer_v4_side_ear_candidate/pipilabu_shiba_customer_v4.fbx`

The v4 invariants retained in the contract are model v4, generator 2.3.0, approximate bounds `[2.25, 2.05, 2.5]`, 21,326 triangles, and the six existing customer actions. Supplied character/video references informed size contrast, low loaf anatomy, fruit focal emphasis, and controlled motion cues only; rejected top ears, cream forehead masking, new player/owner identity, and gameplay-changing role differences.

## Candidate artifacts

- `README.md` — scope and review notes.
- `baby_customer_cast_contract.json` — role, silhouette, material, source, and future-gate contract.
- `scripts/generate_baby_customer_cast.py` — deterministic Pillow generator.
- `scripts/verify_baby_customer_cast.py` — contract/image/hash verifier.
- `baby_customer_cast_sheet.png` — 1600×1000 generated review board.
- `generation_report.json` — generated hash and non-approval flags.
- `verification/structural_report.json` — passing structural evidence.

## Verification evidence

Ran:

```text
py -3 -m py_compile assets/candidates/pipilabu_baby_customer_cast_v1/scripts/generate_baby_customer_cast.py assets/candidates/pipilabu_baby_customer_cast_v1/scripts/verify_baby_customer_cast.py
PIPILABU_BABY_CAST_VERIFY_OK
PIPILABU_BABY_CAST_DETERMINISTIC_OK files=4
```

The verifier confirmed the four-role order, v4 source invariants, scale bands, circular-crown/lateral-ear rule, all-false approval/import flags, exact PNG size `1600×1000`, and generation-report hash. Current PNG SHA-256:

`7426bf3bda6f77d1897b59f5d5a32452a9449eafd9c01881a6aed3dc379eef66`

Visual inspection confirmed the shared-base subtitle is unobstructed, role captions no longer collide, the role names/emotions remain single-line, the four poses are distinguishable, and eye catchlights remain visible. No Studio, Rojo source, canonical asset, place file, cloud asset, upload, publish, or gameplay source was touched.

## Risks still open

- This is a 2D direction sheet, not four rigged or imported character assets. It does not prove Blender topology, PBR response, animation, collision, or mobile performance.
- The generated board cannot answer the one-second queue-distance or mobile-thumbnail recognition question for real 3D customers; Leo/Jon visual review remains required.
- The Honeygold apple/hold and motion marks are authored review cues only. They must not become new order, queue, patience, reward, or audio rules.
- The existing v4 side-ear candidate remains a local review candidate and is not approved canonical content.

## Exact future private-play integration gate

1. Keep the open v0.9.3 service-loop gameplay gate recorded or explicitly deferred; this ticket is not gameplay evidence.
2. Leo and Jon review this board and a mobile-sized thumbnail. Reject any role with ears reading above the crown, a cream forehead mask, broken caramel/cream material hierarchy, lost catchlights, noisy variation, or a pose that competes with apple contact.
3. If the visual review survives, author exactly one bounded role variant from the existing v4 side-ear Blender candidate in a disposable local `0/0` sandbox. Preserve the v4 FBX, PBR maps, six actions, attachments, and collision marker as source truth.
4. Only for a later private test, assert `PlaceId=133099029551440`, `GameId=10646495069`, and `Edit` before placing the candidate under `ServerStorage.PipilabuCandidateAssets.BabyCustomerCastV1`. Do not alter `src/`, Rojo mappings, live gameplay modules, or the existing market-kit candidate.
5. Run one complete ten-customer shift on mobile and desktop camera distances with queue membership, prompt rules, patience, order data, handoff timing, rewards, and audio unchanged. Record role recognition, ready-customer targeting, apple receipt/hold, collision clarity, and line direction.
6. Remove the candidate root if it slows targeting, hides the apple, creates collision ambiguity, or reads as a generic crowd. Only an explicit later Leo/Jon decision after this sandbox/private validation can approve promotion; no upload, publish, or canonical replacement is implied.
