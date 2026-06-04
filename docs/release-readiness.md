# Circleu Release Readiness

This branch is prepared as the first shareable local-first MVP branch for phone testing.

## Branch

- Branch: `dev/mike`
- Remote: `origin`
- Project: `/Users/tuanm.nguyen/Documents/JornalApp-personal/Circleu.xcodeproj`
- Commit workflow: use `docs/git-workflow.md`

## MVP Coverage

- Onboarding saves a local display name.
- Home shows local progress, latest reflection, daily prompt, and active quest.
- Recording supports voice capture, permission readiness, speech recognition, transcript quality checks, typed fallback, AI analysis retry, reflection regeneration, and save confirmation.
- Journal lists saved reflections, opens detail, exports entries, manages related quests, and saves insights to private circles.
- Journal detail supports editable reflection workspace fields and AI session history.
- Circles support local private spaces, notes, edits, deletes, and reflection shares.
- Profile shows real local progress, editable profile, local data summary, and QA seed/reset/export tools.
- AI Lab exposes local session history, attempt counts, and exportable QA data.

## Repo Cleanup

- Feature screens live under `Circleu/Features`.
- Shared form controls live under `Circleu/Components`.
- Profile QA tools live in `Circleu/Features/Profile/ProfileQAToolsSheet.swift`.
- Circle sheets live in `Circleu/Features/Circle/CircleSheets.swift`.
- Journal circle sharing lives in `Circleu/Features/Journal/JournalCircleShareSheet.swift`.

## Phone QA Flow

1. Run the app on the connected iPhone from Xcode.
2. Open **Profile > QA tools**.
3. Tap **Seed demo data**.
4. Confirm Home, Journal, Circles, and Profile all reflect the seeded local state.
5. Open the latest journal detail and complete, skip, or reactivate the quest.
6. Save the reflection into a private circle and confirm duplicate saves are disabled.
7. Open Circles and confirm the saved reflection appears as a post.
8. Return to **Profile > QA tools** and test **Copy QA**, **Share QA**, and **Reset local data**.

## Backend Status

No backend is required for this branch. Add backend work later for shared accounts, cloud sync, production analytics, or cloud AI model providers.
