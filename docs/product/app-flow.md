# Circleu App Flow

This flow keeps Figma, Xcode, team discussion, and live testing aligned.

## Primary Path

```text
Onboarding -> Home -> Record or Type -> AI Reflection -> Journal -> Tips -> Progress -> Circle/Profile
```

## Screen Responsibilities

- **Onboarding**: collect a local display name and introduce the reflection loop.
- **Home**: show the daily prompt, latest reflection, active tip, and progress entry points.
- **Recording**: capture audio, show transcript readiness, support typed fallback, and validate transcript quality.
- **AI Processing**: run Apple Intelligence when available, with local reflection fallback.
- **Reflection**: present structured insight, regenerate, Save Entry, or Save & Open Tips.
- **Saved**: confirm the reflection was saved and route the user back into the app.
- **Journal**: list, search, edit, export, reopen, and share saved reflections.
- **Tips**: complete, skip, restart, and source-link AI-suggested actions.
- **Circles**: show supportive spaces, selected reflection shares, posts, replies, likes, and bookmarks.
- **Profile**: show progress, profile settings, Firebase status, local data summary, QA tools, and AI session history.

## Implementation Notes

- Keep Swift file names semantic, such as `HomeView`, `RecordingView`, and `JournalViewModel`.
- Keep AI behind `ReflectionAnalyzing` so Apple Intelligence, local fallback, and future providers can share one boundary.
- Keep the data loop explicit: `ReflectionJournalStore` owns saved reflections, `QuestStore` owns tips, `CircleStore` owns circle state, and `AIReflectionSessionStore` owns AI generation history.
- Backend work should enter through services and stores, not directly through SwiftUI views.
- Firebase private backup stays under `users/{uid}`. Shared circle data stays under public circle collections with rules and UI checks reviewed separately.
