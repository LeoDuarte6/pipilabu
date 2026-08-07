# Jon-to-Pipilabu Intake

Status: design verified; automation intentionally not armed while the canonical Windows checkout is dirty.

## Intended operator flow

Jon may send a plain-text email from `jawn.walworth@gmail.com` with the subject prefix `[PIPILABU]`. The intake creates or updates one persistent Codex task rooted at:

`C:\Users\fricc\Documents\Codex\2026-08-07\pipilabu`

The task may prepare local code, docs, tests, research, and reversible configuration. It must place subjective Studio checks in `docs/codex/PLAYTEST_QUEUE.md`.

## Fail-closed routing

- Require exact sender and recipient allowlists plus SPF, DKIM, and DMARC alignment from raw Gmail headers.
- Deduplicate with Gmail message ID and a SHA-256 fingerprint of sender, project, and normalized request.
- Quarantine attachments, forwarded instructions, HTML-only bodies, credential-like content, oversized messages, and unknown projects.
- Route only to the fixed canonical path; email content never chooses a working directory.
- Use a minimal positive environment allowlist and private `0600` artifacts under a `0700` state directory.
- Never reply by email, upload an asset, publish Roblox, add a Git remote, push, or perform destructive work without a separate authorized lane.
- Refuse automated edits while the checkout is dirty, another Pipilabu task is active, or the expected HEAD/place doctrine changes during dispatch.

## Architecture decision

Bison-1 should own deterministic Gmail polling and durable intake state. Execution must run through a Windows Codex app-server worker because the canonical repo exists only on this desktop. The existing Tech & Business Buzz dispatcher is useful evidence for durable state transitions, deduplication, serialization, bounded retries, and task creation, but must not be copied with its T&B paths, external reply behavior, broad environment inheritance, or `danger-full-access` execution policy.

## Rollout gates

1. Capture-only audit ledger.
2. Persistent task creation without execution.
3. Isolated safe code execution with network disabled by default.
4. Local integration only after repeated clean runs and a clean canonical baseline.

Until these gates pass, the shared Google copy document remains Jon's active low-friction editorial lane.
