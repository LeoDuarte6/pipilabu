# Epic-derived production workflow

This is a small-team adaptation for Pipilabu, not a claim that Epic exposes its complete internal Fortnite organization.

## Transferable practices

- Prove one small action, then scale it into a system. Pipilabu's atomic action is `take apple -> understand request -> hand over -> enjoy reaction`. Epic describes Fortnite as growing successful small ideas while keeping balance data externalized and protecting quality with automated tests. [Building Fortnite with Unreal Engine](https://www.unrealengine.com/blog/building-fortnite-with-unreal-engine-4?lang=en-US)
- Optimize edit-to-play time. Keep one canonical Studio session, Rojo hot sync, fast round restarts, and named checkpoints; rebuild or reopen only when necessary. This is the Roblox equivalent of Epic's incremental Live Edit workflow. [Live Edit and Iteration Improvements](https://dev.epicgames.com/documentation/fortnite/live-edit-and-iteration-improvements-in-fortnite)
- Observe a first run without coaching. The game must communicate for itself; different testers expose different assumptions. [The Vital Importance of Playtesting](https://dev.epicgames.com/documentation/en-us/fortnite/how-to-design-a-game-in-fortnite-creative)
- Promote work through `candidate -> technically validated -> gameplay gate -> approved`. Never let an art experiment silently replace the last good playable build. [Fortnite Collaboration Workflow](https://www.unrealengine.com/blog/workflow-on-fortnite-collaboration-on-large-teams-with-unrealgamesync?lang=en-US)
- Build reusable presentation families: shared eye, fur, reaction, handoff, sound, material, prop, and animation systems. Epic's Fortnite FX workflow uses reusable parent modules rather than isolated one-off effects. [Niagara in Fortnite](https://www.unrealengine.com/tech-blog/how-epic-is-integrating-niagara-into-fortnite?lang=de)
- Judge art by whether it improves intuition, navigation, novelty, replay, and fun—not decoration alone. [Epic's Picks criteria](https://dev.epicgames.com/documentation/fortnite/epics-picks-in-fortnite?lang=en-US)
- Instrument behavior. Start with shift start, first pickup, serve attempt, serve success, timeout, customer exit, shift complete, and voluntary replay. Measure time-to-first-serve, serves per minute, timeout rate, completion, replay, bounce, and later D1/D7 retention. [Project Analytics](https://dev.epicgames.com/documentation/fortnite/project-analytics-for-fortnite-games?lang=en-US)
- Monetization comes downstream of fun. Find moments where players naturally want more, make value transparent, and do not pressure minors. [In-island transaction loop audit](https://dev.epicgames.com/documentation/fortnite/your-in-island-transactions-in-fortnite)

## Leo + Jon live session

Live collaboration is gameplay-only. Run 35-45 minute feature-cell loops:

1. Choose one gameplay hypothesis.
2. Play the untouched baseline without coaching.
3. Record one obstruction, one delightful moment, and one measurable result.
4. Codex implements the smallest complete change.
5. Run deterministic tests/build checks.
6. Both players replay immediately.
7. Promote only if the interaction is clearer or more enjoyable.
8. End every visual or animation integration at a named gameplay check-in.

Story writing, broad lore, unconstrained concepting, and long visual production do not consume Jon-and-Leo live gameplay time.

## Hermes + Luna away session

When Leo and Jon are absent, Hermes may choose one bounded art ticket and ask Luna Max to:

1. Produce two or three concepts.
2. Develop one technical candidate.
3. Validate scale, rig, materials, textures, deformation, attachments, and performance.
4. Produce both a polished render and an in-engine screenshot.
5. Integrate only behind a candidate flag/path.
6. Leave a concise comparison and an explicit gameplay-gate question.

The worker may not self-approve the candidate, publish Roblox state, or begin a second visual integration before the first reaches a recorded or explicitly deferred gameplay gate. One integration candidate per night is the default ceiling; additional output should be concept-only.

Good away-session tickets include character sheets, customer variants, prop families, modular shop kits, market/street studies, lighting palettes, reaction animation families, and cleared sound-family studies.

## Character-sheet contract

The gray-board Peepilabu sheet should include a hero render, front/profile/rear views, eye and muzzle close-ups, expression states, gameplay poses, material callouts, rig/attachment callouts, scale comparisons, one Roblox in-engine capture, and a visible state label: `Concept`, `Candidate`, or `Gameplay Approved`.

Current concept asset: `assets/concepts/peepilabu_character_sheet_v1.png`. It is a visual-development reference, not a replacement for the verified Blender/Roblox rig.
