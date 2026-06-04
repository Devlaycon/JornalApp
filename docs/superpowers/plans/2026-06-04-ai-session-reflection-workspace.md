# AI Session Reflection Workspace Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build local AI session history, AI Lab QA tooling, editable journal reflection workspaces, and backend-prep interfaces without adding a real backend.

**Architecture:** Add `AIReflectionSession` as a separate model/store from `JournalReflectionEntry`, then route analysis through `ReflectionSessionRunner` so every AI attempt is captured. Journal entries remain the user-facing source of truth, while session history is the model-evaluation source of truth used by Reflection, Journal detail, and Profile QA tools.

**Tech Stack:** SwiftUI, Combine, Foundation, UserDefaults JSON persistence, AVFoundation/Speech through existing services, local-first `ReflectionAnalyzing` engine abstraction.

---

## File Structure

Create:

- `Circleu/Models/AIReflectionSession.swift`: Codable session, attempt, status, source, export helpers.
- `Circleu/Stores/AIReflectionSessionStore.swift`: local persistence and session mutation APIs.
- `Circleu/Engines/ReflectionSessionRunner.swift`: wraps `ReflectionAnalyzing` and records timed attempts.
- `Circleu/Services/BackendPreparation.swift`: future provider protocols plus local no-op implementations.
- `Circleu/Features/Profile/AIReflectionLabView.swift`: QA session list and detail UI.
- `Circleu/Features/Journal/JournalWorkspaceEditSheet.swift`: lightweight edit UI for saved reflection workspace fields.

Modify:

- `Circleu/App/ContentView.swift`: inject `AIReflectionSessionStore`.
- `Circleu/App/RootView.swift`: preview environment injection.
- `Circleu/Models/ReflectionEntry.swift`: add editable workspace fields and display helpers.
- `Circleu/Stores/ReflectionJournalStore.swift`: update/edit/link APIs and edited-value export.
- `Circleu/Stores/QuestStore.swift`: use edited quest display when reactivating.
- `Circleu/Stores/CircleStore.swift`: use edited reflection display when sharing.
- `Circleu/Features/Recording/RecordingView.swift`: run analysis through `ReflectionSessionRunner`.
- `Circleu/Features/Reflection/ReflectionView.swift`: show session metadata and append regenerate attempts.
- `Circleu/Features/Journal/JournalEntryDetailView.swift`: add workspace sections, edit sheet, session history, edited-value share.
- `Circleu/Features/Journal/JournalCircleShareSheet.swift`: use latest edited display values.
- `Circleu/Features/Profile/ProfileQAToolsSheet.swift`: add AI Lab entry point, session counts, export/reset/seed integration.
- `docs/domain-models.md`: document AI session model.
- `docs/project-structure.md`: document backend-prep services.
- `docs/phone-test-checklist.md`: add AI Lab and workspace QA steps.
- `docs/release-readiness.md`: update MVP coverage.

Use the same simulator build after Swift slices:

```bash
xcodebuild -project Circleu.xcodeproj -scheme Circleu -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -configuration Debug build
```

Expected: `** BUILD SUCCEEDED **`

---

### Task 1: AI Session Models

**Files:**
- Create: `Circleu/Models/AIReflectionSession.swift`
- Modify: `Circleu/Models/ReflectionEntry.swift`

- [ ] **Step 1: Add the AI session model**

Create `Circleu/Models/AIReflectionSession.swift`:

```swift
import Foundation

enum AIReflectionSource: String, Codable, CaseIterable {
    case recording
    case typedFallback
    case journalRegeneration
    case qaSeed

    var label: String {
        switch self {
        case .recording:
            return "Recording"
        case .typedFallback:
            return "Typed fallback"
        case .journalRegeneration:
            return "Journal regeneration"
        case .qaSeed:
            return "QA seed"
        }
    }
}

enum AIReflectionAttemptStatus: String, Codable {
    case succeeded
    case failed
    case cancelled

    var label: String {
        switch self {
        case .succeeded:
            return "Succeeded"
        case .failed:
            return "Failed"
        case .cancelled:
            return "Cancelled"
        }
    }
}

struct AIReflectionAttempt: Identifiable, Codable, Equatable {
    let id: UUID
    var createdAt: Date
    var engineName: String
    var status: AIReflectionAttemptStatus
    var result: AIReflectionResult?
    var errorMessage: String?
    var elapsedMilliseconds: Int?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        engineName: String,
        status: AIReflectionAttemptStatus,
        result: AIReflectionResult? = nil,
        errorMessage: String? = nil,
        elapsedMilliseconds: Int? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.engineName = engineName
        self.status = status
        self.result = result
        self.errorMessage = errorMessage
        self.elapsedMilliseconds = elapsedMilliseconds
    }
}

struct AIReflectionSession: Identifiable, Codable, Equatable {
    let id: UUID
    var createdAt: Date
    var updatedAt: Date
    var entryID: UUID?
    var engineName: String
    var source: AIReflectionSource
    var transcript: String
    var durationSeconds: Int
    var attempts: [AIReflectionAttempt]
    var selectedAttemptID: UUID?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        entryID: UUID? = nil,
        engineName: String,
        source: AIReflectionSource,
        transcript: String,
        durationSeconds: Int,
        attempts: [AIReflectionAttempt] = [],
        selectedAttemptID: UUID? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.entryID = entryID
        self.engineName = engineName
        self.source = source
        self.transcript = transcript
        self.durationSeconds = durationSeconds
        self.attempts = attempts
        self.selectedAttemptID = selectedAttemptID
    }

    var selectedAttempt: AIReflectionAttempt? {
        if let selectedAttemptID,
           let selected = attempts.first(where: { $0.id == selectedAttemptID }) {
            return selected
        }

        return attempts.last(where: { $0.status == .succeeded }) ?? attempts.last
    }

    var selectedResult: AIReflectionResult? {
        selectedAttempt?.result
    }

    var latestErrorMessage: String? {
        attempts.last(where: { $0.status == .failed })?.errorMessage
    }

    var wordCount: Int {
        transcript.split(whereSeparator: { $0.isWhitespace }).count
    }

    var succeededAttemptCount: Int {
        attempts.filter { $0.status == .succeeded }.count
    }

    var failedAttemptCount: Int {
        attempts.filter { $0.status == .failed }.count
    }

    var exportText: String {
        let attemptLines = attempts.map { attempt in
            """
            Attempt: \(attempt.createdAt.formatted(date: .abbreviated, time: .shortened))
            Engine: \(attempt.engineName)
            Status: \(attempt.status.label)
            Elapsed: \(attempt.elapsedMilliseconds.map { "\($0) ms" } ?? "Unknown")
            Result: \(attempt.result?.title ?? "No result")
            Error: \(attempt.errorMessage ?? "None")
            """
        }
        .joined(separator: "\n\n")

        return """
        AI Reflection Session

        Session: \(id.uuidString)
        Source: \(source.label)
        Engine: \(engineName)
        Created: \(createdAt.formatted(date: .complete, time: .shortened))
        Transcript words: \(wordCount)
        Duration: \(durationSeconds)s
        Linked entry: \(entryID?.uuidString ?? "Not saved")

        Transcript
        \(transcript)

        Attempts
        \(attemptLines.isEmpty ? "No attempts recorded." : attemptLines)
        """
    }
}
```

- [ ] **Step 2: Extend `JournalReflectionEntry` with editable fields**

Modify `Circleu/Models/ReflectionEntry.swift`.

Change the stored properties:

```swift
struct JournalReflectionEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var createdAt: Date
    var durationSeconds: Int
    var transcript: String
    var engineName: String
    var result: AIReflectionResult
    var sessionID: UUID?
    var editableTitle: String?
    var editableEmotion: String?
    var privateNote: String
    var tags: [String]
    var lastEditedAt: Date?
```

Change the initializer signature:

```swift
init(
    id: UUID = UUID(),
    createdAt: Date = Date(),
    durationSeconds: Int,
    transcript: String,
    engineName: String,
    result: AIReflectionResult,
    sessionID: UUID? = nil,
    editableTitle: String? = nil,
    editableEmotion: String? = nil,
    privateNote: String = "",
    tags: [String] = [],
    lastEditedAt: Date? = nil
) {
    self.id = id
    self.createdAt = createdAt
    self.durationSeconds = durationSeconds
    self.transcript = transcript
    self.engineName = engineName
    self.result = result
    self.sessionID = sessionID
    self.editableTitle = editableTitle
    self.editableEmotion = editableEmotion
    self.privateNote = privateNote
    self.tags = tags
    self.lastEditedAt = lastEditedAt
}
```

Add display helpers below the initializer:

```swift
var displayTitle: String {
    sanitized(editableTitle, fallback: result.title)
}

var displayEmotion: String {
    sanitized(editableEmotion, fallback: result.emotion)
}

var displayQuest: String {
    result.suggestedQuest
}

var displaySummary: String {
    result.summary
}

private func sanitized(_ value: String?, fallback: String) -> String {
    guard let value else { return fallback }
    let clean = value
        .split(whereSeparator: { $0.isWhitespace })
        .joined(separator: " ")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    return clean.isEmpty ? fallback : clean
}
```

- [ ] **Step 3: Build**

Run:

```bash
xcodebuild -project Circleu.xcodeproj -scheme Circleu -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -configuration Debug build
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add Circleu/Models/AIReflectionSession.swift Circleu/Models/ReflectionEntry.swift
git commit -m "feat: add ai session models"
```

---

### Task 2: AI Session Store

**Files:**
- Create: `Circleu/Stores/AIReflectionSessionStore.swift`
- Modify: `Circleu/App/ContentView.swift`
- Modify: `Circleu/App/RootView.swift`

- [ ] **Step 1: Add the store**

Create `Circleu/Stores/AIReflectionSessionStore.swift`:

```swift
import Combine
import Foundation

@MainActor
final class AIReflectionSessionStore: ObservableObject {
    @Published private(set) var sessions: [AIReflectionSession] = []

    private let storageKey = "circleu.aiReflectionSessions.v1"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        load()
    }

    func add(_ session: AIReflectionSession) {
        guard !sessions.contains(where: { $0.id == session.id }) else { return }
        sessions.insert(session, at: 0)
        save()
    }

    func upsert(_ session: AIReflectionSession) {
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
        } else {
            sessions.insert(session, at: 0)
        }
        sessions.sort { $0.updatedAt > $1.updatedAt }
        save()
    }

    func append(_ attempt: AIReflectionAttempt, to sessionID: UUID) {
        guard let index = sessions.firstIndex(where: { $0.id == sessionID }) else { return }
        sessions[index].attempts.append(attempt)
        sessions[index].updatedAt = Date()
        if attempt.status == .succeeded {
            sessions[index].selectedAttemptID = attempt.id
            sessions[index].engineName = attempt.engineName
        }
        sessions.sort { $0.updatedAt > $1.updatedAt }
        save()
    }

    func link(sessionID: UUID, to entryID: UUID) {
        guard let index = sessions.firstIndex(where: { $0.id == sessionID }) else { return }
        sessions[index].entryID = entryID
        sessions[index].updatedAt = Date()
        save()
    }

    func selectAttempt(_ attemptID: UUID, in sessionID: UUID) {
        guard let index = sessions.firstIndex(where: { $0.id == sessionID }),
              sessions[index].attempts.contains(where: { $0.id == attemptID && $0.status == .succeeded }) else {
            return
        }

        sessions[index].selectedAttemptID = attemptID
        sessions[index].updatedAt = Date()
        save()
    }

    func session(with id: UUID?) -> AIReflectionSession? {
        guard let id else { return nil }
        return sessions.first { $0.id == id }
    }

    func replaceAll(with newSessions: [AIReflectionSession]) {
        sessions = newSessions.sorted { $0.updatedAt > $1.updatedAt }
        save()
    }

    func reset() {
        sessions = []
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    func exportText() -> String {
        guard !sessions.isEmpty else {
            return "Circleu AI Sessions\n\nNo AI sessions recorded yet."
        }

        return "Circleu AI Sessions\n\n" + sessions.map(\.exportText).joined(separator: "\n\n---\n\n")
    }

    func seedDemoData(entries: [JournalReflectionEntry], referenceDate: Date = Date()) {
        let demoSessions = entries.map { entry in
            let attempt = AIReflectionAttempt(
                createdAt: entry.createdAt,
                engineName: entry.engineName,
                status: .succeeded,
                result: entry.result,
                elapsedMilliseconds: 420
            )

            return AIReflectionSession(
                id: entry.sessionID ?? UUID(),
                createdAt: entry.createdAt,
                updatedAt: entry.createdAt,
                entryID: entry.id,
                engineName: entry.engineName,
                source: .qaSeed,
                transcript: entry.transcript,
                durationSeconds: entry.durationSeconds,
                attempts: [attempt],
                selectedAttemptID: attempt.id
            )
        }

        replaceAll(with: demoSessions)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let savedSessions = try? decoder.decode([AIReflectionSession].self, from: data) else {
            sessions = []
            return
        }

        sessions = savedSessions.sorted { $0.updatedAt > $1.updatedAt }
    }

    private func save() {
        guard let data = try? encoder.encode(sessions) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
```

- [ ] **Step 2: Inject the store**

Modify `Circleu/App/ContentView.swift`:

```swift
@StateObject private var aiSessionStore = AIReflectionSessionStore()
```

Add the environment object:

```swift
.environmentObject(aiSessionStore)
```

Modify the `RootView` preview in `Circleu/App/RootView.swift`:

```swift
.environmentObject(AIReflectionSessionStore())
```

- [ ] **Step 3: Build**

Run the simulator build command.

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add Circleu/Stores/AIReflectionSessionStore.swift Circleu/App/ContentView.swift Circleu/App/RootView.swift
git commit -m "feat: add ai session store"
```

---

### Task 3: Session Runner

**Files:**
- Create: `Circleu/Engines/ReflectionSessionRunner.swift`

- [ ] **Step 1: Add runner value type**

Create `Circleu/Engines/ReflectionSessionRunner.swift`:

```swift
import Foundation

struct ReflectionSessionRunResult {
    var session: AIReflectionSession
    var attempt: AIReflectionAttempt

    var result: AIReflectionResult? {
        attempt.result
    }
}

struct ReflectionSessionRunner {
    func analyze(
        transcript: String,
        durationSeconds: Int,
        source: AIReflectionSource,
        engine: any ReflectionAnalyzing,
        existingSession: AIReflectionSession? = nil
    ) async -> ReflectionSessionRunResult {
        let start = Date()
        let cleanTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)

        var session = existingSession ?? AIReflectionSession(
            engineName: engine.displayName,
            source: source,
            transcript: cleanTranscript,
            durationSeconds: durationSeconds
        )

        session.engineName = engine.displayName
        session.source = source
        session.transcript = cleanTranscript
        session.durationSeconds = durationSeconds
        session.updatedAt = Date()

        do {
            let result = try await engine.analyze(
                transcript: cleanTranscript,
                durationSeconds: durationSeconds
            )
            let elapsed = Int(Date().timeIntervalSince(start) * 1_000)
            let attempt = AIReflectionAttempt(
                engineName: engine.displayName,
                status: .succeeded,
                result: result,
                elapsedMilliseconds: elapsed
            )
            session.attempts.append(attempt)
            session.selectedAttemptID = attempt.id
            session.updatedAt = Date()
            return ReflectionSessionRunResult(session: session, attempt: attempt)
        } catch {
            let elapsed = Int(Date().timeIntervalSince(start) * 1_000)
            let attempt = AIReflectionAttempt(
                engineName: engine.displayName,
                status: .failed,
                errorMessage: error.localizedDescription,
                elapsedMilliseconds: elapsed
            )
            session.attempts.append(attempt)
            session.updatedAt = Date()
            return ReflectionSessionRunResult(session: session, attempt: attempt)
        }
    }
}
```

- [ ] **Step 2: Build**

Run the simulator build command.

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add Circleu/Engines/ReflectionSessionRunner.swift
git commit -m "feat: track reflection analysis attempts"
```

---

### Task 4: Recording And Reflection Session Wiring

**Files:**
- Modify: `Circleu/Features/Recording/RecordingView.swift`
- Modify: `Circleu/Features/Reflection/ReflectionView.swift`

- [ ] **Step 1: Wire Recording to create sessions**

In `RecordingView`, add environment and state:

```swift
@EnvironmentObject private var aiSessionStore: AIReflectionSessionStore
@State private var sessionRunner = ReflectionSessionRunner()
@State private var pendingSession: AIReflectionSession?
```

In `finishRecording()`, replace the direct `engine.analyze` call with:

```swift
let source: AIReflectionSource = recorder.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .typedFallback : .recording
let run = await sessionRunner.analyze(
    transcript: transcript,
    durationSeconds: recorder.elapsedSeconds,
    source: source,
    engine: engine
)
guard !Task.isCancelled else { return }

await MainActor.run {
    aiSessionStore.upsert(run.session)

    guard let result = run.result else {
        isAnalyzing = false
        analysisTask = nil
        analysisMessage = run.attempt.errorMessage ?? "AI analysis failed. Please try again."
        return
    }

    let entry = JournalReflectionEntry(
        durationSeconds: recorder.elapsedSeconds,
        transcript: transcript,
        engineName: run.attempt.engineName,
        result: result,
        sessionID: run.session.id
    )

    pendingEntry = entry
    pendingSession = run.session
    isAnalyzing = false
    analysisTask = nil
    showReflection = true
}
```

Keep the existing `catch` block only for task-level failures. The runner converts engine failures into failed attempts.

Update the full-screen cover:

```swift
ReflectionView(entry: pendingEntry, session: pendingSession) { entry in
    journalStore.add(entry)
    if let sessionID = entry.sessionID {
        aiSessionStore.link(sessionID: sessionID, to: entry.id)
    }
    savedEntry = entry
    showReflection = false
    showSaveConfirmation = true
}
```

- [ ] **Step 2: Wire Reflection regeneration to append attempts**

In `ReflectionView`, add:

```swift
@EnvironmentObject private var aiSessionStore: AIReflectionSessionStore
@State private var draftSession: AIReflectionSession?
@State private var sessionRunner = ReflectionSessionRunner()
```

Change the initializer:

```swift
init(
    entry: JournalReflectionEntry? = nil,
    session: AIReflectionSession? = nil,
    onSave: ((JournalReflectionEntry) -> Void)? = nil
) {
    self.onSave = onSave
    _draftEntry = State(initialValue: entry)
    _draftSession = State(initialValue: session)
}
```

Update `regenerateReflection()` to call the runner:

```swift
guard !hasSaved, let draftEntry, !isRegenerating else { return }

regenerateTask?.cancel()
isRegenerating = true
regenerateMessage = nil

regenerateTask = Task {
    let run = await sessionRunner.analyze(
        transcript: draftEntry.transcript,
        durationSeconds: draftEntry.durationSeconds,
        source: .journalRegeneration,
        engine: engine,
        existingSession: draftSession
    )
    guard !Task.isCancelled else { return }

    await MainActor.run {
        draftSession = run.session
        aiSessionStore.upsert(run.session)

        if let result = run.result {
            self.draftEntry?.result = result
            self.draftEntry?.engineName = run.attempt.engineName
            self.draftEntry?.sessionID = run.session.id
            self.regenerateMessage = "Generated attempt \(run.session.attempts.count) with \(run.attempt.engineName)."
        } else {
            self.regenerateMessage = run.attempt.errorMessage ?? "Regeneration failed. Your previous reflection is still available."
        }

        self.isRegenerating = false
        self.regenerateTask = nil
    }
}
```

Add a compact session status below the quote card:

```swift
private var sessionStatusCard: some View {
    VStack(alignment: .leading, spacing: 8) {
        Label("AI Session", systemImage: "cpu")
            .font(.system(size: 17, weight: .bold, design: .rounded))
            .foregroundStyle(PinguDesign.ink)

        Text(sessionStatusText)
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundStyle(PinguDesign.muted)
            .lineSpacing(4)
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.white)
    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
}

private var sessionStatusText: String {
    guard let draftSession else {
        return "This reflection has no AI session metadata yet."
    }

    return "\(draftSession.source.label) • \(draftSession.engineName) • \(draftSession.attempts.count) attempts • \(draftSession.wordCount) words"
}
```

Render `sessionStatusCard` before `regenerationStatus`.

- [ ] **Step 3: Update previews**

Add `.environmentObject(AIReflectionSessionStore())` to `RecordingView` and `ReflectionView` previews.

- [ ] **Step 4: Build**

Run the simulator build command.

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add Circleu/Features/Recording/RecordingView.swift Circleu/Features/Reflection/ReflectionView.swift
git commit -m "feat: connect reflections to ai sessions"
```

---

### Task 5: AI Lab In QA Tools

**Files:**
- Create: `Circleu/Features/Profile/AIReflectionLabView.swift`
- Modify: `Circleu/Features/Profile/ProfileQAToolsSheet.swift`

- [ ] **Step 1: Create AI Lab view**

Create `Circleu/Features/Profile/AIReflectionLabView.swift`:

```swift
import SwiftUI
import UIKit

struct AIReflectionLabView: View {
    @EnvironmentObject private var aiSessionStore: AIReflectionSessionStore
    @State private var selectedSession: AIReflectionSession?
    @State private var statusMessage = "Inspect local AI sessions from this iPhone."

    var body: some View {
        ZStack {
            PinguScreenBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    exportCard

                    if aiSessionStore.sessions.isEmpty {
                        emptyState
                    } else {
                        ForEach(aiSessionStore.sessions) { session in
                            sessionRow(session)
                        }
                    }
                }
                .padding(.horizontal, PinguDesign.screenSidePadding)
                .padding(.top, 18)
                .padding(.bottom, 34)
            }
        }
        .navigationTitle("AI Lab")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedSession) { session in
            NavigationStack {
                ScrollView(showsIndicators: false) {
                    Text(session.exportText)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(PinguDesign.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                }
                .navigationTitle("Session Detail")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Copy") {
                            UIPasteboard.general.string = session.exportText
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AI Lab")
                .font(.system(size: 31, weight: .bold, design: .rounded))
                .foregroundStyle(PinguDesign.ink)

            Text(statusMessage)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(PinguDesign.muted)
                .lineSpacing(4)
        }
    }

    private var exportCard: some View {
        HStack(spacing: 10) {
            Button {
                UIPasteboard.general.string = aiSessionStore.exportText()
                statusMessage = "Copied all AI session data."
            } label: {
                Label("Copy AI QA", systemImage: "doc.on.doc")
            }
            .buttonStyle(PinguSecondaryButtonStyle())

            ShareLink(item: aiSessionStore.exportText()) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(PinguPrimaryButtonStyle())
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "cpu")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(PinguDesign.blue)

            Text("No AI sessions yet")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(PinguDesign.ink)

            Text("Record or type a reflection, then return here to inspect the engine output.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(PinguDesign.muted)
                .lineSpacing(4)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func sessionRow(_ session: AIReflectionSession) -> some View {
        Button {
            selectedSession = session
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(session.selectedResult?.title ?? "No successful result")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(PinguDesign.ink)
                        .lineLimit(2)

                    Spacer()

                    Text(session.source.label)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(PinguDesign.blue)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(PinguDesign.lightBlue.opacity(0.7))
                        .clipShape(Capsule())
                }

                Text("\(session.engineName) • \(session.attempts.count) attempts • \(session.wordCount) words")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(PinguDesign.muted)

                Text(session.updatedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(PinguDesign.muted.opacity(0.8))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
```

- [ ] **Step 2: Add QA tools integration**

In `ProfileQAToolsSheet`, add:

```swift
@EnvironmentObject private var aiSessionStore: AIReflectionSessionStore
@State private var showAILab = false
```

In `dataCard`, add:

```swift
ProfileDataRow(title: "AI sessions", value: "\(aiSessionStore.sessions.count)")
```

In `actionsCard`, add before reset:

```swift
Button {
    showAILab = true
} label: {
    Label("Open AI Lab", systemImage: "cpu")
}
.buttonStyle(PinguSecondaryButtonStyle())
```

Add navigation destination or sheet:

```swift
.sheet(isPresented: $showAILab) {
    NavigationStack {
        AIReflectionLabView()
            .environmentObject(aiSessionStore)
    }
}
```

Add AI export to `qaExport`:

```swift
\(aiSessionStore.exportText())
```

In `seedDemoData()` after `journalStore.replaceAll(with: entries)`:

```swift
aiSessionStore.seedDemoData(entries: entries, referenceDate: referenceDate)
```

In `resetLocalData()`:

```swift
aiSessionStore.reset()
```

- [ ] **Step 3: Build**

Run the simulator build command.

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add Circleu/Features/Profile/AIReflectionLabView.swift Circleu/Features/Profile/ProfileQAToolsSheet.swift
git commit -m "feat: add ai lab qa tools"
```

---

### Task 6: Editable Journal Workspace Store APIs

**Files:**
- Modify: `Circleu/Stores/ReflectionJournalStore.swift`
- Modify: `Circleu/Stores/QuestStore.swift`
- Modify: `Circleu/Stores/CircleStore.swift`

- [ ] **Step 1: Add journal update APIs**

In `ReflectionJournalStore`, add methods:

```swift
func updateWorkspace(
    entry: JournalReflectionEntry,
    title: String,
    emotion: String,
    privateNote: String,
    tags: [String]
) {
    guard let index = entries.firstIndex(where: { $0.id == entry.id }) else { return }
    entries[index].editableTitle = sanitizedOptional(title)
    entries[index].editableEmotion = sanitizedOptional(emotion)
    entries[index].privateNote = sanitized(privateNote, fallback: "")
    entries[index].tags = tags
        .map { sanitized($0, fallback: "") }
        .filter { !$0.isEmpty }
    entries[index].lastEditedAt = Date()
    save()
}

func attach(sessionID: UUID, to entryID: UUID) {
    guard let index = entries.firstIndex(where: { $0.id == entryID }) else { return }
    entries[index].sessionID = sessionID
    entries[index].lastEditedAt = Date()
    save()
}

func replaceResult(entryID: UUID, result: AIReflectionResult, engineName: String, sessionID: UUID?) {
    guard let index = entries.firstIndex(where: { $0.id == entryID }) else { return }
    entries[index].result = result
    entries[index].engineName = engineName
    entries[index].sessionID = sessionID ?? entries[index].sessionID
    entries[index].lastEditedAt = Date()
    save()
}

func entry(with id: UUID) -> JournalReflectionEntry? {
    entries.first { $0.id == id }
}

private func sanitizedOptional(_ value: String) -> String? {
    let clean = sanitized(value, fallback: "")
    return clean.isEmpty ? nil : clean
}

private func sanitized(_ value: String, fallback: String) -> String {
    let clean = value
        .split(whereSeparator: { $0.isWhitespace })
        .joined(separator: " ")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    return clean.isEmpty ? fallback : String(clean.prefix(280))
}
```

Update `shareText(for:)` to use display fields:

```swift
\(entry.displayTitle)
...
Emotion: \(entry.displayEmotion)
...
Private Note
\(entry.privateNote.isEmpty ? "None" : entry.privateNote)
```

- [ ] **Step 2: Update quest store to use edited quest source**

In `QuestStore.activateSuggestedQuest(from:)`, keep `entry.result.suggestedQuest` for quest detail because quest editing is not stored on `JournalReflectionEntry` in this phase. Use `entry.displayTitle` if a title is needed in later labels. No change is required if the current implementation only stores `"Try this next"`.

- [ ] **Step 3: Update circle sharing**

In `CircleStore.share(entry:to:)`, replace:

```swift
title: entry.result.title,
body: "\(entry.result.summary)\n\nQuest: \(entry.result.suggestedQuest)",
```

with:

```swift
title: entry.displayTitle,
body: "\(entry.displaySummary)\n\nQuest: \(entry.displayQuest)",
```

In `seedDemoData`, replace `latestEntry.result.title` with `latestEntry.displayTitle`.

- [ ] **Step 4: Build**

Run the simulator build command.

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add Circleu/Stores/ReflectionJournalStore.swift Circleu/Stores/QuestStore.swift Circleu/Stores/CircleStore.swift
git commit -m "feat: add editable reflection store APIs"
```

---

### Task 7: Journal Workspace UI

**Files:**
- Create: `Circleu/Features/Journal/JournalWorkspaceEditSheet.swift`
- Modify: `Circleu/Features/Journal/JournalEntryDetailView.swift`
- Modify: `Circleu/Features/Journal/JournalCircleShareSheet.swift`

- [ ] **Step 1: Add edit sheet**

Create `Circleu/Features/Journal/JournalWorkspaceEditSheet.swift`:

```swift
import SwiftUI

struct JournalWorkspaceEditSheet: View {
    let entry: JournalReflectionEntry
    var onSave: (String, String, String, [String]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var emotion: String
    @State private var privateNote: String
    @State private var tagsText: String

    init(entry: JournalReflectionEntry, onSave: @escaping (String, String, String, [String]) -> Void) {
        self.entry = entry
        self.onSave = onSave
        _title = State(initialValue: entry.displayTitle)
        _emotion = State(initialValue: entry.displayEmotion)
        _privateNote = State(initialValue: entry.privateNote)
        _tagsText = State(initialValue: entry.tags.joined(separator: ", "))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PinguScreenBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        PinguTextInput(title: "Title", placeholder: "Reflection title", text: $title)
                        PinguTextInput(title: "Emotion", placeholder: "Emotion tag", text: $emotion)
                        PinguTextInput(title: "Private note", placeholder: "What do you want to remember?", text: $privateNote, axis: .vertical)
                        PinguTextInput(title: "Tags", placeholder: "confidence, class, practice", text: $tagsText)
                    }
                    .padding(.horizontal, PinguDesign.screenSidePadding)
                    .padding(.top, 20)
                    .padding(.bottom, 34)
                }
            }
            .navigationTitle("Edit Reflection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(title, emotion, privateNote, parsedTags)
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }

    private var parsedTags: [String] {
        tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
```

- [ ] **Step 2: Use live entry in detail view**

In `JournalEntryDetailView`, add:

```swift
@EnvironmentObject private var aiSessionStore: AIReflectionSessionStore
@State private var showEditSheet = false

private var currentEntry: JournalReflectionEntry {
    journalStore.entry(with: entry.id) ?? entry
}

private var session: AIReflectionSession? {
    aiSessionStore.session(with: currentEntry.sessionID)
}
```

Replace visible `entry` references with `currentEntry` where the user sees reflection fields, transcript, title, emotion, share text, delete action, and circle share sheet.

Add an edit button in the toolbar menu:

```swift
Button {
    showEditSheet = true
} label: {
    Label("Edit workspace", systemImage: "pencil")
}
```

Add sheet:

```swift
.sheet(isPresented: $showEditSheet) {
    JournalWorkspaceEditSheet(entry: currentEntry) { title, emotion, privateNote, tags in
        journalStore.updateWorkspace(
            entry: currentEntry,
            title: title,
            emotion: emotion,
            privateNote: privateNote,
            tags: tags
        )
    }
    .presentationDetents([.medium, .large])
}
```

Add workspace cards after `practiceActionsCard`:

```swift
workspaceCard
sessionHistoryCard
```

Use these view properties:

```swift
private var workspaceCard: some View {
    VStack(alignment: .leading, spacing: 10) {
        Label("Workspace", systemImage: "pencil.and.list.clipboard")
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(PinguDesign.ink)

        Text(currentEntry.privateNote.isEmpty ? "No private note yet." : currentEntry.privateNote)
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .foregroundStyle(PinguDesign.body)
            .lineSpacing(4)

        if !currentEntry.tags.isEmpty {
            Text(currentEntry.tags.map { "#\($0)" }.joined(separator: " "))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(PinguDesign.blue)
        }

        if let lastEditedAt = currentEntry.lastEditedAt {
            Text("Edited \(lastEditedAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(PinguDesign.muted)
        }
    }
    .padding(18)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.white)
    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
}

private var sessionHistoryCard: some View {
    VStack(alignment: .leading, spacing: 10) {
        Label("AI session", systemImage: "cpu")
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(PinguDesign.ink)

        if let session {
            Text("\(session.engineName) • \(session.attempts.count) attempts • \(session.wordCount) words")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(PinguDesign.muted)

            Text(session.selectedAttempt?.status.label ?? "No selected attempt")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(PinguDesign.blue)
        } else {
            Text("No AI session metadata is linked to this reflection.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(PinguDesign.muted)
        }
    }
    .padding(18)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(.white)
    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
}
```

- [ ] **Step 3: Update circle share sheet**

In `JournalCircleShareSheet`, display `entry.displayTitle` in any saved/share context. The sheet mostly delegates to `CircleStore.share`, so no additional store mutation is required.

- [ ] **Step 4: Build**

Run the simulator build command.

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add Circleu/Features/Journal/JournalWorkspaceEditSheet.swift Circleu/Features/Journal/JournalEntryDetailView.swift Circleu/Features/Journal/JournalCircleShareSheet.swift
git commit -m "feat: add editable journal workspace"
```

---

### Task 8: Backend Prep Protocols

**Files:**
- Create: `Circleu/Services/BackendPreparation.swift`
- Modify: `docs/project-structure.md`

- [ ] **Step 1: Add local no-op provider protocols**

Create `Circleu/Services/BackendPreparation.swift`:

```swift
import Foundation

protocol ReflectionModelProvider {
    var providerName: String { get }
    var isAvailable: Bool { get }
}

protocol ReflectionSyncing {
    func syncIfNeeded() async
}

protocol UserIdentityProviding {
    var localUserID: String { get }
    var displayName: String { get }
}

protocol AnalyticsTracking {
    func track(event: String, properties: [String: String])
}

struct LocalReflectionModelProvider: ReflectionModelProvider {
    let providerName = "Local"
    let isAvailable = true
}

struct NoOpReflectionSyncer: ReflectionSyncing {
    func syncIfNeeded() async {}
}

struct LocalUserIdentityProvider: UserIdentityProviding {
    var localUserID: String {
        if let existing = UserDefaults.standard.string(forKey: "circleu.localUserID") {
            return existing
        }

        let created = UUID().uuidString
        UserDefaults.standard.set(created, forKey: "circleu.localUserID")
        return created
    }

    var displayName: String {
        UserDefaults.standard.string(forKey: "circleu.displayName") ?? "Friend"
    }
}

struct NoOpAnalyticsTracker: AnalyticsTracking {
    func track(event: String, properties: [String: String] = [:]) {}
}
```

- [ ] **Step 2: Update structure docs**

In `docs/project-structure.md`, add under Services:

```markdown
- `Services/BackendPreparation.swift` defines local no-op interfaces for future identity, sync, analytics, and model provider work. These protocols prepare the app for backend work without adding network calls or secrets.
```

- [ ] **Step 3: Build**

Run the simulator build command.

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add Circleu/Services/BackendPreparation.swift docs/project-structure.md
git commit -m "chore: add backend prep interfaces"
```

---

### Task 9: Documentation And Final Verification

**Files:**
- Modify: `docs/domain-models.md`
- Modify: `docs/phone-test-checklist.md`
- Modify: `docs/release-readiness.md`

- [ ] **Step 1: Update domain docs**

Add to `docs/domain-models.md` after AI Reflection Result:

```markdown
## AI Reflection Session

`AIReflectionSession` is the local record of how a reflection was generated.

It contains:

- source, such as recording, typed fallback, regeneration, or QA seed,
- transcript and duration,
- engine name,
- linked journal entry when saved,
- one or more attempts,
- selected successful attempt.

Journal entries are for the user's saved reflection. AI sessions are for model evaluation and QA.
```

- [ ] **Step 2: Update phone checklist**

Add to `docs/phone-test-checklist.md` under Recording Reliability Checks:

```markdown
10. Open **Profile > QA tools > AI Lab** and confirm the session appears.
11. Copy the AI QA export and confirm it includes transcript, engine, attempts, and status.
12. Open the saved Journal detail, edit title/emotion/private note/tags, and confirm the edited values appear after closing the sheet.
13. Share the edited reflection into a private circle and confirm the circle post uses the edited title.
```

- [ ] **Step 3: Update release readiness**

In `docs/release-readiness.md`, update MVP coverage to include:

```markdown
- AI Lab exposes local session history, attempt counts, and exportable QA data.
- Journal detail supports editable reflection workspace fields and AI session history.
```

- [ ] **Step 4: Final verification**

Run:

```bash
rg -n "TODO|FIXME|Lorem|lorem|coming soon|dummy" Circleu
```

Expected: no matches. If matches are legitimate labels, document them in the final response.

Run:

```bash
xcodebuild -project Circleu.xcodeproj -scheme Circleu -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' -configuration Debug build
```

Expected: `** BUILD SUCCEEDED **`

Run:

```bash
git status --short --branch
```

Expected: only the planned doc changes before commit.

- [ ] **Step 5: Commit**

```bash
git add docs/domain-models.md docs/phone-test-checklist.md docs/release-readiness.md
git commit -m "docs: update ai workspace qa"
```

- [ ] **Step 6: Push**

```bash
git push origin dev/mike
```

Expected: `dev/mike -> dev/mike`

---

## Spec Coverage Review

- AI Lab and evaluation tooling: Tasks 1, 2, 5, and 9.
- Editable Journal and Reflection detail workspace: Tasks 1, 6, 7, and 9.
- Backend prep through clean interfaces: Task 8.
- Local-first and no backend calls: Tasks 2 and 8 keep persistence local and protocols no-op.
- Recording to Reflection session creation: Tasks 3 and 4.
- Regeneration attempt history: Tasks 3 and 4.
- Exportable QA detail: Tasks 1, 2, 5, and 9.
- Edited values in sharing/export: Tasks 6 and 7.
- Phone QA docs and release notes: Task 9.
