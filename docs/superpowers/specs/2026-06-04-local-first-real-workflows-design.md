# Local-First Real Workflows Design

## Goal

Replace remaining placeholder tab content with real local workflows and organize the app around small model, store, and engine files that are easier to manage as the project grows.

Circleu should feel like a working iPhone MVP: every tab should let the user do something real with local data, even before backend, login, signup, or cloud AI are added.

## Scope

In scope:

- Create clearer app model types for profile, progress, quests, tips plans, circles, and support posts.
- Add local stores or engines that derive real state from saved reflections.
- Remove old sample/static data structures that are not connected to the user.
- Replace fake Circle tab groups/member counts with private local circle workflows.
- Replace fake Profile level, XP, circles, support quest, and coming-next content with real local progress.
- Connect saved reflections to quests, tips, circles, and profile progress.
- Keep the current recording and AI reflection flow working.

Out of scope:

- Backend services.
- Signup and login.
- Real multi-user community features.
- Cloud sync.
- Push notifications.
- New third-party AI providers.
- Complex database migration beyond UserDefaults-backed local persistence.

## Product Model

Circleu uses a local-first domain model:

- `JournalReflectionEntry`: one saved reflection created from recording or typed fallback.
- `UserProfile`: display name and lightweight local preferences.
- `AppProgressSnapshot`: derived entries, streak, level, XP, badges, and emotion mix.
- `Quest`: a suggested action that can be active, completed, or skipped.
- `TipsPlan`: a repeatable local tips item derived from the user's reflection patterns.
- `CircleSpace`: a private support space the user can create locally.
- `CirclePost`: a note or reflection share saved inside a local circle.

The app should not pretend local circles are live communities. They are private spaces for organizing encouragement, notes, and reflection shares until backend community support exists.

## Folder Organization

Use simple folders under `Circleu/App`:

- `Models`: plain data types.
- `Stores`: UserDefaults-backed observable stores.
- `Engines`: derived logic such as progress and quest generation.

Existing files can remain where they are if moving them would create a risky Xcode project churn, but newly added domain files should follow this organization. Views should read from stores/engines instead of embedding sample arrays.

## Home Workflow

Home remains the daily start screen.

Real data:

- Greeting uses `UserProfileStore`.
- Level, streak, entries, latest emotion, and latest reflection use `ProgressEngine` and `ReflectionJournalStore`.
- Suggested next action uses the latest active quest from `QuestStore`.
- Daily prompt stays local and refreshable.

Home should link naturally to recording and journal review.

## Journal Workflow

Journal remains the private saved reflection library.

Real data:

- Entries come from `ReflectionJournalStore`.
- Search filters real saved content.
- Detail view displays transcript, AI result, engine name, date, duration, confidence, and suggested quest.
- Delete removes the saved reflection.

Journal does not need backend or sample entries.

## Circle Workflow

Circle becomes local private circles.

Real data:

- User can create a local circle with a name and intention.
- Default circles may be seeded once only if the user has no circles, but they must be framed as private starter spaces, not fake groups.
- User can save a reflection share or support note into a circle.
- Circle cards show real post counts and last activity.
- Circle detail sheet lists real local posts and offers actions to add a note or share the latest reflection.

No fake member counts, owner labels, or live discovery content.

## Profile Workflow

Profile becomes a real local progress and settings tab.

Real data:

- Display name is editable.
- Level and XP are derived from saved entries and streak.
- Badges are derived from milestones.
- Active quests come from `QuestStore`.
- Stats use entry count, streak, local circles, and most common emotion.
- Settings show real local controls only: display name, reset local onboarding/name if needed, privacy summary, local data summary.

No hard-coded `Level 4`, `4 circles`, fake support quest, or “coming next” card.

## Quest Workflow

Quests are local actions tied to the journaling loop.

Behavior:

- When a reflection is saved, create or refresh a suggested quest from the reflection result.
- User can mark quests complete or skip them.
- Completed quest count contributes to XP.
- Quests persist locally.

Quest copy should be practical and short.

## Data Persistence

Continue using UserDefaults JSON for this MVP:

- Existing reflection storage remains unchanged.
- New stores get versioned keys.
- Stores should be idempotent when seeding starter data.
- Derived progress does not need persistence because it can be recalculated.

## Architecture

Keep SwiftUI and ObservableObject stores.

Recommended file responsibilities:

- `App/Models/PinguModels.swift`: shared local domain structs and enums.
- `App/Engines/ProgressEngine.swift`: pure calculations for level, XP, streak, badges, emotion mix.
- `App/Stores/CircleStore.swift`: local circles and posts.
- `App/Stores/QuestStore.swift`: local quests and completion state.
- Existing `ReflectionJournalStore` remains the source of saved reflection truth.
- Existing `UserProfileStore` remains the profile source of truth.

Views should stay focused on layout and user interaction.

## Testing

Automated verification:

- Build iPhone 17 Pro simulator.
- Build generic iOS device.
- Build connected iPhone when available.

Manual phone test:

1. Fresh install and complete onboarding.
2. Save a typed or voice reflection.
3. Confirm Home updates latest reflection, level, streak, and quest.
4. Open Journal and confirm the saved entry appears and detail is complete.
5. Open Circle, create a circle, add a support note, and share latest reflection.
6. Confirm Circle card post count and last activity update.
7. Open Profile and confirm level, XP, badges, stats, and quests use real data.
8. Complete or skip a quest and confirm Profile/Home update.

## Success Criteria

This pass succeeds when:

- No tab depends on fake sample data for its primary content.
- Circle and Profile provide real local workflows.
- Models/stores/engines make the app easier to extend.
- Backend-dependent features are honestly represented as local-only for now.
- Existing recording and reflection flow still builds and works.
