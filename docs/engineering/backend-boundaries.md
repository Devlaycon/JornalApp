# Circleu Backend Boundaries

Circleu is local-first. Backend work should be added through explicit service boundaries, not directly from SwiftUI views or feature ViewModels.

## Current Local Ownership

These systems work locally today:

- reflection journal entries,
- tips and quest state,
- circle spaces and private posts,
- profile name and preferences,
- AI reflection session history,
- QA seed, reset, and export tools.

Local stores remain the source of truth until the app intentionally adds account login, cloud sync, analytics, shared devices, or external AI providers.

## Backend Entry Points

Future backend work enters through `Circleu/Services/BackendPreparation.swift` and focused service files in `Circleu/Services/`.

Current protocol boundaries:

- `UserIdentityProviding`: local or backend-backed user identity and display name.
- `ReflectionSyncing`: sync boundary for `BackendSyncSnapshot`.
- `AnalyticsTracking`: privacy-safe `AnalyticsEvent` tracking boundary.
- `ReflectionModelProvider`: model-provider availability, provider identity, and on-device capability.

Current contract types:

- `BackendSyncSnapshot`: local payload prepared for future sync.
- `BackendSyncCounts`: count summary for sync visibility and tests.
- `BackendSyncResult`: result of a sync attempt, including failed scopes.
- `BackendSyncScope`: data groups that can be synced independently later.
- `AnalyticsEvent`: sanitized event name, properties, and timestamp.
- `CloudKitRecordSchema`: stable CloudKit record type, scope, field, sensitive-field, and record-name metadata.

## Rule

Do not call a backend directly from `Circleu/Features/`.

```text
View -> ViewModel -> Store / Engine / Service -> Model
```

## Future Backend Responsibilities

- Auth/account identity: replace or extend `UserIdentityProviding`.
- Cloud sync: map local snapshots into CloudKit-ready payloads, then implement upload-only backup before two-way sync.
- Analytics: implement `AnalyticsTracking` with privacy-safe event names and properties.
- External AI: add provider implementations behind the reflection/model-provider boundary.
- Model evaluation: sync AI session attempts without exposing unnecessary raw content.

## Apple Intelligence Status

`ReflectionEngineFactory` uses `AppleIntelligenceReflectionEngine` only when the `FoundationModels` framework can be imported and the runtime is iOS 26 or newer. If Apple Intelligence is unavailable, disabled, still preparing its model, or returns unreadable JSON, Circleu falls back to `LocalReflectionEngine`.

Apple Intelligence must be fully validated on an eligible iOS 26 device or runtime where `SystemLanguageModel.default.availability` is `.available`. The local fallback path is covered by automated tests and keeps reflection saving working when Apple Intelligence is not available.

## Privacy Rules

Treat transcripts, journal entries, private notes, tags, circle posts, practice messages, and AI attempts as sensitive data.

Every backend-bound feature must define:

- what data leaves the device,
- why the data is needed,
- whether the user can opt out,
- how local-only mode still works,
- how failures fall back to local behavior.

Backend failures must never block local journaling, tips, circles, profile editing, or QA export.

## Ownership

The engine/backend owner maintains:

- `Circleu/Engines/`
- `Circleu/Stores/`
- `Circleu/Services/`
- `Circleu/Models/`
- `CircleuTests/` for engine, store, backend, and data-flow behavior
- `docs/engineering/`

UI owners should be able to change `Circleu/Features/`, `Circleu/Components/`, and `Circleu/Design/` without changing engine/backend behavior.
