# Daily Reflection Beta v1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first real-life AI beta loop: onboarding -> Home daily hub -> record/type reflection -> AI result -> Journal save/edit -> Practice action -> local sharing and phone-test verification.

**Architecture:** Keep Circleu local-first. Add small model/store/engine improvements for testable workflow state, then wire SwiftUI screens through existing feature folders. Reuse the current `Models`, `Stores`, `Engines`, `Services`, `Features`, `Components`, and `Design` structure without a large repo restructure.

**Tech Stack:** Swift 5, SwiftUI, Combine, UserDefaults JSON persistence, AVFoundation/Speech, XCTest when a test target is added, Xcode project build verification.

---

## File Map

Modify:

- `Circleu/Components/PinguComponents.swift`: add `practice` tab, reusable status/action components if needed.
- `Circleu/App/RootView.swift`: route the new Practice tab and support cross-tab navigation from reflection results.
- `Circleu/Features/Home/HomeView.swift`: refine daily hub and route active practice to Practice.
- `Circleu/Features/Onboarding/Onboarding.swift`: make onboarding cover privacy, preferences, and permission education more clearly.
- `Circleu/Features/Recording/RecordingView.swift`: tighten capture states and pass practice navigation intent after saving.
- `Circleu/Features/Reflection/ReflectionView.swift`: make Save, Regenerate, and Start Practice clear next actions.
- `Circleu/Features/Journal/JournalView.swift`: use edited display fields in rows and search.
- `Circleu/Features/Journal/JournalEntryDetailView.swift`: resolve sessions more robustly and make Practice actions link to the new Practice workflow.
- `Circleu/Features/Circle/CircleView.swift`: make local-only sharing status explicit and useful.
- `Circleu/Features/Profile/ProfileView.swift`: align active quest/practice language with the new Practice tab.
- `Circleu/Stores/QuestStore.swift`: add computed practice collections and safer activation/completion helpers.
- `Circleu/Engines/ProgressEngine.swift`: verify progress handles practice completion cleanly.
- `docs/phone-test-checklist.md`: update with the beta v1 end-to-end flow.
- `docs/app-flow.md`: document the connected beta workflow.
- `docs/project-structure.md`: note the Practice feature folder and workflow ownership.

Create:

- `Circleu/Features/Practice/PracticeView.swift`: dedicated Practice tab for active, completed, and skipped AI-suggested practices.
- `Circleu/Engines/DailyReflectionBetaState.swift`: small pure Swift helpers for daily status, practice progress, and next-action text.
- `CircleuTests/DailyReflectionBetaStateTests.swift`: behavior tests for the new pure logic, if test target setup is practical in the current Xcode project.

Optional if project test target setup is too large for this slice:

- `docs/testing-notes.md`: document why build + phone-flow verification is used until a test target is added.

---

### Task 1: Add Testable Beta State Helpers

**Files:**
- Create: `Circleu/Engines/DailyReflectionBetaState.swift`
- Optional Test: `CircleuTests/DailyReflectionBetaStateTests.swift`

- [ ] **Step 1: Create pure beta workflow helpers**

Add this file:

```swift
import Foundation

struct DailyReflectionBetaState: Equatable {
    let hasCompletedToday: Bool
    let nextActionTitle: String
    let nextActionSubtitle: String
    let practiceProgressText: String

    static func make(
        entries: [JournalReflectionEntry],
        quests: [Quest],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> DailyReflectionBetaState {
        let hasCompletedToday = entries.contains { calendar.isDate($0.createdAt, inSameDayAs: now) }
        let activePractice = quests.first { $0.status == .active }
        let completedCount = quests.filter { $0.status == .completed }.count

        if let activePractice {
            return DailyReflectionBetaState(
                hasCompletedToday: hasCompletedToday,
                nextActionTitle: "Continue today's practice",
                nextActionSubtitle: activePractice.detail,
                practiceProgressText: "\(completedCount) completed"
            )
        }

        if hasCompletedToday {
            return DailyReflectionBetaState(
                hasCompletedToday: true,
                nextActionTitle: "Reflect again if something changed",
                nextActionSubtitle: "You already saved a reflection today. Add another if a new moment needs attention.",
                practiceProgressText: "\(completedCount) completed"
            )
        }

        return DailyReflectionBetaState(
            hasCompletedToday: false,
            nextActionTitle: "Start today's reflection",
            nextActionSubtitle: "Record or type one honest check-in to create your next AI-guided practice.",
            practiceProgressText: "\(completedCount) completed"
        )
    }
}
```

- [ ] **Step 2: If a test target already exists or can be added safely, add tests**

Use these test cases:

```swift
import XCTest
@testable import Circleu

final class DailyReflectionBetaStateTests: XCTestCase {
    func testMakeReturnsReflectionPromptWhenNoEntriesOrQuestsExist() {
        let state = DailyReflectionBetaState.make(entries: [], quests: [], now: Date(timeIntervalSince1970: 1000))

        XCTAssertFalse(state.hasCompletedToday)
        XCTAssertEqual(state.nextActionTitle, "Start today's reflection")
        XCTAssertEqual(state.practiceProgressText, "0 completed")
    }

    func testMakePrioritizesActivePractice() {
        let quest = Quest(title: "Try this next", detail: "Take one slow breath before class.")

        let state = DailyReflectionBetaState.make(entries: [], quests: [quest], now: Date(timeIntervalSince1970: 1000))

        XCTAssertEqual(state.nextActionTitle, "Continue today's practice")
        XCTAssertEqual(state.nextActionSubtitle, "Take one slow breath before class.")
    }

    func testMakeCountsCompletedPractice() {
        let completed = Quest(
            title: "Completed practice",
            detail: "Write one sentence.",
            completedAt: Date(timeIntervalSince1970: 900),
            status: .completed
        )

        let state = DailyReflectionBetaState.make(entries: [], quests: [completed], now: Date(timeIntervalSince1970: 1000))

        XCTAssertEqual(state.practiceProgressText, "1 completed")
    }
}
```

- [ ] **Step 3: Verify build or tests**

Run one of:

```bash
xcodebuild test -project Circleu.xcodeproj -scheme Circleu -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Expected if test target exists: tests pass.

If there is no test target, run:

```bash
xcodebuild build -project Circleu.xcodeproj -scheme Circleu -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Expected: build succeeds.

- [ ] **Step 4: Commit**

```bash
git add Circleu/Engines/DailyReflectionBetaState.swift CircleuTests/DailyReflectionBetaStateTests.swift Circleu.xcodeproj/project.pbxproj
git commit -m "feat: add daily beta state helpers"
```

If no test target was added, stage only the helper file.

---

### Task 2: Add Dedicated Practice Tab

**Files:**
- Modify: `Circleu/Components/PinguComponents.swift`
- Modify: `Circleu/App/RootView.swift`
- Create: `Circleu/Features/Practice/PracticeView.swift`
- Modify: `Circleu/Stores/QuestStore.swift`

- [ ] **Step 1: Add `practice` to `PinguTab`**

Change the enum to:

```swift
enum PinguTab: String, CaseIterable {
    case home = "Home"
    case journal = "Journal"
    case practice = "Practice"
    case circle = "Circle"
    case profile = "Profile"

    var icon: String {
        switch self {
        case .home: "house.fill"
        case .journal: "book.closed.fill"
        case .practice: "checklist.checked"
        case .circle: "person.2.fill"
        case .profile: "person.crop.circle.fill"
        }
    }
}
```

- [ ] **Step 2: Add computed quest collections**

Add to `QuestStore`:

```swift
var completedQuests: [Quest] {
    quests.filter { $0.status == .completed }
}

var skippedQuests: [Quest] {
    quests.filter { $0.status == .skipped }
}

var latestActiveQuest: Quest? {
    activeQuests.first
}
```

- [ ] **Step 3: Create `PracticeView`**

Add a SwiftUI screen that:

- shows the active practice first,
- lets the user complete or skip it,
- shows completed practice history,
- shows skipped practices with a reactivate button,
- opens the source journal entry when available,
- has a real empty state that sends the user to recording.

Required public initializer:

```swift
struct PracticeView: View {
    let onStartRecording: () -> Void
    let onOpenJournalEntry: (JournalReflectionEntry) -> Void
}
```

- [ ] **Step 4: Wire Practice in `RootView`**

Add `@State private var selectedJournalEntry: JournalReflectionEntry?`.

In the tab switch:

```swift
case .practice:
    PracticeView(
        onStartRecording: { showRecording = true },
        onOpenJournalEntry: { selectedJournalEntry = $0 }
    )
```

Add a sheet for `selectedJournalEntry` using `JournalEntryDetailView(entry:)`.

Update `navigationTitle`, `navigationIcon`, and `navigationTrailing` for `.practice`.

- [ ] **Step 5: Verify build**

```bash
xcodebuild build -project Circleu.xcodeproj -scheme Circleu -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Expected: build succeeds and tab bar shows five tabs without text overlap.

- [ ] **Step 6: Commit**

```bash
git add Circleu/Components/PinguComponents.swift Circleu/App/RootView.swift Circleu/Features/Practice/PracticeView.swift Circleu/Stores/QuestStore.swift
git commit -m "feat: add practice tab workflow"
```

---

### Task 3: Refine Home As Daily Hub

**Files:**
- Modify: `Circleu/Features/Home/HomeView.swift`
- Modify: `Circleu/App/RootView.swift`

- [ ] **Step 1: Add Home route for Practice**

Change `HomeView` initializer to include:

```swift
let onOpenPractice: () -> Void
```

Update `RootView` call:

```swift
HomeView(
    onStartRecording: { showRecording = true },
    onOpenJournal: { selectedTab = .journal },
    onOpenPractice: { selectedTab = .practice }
)
```

- [ ] **Step 2: Use `DailyReflectionBetaState`**

Add a computed property in `HomeView`:

```swift
private var betaState: DailyReflectionBetaState {
    DailyReflectionBetaState.make(entries: journalStore.entries, quests: questStore.quests)
}
```

Use `betaState.nextActionTitle`, `betaState.nextActionSubtitle`, and `betaState.practiceProgressText` in the next-action card.

- [ ] **Step 3: Add an explicit Practice action**

When an active quest exists, add a primary button:

```swift
Button {
    onOpenPractice()
} label: {
    Label("Open Practice", systemImage: "checklist.checked")
}
.buttonStyle(HomeQuestButtonStyle(isPrimary: true))
```

Keep Complete and Skip available, but make Open Practice the main path.

- [ ] **Step 4: Verify build**

Run build command from Task 2.

- [ ] **Step 5: Commit**

```bash
git add Circleu/Features/Home/HomeView.swift Circleu/App/RootView.swift
git commit -m "feat: refine home daily beta hub"
```

---

### Task 4: Fix Journal Display/Search And Session Linking

**Files:**
- Modify: `Circleu/Features/Journal/JournalView.swift`
- Modify: `Circleu/Features/Journal/JournalEntryDetailView.swift`
- Modify: `Circleu/Stores/AIReflectionSessionStore.swift`

- [ ] **Step 1: Use edited display fields in Journal search**

In `filteredEntries`, replace raw title/emotion fields with:

```swift
entry.displayTitle,
entry.displayEmotion,
entry.displaySummary,
entry.privateNote,
entry.tags.joined(separator: " ")
```

Keep transcript, insight, quote, and engine name in the searchable text.

- [ ] **Step 2: Use edited display fields in Journal row**

Ensure `JournalEntryRow` displays:

```swift
entry.displayTitle
entry.displayEmotion
entry.displaySummary
```

- [ ] **Step 3: Resolve AI session by session ID or entry ID**

In `AIReflectionSessionStore`, add:

```swift
func session(for entry: JournalReflectionEntry) -> AIReflectionSession? {
    if let session = session(with: entry.sessionID) {
        return session
    }

    return sessions.first { $0.entryID == entry.id }
}
```

In `JournalEntryDetailView`, replace direct lookup with:

```swift
private var session: AIReflectionSession? {
    aiSessionStore.session(for: currentEntry)
}
```

- [ ] **Step 4: Dedupe tags on edit**

In the journal store update method, normalize tags by trimming whitespace, removing empty strings, and preserving first occurrence case-insensitively.

- [ ] **Step 5: Verify build**

Run build command from Task 2.

- [ ] **Step 6: Commit**

```bash
git add Circleu/Features/Journal/JournalView.swift Circleu/Features/Journal/JournalEntryDetailView.swift Circleu/Stores/AIReflectionSessionStore.swift Circleu/Stores/ReflectionJournalStore.swift
git commit -m "fix: align journal workspace display state"
```

---

### Task 5: Make Reflection Result Actions Lead Into Practice

**Files:**
- Modify: `Circleu/Features/Reflection/ReflectionView.swift`
- Modify: `Circleu/Features/Recording/RecordingView.swift`
- Modify: `Circleu/App/RootView.swift`

- [ ] **Step 1: Add optional post-save destination**

Add a simple enum if needed:

```swift
enum ReflectionSaveDestination {
    case journal
    case practice
}
```

- [ ] **Step 2: Add Start Practice action to Reflection result**

On the reflection result screen, make the suggested quest card include:

```swift
Button {
    saveAndStartPractice()
} label: {
    Label("Save & Start Practice", systemImage: "checklist.checked")
}
.buttonStyle(PinguPrimaryButtonStyle())
```

`saveAndStartPractice()` should save the entry, activate the quest, and request navigation to Practice.

- [ ] **Step 3: Pass destination through Recording -> Root**

Extend `RecordingView` callbacks so Root can set:

```swift
selectedTab = .practice
```

when the user chooses Save & Start Practice.

- [ ] **Step 4: Keep Save Entry behavior unchanged**

The existing Save Entry button should still save the reflection and show the save confirmation.

- [ ] **Step 5: Verify build**

Run build command from Task 2.

- [ ] **Step 6: Commit**

```bash
git add Circleu/Features/Reflection/ReflectionView.swift Circleu/Features/Recording/RecordingView.swift Circleu/App/RootView.swift
git commit -m "feat: connect reflection results to practice"
```

---

### Task 6: Tighten Onboarding And Permission Education

**Files:**
- Modify: `Circleu/Features/Onboarding/Onboarding.swift`
- Modify: `Circleu/Stores/UserProfileStore.swift` if preference storage is needed

- [ ] **Step 1: Update onboarding pages**

Use four pages:

1. Private daily reflection.
2. Voice or typed capture.
3. AI insight and practice.
4. Name and preference setup.

- [ ] **Step 2: Keep completion local**

Confirm onboarding completion continues through existing profile/local storage flow.

- [ ] **Step 3: Ensure iPhone 17 Pro layout fits**

Reduce overly tall fixed `TabView` height if needed and use responsive spacing from `GeometryReader`.

- [ ] **Step 4: Verify build**

Run build command from Task 2.

- [ ] **Step 5: Commit**

```bash
git add Circleu/Features/Onboarding/Onboarding.swift Circleu/Stores/UserProfileStore.swift
git commit -m "feat: refine onboarding for beta flow"
```

---

### Task 7: Improve Circle Local Sharing Clarity

**Files:**
- Modify: `Circleu/Features/Circle/CircleView.swift`
- Modify: `Circleu/Features/Circle/CircleSheets.swift`
- Modify: `Circleu/Stores/CircleStore.swift` if share body needs display-field fixes

- [ ] **Step 1: Make Circle explicitly local-first**

Keep product language positive:

```text
Private support spaces saved on this iPhone.
```

Avoid implying live multi-user sync exists.

- [ ] **Step 2: Ensure share previews use edited display fields**

When sharing an entry, use:

```swift
entry.displayTitle
entry.displaySummary
entry.displayQuest
```

Never include `privateNote` in a normal Circle post.

- [ ] **Step 3: Add useful empty state**

If there are no circles, show a CTA to create the first private circle.

- [ ] **Step 4: Verify build**

Run build command from Task 2.

- [ ] **Step 5: Commit**

```bash
git add Circleu/Features/Circle/CircleView.swift Circleu/Features/Circle/CircleSheets.swift Circleu/Stores/CircleStore.swift
git commit -m "feat: clarify local circle sharing"
```

---

### Task 8: Update Docs And Phone QA

**Files:**
- Modify: `docs/phone-test-checklist.md`
- Modify: `docs/app-flow.md`
- Modify: `docs/project-structure.md`
- Modify: `docs/release-readiness.md`

- [ ] **Step 1: Update phone checklist with Practice tab**

Add checks for:

- onboarding,
- recording or typing,
- AI result,
- Save & Start Practice,
- Practice tab completion,
- Journal edited display fields,
- Circle local share privacy,
- Profile QA export.

- [ ] **Step 2: Update app flow doc**

Document:

```text
Home -> Record/Type -> AI Reflection -> Journal -> Practice -> Progress -> Circle/Profile
```

- [ ] **Step 3: Update project structure**

Add `Features/Practice` ownership and explain why practice is a feature, while `QuestStore` owns practice state.

- [ ] **Step 4: Commit docs**

```bash
git add docs/phone-test-checklist.md docs/app-flow.md docs/project-structure.md docs/release-readiness.md
git commit -m "docs: update daily beta qa flow"
```

---

### Task 9: Final Verification

**Files:**
- No code changes unless verification finds a bug.

- [ ] **Step 1: Check git status**

```bash
git status --short --branch
```

Expected: branch contains only intentional commits and no uncommitted files.

- [ ] **Step 2: Build for simulator**

```bash
xcodebuild build -project Circleu.xcodeproj -scheme Circleu -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 3: Run phone smoke test from docs**

From Xcode:

1. Choose connected iPhone.
2. Run Circleu.
3. Complete onboarding or seed demo data.
4. Record/type reflection.
5. Save & Start Practice.
6. Complete practice.
7. Confirm Journal/Profile/Circle state updates.

- [ ] **Step 4: Commit any verification docs if changed**

```bash
git add docs/phone-test-checklist.md
git commit -m "docs: record beta verification notes"
```

Only commit if a doc changed.

---

## Self-Review

Spec coverage:

- Daily reflection loop: Tasks 2, 3, 5, 6.
- AI result to Journal and Practice: Tasks 4 and 5.
- Practice and progress: Tasks 1, 2, 3, 5.
- Circle local sharing: Task 7.
- Product polish and no placeholder-only tabs: Tasks 2, 3, 6, 7.
- Backend readiness: preserved by not adding backend and keeping provider/storage boundaries intact.
- Phone testing: Tasks 8 and 9.

Known plan constraint:

- The current project has no visible test target. Task 1 uses pure logic designed for XCTest, but implementation may choose build verification first if adding an Xcode test target would create disproportionate project-file churn.
