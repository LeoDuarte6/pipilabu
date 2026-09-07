# Pipilabu Overnight Art Ledger

This is the bounded queue for Hermes-triggered Luna Max art-direction work while Leo and Jon are absent.

The overnight lane creates reviewable concepts, model experiments, environment kits, and art documentation only. It never edits gameplay source, opens or mutates Roblox Studio, uploads assets, publishes the experience, changes the active place, or declares a human gate passed.

## Workflow contract

- Live Leo + Jon sessions are gameplay sessions. Work together on player action, feel, rules, pressure, replay desire, and direct playtesting.
- Both `Live` and `AFK` permit isolated Luna candidate work. Only an explicit `Paused` mode, missing/malformed control, or an exhausted eligible queue stops dispatch. Human gameplay, visual, moderation, and taste gates block only the dependent ticket's verdict or promotion; they never stop independent production.
- Each batch tests one named visual hypothesis. The machine-readable priority/dependency layer is `overnight-art-ledger.json`; this Markdown file remains the full creative brief.
- Every completed batch writes a `PLAYTEST_CHECKIN.md`. That check-in blocks only later work which explicitly depends on it. The scheduler skips blocked items and continues with the highest-priority independent safe batch.
- Gameplay-gated integration never stalls concept sheets, isolated model experiments, prop studies, environment kits, rights-safe research, or art documentation that do not depend on that gate.
- Outputs land under `outputs/overnight-art/` as review candidates. Nothing is automatically promoted into `assets/models`, `src`, or Studio.
- Luna workers run in an isolated staging directory with a workspace-write sandbox, one-worker concurrency, a hard runtime limit, and no public or external delivery.

## Ordered batches

### ART-001 - Pipi Labu hero character sheet

Status: `COMPLETED` at `assets/concepts/peepilabu_character_sheet_v1.png`. Do not regenerate it. Its gray-board layout is useful presentation structure, but its prominent top ears are rejected; future geometry follows the tiny lateral/no-top-ear correction.

Create a premium gray presentation board for the approved Pipi Labu owner direction: clear title treatment, front/three-quarter/profile/back views, expression and paw/serve studies, silhouette/proportion callouts, material notes, and animation notes. Use iconic AAA character-sheet clarity as inspiration without copying Blizzard typography, logos, proprietary layout, or Tracer-specific design. Preserve the lively eyes, soft short fur, counter-ready paws, and anthropomorphic shopkeeper posture. Universal correction: the face/crown silhouette is circular; ears are tiny side-set fur hints and never prominent triangles above the head. Earlier concept/model ears are rejected.

Visual hypothesis: a disciplined hero sheet will make later modeling, rigging, animation, and environment decisions converge around one readable owner identity.

Gameplay check-in: after an approved sheet is integrated into the private place, verify that the owner remains readable at normal mobile camera distance and that Idle, Serve, Happy, Stressed, and Talk reinforce the apple handoff rather than distracting from it.

### ART-005 - Owner integration specification

Status: `READY`, but dependent on `ART-001` completion and `ART-001-CHECKIN` being recorded or explicitly deferred.

Turn the accepted hero-sheet decisions into a precise, non-mutating integration packet: scale targets, camera-distance checks, animation-state mapping, attachment expectations, warm-fallback/PBR rules, and rollback criteria. This batch produces specifications only; it never opens Studio or mutates gameplay.

Visual hypothesis: the owner can reinforce the serve without stealing attention from the apple-contact peak.

Gameplay check-in: after a separate authorized integration pass, verify the owner at mobile and desktop camera distances through Idle, Serve, Happy, Stressed, and Talk during a full timed shift.

### ART-002 - Baby customer cast sheet

Status: `COMPLETED` as a local `REVIEW_CANDIDATE` under `assets/candidates/pipilabu_baby_customer_cast_v1/`. Human approval and Studio integration remain false.

Develop a family of small Pipi Labu customers with one shared readable base and controlled variation in proportions, face, fur tone, patience reaction, and received-apple pose. Preserve the universal circular head silhouette with tiny lateral or visually absent ears; do not use prominent top-ear variation. Favor anthropomorphic queue readability; reserve selected four-legged babies as a later contrast, not the entire cast.

Visual hypothesis: controlled variation makes the line feel alive while preserving instant order readability.

Gameplay check-in: serve ten customers and verify request readability, collision clarity, queue direction, received-apple readability, and whether variation improves delight without slowing targeting.

### ART-006 - Pear-cat harvest-event study

Status: `COMPLETED` as a canonical local review candidate; independent of the current gameplay and character-promotion gates. `human_approved=false`; `studio_imported=false`.

Integrated `assets/candidates/pipilabu_pear_cat_harvest_event_v1/` after rejecting an initial literal green-pear drift. The verified board translates Jon's stills into an original warm tan/golden near-spherical orchard cat-loaf with tiny side-folded ears, feline eyes/nose/mouth/whiskers, heavy squash, and tree/hand/basket context. Fruit stays contextual rather than becoming body anatomy. It remains distinct from the canonical Pipi Labu dog cast and is only a rare orchard customer, harvest surprise, or future sourcing encounter—not a replacement owner/player rig.

Visual hypothesis: a surprising fruit-creature silhouette can make sourcing feel alive while reusing the known reach, carry, and serve verbs.

Gameplay check-in: only after an isolated prototype exists, verify whether the tree-hang, hand-squash, basket-cluster, and receipt-delight states create a readable harvest objective without confusing ordinary Ruby/Honeygold orders.

### ART-003 - Apple and serving-prop kit

Status: `COMPLETED` as a local review candidate. Canonical artifact: `assets/candidates/pipilabu_apple_serving_props_v1/apple_serving_props_sheet.png`. Deterministic structural verification passes; `human_approved=false` and `studio_imported=false`.

Design a coherent red-apple crate, held apple, received apple, counter tray, simple price marker, and future rarity seams. The ordinary red apple remains the baseline. Presentation should focus sensory attention on contact and receipt, not pickup.

Visual hypothesis: a small authored prop family can make the core handoff feel intentional without adding mechanical complexity.

Gameplay check-in: compare pickup, carry, toss, contact, and held-by-customer readability; successful contact must remain the sensory peak.

### ART-004 - Market street modular kit

Status: `READY`

Develop a compact Japanese-city/farmers-market-inspired modular kit: shop facade, awning, shelves, fruit crates, lanterns, street edge, neighboring stall, reserved shop bay, and distant landmark silhouettes. Derive the world from serving sightlines, queue flow, neighbor helping, and future market runs.

Visual hypothesis: a modular street kit can create a memorable place while preserving the fast apple loop and multiplayer shop readability.

Gameplay check-in: run the timed shift on mobile and desktop camera distances; verify navigation, queue sightline, prompt visibility, collision, and whether the environment helps rather than competes with the serve.

## Promotion rule

Leo and Jon choose whether a review candidate is rejected, revised, or promoted. Promotion into canonical game assets is a separate bounded implementation batch followed by the exact private-place gameplay gate in `docs/codex/PLAYTEST_QUEUE.md`.
