# Circleu Documentation

This folder holds the current project knowledge the team should follow while building, testing, and presenting Circleu.

## Start Here

1. [Product overview](product/overview.md)
2. [App flow](product/app-flow.md)
3. [Project structure](engineering/project-structure.md)
4. [Architecture](engineering/architecture.md)
5. [Domain models](engineering/domain-models.md)
6. [Backend boundaries](engineering/backend-boundaries.md)
7. [Backend roadmap](engineering/backend-roadmap.md)
8. [Firebase backend plan](engineering/firebase-backend-plan.md)
9. [CloudKit data model](engineering/cloudkit-data-model.md)
10. [Phone test checklist](qa/phone-test-checklist.md)
11. [Git workflow](process/git-workflow.md)
12. [Team standards](process/team-standards.md)

## Folder Map

- `product/`: what the app is, who it serves, and how the user flow works.
- `engineering/`: architecture, source ownership, domain language, backend boundaries, and technical decisions.
- `qa/`: repeatable manual checks for simulator and real-phone testing.
- `process/`: Git workflow, commit standards, branch rules, and collaboration norms.
- `archive/`: historical plans and specs. Archived files are reference material, not current instructions.

## Documentation Standard

Keep active docs short, current, and action-oriented. A current doc should answer what the team should do now; historical implementation notes belong in `archive/`.

When behavior, architecture, or process changes, update the matching active doc in the same commit. If a doc is important for new contributors, link it from this index and from the root `README.md`.
