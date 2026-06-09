# Recording And AI Reflection Reliability Refinement Design

## Goal

Make Circleu's main reflection loop reliable enough for real iPhone testing. A user should always understand what state the recording flow is in, how to recover from permission or AI failures, and what happens after saving.

This refinement focuses on the path:

Home -> Recording -> Transcript -> AI Analysis -> Reflection -> Save Confirmation -> Journal or Record Another

## Scope

In scope:

- Clear recording state behavior for ready, recording, paused, analyzing, failed, and finished moments.
- Permission-aware microphone and speech recognition UX.
- Typed fallback as a first-class recovery path.
- AI analysis retry without losing transcript text.
- Apple Intelligence unavailable fallback clarity.
- Save protection so one reflection cannot create duplicate journal entries.
- Build verification on simulator and iOS device target.

Out of scope:

- Backend, login, signup, cloud sync, push notifications, and shared accounts.
- Replacing the current `ReflectionAnalyzing` boundary.
- Major visual redesign of unrelated Home, Journal, Circle, or Profile screens.
- Cloud AI provider integration.

## Product Behavior

### Recording State

The recording screen should communicate the current state through title, subtitle, buttons, and transcript panel.

- Ready/recording: user can pause or finish after transcript text exists.
- Paused: user can resume or finish if transcript text exists.
- Analyzing: user cannot edit or start another analysis, and sees a focused loading state.
- Failed analysis: transcript remains visible and the user can retry analysis.
- Cancelled: recorder stops and the user returns to the previous screen.

### Permission And Fallback

If microphone permission or speech recognition is unavailable, the app should not feel broken. The transcript box remains editable and copy explains that typing is supported.

The user can finish using typed text even when live transcription never starts.

### Analysis

The app should analyze the effective transcript, choosing live transcript first and typed fallback second. Empty transcript submissions remain blocked.

If Apple Intelligence is unavailable, Circleu should show a calm fallback message and use the local test engine. If analysis fails, the app should show the error, keep the transcript, and allow retry.

### Reflection And Save

The reflection screen should accept exactly one save action per pending entry. After saving, the user sees confirmation and can:

- return to Home,
- view Journal,
- or record another reflection.

No path should create duplicate saved entries from the same reflection.

## Architecture

Keep the existing architecture:

- `RecordingView` owns the recording and analysis interaction state.
- `VoiceRecorder` owns microphone, speech recognition, transcript, elapsed time, and recorder status.
- `ReflectionAnalyzing` remains the AI abstraction.
- `ReflectionJournalStore` remains the only saved-entry writer.
- `ReflectionView` handles review and save action state.
- `SaveConfirmationView` handles post-save navigation choices.

The refinement should improve boundaries without introducing a new backend or large state-management framework.

## Data Flow

1. User starts recording from Home.
2. `VoiceRecorder` attempts microphone and speech recognition.
3. User speaks or types text.
4. `RecordingView` computes `effectiveTranscript`.
5. `RecordingView` sends transcript and duration to `ReflectionAnalyzing`.
6. The engine returns `AIReflectionResult` or fails.
7. Success creates one pending `JournalReflectionEntry`.
8. `ReflectionView` displays the entry.
9. Save writes the entry once through `ReflectionJournalStore`.
10. `SaveConfirmationView` routes the user to Journal, Home, or another recording.

## Error Handling

Handle these cases explicitly:

- Empty transcript: disable finish and show a short prompt.
- Microphone denied: stop trying to record and keep typed fallback available.
- Speech recognition denied/unavailable: keep typed fallback available.
- Pause/resume while not recording: buttons should be disabled or harmless.
- Analysis failure: keep transcript, show error, allow retry.
- Double save: disable save after the first successful save.
- Record another: reset pending entry, saved entry, error message, typed text, and recorder state.

## Testing

Automated verification:

- Build for iPhone 17 Pro simulator.
- Build for generic iOS device signing target.
- Build for connected iPhone when Xcode lists it as available.

Manual iPhone test:

1. Start recording from Home.
2. Deny or interrupt microphone/speech if possible and confirm typed fallback still works.
3. Type a short reflection and finish.
4. Confirm analysis loading appears.
5. Save the reflection once.
6. Tap save again if visible and confirm no duplicate entry is created.
7. View Journal and confirm one entry appears.
8. Record another reflection from confirmation and confirm old transcript/error state is cleared.

## Success Criteria

This pass succeeds when:

- The recording flow has no dead end on a real iPhone.
- The user can complete a reflection using only typed fallback.
- AI failure does not lose transcript text.
- Retry analysis is visible after failure.
- Saved reflections are not duplicated by repeated taps.
- Simulator and iOS device builds succeed.
