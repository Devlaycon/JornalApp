# Circleu Project Structure

Circleu uses a feature-first structure with a small shared core. This keeps product workflows easy to find while still giving shared models, stores, services, engines, design tokens, and components clear homes.

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

## Feature Folders

Use `Features/<FeatureName>/` for screens and UI that belong to one workflow, such as Home, Journal, Tips, Circle, Recording, Reflection, Profile, or Onboarding.

Keep feature-specific cards, rows, and sheets inside the feature folder until another feature truly needs them.

Screen and workflow state should live in feature-local ViewModels. The app follows:

```text
View -> ViewModel -> Store / Engine / Service -> Model
```

Views render SwiftUI layout and call ViewModel actions. ViewModels own screen state, form validation, copy/export state, navigation sheet flags, and calls into stores, engines, or services. Stores remain the shared source of truth for local persistence.

Profile also owns local QA tools because the controls are user-facing during phone testing but specific to app state and reproducibility.

Tips owns the user-facing action workflow. The underlying model is still named `Quest` for now because earlier app state and persistence already use that language; `QuestStore` owns active, completed, skipped, and reactivated tip state.

## Components

Use `Components/` only for reusable UI used by multiple features. Examples:

- `PinguScreenBackground`
- `PinguTopBar`
- `PinguBottomTabBar`
- `PinguTextInput`
- `PinguPrimaryButtonStyle`
- `PinguSecondaryButtonStyle`

Do not put domain-specific screens in `Components`.

## Design

Use `Design/` for visual tokens and constants only. `PinguDesign` owns app colors, spacing, and fixed layout constants. SwiftUI views should live in `Components/` or `Features/`.

## Models, Stores, Engines, Services

- `Models/` defines app data types.
- `Stores/` owns app state and persistence.
- `Engines/` transforms data or runs analysis.
- `Services/` wraps system APIs such as audio recording and speech recognition.
- `Services/BackendPreparation.swift` defines local no-op interfaces for future identity, sync, analytics, and model provider work. These protocols prepare the app for backend work without adding network calls or secrets.

This separation lets frontend, business logic, and system integrations evolve independently while keeping the app easy to test on a real phone.

## Reproducible Phone Testing

Use `Profile > QA tools` on a device to seed deterministic local demo data, reset first-run app state, and export a QA summary. These controls are local-only and do not require a backend.

## First Push Cleanup

The first shareable branch keeps large workflow helpers close to their features:

- `Features/Profile/ProfileQAToolsSheet.swift` owns local QA seed/reset/export UI.
- `Features/Tips/TipsView.swift` owns the active/completed/skipped tip workflow.
- `Features/Circle/CircleSheets.swift` owns circle create/detail/edit/post/share sheets.
- `Features/Journal/JournalCircleShareSheet.swift` owns journal-to-circle sharing UI.

This keeps top-level tab views focused on layout and navigation while keeping feature behavior easy to find.
