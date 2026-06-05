# Local-First Real Workflows Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace remaining placeholder tab content with local model-backed workflows for Circle, Profile, Home, and quests.

**Architecture:** Keep the existing SwiftUI app and ObservableObject stores. Add a small local domain model layer, pure progress calculations, and UserDefaults-backed stores for circles and quests. Views consume real stores and derived snapshots instead of sample arrays.

**Tech Stack:** SwiftUI, Combine, Foundation, UserDefaults JSON persistence, Xcode iOS builds.

---

## File Structure

- Modify `Circleu/App/PinguModels.swift`: replace old sample structs with local domain structs and enums.
- Create `Circleu/App/ProgressEngine.swift`: pure progress, streak, badge, and emotion calculations.
- Create `Circleu/App/CircleStore.swift`: UserDefaults-backed local circles and posts.
- Create `Circleu/App/QuestStore.swift`: UserDefaults-backed local quest lifecycle.
- Modify `Circleu/App/ContentView.swift`: inject new stores.
- Modify `Circleu/App/RootView.swift`: consume `ProgressEngine` and pass new workflows into tabs.
- Modify `Circleu/View/Home/HomeView.swift`: show real active quest and derived progress.
- Modify `Circleu/View/Circle/CircleView.swift`: replace static/fake groups with local circles, creation, notes, and reflection sharing.
- Modify `Circleu/View/Profile/ProfileView.swift`: replace hard-coded progress and fake quests with real progress, badges, settings, and quest actions.
- Modify `Circleu/View/Reflection/ReflectionView.swift`: create a local quest when a reflection is saved.
- Modify `Circleu/View/Recording/SaveConfirmationView.swift`: keep behavior compatible with quest creation.
- Modify `docs/phone-test-checklist.md`: add local workflow checks.

## Task 1: Domain Models

**Files:**
- Modify: `Circleu/App/PinguModels.swift`

- [ ] **Step 1: Replace old sample data with local app domain types**

Define:

```swift
enum QuestStatus: String, Codable, Equatable {
    case active
    case completed
    case skipped
}

struct Quest: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var detail: String
    var sourceEntryID: UUID?
    var createdAt: Date
    var completedAt: Date?
    var status: QuestStatus
}

struct CircleSpace: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var intention: String
    var createdAt: Date
}

struct CirclePost: Identifiable, Codable, Equatable {
    let id: UUID
    var circleID: UUID
    var createdAt: Date
    var title: String
    var body: String
    var sourceEntryID: UUID?
}

struct ProgressBadge: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let isUnlocked: Bool
}

struct AppProgressSnapshot: Equatable {
    var entryCount: Int
    var streak: Int
    var level: Int
    var xp: Int
    var xpForNextLevel: Int
    var mostCommonEmotion: String
    var completedQuestCount: Int
    var badges: [ProgressBadge]
}
```

- [ ] **Step 2: Build**

Run: `xcodebuild -project Circleu.xcodeproj -scheme Circleu -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -configuration Debug build`

Expected: old sample data references fail if any views still depend on them. Remove those references in later tasks.

## Task 2: Progress Engine

**Files:**
- Create: `Circleu/App/ProgressEngine.swift`

- [ ] **Step 1: Add pure progress calculations**

Create a `ProgressEngine` with:

```swift
enum ProgressEngine {
    static func snapshot(entries: [JournalReflectionEntry], quests: [Quest]) -> AppProgressSnapshot
    static func streak(from entries: [JournalReflectionEntry], calendar: Calendar = .current) -> Int
    static func level(entryCount: Int, completedQuestCount: Int, streak: Int) -> Int
    static func xp(entryCount: Int, completedQuestCount: Int, streak: Int) -> Int
}
```

Rules:

- XP = `entryCount * 30 + completedQuestCount * 20 + streak * 10`.
- Level = `max(1, min(12, xp / 100 + 1))`.
- `xpForNextLevel` = `max(100, level * 100)`.
- Streak counts consecutive calendar days with at least one entry, including today or yesterday as the starting day.
- Emotion defaults to `"None"` when there are no entries.
- Badges unlock at first reflection, three reflections, seven-day streak, and three completed quests.

- [ ] **Step 2: Build**

Run the iPhone 17 Pro simulator build.

Expected: build succeeds after any imports are fixed.

## Task 3: Quest Store

**Files:**
- Create: `Circleu/App/QuestStore.swift`

- [ ] **Step 1: Add local quest persistence**

Create `@MainActor final class QuestStore: ObservableObject` with:

- `@Published private(set) var quests: [Quest]`
- `func addSuggestedQuest(from entry: JournalReflectionEntry)`
- `func complete(_ quest: Quest)`
- `func skip(_ quest: Quest)`
- `func delete(_ quest: Quest)`

Behavior:

- Do not create duplicate quests for the same `sourceEntryID`.
- New reflection quest title is `"Try this next"`.
- Detail comes from `entry.result.suggestedQuest`.
- Completed and skipped quests update `status` and `completedAt`.
- Persist to `circleu.quests.v1` with ISO8601 dates.

- [ ] **Step 2: Build**

Run the simulator build.

Expected: build succeeds.

## Task 4: Circle Store

**Files:**
- Create: `Circleu/App/CircleStore.swift`

- [ ] **Step 1: Add local private circle persistence**

Create `@MainActor final class CircleStore: ObservableObject` with:

- `@Published private(set) var circles: [CircleSpace]`
- `@Published private(set) var posts: [CirclePost]`
- `func createCircle(name: String, intention: String)`
- `func addNote(circle: CircleSpace, title: String, body: String)`
- `func share(entry: JournalReflectionEntry, to circle: CircleSpace)`
- `func posts(for circle: CircleSpace) -> [CirclePost]`
- `func lastActivity(for circle: CircleSpace) -> Date?`
- `func deleteCircle(_ circle: CircleSpace)`

Behavior:

- Seed two private starter spaces only when storage is empty: `Reflection Tips` and `Encouragement Notes`.
- Do not use member counts.
- Persist to `circleu.circles.v1` and `circleu.circlePosts.v1`.

- [ ] **Step 2: Build**

Run the simulator build.

Expected: build succeeds.

## Task 5: Inject Stores And Progress

**Files:**
- Modify: `Circleu/App/ContentView.swift`
- Modify: `Circleu/App/RootView.swift`
- Modify: `Circleu/App/PinguDesign.swift`

- [ ] **Step 1: Inject stores**

Add `@StateObject private var circleStore = CircleStore()` and `@StateObject private var questStore = QuestStore()` in `ContentView`, then inject both as environment objects.

- [ ] **Step 2: Use progress snapshot**

In `RootView`, compute:

```swift
private var progress: AppProgressSnapshot {
    ProgressEngine.snapshot(entries: journalStore.entries, quests: questStore.quests)
}
```

Use `progress.level` and `progress.streak` for top bar values.

- [ ] **Step 3: Build**

Run the simulator build.

Expected: build succeeds and previews may require new environment objects.

## Task 6: Save Reflection Creates Quest

**Files:**
- Modify: `Circleu/View/Reflection/ReflectionView.swift`

- [ ] **Step 1: Add quest creation on save**

Inject `@EnvironmentObject private var questStore: QuestStore` and after `journalStore.add(entry)` call `questStore.addSuggestedQuest(from: entry)`.

- [ ] **Step 2: Build**

Run the simulator build.

Expected: build succeeds.

## Task 7: Home Real Quest Surface

**Files:**
- Modify: `Circleu/View/Home/HomeView.swift`

- [ ] **Step 1: Add quest store and progress snapshot**

Show the first active quest when one exists. If no active quest exists, show a real empty action card inviting the user to record the next reflection.

- [ ] **Step 2: Replace local streak helper**

Use `ProgressEngine.snapshot` instead of duplicate streak logic.

- [ ] **Step 3: Build**

Run the simulator build.

Expected: Home compiles and all metrics are derived.

## Task 8: Circle Real Local Workflow

**Files:**
- Replace main body in: `Circleu/View/Circle/CircleView.swift`

- [ ] **Step 1: Replace static groups with local circles**

Use `CircleStore.circles` and show cards with circle name, intention, post count, and last activity.

- [ ] **Step 2: Add circle creation sheet**

Fields: circle name and intention. Save button calls `circleStore.createCircle`.

- [ ] **Step 3: Add circle detail sheet**

Show posts for the circle, add a support note, and share latest reflection when `journalStore.entries.first` exists.

- [ ] **Step 4: Build**

Run the simulator build.

Expected: no fake member counts or discovery cards remain.

## Task 9: Profile Real Progress

**Files:**
- Modify: `Circleu/View/Profile/ProfileView.swift`

- [ ] **Step 1: Replace hard-coded progress**

Use `ProgressEngine.snapshot` for level, XP, streak, entries, circles, most common emotion, and badges.

- [ ] **Step 2: Replace active quests**

Use `QuestStore.quests`, showing active quest rows with complete and skip buttons.

- [ ] **Step 3: Replace coming-next card**

Show a local data card with privacy summary, saved entries, local circles, and completed quests.

- [ ] **Step 4: Build**

Run the simulator build.

Expected: no hard-coded level, fake circle count, fake quest, or coming-next copy remains.

## Task 10: Documentation And Verification

**Files:**
- Modify: `docs/phone-test-checklist.md`

- [ ] **Step 1: Add local workflow manual checks**

Add steps for creating circles, adding notes, sharing reflections, completing/skipping quests, and verifying profile progress.

- [ ] **Step 2: Run final builds**

Run:

```bash
xcodebuild -project Circleu.xcodeproj -scheme Circleu -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -configuration Debug build
xcodebuild -project Circleu.xcodeproj -scheme Circleu -sdk iphoneos -destination 'generic/platform=iOS' -configuration Debug -allowProvisioningUpdates build
xcodebuild -project Circleu.xcodeproj -scheme Circleu -sdk iphoneos -destination 'platform=iOS,name=UTS - GK2WN790NV' -configuration Debug -allowProvisioningUpdates build
```

Expected: all builds exit 0.

## Self-Review

Spec coverage:

- Model/store organization: Tasks 1-5.
- Real Circle workflow: Task 8.
- Real Profile workflow: Task 9.
- Quest workflow: Tasks 3, 6, 7, 9.
- Home data connection: Task 7.
- Documentation and verification: Task 10.

Placeholder scan:

- No task leaves a feature as future-only.
- Backend and real community remain explicitly out of scope.

Type consistency:

- `Quest`, `CircleSpace`, `CirclePost`, `ProgressBadge`, and `AppProgressSnapshot` are introduced before stores and views consume them.
