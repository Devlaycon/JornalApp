# Circleu App Flow

This product flow aligns Figma, Xcode, team discussion, and live testing without requiring numbered files or folders in the repo.

- **Onboarding**: Introduce Circleu and move the user into the app.
- **Home**: Invite the user to begin a voice check-in.
- **Recording**: Capture voice, show live transcript, and let the user finish.
- **AI Processing**: Analyze the transcript with Apple Intelligence when available, with local fallback.
- **Reflection**: Show emotion, insight, expression moment, quote, confidence score, regenerate, save, and **Save & Start Practice**.
- **Saved**: Confirm the reflection was saved and explain where it lives.
- **Journal**: List saved AI reflections, search edited workspace fields, open details, manage the related practice, and save useful insights into private circles.
- **Practice**: Show the active AI-suggested practice, complete or skip it, restart past practices, and open the source reflection.
- **Circles**: Store private support notes and privacy-safe reflection shares on this iPhone.
- **Profile**: Show journey progress based on saved reflections.

Primary beta path:

```text
Onboarding -> Home -> Record or Type -> AI Reflection -> Journal -> Practice -> Progress -> Circle/Profile
```

Implementation notes:
- Keep Swift file names semantic, such as `HomeView` and `RecordingView`.
- Keep AI behind `ReflectionAnalyzing` so Apple Intelligence can be replaced or joined by other providers later.
- Keep the daily practice loop local-first: `ReflectionJournalStore` owns saved reflections, `QuestStore` owns practice state, and `CircleStore` owns private support posts.
