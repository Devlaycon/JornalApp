# Circleu Architecture

Circleu uses a local-first SwiftUI architecture with feature-first folders and a small shared core.

The main dependency flow is:

```text
View -> ViewModel -> Store / Engine / Service -> Model
```

## Responsibilities

`View`

- Renders SwiftUI layout.
- Owns only visual state such as selected rows, sheet presentation, and animation state.
- Calls ViewModel methods for user actions.

`ViewModel`

- Owns screen-specific state and user actions.
- Converts model/store data into UI-ready values.
- Coordinates stores, engines, and services.
- Handles loading, empty, disabled, and error states.
- Should be testable without rendering SwiftUI.

`Store`

- Owns shared app state and local persistence.
- Saves, loads, updates, deletes, resets, and exports local data.
- Can be injected into multiple ViewModels.
- Should not know about screen layout.

`Engine`

- Runs pure or mostly pure business logic.
- Examples: reflection generation, progress calculation, transcript quality checks, and beta state derivation.
- Should be easy to unit test.

`Service`

- Wraps device/system APIs or future external integrations.
- Examples: audio recording, speech recognition, future sync, analytics, identity, and model provider boundaries.

`Model`

- Defines Codable domain objects and value types.
- Contains data shape and small computed properties when they are universally true.
- Should not call stores, engines, or services.

## Feature Ownership

Screens and screen ViewModels live together under `Circleu/Features/<FeatureName>/`.

Shared reusable SwiftUI pieces live in `Circleu/Components/` only after more than one feature needs them. Visual constants live in `Circleu/Design/`. Persistence belongs in `Circleu/Stores/`, business logic in `Circleu/Engines/`, and device/system integrations in `Circleu/Services/`.

## Local-First Boundary

The current beta does not require a backend. Reflections, tips, profile data, AI session history, and circles are stored locally. Future backend work should enter through service protocols for identity, sync, analytics, and model providers instead of being called directly from views.

## Testing Boundary

Prefer ViewModel, Store, and Engine tests for behavior. Use phone QA for microphone, speech recognition, signing, Apple Intelligence availability, and full user-flow checks that cannot be verified reliably in pure unit tests.
