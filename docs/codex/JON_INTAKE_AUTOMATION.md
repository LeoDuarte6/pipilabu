# Jon-to-Pipilabu Intake

Status: capture-only Gmail/Buzz polling is active on bison-1; Codex execution remains intentionally unarmed.

The repo-owned capture boundary is `scripts/pipilabu-intake.py`. It accepts one authenticated Gmail or Buzz envelope, enforces the fixed Pipi Labu route and allowlists, deduplicates by transport ID and normalized SHA-256 fingerprint, and writes private `0600` metadata/body artifacts below `.local/intake/`. The bison adapter is `scripts/pipilabu-inbox-poll.py`; its systemd templates live under `ops/systemd/`. Neither component replies, starts an agent, modifies the game, or lets message content select a workspace. Run the deterministic core contract with:

```powershell
py -3 scripts/test-pipilabu-intake.py
```

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

Current verified integration state on 2026-08-07:

- The Codex Gmail connector is authenticated as `leo@buffalowebproducts.com`; no matching Pipi Labu message from Jon was present during the audit.
- Hermes has Google OAuth secret references in the encrypted vault, but its standalone Google Workspace client has no materialized `~/.hermes/google_token.json`. The Pipi adapter avoids copying secrets into config: it resolves the three exact OAuth fields through the allowlisted `chief-secret-get` helper, exchanges the refresh token in memory, and logs no credential values.
- The live T&B Buzz inbox and Codex dispatcher poll every two minutes and have durable v2 state, SHA-256 dedupe, serialization, retries, and a watchdog. They authorize Leo and Pierce, target the T&B checkout, execute with broad access, and post automatic Buzz replies. They are evidence, not a safe Pipi Labu transport.
- A separate `pipilabu-inbox-capture.timer` is enabled and active on bison-1 every two minutes. Its first live Gmail + Buzz run exited successfully with a healthy, empty ledger. State is private under `/home/leo/.hermes/pipilabu-intake`; the service does not acknowledge either source, reply, or dispatch an agent.
- Safe Buzz syntax is an exact leading `[PIPILABU]` with no `@Codex` mention. The project prefix itself is the explicit Pipi route. `@Codex` belongs to the existing T&B dispatcher and could execute against the wrong checkout, so the Pipi core records that form as `shared_dispatch_conflict` instead of accepting it.
- The capture core currently enrolls Jon's exact email and Leo's verified Buzz public identity. Jon's Buzz public key is unknown; it must be verified from his live Buzz profile before enrollment. Unknown Buzz identities are quarantined.
- Captured requests are not execution tickets. A separate reviewed dispatcher must promote a capture into a persistent Pipi Labu task while preserving AFK/live mode, dirty-tree serialization, Studio identity checks, and production boundaries.

## Rollout gates

1. Capture-only audit ledger. **Live and verified on bison-1.**
2. Persistent task creation without execution.
3. Isolated safe code execution with network disabled by default.
4. Local integration only after repeated clean runs and a clean canonical baseline.

Until these gates pass, the shared Google copy document remains Jon's active low-friction editorial lane.

## Outbound visual-review lane

Jon must receive the actual completed review images so he and Leo work in the same visual plane. `docs/codex/JON_VISUAL_REVIEW_WORKFLOW.md` defines a separate content-hash manifest and bounded daily digest. This outbound lane does not weaken inbound authentication and does not grant Jon publish, upload, deploy, spend, delete, or secret authority.
