# Nightly Conversation Reconciliation — August 8, 2026

This document is the filtered execution record from Leo and Jon's full voice session. It preserves game decisions and workflow corrections while excluding ambient conversation, unrelated politics/media, jokes, and accidental dictation.

Status language:

- `ACTIVE`: canonical private build behavior.
- `IMPLEMENTED_DISABLED`: tested code exists but cannot promote without its named gate.
- `REVIEW_CANDIDATE`: local reversible artifact; no human approval implied.
- `READY`: bounded independent work suitable for Luna.
- `HUMAN_GATE`: evidence/taste decision only; never a global production stop.
- `REJECTED`: do not revive without an explicit new decision.

## Product identity and player fantasy

- `ACTIVE`: player-facing name is **Pipi Labu**, always with a space and this spelling.
- `ACTIVE`: the current player remains a normal Roblox avatar. A custom playable worker-dog/color-variant rig is later exploration, not a dependency for NPC quality.
- `ACTIVE`: the core fantasy is service—take a visible requested apple, carry it, give it to a small customer, see the customer receive/hold/react, and earn progress.
- `READY`: Pipi Labu may become the larger owner/mentor behind the shop: an expressive working shopkeeper who can stress, help, give missions, and anchor story without replacing play with dialogue.
- `ACTIVE`: biblical meaning emerges through service, stewardship, generosity, honest work, good fruit, and neighbor care. No blunt exposition.

## Character direction

- `ACTIVE`: owner and primary customers are cute anthropomorphic/bipedal Shiba-like NPCs with two readable legs and authored materials. Selected four-legged babies may appear later as contrast only.
- `ACTIVE`: universal silhouette is a circular uninterrupted crown. Ears are tiny, lateral, folded into/swallowed by the fur contour, and often visually absent. Prominent upright/top ears are rejected.
- `ACTIVE`: large owner/small customer size contrast is essential. The owner cannot read as a blob or a slightly enlarged customer.
- `ACTIVE`: eyes require visible life—catchlights and restrained warm lower-eye reflection—without uncanny glassiness.
- `REVIEW_CANDIDATE`: v4 Blender/PBR owner and customer assets remain the rendered-quality source. Flat boards are decision surfaces, never a downgrade to final geometry/material quality.
- `REVIEW_CANDIDATE`: ART-002 defines four baby roles—RubySprout, HoneygoldHugger, ShyLoaf, HurryWaddle—on one shared face/material language.
- `REVIEW_CANDIDATE`: Jon's pear-cat reference is integrated as ART-006: an original warm golden spherical orchard cat-loaf for a rare orchard/customer/sourcing event. Its tree-hang, hand-squash, basket-cluster, and receipt-delight states reuse existing verbs. It does not replace the Pipi Labu dog cast, and the rejected literal green-pear interpretation is forbidden.

## Core serve loop and sensory hierarchy

- `ACTIVE`: queue reads parallel to the counter, ready customer centered, and movement proceeds left-to-right from the shopkeeper's view.
- `ACTIVE`: idles are phase-offset; synchronized NPC animation is rejected.
- `ACTIVE`: ordinary choices are Ruby and Honeygold. Early orders teach Ruby before color matching expands.
- `ACTIVE`: wrong apple remains in the player's hand. Teaching cannot confiscate effort.
- `ACTIVE`: apple is unmistakably visible in hand, travels through a fast readable handoff, and becomes a customer-held received apple. Fast next pickup cannot delete a committed toss.
- `ACTIVE`: successful contact/receipt is the sensory peak. Pickup feedback stays restrained.
- `ACTIVE`: customer gets a receive/happy/hold beat before leaving; animation and audio must not obscure the apple.
- `ACTIVE`: current timed shift target is ten serves, with explicit win/loss/replay language. UI copy must avoid AI-flavored filler and guilt phrasing.
- `IMPLEMENTED_DISABLED`: P1 pluck-first branch is the first physical sourcing mechanic: one attached Ruby, visible spring tension, pull/twist, pop, catch/recover, carry, serve.
- `READY`: later physical verbs include washing/polishing, water/soap motion, leaf removal, slicing, honey/caramel preparation, crate opening, and physics-driven drag/impact. Add one verb at a time and reuse known interaction grammar.

## UI, camera, copy, and audio

- `ACTIVE`: approved native HUD direction is warm, compact, world-first medallions—not large black cards or paragraphs.
- `ACTIVE`: top-left HUD sits below Roblox CoreGui safe insets. Persistent redundant `Pipi Labu`/`Good Fruit` title text is rejected.
- `ACTIVE`: customer urgency is circular/radial rather than a large rectangular patience paragraph.
- `ACTIVE`: shift completion must clearly say what happens next; a successful shift cannot feel like a generic failure/retry.
- `ACTIVE`: classic third person is the default, but first-person zoom remains available.
- `ACTIVE`: copy lives in repo keys and the private human editorial surface; the game never fetches a mutable public document at runtime.
- `READY`: original reaction cues use a deterministic shuffle bag, higher/cuter baby variants, restrained owner phrases, and silence fallbacks. Production audio must be rights-safe and newly authored; extracted meme/video vocals remain reference only.
- `READY`: interaction sound work begins in parallel with verbs—strain, rustle, stem pop, wobble, impact, water, cloth, contact, receipt. A fuller adaptive score waits for stable pacing/locations.

## World and map direction

- `ACTIVE`: the shop stays grounded on a collidable base/terrain; floating architecture is rejected.
- `ACTIVE`: visible structural objects have honest collision. Prompts, markers, VFX, fruit, and decorative non-solids do not receive blanket collision.
- `REVIEW_CANDIDATE`: ART-004 modular market kit provides stalls, facade, awning, shelf, crates, lantern, street edge, collision proxies, and an eight-stud service corridor.
- `READY`: compact Japanese city/farmers-market composition—narrow streets, rows of shops, shelves, awnings, fruit displays, neighbor bays, and distant landmarks.
- `READY`: map expansion follows verbs. Orchard follows proven plucking; farmer's market follows inventory sourcing; mountain/landmark route follows a proven rare-customer interruption.
- `READY`: use large/medium/small landmarks, occlusion/reveal, route choice, and sightlines. Do not build a huge imitation open world before compact travel is fun.
- `READY`: neighboring players can cross streets, visit shops, and help one another. Generosity should become useful play, not flavor text.

## Progression, events, and retention

- `READY`: shop upgrades, denser lines, more demanding preparation, inventory planning, and distinct days/shifts build around the handoff instead of replacing it with menus.
- `READY`: weekly farmer's-market sourcing scramble may include playful competition/punching, but cannot erase generosity or accessibility.
- `READY`: controlled disruptions—robber, fire, rotten apple, other surprises—reuse known verbs and arrive one at a time.
- `READY`: reputation/economic moments include paying customers, a customer unable to pay, generosity consequences, and robbery. Do not prematurely punish kindness.
- `READY`: rarity progression can move from ordinary apples toward rare/mythic variants after color matching works.
- `READY`: rare suited/fedora VIP interruption may trigger a restrained lighting/spotlight beat and request a Mythic apple, potentially redirecting the player to a mountain/source through existing carry/serve verbs.
- `READY`: a timed optional call/reaction after handoff could create rank/score expression only after it proves clearer and more fun than noise.
- `ACTIVE GOAL`: optimize for genuine replay desire and long-term/28-day retention through mastery, variety, social helping, progression, and authored surprise—not grind or slot-machine substitution.

## Multiplayer, persistence, and platforms

- `IMPLEMENTED_DISABLED`: pure four-bay shop assignment contract covers allocation, capacity, respawn continuity, leave/rejoin, and immutable server truth.
- `IMPLEMENTED_DISABLED`: pure profile schema covers coins, upgrades, discovered apple types, tutorial state, migration, corruption recovery, and versioning. No DataStore adapter is enabled.
- `READY`: next multiplayer batch connects server-session shop ownership to replicated shop bays without changing solo behavior.
- `READY`: persistence adapter comes after schema review and remains server-owned with bounded retries/session locking. No live DataStore write is implied.
- `ACTIVE TARGET`: console and mobile remain product targets; prompts, camera, HUD, collisions, and hand visibility must be checked at device scale.

## Development methodology

- `ACTIVE`: Leo/Jon live time is gameplay-first—player action, feel, pressure, spatial readability, multiplayer behavior, uncoached runs, and immediate taste decisions.
- `ACTIVE`: when Leo/Jon are absent, Luna continues isolated code, tests, tools, art, maps, audio prep, performance, instrumentation, disabled mechanics, multiplayer/save architecture, and documentation.
- `ACTIVE`: a human gameplay/visual/moderation/taste gate is ticket-scoped only. It blocks only dependent verdict/promotion/default enablement. It never pauses unrelated production.
- `ACTIVE`: only explicit `Paused` stops isolated workers; both `Live` and `AFK` permit them.
- `ACTIVE`: Sol owns framing, architecture, risk, acceptance criteria, integration, and final review; Luna Max owns bounded implementation candidates with deterministic verification.
- `ACTIVE`: every visual pass creates a named gameplay check-in, but the scheduler immediately skips to other independent work while that check-in waits.
- `ACTIVE`: larger batches may contain several independent candidates, but every promoted variable remains separately reversible and testable.
- `ACTIVE`: original authored quality must be indistinguishable from a deliberate human-made game. Generic AI copy, debug markers, incoherent kit geometry, and default-asset presentation are rejected.

## Operations and collaboration

- `ACTIVE`: canonical local repo is `C:\Users\fricc\Documents\Codex\2026-08-07\pipilabu`; exact private place is PlaceId `133099029551440`, GameId `10646495069`.
- `ACTIVE`: boot opens the correct Studio place, one Rojo listener, and XSplit voice bridge; duplicate/blocked places are never mutated.
- `ACTIVE`: routine trusted local work uses no approval prompts. This does not expand authority to public publish, destructive production changes, purchases, or unrelated external messaging.
- `ACTIVE`: Jon's authenticated `[PIPILABU]` Gmail/Buzz notes may be captured and deduplicated into a fixed private ledger. Capture never silently grants execution/publication authority.
- `ACTIVE`: Jon's design/aesthetic questions should be prepared as concise bounded choices when his taste is genuinely needed. His absence does not block unrelated work.
- `ACTIVE`: private Roblox asset moderation is an external state gate. Workers prepare validators/fallbacks and continue elsewhere; they never call the entire project blocked.

## Current overnight routing

1. ART-003 apple/serving-prop kit completed in isolated Luna, is integrated as a verified local review candidate, and remains unapproved/unimported.
2. Canonical code foundations completed tonight: shop-assignment registry plus disabled server adapter, profile schema plus disabled fail-closed persistence adapter, recorder schema v3 timing/continuity instrumentation, and a disabled physical-interaction kernel.
3. ART-006, the disabled multiplayer service adapter, and the disabled persistence adapter are complete as local/technical candidates. Next independent queue: audio implementation candidates and additional authored market/character assets. The physical interaction kernel and rights-safe audio grammar are already complete as disabled/spec foundations.
4. Human v0.9.3 runs and v4/moderation judgments remain honest pending evidence only.

## Explicit rejections to preserve

- No project-wide stop caused by a human gate.
- No prominent top/upright Pipi Labu ears.
- No forced Pipi Labu player rig at the current gate.
- No persistent redundant game title in the HUD.
- No large black paragraph HUD or rectangular patience card.
- No synchronized customer animation.
- No instant disappearing apple or next pickup destroying the prior toss.
- No blanket collision on markers/VFX or walking through visible solid architecture.
- No giant unexplained mascot standing in the middle of the shop.
- No runtime Google Doc dependency.
- No unreviewed free-model scripts in the canonical place.
- No extracted meme voice treated as cleared production audio.
- No public publish/upload/deploy claimed from local candidate work.
