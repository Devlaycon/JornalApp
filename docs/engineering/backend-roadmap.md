# Circleu Backend Roadmap

Circleu should stay local-first until backend features are needed for real users. Add backend work in small, reversible slices behind service contracts.

## Current Position

The beta already works locally:

- reflection journal entries,
- tips and quest state,
- circle spaces and private posts,
- reward points and profile activity,
- profile name and preferences,
- AI reflection session history,
- QA seed, reset, and export tools.

Backend-ready boundaries are documented in [backend-boundaries.md](backend-boundaries.md). Firebase is the current backend target and is documented in [firebase-backend-plan.md](firebase-backend-plan.md). CloudKit remains an Apple-first reference in [cloudkit-data-model.md](cloudkit-data-model.md).

## Build Order

### 1. Identity

Goal: give each user a stable account while keeping local-only mode available.

Add:

- sign-in state,
- stable backend user ID,
- migration path from local `AuthStore` accounts,
- migration from `LocalUserIdentityProvider.localUserID`,
- sign-out behavior that does not accidentally destroy local data.

Local journaling must keep working if sign-in or Firebase availability fails. Do not upload local password hashes to Firebase.

### 2. Firebase Sync

Goal: sync the local-first data model across devices.

Use `BackendSyncSnapshot` as the local data source and [firebase-backend-plan.md](firebase-backend-plan.md) as the Firestore schema. Start by mapping local models into Firebase-ready payloads:

- journal entries,
- quests,
- circles,
- circle posts,
- circle post replies,
- AI sessions,
- tips practice sessions.
- reward state,
- point entries,
- activity events.

Start with upload-only private user backup. Add shared circles and two-way sync only after security rules and conflict rules are defined.

### 3. Analytics

Goal: understand product usage without collecting private journal content.

Use `AnalyticsEvent`. Events should describe actions, not sensitive text.

Allowed examples:

- `reflection_saved`
- `quest_completed`
- `circle_created`
- `ai_reflection_regenerated`
- `qa_export_copied`

Never send transcript text, private notes, tags, circle post bodies, practice messages, or raw AI reflection content as analytics properties.

### 4. External AI Provider

Goal: support cloud model providers when Apple Intelligence or local fallback is not enough.

Add this after identity, consent, and privacy rules are clear. External AI must sit behind the reflection/model-provider boundary and preserve local fallback behavior.

Before sending transcript text to a cloud model, define:

- user consent,
- what text is sent,
- retention policy,
- failure fallback,
- whether cloud AI can be disabled.

## Local-First Guarantees

Even after backend support exists:

- users can record or type without network access,
- users can save a local journal entry without sign-in,
- existing local data remains readable if sync fails,
- QA seed/reset/export tools keep working,
- local reflection fallback keeps working when provider services are unavailable.

## Implementation Slices

Recommended backend sequence:

1. `docs: add Firebase backend plan`
2. `test: cover Firebase schema foundation`
3. `feat: add Firebase schema foundation`
4. `test: cover Firebase snapshot mapping`
5. `feat: map local snapshots to Firebase payloads`
6. `test: cover Firebase auth boundary`
7. `feat: add Firebase auth service boundary`
8. `test: cover upload-only sync fallback`
9. `feat: add upload-only Firestore backup sync`
10. `test: cover privacy-safe analytics events`
11. `feat: add analytics tracker`
12. `test: cover external reflection provider fallback`
13. `feat: add external reflection provider boundary`

Each slice must keep local mode working and include tests for failure fallback.

## Not Yet

Do not build these until the product has a clear need:

- live multi-user circles,
- real-time chat,
- social feeds,
- production recommendation ranking,
- server-side moderation workflows,
- admin dashboards.
