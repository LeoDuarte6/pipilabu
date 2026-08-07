# Pipilabu Copy Workflow

The collaborative copy sheet is [Pipilabu — Game Copy (Jon + Leo)](https://docs.google.com/document/d/121Qblrx2BvCuFEC8J5ETVGLz2t_S0W5z2rFVrO19KYs). Jon has writer access through `jawn.walworth@gmail.com`.

## Source of truth

- The Google Doc is the easy editorial surface for Leo and Jon.
- `src/shared/Copy.luau` is the reviewed runtime source of truth.
- The live game never reads Google Docs, so a document outage or accidental edit cannot break a server.
- Stable keys in the Doc map one-to-one to `Copy.luau`. Edit wording after the arrow and leave the key unchanged.

## Sync rule

When Leo or Jon asks Codex to sync copy:

1. Read the Google Doc and compare every stable key with `src/shared/Copy.luau`.
2. Flag missing, duplicated, or renamed keys instead of guessing.
3. Apply approved wording to `Copy.luau`.
4. Run a Rojo build and a focused UI/prompt playtest.
5. Record the verified copy revision in `docs/codex/HANDOFF.md`.

Drafting notes in the document do not ship until Leo and Jon promote them into stable keys.
