# Pipi Labu v0.9.x Completion Audit

Objective: advance the canonical private build through the gameplay-first batch and finish at a recorded human playtest gate without publishing.

| Requirement | Authoritative evidence | Status |
|---|---|---|
| Finalize player-facing name as `Pipi Labu` | `Config.DisplayName`; `scripts/test-v0.9-gameplay-contract.luau`; current `Copy` values | Proved |
| Center the recipient and reverse the line to left-to-right | `GameService` runtime normalization; exact-place queue spots `0, 4.25, 8.5, 12.75`; spawn X `17`; exit X `-15`; `QueueScreenDirection=LeftToRightFromShopkeeper` | Proved technically; human screen-direction verdict pending |
| Add meaningful multi-apple service | `AppleCatalog`; Ruby/Honeygold crates; wrong match retains held apple; exact-place pickup/handoff evidence; v0.9 contract | Proved technically; subjective value pending |
| Remove clunky copy and implement approved HUD direction | `Copy`; `HudView`; banned-copy/button contract; exact-place v0.9.2+ Waiting and terminal captures | Proved technically; human readability verdict pending |
| Improve collision | Builder rules; runtime exact-name structural repair; exact private Play reports 24 repaired shop/stall parts; `scripts/test-collision-contract.luau` guards shop, market, ground, queryability, and non-structural exclusions | Proved technically; human walk-through check pending |
| Improve serving feel | 0.16-second paw-targeted handoff; receive/hold animation; received apple welded to v4 `Paw_R`; committed toss leaves player inventory as `HandoffApple` before motion so a fast next pickup cannot delete it | Proved technically; feel pending |
| Stop synchronized customer motion | deterministic idle-phase contract; exact-place customers report distinct loop time positions | Proved technically; visual naturalness pending |
| Create a separate design/spec task and skill | `Pipi Labu Design Room` task `019fdee0-52fc-7fc1-a50e-0b637db69ff8`; installed `$start-pipi-labu-design-room` | Proved |
| Preserve private/local boundary | exact PlaceId `133099029551440` / GameId `10646495069`; blocked duplicate excluded; no Git remote; no public publish | Proved |
| Record the human gameplay gate | Recorder schema v2 exposes build/place identity, latest completed pair, wrong-attempt total, objective readiness, and explicit human-verdict state; current `RunCount=0` and no post-v0.9.3 Leo/Jon qualitative answers are recorded | **Pending human test** |

## Required final evidence

1. Two uncoached Leo/Jon runs in the v0.9.3 Play session.
2. At least one intentional wrong-color serve attempt.
3. Recorder summaries for both runs.
4. A qualitative verdict on first-action clarity, screen-space queue direction, crate/order readability, native medallion HUD, paw-targeted handoff feel, fast-next-pickup continuity, collision honesty, 18-second pressure, matching friction, terminal clarity, and voluntary replay.
5. Update `PLAYTEST_QUEUE.md` to `RECORDED`, update the handoff and durable memory, and only then mark the active goal complete.

An unattended or Codex-controlled run cannot satisfy this requirement. The isolated Physics Lab and local no-top-ear Blender renders are separate review evidence and cannot substitute for the service-loop gate.
