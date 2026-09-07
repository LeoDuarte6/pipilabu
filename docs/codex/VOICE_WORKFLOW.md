# Shared voice workflow

## Verified routing

```text
Leo: HyperX microphone ------\
                              XSplit Audio (Broadcaster) ---> Codex voice/dictation
Jon: Discord/HyperX output --/

Leo: HyperX microphone -------------------------------> Discord ---> Jon
```

The separate Discord input is important. If Discord uses XSplit as its microphone, Jon can hear himself echoed back.

## Windows configuration

- XSplit system sound: `Default Speakers`, currently `Headphones (HyperX Cloud III)`.
- XSplit microphone: explicitly `Microphone (HyperX Cloud III)` and unmuted.
- Discord microphone: explicitly `Microphone (HyperX Cloud III)`.
- Discord speaker: explicitly `Headphones (HyperX Cloud III)`.
- Codex Settings > Voice > Microphone: `XSplit Audio (Broadcaster)`.

Run the repo-owned `boot-jon-leo-roblox` skill before a shared session. It invokes `scripts/start-voice-bridge.ps1` automatically, reusing XSplit when already open or launching it minimized when absent. Use the voice script directly only for a bounded voice-only recovery. XSplit may be minimized, but it must remain running.

## Codex modes

- A task started as a voice chat supports live back-and-forth voice.
- An existing text task uses dictation to turn speech into a prompt.
- Voice and dictation share the microphone selected in Codex Settings > Voice.

## Wispr

Wispr Notetaker is optional for meeting notes and transcripts. It is not part of the live bridge. Notetaker requires Wispr private cloud sync, so only enable it when Leo and Jon want a retained meeting record.

## Recovery checklist

If Codex hears only Leo, confirm the XSplit system-sound meter moves while Jon speaks. If Codex hears only Jon, confirm the XSplit microphone meter is unmuted. If Jon hears an echo, immediately set Discord's microphone back to the physical HyperX device.
