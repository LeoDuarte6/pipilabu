# Jon Codex Bootstrap Brief

This is the one handoff Jon can give to a fresh Codex installation. It explains how to acquire the project, connect Codex to Roblox Studio, recover the current project context, and work without touching the wrong place or losing Leo's newer uncommitted work.

Shared Google Doc: <https://docs.google.com/document/d/1KzwPfXaFY1etcvu32myrPCXov9NmM7fb02BrFn2Id04/edit>

## Paste this into Jon's first Codex task

> I am Jon Walworth, GitHub `jawnwalworth-tech`, Roblox `jwallyguy` / `Awchism`. Set up my computer for the private Pipi Labu Roblox project using this brief as the initial authority. Inspect my operating system and installed tools first. Install or configure routine local prerequisites directly when I have given Codex Full Access. Do not invent or reconstruct the repository from prose: obtain Leo's verified private remote URL or transfer bundle first. After the repo exists locally, read `AGENTS.md`, `README.md`, this brief, `docs/codex/HANDOFF.md`, `docs/codex/PLAYTEST_QUEUE.md`, and `docs/IDEA_LEDGER.md` before substantive work. Configure Roblox Studio's built-in MCP server, install the pinned Rokit/Rojo toolchain, start exactly one Rojo server on port 34872, and verify the exact PlaceId and GameId before any Studio mutation. Never touch PlaceId `104936800417970`. Do not publish, make the experience public, upload assets, spend money, create or change a Git remote, delete data, or push unfinished work without current explicit direction. Do not configure XSplit or a voice bridge on my machine. When setup is complete, report the exact local repo path, Git HEAD/branch/remote, tool versions, Rojo listener, connected Studio instance and IDs, live `Config.DevelopmentVersion`, Output errors, and the current playtest queue state.

## People and fixed identities

- Leo Duarte: GitHub `LeoDuarte6`; Roblox `thegreatwizardrock2`.
- Jon Walworth: GitHub `jawnwalworth-tech`; Roblox `jwallyguy` and `Awchism`.
- Jon's confirmed email: `jawn.walworth@gmail.com`.
- Correct private experience: `Pipilabu`.
- Correct GameId / UniverseId: `10646495069`.
- Correct PlaceId: `133099029551440`.
- Blocked older duplicate PlaceId: `104936800417970`.
- Blocked older duplicate GameId: `10646407271`.
- Both Jon Roblox accounts have Edit access to the correct private experience.

The place IDs are hard safety boundaries. Before Codex reads or mutates Studio state, it must list Studio instances, select the correct one, and assert both exact IDs. A window title containing “Pipilabu” is not sufficient identity proof.

## What Pipi Labu is

Pipi Labu is a private Roblox game Leo and Jon are designing together. The core fantasy is working in a warm Doge market shop: physically handle fruit, serve a line of tiny Doges, receive a satisfying reaction, earn pay, and gradually help build a generous neighborhood.

The design pillars are:

- Active, physical service rather than menu-driven work.
- One apple at a time so movement, rhythm, and prioritization create pressure.
- Growth through stewardship, shop capacity, recipes, neighbors, and generosity.
- Biblical meaning through action—good fruit, honest work, service, care, and generosity—without blunt exposition.
- Doge absurdity and warmth, with an authored rather than generic-AI presentation.
- Action-first development: prove one repeated verb by hand, then add one variable.

The sensory center is the apple handoff. The apple must remain visible, travel cleanly into the customer's paws, remain in the customer's possession for a readable beat, and own the strongest animation/audio reaction.

## Current source and transfer truth

- Leo's canonical checkout is `C:\Users\fricc\Documents\Codex\2026-08-07\pipilabu`.
- Branch: `main`.
- Private remote: <https://github.com/LeoDuarte6/pipilabu>.
- Jon's GitHub account `jawnwalworth-tech` has a pending write-access invitation.
- Required historical baseline: `0615886c7841ec02887261248642d0eb6b30c973` must be HEAD or an ancestor.
- The repository includes the reconciled `v0.9.9-dev` game, tests, docs, art candidates, and tooling rather than the previous stale HEAD-only snapshot.
- Git LFS owns the large Blender, FBX, PNG, audio, and video binaries; install Git LFS before cloning or checkout.

First collaboration gate: accept the GitHub invitation, install Git LFS, and clone the verified private remote. Do not reconstruct the project from prose or create a second empty repository.

## Current playable state

Disk `src/shared/Config.luau` reports `0.9.9-dev`.

The current first shift contains:

- Eight customers, with no replacement spawns during level one.
- Ruby and Honeygold orders; the first two orders teach Ruby.
- Visible world pickup prompts on the display apples during an active shift.
- One carried apple at a time; the wrong apple returns to the player instead of being confiscated.
- A compact warm medallion HUD with time, served, missed, order/patience, and end-state presentation.
- An interior shopkeeper at the rear-left with world interaction and bottom-screen dialogue subtitles.
- Terminal physical shift pay: `$2` base, `$1` per served customer, and a `$4` full-clear bonus.
- A world cash bundle beside the shopkeeper. The result remains `COLLECT PAY` until the player uses the world prompt. Collected notes appear in the avatar's hand and the session balance survives into the next shift. Persistent account saving and a spending shop are intentionally still disabled.
- A Studio-only Physics Lab that uses one continuous apple journey: pluck a dirty apple, carry it into deep responsive water, physically pour soap, scrub it clean, lift the crate lid, and drop the same apple into one of six grid slots.

Automated/runtime evidence already proves the state transitions, payout math, literal prompt collection, held cash, bottom subtitle, fixed population, responsive water, and crate path. It does not prove that the interaction feels good. Human tactile judgment is still required.

## Current human playtest

`docs/codex/PLAYTEST_QUEUE.md` is the only current playtest-status surface. It currently records `READY`, build `v0.9.9-dev`, 8–10 minutes, using the local `0/0` fallback. This repair pass has not been published to the private cloud place.

The required pass checks:

1. The eight-customer line does not refill after a miss.
2. Ruby and Honeygold pickup routes are clear and not blocked by the shopkeeper.
3. Shopkeeper dialogue remains readable while moving and the roof remains visible/collidable.
4. The same Physics Lab apple survives pluck, wash, soap, scrub, crate drop, and six-slot lock.
5. Pluck lag, water depth, crate snap, button depth, and overall comfort feel satisfying.
6. A finished or failed shift produces the correct physical pay, collection state, held-note prop, and retained session balance.
7. Bottom-screen dialogue feels like character dialogue, not another HUD card.

Only Leo and Jon can record the qualitative verdict. Automated tests may record objective state but must never mark a human taste gate as passed.

## Character and art state

- The player remains a normal Roblox avatar for the current gates.
- The owner is the hero NPC: a room-filling fused-neck Shiba orb with a continuous rounded crown, low wet eyes, broad cream muzzle/cheeks, tiny paws, and no readable upright top ears.
- Leo selected owner identity A, the room-frame giant orb. The cute counter-frame naturalistic Shiba remains a separate future character/reference and must not be averaged into the owner body.
- The current registered 2D owner target is `assets/concepts/pipi-labu-owner-reconstruction-sheet-v11.png`.
- A v11 rig/import pipeline crossed the real Blender-to-Roblox boundary and remains quarantined under `ServerStorage.PipiLabuV11CandidateAssets`; it is not approved to replace the active shopkeeper.
- Procedural ellipsoid iterations, top-ear variants, TripoSR controls, Roblox GenerateMesh controls, and other rejected candidates remain evidence only.
- The most recent Meshy-era state has one visually approved child/customer raw, one liked adult identity raw with missing lower limbs, one adult anatomy donor that reads too hamster-like, and a prepared canine-corrected v14 turnaround. Further paid Meshy use and the remaining recorded credits are deferred until Jon confirms with Leo.
- Private or candidate asset import success is not visual approval. Review front, three-quarter, side, rear, mobile-distance read, deformation, materials, paws, and attachments before promotion.
- The approved HUD direction is `assets/concepts/pipi_labu_hud_direction_v1.png`; rebuild it with native responsive Roblox UI, not as a baked image.
- The primary visual grammar reference is `assets/reference/peepilabu-market-reference.mp4`. Re-author the character and scene; do not copy compressed video pixels, UI, logos, or copyrighted sound.

## Prioritized idea stack

### Now

- Make the `take -> carry -> handoff -> customer enjoyment -> shift pay` loop obvious and satisfying.
- Keep level one to Ruby/Honeygold, eight fixed customers, one apple at a time, honest collision, readable queue direction, and humane pressure.
- Decide whether color matching adds satisfying attention or only walking.
- Decide whether the physical cash ritual creates desire for the next mechanic.
- Pass the current tactile/comfort gate before promoting more systems.

### Next, one gate at a time

- P1: one Ruby on one springy branch. The implementation exists behind `Enabled=false` and `StudioOnly=true`; it is not promoted.
- P2: one dirty apple and one physical wash/polish station.
- Better apple access and authored recipes as the first spending targets.
- One pre-handoff character interaction that creates anticipation or relationship.
- Shop upgrades only when repetition creates a clear desire for capacity, expression, or mastery.
- Adjacent friend shops, carrying supplies, clearing overflow, and visible Goodwill only after the one-shop loop works.
- Multiplayer shop assignment and durable account progression only after ownership/reset semantics are explicit and verified.

### Later, preserved but gated

- Orchard and farmer's-market sourcing with distinct physical verbs.
- Leaf removal, polishing, slicing, honey/caramel treatment, recipes, and eventually fried chicken.
- Living-market systems: carts, source traffic, guards/robbers, fires, rotten apples, rare VIP customers, and controlled surprises that reuse known actions.
- Weekly inventory competition and playful physical competition only after cooperative shops work.
- A compact Japanese market/city village with narrow streets, parallel storefronts, awnings, shelves, lanterns, and legible gathering spaces.
- A custom worker-dog player rig with color variation only after owner/customer art gates pass.
- Original character-specific bit-crushed bleep grammars inspired by readable game dialogue without copying Animal Crossing, The Sims, or Undertale audio.
- Instrument voluntary replay, time-to-first-serve, abandonment, completion, source choice, and later real D1/D7/D28 cohorts. Never claim retention without real cohort evidence.

`docs/IDEA_LEDGER.md` is the canonical long-form idea record. Ambient jokes, unrelated voice chatter, and accidental dictation are not requirements.

## Architecture and code truth

There are three channels:

1. Filesystem plus Git are code truth. Edit `.luau` under `src/`.
2. Rojo is the live code bridge from disk to Studio on `localhost:34872`.
3. Studio MCP is the observation, bounded world-edit, runtime-input, and playtest bridge.

Never edit Rojo-owned scripts through Studio or MCP `multi_edit`. Those changes are not durable Git truth and can be overwritten by the next Rojo sync.

Disk-to-Studio mapping:

- `src/shared/` -> `ReplicatedStorage/JonAndLeoDevelopment`.
- `src/server/` -> `ServerScriptService/JonAndLeoDevelopment`.
- `src/client/` -> `StarterPlayer/StarterPlayerScripts/JonAndLeoDevelopment`.

Server code owns authoritative gameplay state. Client code owns input, camera, HUD, water/drag presentation, and prediction only where explicitly designed.

Important modules:

- `src/server/GameService.luau`: queue, shift lifecycle, prompts, carried apple, handoff, misses, payout, and cash collection.
- `src/client/HudView.luau`: responsive native HUD and bottom dialogue.
- `src/client/PhysicsLabDrag.client.luau` and `PhysicsLabWater.client.luau`: pointer-owned tactile presentation.
- `src/server/PhysicsLabService.luau`: authoritative Physics Lab state.
- `src/server/CustomerPresentationService.luau`: customer visual/animation adapter with fail-closed primitive fallback.
- `src/server/OwnerPresentationService.luau`, `OwnerInteractionService.luau`, and `OwnerAnimationAdapter.luau`: owner presentation and dialogue.
- `src/server/PlaytestRecorderService.luau`: bounded objective test evidence; it must not infer taste.
- `src/shared/Config.luau`: version and gameplay tunables.
- `src/shared/Copy.luau`: reviewed runtime player-facing copy.
- `src/shared/AppleCatalog.luau`: apple definitions.
- `src/shared/PhysicalInteractionKernel.luau`: disabled future shared authority seam.
- `src/server/ProfilePersistenceService.luau` and `src/shared/ProfileSchema.luau`: disabled, fail-closed persistence candidate.
- `src/server/ShopAssignmentService.luau` and `src/shared/ShopAssignment.luau`: disabled multiplayer shop-assignment candidate.
- `src/server/P1SpringyBranchService.luau` and shared P1 modules: disabled Studio-only first sourcing candidate.

## Repository map and reading order

Read before work:

1. `AGENTS.md` — hard operating, safety, playtest, and verification rules.
2. `README.md` — workspace overview and source mapping.
3. `docs/codex/HANDOFF.md` — verified implementation history and newest gates.
4. `docs/codex/PLAYTEST_QUEUE.md` — only current human-test status.
5. `docs/IDEA_LEDGER.md` — preserved ideas and sequencing.
6. The exact feature/design document for the lane being changed.

Directory roles:

- `src/`: durable Luau code.
- `scripts/`: boot/dev helpers, local world builders, model-generation/verification tools, deterministic Luau/Python tests, and automation adapters.
- `docs/codex/`: handoffs, architecture, audits, playtest surfaces, Jon workflows, candidate handoffs, and repo-owned skills.
- `docs/design/`: accepted bounded design contracts such as P1.
- `docs/art/` and `docs/audio/`: candidate production ledgers and rights-safe cue grammar.
- `assets/concepts/`: concept sheets and visual decision artifacts.
- `assets/models/`: Blender/FBX/PBR candidate generations and verification outputs.
- `assets/candidates/`: isolated props, environments, cast, and event candidates with their own contracts.
- `assets/reference/`: supplied or audited references; not automatic production assets.
- `places/`: gitignored local Roblox place files. Preserve them; never treat them as the code collaboration layer.
- `.local/`: machine-local runtime state, logs, locks, and automation state. Do not share or commit it.
- `ops/`: bison/systemd automation definitions. They are not required for Jon's local gameplay loop.

Key design docs:

- `docs/GAME_CONCEPT.md`: fantasy, pillars, first slice, and later layers.
- `docs/CHARACTER_ART_DIRECTION.md`: owner/customer hierarchy and art gate.
- `docs/HUD_DIRECTION.md`: approved interface contract.
- `docs/ROBLOX_ASSET_PIPELINE.md` and `docs/ASSET_PIPELINE.md`: rights-safe Blender/Roblox asset route.
- `docs/COPY_WORKFLOW.md`: Google Doc editorial surface to `Copy.luau` promotion.
- `docs/MARKET_VILLAGE_PROTOTYPE.md`: removable future-village presentation lane.
- `docs/EPIC_WORKFLOW.md`, `docs/NINTENDO_GAMEPLAY_RESEARCH.md`, and `docs/KOJIMA_GAMEPLAY_METHOD.md`: action-first production logic.
- `docs/design/GATE_P1_ONE_RUBY_ONE_SPRINGY_BRANCH.md`: accepted P1 contract.
- `docs/codex/JON_VISUAL_REVIEW_WORKFLOW.md`: actual-image review packets and dedupe rules.
- `docs/codex/JON_INTAKE_AUTOMATION.md`: capture-only `[PIPILABU]` Gmail/Buzz lane; it does not execute requests.

The shared copy sheet is `Pipi Labu Copy Sheet`: <https://docs.google.com/document/d/1H_9lUV68CCpCfxnDsDSS0CY-aVSWAG3uB6a_YKz_hBE>. Jon already has writer access. It is editorial, never a live runtime dependency. Approved copy must be synchronized into `src/shared/Copy.luau` and verified in Studio.

## Jon's machine setup

### 1. Claim student benefits before unregistering

Use the personal ChatGPT account Jon intends to keep. The school email is for SheerID verification; it does not have to be the ChatGPT login email. Verify before enrollment ends.

Claim both separate current offers:

1. Four free monthly billing periods of ChatGPT Plus / ChatGPT Work: <https://chatgpt.com/students/2026/>. Eligible U.S. college students must claim by October 31, 2026. A valid payment method may be required. It renews at `$20/month` after the promotion unless canceled. App Store and Google Play billed subscriptions must be moved off store billing before they qualify.
2. `$100` in Codex credits: <https://chatgpt.com/codex/students/>. The offer is for verified university students in the U.S. or Canada who reside there at claim time. It adds 2,500 Codex credits to the personal workspace, works with Free/Go/Plus/Pro, and expires 12 months after grant.

Important: complete both flows while signed in to the correct long-term personal ChatGPT account. OpenAI says student verification/benefits cannot be transferred to another account after the wrong-account claim.

UConn clarification: OpenAI explicitly permits the personal ChatGPT login email to differ from the university email used for SheerID. Jon should therefore claim both offers from the personal account he will keep and use his UConn email only to prove current enrollment. That personal workspace is not the same thing as UConn's separately licensed, institution-managed ChatGPT Edu workspace, which may have university-set access tiers and usage controls. UConn still controls its own email accounts and course AI rules, and Jon must not upload FERPA, HIPAA, confidential, or embargoed university information. For this private Roblox project, the clean setup is personal ChatGPT plus UConn-only verification before he unregisters.

Official details:

- <https://help.openai.com/en/articles/20001493-chatgpt-back-to-school-offer-for-students>
- <https://help.openai.com/en/articles/20001147-codex-credits-for-students-terms-of-service>

### 2. Install local prerequisites

Minimum:

- Codex desktop app from OpenAI, signed in with the claimed personal ChatGPT account: <https://openai.com/codex>.
- Git and Git LFS.
- Roblox Studio, signed into `jwallyguy` or `Awchism` and able to edit the correct private experience.
- PowerShell 7 or Windows PowerShell on Windows.
- Rokit, then the repository-pinned toolchain from `rokit.toml`.
- Python 3 for the repository's Python verification and asset tooling.

Optional by lane:

- Blender 4.5.x for the current `.blend` generation/verification workflow.
- Gmail and Google Drive connectors in Codex for the handoff, copy sheet, and review packets.
- Image-generation tools for new visual candidates only when the exact art task calls for them.

Do not install XSplit or configure a voice bridge for Jon. The repository preserves an older Leo-only XSplit workflow, but it is not part of Jon's setup and its HyperX notes are stale relative to Leo's current QuadCast hardware.

### 3. Acquire the source

Wait for either:

- A verified private Git remote URL plus collaborator access for `jawnwalworth-tech`; or
- A verified source transfer bundle from Leo containing the current working tree.

If a private remote is used, install Git LFS before cloning or before checking out the binary-asset commit. Do not push Leo's current dirty tree through a blanket `git add .`; first classify generated/rejected assets, rights status, local state, and which binaries belong in LFS.

Choose a normal local path, for example:

- Windows: `C:\Users\<Jon>\Documents\Codex\pipilabu`.
- macOS: `/Users/<jon>/Documents/Codex/pipilabu`.

The repo-owned boot helper now resolves the clone it lives in instead of requiring Leo's username/path.

### 4. Install pinned Roblox tools

From the repository root:

```powershell
rokit install
rojo --version
lune --version
wally --version
rojo plugin install
```

Expected pinned versions at this handoff:

- Rokit `1.2.0` on Leo's current machine.
- Rojo `7.6.1`.
- Lune `0.10.4`.
- Wally `0.3.2`.
- `wally-package-types` `1.6.2`.

Rojo has two halves: the CLI server and the Roblox Studio plugin. Installing only one is incomplete. Official Rojo installation: <https://rojo.space/docs/v7/getting-started/installation/>.

### 5. Connect Codex to Roblox Studio MCP

Roblox Studio now includes its MCP server.

In Studio:

1. Open Assistant.
2. Open `…` / Assistant settings, then `Manage MCP Servers`.
3. Enable `Studio as MCP server`.
4. Use Quick Connect for Codex if shown, or keep the repo's `.mcp.json`.
5. Restart Codex after changing MCP configuration.

The portable Windows repo config is:

```json
{
  "mcpServers": {
    "Roblox_Studio": {
      "type": "stdio",
      "command": "cmd.exe",
      "args": ["/c", "%LOCALAPPDATA%\\Roblox\\mcp.bat"],
      "env": {}
    }
  }
}
```

On macOS, use Roblox's current native command instead:

```text
/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP
```

Official Roblox MCP guide: <https://create.roblox.com/docs/studio/mcp>.

After connection, Codex must list Studio instances, select the exact correct one, require Edit mode, and run this read-only identity assertion before any mutation:

```luau
assert(game.PlaceId == 133099029551440 and game.GameId == 10646495069, "wrong Pipilabu")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local root = ReplicatedStorage:FindFirstChild("JonAndLeoDevelopment")
local config = root and root:FindFirstChild("Config")
return {
    name = game.Name,
    placeId = game.PlaceId,
    gameId = game.GameId,
    configSource = config and config.Source or nil,
    hasShop = workspace:FindFirstChild("DogeAppleShop") ~= nil,
}
```

### 6. Start the project

On Windows, after tools and Studio MCP are ready:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts\boot-jon-leo-roblox.ps1
```

The helper:

- Resolves the current verified clone.
- Requires baseline ancestry.
- Checks the exact Rojo allowlist: local `0` plus private PlaceId `133099029551440` only.
- Refuses the blocked duplicate.
- Reuses or starts exactly one Rojo listener on `localhost:34872`.
- Reports Git changes and remotes without modifying them.
- Leaves voice disabled unless Leo separately invokes `-UseVoiceBridge` on his own machine.

Connect the Rojo Studio plugin to `localhost:34872`. Then confirm disk `DevelopmentVersion` matches the synced live Config source. The boot helper does not start Play or publish.

## Normal work loop

1. Pull and inspect status before starting once a remote exists.
2. Read the current queue and exact design contract.
3. Make one bounded, reversible change on disk.
4. Run focused deterministic tests, including at least one boundary/failure case.
5. Run `rojo build default.project.json --output <temporary-place>`.
6. Confirm one Rojo listener on port 34872.
7. Verify the exact Studio IDs and Edit DataModel.
8. Playtest the changed behavior and inspect Studio Output.
9. Update `docs/codex/HANDOFF.md` and, when human judgment is needed, `docs/codex/PLAYTEST_QUEUE.md`.
10. Commit code and its meaningful tests together. Use a `codex/` branch for Codex-authored work unless Jon and Leo choose another convention.

Live Leo/Jon time is gameplay-first. When a subjective gate is pending, it blocks only the dependent candidate. Independent tests, tools, code behind disabled flags, research, rights-safe art preparation, and documentation may continue.

## Verification commands

The exact test list evolves. Discover it from `scripts/test-*` and the current handoff rather than copying a stale hard-coded count. A representative Windows verification pass is:

```powershell
$tests = Get-ChildItem scripts -Filter 'test-*.luau' | Sort-Object Name
foreach ($test in $tests) { lune run $test.FullName; if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE } }
py -3 scripts/test-pipilabu-intake.py
py -3 scripts/test-jon-visual-manifest.py
py -3 scripts/test-pipilabu-visual-digest.py
rojo build default.project.json --output "$env:TEMP\pipilabu-verify.rbxlx"
git diff --check
```

Do not treat a successful build as proof of feel, art quality, private-cloud persistence, or publication.

## Boundaries Jon's Codex must keep

- Private experience only. Never make it public without explicit current-task authorization.
- Never mutate the blocked duplicate place.
- Never publish or upload assets merely because an import/build passed.
- Never use Studio/MCP edits as the durable path for Rojo-owned code.
- Never delete/reparent broad world trees without inspecting exact targets.
- Preserve local place files and unsaved-data prompts.
- Keep candidate art quarantined until technical and human gates pass.
- Do not spend Meshy credits or money without explicit direction.
- Do not weaken tests/validators or rewrite goldens to make a candidate pass.
- Do not expose credentials, Roblox cookies, OAuth tokens, or private automation state.
- Do not let a pending human gate pause unrelated safe production.

## Collaboration surfaces already built

- Jon receives visual-review email digests with actual images, content-hash deduplicated. His reply is design evidence, not publish/spend/delete authority.
- The `[PIPILABU]` inbound Gmail/Buzz path is capture-only. It authenticates and records requests on bison-1 but does not start Codex or modify the game.
- The shared Pipi Labu Copy Sheet is the low-friction editorial surface and already grants Jon writer access.
- The repo-owned `boot-jon-leo-roblox` skill lives at `docs/codex/skills/boot-jon-leo-roblox/`. After the clone exists, Jon's Codex may install that folder into its local Codex skills directory and use it for future sessions.
- Leo's old XSplit shared-voice bridge remains documented under `docs/codex/VOICE_WORKFLOW.md`, but it is not part of Jon's setup and is currently unverified for Leo's QuadCast.

## Definition of a completed Jon setup

Setup is complete only when Jon's Codex can report all of the following from live evidence:

- Correct personal ChatGPT account and claimed student benefits, or an exact verification blocker.
- Local repo path and a source handoff that includes current work, not HEAD-only history.
- Git branch, HEAD, working-tree status, LFS state, and private remote identity if one exists.
- Pinned tool versions.
- Roblox Studio signed into an authorized Jon account.
- Built-in Studio MCP enabled and visible to Codex.
- Exact correct Studio PlaceId/GameId selected in Edit mode.
- Exactly one Rojo server on port 34872.
- Disk and live Config development versions match.
- `Workspace.DogeAppleShop` exists.
- Current playtest queue is reported without inventing a passed human verdict.
- No publish, public release, asset spend/upload, or blocked-place mutation occurred during setup.
