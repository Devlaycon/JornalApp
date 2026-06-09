# Reproducible Phone-Test MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add local QA controls so Circleu can be reset, seeded, exported, and tested reproducibly on a real iPhone.

**Architecture:** Keep all data local. Add deterministic seed/reset APIs to the existing stores, then expose them from a Profile QA sheet. Use existing export text APIs and app bundle metadata for reproducible testing context.

**Tech Stack:** SwiftUI, UserDefaults-backed stores, local Codable models, Xcode simulator/device builds.

---

### Task 1: Store Reset And Seed APIs

**Files:**
- Modify: `Circleu/Stores/ReflectionJournalStore.swift`
- Modify: `Circleu/Stores/CircleStore.swift`
- Modify: `Circleu/Stores/QuestStore.swift`
- Modify: `Circleu/Stores/UserProfileStore.swift`

- [ ] Add `reset()` methods that clear local state and persisted UserDefaults keys.
- [ ] Add deterministic demo seed methods for profile, reflections, quests, circles, and posts.
- [ ] Keep seed data realistic and clearly local.

### Task 2: Profile QA Sheet

**Files:**
- Modify: `Circleu/Features/Profile/ProfileView.swift`

- [ ] Add a QA button/card in Profile.
- [ ] Add a sheet with app build info, current local data counts, export actions, seed demo data, and reset local data.
- [ ] Use confirmation dialogs for destructive reset actions.

### Task 3: Reproducibility Docs

**Files:**
- Modify: `docs/phone-test-checklist.md`
- Modify: `docs/project-structure.md`

- [ ] Document the local QA flow.
- [ ] Explain where QA-only controls live.
- [ ] Keep docs short enough for teammates to follow while testing on phone.

### Task 4: Verification

- [ ] Scan for accidental placeholder/debug copy.
- [ ] Build iPhone 17 Pro simulator.
- [ ] Build generic iOS device.
