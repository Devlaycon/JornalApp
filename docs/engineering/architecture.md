# Circleu Architecture

Circleu uses a local-first SwiftUI architecture with feature-first folders and a small shared core.

## Dependency Flow

```text
View -> ViewModel -> Store / Engine / Service -> Model
```

## Responsibilities

- **View**: renders SwiftUI layout, owns visual-only state, and calls ViewModel actions.
- **ViewModel**: owns screen state, validation, loading/empty/error states, and coordinates stores, engines, and services.
- **Store**: owns shared app state and local persistence. Stores save, load, update, delete, reset, and export local data.
- **Engine**: runs business logic, reflection generation, transcript checks, progress calculation, and beta state derivation.
- **Service**: wraps device APIs and future external integrations such as identity, sync, analytics, and model providers.
- **Model**: defines `Codable` domain data and small computed properties that are universally true.

## Ownership

Screens and feature ViewModels live together under `Circleu/Features/<FeatureName>/`.

Shared reusable SwiftUI pieces live in `Circleu/Components/` only after more than one feature needs them. Visual constants live in `Circleu/Design/`. Persistence belongs in `Circleu/Stores/`, business logic in `Circleu/Engines/`, system and backend boundaries in `Circleu/Services/`, and data shapes in `Circleu/Models/`.

## Local-First Boundary

The beta stores reflections, tips, profile data, AI session history, and circles locally. Backend work must enter through service protocols and payload mapping, not directly from SwiftUI views or feature ViewModels.

Firebase is the current backend direction, but local mode remains the source of truth until sync is explicitly enabled. CloudKit remains documented as a future Apple-first alternative.

## Testing Boundary

Prefer unit tests for ViewModels, Stores, Engines, data flow, backend contracts, and CloudKit mapping. Use phone QA for microphone, speech recognition, signing, Apple Intelligence availability, and full user-flow checks.
