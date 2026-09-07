# Jon onboarding

The full machine and Codex handoff is `docs/codex/JON_CODEX_BOOTSTRAP_BRIEF.md`. This short file remains the identity/access summary.

## Identity and access

- Name: Jon Walworth
- GitHub: `jawnwalworth-tech`
- Roblox: `jwallyguy` and `Awchism`
- Both Roblox accounts have Edit access to the private shared experience.

## Correct Roblox project

- Experience: `Pipilabu`
- PlaceId: `133099029551440`
- GameId / UniverseId: `10646495069`

Never develop against the older duplicate `Pipilabu` (`PlaceId 104936800417970`). Verify PlaceId before any Studio MCP mutation.

## Current collaboration state

The complete current repository is private at <https://github.com/LeoDuarte6/pipilabu>. Jon has been invited as `jawnwalworth-tech` with write access. The source includes the current `v0.9.9-dev` work and uses Git LFS for large binary art/model/audio files.

Jon's independent lane is:

1. Accept the GitHub invitation, install Git LFS, clone the repository, and install the pinned Rokit tools.
2. Open the shared cloud `Pipilabu` and confirm its PlaceId.
3. Start the repository's Rojo server and connect Studio to it.
4. Enable Studio as an MCP server for his own Codex task.
5. Pull before work, commit one bounded mechanic or presentation pass at a time, and push only after a clean Rojo build and playtest.

Only one Rojo server should own a given Studio session. Git is the collaboration boundary between Leo's and Jon's computers; Rojo is not a multi-computer sync service.
