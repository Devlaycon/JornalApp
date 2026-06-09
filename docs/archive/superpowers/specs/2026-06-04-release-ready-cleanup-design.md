# Release Ready Cleanup Design

## Goal

Prepare Circleu's `dev/mike` branch for its first push by cleaning the repo structure, reducing oversized SwiftUI files, preserving the current local-first product behavior, and verifying the app on simulator and connected iPhone.

## Scope

This cleanup does not add backend accounts, cloud sync, analytics, or new product tabs. It focuses on making the existing MVP easier to maintain and safer to share with teammates.

## Architecture

Feature views should keep screen layout and navigation decisions. Reusable controls move into `Circleu/Components`, feature-specific sheets move beside their feature under `Circleu/Features`, and stores remain under `Circleu/Stores`. This keeps business state in stores while making views easier for frontend and business teammates to review.

## File Organization

- `Components`: reusable controls shared across features, including form inputs and shared button/card styles.
- `Features/Profile`: profile screen and profile-specific QA tools.
- `Features/Journal`: journal list/detail screens and journal-specific share sheets.
- `Features/Circle`: circle list screen plus circle create/edit/detail/post/picker sheets.
- `docs`: app flow, structure, phone testing, and release readiness notes.

## Completion Criteria

1. No dead old numbered or placeholder view folders are referenced by the Xcode project.
2. Large feature files are split where the split is mechanical and low risk.
3. The app still supports onboarding, recording, AI reflection, journal, daily quest, circles, profile, and QA seed/reset/export.
4. Placeholder scan reports only intentional documentation or text-field placeholder parameters.
5. iPhone 17 Pro simulator build succeeds.
6. Connected iPhone build succeeds.
7. Changes are committed and pushed to `origin/dev/mike`.

## Manual QA

After pushing, run on the phone, seed demo data from Profile QA tools, test Home quest actions, open a journal detail, save a reflection into a circle, confirm duplicate share prevention, and reset app data.
