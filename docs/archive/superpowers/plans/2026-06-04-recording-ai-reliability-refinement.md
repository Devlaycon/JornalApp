# Recording AI Reliability Refinement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Circleu's recording-to-reflection flow reliable on a real iPhone, with no dead ends from permissions, analysis failures, or repeated save taps.

**Architecture:** Keep `RecordingView` as the interaction coordinator, `VoiceRecorder` as the speech/microphone state owner, `ReflectionAnalyzing` as the AI boundary, and `ReflectionJournalStore` as the single writer for saved entries. Add small state and helper APIs rather than introducing a new state-management framework.

**Tech Stack:** SwiftUI, Combine, AVFoundation, Speech, UserDefaults JSON persistence, FoundationModels where available, Xcode simulator and iOS device builds.

---

## File Structure

- Modify `Circleu/App/VoiceRecorder.swift`: expose typed-fallback state, make permission denial explicit, and add a reset helper.
- Modify `Circleu/App/ReflectionJournalStore.swift`: make saving idempotent by entry ID.
- Modify `Circleu/View/Recording/RecordingView.swift`: clarify button behavior, stop stale analysis tasks, reset cleanly for another recording, and present fallback status.
- Modify `Circleu/View/Reflection/ReflectionView.swift`: harden save action against repeated taps and communicate saved state.
- Modify `Circleu/View/Recording/SaveConfirmationView.swift`: make post-save routes explicit and robust when entry is missing.
- Modify `docs/phone-test-checklist.md`: add recording reliability test steps.

## Task 1: Harden VoiceRecorder State

**Files:**
- Modify: `Circleu/App/VoiceRecorder.swift`

- [ ] **Step 1: Add fallback state**

Add this published property near the other `@Published` values:

```swift
@Published var isTypedFallbackAvailable = false
```

- [ ] **Step 2: Add `resetSession()`**

Add this method after `stop()`:

```swift
func resetSession() {
    stop()
    transcript = ""
    elapsedSeconds = 0
    errorMessage = nil
    isTypedFallbackAvailable = false
    statusMessage = "Preparing microphone..."
}
```

- [ ] **Step 3: Add `enterTypedFallback(message:)`**

Add this private helper before `requestPermissions()`:

```swift
@MainActor
private func enterTypedFallback(message: String) {
    stopTimer()
    audioEngine.stop()
    audioEngine.inputNode.removeTap(onBus: 0)
    recognitionRequest?.endAudio()
    recognitionTask?.cancel()
    recognitionTask = nil
    recognitionRequest = nil
    isRecording = false
    isPaused = false
    isTypedFallbackAvailable = true
    errorMessage = message
    statusMessage = "Type reflection"
}
```

- [ ] **Step 4: Update permission failures to use typed fallback**

In `requestPermissions()`, replace the speech permission failure body with:

```swift
await MainActor.run {
    self.enterTypedFallback(message: "Speech recognition is unavailable. You can still type your reflection below.")
}
return false
```

Replace the microphone permission failure body with:

```swift
await MainActor.run {
    self.enterTypedFallback(message: "Microphone permission is unavailable. You can still type your reflection below.")
}
return false
```

- [ ] **Step 5: Clear fallback when live recognition begins**

In `beginRecognition()`, after `errorMessage = nil`, add:

```swift
isTypedFallbackAvailable = false
```

- [ ] **Step 6: Use fallback if speech recognizer is unavailable**

Replace the speech recognizer unavailable block with:

```swift
enterTypedFallback(message: "Speech recognition is not available right now. You can still type your reflection below.")
return
```

- [ ] **Step 7: Use fallback when recording start throws**

In the `catch` block of `beginRecognition()`, replace the current error/status handling with:

```swift
enterTypedFallback(message: "Could not start recording. You can still type your reflection below.")
```

## Task 2: Make Journal Saves Idempotent

**Files:**
- Modify: `Circleu/App/ReflectionJournalStore.swift`

- [ ] **Step 1: Replace `add(_:)` with an idempotent implementation**

Replace:

```swift
func add(_ entry: JournalReflectionEntry) {
    entries.insert(entry, at: 0)
    save()
}
```

with:

```swift
func add(_ entry: JournalReflectionEntry) {
    guard !entries.contains(where: { $0.id == entry.id }) else { return }
    entries.insert(entry, at: 0)
    save()
}
```

This protects the journal even if a view accidentally sends the same saved entry twice.

## Task 3: Strengthen RecordingView Flow

**Files:**
- Modify: `Circleu/View/Recording/RecordingView.swift`

- [ ] **Step 1: Add analysis task tracking**

Add this state property near `manualTranscript`:

```swift
@State private var analysisTask: Task<Void, Never>?
```

- [ ] **Step 2: Cancel analysis when leaving**

Add this modifier near the `.task` modifier:

```swift
.onDisappear {
    analysisTask?.cancel()
    recorder.stop()
}
```

- [ ] **Step 3: Clarify subtitle for typed fallback**

Update `subtitle` so fallback appears before generic engine fallback:

```swift
if recorder.isTypedFallbackAvailable {
    return "Voice is not ready, but typing works. Your reflection can still continue."
}
```

Place it after the `isAnalyzing` branch and before `recorder.errorMessage`.

- [ ] **Step 4: Disable restart while analysis or reflection is pending**

Change the restart button disabled condition from:

```swift
.disabled(isAnalyzing)
```

to:

```swift
.disabled(isAnalyzing || showReflection || showSaveConfirmation)
```

- [ ] **Step 5: Use a full reset for restart**

Replace the restart button action:

```swift
recorder.stop()
manualTranscript = ""
recorder.start()
```

with:

```swift
analysisTask?.cancel()
pendingEntry = nil
savedEntry = nil
analysisMessage = nil
manualTranscript = ""
recorder.resetSession()
recorder.start()
```

- [ ] **Step 6: Make fallback text editor always usable when there is no live transcript**

In the `TextEditor`, add:

```swift
.disabled(isAnalyzing)
```

This prevents editing during analysis while preserving typed fallback before and after failures.

- [ ] **Step 7: Avoid overlapping analysis tasks**

At the beginning of `finishRecording()` after the `guard canFinish` block, add:

```swift
analysisTask?.cancel()
```

Replace:

```swift
Task {
```

with:

```swift
analysisTask = Task {
```

- [ ] **Step 8: Ignore cancelled analysis results**

Inside the analysis task, after the `engine.analyze` call returns and before creating the entry, add:

```swift
guard !Task.isCancelled else { return }
```

Inside the `catch` block, add this before updating UI:

```swift
guard !Task.isCancelled else { return }
```

- [ ] **Step 9: Reset analysis task after success or failure**

In both success and failure `MainActor.run` blocks, set:

```swift
analysisTask = nil
```

- [ ] **Step 10: Make record-another reset complete**

Replace `resetForAnotherRecording()` with:

```swift
private func resetForAnotherRecording() {
    analysisTask?.cancel()
    analysisTask = nil
    pendingEntry = nil
    savedEntry = nil
    showReflection = false
    showSaveConfirmation = false
    isAnalyzing = false
    analysisMessage = nil
    manualTranscript = ""
    recorder.resetSession()
    recorder.start()
}
```

## Task 4: Harden Reflection Save

**Files:**
- Modify: `Circleu/View/Reflection/ReflectionView.swift`

- [ ] **Step 1: Add a dedicated save helper**

Add this method before `shareText`:

```swift
private func saveEntry() {
    guard !hasSaved else { return }
    guard let entry else {
        dismiss()
        return
    }

    hasSaved = true
    onSave?(entry)
}
```

- [ ] **Step 2: Replace save button action**

Replace the save button action:

```swift
if let entry {
    hasSaved = true
    onSave?(entry)
} else {
    dismiss()
}
```

with:

```swift
saveEntry()
```

- [ ] **Step 3: Disable cancel after successful save**

Change the Cancel button action:

```swift
dismiss()
```

to:

```swift
if !hasSaved {
    dismiss()
}
```

Add to the Cancel button:

```swift
.disabled(hasSaved)
.opacity(hasSaved ? 0.45 : 1)
```

## Task 5: Make Save Confirmation Robust

**Files:**
- Modify: `Circleu/View/Recording/SaveConfirmationView.swift`

- [ ] **Step 1: Make missing-entry copy explicit**

Change the subtitle text to:

```swift
Text(entry == nil ? "Your reflection flow is complete." : "Your AI-powered reflection is now available in Journal History.")
```

- [ ] **Step 2: Disable View Journal if there is no entry**

Add to the View Journal button:

```swift
.disabled(entry == nil)
.opacity(entry == nil ? 0.55 : 1)
```

This avoids a confusing route when the confirmation screen has no saved entry.

## Task 6: Update Phone Test Checklist

**Files:**
- Modify: `docs/phone-test-checklist.md`

- [ ] **Step 1: Add reliability checks**

Add this section after the real user flow:

```markdown
## 6. Recording Reliability Checks

Test these before calling the build demo-ready:

1. Start recording and type instead of speaking.
2. Confirm **Finish** stays disabled until text exists.
3. Finish with typed text and confirm AI analysis starts.
4. Save once and confirm the confirmation screen appears.
5. Open Journal and confirm only one new entry exists.
6. Use **Record Another** and confirm the previous transcript is cleared.
7. Deny microphone or speech permission on a fresh install if possible and confirm typed fallback still works.
```

## Task 7: Verification

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

- [ ] **Step 3: Run connected iPhone build when available**

```bash
xcodebuild -project Circleu.xcodeproj -scheme Circleu -sdk iphoneos -destination 'id=00008140-001C3C202E78801C' -configuration Debug -allowProvisioningUpdates build
```

Expected: `BUILD SUCCEEDED` when Xcode lists the phone as available. If Xcode lists the phone as unavailable, report the device availability issue and rely on the generic iOS device build for compile/signing verification.

## Self-Review

Spec coverage:

- Recording state clarity: Task 1 and Task 3.
- Permission-aware fallback: Task 1 and Task 3.
- Analysis retry and cancellation: Task 3.
- Save protection: Task 2 and Task 4.
- Confirmation robustness: Task 5.
- Test coverage: Task 6 and Task 7.

Placeholder scan:

- The plan contains no TBD, TODO, or incomplete implementation step.

Type consistency:

- `isTypedFallbackAvailable`, `resetSession()`, and `analysisTask` are introduced before use.
- Existing types `ReflectionJournalStore`, `RecordingView`, `ReflectionView`, and `SaveConfirmationView` keep their public roles.
