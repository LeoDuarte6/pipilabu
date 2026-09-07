# Pipi Labu v0.9 gameplay-goal completion audit

This audit maps the original gameplay-first objective to authoritative evidence. Passing automated checks proves the build is ready for human evaluation; it does not manufacture Leo and Jon's subjective verdict.

| Requirement | Authoritative evidence | Status |
| --- | --- | --- |
| Standardize public naming | `Config.DisplayName = "Pipi Labu"`; centralized `Copy`; banned-copy assertions in `scripts/test-v0.9-gameplay-contract.luau`; exact private Studio reports v0.9.3-dev | Technically proved |
| Center and reverse the customer queue | Builder uses centered `Spot_01` at X=0, remaining spots at +4.25/+8.5/+12.75, spawn +17 and exit -15; `GameService` assigns queue index 1 to the centered spot and sole serve prompt. A fresh exact-place audit caught stale reverse-signed Studio geometry, corrected it, and technical Play read back live customers at X=0/4.25/8.5 with Ruby/Ruby/Honeygold orders | Technically proved; human spatial-read verdict pending |
| Meaningful multi-apple service | `AppleCatalog` exposes exactly Ruby and Honeygold, deterministic teaching sequence Ruby/Ruby/Honeygold, distinct crates and order medallion; wrong match preserves the held apple and offers swap | Technically proved; attention-vs-walking verdict pending |
| Remove clunky copy | All player-facing copy is centralized; empty serve filler; banned fragments include old spellings, Good Fruit, Nice Serve, Serve Kindly, Front/Small Doge, and Care Board | Proved |
| Improve collision | Baseplate, roof, awning, counter, shelves, stall backs/roofs are structural and repaired through an explicit allowlist; fruit, UI, and markers stay non-collidable | Technically proved; human walk-into-everything check pending |
| Improve serving feel | Server consumes inventory once, reparents the committed apple before motion, follows a 0.16-second restrained paw-targeted arc, settles at the customer, plays receive/happy/hold, and permits immediate next pickup without deleting the traveling apple | Technically proved; satisfaction verdict pending |
| Separate design/specification lane | Sidebar task `Pipi Labu Design Room` (`019fdee0-52fc-7fc1-a50e-0b637db69ff8`) exists and is pinned; repo and installed `$start-pipi-labu-design-room` skill separate specification from canonical implementation | Proved |
| Finish at a recorded human playtest gate without publishing | `PLAYTEST_QUEUE.md` records exact build/place, two-run script, objective checks, qualitative questions, and explicit pending verdict fields; Studio remains private and no publish occurred | Ready; human evidence pending |

## Current completion boundary

All implementation requirements are technically proved. The only evidence that cannot be produced autonomously is the two uncoached Leo/Jon runs and their qualitative answers about spatial reading, satisfaction, pressure, and voluntary replay. That gate blocks only the final gameplay verdict and dependent promotion; isolated production continues.

This gameplay-first batch ends at that recorded gate, exactly as scoped. The batch is complete without pretending the human verdict passed; completing the two runs and replacing the pending fields is the next gameplay task.
