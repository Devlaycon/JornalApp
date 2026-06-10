# Circleu Release Readiness

This checklist describes what must be true before a branch is considered shareable for teammate review, demo testing, or merge into `main`.

## Branch Expectations

- Work starts from the latest `main`.
- Changes are committed by functional slice.
- App-code changes include a build or test result.
- Documentation changes include a quick link/path scan.
- Real-device behavior is checked on an iPhone when the change touches signing, microphone, speech recognition, Apple Intelligence, or end-to-end flow.

## MVP Coverage

- Onboarding saves a local display name.
- Home shows local progress, latest reflection, daily prompt, and active tip routing.
- Recording supports voice capture, permission readiness, speech recognition, transcript quality checks, typed fallback, AI analysis retry, reflection regeneration, and save confirmation.
- Reflection supports Save Entry and Save & Open Tips.
- Journal lists saved reflections, opens detail, exports entries, manages related tips, and saves privacy-safe insights to private circles.
- Journal detail supports editable title, emotion, private note, tags, and AI session history.
- Tips supports active, completed, skipped, restarted, and source-linked AI-suggested actions.
- Circles support local private spaces, notes, edits, deletes, and reflection shares.
- Profile shows real local progress, editable profile, local data summary, QA seed/reset/export tools, and AI Lab.

## Phone QA Flow

1. Run the app on a connected iPhone from Xcode.
2. Open **Profile > QA tools**.
3. Tap **Seed demo data**.
4. Confirm Home, Journal, Tips, Circles, and Profile reflect the seeded local state.
5. Start a new reflection and choose **Save & Open Tips**.
6. Confirm the Tips tab opens with the new active tip.
7. Complete, skip, and restart tips.
8. Save a reflection into a private circle and confirm duplicate saves are disabled.
9. Open Circles and confirm the saved reflection appears as a privacy-safe post.
10. Return to **Profile > QA tools** and test **Copy QA**, **Share QA**, and **Reset local data**.

## Backend Status

Firebase is the active backend path for the current beta:

- Firebase Authentication handles account identity during onboarding.
- Cloud Firestore stores and restores private backups under `users/{uid}`.
- Profile > QA tools shows Firebase sign-in and sync status.
- Shared circles remain local-only until membership rules and security rules are designed.

Before demoing backend work, create a fresh account, save one reflection, then verify Firebase Console shows:

1. the user in Authentication,
2. `users/{uid}`,
3. `users/{uid}/profile/main`,
4. `users/{uid}/journalEntries/{entryID}`,
5. `users/{uid}/rewardState/main`.
6. After clearing local data and signing in again, private data restores from `users/{uid}`.

See [backend-roadmap.md](../engineering/backend-roadmap.md) and [firebase-backend-plan.md](../engineering/firebase-backend-plan.md).
