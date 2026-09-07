---
name: start-pipi-labu-design-room
description: Open or resume Leo Duarte and Jon Walworth's separate voice-first Pipi Labu design/specification task while another task owns implementation. Use when Leo asks for a new Pipi Labu stream, design room, Buda room, back-and-forth speccing session, map-painting discussion, or a place to capture gameplay ideas without interrupting active Roblox development.
---

# Start the Pipi Labu Design Room

Keep creative conversation and canonical implementation coordinated without allowing two tasks to edit gameplay simultaneously.

## Fixed boundaries

- Use the saved local project at `C:\Users\fricc\Documents\Codex\2026-08-07\pipilabu`.
- Spell the public-facing name exactly `Pipi Labu`.
- Let the main active Pipi Labu task own `src/`, Roblox Studio, Rojo, assets, cloud state, and playtest execution.
- Let the design room ask questions, synthesize voice dictation, compare options, and write accepted specifications only.
- Filter ambient chatter. Preserve concrete ideas and disagreements from Leo and Jon.
- Do not publish, upload, start or stop Play, or begin an art integration from the design room.

## Start or resume

1. List Codex tasks and reuse the pinned task titled `Pipi Labu Design Room` when it exists. Do not create a duplicate.
2. If Leo explicitly asked for a new task and none exists, list saved projects and create a task in the `pipilabu` project using the local environment so it sees the current checkout. Pin it.
3. In the design room, read `AGENTS.md`, `docs/codex/HANDOFF.md`, `docs/IDEA_LEDGER.md`, `docs/codex/PLAYTEST_GATES.md`, `docs/codex/PLAYTEST_QUEUE.md`, `docs/EPIC_WORKFLOW.md`, and `docs/CHARACTER_ART_DIRECTION.md`.
4. Read the latest compact status of the active implementation task. Treat repo handoff and verified runtime evidence as truth; do not infer completed work from conversation alone.
5. Navigate to the design-room task only when Leo asks to open or show it. Otherwise leave the implementation task visible and return the task link/directive.

## Conversation loop

1. Identify the current player action and named gate.
2. Extract decisions, open questions, and deferred ideas from voice dictation.
3. Ask at most one high-leverage question at a time. Prefer concrete A/B differences over broad brainstorming.
4. Separate `NOW`, `NEXT TEST`, and `LATER` so creative scope remains preserved without entering the current build accidentally.
5. Turn an accepted idea into a bounded spec: player verb, trigger, feedback, failure state, dependencies, non-goals, and playtest acceptance criteria.
6. Update only `docs/IDEA_LEDGER.md` and a focused file under `docs/design/` after Leo or Jon accepts the spec.
7. Send the implementation task one exact batch request. Never edit gameplay from the design room.

## Map timing rule

Develop the map when space changes a proven verb: travel time, visibility, queue reading, choice, risk, social helping, or surprise. Decorative map work belongs in the isolated art lane. A new location must answer what the player does there, what existing action it reuses, and what the next uncoached playtest measures.
