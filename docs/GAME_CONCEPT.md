# Doge Apple Shop

Working title only. This document captures the concept Leo and Jon developed by voice on 2026-08-07.

## One-sentence fantasy

You work in a warm Doge market shop, hand fruit to a growing line of little Doges, and help build a generous neighborhood around it.

## Design pillars

- Service feels active, physical, and satisfying rather than menu-driven.
- Every apple is handled one at a time so pressure comes from movement and prioritization.
- Growth means becoming a better steward: a better shop, more capacity, and more neighbors served.
- Biblical themes live underneath the world through generosity, stewardship, good fruit, honest work, and care for neighbors.
- Comedy and Doge absurdity keep the experience approachable.

## First playable slice

The smallest complete loop is:

1. Walk to the apple crate.
2. Take one apple.
3. Carry it visibly.
4. Give it to the next small Doge in a queue that runs parallel to the counter and advances left-to-right, like the reference video.
5. See that customer visibly receive and hold the apple before leaving.
6. Earn a coin and one served-customer point.
7. Watch the line advance and repeat.

The slice is successful when two people can understand that loop without developer explanation, complete it repeatedly, and see both progress values increase.

## Next layers, not MVP

- Timed orders that begin with red and gold apple matching.
- Treated apples made at a potion/barista-style station after color matching is proven fun.
- Shop upgrades and additional products.
- Busier days, more complicated orders, and Overcooked-style coordination.
- A street of player shops where neighbors can carry supplies, clear overflow orders, and earn visible Goodwill for helping.
- Multiplayer ownership in which each player receives a shop, backed by saved account progression once the one-shop loop has passed its playtest gates.
- Controlled surprise events such as a Golden Apple Rush, a rotten-apple cleanup, fire, or a robber. Surprises must use rules the player already understands.
- A weekly farmer's market where players compete for limited crates and bring inventory home for the week.
- Physical competition at the market, including scrambling and playful punching.
- A larger story and more explicit thematic meaning once the core service loop is fun.
- A fully rigged playable Doge and animated customer cast.
- Peepilabu as a large, cute, visibly stressed shop owner who anchors the setting, gives tasks or quests, and makes the player feel like a worker in a living shop rather than its only moving part.

## World and presentation direction

- Start with one compact, grounded shop; do not let the kiosk, customers, or path read as floating above the map.
- Grow toward a dense Japanese market/city-village rhythm: narrow streets, parallel storefronts, shelves, awnings, fruit displays, and small readable gathering spaces rather than an empty Roblox baseplate.
- Keep authored composition, silhouettes, animation, copy, and props specific enough that the result does not read as generic AI output or an untouched Roblox template.
- Use third-person as the designed default camera, while allowing a player to enter first-person if they choose.
- Keep the HUD in the upper-left but below Roblox CoreGui controls and safe insets. Replace placeholder slogans such as `GOOD FRUIT` with concise world-specific copy selected by Leo and Jon.

## Character-audio grammar

- Successful service draws baby-customer reactions from a no-immediate-repeat shuffle bag so repeated handoffs stay lively.
- High-pitched `Peepilabu` clips belong to the small customers. Larger/player callouts such as `What the dog doing?` are reserved for a separately tested pre-handoff interaction rather than mixed randomly into every reward.
- The apple transfer, the customer's visible hold, and the reaction sound should read as one authored beat before the customer exits.

## Current experiment

The first build uses deterministic primitive Doge customers for reliable movement and interaction. One generated Doge asset is tested separately so model-generation quality cannot block the playable loop.

## Prototype doctrine

The internal culture shorthand is “new Valve”: Leo and Jon talk freely, Codex turns the discussion into small playable builds, and the humans enter at explicit gates. The game is not allowed to grow past the service loop until serving a plain red apple is satisfying enough that a player voluntarily serves one more.
