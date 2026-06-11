# Circleu

Circleu is an iOS reflection and journaling app that helps people turn short voice or typed check-ins into useful insight. Users can record a reflection, review AI-assisted feedback, save a private journal entry, practice one communication tip, and share selected support notes with a circle.

The current beta is built for real-device testing through TestFlight with Firebase Authentication and Firestore backup/sync.

```text
Onboarding -> Home -> Record or Type -> AI Reflection -> Journal -> Tips -> Circle/Profile
```

## App Store Preview

App Store/TestFlight-ready screenshots live in [docs/product/snapshots/app-store](docs/product/snapshots/app-store). Raw simulator screenshots are kept in [docs/product/snapshots](docs/product/snapshots).

| Reflect | Insight | Journal |
| --- | --- | --- |
| ![Circleu App Store screenshot: reflect in your own voice](docs/product/snapshots/app-store/01-reflect-in-your-own-voice.png) | ![Circleu App Store screenshot: turn check-ins into insight](docs/product/snapshots/app-store/02-turn-check-ins-into-insight.png) | ![Circleu App Store screenshot: save your private journal](docs/product/snapshots/app-store/03-save-your-private-journal.png) |

| Tips | Circles |
| --- | --- |
| ![Circleu App Store screenshot: practice one small next step](docs/product/snapshots/app-store/04-practice-one-small-step.png) | ![Circleu App Store screenshot: share support with circles](docs/product/snapshots/app-store/05-share-support-with-circles.png) |

## Current Beta

- TestFlight-ready iOS app.
- Firebase email/password sign-in.
- Firestore backup for profiles, journal entries, AI reflection sessions, tips practice, rewards, activity, and circles.
- Public circle data through Firestore-backed circles, posts, replies, likes, and bookmarks.
- Local persistence remains available so the app can keep working during normal beta testing and development.

## Core Features

- Voice recording with microphone permission handling.
- Speech recognition with typed fallback.
- AI reflection generation through a `ReflectionAnalyzing` boundary.
- Apple Intelligence support when available, with local fallback behavior for simulator and unsupported devices.
- Rough-language and low-signal reflection handling in the local engine.
- Saved journal entries with editable title, emotion, notes, and tags.
- Tips workflow for active, completed, skipped, and restarted actions.
- Circle sharing for selected reflection insights and support posts.
- Profile progress, Firebase status, QA tools, demo seeding, force upload, and restore controls.

## Tech Stack

- SwiftUI
- Xcode project: `Circleu.xcodeproj`
- Firebase Authentication
- Cloud Firestore
- AVFoundation for recording
- Speech framework for transcription
- Foundation Models / Apple Intelligence when available
- `ObservableObject` stores with `Codable` persistence-friendly models

## Project Structure

```text
Circleu/
  App/                 App entry, dependency injection, root navigation
  Assets.xcassets/     Colors, app icon, mascot, and image assets
  Components/          Shared reusable SwiftUI components and button styles
  Design/              Design tokens such as colors, spacing, and layout constants
  Engines/             Pure business and AI/reflection logic
  Features/            User-facing screens grouped by product workflow
  Models/              Codable domain models and value types
  Services/            Device, Firebase, and backend integration boundaries
  Stores/              ObservableObject app state and local persistence
```

See [docs/engineering/project-structure.md](docs/engineering/project-structure.md) for folder ownership rules.

## Run Locally

1. Open `Circleu.xcodeproj` in Xcode.
2. Select the `Circleu` scheme.
3. Select an iPhone simulator, such as iPhone 17 Pro.
4. Build and run.

Command-line simulator build:

```bash
xcodebuild build -project Circleu.xcodeproj -scheme Circleu -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## Firebase Setup

Firebase is required for the live beta backend. The app expects a valid `GoogleService-Info.plist` for the current bundle identifier.

For the shared TestFlight app, the bundle identifier is:

```text
edu.uts.tuannm3812.Circleu
```

If Firebase cannot be configured, the app falls back to no-op backend services and local state for development, but TestFlight data will not sync to Firestore until the Firebase config matches the app bundle ID.

## Test

Run the shared unit test target:

```bash
xcodebuild test -project Circleu.xcodeproj -scheme Circleu -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Before a TestFlight upload, run a device or archive build from Xcode and complete the phone checklist:

- [docs/qa/phone-test-checklist.md](docs/qa/phone-test-checklist.md)
- [docs/product/testflight-description.md](docs/product/testflight-description.md)

## TestFlight Status

Circleu has been uploaded to Apple for TestFlight processing. Use App Store Connect to add beta app information, assign testers, and submit the build for internal or external testing.

Test account:

```text
Email: test.circleu@gmail.com
Password: CircleuTest123!
```

## Git Workflow

Use `main` as the stable team branch. Do feature work in a personal or feature branch, then merge only after the app builds and the user flow is tested.

Recommended daily workflow:

```bash
git checkout feat/your-slice
git fetch origin
git merge origin/main
```

Commit by functional slice:

```text
feat: add journal-to-circle sharing
fix: handle empty transcript fallback
refactor: split profile qa tools
docs: update phone test checklist
```

See [docs/process/git-workflow.md](docs/process/git-workflow.md) and [docs/process/team-standards.md](docs/process/team-standards.md) for commit and push rules.

## Key Docs

- [Docs index](docs/README.md)
- [Product overview](docs/product/overview.md)
- [App flow](docs/product/app-flow.md)
- [TestFlight description](docs/product/testflight-description.md)
- [Domain models](docs/engineering/domain-models.md)
- [Architecture](docs/engineering/architecture.md)
- [Backend boundaries](docs/engineering/backend-boundaries.md)
- [Firebase backend plan](docs/engineering/firebase-backend-plan.md)
- [Project structure](docs/engineering/project-structure.md)
- [Phone test checklist](docs/qa/phone-test-checklist.md)
- [Release readiness](docs/product/release-readiness.md)
- [Team standards](docs/process/team-standards.md)

## Product Direction

Circleu is being built as a real beta, not just a static prototype. The immediate focus is stable TestFlight testing, reliable Firebase-backed data flow, clearer AI reflection behavior, and a polished loop from reflection to journal, tips, and circles.
