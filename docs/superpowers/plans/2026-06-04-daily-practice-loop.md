# Daily Practice Loop Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a local-first daily practice loop where reflections create actionable quests and useful insights can be saved into private circles.

**Architecture:** Stores remain the source of truth. `QuestStore` adds lookup and activation helpers, `CircleStore` adds duplicate-share helpers, Home surfaces quest context, and Journal detail becomes the place to act on one reflection.

**Tech Stack:** SwiftUI, Combine observable stores, UserDefaults JSON persistence, Xcode iOS builds.

---

### Task 1: Store Helpers

**Files:**
- Modify: `Circleu/Stores/QuestStore.swift`
- Modify: `Circleu/Stores/CircleStore.swift`

- [ ] Add `QuestStore.quest(for:)`, `activeQuest(for:)`, and `activateSuggestedQuest(from:)` so views can find or recreate the local next action for a reflection.
- [ ] Add `CircleStore.hasShared(entry:to:)` so journal and circle sharing surfaces can prevent duplicate local posts.
- [ ] Build the app to catch model or actor-isolation mistakes.

### Task 2: Home Quest Context

**Files:**
- Modify: `Circleu/Features/Home/HomeView.swift`

- [ ] Replace the simple active quest card with a richer daily practice card.
- [ ] Show source reflection title, quest age, and complete/skip actions when a quest exists.
- [ ] Add an action to open the source reflection from Home when the quest is tied to an entry.
- [ ] Keep the no-quest state focused on recording the next reflection.

### Task 3: Journal Detail Actions

**Files:**
- Modify: `Circleu/Features/Journal/JournalEntryDetailView.swift`

- [ ] Inject `QuestStore` and `CircleStore` into the detail view.
- [ ] Add an action card below the reflection details.
- [ ] Let users activate, complete, or skip the quest tied to the open reflection.
- [ ] Let users save the reflection to a private circle from the journal detail.
- [ ] Keep copy, share, and delete actions in the toolbar.

### Task 4: Circle Share Picker

**Files:**
- Modify: `Circleu/Features/Journal/JournalEntryDetailView.swift`

- [ ] Add a focused `JournalCircleShareSheet`.
- [ ] Show available circle spaces with duplicate-share disabled state.
- [ ] Save the selected reflection into the selected circle through `CircleStore.share(entry:to:)`.
- [ ] Show a clear empty state when no circles exist.

### Task 5: Docs And Verification

**Files:**
- Modify: `docs/phone-test-checklist.md`
- Modify: `docs/app-flow.md`

- [ ] Add manual test steps for Home quest context, journal quest actions, and journal-to-circle sharing.
- [ ] Run a placeholder scan.
- [ ] Run an iPhone 17 Pro simulator build.
- [ ] Run a connected iPhone build.
