# Release Ready Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prepare Circleu's `dev/mike` branch for first push by splitting oversized SwiftUI files, keeping the local-first MVP behavior intact, and verifying simulator plus connected iPhone builds.

**Architecture:** Keep stores and engines unchanged except for compiler fixes. Move reusable controls into `Components`, feature-specific sheets into their owning feature folders, and keep top-level feature views focused on screen layout and navigation.

**Tech Stack:** SwiftUI, Combine observable stores, UserDefaults persistence, Xcode iOS simulator/device builds, Git.

---

### Task 1: Shared Form Control

**Files:**
- Create: `Circleu/Components/PinguFormControls.swift`
- Modify: `Circleu/Features/Circle/CircleView.swift`

- [ ] Move `PinguTextInput` out of `CircleView.swift` into `PinguFormControls.swift`.
- [ ] Keep the API identical: `title`, `placeholder`, `text`, and optional `axis`.
- [ ] Build to confirm all circle sheets still compile.

### Task 2: Journal Share Sheet Split

**Files:**
- Create: `Circleu/Features/Journal/JournalCircleShareSheet.swift`
- Modify: `Circleu/Features/Journal/JournalEntryDetailView.swift`

- [ ] Move `JournalCircleShareSheet` into its own file.
- [ ] Keep `JournalEntryDetailView` responsible for showing the sheet.
- [ ] Build to confirm journal detail actions still compile.

### Task 3: Profile QA Tools Split

**Files:**
- Create: `Circleu/Features/Profile/ProfileQAToolsSheet.swift`
- Modify: `Circleu/Features/Profile/ProfileView.swift`

- [ ] Move `ProfileQAToolsSheet` and its helper cards into the new profile-specific file.
- [ ] Keep Profile screen responsible for presenting the sheet.
- [ ] Build to confirm QA seed/reset/export controls still compile.

### Task 4: Circle Sheet Split

**Files:**
- Create: `Circleu/Features/Circle/CircleSheets.swift`
- Modify: `Circleu/Features/Circle/CircleView.swift`

- [ ] Move circle create, detail, edit, reflection picker, post edit, and post card helper views into `CircleSheets.swift`.
- [ ] Keep `CircleView` responsible for list layout and sheet presentation.
- [ ] Build to confirm circle creation, notes, edits, and reflection sharing still compile.

### Task 5: Release Notes And Verification

**Files:**
- Create: `docs/release-readiness.md`
- Modify: `docs/project-structure.md`

- [ ] Document the first-push branch state and manual phone QA flow.
- [ ] Run placeholder scan.
- [ ] Run iPhone 17 Pro simulator build.
- [ ] Run connected iPhone build.
- [ ] Stage the app cleanup changes, commit, and push `dev/mike` to origin.
