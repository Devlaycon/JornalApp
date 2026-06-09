# Circleu Real Daily Journaling MVP Design

## Goal

Make Circleu feel like a real local-first iPhone journaling app that can be tested end to end on a physical device. The next version should make the core loop dependable before expanding backend, accounts, or cloud AI.

Core loop:

1. Onboard with a clear privacy promise and display name.
2. Start from a useful home screen.
3. Record or type a short reflection.
4. Generate an Apple Intelligence or local AI reflection.
5. Save it once.
6. Review, search, and delete it in Journal.
7. See progress update in Profile.

## Scope

In scope:

- Local-first user profile with display name.
- Local journal persistence using the existing JSON/UserDefaults storage pattern.
- Stronger connected navigation across Home, Recording, Reflection, Journal, and Profile.
- Better empty, error, permission, loading, and saved states.
- Real user metrics derived from saved entries: entry count, streak, XP, latest emotion, and active quest progress.
- Phone testing instructions and successful local build verification.

Out of scope for this slice:

- Backend, signup, login, cloud sync, shared accounts, analytics, and server-side AI.
- Production social/community features.
- Push notifications, unless added later as a separate reminder slice.
- Replacing Apple Intelligence/local AI abstraction with cloud models.

## Product Behavior

### Onboarding

Onboarding introduces Circleu as a private voice reflection companion. It should ask for a display name and save it locally. The final onboarding action enters the app and should not appear again unless local app data is reset.

### Home

Home greets the user by display name, shows a daily prompt, highlights the latest saved reflection when available, and keeps the main action focused on starting a reflection. It should feel like the place a user returns to each day, not a static landing page.

### Recording

Recording supports microphone speech recognition and typed fallback. The user cannot finish with an empty transcript. Permission failures, unavailable speech recognition, and Apple Intelligence fallback states should be visible and understandable. Finishing creates one pending reflection.

### Reflection

Reflection presents emotion, summary, insight, expression moment, quote, confidence, and suggested quest. Saving should be idempotent from the user's perspective: once saved, the save button should not create duplicate entries.

### Journal

Journal is the source of truth for saved reflections. Users can search entries, open detail, and delete entries. Empty and no-result states should guide the user back to recording.

### Profile

Profile reads real local data instead of hard-coded progress. It shows display name, entry count, current streak, XP/progress, privacy status, and active quest progress. Editing the profile should at least allow changing the local display name.

## Architecture

Keep the app local-first and SwiftUI-native.

- `UserProfileStore`: owns display name and lightweight local preferences.
- `ReflectionJournalStore`: remains the journal source of truth and continues to persist entries locally.
- `ReflectionAnalyzing`: remains the AI boundary so Apple Intelligence and later cloud models can be swapped without rewriting views.
- `RootView`: owns app-level navigation state and shared recording presentation.
- Feature views consume stores through environment objects instead of creating duplicate state.

This keeps the current direction intact while making the app more believable and easier to test.

## Data Flow

Onboarding saves `displayName` and sets `hasCompletedOnboarding`.

Home reads `UserProfileStore` and `ReflectionJournalStore`.

Recording creates a transcript from speech recognition or typed fallback, then asks `ReflectionAnalyzing` for a result.

Reflection saves a `JournalReflectionEntry` through `ReflectionJournalStore`.

Journal and Profile update automatically because they read the same store.

## Error Handling

The app should handle:

- Empty transcript: block finish and show a short prompt.
- Microphone denied: explain how to continue by typing.
- Speech recognition unavailable or denied: keep typed fallback available.
- Apple Intelligence unavailable: use local test engine and show the fallback message.
- AI failure: keep transcript available and let the user retry or type/edit before finishing.
- Duplicate save attempts: disable save after success.

## Testing

Verification for this slice:

- Build on iPhone simulator.
- Build on the connected physical iPhone.
- Manual phone flow:
  - fresh onboarding
  - set display name
  - start recording
  - allow or deny permissions
  - type fallback if needed
  - finish analysis
  - save reflection
  - inspect detail in Journal
  - search and delete entry
  - confirm Profile updates

## Success Criteria

Circleu feels real when tested on a phone if:

- The user can complete the full reflection loop without developer help.
- The app survives permission denial by offering typed fallback.
- Saved entries persist after app restart.
- Home, Journal, and Profile all reflect the same local data.
- There are no obvious dead buttons in the core flow.
- The app builds successfully for simulator and the user's connected iPhone.
