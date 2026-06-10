# Backend Engine Stability Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Harden Circleu's Firebase QA reliability and local reflection engine behavior before TestFlight.

**Architecture:** Keep the app local-first. Extend `BackendSessionStore` with in-memory sync timing metadata and reuse existing QA tools for manual upload/restore controls. Add deterministic transcript classification inside the engine layer without introducing a new model provider or large Firestore rewrite.

**Tech Stack:** Swift, SwiftUI, XCTest, Firebase Auth, Cloud Firestore, Xcode iOS simulator.

---

## File Structure

- Modify `Circleu/Stores/BackendSessionStore.swift`
  - Owns backend session state, auth state, sync operation state, and new in-memory sync timing metadata.
- Modify `Circleu/Features/Profile/ProfileQAToolsSheet.swift`
  - Shows Firebase status, manual backup/restore actions, and new timing metadata for QA.
- Modify `Circleu/Features/Profile/ProfileView.swift`
  - Uses existing profile sync summary, updated only if new backend metadata makes the summary clearer.
- Modify `Circleu/Engines/ReflectionEngine.swift`
  - Adds deterministic local transcript classification and maps classifications to local feedback profiles.
- Modify `Circleu/Engines/TranscriptQuality.swift`
  - Keeps low-signal and rough-language helpers small and reusable by `ReflectionEngine`.
- Modify `CircleuTests/BackendSessionStoreTests.swift`
  - Covers upload/restore timing metadata and failure behavior.
- Modify `CircleuTests/EngineBehaviorTests.swift`
  - Covers boundary/conflict, rough/hostile, stress, short/low-signal, and neutral transcript behavior.
- Modify `docs/product/release-readiness.md`
  - Adds the new QA check for force upload/restore and engine rough/conflict behavior.

## Task 1: Backend Sync Timing Metadata

**Files:**
- Modify: `Circleu/Stores/BackendSessionStore.swift`
- Test: `CircleuTests/BackendSessionStoreTests.swift`

- [ ] **Step 1: Write failing tests for successful upload timing**

Add this test after `testUploadPrivateBackupUsesFirebaseUID()` in `CircleuTests/BackendSessionStoreTests.swift`:

```swift
func testUploadPrivateBackupTracksAttemptAndSuccessTimes() async {
    let journalStore = ReflectionJournalStore(userDefaults: makeDefaults())
    let syncer = CapturingSyncer()
    let authenticator = FakeFirebaseAuthenticator(
        currentSession: FirebaseAuthSession(
            uid: "firebase-user-1",
            email: "tuan@example.com",
            displayName: "Tuan",
            localUserID: "local-user-1"
        )
    )
    let store = BackendSessionStore(authenticator: authenticator, syncer: syncer)
    journalStore.add(makeEntry())

    await store.uploadPrivateBackup(
        profileStore: UserProfileStore(userDefaults: makeDefaults()),
        journalStore: journalStore,
        questStore: QuestStore(userDefaults: makeDefaults()),
        tipsPracticeStore: TipsPracticeStore(userDefaults: makeDefaults()),
        rewardsStore: RewardsStore(userDefaults: makeDefaults(), seedIfEmpty: false),
        circleStore: CircleStore(userDefaults: makeDefaults(), seedStarterSpaces: false),
        aiSessionStore: AIReflectionSessionStore(userDefaults: makeDefaults())
    )

    XCTAssertNotNil(store.lastSyncAttemptedAt)
    XCTAssertNotNil(store.lastUploadStartedAt)
    XCTAssertNotNil(store.lastUploadSucceededAt)
    XCTAssertNil(store.lastRestoreStartedAt)
    XCTAssertNil(store.lastRestoreSucceededAt)
    XCTAssertNil(store.lastSyncErrorMessage)
}
```

- [ ] **Step 2: Write failing tests for upload failure timing**

First update the test fakes at the bottom of `CircleuTests/BackendSessionStoreTests.swift` so failure behavior can be tested.

Change `CapturingSyncer` to:

```swift
private final class CapturingSyncer: ReflectionSyncing {
    var snapshots: [BackendSyncSnapshot] = []
    var error: Error?

    func sync(_ snapshot: BackendSyncSnapshot) async throws -> BackendSyncResult {
        if let error { throw error }
        snapshots.append(snapshot)
        return BackendSyncResult(uploadedCounts: snapshot.counts)
    }
}
```

Change `CapturingRestorer` to:

```swift
private final class CapturingRestorer: ReflectionBackupRestoring {
    var restoredUserIDs: [String] = []
    var error: Error?
    private let snapshot: BackendSyncSnapshot

    init(snapshot: BackendSyncSnapshot) {
        self.snapshot = snapshot
    }

    func restorePrivateBackup(userID: String) async throws -> BackendSyncSnapshot {
        if let error { throw error }
        restoredUserIDs.append(userID)
        return snapshot
    }
}
```

Then add this test after the successful upload timing test:

```swift
func testUploadPrivateBackupTracksFailureWithoutClearingLocalData() async {
    let journalStore = ReflectionJournalStore(userDefaults: makeDefaults())
    let entry = makeEntry()
    journalStore.add(entry)
    let syncer = CapturingSyncer()
    syncer.error = TestBackendError.failed
    let authenticator = FakeFirebaseAuthenticator(
        currentSession: FirebaseAuthSession(
            uid: "firebase-user-1",
            email: "tuan@example.com",
            displayName: "Tuan",
            localUserID: "local-user-1"
        )
    )
    let store = BackendSessionStore(authenticator: authenticator, syncer: syncer)

    await store.uploadPrivateBackup(
        profileStore: UserProfileStore(userDefaults: makeDefaults()),
        journalStore: journalStore,
        questStore: QuestStore(userDefaults: makeDefaults()),
        tipsPracticeStore: TipsPracticeStore(userDefaults: makeDefaults()),
        rewardsStore: RewardsStore(userDefaults: makeDefaults(), seedIfEmpty: false),
        circleStore: CircleStore(userDefaults: makeDefaults(), seedStarterSpaces: false),
        aiSessionStore: AIReflectionSessionStore(userDefaults: makeDefaults())
    )

    XCTAssertEqual(journalStore.entries.map(\.id), [entry.id])
    XCTAssertNotNil(store.lastSyncAttemptedAt)
    XCTAssertNotNil(store.lastUploadStartedAt)
    XCTAssertNil(store.lastUploadSucceededAt)
    XCTAssertEqual(store.lastSyncErrorMessage, TestBackendError.failed.localizedDescription)
    XCTAssertEqual(store.lastSyncErrorOperation, .uploading)
    XCTAssertEqual(store.backendUserID, "firebase-user-1")
}
```

- [ ] **Step 3: Write failing tests for restore timing and failure behavior**

Add these tests after `testRestorePrivateBackupMergesRemoteSnapshotIntoLocalStores()`:

```swift
func testRestorePrivateBackupTracksAttemptAndSuccessTimes() async {
    let restorer = CapturingRestorer(snapshot: makeRemoteSnapshot())
    let authenticator = FakeFirebaseAuthenticator(
        currentSession: FirebaseAuthSession(
            uid: "firebase-user-1",
            email: "tuan@example.com",
            displayName: "Tuan",
            localUserID: "local-user-1"
        )
    )
    let store = BackendSessionStore(
        authenticator: authenticator,
        syncer: NoOpReflectionSyncer(),
        restorer: restorer
    )

    await store.restorePrivateBackup(
        profileStore: UserProfileStore(userDefaults: makeDefaults()),
        journalStore: ReflectionJournalStore(userDefaults: makeDefaults()),
        questStore: QuestStore(userDefaults: makeDefaults()),
        tipsPracticeStore: TipsPracticeStore(userDefaults: makeDefaults()),
        rewardsStore: RewardsStore(userDefaults: makeDefaults(), seedIfEmpty: false),
        aiSessionStore: AIReflectionSessionStore(userDefaults: makeDefaults())
    )

    XCTAssertNotNil(store.lastSyncAttemptedAt)
    XCTAssertNotNil(store.lastRestoreStartedAt)
    XCTAssertNotNil(store.lastRestoreSucceededAt)
    XCTAssertNil(store.lastUploadStartedAt)
    XCTAssertNil(store.lastUploadSucceededAt)
    XCTAssertNil(store.lastSyncErrorMessage)
}

func testRestorePrivateBackupTracksFailureWithoutClearingLocalData() async {
    let journalStore = ReflectionJournalStore(userDefaults: makeDefaults())
    let entry = makeEntry()
    journalStore.add(entry)
    let restorer = CapturingRestorer(snapshot: makeRemoteSnapshot())
    restorer.error = TestBackendError.failed
    let authenticator = FakeFirebaseAuthenticator(
        currentSession: FirebaseAuthSession(
            uid: "firebase-user-1",
            email: "tuan@example.com",
            displayName: "Tuan",
            localUserID: "local-user-1"
        )
    )
    let store = BackendSessionStore(
        authenticator: authenticator,
        syncer: NoOpReflectionSyncer(),
        restorer: restorer
    )

    await store.restorePrivateBackup(
        profileStore: UserProfileStore(userDefaults: makeDefaults()),
        journalStore: journalStore,
        questStore: QuestStore(userDefaults: makeDefaults()),
        tipsPracticeStore: TipsPracticeStore(userDefaults: makeDefaults()),
        rewardsStore: RewardsStore(userDefaults: makeDefaults(), seedIfEmpty: false),
        aiSessionStore: AIReflectionSessionStore(userDefaults: makeDefaults())
    )

    XCTAssertEqual(journalStore.entries.map(\.id), [entry.id])
    XCTAssertNotNil(store.lastSyncAttemptedAt)
    XCTAssertNotNil(store.lastRestoreStartedAt)
    XCTAssertNil(store.lastRestoreSucceededAt)
    XCTAssertEqual(store.lastSyncErrorMessage, TestBackendError.failed.localizedDescription)
    XCTAssertEqual(store.lastSyncErrorOperation, .restoring)
}
```

- [ ] **Step 4: Run tests and verify they fail**

Run:

```bash
xcodebuild test -quiet -project Circleu.xcodeproj -scheme Circleu -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:CircleuTests/BackendSessionStoreTests
```

Expected: FAIL because `BackendSessionStore` does not yet expose `lastSyncAttemptedAt`, `lastUploadStartedAt`, `lastUploadSucceededAt`, `lastRestoreStartedAt`, or `lastRestoreSucceededAt`.

- [ ] **Step 5: Add sync timing metadata**

In `Circleu/Stores/BackendSessionStore.swift`, add published metadata near the existing sync state:

```swift
@Published private(set) var lastSyncAttemptedAt: Date?
@Published private(set) var lastUploadStartedAt: Date?
@Published private(set) var lastUploadSucceededAt: Date?
@Published private(set) var lastRestoreStartedAt: Date?
@Published private(set) var lastRestoreSucceededAt: Date?
```

In `uploadPrivateBackup(...)`, after the `guard !snapshot.isEmpty else { return }` line and before `syncOperation = .uploading`, add:

```swift
let startedAt = Date()
lastSyncAttemptedAt = startedAt
lastUploadStartedAt = startedAt
```

In the upload success branch, after `lastSyncResult = result`, add:

```swift
lastUploadSucceededAt = result.syncedAt
```

In `restorePrivateBackup(...)`, after the `guard !isSyncing else { return }` line and before `syncOperation = .restoring`, add:

```swift
let startedAt = Date()
lastSyncAttemptedAt = startedAt
lastRestoreStartedAt = startedAt
```

In the restore success branch, after `lastSyncResult = result`, add:

```swift
lastRestoreSucceededAt = result.syncedAt
```

- [ ] **Step 6: Run backend session tests**

Run:

```bash
xcodebuild test -quiet -project Circleu.xcodeproj -scheme Circleu -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:CircleuTests/BackendSessionStoreTests
```

Expected: PASS.

- [ ] **Step 7: Commit Task 1**

Run:

```bash
git add Circleu/Stores/BackendSessionStore.swift CircleuTests/BackendSessionStoreTests.swift
git commit -m "feat: track Firebase sync timing"
```

## Task 2: QA Tools Sync Status and Manual Actions

**Files:**
- Modify: `Circleu/Features/Profile/ProfileQAToolsSheet.swift`
- Modify: `Circleu/Features/Profile/ProfileView.swift`
- Modify: `docs/product/release-readiness.md`

- [ ] **Step 1: Update QA backend diagnostics display**

In `Circleu/Features/Profile/ProfileQAToolsSheet.swift`, inside `backendDiagnosticsCard`, replace the existing sync rows:

```swift
ProfileDataRow(title: "Last upload", value: formattedSyncTime(backendSessionStore.lastUploadResult))
ProfileDataRow(title: "Uploaded payload", value: uploadedDiagnosticsSummary)
ProfileDataRow(title: "Last restore", value: formattedSyncTime(backendSessionStore.lastRestoreResult))
ProfileDataRow(title: "Restored payload", value: restoredDiagnosticsSummary)
```

with:

```swift
ProfileDataRow(title: "Last attempt", value: formattedDate(backendSessionStore.lastSyncAttemptedAt))
ProfileDataRow(title: "Upload started", value: formattedDate(backendSessionStore.lastUploadStartedAt))
ProfileDataRow(title: "Upload succeeded", value: formattedDate(backendSessionStore.lastUploadSucceededAt))
ProfileDataRow(title: "Uploaded payload", value: uploadedDiagnosticsSummary)
ProfileDataRow(title: "Restore started", value: formattedDate(backendSessionStore.lastRestoreStartedAt))
ProfileDataRow(title: "Restore succeeded", value: formattedDate(backendSessionStore.lastRestoreSucceededAt))
ProfileDataRow(title: "Restored payload", value: restoredDiagnosticsSummary)
```

Add this helper below `formattedSyncTime(_:)`:

```swift
private func formattedDate(_ date: Date?) -> String {
    guard let date else { return "Never" }
    return date.formatted(date: .abbreviated, time: .shortened)
}
```

- [ ] **Step 2: Rename manual action labels to force actions**

In `backendCard`, change:

```swift
Label("Back Up Now", systemImage: "arrow.up.doc")
```

to:

```swift
Label("Force Upload", systemImage: "arrow.up.doc")
```

Change:

```swift
Label("Restore Now", systemImage: "arrow.down.doc")
```

to:

```swift
Label("Force Restore", systemImage: "arrow.down.doc")
```

- [ ] **Step 3: Make manual action status messages match QA language**

In `backUpNow()`, replace status strings:

```swift
viewModel.statusMessage = "Backing up private Firebase data..."
```

with:

```swift
viewModel.statusMessage = "Force uploading private Firebase data..."
```

Replace:

```swift
? "Firebase backup finished."
: "Firebase backup finished with an error."
```

with:

```swift
? "Firebase force upload finished."
: "Firebase force upload finished with an error."
```

In `restoreNow()`, replace:

```swift
viewModel.statusMessage = "Restoring private Firebase data..."
```

with:

```swift
viewModel.statusMessage = "Force restoring private Firebase data..."
```

Replace:

```swift
? "Firebase restore finished."
: "Firebase restore finished with an error."
```

with:

```swift
? "Firebase force restore finished."
: "Firebase force restore finished with an error."
```

- [ ] **Step 4: Improve Profile sync subtitle with last successful upload**

In `Circleu/Features/Profile/ProfileView.swift`, inside `syncStatusSubtitle`, prefer `lastUploadSucceededAt` when present. Use this shape:

```swift
if let uploadSucceededAt = backendSessionStore.lastUploadSucceededAt {
    return "Last upload \(uploadSucceededAt.formatted(date: .omitted, time: .shortened))."
}

guard let syncedAt = backendSessionStore.lastSyncResult?.syncedAt else {
    return backendSessionStore.backendUserID == nil
        ? "Sign in to back up private data."
        : "Ready to back up private data."
}

return "Last updated \(syncedAt.formatted(date: .omitted, time: .shortened))."
```

- [ ] **Step 5: Update release readiness QA checklist**

In `docs/product/release-readiness.md`, under `Phone QA Flow`, add these lines after the QA tools step:

```markdown
4. Confirm Firebase status shows auth, sync, last attempt, upload, and restore fields.
5. Tap **Force Upload** and confirm the upload success time changes.
6. Tap **Force Restore** and confirm local data remains present after merge-only restore.
```

Renumber the remaining checklist items so the list stays sequential.

- [ ] **Step 6: Build the app**

Run:

```bash
xcodebuild build -quiet -project Circleu.xcodeproj -scheme Circleu -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 7: Commit Task 2**

Run:

```bash
git add Circleu/Features/Profile/ProfileQAToolsSheet.swift Circleu/Features/Profile/ProfileView.swift docs/product/release-readiness.md
git commit -m "feat: improve Firebase QA controls"
```

## Task 3: Reflection Transcript Classification

**Files:**
- Modify: `Circleu/Engines/ReflectionEngine.swift`
- Modify: `Circleu/Engines/TranscriptQuality.swift`
- Test: `CircleuTests/EngineBehaviorTests.swift`

- [ ] **Step 1: Write failing tests for boundary and conflict**

Add this test after `testLocalReflectionEngineCoachesCoherentRoughLanguageWithoutGenericPraise()`:

```swift
func testLocalReflectionEngineCoachesBoundaryConflictWithoutGenericPraise() async throws {
    let result = try await analyze(
        "I felt angry after my teammate interrupted me twice. I want to tell them I need space to finish my idea before they respond.",
        durationSeconds: 80
    )

    XCTAssertEqual(result.title, "Name the boundary clearly")
    XCTAssertEqual(result.emotion, "Protective")
    XCTAssertTrue(result.summary.lowercased().contains("interrupted"))
    XCTAssertTrue(result.insight.lowercased().contains("boundary"))
    XCTAssertFalse(result.summary.contains("You gave shape to what was on your mind"))
    XCTAssertEqual(result.suggestedQuest, "Write one sentence that names what happened and what you need next.")
    XCTAssertConfidenceScoreIsValid(result)
}
```

- [ ] **Step 2: Write failing tests for stronger stress classification**

Add this test after the boundary test:

```swift
func testLocalReflectionEngineAnchorsStressFeedbackToOverwhelm() async throws {
    let result = try await analyze(
        "I felt overwhelmed because the demo, Firebase setup, and team messages all arrived at once, and I did not know what to finish first.",
        durationSeconds: 75
    )

    XCTAssertEqual(result.title, "Make the load smaller")
    XCTAssertEqual(result.emotion, "Overloaded")
    XCTAssertTrue(result.summary.lowercased().contains("overwhelmed"))
    XCTAssertTrue(result.insight.lowercased().contains("too many"))
    XCTAssertEqual(result.suggestedQuest, "Choose the smallest useful task and leave the rest for the next pass.")
    XCTAssertConfidenceScoreIsValid(result)
}
```

- [ ] **Step 3: Run engine tests and verify new tests fail**

Run:

```bash
xcodebuild test -quiet -project Circleu.xcodeproj -scheme Circleu -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:CircleuTests/EngineBehaviorTests
```

Expected: FAIL because the local engine still routes boundary and overwhelm examples through older generic profiles.

- [ ] **Step 4: Add transcript classification enum and classifier**

In `Circleu/Engines/ReflectionEngine.swift`, add this enum near `LocalReflectionEngine`:

```swift
private enum LocalReflectionKind {
    case roughLowSignal
    case roughLanguage
    case boundaryConflict
    case overwhelm
    case anxiety
    case pride
    case tender
    case neutral
}
```

Inside `LocalReflectionEngine`, add this helper before `reflectionProfile(for:)`:

```swift
private func reflectionKind(for cleanTranscript: String) -> LocalReflectionKind {
    if TranscriptQuality.isRoughLowSignal(cleanTranscript) {
        return .roughLowSignal
    }

    if TranscriptQuality.containsRoughLanguage(cleanTranscript) {
        return .roughLanguage
    }

    let text = cleanTranscript.lowercased()

    if containsAny(["boundary", "interrupted", "crossed a line", "need space", "angry", "frustrated", "conflict"], in: text) {
        return .boundaryConflict
    }

    if containsAny(["overwhelmed", "too much", "too many", "burned out", "burnt out", "exhausted"], in: text) {
        return .overwhelm
    }

    if containsAny(["nervous", "anxious", "scared", "afraid", "worried", "panic"], in: text) {
        return .anxiety
    }

    if containsAny(["proud", "grateful", "happy", "relieved", "excited", "win"], in: text) {
        return .pride
    }

    if containsAny(["sad", "lonely", "hurt", "miss", "tired", "cry"], in: text) {
        return .tender
    }

    return .neutral
}
```

- [ ] **Step 5: Route analysis through classification**

In `LocalReflectionEngine.analyze(...)`, replace the current rough checks and profile selection:

```swift
if TranscriptQuality.isRoughLowSignal(cleanTranscript) {
    return roughLowSignalReflection(durationSeconds: durationSeconds)
}

if TranscriptQuality.containsRoughLanguage(cleanTranscript) {
    return roughLanguageReflection()
}

let lowercased = cleanTranscript.lowercased()
let profile = reflectionProfile(for: lowercased)
let summary = summarize(cleanTranscript)
```

with:

```swift
let kind = reflectionKind(for: cleanTranscript)

if kind == .roughLowSignal {
    return roughLowSignalReflection(durationSeconds: durationSeconds)
}

if kind == .roughLanguage {
    return roughLanguageReflection()
}

let profile = reflectionProfile(for: kind)
let lowercased = cleanTranscript.lowercased()
let summary = summarize(cleanTranscript)
```

- [ ] **Step 6: Replace profile lookup with classification-based profile**

Replace `private func reflectionProfile(for text: String) -> LocalReflectionProfile` with:

```swift
private func reflectionProfile(for kind: LocalReflectionKind) -> LocalReflectionProfile {
    switch kind {
    case .roughLowSignal:
        return LocalReflectionProfile(
            title: "Try that check-in again",
            emotion: "Unclear",
            insight: "Circleu needs one specific situation to give useful feedback.",
            expressionMoment: "You may have been testing the recording.",
            quote: "A clearer moment gives your reflection something kind to hold.",
            score: 0.32
        )
    case .roughLanguage:
        return LocalReflectionProfile(
            title: "Pause before you respond",
            emotion: "Heated",
            insight: "Strong words may point to a real boundary, but the next step will land better if it is steady.",
            expressionMoment: "You noticed the words might be too sharp.",
            quote: "A steady boundary can be stronger than a sharper sentence.",
            score: 0.58
        )
    case .boundaryConflict:
        return LocalReflectionProfile(
            title: "Name the boundary clearly",
            emotion: "Protective",
            insight: "A boundary is easier to hear when it names the moment, the impact, and the need without attacking the person.",
            expressionMoment: "You noticed a line that matters.",
            quote: "Clear does not have to become harsh.",
            score: 0.76
        )
    case .overwhelm:
        return LocalReflectionProfile(
            title: "Make the load smaller",
            emotion: "Overloaded",
            insight: "Too many demands arrived at once, so the useful move is to shrink the next step instead of solving everything.",
            expressionMoment: "Everything arrived at once.",
            quote: "Small enough is often the way back to steady.",
            score: 0.75
        )
    case .anxiety:
        return LocalReflectionProfile(
            title: "You met uncertainty with courage",
            emotion: "Brave",
            insight: "You noticed fear without letting it make every decision for you.",
            expressionMoment: "You stayed with the moment.",
            quote: "Courage often starts as one honest sentence.",
            score: 0.72
        )
    case .pride:
        return LocalReflectionProfile(
            title: "You noticed a meaningful win",
            emotion: "Proud",
            insight: "Naming what went well helps you repeat the conditions that supported it.",
            expressionMoment: "You recognized your effort.",
            quote: "Progress becomes easier to trust when you name it.",
            score: 0.78
        )
    case .tender:
        return LocalReflectionProfile(
            title: "You gave a tender feeling some space",
            emotion: "Tender",
            insight: "A soft feeling is asking for care, not a quick fix.",
            expressionMoment: "You let the feeling be real.",
            quote: "Soft honesty is still strength.",
            score: 0.7
        )
    case .neutral:
        return LocalReflectionProfile(
            title: "You checked in with yourself",
            emotion: "Thoughtful",
            insight: "You gave shape to what was on your mind. That makes the next small step easier to choose.",
            expressionMoment: "You paused long enough to notice.",
            quote: "Small honest words can become steady progress.",
            score: 0.62
        )
    }
}
```

- [ ] **Step 7: Update suggested quest for classification**

Replace `suggestedQuest(for:durationSeconds:)` with:

```swift
private func suggestedQuest(for text: String, durationSeconds: Int, kind: LocalReflectionKind) -> String {
    if durationSeconds < 30 {
        return "Try a one-minute check-in next time and name one feeling clearly."
    }

    switch kind {
    case .boundaryConflict:
        return "Write one sentence that names what happened and what you need next."
    case .overwhelm:
        return "Choose the smallest useful task and leave the rest for the next pass."
    case .anxiety:
        return "Write one sentence you can say when the worry gets loud."
    case .pride:
        return "Save one sentence about what helped this moment go well."
    case .tender:
        return "Send yourself one kind sentence you would offer a friend."
    case .roughLowSignal, .roughLanguage, .neutral:
        if containsAny(["stressed", "overwhelmed", "busy", "deadline"], in: text) {
            return "Choose one task you can make smaller before the day ends."
        }
        return "Write down one next step that would make tomorrow feel lighter."
    }
}
```

Update the call site in `analyze(...)` from:

```swift
suggestedQuest: suggestedQuest(for: lowercased, durationSeconds: durationSeconds)
```

to:

```swift
suggestedQuest: suggestedQuest(for: lowercased, durationSeconds: durationSeconds, kind: kind)
```

- [ ] **Step 8: Run engine tests**

Run:

```bash
xcodebuild test -quiet -project Circleu.xcodeproj -scheme Circleu -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:CircleuTests/EngineBehaviorTests
```

Expected: PASS.

- [ ] **Step 9: Commit Task 3**

Run:

```bash
git add Circleu/Engines/ReflectionEngine.swift Circleu/Engines/TranscriptQuality.swift CircleuTests/EngineBehaviorTests.swift
git commit -m "feat: classify reflection transcripts"
```

## Task 4: Final Verification and Release Docs

**Files:**
- Verify: `Circleu/Stores/BackendSessionStore.swift`
- Verify: `Circleu/Features/Profile/ProfileQAToolsSheet.swift`
- Verify: `Circleu/Features/Profile/ProfileView.swift`
- Verify: `Circleu/Engines/ReflectionEngine.swift`
- Verify: `CircleuTests/BackendSessionStoreTests.swift`
- Verify: `CircleuTests/FirebaseFirestoreSyncServiceTests.swift`
- Verify: `CircleuTests/EngineBehaviorTests.swift`
- Modify if needed: `docs/product/release-readiness.md`

- [ ] **Step 1: Run focused backend and engine tests**

Run:

```bash
xcodebuild test -quiet -project Circleu.xcodeproj -scheme Circleu -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:CircleuTests/BackendSessionStoreTests -only-testing:CircleuTests/FirebaseFirestoreSyncServiceTests -only-testing:CircleuTests/EngineBehaviorTests
```

Expected: PASS.

- [ ] **Step 2: Run simulator build**

Run:

```bash
xcodebuild build -quiet -project Circleu.xcodeproj -scheme Circleu -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Confirm no shared circle backend writes were introduced**

Run:

```bash
rg -n "circles/|circlePosts|circlePostReplies|scope == \\.circles|scope == \\.circlePosts" Circleu/Services/FirebaseFirestoreSyncService.swift CircleuTests/FirebaseFirestoreSyncServiceTests.swift firestore.rules
```

Expected: output still shows tests/rules that deny or exclude shared circles; no new production Firestore write path for top-level `circles/{circleID}`.

- [ ] **Step 4: Inspect changed files**

Run:

```bash
git status --short
git diff --stat
```

Expected: only files from this plan are changed.

- [ ] **Step 5: Commit any release-doc-only adjustments**

If Task 2 already committed `docs/product/release-readiness.md`, skip this step. If final verification required a wording update, run:

```bash
git add docs/product/release-readiness.md
git commit -m "docs: update backend QA checklist"
```

- [ ] **Step 6: Push all commits**

Run:

```bash
git push origin main
```

Expected: push succeeds.
