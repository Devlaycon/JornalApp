# Circleu Git Workflow

Use small, reviewable commits by default. Each commit should represent one clear function, feature slice, refactor, or documentation update.

## Commit Scope

Prefer commits like:

- `feat: add journal-to-circle sharing`
- `feat: add daily practice quest flow`
- `refactor: split profile qa tools`
- `refactor: move shared form controls`
- `docs: add phone test checklist`
- `chore: remove unused placeholder files`

Avoid mixing unrelated work in one commit. A UI refactor, a model change, a doc update, and a build setting change should be separate commits unless they are required together for one working slice.

## Functional Slice Rule

A commit should answer one of these questions:

- What user-facing function did this add or improve?
- What internal structure did this clean up?
- What bug or build issue did this fix?
- What documentation did this clarify?

If the answer needs "and then also," split the commit.

## Before Committing

Run the smallest useful verification for the change:

- SwiftUI or store-only changes: run an iPhone simulator build.
- Device, signing, microphone, or speech changes: run a connected iPhone build.
- Documentation-only changes: run a quick status/diff review.
- Release or push-ready changes: run placeholder scan, simulator build, and connected iPhone build.

## Commit Message Format

Use this format:

```text
type: short imperative summary
```

Common types:

- `feat`: user-facing feature or workflow
- `fix`: bug fix
- `refactor`: structure change without intended behavior change
- `docs`: documentation only
- `chore`: cleanup, project metadata, or maintenance

## Push Rule

Push after a coherent set of commits is ready for teammate review. Do not wait until many unrelated features pile up.

## First MVP Exception

The commit `02078f3 feat: prepare local-first MVP` was a one-time consolidation commit because the first MVP branch already had many uncommitted app, asset, store, and doc changes. Future work should return to functional-slice commits.
