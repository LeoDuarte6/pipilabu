# Pipi Labu Copy Workflow

The current collaborative copy sheet is [Pipi Labu Copy Sheet](https://docs.google.com/document/d/1H_9lUV68CCpCfxnDsDSS0CY-aVSWAG3uB6a_YKz_hBE). Jon has writer access through `jawn.walworth@gmail.com`.

The older `Pipilabu — Game Copy (Jon + Leo)` document is superseded editorial history. Do not sync from it.

## Source of truth

- The Google Doc is the easy editorial surface for Leo and Jon.
- `src/shared/Copy.luau` is the reviewed runtime source of truth.
- The live game never reads Google Docs, so a document outage or accidental edit cannot break a server.
- The Doc contains a native five-column table: stable key, surface/speaker, current copy, status, and notes. Leave stable keys unchanged.

## Sync rule

When Leo or Jon asks Codex to sync copy:

1. Read the Google Doc and compare every stable key with `src/shared/Copy.luau`.
2. Flag missing, duplicated, or renamed keys instead of guessing.
3. Apply approved wording to `Copy.luau`.
4. Run a Rojo build and a focused UI/prompt playtest.
5. Record the verified copy revision in `docs/codex/HANDOFF.md`.

Drafting notes in the document do not ship until Leo and Jon promote them into stable keys.
