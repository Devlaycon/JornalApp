# Daily Practice Loop Design

## Goal

Make Circleu feel like a working daily practice product after demo seeding or a real recording: reflection leads to a quest, the quest can be completed or skipped, and the user can save useful insights into private circles.

## Scope

This slice stays local-first. It does not add backend accounts, cloud sync, analytics, or multiplayer circle membership. The app should remain testable on a connected iPhone with seeded demo data or with a fresh user-created reflection.

## Product Flow

1. The user opens Home and sees the latest reflection, progress, and the active next action.
2. If there is an active quest, Home shows the source reflection, quest age, complete and skip actions, and a way to open the source reflection.
3. If the user opens a journal detail, they can copy or share the reflection, create or update the follow-up quest, and save the reflection to a private circle.
4. If the user saves to a circle, the app presents real local circle choices and prevents duplicate shares into the same circle.
5. Completing or skipping a quest immediately updates Home and Profile progress because `QuestStore` remains the source of truth.

## Architecture

The implementation keeps business state in stores and adds small workflow UI components close to the feature that uses them. `QuestStore` owns quest lookup and activation. `CircleStore` owns duplicate share checks. Journal detail coordinates cross-feature actions through environment stores without adding navigation complexity to `RootView`.

## Error Handling

Empty states stay actionable: no quest prompts the user to record; no circles prompts the user to create a private circle from the Circles tab; no reflections disables share actions. Duplicate circle shares show disabled state instead of creating repeated posts.

## Testing

Verification uses deterministic demo data, a placeholder scan, an iPhone 17 Pro simulator build, and a connected iPhone build. Manual phone testing should confirm seed data, quest completion, quest skipping, journal detail actions, and circle share behavior.
