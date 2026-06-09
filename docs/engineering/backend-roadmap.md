# Circleu Backend Roadmap

Circleu should stay local-first until the product needs backend features for real users. Backend work should be added in small, reversible slices behind the service contracts in `Circleu/Services/BackendPreparation.swift`.

## Current Position

The current beta does not require a backend. These systems already work locally:

- Reflection journal entries
- Tips and quest state
- Circle spaces and private posts
- Profile name and preferences
- AI reflection session history
- QA seed, reset, and export tools

The backend-ready boundaries are documented in [backend-boundaries.md](backend-boundaries.md). Do not add direct network calls from SwiftUI views or feature ViewModels.

## Build Order

### 1. Identity

Goal: give each user a stable account while keeping local-only mode available.

Add first:

- account sign-in state,
- stable backend user ID,
- migration from `LocalUserIdentityProvider.localUserID`,
- sign-out behavior that does not destroy local data by accident.

Do not require identity before the app can journal locally. If sign-in fails, the app should continue with the local identity provider.

### 2. Cloud Sync

Goal: sync the local-first data model across devices.

Use `BackendSyncSnapshot` as the starting contract. Sync should cover:

- journal entries,
- quests,
- circles,
- circle posts,
- AI sessions.

Start with upload-only backup before adding two-way sync. Two-way sync needs conflict rules for edited journal workspace fields, deleted circle posts, quest status changes, and AI session merges.

### 3. Analytics

Goal: understand product usage without collecting private journal content.

Use `AnalyticsEvent`. Events should describe actions, not sensitive text.

Allowed examples:

- `reflection_saved`
- `quest_completed`
- `circle_created`
- `ai_reflection_regenerated`
- `qa_export_copied`

Do not send transcript text, private notes, circle post bodies, or raw AI reflection content as analytics properties.

### 4. External AI Provider

Goal: support cloud model providers when Apple Intelligence or local fallback is not enough.

Add this after identity and privacy rules are clear. External AI should sit behind the reflection/model-provider boundary and preserve local fallback behavior.

Before sending transcript text to a cloud model, define:

- user consent,
- what text is sent,
- retention policy,
- failure fallback,
- whether cloud AI can be disabled.

## What Stays Local

Even after backend support exists, Circleu should keep these local-first guarantees:

- Users can record or type a reflection without network access.
- Users can save a local journal entry without sign-in.
- Existing local journal data remains readable if backend sync fails.
- QA seed/reset/export tools keep working for demos and development.
- Local fallback reflection still works when external model providers are unavailable.

## Privacy Rules

Treat these as sensitive user data:

- transcripts,
- journal entries,
- private notes,
- tags,
- circle posts,
- AI session attempts,
- AI-generated reflection content.

Every backend feature must answer:

- What data leaves the device?
- Why does it need to leave the device?
- Can the user opt out?
- What happens offline?
- What happens if sync or AI fails?
- How can a developer test it without production credentials?

## Implementation Slices

Use this order for future backend commits:

1. `docs: add backend decision record`
2. `test: cover identity provider behavior`
3. `refactor: add backend identity provider`
4. `test: cover sync snapshot serialization`
5. `feat: add upload-only backup sync`
6. `test: cover privacy-safe analytics events`
7. `feat: add analytics tracker`
8. `test: cover external reflection provider fallback`
9. `feat: add external reflection provider boundary`

Each slice should keep local mode working and should include tests for failure fallback.

## Not Yet

Do not build these until the product has a clear need:

- live multi-user circles,
- real-time chat,
- social feeds,
- production recommendation ranking,
- server-side moderation workflows,
- complex admin dashboards.

Those features require product decisions and privacy review beyond the current beta.
