# Circleu Release Readiness

This branch is prepared as the first shareable local-first MVP branch for phone testing.

## Branch

- Branch: `dev/mike`
- Remote: `origin`
- Project: `/Users/tuanm.nguyen/Documents/JornalApp-personal/Circleu.xcodeproj`
- Commit workflow: use `docs/process/git-workflow.md` and `docs/process/team-standards.md`

## MVP Coverage

- Onboarding saves a local display name.
- Home shows local progress, latest reflection, daily prompt, and active tips routing.
- Recording supports voice capture, permission readiness, speech recognition, transcript quality checks, typed fallback, AI analysis retry, reflection regeneration, and save confirmation.
- Reflection supports Save Entry and Save & Open Tips.
- Journal lists saved reflections, opens detail, exports entries, manages related tips, and saves insights to private circles.
- Journal detail supports editable reflection workspace fields and AI session history.
- Tips supports active, completed, skipped, restarted, and source-linked AI-suggested tips.
- Circles support local private spaces, notes, edits, deletes, and privacy-safe reflection shares.
- Profile shows real local progress, editable profile, local data summary, and QA seed/reset/export tools.
- AI Lab exposes local session history, attempt counts, and exportable QA data.

## Repo Cleanup

- Feature screens live under `Circleu/Features`.
- Shared form controls live under `Circleu/Components`.
- Tips workflow lives in `Circleu/Features/Tips/TipsView.swift`.
- Profile QA tools live in `Circleu/Features/Profile/ProfileQAToolsSheet.swift`.
- Circle sheets live in `Circleu/Features/Circle/CircleSheets.swift`.
- Journal circle sharing lives in `Circleu/Features/Journal/JournalCircleShareSheet.swift`.

## Phone QA Flow

1. Run the app on the connected iPhone from Xcode.
2. Open **Profile > QA tools**.
3. Tap **Seed demo data**.
4. Confirm Home, Journal, Tips, Circles, and Profile all reflect the seeded local state.
5. Start a new reflection and choose **Save & Open Tips** from the reflection result.
6. Confirm the Tips tab opens with the new active tips.
7. Complete, skip, and restart tips from Tips.
8. Save a reflection into a private circle and confirm duplicate saves are disabled.
9. Open Circles and confirm the saved reflection appears as a privacy-safe post.
10. Return to **Profile > QA tools** and test **Copy QA**, **Share QA**, and **Reset local data**.

## Backend Status

No backend is required for this branch. Add backend work later for shared accounts, cloud sync, production analytics, or cloud AI model providers.
