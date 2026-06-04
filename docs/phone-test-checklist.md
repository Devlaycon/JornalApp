# Circleu Phone Test Checklist

Use this checklist to run Circleu on a real iPhone from Xcode.

## 1. Open The Right Project

Open:

`/Users/tuanm.nguyen/Documents/JornalApp-personal/Circleu.xcodeproj`

Use branch:

`dev/mike`

## 2. Add Apple Account In Xcode

1. Open Xcode.
2. Go to **Xcode > Settings > Accounts**.
3. Add your Apple ID.
4. Make sure Xcode shows an Apple Development signing identity.

## 3. Select Signing Team

1. Select the `Circleu` project in the left sidebar.
2. Select the `Circleu` target.
3. Open **Signing & Capabilities**.
4. Enable **Automatically manage signing**.
5. Choose your personal/team development team.
6. If the bundle ID is already taken, change it to something unique, such as:

`com.tuannguyen.Circleu`

## 4. Connect iPhone

1. Connect your iPhone by cable.
2. Unlock the phone.
3. Tap **Trust This Computer** if prompted.
4. In Xcode's device picker, choose your iPhone.

## 5. Run The Real User Flow

Test this flow:

1. Reset app data if you want to see onboarding again.
2. Open **Onboarding**.
3. Enter a display name during onboarding.
4. Continue to **Home**.
5. Confirm **Home** greets you by name.
6. Start **Recording**.
7. Allow microphone permission.
8. Allow speech recognition permission.
9. Confirm the transcript card shows **Mic Ready** and **Speech Ready**, or a clear fallback state.
10. Speak a short reflection, or type in the transcript box if microphone or speech recognition is not ready.
11. Confirm **Finish** stays unavailable until the transcript quality message says the entry is ready.
12. Tap **Finish**.
13. Wait for **AI Processing**.
14. Review **Reflection**.
15. Tap regenerate and confirm the reflection refreshes or shows a clear error.
16. Tap **Save & Start Practice**.
17. Confirm the app opens **Practice** with the suggested action active.
18. Complete or skip the practice and confirm Home/Profile progress changes.
19. Start another reflection and tap **Save Entry**.
20. Confirm the **Saved** screen still appears.
21. Open **Journal** and inspect the saved detail.
22. In the journal detail, add or reactivate the suggested practice.
23. Save the reflection into a private circle from the journal detail.
24. Open **Circles** and confirm the saved reflection appears as a private post without private workspace notes.
25. Open **Profile** and confirm the name, entry count, streak, and progress changed.
26. Edit the display name from **Profile** and confirm **Home** updates.
27. Open **Profile > QA tools** and confirm build info, local counts, export, seed, and reset controls are available.
28. Open **Profile > QA tools > AI Lab** and confirm the saved session appears with transcript, engine, attempts, and status.
29. Open the saved Journal detail, edit title, emotion, private note, and tags, then confirm edited values remain after closing the sheet.
30. Share the edited reflection into a private circle and confirm the circle post uses the edited title.

Use Simulator for SwiftUI Previews. Use the connected iPhone for Run testing. Physical-device Preview errors do not necessarily mean the app build is broken.

## 6. Reproducible QA Checks

Use these controls when teammates need the same local state on a phone:

1. Open **Profile**.
2. Tap **QA tools**.
3. Tap **Seed demo data**.
4. Confirm Profile now shows demo reflections, circles, posts, practices, XP, and mood.
5. Open **Home**, **Journal**, **Practice**, and **Circles** to confirm the same demo state appears across tabs.
6. Open **Practice** and use the active practice card to complete, skip, or restart a practice.
7. Save the latest reflection into a circle and confirm duplicate saves are disabled.
8. Return to **Profile > QA tools**.
9. Tap **Copy QA** or **Share QA** and confirm the export includes build info, profile summary, local counts, and journal text.
10. Tap **Reset local data** and confirm the warning appears before data is cleared.
11. Relaunch or close the sheet and confirm onboarding can be tested from a first-run state.

## 7. Recording Reliability Checks

Test these before calling the build demo-ready:

1. Start recording and type instead of speaking.
2. Confirm the word-count and guidance messages update as text changes.
3. Confirm **Finish** stays disabled until the transcript passes the quality check.
4. Finish with typed text and confirm AI analysis starts.
5. Regenerate from the reflection screen and confirm Save uses the latest generated result.
6. Save once and confirm the confirmation screen appears.
7. Repeat with another reflection, use **Save & Start Practice**, and confirm Practice opens with the new practice.
8. Open Journal and confirm only one new entry exists.
9. Use **Record Another** and confirm the previous transcript is cleared.
10. Deny microphone or speech permission on a fresh install if possible and confirm typed fallback still works.
11. Open **Profile > QA tools > AI Lab** and confirm the session appears.
12. Copy the AI QA export and confirm it includes transcript, engine, attempts, and status.
13. Open the saved Journal detail, edit title, emotion, private note, and tags, and confirm the edited values appear after closing the sheet.
14. Share the edited reflection into a private circle and confirm the circle post uses the edited title.

## 8. Onboarding And Home Visual Checks

1. Reset app data and confirm onboarding fits on the phone.
2. Leave name empty and confirm Home greets `Friend`.
3. Enter a real name and confirm Home greets that name.
4. Tap refresh on the daily prompt and confirm the prompt changes.
5. Save a reflection and confirm Home stats and latest reflection update.
6. Confirm top bar level/streak values are not hard-coded.

## 9. Local Workflow Checks

1. Save a reflection and confirm Home shows a real next action.
2. Tap **Open Practice** from Home and confirm the Practice tab opens.
3. Complete the active practice and confirm Profile XP/progress updates.
4. Save another reflection and tap **Skip** in Practice to confirm it disappears from active practices.
5. Restart a skipped or completed practice from the Practice tab.
6. Save the reflection into a private circle from the journal detail.
7. Open **Circles** and confirm cards show spaces, posts, and reflections instead of member counts.
8. Create a new private circle.
9. Open the circle and add a support note.
10. Share the latest reflection into that circle.
11. Confirm the circle post count and latest activity update.
12. Open **Profile** and confirm entries, streak, circles, mood, badges, practices, and local data summary all reflect real local state.
13. Edit the display name and confirm Home/Profile use the new name.

## Backend Decision

For the current Apple Intelligence test, no backend is required because the reflection engine runs on device when Apple Intelligence is available.

Add a backend later when Circleu needs:

- OpenAI, Claude, or another cloud model.
- Shared team accounts.
- Cloud sync across devices.
- Analytics and production logging.
- Server-side model evaluation.
