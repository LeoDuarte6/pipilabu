# Pipi Labu Handoff Cue Grammar

Status: local implementation specification. No audio asset is approved, uploaded, or published by this document.

## Sensory rule

The successful apple contact and visible customer receipt are the loudest, clearest, most rewarding moments. Pickup confirms state quietly. Carry is mostly visual. Character reactions add life after contact and never mask it.

## Rights rule

- Supplied Pipi Labu/What-the-dog-doing video vocals are reference material only.
- Production cues and voices must be newly recorded or newly synthesized from an original performance with documented rights.
- Do not imitate a distinctive third-party voice closely enough to imply it is the source performance.
- Every production candidate records creator/tool, prompt or performance notes, license/ownership, edit history, and Roblox asset moderation state.
- Missing rights metadata means silence, not fallback to a ripped clip.

## Cue hierarchy

| Beat | Cue family | Target role | Relative peak | Concurrency |
| --- | --- | --- | --- | --- |
| Aim/hover | soft paw/cloth tick | Optional affordance only | -24 dB from contact | 1 per player |
| Pickup | short leaf/wood/paw confirmation | Inventory state changed | -12 dB from contact | 1; newest replaces prior |
| Swap apple | two-note soft tick | Different apple now held | -10 dB from contact | 1; no voice |
| Branch strain | elastic wood + leaf movement | Continuous physical tension | -14 to -8 dB | 1 per object; parameterized |
| Stem pop | dry pop with tiny low body | Sourcing release | -6 dB | 2 global |
| Apple travel | usually silent; optional quiet air tuck | Preserve visual clarity | -18 dB | 1 per handoff |
| Contact | authored crisp body + soft fruit thump | Primary action peak | 0 dB reference | 2 global |
| Customer receipt | warm paw/chest settle | Confirms possession | -3 dB | 2 global |
| Happy reaction | short original syllable/chirp | Character delight after receipt | -5 dB | 1 customer voice + 3 global |
| Wrong apple | restrained puzzled chirp | Teaches without punishment | -10 dB | 1 customer voice |
| Miss/leave | disappointed breath/step | Consequence, not shame | -9 dB | 2 global |
| Shift clear | compact musical resolution | Closure and replay invitation | -2 dB | 1 global; ducks reactions |
| Shift lost | soft unresolved cadence | Clear result without humiliation | -7 dB | 1 global |

Relative peaks are mix relationships, not final Roblox `Volume` values. Final values require a measured in-engine audition on desktop, phone speaker, headphones, and console/TV distance.

## Reaction grammar

Each semantic role owns a deterministic shuffle bag. A bag plays every eligible cue once before reshuffling; it cannot repeat the immediately previous cue across a refill.

Candidate roles:

- `BabyHappyHigh`: tiny high original syllables for small customers.
- `BabyHappySoft`: breathier/quiet delight for ShyLoaf-type customers.
- `BabyEager`: quick bright response for HurryWaddle-type customers.
- `OwnerApprove`: warm low shopkeeper acknowledgement.
- `OwnerStressed`: short nonverbal concern; never a lecture.
- `WrongOrderPuzzled`: gentle question-like cue.
- `RareCustomerEntrance`: one bounded event sting, not permanent background music.

Rules:

- Reaction begins 40–110 ms after contact so the impact reads first.
- Maximum reaction length is 850 ms for ordinary customers.
- Pitch randomization stays within a restrained authored band; random pitch cannot be the only differentiation.
- A customer with no cleared cue stays silent while animation/face/received apple carry the response.
- Owner and customer voice cues never overlap; customer receipt wins.
- No spatial voice should remain audible after its customer is destroyed.

## Implementation contract

- Server owns semantic events: pickup, swap, handoff committed, contact completed, wrong order, miss, shift result.
- Client owns local playback and optional haptics after receiving an authorized semantic event.
- Cue selection uses the existing deterministic shuffle-bag contract with rights-safe IDs only.
- Sound IDs, volumes, playback rates, cooldowns, and role eligibility live in one shared catalog.
- Catalog validation fails closed on missing/zero IDs, unknown roles, out-of-range volume/rate, duplicate cue IDs inside a role, or missing rights metadata.
- Ordinary gameplay never waits for a sound to load or finish.
- Mobile low-memory fallback keeps contact and shift-result cues, then drops hover/travel/secondary reactions first.

## Human audition gate

Leo and Jon compare two or three bounded original cue families during the same unchanged ten-customer shift.

Record:

1. Is contact unmistakably stronger than pickup?
2. Does the customer reaction feel cute after ten serves or become repetitive?
3. Can Ruby/Honeygold still be read visually with audio muted?
4. Does phone-speaker playback preserve contact without harshness?
5. Does rapid serving create clipping, voice pileup, or delayed reactions?
6. Which candidate feels authored for Pipi Labu rather than pasted from a meme?

This gate approves a cue family only. Other code, art, map, multiplayer, save, and tooling tickets continue while it waits.
