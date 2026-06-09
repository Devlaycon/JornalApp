# Circleu Product Overview

## Short Introduction

Circleu is a local-first iOS reflection app that helps users turn voice journaling into useful AI-assisted insight and small daily tips. The app lets a user record or type a reflection, receive an AI-generated summary, save it into a private journal, open a suggested tip, and organize privacy-safe reflection cards into local communities.

Our current beta focuses on one complete real-user loop:

```text
Onboarding -> Home -> Record or Type -> AI Reflection -> Journal -> Tips -> Progress -> Circle/Profile
```

The app is built to run on a real iPhone without requiring a backend. User reflections, tip state, community posts, and profile progress are stored locally on the device. Apple Intelligence is used when available, and the app has fallback logic for simulator or unsupported devices.

## One-Minute Presentation Script

Circleu is our AI-powered reflection and self-improvement app. The main idea is simple: a user can speak naturally, get a helpful AI reflection, save it into a journal, and turn that insight into one small actionable tip. We designed the app to feel calm, private, and practical rather than like a generic chatbot.

The current version is local-first, which means we can test the full experience on an iPhone before building a backend. The app already supports recording, speech recognition, typed fallback, AI reflection generation, saved journals, a Tips workflow, private local communities, profile progress, and QA tools for repeatable testing.

In Xcode, we organize the project by product feature first. Screens live in `Features`, reusable UI lives in `Components`, visual constants live in `Design`, data models live in `Models`, app state lives in `Stores`, business and AI logic lives in `Engines`, and device integrations live in `Services`. This structure makes it easier for frontend, AI, and future backend work to grow without mixing everything into one file.

## Product Flow

1. **Onboarding** introduces the app and prepares the user for the reflection experience.
2. **Home** is the daily hub where the user starts a reflection and sees current progress.
3. **Recording** captures voice, shows transcript status, and supports typed fallback.
4. **Reflection** shows AI-generated emotion, insight, quote, expression moment, and next tip.
5. **Journal** stores saved reflections and lets the user search, edit, and reopen entries.
6. **Tips** turns an AI suggestion into an action the user can complete, skip, or restart.
7. **Circle** stores private community-style support notes and reflection shares locally.
8. **Profile** shows progress, local data summary, and QA tools for testing.

## Xcode Project Structure

```text
Circleu/
  App/                 App entry, dependency injection, root navigation
  Assets.xcassets/     Colors, app icon, mascot, and image assets
  Components/          Shared reusable SwiftUI components and button styles
  Design/              Design tokens such as colors, spacing, and layout constants
  Engines/             Pure business logic and AI/reflection logic
  Features/            User-facing screens grouped by product workflow
  Models/              Codable domain models and value types
  Services/            Device/system integrations such as audio and speech
  Stores/              ObservableObject app state and local persistence
```

## Key Folders Explained

### `App/`

This folder contains the app shell. `RootView` controls the main tab navigation, shows the top bar and bottom tab bar, and injects the correct feature screen for Home, Journal, Tips, Circle, and Profile.

### `Features/`

This is where most screen work happens. Each feature folder owns one user workflow:

- `Home/`: daily hub and entry point into recording or tips
- `Recording/`: microphone, transcript, typed fallback, and recording controls
- `Reflection/`: AI result screen and save actions
- `Journal/`: saved reflections and journal detail views
- `Tips/`: active, completed, skipped, and restarted tip workflow
- `Circle/`: private community spaces and saved support posts
- `Profile/`: user progress, local profile, and QA tools
- `Onboarding/`: first-run introduction screens

### `Components/`

Shared UI lives here only when multiple features use it. Examples include the app background, top navigation bar, bottom tab bar, reusable text input, and primary/secondary button styles.

### `Design/`

`PinguDesign` centralizes the app's colors, spacing, and layout constants. This keeps the UI visually consistent and makes Figma-to-Xcode refinement easier.

### `Models/`

Models define the shape of the app's data, such as saved reflections, quests/tips, community spaces, posts, progress badges, and AI sessions.

### `Stores/`

Stores own app state and local persistence. They are `ObservableObject` classes used by SwiftUI views. For example:

- `ReflectionJournalStore` saves journal entries.
- `QuestStore` manages tip actions.
- `CircleStore` manages local community spaces and posts.
- `UserProfileStore` manages profile name and daily prompt state.
- `AIReflectionSessionStore` stores AI analysis sessions.

### `Engines/`

Engines contain logic that transforms data or runs analysis. This keeps business logic out of the UI. The AI reflection system is behind an abstraction so Apple Intelligence can be used now and other AI providers can be added later.

### `Services/`

Services wrap system APIs and future external integrations. Audio recording, speech recognition, backend preparation protocols, analytics preparation, and future sync boundaries belong here.

## Why This Structure Is Professional

- It is feature-first, so developers can find screens by product workflow.
- It separates UI, state, models, business logic, and device integrations.
- It supports local-first testing now and backend growth later.
- It keeps reusable UI components shared without turning `Components/` into a dumping ground.
- It makes collaboration easier because team members can own different folders without constantly editing the same files.

## Current Beta Status

Circleu is not just a static Figma copy. It is already a working local-first iOS beta with:

- voice recording,
- speech recognition,
- typed fallback,
- AI reflection generation,
- saved journal entries,
- actionable Tips,
- private local communities,
- profile progress,
- repeatable QA seed/reset/export tools.

The next major product step is to continue improving real workflows, then add backend features only when we need login, sync, multi-device data, analytics, or shared communities.
