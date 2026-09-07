# Playtest Gates

These gates preserve the historical first-principles progression. Leo and Jon later explicitly authorized the composite v0.9.3 batch (timer plus Ruby/Honeygold matching) before the older gates were individually recorded. The authoritative current gate is therefore `docs/codex/PLAYTEST_QUEUE.md`; these older gates remain useful diagnostic lenses and must not be misread as a project-wide stop.

## Gate A - Serve feel

The v0.4 test failed subjectively: the loop worked, but serving felt like turning a cog or finishing a screwdriver motion. Keep only plain red apples. The v0.5 experiment makes the apple physically leave the player's paw, follow a short forgiving arc, reach the Doge, squash on contact, and only then award the serve. It also squares the shop, lowers the counter to 1.55 studs, fixes the spawn view, removes the Neon queue pads and duplicate order marker, and neutralizes the yellow HUD.

Test with no coaching:

1. Can each player identify the correct Doge and serve once?
2. Were you still looking forward to seeing and causing the handoff itself, or were you pressing Serve only to make it finish?
3. After ten customers, do both players voluntarily serve an eleventh?

Do not build Gate B until this passes by hand.

## Gate B - Ninety-second Dandori run

Add a timer, score, streak, and personal best without new apple types. Run twice. The second run should improve because the players learned technique rather than because randomness changed.

## Gate C - Zero-instruction first customer

Temporarily hide written instructions. A fresh player should complete the first serve within 30 seconds using staging, request presentation, glow, prompts, and reactions.

## Gate D - One-variable color matching

Add only red and gold apples. Keep every other rule fixed. The added choice must create satisfying attention instead of extra walking.

## Gate E - One controlled surprise

After five ordinary orders, clearly announce a 20-second Golden Apple Rush using the same actions. The event passes if players understand it immediately and become excited rather than confused.

## Gate F - Help a neighbor

Give two players adjacent shops and separate queues. Either may carry an apple to the other's shop and earn Goodwill, but cannot steal inventory or sales. The gate passes if helping happens naturally and feels worthwhile.

## Gate G - System multiplication

Only after the relevant A-F qualities pass, add one treatment station and one treated order. Validate `apple color x treatment x request` before building potion depth, market competition, random disasters, or progression systems.
