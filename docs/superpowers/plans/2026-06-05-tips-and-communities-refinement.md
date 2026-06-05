# Tips and Communities Refinement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refine the existing Tips and Circle tabs into a native Tips Coach and Communities experience while preserving local-first workflows.

**Architecture:** This is a SwiftUI view refinement over existing stores. `TipsView` remains the implementation behind the `Tips` tab, `CircleView` and `CircleSheets` remain backed by `CircleStore`, and no new backend or persistence layer is introduced.

**Tech Stack:** SwiftUI, Combine, UserDefaults-backed local stores, Xcode iOS build.

---

### Task 1: Refine Tips Screen

**Files:**
- Modify: `Circleu/Features/Tips/TipsView.swift`

- [ ] **Step 1: Update screen copy and hierarchy**

Change the header from generic tips language to Tips Coach language while keeping the tab name controlled by `RootView`.

- [ ] **Step 2: Add a coach preview card**

Add a real local action card that explains how to use the tab and routes users to recording or the current active tips.

- [ ] **Step 3: Retain functional quest actions**

Keep complete, skip, restart, reflection open, and record actions wired to the current stores and callbacks.

### Task 2: Refine Communities Screen

**Files:**
- Modify: `Circleu/Features/Circle/CircleView.swift`
- Modify: `Circleu/Features/Circle/CircleSheets.swift`
- Modify: `Circleu/Stores/CircleStore.swift`

- [ ] **Step 1: Update Circle landing copy**

Make the screen read as private communities, with summary tiles and cards that explain purpose and activity.

- [ ] **Step 2: Update sheets and empty states**

Use community wording in create, edit, detail, share, and local privacy explanations.

- [ ] **Step 3: Refresh starter data**

Rename starter spaces so new installs see community-oriented examples.

### Task 3: Verify

**Files:**
- No code changes.

- [ ] **Step 1: Build the app**

Run: `xcodebuild -project Circleu.xcodeproj -scheme Circleu -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`

Expected: build succeeds.

- [ ] **Step 2: Check git status**

Run: `git status --short --branch`

Expected: only intentional documentation and SwiftUI refinement files changed.
