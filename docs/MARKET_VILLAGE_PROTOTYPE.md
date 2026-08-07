# Market Village Prototype

This is an additive, local-only presentation prototype for Pipilabu's future compact Japanese market/city-village direction. It keeps `Workspace.DogeAppleShop` as the only active gameplay contract and creates a separate `Workspace.PipilabuMarketVillagePrototype` folder beside it.

## What the prototype answers

- Does a narrow street, small plaza, rows of stalls, shelves, awnings, fruit displays, and warm lanterns make the existing apple handoff feel like the first shop in a living neighborhood?
- Do reserved neighboring plots and visible lanes make future generosity/helping legible without pretending multiplayer or ownership exists yet?
- Does a non-blocking Peepilabu owner/quest-anchor placeholder give the market a social focal point without turning into a quest system or obscuring the handoff?
- Does positive service consequence readback make care visible without introducing a timer, loss condition, punishment, persistence, or required extra action?

## Build contract

Run `scripts/build-market-village-prototype.luau` through Studio MCP or the Studio Command Bar in Edit mode only after the existing local shop is present and Rojo has synced `MarketVillage.luau` and `Presentation.luau`.

The script has two safety boundaries:

1. It asserts `PlaceId == 0` and `GameId == 0`.
2. It deletes only a pre-existing folder with the exact prototype root name, then recreates that folder. It never edits, reparents, or replaces `Workspace.DogeAppleShop`, the Baseplate, Lighting, or SpawnLocation.

The whole lane is removable with one bounded local deletion of `Workspace.PipilabuMarketVillagePrototype`. No asset upload, publish, remote, DataStore, multiplayer authority, or Blender workflow is involved.

## Layout grammar

| Region | Prototype content | Intent |
| --- | --- | --- |
| `Grounding` | Market Street and Market Plaza | Establish a compact readable grid around the existing shop. |
| `AuthoredFixtures` | Tea, Flower, Rice, and Lantern stalls; shelves; awnings; fruit displays; lantern posts | Test authored color, silhouette, prop density, and commerce rhythm with primitives. |
| `NeighborLanes` | Four narrow lanes linking the current shop side and future plots to the street | Make adjacent help routes legible without enabling travel or ownership logic. |
| `FutureShopPlots` | Four labeled reserved pads with lane metadata | Make adjacent shops and generous help spatially legible without activating ownership. |
| `StewardshipDisplay` | Three care markers and a board message/count | Show positive service consequences at 3, 6, and 10 completed handoffs. |
| `PeepilabuQuestAnchor` | Small owner placeholder, clipboard, and deferred-role label | Give the village a social anchor without a prompt or quest behavior. |
| `ExtensionSeams` | Reputation, Economy, RandomEvents, and NeighborHelp marker folders | Reserve named integration points; every seam is explicitly inactive. |

The current shop remains at its existing coordinates. The village grid occupies the open space toward the spawn-side plaza and extends north along a ten-stud market street. All prototype fixtures are non-collidable and non-queryable so they cannot steal movement, prompt, or apple-handoff behavior from Gate A.

## Stewardship readback

`src/shared/Stewardship.luau` is a pure contract:

| Completed serves | Stage | Visible readback |
| ---: | --- | --- |
| 0–2 | `OPEN HANDS` | Board starts quiet; existing coin/served loop is unchanged. |
| 3–5 | `WARM WELCOME` | Care marker 1 lights; board message changes. |
| 6–9 | `GROWING LANE` | Care marker 2 lights; board message changes. |
| 10+ | `GOOD CARE TRAVELS` | Care marker 3 lights; board reaches the current ten-serve test point. |

The optional `StewardshipService` binds only when the prototype folder exists. It mirrors the existing `Served` count into a temporary `Goodwill` readout and updates the board/markers. It does not alter the existing `Coins` reward, queue timing, prompt rules, customer behavior, or success/failure state. It has no clock, decay, loss branch, DataStore, player ownership, or random event.

The optional `MarketPresentation.client.luau` adds a small safe-area card only in prototype mode. The normal Gate A HUD is unchanged when the village folder is absent.

## Bounded test

1. Build the existing local Doge Apple Shop, then run the village builder.
2. Play the ordinary red-apple pickup and handoff loop without coaching.
3. At 0, 3, 6, and 10 served customers, inspect the board, care markers, player `CareMarks`, `StewardshipStage`, and `Goodwill`.
4. Confirm the player can still identify the crate/front Doge, carry one apple, complete the visible handoff, and watch the queue cycle.
5. Walk past the Peepilabu placeholder and future plots. Confirm there is no prompt, collision, ownership claim, quest, timer, loss, or required detour.
6. Confirm all four `ExtensionSeams` remain `Active = false`.

The human question is: “Does the market feel more alive and does care feel visible, while the handoff remains the reason to play?” If the answer is no, delete the prototype root and keep the existing shop unchanged.

## Extension seams

The named folders are scaffolding, not implementation permission:

- `Reputation`: future visible trust/reputation experiments after service and neighbor-help gates.
- `Economy`: future poor-customer, payment, or honest-work experiments, one variable at a time.
- `RandomEvents`: future controlled disruptions that reuse known actions; no surprises are active here.
- `NeighborHelp`: future adjacent-shop help tests; no multiplayer or ownership authority exists here.

Future systems should consume these stable names or add a versioned contract rather than reaching into the current shop's queue internals. The village prototype is intentionally presentation-first so it can be removed without a gameplay migration.
