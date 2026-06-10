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

Backend-ready boundaries are documented in [backend-boundaries.md](backend-boundaries.md). CloudKit schema direction is documented in [cloudkit-data-model.md](cloudkit-data-model.md).

## Build Order

### 1. Identity

Goal: give each user a stable account while keeping local-only mode available.

Add:

- sign-in state,
- stable backend user ID,
- migration from `LocalUserIdentityProvider.localUserID`,
- sign-out behavior that does not accidentally destroy local data.

Local journaling must keep working if sign-in fails.

### 2. CloudKit Sync

Goal: sync the local-first data model across Apple devices.

Use `BackendSyncSnapshot` as the local data source and [cloudkit-data-model.md](cloudkit-data-model.md) as the record schema. Start by mapping local models into CloudKit-ready payloads:

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

Start with upload-only private backup. Add two-way sync only after conflict rules are defined.

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

1. `docs: update CloudKit guide for current models`
2. `test: update CloudKit schema coverage`
3. `refactor: align CloudKit schema constants`
4. `test: cover CloudKit snapshot mapping`
5. `feat: map local snapshots to CloudKit payloads`
6. `test: cover identity provider behavior`
7. `refactor: add backend identity provider`
8. `test: cover upload-only sync fallback`
9. `feat: add upload-only CloudKit backup sync`
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
