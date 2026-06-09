# Real Daily Journaling MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Circleu feel like a real local-first iPhone journaling app with a dependable daily reflection loop.

**Architecture:** Keep the current SwiftUI app local-first. Add one profile store for display name/preferences, continue using `ReflectionJournalStore` as the saved-entry source of truth, and pass both stores through SwiftUI environment objects so Home, Onboarding, Journal, and Profile share the same data.

**Tech Stack:** SwiftUI, Combine, UserDefaults JSON persistence, AVFoundation, Speech, FoundationModels when available, Xcode/iOS simulator and physical iPhone builds.

---

## File Structure

- Create `Circleu/App/UserProfileStore.swift`: local display name and lightweight preferences.
- Modify `Circleu/App/ContentView.swift`: own and inject `UserProfileStore`.
- Modify `Circleu/Onboarding.swift`: collect display name and save it before entering the app.
- Modify `Circleu/View/Home/HomeView.swift`: greet by saved name and surface real prompt/progress data.
- Modify `Circleu/View/Profile/ProfileView.swift`: read/edit display name and derive real metrics from journal entries.
- Modify `Circleu/View/Recording/RecordingView.swift`: refine typed fallback, retry, and failure behavior where needed.
- Modify `docs/phone-test-checklist.md`: add the improved real-user test flow.

## Task 1: Add Local Profile Store

**Files:**
- Create: `Circleu/App/UserProfileStore.swift`
- Modify: `Circleu/App/ContentView.swift`

- [ ] **Step 1: Add `UserProfileStore`**

Create `Circleu/App/UserProfileStore.swift`:

```swift
import Combine
import Foundation

@MainActor
final class UserProfileStore: ObservableObject {
    @Published var displayName: String {
        didSet { saveDisplayName(displayName) }
    }

    @Published var dailyPromptIndex: Int {
        didSet { UserDefaults.standard.set(dailyPromptIndex, forKey: dailyPromptIndexKey) }
    }

    private let displayNameKey = "circleu.profile.displayName.v1"
    private let dailyPromptIndexKey = "circleu.profile.dailyPromptIndex.v1"

    init() {
        let savedName = UserDefaults.standard.string(forKey: displayNameKey) ?? ""
        displayName = savedName.trimmingCharacters(in: .whitespacesAndNewlines)
        dailyPromptIndex = UserDefaults.standard.integer(forKey: dailyPromptIndexKey)
    }

    var firstName: String {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.split(separator: " ").first else { return "friend" }
        return String(first)
    }

    var hasDisplayName: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func updateDisplayName(_ value: String) {
        displayName = sanitizedName(value)
    }

    private func sanitizedName(_ value: String) -> String {
        let collapsed = value
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
        return String(collapsed.prefix(32))
    }

    private func saveDisplayName(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        UserDefaults.standard.set(trimmed, forKey: displayNameKey)
    }
}
```

- [ ] **Step 2: Inject the store in `ContentView`**

Update `Circleu/App/ContentView.swift` to own both stores:

```swift
import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var journalStore = ReflectionJournalStore()
    @StateObject private var profileStore = UserProfileStore()

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                RootView()
            } else {
                PinguOnboardingView()
            }
        }
        .environmentObject(journalStore)
        .environmentObject(profileStore)
    }
}

#Preview {
    ContentView()
}
```

- [ ] **Step 3: Build to verify the new file is in the Xcode target**

Run:

```bash
xcodebuild -project Circleu.xcodeproj -scheme Circleu -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -configuration Debug build
```

Expected: if `UserProfileStore.swift` is not automatically in the project target, the build fails with `cannot find 'UserProfileStore' in scope`; add the file to `Circleu.xcodeproj/project.pbxproj` through Xcode or the existing project file pattern, then rerun until it builds.

## Task 2: Make Onboarding Collect The Real User Name

**Files:**
- Modify: `Circleu/Onboarding.swift`

- [ ] **Step 1: Add profile environment and name state**

At the top of `PinguOnboardingView`, add:

```swift
@EnvironmentObject private var profileStore: UserProfileStore
@State private var draftName = ""
```

- [ ] **Step 2: Add a name input to the final onboarding page**

On the final page of the onboarding pager, add this input block below the explanatory copy:

```swift
VStack(alignment: .leading, spacing: 8) {
    Text("What should Circleu call you?")
        .font(.system(size: 15, weight: .bold, design: .rounded))
        .foregroundStyle(PinguDesign.ink)

    TextField("Your name", text: $draftName)
        .font(.system(size: 18, weight: .semibold, design: .rounded))
        .textInputAutocapitalization(.words)
        .autocorrectionDisabled()
        .padding(.horizontal, 16)
        .frame(height: 54)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(PinguDesign.border, lineWidth: 1)
        }
}
```

- [ ] **Step 3: Save the name before entering the app**

Where the final onboarding button sets `hasCompletedOnboarding = true`, update the action:

```swift
if draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
    profileStore.updateDisplayName("Mike")
} else {
    profileStore.updateDisplayName(draftName)
}
hasCompletedOnboarding = true
```

- [ ] **Step 4: Update preview**

Ensure the onboarding preview injects:

```swift
.environmentObject(UserProfileStore())
```

- [ ] **Step 5: Build**

Run the simulator build command from Task 1.

Expected: `BUILD SUCCEEDED`.

## Task 3: Make Home Feel Like A Real Daily Start Screen

**Files:**
- Modify: `Circleu/View/Home/HomeView.swift`

- [ ] **Step 1: Read the profile store**

Add:

```swift
@EnvironmentObject private var profileStore: UserProfileStore
```

- [ ] **Step 2: Replace hard-coded greeting**

Change the greeting title to:

```swift
Text("Hey \(profileStore.firstName),")
```

- [ ] **Step 3: Add a daily prompt card above the record action**

Add this computed property:

```swift
private var dailyPromptCard: some View {
    VStack(alignment: .leading, spacing: 10) {
        HStack(spacing: 8) {
            Image(systemName: "sun.max.fill")
                .foregroundStyle(PinguDesign.orange)
            Text("Today's prompt")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(PinguDesign.muted)
        }

        Text(dailyPrompt)
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(PinguDesign.ink)
            .lineSpacing(4)
    }
    .padding(16)
    .frame(maxWidth: 330, alignment: .leading)
    .background(.white)
    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    .shadow(color: PinguDesign.deepBlue.opacity(0.05), radius: 12, y: 6)
}

private var dailyPrompt: String {
    let prompts = [
        "What feeling has been sitting with you today?",
        "What small moment changed your mood?",
        "What do you want to understand about yourself today?",
        "What would make tomorrow feel lighter?"
    ]
    return prompts[profileStore.dailyPromptIndex % prompts.count]
}
```

Place `dailyPromptCard` immediately before the microphone button in `recordPrompt`.

- [ ] **Step 4: Add real progress copy**

Below the prompt card, add:

```swift
Text(homeProgressText)
    .font(.system(size: 14, weight: .bold, design: .rounded))
    .foregroundStyle(PinguDesign.muted)
```

Add:

```swift
private var homeProgressText: String {
    let count = journalStore.entries.count
    if count == 0 {
        return "Start your first local reflection."
    }
    if count == 1 {
        return "1 reflection saved locally."
    }
    return "\(count) reflections saved locally."
}
```

- [ ] **Step 5: Update preview**

Ensure preview injects `UserProfileStore`.

- [ ] **Step 6: Build**

Run the simulator build command from Task 1.

Expected: `BUILD SUCCEEDED`.

## Task 4: Make Profile Editable And Data-Driven

**Files:**
- Modify: `Circleu/View/Profile/ProfileView.swift`

- [ ] **Step 1: Read profile store**

Add:

```swift
@EnvironmentObject private var profileStore: UserProfileStore
```

- [ ] **Step 2: Replace hard-coded name**

Replace profile header name:

```swift
Text(profileStore.firstName)
```

Replace the subtitle with:

```swift
Text(profileTitle)
```

Add:

```swift
private var profileTitle: String {
    if journalStore.entries.count >= 7 { return "Steady Reflector" }
    if journalStore.entries.count >= 3 { return "Confident Explorer" }
    return "New Voice Explorer"
}
```

- [ ] **Step 3: Pass the profile store into editor sheet**

Change the sheet:

```swift
ProfileEditSheet(entriesCount: journalStore.entries.count)
    .environmentObject(profileStore)
    .presentationDetents([.medium])
```

- [ ] **Step 4: Make `ProfileEditSheet` editable**

Inside `ProfileEditSheet`, add:

```swift
@EnvironmentObject private var profileStore: UserProfileStore
@State private var draftName = ""
```

Add `.onAppear` to the sheet root:

```swift
.onAppear {
    draftName = profileStore.displayName
}
```

Replace the display name row with:

```swift
VStack(alignment: .leading, spacing: 8) {
    Text("Display name")
        .font(.system(size: 15, weight: .bold, design: .rounded))
        .foregroundStyle(PinguDesign.ink)

    TextField("Your name", text: $draftName)
        .font(.system(size: 17, weight: .semibold, design: .rounded))
        .textInputAutocapitalization(.words)
        .autocorrectionDisabled()
        .padding(.horizontal, 14)
        .frame(height: 50)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
}
```

Update the Done button action:

```swift
profileStore.updateDisplayName(draftName.isEmpty ? "Mike" : draftName)
dismiss()
```

- [ ] **Step 5: Update previews**

Ensure previews inject `UserProfileStore`.

- [ ] **Step 6: Build**

Run the simulator build command from Task 1.

Expected: `BUILD SUCCEEDED`.

## Task 5: Tighten Recording Failure And Retry Behavior

**Files:**
- Modify: `Circleu/View/Recording/RecordingView.swift`

- [ ] **Step 1: Keep failed transcripts editable**

Confirm `finishRecording()` sets `analysisMessage` without clearing `manualTranscript`, `recorder.transcript`, or `pendingEntry` on failure. If any of those are cleared, remove that clearing.

- [ ] **Step 2: Make retry explicit after AI failure**

In `transcriptPanel`, below `analysisMessage`, add:

```swift
if analysisMessage != nil && canFinish {
    Button {
        finishRecording()
    } label: {
        Label("Try analysis again", systemImage: "arrow.clockwise")
            .font(.system(size: 13, weight: .bold, design: .rounded))
    }
    .buttonStyle(.plain)
    .foregroundStyle(PinguDesign.blue)
}
```

- [ ] **Step 3: Improve typed fallback copy**

Change the placeholder text to:

```swift
Text("Speak naturally, or type here if microphone or speech recognition is not ready.")
```

- [ ] **Step 4: Build**

Run the simulator build command from Task 1.

Expected: `BUILD SUCCEEDED`.

## Task 6: Update Phone Test Checklist

**Files:**
- Modify: `docs/phone-test-checklist.md`

- [ ] **Step 1: Add local profile checks**

Add these steps to the real user flow:

```markdown
1. Reset app data if you want to see onboarding again.
2. Enter a display name during onboarding.
3. Confirm Home greets you by name.
4. Save a reflection.
5. Open Profile and confirm the name, entry count, streak, and progress changed.
6. Edit the display name from Profile and confirm Home updates.
```

- [ ] **Step 2: Add Preview guidance**

Add:

```markdown
Use Simulator for SwiftUI Previews. Use the connected iPhone for Run testing. Physical-device Preview errors do not necessarily mean the app build is broken.
```

## Task 7: Final Verification

**Files:**
- Verify: full project

- [ ] **Step 1: Run simulator build**

```bash
xcodebuild -project Circleu.xcodeproj -scheme Circleu -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -configuration Debug build
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 2: Run physical iPhone build**

```bash
xcodebuild -project Circleu.xcodeproj -scheme Circleu -sdk iphoneos -destination 'id=00008140-001C3C202E78801C' -configuration Debug -allowProvisioningUpdates build
```

Expected: `BUILD SUCCEEDED`.

- [ ] **Step 3: Manual smoke test on phone**

Test:

```text
Onboarding -> enter name -> Home greeting -> Record -> type fallback or speak -> Finish -> Reflection -> Save -> View Journal -> Open detail -> Profile -> Edit name -> Home greeting updates
```

Expected: no dead buttons in the core loop, saved entry persists after relaunch, Profile metrics update from saved entries.

- [ ] **Step 4: Commit implementation**

Stage only files changed by this plan:

```bash
git add Circleu/App/UserProfileStore.swift Circleu/App/ContentView.swift Circleu/Onboarding.swift Circleu/View/Home/HomeView.swift Circleu/View/Profile/ProfileView.swift Circleu/View/Recording/RecordingView.swift docs/phone-test-checklist.md Circleu.xcodeproj/project.pbxproj
git commit -m "Improve real daily journaling MVP"
```

Expected: commit succeeds on branch `dev/mike`.

## Self-Review

Spec coverage:

- Local profile: Task 1, Task 2, Task 4.
- Connected core loop: Task 2, Task 3, Task 4, Task 5.
- Error states and typed fallback: Task 5.
- Real local metrics: Task 3, Task 4.
- Phone testing and builds: Task 6, Task 7.

Placeholder scan:

- The plan contains no TBD, TODO, or unspecified implementation steps.

Type consistency:

- `UserProfileStore.displayName`, `firstName`, `hasDisplayName`, and `updateDisplayName(_:)` are introduced in Task 1 and reused consistently in later tasks.
