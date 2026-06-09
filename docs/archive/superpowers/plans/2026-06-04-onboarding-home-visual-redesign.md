# Onboarding Home Visual Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Circleu's onboarding, Home screen, and shared navigation feel more beautiful and premium while removing fake stats from the first app surfaces.

**Architecture:** Keep the current SwiftUI structure. `ContentView` injects profile and journal stores, `RootView` computes shared navigation stats from local journal data, `HomeView` renders the daily dashboard, and `PinguDesign.swift` owns shared visual components.

**Tech Stack:** SwiftUI, local `UserDefaults` stores, asset catalog colors/images, Xcode simulator and iOS device builds.

---

## File Structure

- Modify `Circleu/App/PinguDesign.swift`: polish top bar, bottom tabs, button styling, and support real navigation stat values.
- Modify `Circleu/App/RootView.swift`: pass real local level/streak values into the top bar.
- Modify `Circleu/App/UserProfileStore.swift`: add prompt rotation helper.
- Modify `Circleu/Onboarding.swift`: improve visual hierarchy, name setup, and use `Friend` fallback.
- Modify `Circleu/View/Home/HomeView.swift`: redesign as a beautiful daily dashboard with prompt refresh, real stats, and latest reflection.
- Modify `docs/phone-test-checklist.md`: add visual dashboard test steps.

## Task 1: Shared Navigation And Component Polish

**Files:**
- Modify: `Circleu/App/PinguDesign.swift`
- Modify: `Circleu/App/RootView.swift`

- [ ] **Step 1: Replace hard-coded top bar stats**

Change `PinguTopBar.Trailing` to carry values:

```swift
enum Trailing {
    case level(Int)
    case streak(Int)
    case edit(() -> Void)
    case none
}
```

Update the switch so `.level(let value)` shows `LV\(value)`, `.streak(let value)` shows `\(value) STREAK`, `.edit(let action)` uses a real button action, and `.none` is empty.

- [ ] **Step 2: Make bottom navigation more polished**

Keep four tabs, but make selected tab visually distinct with blue icon/text and a stable rounded background. Keep unselected tabs muted.

- [ ] **Step 3: Add real stat helpers in `RootView`**

Add environment access:

```swift
@EnvironmentObject private var journalStore: ReflectionJournalStore
```

Add:

```swift
private var localLevel: Int {
    max(1, min(12, 1 + journalStore.entries.count / 3))
}

private var localStreak: Int {
    guard !journalStore.entries.isEmpty else { return 0 }
    let calendar = Calendar.current
    let uniqueDays = Set(journalStore.entries.map { calendar.startOfDay(for: $0.createdAt) })
    var streak = 0
    var day = calendar.startOfDay(for: Date())

    while uniqueDays.contains(day) {
        streak += 1
        guard let previousDay = calendar.date(byAdding: .day, value: -1, to: day) else { break }
        day = previousDay
    }

    return streak
}
```

Update navigation trailing:

```swift
case .home:
    .level(localLevel)
case .journal, .profile:
    .streak(localStreak)
case .circle:
    .none
```

## Task 2: User Profile Prompt Rotation

**Files:**
- Modify: `Circleu/App/UserProfileStore.swift`

- [ ] **Step 1: Add prompt advancement**

Add:

```swift
func advanceDailyPrompt(totalPrompts: Int) {
    guard totalPrompts > 0 else { return }
    dailyPromptIndex = (dailyPromptIndex + 1) % totalPrompts
}
```

## Task 3: Onboarding Visual Redesign

**Files:**
- Modify: `Circleu/Onboarding.swift`

- [ ] **Step 1: Use Friend fallback**

Change empty-name fallback from `"Mike"` to `"Friend"`.

- [ ] **Step 2: Improve page structure**

Add a small trust pill near the top of each page:

```swift
Label("Private local reflections", systemImage: "lock.fill")
```

Style it with white translucent background and compact rounded shape.

- [ ] **Step 3: Improve final name input**

Make the name field feel intentional by adding supporting text:

```swift
Text("This stays on this iPhone and helps Circleu greet you naturally.")
```

Keep the input readable over the hero image.

- [ ] **Step 4: Shorten onboarding copy**

Use concise page subtitles:

- Page 1: `A calmer place to understand your day, one honest check-in at a time.`
- Page 2: `Speak naturally or type instead. Circleu keeps the reflection flow moving either way.`
- Page 3: `Apple Intelligence or the local engine turns your words into a private journal insight.`

## Task 4: Home Visual Redesign

**Files:**
- Modify: `Circleu/View/Home/HomeView.swift`

- [ ] **Step 1: Replace vertical spacer-heavy layout**

Use a single `VStack(spacing: 20)` inside the scroll view with:

1. Greeting block.
2. Hero record panel.
3. Daily prompt row.
4. Local stats row.
5. Latest reflection or empty encouragement.

- [ ] **Step 2: Add a polished hero record panel**

Create a white rounded panel with the Pingu hero orb, mic button, and short action copy:

```swift
Text("Start today's reflection")
Text("Speak for a minute, or type if voice is not ready.")
```

Keep the mic button as the strongest action.

- [ ] **Step 3: Add refreshable daily prompt**

Daily prompt card includes a small refresh icon button that calls:

```swift
profileStore.advanceDailyPrompt(totalPrompts: dailyPrompts.count)
```

- [ ] **Step 4: Add real local stats row**

Show three compact stats:

- Entries: `journalStore.entries.count`
- Streak: computed local streak
- Latest: latest emotion or `Start`

- [ ] **Step 5: Polish latest reflection card**

Keep it tappable and visually refined. If no latest entry exists, show an encouraging empty card with a mic action.

## Task 5: Phone Checklist Update

**Files:**
- Modify: `docs/phone-test-checklist.md`

- [ ] **Step 1: Add visual checks**

Add:

```markdown
## 7. Onboarding And Home Visual Checks

1. Reset app data and confirm onboarding fits on the phone.
2. Leave name empty and confirm Home greets `Friend`.
3. Enter a real name and confirm Home greets that name.
4. Tap refresh on the daily prompt and confirm the prompt changes.
5. Save a reflection and confirm Home stats and latest reflection update.
6. Confirm top bar level/streak values are not hard-coded.
```

## Task 6: Verification

**Files:**
- Verify: full project

- [ ] **Step 1: Run simulator build**

```bash
xcodebuild -project Circleu.xcodeproj -scheme Circleu -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -configuration Debug build
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 2: Run generic iOS device build**

```bash
xcodebuild -project Circleu.xcodeproj -scheme Circleu -sdk iphoneos -destination 'generic/platform=iOS' -configuration Debug -allowProvisioningUpdates build
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 3: Run connected iPhone build**

```bash
xcodebuild -project Circleu.xcodeproj -scheme Circleu -sdk iphoneos -destination 'platform=iOS,name=UTS - GK2WN790NV' -configuration Debug -allowProvisioningUpdates build
```

Expected: `BUILD SUCCEEDED` when the phone is connected and trusted.

## Self-Review

Spec coverage:

- Onboarding visual polish: Task 3.
- Home daily dashboard: Task 4.
- No fake navigation stats: Task 1.
- Prompt refresh: Task 2 and Task 4.
- Testing: Task 5 and Task 6.

Placeholder scan:

- The plan contains no TBD, TODO, or unresolved placeholder instruction.

Type consistency:

- `advanceDailyPrompt(totalPrompts:)`, `localLevel`, and `localStreak` are introduced before use.
