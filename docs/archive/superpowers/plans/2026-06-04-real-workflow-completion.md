# Real Workflow Completion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the remaining runtime placeholders and make Circleu's local-first workflows feel complete enough to test on a real iPhone.

**Architecture:** Keep the app local-first with SwiftUI views backed by ObservableObject stores. Add small store methods for editing, deleting, and export/share text so views do not hide business logic inside UI handlers.

**Tech Stack:** SwiftUI, UserDefaults persistence, Xcode synchronized project root, iOS simulator/device builds.

---

### Task 1: Store Capabilities

**Files:**
- Modify: `Circleu/Stores/CircleStore.swift`
- Modify: `Circleu/Stores/ReflectionJournalStore.swift`
- Modify: `Circleu/Stores/UserProfileStore.swift`

- [ ] Add edit/delete methods for circles and posts.
- [ ] Add reusable export/share text for journal entries.
- [ ] Add profile summary export text.

### Task 2: Circle Workflows

**Files:**
- Modify: `Circleu/Features/Circle/CircleView.swift`

- [ ] Replace future-backend copy with local-first privacy copy.
- [ ] Add circle editing.
- [ ] Add a reflection picker before sharing.
- [ ] Add delete actions for saved posts.
- [ ] Disable invalid form submissions instead of silently using generic fallbacks.

### Task 3: Journal And Reflection Actions

**Files:**
- Modify: `Circleu/Features/Journal/JournalView.swift`
- Modify: `Circleu/Features/Journal/JournalEntryDetailView.swift`
- Modify: `Circleu/Features/Reflection/ReflectionView.swift`

- [ ] Add copy/share/export actions to journal rows and details.
- [ ] Add delete from detail.
- [ ] Replace runtime preview fallback with an explicit empty reflection state.

### Task 4: Profile Local Controls

**Files:**
- Modify: `Circleu/Features/Profile/ProfileView.swift`

- [ ] Add local summary export/share.
- [ ] Add clearer privacy/storage controls.
- [ ] Keep data destructive actions out of this batch unless there is a confirmation UI.

### Task 5: Verification

**Files:**
- Build project.

- [ ] Run placeholder scan.
- [ ] Run iPhone 17 Pro simulator build.
- [ ] Report remaining non-runtime preview references separately.
