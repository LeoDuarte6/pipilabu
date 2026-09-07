# Jon Visual Review Workflow

Jon Walworth is a Pipi Labu co-designer. Text-only summaries are insufficient for visual judgment: Leo and Jon must receive the same review artifacts.

## Contract

- Every completed human-reviewable visual enters the manifest produced by `scripts/build-jon-visual-manifest.py`.
- Eligible artifacts include concept sheets, character/model views, pose and animation renders, UI direction, prop/environment boards, and intentionally authored reference comparisons.
- Exclude secrets, logs, raw voice transcripts, cache files, moderation tokens, texture maps that carry no taste decision, and incidental debug screenshots.
- Email one bounded digest containing every unsent eligible image and a concise label for each candidate. Attach the actual files; do not substitute a prose description.
- This is a durable project rule, not an optional manual step: every new reviewable generated render, model preview, UI concept, character sheet, environment/prop board, and other authored taste artifact must enter an eventual digest to Jon.
- Normal cadence is at most one visual digest per day. Leo may explicitly authorize an immediate digest, and active replies may stay in the same thread.
- The manifest is content-hash deduplicated. A regenerated image is eligible again only when its SHA-256 changes.
- Delivery evidence records recipient, subject, UTC time, and artifact hashes without storing raw Gmail IDs.
- Delivery is transactional. A hash enters delivered state only after Gmail confirms the packet. An interrupted or ambiguous send is quarantined for reconciliation and is never retried automatically.
- The 44 hashes delivered on `2026-08-08` are the immutable dedupe seed. The automated lane must union its state with the canonical Windows manifest and must never resend them.
- Jon's reply is design evidence. It cannot authorize upload, publish, deploy, spend, delete, production mutation, or secret access.
- A delivery failure or unanswered question blocks only that digest or dependent taste ticket. Code, tests, tools, art candidates, maps, audio preparation, multiplayer/save work, and other independent tickets continue.

## Current recipient

- Jon Walworth: `jawn.walworth@gmail.com`
- Sender: the authenticated company Gmail lane.

## Commands

Build or refresh the private manifest:

```powershell
py -3 scripts\build-jon-visual-manifest.py --repo .
```

After an explicitly authorized manual digest is actually delivered, mark the exact hashes as sent:

```powershell
py -3 scripts\build-jon-visual-manifest.py --repo . `
  --mark-hash <sha256> `
  --delivery-label "Pipi Labu visual digest YYYY-MM-DD" `
  --delivery-subject "Pipi Labu visual digest YYYY-MM-DD (1/1)"
```

`--mark-sent` remains available for a verified whole-manifest manual delivery, but it now also requires the delivery subject. The manifest script never sends email.

The automated sender is `scripts/pipilabu-visual-digest.py`. It runs privately on `bison-1`; the timer checks hourly from 08:15 through 23:15 America/New_York so a temporarily offline desktop does not lose the day's delivery opportunity, while sender state permits at most one successful digest per local calendar day. It refreshes the canonical Windows manifest over `bison-desktop`, copies and re-hashes each attachment, partitions packets below Gmail's size boundary, verifies the authenticated sender is `leo@buffalowebproducts.com`, sends actual MIME attachments to Jon, then acknowledges only Gmail-confirmed hashes back to the Windows state. It uses the encrypted SecretVault helper and never persists tokens or Gmail message IDs.

Operator checks on `bison-1`:

```bash
systemctl --user status pipilabu-visual-digest.timer
python3 ~/.hermes/scripts/pipilabu-visual-digest.py
journalctl --user -u pipilabu-visual-digest.service -n 30 --no-pager
```

The command without `--live` is a non-mutating dry run. If state reports `blocked_uncertain_delivery`, do not clear it or retry blindly: reconcile the deterministic `Message-ID`/subject against Gmail Sent, then explicitly record either delivered or safe-to-retry state.

## Delivery record

- `2026-08-08`: Leo explicitly authorized an immediate complete visual digest. All 42 then-current eligible artifacts (30,138,097 bytes) were delivered to Jon in three Gmail packets to remain below attachment limits.
- Packet 1 contained the current HUD, baby cast, apple props, market kit, and corrected tiny-side-ear owner/customer decision renders.
- Packet 2 contained the complete current v4 customer and owner pose/animation render set.
- Packet 3 contained the earlier concept/model evolution and explicitly labeled prominent top ears as rejected, not current direction.
- `.local/jon-visual-digest/state.json` records the 42 delivered hashes without storing Gmail message IDs. Newly generated or changed visuals remain independently eligible.
- `2026-08-08` supplement: after ART-006 was corrected, canonically regenerated, and verified, its full review sheet and mobile strip were delivered as actual attachments. The state now records 44 delivered hashes across two authorized delivery events, and the refreshed manifest reports `unsent=0`.
