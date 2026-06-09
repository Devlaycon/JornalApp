# Recording ViewModel Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move Recording screen controller logic out of `RecordingView` into a focused `RecordingViewModel` while preserving the current recording, typed fallback, AI analysis, reflection, and save-confirmation behavior.

**Architecture:** Keep `VoiceRecorder` as the device/speech service and keep `ReflectionJournalStore` / `AIReflectionSessionStore` as shared persistence stores. Add `RecordingViewModel` beside `RecordingView`; the ViewModel owns transcript fallback, analysis state, pending reflection/session state, reset/restart actions, and save-session linking, while `RecordingView` becomes mostly layout and navigation presentation.

**Tech Stack:** SwiftUI, Combine `ObservableObject`, Swift concurrency `Task`, existing Circleu `VoiceRecorder`, `ReflectionSessionRunner`, `ReflectionAnalyzing`, `TranscriptQuality`, `JournalReflectionEntry`, and Xcode iOS Simulator build verification.

---

## Scope

This plan implements the first MVVM vertical slice from the approved architecture spec:

- Spec: `docs/superpowers/specs/2026-06-05-mvvm-screen-viewmodels-design.md`
- Feature: `Circleu/Features/Recording/`

This plan does not migrate Reflection, Journal, Tips, Circle, or Profile. Those become later feature-scoped refactor plans after Recording is stable.

## File Structure

Create:

- `Circleu/Features/Recording/RecordingViewModel.swift`
  - Screen-level controller for `RecordingView`.
  - Owns the existing `VoiceRecorder` instance.
  - Owns manual transcript, AI analysis task, pending entry/session, saved entry, save confirmation state, and reflection presentation state.
  - Exposes computed UI state: subtitle, effective transcript, transcript quality, can finish, finish action title, formatted timer text.
  - Exposes user actions: start, stop, close, restart, finish recording, reset for another recording, apply session changes, save entry.

Modify:

- `Circleu/Features/Recording/RecordingView.swift`
  - Replace controller `@State` properties with `@StateObject private var viewModel = RecordingViewModel()`.
  - Read recording state through `viewModel`.
  - Bind the transcript editor to `viewModel.manualTranscript`.
  - Move action calls to ViewModel methods.
  - Keep view-only concerns: `dismiss`, full-screen covers, `onViewJournal`, `onViewTips`, and layout.

No model/store/service files are changed in this first slice.

## Important Behavior To Preserve

- Recording starts when the screen appears.
- Recording stops and analysis cancels when the screen disappears.
- Close button stops recording and dismisses the screen.
- Restart button clears pending analysis/reflection/save state and starts a fresh recording.
- User can type a reflection when live transcript is empty.
- Finish is disabled until `TranscriptQuality.evaluate` returns ready.
- AI analysis creates a pending `JournalReflectionEntry` and pending `AIReflectionSession`.
- Reflection sheet can update the pending entry when the selected AI attempt changes.
- Saving from Reflection writes the entry to `ReflectionJournalStore`.
- Saving also links/upserts the pending AI session through `AIReflectionSessionStore`.
- Save confirmation can dismiss, go to Journal, or record another reflection.

## Task 1: Add RecordingViewModel

**Files:**

- Create: `Circleu/Features/Recording/RecordingViewModel.swift`

- [ ] **Step 1: Create the ViewModel file**

Create `Circleu/Features/Recording/RecordingViewModel.swift` with:

```swift
import Combine
import Foundation

@MainActor
final class RecordingViewModel: ObservableObject {
    @Published var recorder: VoiceRecorder
    @Published var manualTranscript = ""
    @Published var showReflection = false
    @Published var showSaveConfirmation = false
    @Published var pendingEntry: JournalReflectionEntry?
    @Published var pendingSession: AIReflectionSession?
    @Published var savedEntry: JournalReflectionEntry?
    @Published var isAnalyzing = false
    @Published var analysisMessage: String?

    let engine: any ReflectionAnalyzing
    private var analysisTask: Task<Void, Never>?
    private var sessionRunner: ReflectionSessionRunner
    private var cancellables = Set<AnyCancellable>()

    init(
        recorder: VoiceRecorder = VoiceRecorder(),
        engine: any ReflectionAnalyzing = ReflectionEngineFactory.makeDefault(),
        sessionRunner: ReflectionSessionRunner = ReflectionSessionRunner()
    ) {
        self.recorder = recorder
        self.engine = engine
        self.sessionRunner = sessionRunner

        recorder.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    var subtitle: String {
        if isAnalyzing {
            return "Apple Intelligence is creating your reflection."
        }

        if recorder.isTypedFallbackAvailable {
            return "Voice is not ready, but typing works. Your reflection can still continue."
        }

        if let message = recorder.errorMessage {
            return message
        }

        if let message = engine.availabilityMessage {
            return message
        }

        return "Speak naturally. Your transcript stays on this device."
    }

    var effectiveTranscript: String {
        let liveTranscript = recorder.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        if !liveTranscript.isEmpty {
            return liveTranscript
        }

        return manualTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var transcriptQuality: TranscriptQuality {
        TranscriptQuality.evaluate(effectiveTranscript)
    }

    var canFinish: Bool {
        !isAnalyzing && transcriptQuality.isReady
    }

    var finishActionTitle: String {
        if isAnalyzing {
            return "WAIT"
        }

        return canFinish ? "FINISH" : "TYPE"
    }

    var formattedElapsedTime: String {
        formattedTime(recorder.elapsedSeconds)
    }

    func start() {
        recorder.start()
    }

    func stop() {
        analysisTask?.cancel()
        analysisTask = nil
        recorder.stop()
    }

    func togglePause() {
        recorder.togglePause()
    }

    func restartRecording() {
        analysisTask?.cancel()
        analysisTask = nil
        pendingEntry = nil
        pendingSession = nil
        savedEntry = nil
        analysisMessage = nil
        manualTranscript = ""
        showReflection = false
        showSaveConfirmation = false
        isAnalyzing = false
        recorder.resetSession()
        recorder.start()
    }

    func resetForAnotherRecording() {
        restartRecording()
    }

    func finishRecording() {
        guard canFinish else {
            analysisMessage = transcriptQuality.guidance
            return
        }

        analysisTask?.cancel()
        recorder.stop()
        analysisMessage = nil

        let transcript = effectiveTranscript
        let durationSeconds = recorder.elapsedSeconds
        let reflectionSource: AIReflectionSource = recorder.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? .typedFallback
            : .recording

        analysisTask = Task { [weak self] in
            guard let self else { return }
            self.isAnalyzing = true

            let run = await self.sessionRunner.analyze(
                transcript: transcript,
                durationSeconds: durationSeconds,
                source: reflectionSource,
                engine: self.engine
            )
            guard !Task.isCancelled else { return }

            guard let result = run.result else {
                self.isAnalyzing = false
                self.analysisTask = nil
                self.analysisMessage = run.attempt.errorMessage ?? "AI analysis failed. Please try again."
                return
            }

            let entry = JournalReflectionEntry(
                createdAt: run.attempt.createdAt,
                durationSeconds: durationSeconds,
                transcript: transcript,
                engineName: run.attempt.engineName,
                result: result,
                sessionID: run.session.id
            )

            self.pendingSession = run.session
            self.pendingEntry = entry
            self.isAnalyzing = false
            self.analysisTask = nil
            self.showReflection = true
        }
    }

    func applySessionChange(_ session: AIReflectionSession?) {
        pendingSession = session
        if let selectedResult = session?.selectedResult,
           let selectedAttempt = session?.selectedAttempt,
           selectedAttempt.status == .succeeded {
            pendingEntry?.result = selectedResult
            pendingEntry?.engineName = selectedAttempt.engineName
            pendingEntry?.sessionID = session?.id
        }
    }

    func savePendingEntry(
        _ entry: JournalReflectionEntry,
        journalStore: ReflectionJournalStore,
        aiSessionStore: AIReflectionSessionStore
    ) {
        persistPendingSession(for: entry, aiSessionStore: aiSessionStore)
        journalStore.add(entry)
        savedEntry = entry
        pendingEntry = nil
        pendingSession = nil
        showReflection = false
    }

    func showConfirmationAfterSave() {
        showSaveConfirmation = true
    }

    func clearSaveConfirmation() {
        showSaveConfirmation = false
    }

    private func persistPendingSession(for entry: JournalReflectionEntry, aiSessionStore: AIReflectionSessionStore) {
        guard let sessionID = entry.sessionID else { return }

        if var session = pendingSession, session.id == sessionID {
            session.entryID = entry.id
            session.engineName = entry.engineName
            session.updatedAt = Date()
            aiSessionStore.upsert(session)
            return
        }

        aiSessionStore.link(sessionID: sessionID, to: entry.id)
    }

    private func formattedTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
```

- [ ] **Step 2: Run a build to catch missing symbols**

Run:

```bash
xcodebuild -project Circleu.xcodeproj -scheme Circleu -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected:

- The build can fail because `RecordingView` has not been migrated yet only if there are new-file integration errors.
- Fix any compile error inside `RecordingViewModel.swift` before starting Task 2.

## Task 2: Wire RecordingView To The ViewModel

**Files:**

- Modify: `Circleu/Features/Recording/RecordingView.swift`

- [ ] **Step 1: Replace controller state**

At the top of `RecordingView`, replace:

```swift
@StateObject private var recorder = VoiceRecorder()
let onViewJournal: () -> Void
let onViewTips: () -> Void

@State private var engine = ReflectionEngineFactory.makeDefault()
@State private var showReflection = false
@State private var showSaveConfirmation = false
@State private var pendingEntry: JournalReflectionEntry?
@State private var pendingSession: AIReflectionSession?
@State private var savedEntry: JournalReflectionEntry?
@State private var isAnalyzing = false
@State private var analysisMessage: String?
@State private var manualTranscript = ""
@State private var analysisTask: Task<Void, Never>?
@State private var sessionRunner = ReflectionSessionRunner()
```

with:

```swift
@StateObject private var viewModel = RecordingViewModel()
let onViewJournal: () -> Void
let onViewTips: () -> Void
```

- [ ] **Step 2: Replace state reads in the body**

Apply these replacements in `RecordingView.swift`:

```text
isAnalyzing -> viewModel.isAnalyzing
recorder.statusMessage -> viewModel.recorder.statusMessage
recorder.transcript -> viewModel.recorder.transcript
subtitle -> viewModel.subtitle
recorder.isRecording -> viewModel.recorder.isRecording
recorder.isPaused -> viewModel.recorder.isPaused
recorder.isTypedFallbackAvailable -> viewModel.recorder.isTypedFallbackAvailable
recorder.errorMessage -> viewModel.recorder.errorMessage
recorder.microphonePermissionState -> viewModel.recorder.microphonePermissionState
recorder.speechPermissionState -> viewModel.recorder.speechPermissionState
formattedTime(recorder.elapsedSeconds) -> viewModel.formattedElapsedTime
canFinish -> viewModel.canFinish
finishActionTitle -> viewModel.finishActionTitle
showReflection -> viewModel.showReflection
showSaveConfirmation -> viewModel.showSaveConfirmation
pendingEntry -> viewModel.pendingEntry
pendingSession -> viewModel.pendingSession
savedEntry -> viewModel.savedEntry
analysisMessage -> viewModel.analysisMessage
transcriptQuality -> viewModel.transcriptQuality
engine.displayName -> viewModel.engine.displayName
manualTranscript -> viewModel.manualTranscript
```

For bindings, use:

```swift
TextEditor(text: $viewModel.manualTranscript)
```

and:

```swift
.fullScreenCover(isPresented: $viewModel.showReflection) {
    ReflectionView(
        entry: viewModel.pendingEntry,
        session: viewModel.pendingSession,
        onSessionChange: { session in
            viewModel.applySessionChange(session)
        }
    ) { entry, destination in
        viewModel.savePendingEntry(
            entry,
            journalStore: journalStore,
            aiSessionStore: aiSessionStore
        )

        switch destination {
        case .confirmation:
            viewModel.showConfirmationAfterSave()
        case .tips:
            onViewTips()
            dismiss()
        }
    }
}
.fullScreenCover(isPresented: $viewModel.showSaveConfirmation) {
    SaveConfirmationView(entry: viewModel.savedEntry) {
        viewModel.clearSaveConfirmation()
        dismiss()
    } onViewJournal: {
        viewModel.clearSaveConfirmation()
        onViewJournal()
        dismiss()
    } onRecordAnother: {
        viewModel.clearSaveConfirmation()
        viewModel.resetForAnotherRecording()
    }
}
```

- [ ] **Step 3: Replace user actions**

Update the action closures:

```swift
.task {
    viewModel.start()
}
.onDisappear {
    viewModel.stop()
}
```

Close button:

```swift
Button {
    viewModel.stop()
    dismiss()
} label: {
    Label("Close", systemImage: "xmark")
        .labelStyle(.iconOnly)
        .font(.system(size: 27, weight: .medium))
        .foregroundStyle(PinguDesign.tabText)
        .frame(width: 58, height: 50)
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .background(.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: PinguDesign.deepBlue.opacity(0.08), radius: 10, y: 5)
}
```

Restart button:

```swift
Button {
    viewModel.restartRecording()
} label: {
    Label("Replay", systemImage: "arrow.clockwise")
        .labelStyle(.iconOnly)
        .font(.system(size: 25, weight: .semibold))
        .foregroundStyle(PinguDesign.tabText)
        .frame(width: 58, height: 50)
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .background(.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: PinguDesign.deepBlue.opacity(0.08), radius: 10, y: 5)
}
.disabled(viewModel.isAnalyzing || viewModel.showReflection || viewModel.showSaveConfirmation)
```

Pause/resume action:

```swift
viewModel.togglePause()
```

Finish action:

```swift
viewModel.finishRecording()
```

Try-analysis-again action:

```swift
viewModel.finishRecording()
```

- [ ] **Step 4: Update Reflection sheet logic**

Replace the `ReflectionView` full-screen cover content with:

```swift
ReflectionView(
    entry: viewModel.pendingEntry,
    session: viewModel.pendingSession,
    onSessionChange: { session in
        viewModel.applySessionChange(session)
    }
) { entry, destination in
    viewModel.savePendingEntry(
        entry,
        journalStore: journalStore,
        aiSessionStore: aiSessionStore
    )

    switch destination {
    case .confirmation:
        viewModel.showConfirmationAfterSave()
    case .tips:
        onViewTips()
        dismiss()
    }
}
```

- [ ] **Step 5: Update SaveConfirmation sheet logic**

Replace the `SaveConfirmationView` full-screen cover content with:

```swift
SaveConfirmationView(entry: viewModel.savedEntry) {
    viewModel.clearSaveConfirmation()
    dismiss()
} onViewJournal: {
    viewModel.clearSaveConfirmation()
    onViewJournal()
    dismiss()
} onRecordAnother: {
    viewModel.clearSaveConfirmation()
    viewModel.resetForAnotherRecording()
}
```

- [ ] **Step 6: Remove migrated private helpers**

Delete these members from `RecordingView.swift` after the ViewModel is wired:

- `private var subtitle: String`
- `private func finishRecording()`
- `private var effectiveTranscript: String`
- `private var canFinish: Bool`
- `private var transcriptQuality: TranscriptQuality`
- `private var finishActionTitle: String`
- `private func resetForAnotherRecording()`
- `private func formattedTime(_ seconds: Int) -> String`
- `private func persistPendingSession(for entry: JournalReflectionEntry)`

Keep these layout helpers in `RecordingView.swift`:

- `private var recordingHeader: some View`
- `private var transcriptPanel: some View`
- `private var permissionReadinessRow: some View`
- `private func permissionBadge(title: String, state: VoicePermissionState) -> some View`
- `private func permissionColor(for state: VoicePermissionState) -> Color`
- `private var analyzingOverlay: some View`
- `private func recordingAction(title: String, icon: String, background: Color, foreground: Color, action: @escaping () -> Void) -> some View`

- [ ] **Step 7: Run build**

Run:

```bash
xcodebuild -project Circleu.xcodeproj -scheme Circleu -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected:

```text
** BUILD SUCCEEDED **
```

## Task 3: Verify Behavior And Commit

**Files:**

- Verify: `Circleu/Features/Recording/RecordingView.swift`
- Verify: `Circleu/Features/Recording/RecordingViewModel.swift`

- [ ] **Step 1: Inspect the diff**

Run:

```bash
git diff -- Circleu/Features/Recording/RecordingView.swift Circleu/Features/Recording/RecordingViewModel.swift
```

Expected:

- `RecordingViewModel.swift` contains the moved controller logic.
- `RecordingView.swift` no longer has AI analysis task logic, pending session persistence logic, or transcript quality computed properties.
- SwiftUI layout helpers remain in `RecordingView.swift`.

- [ ] **Step 2: Run final build**

Run:

```bash
xcodebuild -project Circleu.xcodeproj -scheme Circleu -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Expected:

```text
** BUILD SUCCEEDED **
```

- [ ] **Step 3: Manual smoke test on simulator or phone**

Use Xcode Run on iPhone 17 Pro simulator or the connected iPhone.

Smoke-test path:

```text
Home -> Record now -> type at least 8 words -> Finish -> Reflection -> Save -> confirmation -> View Journal
```

Expected:

- Recording screen opens.
- Close and replay buttons remain tappable.
- Typed fallback text enables Finish after enough words.
- Reflection screen opens after analysis.
- Save confirmation opens after saving.
- View Journal navigates to the Journal tab.

- [ ] **Step 4: Commit**

Run:

```bash
git add Circleu/Features/Recording/RecordingView.swift Circleu/Features/Recording/RecordingViewModel.swift
git commit -m "refactor(recording): introduce recording view model"
```

Expected:

- One feature-scoped commit.
- No unrelated files included.

## Follow-Up Plans

After this plan passes and is reviewed, write the next plan for `ReflectionViewModel`. The recommended migration order from the spec remains:

```text
RecordingViewModel -> ReflectionViewModel -> JournalViewModel -> TipsViewModel -> CircleViewModel -> ProfileViewModel
```
