# Circleu MVVM Screen ViewModels Design

## Goal

Refine Circleu toward a professional SwiftUI MVVM structure without over-engineering the local-first beta. The app should stay easy to test on a real iPhone, easy for teammates to navigate, and ready for future backend/AI provider work.

The recommended architecture is:

```text
View -> ViewModel -> Store / Engine / Service -> Model
```

This keeps SwiftUI screens small, keeps persistence in shared stores, and keeps business logic out of view files.

## Current Context

Circleu is already organized by product area:

```text
Circleu/
  App/
  Components/
  Design/
  Engines/
  Features/
  Models/
  Services/
  Stores/
```

This structure should stay. It is a good base because screens are grouped by workflow, shared UI is centralized, and data/persistence already lives outside the views.

The main refinement is to introduce focused screen ViewModels where the views are currently doing too much.

## Architecture Decision

Use per-screen ViewModels and keep shared Stores.

Do not replace `Stores` with ViewModels. Stores remain the source of truth for local persistence and shared app state. ViewModels become screen-level controllers that prepare UI state, call store methods, call engines/services, and expose simple actions to the view.

### Responsibilities

`View`

- Renders SwiftUI layout.
- Owns only visual state such as sheet visibility, selected rows, and transient animation toggles when that state is purely presentational.
- Calls ViewModel methods for user actions.
- Does not contain reflection generation, persistence decisions, transcript validation, or progress calculations.

`ViewModel`

- Owns screen-specific state and user actions.
- Converts store/model data into UI-ready values.
- Coordinates calls to stores, engines, and services.
- Handles loading, empty, disabled, and error states for its screen.
- Stays testable without rendering SwiftUI.

`Store`

- Owns shared app state and local persistence.
- Saves, loads, updates, deletes, resets, and exports data.
- Can be injected into multiple ViewModels.
- Does not know about screen layout.

`Engine`

- Performs pure or mostly pure business logic.
- Examples: AI reflection generation, progress calculation, transcript quality checks, beta state derivation.
- Should be easy to unit test.

`Service`

- Wraps device/system or future external APIs.
- Examples: microphone, speech recognition, backend preparation, sync boundaries.

`Model`

- Defines Codable domain objects and value types.
- Contains data shape and small computed properties when they are universally true for that model.
- Does not call stores, engines, or services.

## Proposed Folder Shape

Keep the feature-first layout. Add ViewModels beside the screens they support:

```text
Circleu/
  Features/
    Home/
      HomeView.swift
      HomeViewModel.swift
    Recording/
      RecordingView.swift
      RecordingViewModel.swift
      SaveConfirmationView.swift
    Reflection/
      ReflectionView.swift
      ReflectionViewModel.swift
    Journal/
      JournalView.swift
      JournalViewModel.swift
      JournalEntryDetailView.swift
      JournalEntryDetailViewModel.swift
    Tips/
      TipsView.swift
      TipsViewModel.swift
    Circle/
      CircleView.swift
      CircleViewModel.swift
      CircleSheets.swift
    Profile/
      ProfileView.swift
      ProfileViewModel.swift
```

Only create a ViewModel when the screen has real state or actions. Small static views and simple reusable components do not need ViewModels.

## Data Flow

### Recording To Reflection

```text
RecordingView
  -> RecordingViewModel
    -> VoiceRecorder service
    -> TranscriptQuality engine
    -> ReflectionSessionRunner / ReflectionEngine
  -> ReflectionViewModel
    -> ReflectionJournalStore
    -> QuestStore
    -> AIReflectionSessionStore
```

The view should display status and controls. The ViewModel should decide when recording can finish, what fallback message to show, when AI analysis starts, and what reflection draft is passed forward.

### Journal

```text
JournalView
  -> JournalViewModel
    -> ReflectionJournalStore
    -> CircleStore for share targets
```

The ViewModel should own search/filter/sort state and expose filtered entries. Detail/edit sheets can get their own ViewModels if editing logic grows.

### Tips

```text
TipsView
  -> TipsViewModel
    -> QuestStore
    -> ReflectionJournalStore for source reflection context
```

The ViewModel should expose active, completed, skipped, and restartable tips as UI-ready sections.

### Circle

```text
CircleView
  -> CircleViewModel
    -> CircleStore
    -> ReflectionJournalStore for shareable reflections
```

The ViewModel should own selected space, composer validation, share actions, and empty states.

### Profile

```text
ProfileView
  -> ProfileViewModel
    -> UserProfileStore
    -> ProgressEngine
    -> ReflectionJournalStore
    -> QuestStore
    -> CircleStore
    -> AIReflectionSessionStore
```

The ViewModel should produce progress summaries and QA actions while stores continue to own the data.

## Migration Strategy

Use small vertical slices, not one huge refactor.

1. Add a `ViewModels` convention inside each feature folder.
2. Start with `RecordingViewModel` because recording has the highest risk and the most controller-like behavior.
3. Move only action/state logic first; avoid redesigning UI in the same commit.
4. Build after each feature migration.
5. Continue with `ReflectionViewModel`, then `JournalViewModel`, `TipsViewModel`, `CircleViewModel`, and `ProfileViewModel`.
6. Leave very small views alone unless they become difficult to read.

Each commit should be scoped by feature, for example:

```text
refactor(recording): introduce recording view model
refactor(reflection): move save actions into view model
refactor(journal): add journal filtering view model
```

## Testing Plan

For each migrated feature:

- Run an iPhone 17 Pro simulator build.
- Smoke-test the main flow on device or simulator when practical.
- Add unit tests for pure ViewModel logic when the behavior is non-trivial.
- Avoid snapshot/UI tests until the app structure stabilizes.

Recommended early ViewModel test targets:

- `RecordingViewModel` finish-state and fallback-state logic.
- `ReflectionViewModel` save/regenerate action state.
- `JournalViewModel` search/filter/sort behavior.
- `TipsViewModel` active/completed/skipped grouping.
- `CircleViewModel` composer validation and post creation.

## Error Handling

ViewModels should expose user-friendly screen state rather than raw errors:

```swift
enum ScreenState {
    case ready
    case loading
    case empty
    case failed(message: String)
}
```

Only introduce shared state enums when at least two screens need the same concept. Keep first migrations simple and local.

## Success Criteria

- Major views become easier to read and mostly describe layout.
- User actions are discoverable in ViewModel methods.
- Stores remain the shared source of truth.
- Engines and services are called from ViewModels or stores, not deeply inside SwiftUI layout blocks.
- The app still builds and runs after each migration.
- Git history shows feature-by-feature refactor commits instead of one large architecture commit.

## Non-Goals

- Do not rewrite all models.
- Do not introduce a backend during this refactor.
- Do not move every small subview into its own file.
- Do not add ViewModels for simple components.
- Do not change app visuals while moving architecture unless a small layout adjustment is required to keep behavior intact.
