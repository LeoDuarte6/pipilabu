# Pipi Labu Autonomous Work Ledger

This is the cross-discipline queue for isolated Luna work. It exists so a pending human gameplay, visual, moderation, or taste gate can never be misread as a project-wide stop.

## Dispatch contract

- `Live` and `AFK` both permit isolated candidate work. Only explicit `Paused` stops dispatch.
- A gate blocks only the ticket that names it as a dependency and only its verdict, promotion, or default enablement.
- Skip blocked tickets and claim the highest-priority eligible independent ticket.
- Code that edits existing paths gets a fresh worktree. Additive candidate-only art, maps, research, or docs may reuse an idle isolated worker if paths do not overlap.
- Workers never mutate Studio, upload Roblox assets, publish, deploy, send mail/Buzz, or claim human approval.
- Gameplay candidates remain disabled by default until their exact private-place gate passes.
- Every ticket ends with deterministic tests, a concise handoff, and an explicit list of paths touched.

## Active and ready tickets

### ART-003 — Apple and serving-prop kit

Status: `COMPLETED` as a canonical local review candidate. The deterministic generator/verifier passes; human approval and Studio import remain false.

Deliver a local-only Ruby/Honeygold apple, crate, tray, and customer-held prop family with scale/pivot/collision/material contracts. The serve/contact/receipt beat remains the sensory peak. No gameplay or Studio integration.

### CODE-002 — Multiplayer shop-assignment contract

Status: `IMPLEMENTED_DISABLED`; independent of every current human gate. The pure allocation/release registry and a server-session adapter exist behind `Enabled=false`; no shop spawning, DataStore, teleport, or live multiplayer behavior is enabled.

Design and test a server-authoritative assignment layer for one shop bay per player, stable ownership for a server session, clean release on leave, and deterministic respawn/rejoin behavior. Produce pure contracts and disabled integration seams only. Do not enable DataStore, teleport, monetization, or live multiplayer mutation.

Acceptance: deterministic allocation tests cover two, four, full-capacity, leave/rejoin, and duplicate-request cases; Rojo build passes; default solo behavior is unchanged.

### CODE-003 — Save-schema and migration contract

Status: `IMPLEMENTED_DISABLED`; independent of every current human gate. Versioned normalization plus a fail-closed server persistence adapter exist; the adapter is behind `Enabled=false`, so default gameplay performs no DataStore read or write.

Create a versioned pure-data profile schema for coins, shop upgrades, discovered apple types, and tutorial state. Include validation, migration, corruption fallback, and server-only ownership contracts. Do not call DataStore in the default build and do not invent economy numbers beyond explicit placeholders.

Acceptance: pure tests cover new profile, valid load, old-version migration, malformed data, unknown fields, and idempotence; no network or Studio dependency.

### CODE-004 — Playtest instrumentation expansion

Status: `IMPLEMENTED_STUDIO_ONLY`; independent of the qualitative verdict it records. Schema v3 observes timing and continuity without changing gameplay.

Extend disabled/Studio-only evidence seams for serve approach time, apple-in-hand visibility duration, handoff completion, immediate-next-pickup continuity, wrong-apple recovery, and shift replay choice. Instrumentation observes; it never coaches, moves the player, changes scoring, or marks a human verdict true.

Acceptance: deterministic recorder contract, schema versioning, bounded event retention, and unchanged gameplay authority.

### CODE-005 — Physical interaction kernel candidate

Status: `IMPLEMENTED_DISABLED`; independent of P1 promotion. Pure server-authority contract exists; no production verb uses it.

Extract reusable server-authoritative contracts from the disabled springy branch and Physics Lab: bounded grab ownership, reach revalidation, release/recovery, motion sampling, and one-object-at-a-time interaction. Keep the candidate disabled and separate from the default service loop.

Acceptance: adversarial tests cover out-of-reach, duplicate grab, disconnect, timeout, regrab, and serve-once truth; Rojo build passes.

### AUDIO-001 — Rights-safe reaction and handoff cue specification

Status: `SPEC_COMPLETE`; independent of voice approval. Cue hierarchy, rights metadata, shuffle grammar, concurrency, fallback, and audition gate are recorded in `docs/audio/HANDOFF_CUE_GRAMMAR.md`.

Prepare an original cue grammar and implementation contract for pickup, carry, contact, receipt, happy hold, miss, and shift completion. Use no extracted copyrighted voice as production audio. Keep pickup restrained and make successful handoff the loudest/most rewarding beat.

Acceptance: cue table, shuffle-bag policy, loudness hierarchy, concurrency limits, mobile speaker check, and explicit human audition gate.

### ART-006 — Pear-cat harvest-event study

Status: `COMPLETED` as a verified canonical local review candidate; independent of current dog-cast and gameplay gates. Human approval and Studio import remain false.

Integrated `assets/candidates/pipilabu_pear_cat_harvest_event_v1/` as an original warm golden spherical orchard cat-loaf with tiny side-folded ears, a distinctly feline face, heavy squash, and tree/hand/basket context. The initial literal green-pear render was rejected and never promoted. Keep this candidate distinct from Pipi Labu and explore it only as a rare orchard customer or sourcing surprise.

Acceptance: reproducible local concept artifact, rights-safe re-authoring notes, mechanic role, silhouette check, and no Studio/gameplay integration.

## Completed foundations

- `DOC-001`: full August 8 voice-session pass reconciled into `docs/codex/NIGHTLY_CONVERSATION_RECONCILIATION_2026-08-08.md`; ambient chatter excluded and every actionable decision routed by status.
- `SYS-001`: ticket-scoped gate policy enforced in repo doctrine, Hermes runner, machine ledger, and active dispatcher.
- `CODE-001`: P1 springy branch implemented disabled/Studio-only with server authority and deterministic tests.
- `CODE-002`: pure multiplayer shop-assignment registry plus a disabled server-session adapter implemented with allocation, capacity, respawn, late-join, release/rejoin, attribute cleanup, ordering, idempotent start, and immutability tests. No persistence, teleport, or shop spawning is enabled.
- `CODE-003`: pure v1 profile schema plus an off-by-default persistence service implemented with conservative defaults, v0 migration, unknown-field stripping, corruption recovery, future-version rejection, departed-player load-race protection, validated `UpdateAsync` saves, leave/close flushing, and explicit load states. The exact private build reports the service disabled and makes no DataStore call.
- `CODE-004`: Studio-only recorder schema v3 observes customer-ready timing, apple-visible duration, handoff start/completion, immediate-next-pickup continuity, and voluntary replay with a 128-event bound. It cannot record the qualitative verdict as true.
- `CODE-005`: disabled pure interaction kernel covers one-object ownership, continuous reach, leases/expiry, release/regrab, disconnect cleanup, consume-once truth, and immutable snapshots.
- `AUDIO-001`: rights-safe cue grammar completed with contact-first mix hierarchy, deterministic role bags, concurrency caps, mobile fallback, and a bounded Leo/Jon audition gate.
- `ART-002`: baby customer cast review candidate generated and verified; human approval and Studio integration remain false.
- `ART-004`: modular market environment candidate generated and verified; no Studio import.
- `ART-003`: Ruby/Honeygold apple, crate, tray, marker, collision-proxy, and contact/receipt presentation kit integrated under `assets/candidates/pipilabu_apple_serving_props_v1/`; deterministic verification passes and no runtime behavior changed.

## Exhaustion rule

The queue is exhausted only when every remaining ticket is completed, actively leased, explicitly rejected, or depends on unavailable evidence. One human gate is never sufficient evidence of exhaustion.
