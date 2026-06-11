# TestFlight Description

Use this page as the source text for App Store Connect beta information.

## App Description

Reflect in your own voice, turn check-ins into insight, and build one small next step at a time.

Circleu is a playful reflection and journaling app for short voice or typed check-ins. Record what is on your mind, review supportive AI reflection feedback, save a private journal entry, practice communication tips, and share selected insights with supportive circles.

## Why Circleu?

- **Reflect quickly**: speak or type a short check-in when something is on your mind.
- **Understand the moment**: review emotion, insight, expression moment, quote, and a suggested next step.
- **Keep a private journal**: save reflections, edit titles, add notes, and revisit your progress.
- **Practice communication**: use tips to rehearse clearer, kinder messages.
- **Share gently**: post selected summaries into circles without sharing raw recordings.
- **Stay in sync**: use Firebase-backed sign-in and Firestore backup during beta testing.

## Screenshot Captions

Use these captions with the App Store-style screenshots in `docs/product/snapshots/app-store/`.

1. reflect in your own voice
2. turn check-ins into insight
3. save your private journal
4. practice one small next step
5. share support with circles

## Contact Information

First Name: Tuan

Last Name: Nguyen

Phone Number (+61 Format): +61 [add your phone number]

Email Address: tuannm3812@gmail.com

## Test Account

Use this account if testers should not create their own account.

```text
Test Email: test.circleu@gmail.com
Test Password: CircleuTest123!
```

## What To Test

1. Install Circleu from TestFlight and open the app.
2. Sign in with the test account, or create a new account with email and password.
3. Complete onboarding and confirm the home screen opens.
4. Tap the reflection entry point.
5. Record a short voice reflection, or use the typed fallback if speech recognition is unavailable.
6. Generate AI reflection feedback.
7. Review the emotion, insight, expression moment, quote, and suggested tip.
8. Save the reflection entry.
9. Open Journal and confirm the saved entry appears.
10. Open the saved entry and edit title, emotion, notes, or tags.
11. Open Tips and test completing, skipping, or restarting a suggested action.
12. Open Circle and test viewing circles, sharing a selected reflection insight, liking, bookmarking, or replying where available.
13. Open Profile and check progress, Firebase status, and QA tools.
14. Close and reopen the app to confirm saved data is still available.

## Beta Notes For Testers

- This is a student beta for the Apple Foundation Program.
- Firebase Authentication and Firestore are used for account sign-in and data backup/sync.
- Reflections may include personal text, so testers should avoid entering highly sensitive real-world information.
- Apple Intelligence may be used when available on the device. Unsupported devices use the local reflection fallback.
- Some circle and AI behaviors are still being refined during TestFlight.

## Suggested External Testing Focus

- Account creation and sign-in reliability.
- Voice recording and speech recognition permission flow.
- AI reflection quality, especially for short, repeated, or rough-language transcripts.
- Journal save/edit behavior.
- Firebase sync behavior after closing and reopening the app.
- Circle sharing and interaction behavior.
- Any crashes, freezes, confusing text, or screens that feel unfinished.
