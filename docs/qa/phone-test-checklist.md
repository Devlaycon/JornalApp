# Circleu Phone Test Checklist

Use this checklist to test Circleu on a real iPhone from Xcode.

## 1. Open Project

Open `Circleu.xcodeproj` from the repo root and use the latest `main` or your current feature branch after merging `origin/main`.

## 2. Configure Signing

1. Open Xcode.
2. Go to **Xcode > Settings > Accounts** and add your Apple ID.
3. Select the `Circleu` project in the left sidebar.
4. Select the `Circleu` target.
5. Open **Signing & Capabilities**.
6. Enable **Automatically manage signing**.
7. Choose your Apple development team.
8. If the bundle identifier is already taken, change it to a unique local value such as `com.yourname.Circleu`.

## 3. Connect iPhone

1. Connect the iPhone by cable.
2. Unlock the phone.
3. Tap **Trust This Computer** if prompted.
4. Choose the iPhone in Xcode's device picker.
5. Press Run.

Use Simulator for SwiftUI previews and unit checks. Use a connected iPhone for microphone, speech recognition, signing, Apple Intelligence availability, and full user-flow testing.

## 4. Primary User Flow

1. Reset app data if you want to test onboarding.
2. Open Onboarding.
3. Enter a display name.
4. Continue to Home.
5. Confirm Home greets the user by name.
6. Start Recording.
7. Allow microphone permission.
8. Allow speech recognition permission.
9. Confirm the transcript card shows ready or clear fallback states.
10. Speak a short reflection, or type in the transcript box.
11. Confirm Finish stays unavailable until transcript quality passes.
12. Tap Finish.
13. Wait for AI Processing.
14. Review Reflection.
15. Tap regenerate and confirm the reflection refreshes or shows a clear error.
16. Tap Save & Open Tips.
17. Confirm Tips opens with the suggested action active.
18. Complete or skip the tip and confirm Home/Profile progress changes.
19. Start another reflection and tap Save Entry.
20. Confirm the Saved screen appears.
21. Open Journal and inspect the saved detail.
22. Add or reactivate the suggested tip from journal detail.
23. Edit title, emotion, private note, and tags.
24. Close and reopen the detail to confirm edits persist.
25. Save the reflection into a private circle.
26. Open Circles and confirm the post does not expose private workspace notes.
27. Open Profile and confirm name, entry count, streak, XP, and progress changed.
28. Edit the display name from Profile and confirm Home updates.

## 5. Reproducible QA Flow

1. Open Profile.
2. Tap QA tools.
3. Tap Seed demo data.
4. Confirm Profile shows demo reflections, circles, posts, tips, XP, and mood.
5. Open Home, Journal, Tips, and Circles to confirm the same demo state appears across tabs.
6. Use Tips to complete, skip, and restart a tip.
7. Save the latest reflection into a circle and confirm duplicate saves are disabled.
8. Return to Profile > QA tools.
9. Tap Copy QA or Share QA and confirm the export includes build info, profile summary, local counts, journal text, and AI session details.
10. Tap Reset local data and confirm a warning appears before data is cleared.
11. Relaunch the app and confirm onboarding can be tested from a first-run state.

## 6. Recording Reliability

1. Start recording and type instead of speaking.
2. Confirm word-count and guidance messages update as text changes.
3. Confirm Finish stays disabled until transcript quality passes.
4. Finish with typed text and confirm AI analysis starts.
5. Regenerate from the reflection screen and confirm Save uses the latest generated result.
6. Save once and confirm the confirmation screen appears.
7. Repeat with another reflection, use Save & Open Tips, and confirm Tips opens with the new tip.
8. Open Journal and confirm only one new entry exists for the save.
9. Use Record Another and confirm the previous transcript is cleared.
10. Deny microphone or speech permission on a fresh install if possible and confirm typed fallback still works.
11. Open Profile > QA tools > AI Lab and confirm the session appears.
12. Copy the AI QA export and confirm it includes transcript, engine, attempts, and status.

## 7. Visual And Local Workflow Checks

1. Reset app data and confirm onboarding fits on the phone.
2. Leave name empty and confirm Home greets `Friend`.
3. Enter a real name and confirm Home greets that name.
4. Tap refresh on the daily prompt and confirm the prompt changes.
5. Save a reflection and confirm Home stats and latest reflection update.
6. Confirm top bar level and streak values are not hard-coded.
7. Tap Open Tips from Home and confirm the Tips tab opens.
8. Complete the active tip and confirm Profile XP/progress updates.
9. Create a new private circle.
10. Add a support note.
11. Share the latest reflection into that circle.
12. Confirm circle post count and latest activity update.

## Backend Note

Firebase is enabled for beta backend testing. After signing up or signing in, open Profile > QA tools and confirm Firebase status shows a UID. Save a reflection, then confirm Firestore has private user documents under `users/{uid}`. Clear local app data or reinstall, sign in with the same account, and confirm private profile/journal/reward/tips data restores. Shared circles are still local-only and should not write under the top-level `circles/` collection.
