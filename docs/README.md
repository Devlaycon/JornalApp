# Circleu Documentation

Use this folder for shared project knowledge that helps the team build, test, and maintain Circleu.

## Start Here

1. [Product overview](product/overview.md)
2. [App flow](product/app-flow.md)
3. [Project structure](engineering/project-structure.md)
4. [Architecture](engineering/architecture.md)
5. [Domain models](engineering/domain-models.md)
6. [Backend boundaries](engineering/backend-boundaries.md)
7. [Backend roadmap](engineering/backend-roadmap.md)
8. [Phone test checklist](qa/phone-test-checklist.md)
9. [Team standards](process/team-standards.md)

## Folder Rules

- `product/`: what the app is, who it serves, and how the user flow works.
- `engineering/`: source ownership, architecture boundaries, domain language, and technical decisions.
- `qa/`: manual test flows, phone checks, and repeatable demo/testing steps.
- `process/`: Git workflow, commit standards, branch rules, and team conventions.
- `archive/`: historical plans and specs. Do not treat archived files as current instructions unless a current doc links to them.

## Documentation Standard

Keep active docs short and current. If a doc describes the product or engineering rules the team should still follow, keep it in `product/`, `engineering/`, `qa/`, or `process/`. If a doc describes a completed implementation plan, old design exploration, or one-time agent workflow, move it to `archive/`.

When adding or moving docs, update this index and the root [README](../README.md) if the doc is important for new contributors.
