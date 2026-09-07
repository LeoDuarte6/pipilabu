# ART-006 - Pipi Labu pear-cat harvest-event study

Date: 2026-08-08
State: `REVIEW_CANDIDATE` / local-only / `human_approved=false` / `studio_imported=false`

## Outcome

Created the isolated candidate at `assets/candidates/pipilabu_pear_cat_harvest_event_v1/`. Following the visual review correction, the ticket nickname remains pear-cat but the authored identity is a warm tan/golden, nearly spherical orchard cat-loaf: heavy hand-squash, extremely tiny lateral side-folded ears nearly swallowed by fur, narrow feline eyes, cat nose/mouth, short whiskers, and paws. Apples remain tree, basket, or receipt context; the cat is not a literal green pear and has no crown stem/leaf. It remains clearly outside the Pipi Labu dog cast and never replaces the owner, player, or baby cast.

The review surface shows four states tied to existing verbs:

1. `ORCHARD_REST` - quiet / curious, under a tree beside a basket.
2. `HARVEST_PEEK` - bright / ready, one reach cue.
3. `CONTACT_DELIGHT` - delight / receives, a visible Ruby receipt apple between paws; this is the sensory peak.
4. `BASKET_GOODBYE` - satisfied / leaves, a small carry-away resolution.

The mechanic contract is `reach -> carry -> serve -> contact -> hold/receipt`. No new sourcing, rarity, queue, patience, reward, economy, HUD, audio, or timing rule was added.

The PNGs are flat cast/pose and mechanic decision surfaces. They are not a downgrade of, replacement for, or approval of the approved rendered v4 Blender material quality. Any future 3D authoring must retain the v4 production bar for authored materials, eye catchlights, rig quality, and mobile readability.

## Reconciled input and provenance

No raw pear-cat attachment was present in the isolated worktree. The source scan found no matching pear/orchard/harvest reference file under the local `assets`, `.local`, or `docs` paths. The corrected user-supplied ART-006 visual brief is therefore recorded as the source input and hashed in `generation_report.json`:

`e52d1fe2a11835aabacade3b6055913701720ca685411a3e54a15137073f247e`

The generation report records paths, byte counts, and SHA-256 hashes for the doctrine sources used:

- `docs/IDEA_LEDGER.md`
- `docs/CHARACTER_ART_DIRECTION.md`
- `docs/GAME_CONCEPT.md`
- `docs/art/OVERNIGHT_ART_LEDGER.md`
- `docs/codex/PLAYTEST_QUEUE.md`

## Candidate artifacts

- `assets/candidates/pipilabu_pear_cat_harvest_event_v1/pear_cat_harvest_event_contract.json`
- `assets/candidates/pipilabu_pear_cat_harvest_event_v1/pear_cat_harvest_event_sheet.png`
- `assets/candidates/pipilabu_pear_cat_harvest_event_v1/pear_cat_harvest_event_mobile_strip.png`
- `assets/candidates/pipilabu_pear_cat_harvest_event_v1/scripts/generate_pear_cat_harvest_event.py`
- `assets/candidates/pipilabu_pear_cat_harvest_event_v1/scripts/verify_pear_cat_harvest_event.py`
- `assets/candidates/pipilabu_pear_cat_harvest_event_v1/generation_report.json`
- `assets/candidates/pipilabu_pear_cat_harvest_event_v1/verification/structural_report.json`

Current generated hashes:

- Review sheet `1800 x 1120`: `d185365cdd1b0cc353ed8f67a652c0da9eb47e047414c9a4f176aeb2e47cdac1`
- Mobile strip `960 x 420`: `67648ddff369a86ca2510a883a38faf0c0c7c9f08486b165e888a5dc63b7808e`
- Contract: `42203e1b4bcdb23c1050fbb38516c2d04c8049c8f79735ea7135138b508fa17a`

## Verification evidence

Ran from the repository root:

```text
py -3 -m py_compile assets/candidates/pipilabu_pear_cat_harvest_event_v1/scripts/generate_pear_cat_harvest_event.py assets/candidates/pipilabu_pear_cat_harvest_event_v1/scripts/verify_pear_cat_harvest_event.py
PIPILABU_PEAR_CAT_GENERATED sheet=1800x1120 mobile=960x420
PIPILABU_PEAR_CAT_VERIFY_OK
```

Visual inspection of both generated PNGs confirmed the identity subtitle, callouts, REST caption, four state names/emotions, feline eye catchlights, whiskers, and Ruby receipt remain readable without the earlier lower-left overlaps. The mobile strip makes the tan/golden cat-loaf, nearly hidden lateral ears, feline expressions, and contact fruit legible as a compact review surface.

The structural verifier also confirmed the source hashes, all-false approval/import/mutation flags, exact state order, 2.25 x 2.35 x 2.1 stud body contract, ground-center pivot, receipt accent, and absence of Studio/place/Blender/runtime assets in the candidate folder.

No gameplay Luau, canonical asset, Rojo mapping, Studio instance, place file, cloud asset, upload, publish state, or existing market, baby-cast, or apple/serving-prop candidate was changed.

## Risks and open decisions

- This is a 2D authored study. It does not prove Blender topology, PBR response, rigging, animation, collision, import scale, or mobile performance.
- Because the raw attachments were inaccessible, this candidate cannot claim exact visual reconciliation against those images; it follows the supplied fallback brief and the hashed local doctrine instead.
- The tan/golden cat-loaf is intentionally distinct from the caramel/cream dog cast, but human review must still reject it if it reads as a dog variant, literal fruit, generic mascot, or replacement cast member.
- The basket/tree are context cues only. They must not become extra collision, occlusion, sourcing chores, or screen noise.
- The candidate is not final art, not a mechanic approval, and not a promotion decision.

## Exact future human and private-play gate

1. Leo and Jon review the full sheet and mobile strip at native size and thumbnail size. Explicitly decide `accept`, `revise`, or `reject`; acceptance must confirm distinct orchard identity, no top/upright ears, readable harvest/contact/receipt states, visible eye life, and no owner/player/baby replacement reading.
2. If the visual decision survives, author one bounded 3D golden orchard-cat candidate in a disposable local `0/0` sandbox. Keep the proposed body bounds `[2.25, 2.35, 2.1]` studs, `ground_center_under_body` pivot, single readable body collision proxy, and no collision on ear hints, held fruit, or tree/basket context. Preserve the approved v4 material quality bar; do not import this board as a texture or add literal pear/stem anatomy.
3. Only after that visual decision and a separately recorded gameplay gate, verify the intended private Studio instance is `PlaceId=133099029551440`, `GameId=10646495069`, with Edit access. Place the disposable candidate under a clearly named candidate root only; do not alter `src/`, Rojo mappings, canonical assets, or existing candidates.
4. Test one optional encounter with rarity/event toggled off by default. Reuse the existing reach, carry, serve, contact, hold/receipt verbs and current service timing. Do not add sourcing, queue, patience, reward, economy, HUD, or audio rules in the integration pass.
5. Run mobile and desktop checks for one-second silhouette recognition, contact-fruit visibility, prompt/queue/sightline clarity, collision, timing, and whether surprise improves the serve loop. Remove the sandbox root if it steals focus, slows targeting, creates collision ambiguity, or requires a new mechanic to understand.
6. Only an explicit later Leo/Jon decision after that private evidence may promote or reject the candidate. Nothing in ART-006 authorizes Studio mutation, upload, publish, or canonical replacement.

## Independent work that may continue

While this human gate is pending, safe independent work includes additional isolated art candidates, rights-safe reference translation, render/mesh experiments outside Studio, deterministic contract/verifier improvements, and documentation. Gameplay Luau, canonical place edits, Studio import, cloud changes, upload, publish, and any promotion remain out of scope until separately authorized and gated.
