# Tips and Communities Refinement Design

## Goal

Refine the Tips and Circle tabs so they feel aligned with the Figma-inspired direction: Tips is a tips coaching surface, and Circle is a community/support surface. The bottom tab name remains `Tips`.

## Scope

- Keep the existing local-first architecture.
- Reuse `QuestStore`, `CircleStore`, `ReflectionJournalStore`, and existing models.
- Do not add backend or authentication in this pass.
- Avoid placeholder actions: visible controls should complete, skip, restart, record, open a reflection, create a community, save a note, or share an existing reflection.

## Tips Tab

The Tips tab should read as a coaching workspace, not a generic quest list. The top area introduces a "Tips Coach" concept and uses Figma-inspired blue cards, rounded controls, tone/context chips, and clear guidance. The screen keeps the active quest workflow because it is already connected to AI reflections. Completed and skipped sections remain, but their copy should refer to tips.

## Circle Tab

The Circle tab should read as communities while keeping local storage. User-facing copy should use "community" where possible, with "local/private" messaging so the app does not imply live backend group chat. Cards should show purpose, saved posts, latest activity, and the connection to shared reflections.

## Verification

- Build the app for an iOS Simulator destination.
- Confirm the tab label remains `Tips`.
- Confirm no new backend dependency is introduced.
