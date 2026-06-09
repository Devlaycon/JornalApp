# AI Recording Reliability v2 Design

## Goal

Make Circleu's core voice-to-reflection loop more trustworthy on a real phone by clarifying permission state, preventing weak transcript analysis, and letting the user regenerate a reflection before saving.

## Scope

This slice stays local-first. It does not add backend accounts, cloud AI providers, cloud sync, or production analytics. It improves the on-device recording and reflection workflow that already exists.

## Product Behavior

1. Recording shows microphone and speech recognition readiness in plain language.
2. If voice is unavailable, typed fallback remains available and clearly explained.
3. Very short transcripts cannot be analyzed yet; the user sees a friendly prompt with what to add.
4. Analysis failure keeps the transcript in place and offers retry.
5. Reflection review includes a regenerate action before saving.
6. Saving still happens only once, and Journal receives only the final accepted entry.

## Architecture

`VoiceRecorder` owns permission state because it talks to system APIs. A small `TranscriptQuality` helper owns the transcript readiness rules. `RecordingView` uses both to decide whether finishing is allowed and what message to show. `ReflectionView` owns regeneration UI and calls the same `ReflectionAnalyzing` engine used by recording so Apple Intelligence and local fallback remain interchangeable.

## Error Handling

Permission denials do not block the whole flow; the app switches to typed fallback. Short transcripts show actionable guidance instead of failing after analysis starts. Regeneration errors are shown in the reflection screen without discarding the current result.

## Testing

Run an iPhone 17 Pro simulator build after code changes. Run a connected iPhone build because the workflow touches microphone and speech permission surfaces. Update the phone checklist with manual tests for permission denial, short transcript guidance, retry, and regenerate.
