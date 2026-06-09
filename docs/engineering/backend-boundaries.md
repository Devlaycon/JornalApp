# Circleu Backend Boundaries

Circleu is local-first for the current beta. Backend work should be added through explicit service boundaries, not directly from SwiftUI views or feature ViewModels.

## Current Local Ownership

These systems stay local in the beta:

- Reflection journal entries
- Tips and quest state
- Circle spaces and private posts
- Profile name and preferences
- AI reflection session history
- QA seed, reset, and export tools

The local stores are the source of truth until the product needs account login, cloud sync, analytics, shared devices, or external AI model providers.

## Backend Entry Points

Future backend work should enter through `Circleu/Services/BackendPreparation.swift`.

The current protocol boundaries are:

- `UserIdentityProviding`: local or backend-backed user identity and display name.
- `ReflectionSyncing`: sync boundary for a `BackendSyncSnapshot` containing reflections, tips, circles, circle posts, and AI sessions.
- `AnalyticsTracking`: privacy-safe `AnalyticsEvent` tracking boundary.
- `ReflectionModelProvider`: model-provider availability, provider identity, and on-device capability.

The current backend contract types are:

- `BackendSyncSnapshot`: local data payload prepared for future sync.
- `BackendSyncCounts`: count summary for sync visibility and test assertions.
- `BackendSyncResult`: result of a sync attempt, including failed scopes.
- `BackendSyncScope`: the local data groups that can be synced independently later.
- `AnalyticsEvent`: sanitized event name, properties, and timestamp.

Do not call a backend directly from `Circleu/Features/`. A feature should call a ViewModel. A ViewModel should coordinate Stores, Engines, and Services.

```text
View -> ViewModel -> Store / Engine / Service -> Model
```

## Future Backend Responsibilities

When the app needs backend support, add implementations behind these boundaries:

- Auth/account identity: replace or extend `UserIdentityProviding`.
- Cloud sync: implement `ReflectionSyncing` for local store snapshots and conflict handling.
- Analytics: implement `AnalyticsTracking` with privacy-safe event names and properties.
- External AI: add a provider behind the reflection/model-provider boundary.
- Model evaluation: sync AI session attempts without exposing private notes or unnecessary raw transcript data.

## Privacy Rules

Treat transcript, journal entries, private notes, and circle posts as sensitive user data.

Backend-bound work must define:

- what data leaves the device,
- why that data is needed,
- whether the user can opt out,
- how local-only mode still works,
- how failures fall back to local behavior.

For the beta, backend failures should never block local journaling, local tips, local circles, or local QA export.

## Your Ownership

The engine/backend owner should maintain:

- `Circleu/Engines/`
- `Circleu/Stores/`
- `Circleu/Services/`
- `Circleu/Models/`
- `CircleuTests/` for engine, store, and data-flow behavior
- `docs/engineering/` for backend and architecture decisions

UI owners should be able to change `Circleu/Features/`, `Circleu/Components/`, and `Circleu/Design/` without changing engine/backend behavior.
