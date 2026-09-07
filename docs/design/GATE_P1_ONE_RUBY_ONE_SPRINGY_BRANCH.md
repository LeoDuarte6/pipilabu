# Gate P1 — One Ruby, One Springy Branch

Status: `ACCEPTED — IMPLEMENTED DISABLED; HUMAN PROMOTION GATE PENDING`

Leo Duarte and Jon Walworth accepted pluck-first as Pipi Labu's first post-v0.9 sourcing and physicality experiment. The implementation now exists behind `Enabled=false` and `StudioOnly=true`. The current v0.9.x repair gate blocks only enabling or promoting this candidate; it never blocks independent development.

## Hypothesis

A single apple source becomes enjoyable when the player's motion visibly loads a spring system, produces a readable release, and leaves the apple with weight, inertia, wobble, and persistent consequences. The physicality should create funny recovery stories without making the underlying carry-and-serve loop unclear or punitive.

## Bounded player verb

`grab attached Ruby -> pull/twist against tension -> pop free -> catch or recover -> carry -> unchanged Paw_R serve`

P1 contains exactly one Ruby, one springy branch, and one isolated source placed close enough to the current loop that route design is not under test.

## Trigger and control contract

- Show one attached Ruby within interaction reach of the isolated branch.
- Press and hold the normal interaction input (`E` on keyboard or gamepad `X`) within the existing six-stud interaction envelope to establish a grip. The server validates reach and that the Ruby is still attached.
- While grip is held, movement away from the branch adds pull tension. Lateral movement or facing change across the stem adds twist. Both inputs feed one bounded, legible tension value.
- The client may predict branch bend, stem stretch, apple wobble, and grip response immediately. The server owns the authoritative grip, detach threshold, detach event, apple state, inventory state, and serve result.
- Detach occurs when validated combined tension crosses the threshold. It must not be a hidden hold timer or an instant prompt-to-inventory conversion.
- Releasing interaction before detachment releases the grip and lets the still-attached branch settle naturally.

## Feedback grammar

### Visual and physical

- Grip produces an immediate small apple/branch response.
- Increasing tension visibly bends the branch, stretches or angles the stem, and increases apple wobble.
- Detachment produces a clear stem release, branch recoil, and a free Ruby that retains the direction and magnitude of the final bounded pull.
- The apple remains a visible persistent object through airborne, caught, dropped, rolling, recovered, carried, and served states. It never disappears into invisible inventory during P1.
- Branch recoil and a dropped apple may create comedy, but the path and consequence must remain readable.

### Minimal sound and haptics

- **Grip:** one quiet leaf/finger contact tick; no reward sting.
- **Load:** restrained leaf rustle plus wood/stem strain whose pitch or intensity follows tension.
- **Near release:** a subtle peak cue without a UI alarm.
- **Pop:** one crisp stem snap/pop and one short medium controller pulse.
- **Catch:** a soft weighty hand impact and one short light pulse.
- **Drop/roll:** surface-appropriate thud, bounce, and sparse rolling ticks; no failure buzzer.
- **Serve:** preserve the existing handoff and customer reaction as the strongest payoff.

Voice selection and final sound-palette approval are human creative gates. P1 may use clearly marked temporary sounds for mechanics testing, but no automated worker chooses final voices or final palette.

## State and authority

The minimum state path is:

`Attached -> Gripped -> DetachedAirborne -> Held | RecoverableGround -> Served`

- Client prediction is presentation-only and must reconcile to server truth without duplicate apples or false inventory.
- The server owns whether the Ruby detaches, whether the player holds it, whether it remains recoverable, and whether the unchanged serve succeeds.
- The customer handoff, reward, queue advancement, and `Paw_R` receive/hold behavior remain unchanged from the current v0.9.x repair candidate; this wording does not approve that candidate or pass its human gate.

## Failure and recovery

- **Insufficient pull:** the Ruby stays attached; branch and apple rebound and settle.
- **Early release:** grip ends; the attached system keeps a short, damped wobble instead of snapping to rest.
- **Missed catch:** the Ruby drops, bounces, or rolls with persistent motion and remains recoverable through the ordinary pickup interaction.
- **Awkward branch recoil:** may look funny but cannot damage, stun-lock, launch, or trap the player.
- **Out of bounds:** only a settled and genuinely unreachable Ruby may use a deterministic last-resort return to the isolated source. Never teleport it merely because the player missed the catch.
- No failure destroys the apple, consumes inventory, resets the shift, or rewrites the serve rule.

## Telemetry

Record the P1 test in Studio-only session evidence, with no production persistence:

- `P1GrabStarted`
- `P1GripReleasedAttached`
- `P1PeakTension` and dominant input (`Pull`, `Twist`, or `Combined`)
- `P1Detached`
- `P1CaughtBeforeGround`
- `P1Dropped`
- `P1Recovered`
- `P1OutOfBoundsRecovered`
- `P1Served`
- `P1Abandoned`

Derive grab-to-detach, detach-to-catch/drop, drop-to-recovery, and detach-to-serve times. Telemetry observes the gate; it does not move the player, alter physics, or decide the qualitative verdict.

## Dependencies

- The current v0.9.x repair gate is recorded in `docs/codex/PLAYTEST_QUEUE.md` or explicitly deferred first.
- The existing Ruby item identity, visible carry state, inventory contract, and `Paw_R` serve path remain available and unchanged.
- The branch/source is isolated and reversible so it cannot silently replace both v0.9 crates or affect the current test.
- The implementation exposes bounded tunables for reach, pull contribution, twist contribution, detach threshold, spring strength, damping, maximum release velocity, catch forgiveness, and last-resort recovery.
- Visible trunk/branch geometry receives honest collision where physically solid. Invisible helpers, prompts, markers, and VFX remain non-collidable.

## Relationship to the Physics Lab

The canonical Rojo tree now contains the accepted P1 implementation as an isolated disabled service with deterministic contract tests. It does not replace the v0.9 Ruby/Honeygold loop and does not satisfy P1 human acceptance criteria. The Studio-only Physics Lab remains exploratory comparison evidence; promotion still requires a fresh private implementation review against this spec and a separate P1 human playtest.

## Non-goals

- No orchard or map expansion.
- No Honeygold source or multiple branches.
- No washing, soap, polishing, leaf removal, cutting, slicing, coating, or recipe chain.
- No economy, inventory expansion, farmer-market route, progression, or multiplayer ownership design.
- No customer, timer, queue, reward, or handoff rewrite.
- No full-body ragdoll and no networked fluid simulation.
- No final voice, final sound palette, final UI, or final character-art approval inside the implementation batch.

## Human playtest and acceptance criteria

Run P1 only after the current v0.9.x repair gate is recorded or explicitly deferred. Leo and Jon each perform at least two uncoached pluck-to-serve cycles, including one deliberate early release and one deliberate missed catch across the session.

P1 passes only when:

1. Both players identify how to grip and create tension without coaching.
2. Branch and apple presentation responds immediately enough that neither describes the interaction as prompt-driven or delayed.
3. Both can explain which motion loaded the branch and what caused the Ruby to detach.
4. The detach has a readable tension-to-pop arc rather than a timer feel.
5. A missed catch creates a funny, persistent, readable consequence and recovery requires no reset.
6. No path duplicates, destroys, invisibly inventories, or permanently loses the Ruby.
7. Catching and carrying communicate weight without making ordinary movement irritating.
8. The unchanged `Paw_R` handoff still works and remains the final sensory payoff.
9. Both voluntarily choose another pluck after completing the required cycle.
10. Server evidence confirms authoritative detach, one held Ruby at most, valid recovery, and one serve reward per apple.

## P2 and later preserved candidates

- `Gate P2 — One Dirty Apple, One Wash/Polish Station`: dirt removal follows actual hand motion with responsive local ripples/particles, tactile sound, and haptics; no networked full-fluid simulation.
- Later preparation candidates are leaf removal, slicing, caramel or honey coating, and the accidental rice-apple concept re-authored intentionally as a novelty. Each receives one isolated verb gate before combination.
- An orchard may be grayboxed only after P1 proves plucking. Space must then change approach, reach, sightline, reveal, route, or risk.

## Permanent presentation constraints

- The Pipi Labu owner and primary customers are cute bipedal/anthropomorphic Shiba-like characters with two readable legs, expressive eyes, and authored materials/textures. Their face/crown silhouette is circular; ears are tiny lateral hints that may disappear into the fur and never form prominent top peaks. Quadrupeds are deliberate later variants only. Never call or design the owner as a blob.
- The player remains a normal Roblox avatar for now. The current owner scale is too small and needs a later explicit composition gate.
- Customer idle animations must be phase-offset or randomized; synchronized queue idles are rejected.
- The current apple/order labels and patience rectangle feel noisy, static, and ugly. A later UI candidate should explore compact radial/circular urgency without copying Breath of the Wild. Completion must clearly announce the result and next action instead of silently stopping.
- Visible structural objects need honest collision. Non-solid VFX, particles, prompts, and markers must not receive collision blindly.
- Final voice selection, sound-palette approval, UI concept approval, and final character look each require an explicit Leo/Jon creative gate.
- Hermes receives this curated spec and the idea ledger, never raw transcripts or ambient voice chatter.
