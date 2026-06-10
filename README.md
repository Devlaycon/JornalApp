# Circleu

Circleu is a local-first iOS reflection app for voice journaling, AI-assisted insight, and small daily tip actions.

The current beta focuses on one complete real-user loop:

```text
Onboarding -> Home -> Record or Type -> AI Reflection -> Journal -> Tips -> Progress -> Circle/Profile
```

Users can record or type a reflection, review an AI-generated summary, save it to a private journal, start a suggested tip action, and optionally share a privacy-safe version into a private circle on the same device.

## Design Reference

- [TEAM 6 PINGU Figma design](https://www.figma.com/design/zLxqQQD19rjIf65Zqs2aeE/TEAM-6-PINGU?node-id=0-1&m=dev&t=MEb8WYBaU5VVG022-1)

## Current Capabilities

- Voice recording with microphone permission handling.
- Speech recognition with typed fallback when recording or transcription is not available.
- AI reflection generation through a `ReflectionAnalyzing` abstraction.
- Apple Intelligence support through Foundation Models when available.
- Local test reflection engine fallback for simulator and unsupported devices.
- Saved reflection journal with editable title, emotion, notes, and tags.
- Tips workflow for active, completed, skipped, and restarted actions.
- Private local circles for support notes and selected reflection shares.
- Profile progress based on local reflection and tip state.
- QA tools for deterministic demo data, local reset, and exportable test summaries.

## Tech Stack

- SwiftUI
- Xcode project: `Circleu.xcodeproj`
- Local-first app state with `ObservableObject` stores
- Swift `Codable` models for persistence-friendly data
- AVFoundation for recording
- Speech framework for transcription
- Foundation Models / Apple Intelligence when available

No backend is required for the current beta. The app is structured so cloud identity, sync, analytics, and external model providers can be added later without rewriting the core user flow.

## Project Structure

```text
Circleu/
  App/                 App entry, dependency injection, root navigation
  Assets.xcassets/     Colors and image assets
  Components/          Shared reusable SwiftUI components and button styles
  Design/              Design tokens such as colors, spacing, and layout constants
  Engines/             Pure business or AI logic
  Features/            User-facing screens grouped by product workflow
  Models/              Codable domain models and value types
  Services/            Device/system integrations
  Stores/              ObservableObject state and local persistence
```

See [docs/engineering/project-structure.md](docs/engineering/project-structure.md) for folder ownership rules.

## Run Locally

1. Open `Circleu.xcodeproj` in Xcode.
2. Select the `Circleu` scheme.
3. Choose an iPhone simulator, such as iPhone 17 Pro.
4. Build and run.

Command-line simulator build:

```bash
xcodebuild build -project Circleu.xcodeproj -scheme Circleu -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## Test

The shared `Circleu` scheme includes the `CircleuTests` unit test target for ViewModel behavior checks.

```bash
xcodebuild test -project Circleu.xcodeproj -scheme Circleu -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## Run On iPhone

1. Open the `Circleu` target in Xcode.
2. Go to **Signing & Capabilities**.
3. Enable **Automatically manage signing**.
4. Select your Apple development team.
5. If needed, use a unique bundle identifier for your local device build.
6. Connect and unlock your iPhone.
7. Select the iPhone in Xcode and press Run.

For the full device checklist, see [docs/qa/phone-test-checklist.md](docs/qa/phone-test-checklist.md).

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

See [docs/process/git-workflow.md](docs/process/git-workflow.md) and [docs/process/team-standards.md](docs/process/team-standards.md) for the team commit and push rules.

## Key Docs

- [Docs index](docs/README.md)
- [Product overview](docs/product/overview.md)
- [App flow](docs/product/app-flow.md)
- [Domain models](docs/engineering/domain-models.md)
- [Architecture](docs/engineering/architecture.md)
- [Backend boundaries](docs/engineering/backend-boundaries.md)
- [Backend roadmap](docs/engineering/backend-roadmap.md)
- [Firebase backend plan](docs/engineering/firebase-backend-plan.md)
- [CloudKit data model](docs/engineering/cloudkit-data-model.md)
- [Project structure](docs/engineering/project-structure.md)
- [Phone test checklist](docs/qa/phone-test-checklist.md)
- [Release readiness](docs/product/release-readiness.md)
- [Team standards](docs/process/team-standards.md)

## Product Direction

Circleu is being built as a real, testable beta rather than a static Figma copy. The immediate priority is a reliable local-first reflection experience on a real iPhone. Backend work should come later when the product needs account login, cloud sync, shared devices, analytics, or external AI model providers.
