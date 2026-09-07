# Pipi Labu Playtest Queue

State: `READY`

- Build: `v0.9.9-dev` from the saved local checkout
- Active test place: local fallback PlaceId `0`, GameId `0`; Rojo allowlist remains only `0` plus private PlaceId `133099029551440` / GameId `10646495069`
- Estimated time: 8-10 minutes
- Publishing: not published in this repair pass; the private cloud experience remains unchanged
- Controls: `R` / gamepad `Y` starts the shift; world prompts use `E` / gamepad `X`; ordinary camera and movement remain enabled

## Current v0.9.9 shift-stakes gate — READY TO PLAYTEST

1. Start the shift and confirm the HUD reads `0 / 8`. The opening line is the whole level: miss one customer, wait beyond the old replacement delay, and confirm the line stays at seven rather than refilling.
2. Take Ruby and Honeygold directly from their visible display apples. Both prompts should appear during the shift, and the rear-left shopkeeper must not block either route.
3. Talk to the shopkeeper at the rear-left of the shop. Walk back across the market while the dialogue is up; it should remain readable. The real roof should stay visible and collidable.
4. At the Physics Lab, use one apple for the whole journey: pull until the pointer visibly outruns the fruit under stem tension, pop it, carry it into the deep basin, physically pour soap, scrub it clean, lift the crate lid, and drop that same apple inside. It should fall briefly and then lock into one of six grid slots.
5. Judge the new pluck threshold/lag, water depth, crate drop/snap, HUD button depth, and overall comfort. Human tactile approval is still required even though the runtime state machine and geometry are technically verified.
6. Finish or lose one shift. A physical green cash bundle must appear beside the rear-left shopkeeper: base pay `$2`, `$1` per served customer, plus a `$4` clear bonus. The result button must say `COLLECT PAY` until the world prompt is used. Collect it, confirm the bundle appears in the avatar's hand, then start another shift and confirm the cash balance survives while the held prop banks away.
7. Talk to the shopkeeper and judge the bottom-screen subtitle treatment. It should feel like character dialogue rather than another HUD card. Character-specific Animal Crossing/Undertale-like voice bleeps are deliberately not added yet; the next audio gate needs an original rights-safe palette.

Automated evidence: `V098_FINAL_OK luau=19 rojo=1 diffcheck=1`; fresh local Play read back owner `(-9, 0.5, -20)`, owner prompt/bubble `16/90`, roof local transparency `0`, shift `target=8/cap=8/spawned=8`, enabled Ruby/Honeygold prompts at `9`, exactly one `JourneyApple`, hollow basin and six-slot hollow crate, and clean Output. A bounded synthetic runtime route verified `AttachedDirty -> PluckedDirty -> Clean -> Crating -> CratedLocked`, `CleanProgress=1`, `WashSerial=1`, and `CrateSerial=1`; this is technical evidence, not a human feel verdict.

v0.9.9 runtime evidence: literal prompt input completed a perfect `8/8, 0 missed` shift and produced `$14` (`$2 + 8×$1 + $4 clear bonus`). A separate `6 served` loss produced a physical `$8 Shift Pay`; literal collection removed the world bundle, attached four notes as `HeldShiftCash`, changed the result action from `COLLECT PAY` to `TRY AGAIN`, and retained `$8` into the next shift. The bottom subtitle rendered the shopkeeper payout line and task. This proves state and interaction, not that the cash feel, sound, or subtitle taste is approved.

## Character replacement pipeline — 2026-08-09

- State: `BUILDING`; there is no replacement character ready for a human playtest.
- Specialist escalation is complete. Fable had no remaining credits; the final explicit `claude-opus-5` audit found a blocking owner-identity fork (room-frame giant orb versus counter-frame naturalistic Shiba) in addition to the procedural-modeling failure. The exact decision record is `docs/codex/OPUS_CHARACTER_REVIEW_DECISION_2026-08-09.md`.
- The stalled 40-step local Hunyuan retry was stopped with zero recorded steps/output. No local Hunyuan result is approved or assumed ship-safe.
- The owner/customer v10 front images remain under `assets/concepts/` as retired conditioning/mood evidence; Opus 5 rejected their stern-eye/uniform-fur owner and legless customer anatomy.
- TripoSR owner/customer controls are rejected because their side/back geometry collapses and their meshes exceed Roblox's per-mesh budget. They were never imported into Studio.
- The Roblox `GenerateMesh` control is rejected as a generic upright, large-eared Shiba and is quarantined in `ServerStorage.PipilabuRejectedAIMeshControls` with gameplay/presentation approval false.
- The licensed-base owner/customer v2 Blender controls are continuous, under the per-mesh triangle cap, and materially more honest than the ellipsoid models, but still fail the exact Pipi Labu face/body read. They remain local and unapproved; do not spend Leo/Jon playtest time on them or promote them into gameplay.
- Blocking decision: Leo selects owner A (room-frame giant orb, recommended) or B (counter-frame naturalistic Shiba). Then correct/re-register the v6 turnaround and build exactly one owner through registered silhouette/neutral-clay review before rigging or Studio upload.

## v8 character candidate gate — 2026-08-09

- Verdict: `REJECTED`. Leo judged both models terrible. Technical import success did not translate into acceptable character art.
- Actual Blender 4.5 headless generation, base/action FBX export, and private Studio import are complete for separate owner and customer models.
- v7 is rejected for Studio-visible terracing and detached pieces. v8 uses smooth topology, flat-safe synthetic normals, a continuous belly-low customer shell with no ears, and an owner whose low lateral folds do not break the round crown.
- Both imports are quarantined in `ServerStorage.PipilabuV8CandidateAssets` with presentation approval false and gameplay replacement forbidden. They are not part of `v0.9.7-dev`, and this pass did not publish the place.
- Automated verification marker: `V8_MODELING_VERIFY_OK luau=19 rojo=1 diffcheck=1`. This proves only pipeline mechanics. The replacement lane must start from learned/sculpted high-fidelity geometry or a licensed base mesh, not procedural ellipsoids. State remains `BUILDING`.

## 2026-08-08 Leo/Jon live review — failed build

The synced `v0.9.3-dev` build is not ready for the two-run gate. Leo and Jon rejected the visible runtime quality and directed a focused repair pass before another normal playtest:

- Physics Lab dragging must track the cursor immediately and continue tracking when the player/camera moves; the crate interaction currently fails this bar.
- Soap must be a held/poured object, not a click-to-toggle state. The basin needs visible cursor/object-driven water response rather than a static glass block.
- The pluck station is unclear and unfinished; it cannot be treated as a promoted mechanic.
- The visible customer line must support more than three customers.
- The owner belongs inside the shop as a persistent talk/task NPC, not outside the shop footprint.
- Current Roblox Doges do not match the approved Blender renders: rejected top ears remain visible and the imported material stack is visibly degraded. Do not describe the Studio models as render-equivalent.
- The warm medallion UI direction is acceptable, but it does not offset the broken interaction and character presentation.

The broad Luna/Hermes dispatcher is paused while these visible defects are closed. No publish should occur from this failed state.

## v0.9.4 automated repair evidence

The focused repair is synced into the exact private Studio Edit session, but it has not passed a Leo/Jon replay:

- Held physics objects are pointer-owned every render frame on a horizontal work plane. A controlled run moved the dirty Ruby into the basin, advanced `CleanProgress` to about `0.1826`, and shifting the active camera reference by `+3.0` studs moved the held Ruby by exactly `+3.0` studs.
- Soap is now a draggable bottle with a visible pour state and droplets. Pouring over the basin set `Soapy=true`, disturbed all 24 spring-water cells, and produced about `0.073` studs of measured surface displacement.
- The crate lid opened around its hinge to `51.566` degrees in the controlled drag check. The instruction sign was moved so it no longer occludes the station.
- The runtime service line starts with five customers and exposes six spots at X `0 / 4.25 / 8.5 / 12.75 / 17 / 21.25`.
- The owner runtime target is inside the shop at `(0, 0.5, -6)`.
- The owner body PBR maps now load from a Studio-authored `PipiLabuBodyPBR` SurfaceAppearance, with authored facial colors retained. This repairs the gray/degraded material failure but does not fix the rejected top-ear silhouette.
- Clean private Play reported `v0.9.4-dev`, `RuntimeBodyPBRApplied=true`, `RuntimeMaterialState=BodyPBRAndAuthoredFacePalette`, five live customers, six queue spots, and no game-script error.
- Final local regression passed all 17 Luau contracts, a fresh Rojo place build, and `git diff --check`.

Still open: side-ear owner/customer reimport, customer material parity, pluck redesign, and Leo/Jon feel approval. These are why the queue remains `BUILDING`.

## v0.9.5 shutdown continuation

- Side-ear owner/customer FBXs are now privately imported and active in Studio; the rejected top-ear models remain recoverable under explicit recovery names.
- Five customer roots are now solid collision proxies. Exact Play loaded all five side-ear PBR visuals and the owner inside the shop facing the service lane.
- Source now contains the slower squash-settle handoff, three-bite/crumb enjoyment, and wrong-apple `NOPE!` boomerang/flinch while preserving the held item.
- The Tea/Flower/Rice/Lantern stores now form a visible two-row grid with cross-streets.
- Eighteen Luau contracts, Rojo build, clean Output boot, and diff integrity pass.

Do not mark this `READY` yet. Tomorrow must run both new interaction sequences through actual prompts, inspect them visually, repair what feels cheap or broken, and repeat the polish pass. Pluck, exact customer atlas parity, owner dialogue/tasks, and resident/group life remain open after that core test.

## v0.9.5 morning literal-input evidence — 2026-08-09

- Wrong-color and matching service interactions now pass through real enabled prompts. Wrong-color preserves ownership after the visible return; correct-color reaches completed handoff, customer apple possession, `YUM!`, served increment, and queue advance with clean Output.
- The former PBR readback was invalid because it accepted an empty SurfaceAppearance. Runtime validation is strict now. Exact owner/customer side-ear ColorMaps are privately uploaded but pending Roblox availability, so the current honest fallback is warm authored color with `RuntimeBodyPBRApplied=false`; no gray pending surface is attached.
- Literal mouse testing found and repaired the Physics Lab controller conflict, Studio processed-input rejection, incorrect 58-pixel inset subtraction, fixed-Y dragging, and stale soap-pour release state.
- Measured literal-input results: apple reaches the basin and cleans to `0.495`; camera/player `+3` moves the held apple exactly `+3`; water reacts; soap reaches `0.84` fill and soapy state; crate lid reaches `48.13°`.
- The occluding Physics Lab title slab is gone. The remaining visible instructions are one verb per station: `PULL UNTIL POP`, `SCRUB + POUR`, and `LIFT LID`.
- Final automated verification passed all 18 Luau contracts, a fresh Rojo build, and `git diff --check`: `MORNING_FINAL_OK luau=18 rojo=1 diffcheck=1`.
- Final clean Studio boot and server readback confirmed five customers plus owner, honest fallback material state on all six visuals, preserved pending exact-map IDs, and single-controller DragDetector state. Studio is back in Edit mode.

Historical v0.9.5 status: the exact side-ear ColorMaps were uploaded and technically recoverable, but the entire side-ear model direction is now superseded by Leo's 2026-08-09 market-video target. Do not attach those maps merely to make the old candidate look finished. No private cloud-place publish occurred from the local recovery snapshot.

## v0.9.6 automated repair evidence — 2026-08-09

- The line now starts with eight customers and supports ten at 3.4-stud spacing. Exact local Play caught and fixed the older-snapshot Y mismatch; all eight now occupy Y `0.54`, X `0` through `23.8`, with collidable roots.
- Physics Lab pluck now uses direct pointer-owned stretch, visible tension, predicted pop, server tension/proximity validation, free post-pop drag, and recoverable early release. A server-backed local test produced `PluckSerial=1` only from valid tension at six studs.
- Owner Talk is live on the active owner presentation (`E` / gamepad `X`, eight studs) and returns context-aware dialogue/task text without replacing serving.
- Wrong-service and successful-service queue ripples are live. Literal prompt tests preserved the wrong apple, then completed a correct Ruby handoff and served increment with the first five waiting customers reacting.
- The Blender import/export route is repaired, but the v5 sculpt is explicitly rejected. Existing v4/side-ear models and two generated comparison meshes also remain evidence only; the exact market-video Shiba is still the art gate. No half-measure model was promoted.
- New modeling reference `assets/concepts/pipi-labu-video-turnaround-v6.png` is the closest current 2D reconstruction of the video target: round crown, swallowed lateral ears, heavy owner, and belly-low long-backed customer. It has now been rebuilt as technically viable v6 owner/customer Blender candidates after two sculpt/export passes. Both are below the 20k per-mesh import ceiling and use the corrected base/action/PBR export contract, but remain unapproved until clean Studio reimport plus gameplay-distance face, fur, scale, ground-contact, and deformation review.
- Offline action proofs are clean after repairing customer fused-body paw spikes and the owner's disappearing nose during Talk. This does not replace the Studio import/deformation gate. Final model verification marker: `V6_FINAL_VERIFY_OK luau=19 ownerLargest=9510 customerLargest=11302`.
- Private-cloud verification caught and fixed one capability-only bootstrap crash: server reads of `SurfaceAppearance` map properties can be blocked outside plugin security. `CharacterMaterialAdapter` now treats unreadable maps as unavailable and falls back without aborting gameplay.
- Published PlaceVersion `83` was reopened with Rojo offline and independently read back as `v0.9.6-dev`, including owner dialogue, eight-customer configuration, direct pluck, queue ripples, and the capability guard. Final regression: `FINAL_REGRESSION_OK luau=19 rojo=1 diffcheck=1`.

State stays `BUILDING` because tactile feel and final character likeness require Leo/Jon judgment, and the current model still fails the explicit video target. The gameplay build is technically ready for the next bounded human pass; the character is not approved.

## v0.9.7 visible-line and pluck evidence — 2026-08-09

- Literal mouse input closes the automated pluck matrix: early release returns to exact rest; full tension produces one authoritative pop; the held apple follows a `+3`-stud player/camera move by `+3.001976`; release clears ownership; and regrab/move succeeds. Human satisfaction remains unclaimed.
- The old eight-customer runtime was real but too wide for one service framing. Queue spacing is now `2.25` studs at X `0` through `15.75`, producing a `0.15`-stud visual gap with the current customer width. The owner moved to `(-3.5, 0.5, -6)` inside the shop so it no longer hides the ready customer.
- Source-backed private-cloud Play showed all eight customers simultaneously, collidable and on the common Y `0.54` plane with unique idle phases. Starting with `R` enabled Serve only for the first customer and preserved owner Talk. Physics Lab reported Ready and Output had no game-script errors.
- All 19 Luau contracts, a fresh Rojo build, and diff integrity passed before publish and again after final documentation: `V097_PREPUBLISH_OK luau=19 rojo=1 diffcheck=1`; `V097_FINAL_OK luau=19 rojo=1 diffcheck=1`.
- Studio's publish-success log records private version `87`. With Rojo offline, a fresh cloud reopen read back `v0.9.7-dev`, spacing `2.25`, owner X `-3.5`, direct pluck, and the capability guard from the saved place. `game.PlaceVersion` returned stale `83`; do not use that property alone as deployment evidence.

State remains `BUILDING`: the next human pass judges interaction feel, while the exact market-video character remains an unpassed art gate. The v6 Blender candidates are not active gameplay art.

## Required service-loop gate

Complete two normal, uncoached shifts. During the pair:

1. Confirm the ready customer is centered and the line advances left-to-right from behind the counter.
2. Watch four customers; their idle movement should feel varied rather than synchronized.
3. Deliberately take the wrong apple once; the feedback should be clear and the apple should remain in hand.
4. Watch the circular order/patience medallion move from calm to urgent.
5. Finish one shift and lose one shift. A win must show the warm `SHIFT CLEAR -> NEXT SHIFT` medallion; only a loss should offer `TRY AGAIN`.
6. Walk into the main roof, awning, counter, shelves, stall backs, and stall roofs. None should be pass-through.
7. Immediately take the next apple after serving. The committed apple must finish traveling into the customer's paws instead of disappearing when the next held apple appears.

Record:

- Is the first action obvious without coaching?
- Does the queue direction now read correctly?
- Do staggered customers feel alive rather than artificial?
- Is Ruby/Honeygold matching attention or merely extra walking?
- Is the native medallion HUD immediately readable against the world?
- Is the radial customer urgency clearer than the old rectangle?
- Does the paw-targeted handoff feel clean and satisfying?
- Does the ending clearly explain what happened and what comes next?
- Is 18 seconds pressure or dead time?
- Do you voluntarily start another round?

## Optional isolated physics comparison

The Studio-only table sits away from the market and owns no inventory or score:

1. `A | PLUCK`: grab the attached Ruby, pull until the visible stretch reaches pop, release early once to check recovery, then pop and freely move the detached apple.
2. `B | WASH`: drag the dirty Ruby through the basin, then pick up the soap bottle and pour it over the water.
3. `C | CRATE`: drag the lid around its hinge.

Record which station creates the strongest urge to repeat and where sound/haptics should land. This cannot pass the service-loop gate or authorize production P1.

## Separate character review state

Leo selected **A, the room-frame giant orb**, as the owner silhouette. The cute counter-frame naturalistic Shiba remains a separate future character/reference direction and must not be averaged into the owner body. `assets/concepts/pipi-labu-owner-reconstruction-sheet-v11.png` is the current registered 2D owner target after a reel-driven face correction: no top ears, low small eyes beneath a broad brow, fused orb body, broad muzzle/cheeks, and the Pipi Labu crescent grin.

V11 has now crossed the actual Blender-to-Roblox boundary. `assets/models/pipilabu_owner_v11_studio_candidate/` contains the verified `.blend`, base/action FBXs, four PBR maps, Blender renders, metrics, and the real Studio capture. The private Studio importer created 14 MeshParts, four body-map assets, a nine-bone rig, and five owner actions. The rigged model is quarantined at `ServerStorage.PipiLabuV11CandidateAssets.PipiLabuOwnerV11Candidate`; a static visual review copy is staged at `Workspace.PipiLabuV11ReviewStage`. Studio reported a successful private publish. The active shopkeeper remains unchanged.

State remains `BUILDING`. This import proves the protected asset route, hierarchy, PBR attachment, palette repair, and cloud persistence; it does **not** prove final likeness. The current Studio capture still reads as a simplified blockout with insufficient fur/surface fidelity and weak paw/body integration compared with the v11 concept and original reel. Do not set `ApprovedForPresentation=true` or route `OwnerPresentationService` to v11 until the actual in-engine model clears Leo/Jon visual review.

## Automated evidence already passed

- Exact private Play reports `v0.9.3-dev` with clean game Output.
- Recorder schema v3 exposes the exact build/place identity, latest completed pair, wrong-attempt total, customer-ready/approach timing, apple-visible duration, handoff start/completion, immediate-next-pickup continuity, voluntary replay, objective-evidence readiness, and an explicit `AwaitingQualitativeVerdict` state without ever claiming the human verdict itself. Events are bounded to 128 per run.
- Queue spots `0, 4.25, 8.5, 12.75`; direction `LeftToRightFromShopkeeper`; collision repair count `24`.
- A fresh 2026-08-08 Edit audit caught and corrected stale Studio-authored geometry that still used the pre-reversal signs. The exact private place now persists service spot X `0`, waiting spots `+4.25 / +8.5 / +12.75`, customer spawn X `+17`, and exit X `-15`. With the player spawn looking toward +Z (`RightVector = -X`), this is screen-left to screen-right from behind the counter.
- A bounded technical Play after the correction showed live customers at X `0 / 4.25 / 8.5` with orders `Ruby / Ruby / Honeygold`, exactly two apple definitions, build `v0.9.3-dev`, `Pipi Labu` display naming, and recorder schema 3 at `AwaitingTwoCompletedRuns`. This technical run did not move the player or count as human evidence. Studio returned to Edit.
- Fifteen Luau contracts, nine Python intake/visual-manifest tests, customer/owner and fresh Blender structural verifiers, four canonical candidate verifiers (market kit, ART-002 cast, ART-003 serving props, corrected ART-006 orchard cat), Rojo build, and `git diff --check` pass.
- This gate blocks only claims that the verdict passed and promotion/default enablement of dependent candidates. It never pauses the project: during both Live and AFK operation, Codex and the Luna crew must continue independent code, art, environment, instrumentation, performance, audio-preparation, testing, and documentation lanes.

## Human verdict record

- Status: `PENDING_TWO_UNCOACHED_RUNS`
- Players: Leo and Jon
- Run 1 outcome: `PENDING`
- Run 2 outcome: `PENDING`
- Wrong-color attempt observed: `PENDING`
- Immediate-next-pickup continuity observed: `PENDING`
- Queue/collision/HUD observations: `PENDING`
- Voluntary replay: `PENDING`
- Qualitative verdict: `PENDING`

Only Leo and Jon's actual play can replace these fields. The recorder may supply objective timings, but it cannot infer or write the qualitative verdict.
