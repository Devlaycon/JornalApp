# Circleu Team Standards

These rules keep the repo understandable for teammates and future contributors.

## Branch Rules

Use `main` as the stable branch. Do feature work on a personal or feature branch.

```bash
git checkout main
git fetch origin
git merge origin/main
git checkout -b feat/journal-circle-sharing
```

Before pushing a feature branch, merge the latest `main` and resolve conflicts locally.

```bash
git fetch origin
git merge origin/main
```

## Commit By Function

Commit one working function, fix, refactor, or doc update at a time. Do not commit random unrelated files together.

Good commit messages:

```text
feat: add journal circle sharing
fix: handle empty transcript fallback
refactor: move profile qa tools into feature folder
docs: reorganize project documentation
test: add tips practice flow coverage
```

Bad commit messages:

```text
update files
final changes
fix stuff
commit all
```

## Professional Commit Commands

Review the repo before staging:

```bash
git status --short
git diff
```

Stage by function, not by habit:

```bash
git add Circleu/Features/Journal
git add Circleu/Stores/ReflectionJournalStore.swift
git commit -m "feat: add journal circle sharing"
```

For docs-only work:

```bash
git status --short
git diff -- docs README.md
git add docs README.md
git commit -m "docs: reorganize project documentation"
```

For a bug fix:

```bash
git diff -- Circleu/Features/Recording Circleu/Engines/TranscriptQuality.swift
git add Circleu/Features/Recording Circleu/Engines/TranscriptQuality.swift
git commit -m "fix: handle short transcript validation"
```

Avoid `git add .` unless you have already reviewed every changed file in `git status --short`.

## Verification Before Commit

Run the smallest useful check for the change:

- Docs only: review `git diff -- docs README.md`.
- ViewModel, Store, or Engine behavior: run unit tests.
- SwiftUI or app integration change: run an iPhone simulator build.
- Microphone, speech, signing, Apple Intelligence, or real-device behavior: run the phone checklist.

Useful commands:

```bash
xcodebuild build -project Circleu.xcodeproj -scheme Circleu -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
xcodebuild test -project Circleu.xcodeproj -scheme Circleu -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## File Ownership Rules

- `Circleu/Features/`: user-facing screens and feature-specific ViewModels.
- `Circleu/Components/`: reusable UI shared by multiple features.
- `Circleu/Design/`: colors, spacing, typography, and layout constants.
- `Circleu/Models/`: Codable domain models and value types.
- `Circleu/Stores/`: shared app state and local persistence.
- `Circleu/Engines/`: business logic and AI/reflection logic.
- `Circleu/Services/`: device APIs and future backend/provider boundaries.
- `CircleuTests/`: behavior tests for ViewModels, Stores, Engines, and data flow.
- `docs/`: living project knowledge and archived planning history.

## Documentation Rules

Update docs in the same commit as the behavior or process change when the docs would otherwise become misleading.

Use these locations:

- Product/user-flow docs: `docs/product/`
- Architecture/domain docs: `docs/engineering/`
- Manual QA docs: `docs/qa/`
- Team process docs: `docs/process/`
- Historical plans/specs: `docs/archive/`

Keep archived docs unchanged unless you are fixing broken links for readability. Current team rules should live in active docs, not in archived implementation plans.

## Pull And Push Rules

Check status before pushing:

```bash
git status --short --branch
```

Push the current branch:

```bash
git push origin HEAD
```

Do not push broken builds or unrelated cleanup mixed with feature work. If a commit includes app code, be ready to say what verification you ran.
