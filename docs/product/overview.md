# Circleu Product Overview

Circleu is a local-first iOS reflection app for voice journaling, AI-assisted insight, and small daily actions. A user can record or type a reflection, receive a structured AI summary, save it into a private journal, start a suggested tip, and optionally share a privacy-safe version into a local circle.

## Current Beta Loop

```text
Onboarding -> Home -> Record or Type -> AI Reflection -> Journal -> Tips -> Progress -> Circle/Profile
```

The current beta is designed to run on a real iPhone without a production backend. Reflections, tips, circles, profile data, and AI session history are stored locally. Apple Intelligence is used when available, with local fallback behavior for simulator and unsupported devices.

## One-Minute Script

Circleu helps people turn everyday reflection into practical growth. Instead of acting like a generic chatbot, it guides a user through a calm loop: speak or type honestly, review a structured AI reflection, save the insight, and take one small follow-up action.

The current version is local-first so the full experience can be tested before cloud accounts and sync are required. It already supports recording, speech recognition, typed fallback, AI reflection generation, saved journals, tips, local circles, progress, and QA tools for repeatable testing.

## Product Areas

- **Onboarding**: introduces the app and stores a local display name.
- **Home**: daily hub for reflection entry points, latest reflection, active tip, and progress.
- **Recording**: microphone capture, transcript status, typed fallback, and quality checks.
- **Reflection**: AI-generated emotion, summary, insight, quote, expression moment, confidence, regenerate, save, and Save & Open Tips.
- **Journal**: saved reflections, search, editable workspace fields, related tips, export, and circle sharing.
- **Tips**: active, completed, skipped, and restarted suggested actions.
- **Circle**: private local support spaces and privacy-safe reflection shares.
- **Profile**: progress, profile editing, local data summary, QA tools, and AI session lab.

## Project Shape

```text
Circleu/
  App/                 App entry, dependency injection, root navigation
  Assets.xcassets/     Colors, app icon, mascot, and image assets
  Components/          Shared reusable SwiftUI components and button styles
  Design/              Design tokens such as colors, spacing, and layout constants
  Engines/             Business logic and AI/reflection logic
  Features/            User-facing screens grouped by product workflow
  Models/              Codable domain models and value types
  Services/            Device APIs and future backend/provider boundaries
  Stores/              ObservableObject app state and local persistence
```

See [project-structure.md](../engineering/project-structure.md) for folder ownership rules.

## Product Direction

The immediate priority is a reliable local-first beta. Backend work should grow in small slices after the local loop is stable:

1. identity,
2. Firebase-backed sync,
3. privacy-safe analytics,
4. optional external AI providers.

Firebase is the current backend direction because the team does not have paid Apple Developer Program access for CloudKit. See [firebase-backend-plan.md](../engineering/firebase-backend-plan.md). CloudKit remains documented as an Apple-first reference in [cloudkit-data-model.md](../engineering/cloudkit-data-model.md).
