import XCTest
@testable import Circleu

@MainActor
final class BackendSessionStoreTests: XCTestCase {
    func testSignUpCreatesLocalAccountAndFirebaseSession() async throws {
        let authStore = AuthStore(userDefaults: makeDefaults())
        let profileStore = UserProfileStore(userDefaults: makeDefaults())
        let authenticator = FakeFirebaseAuthenticator()
        let store = BackendSessionStore(
            authenticator: authenticator,
            syncer: NoOpReflectionSyncer(),
            identityProvider: StubIdentityProvider(localUserID: "local-user-1", displayName: "Tuan")
        )

        let account = try await store.signUp(
            name: " Tuan ",
            email: " TUAN@example.com ",
            password: "strong-password",
            authStore: authStore,
            profileStore: profileStore
        )

        XCTAssertEqual(account.email, "tuan@example.com")
        XCTAssertEqual(profileStore.displayName, "Tuan")
        XCTAssertEqual(store.backendUserID, "firebase-user-1")
        XCTAssertEqual(authenticator.signedUpProfile?.localUserID, "local-user-1")
        XCTAssertFalse(authenticator.signedUpProfile?.email.contains("password") ?? true)
    }

    func testSignUpThrowsWhenFirebaseFailsSoOnboardingCanShowError() async throws {
        let authStore = AuthStore(userDefaults: makeDefaults())
        let profileStore = UserProfileStore(userDefaults: makeDefaults())
        let authenticator = FakeFirebaseAuthenticator()
        authenticator.signUpError = TestBackendError.failed
        authenticator.signInError = TestBackendError.failed
        let store = BackendSessionStore(
            authenticator: authenticator,
            syncer: NoOpReflectionSyncer(),
            identityProvider: StubIdentityProvider(localUserID: "local-user-1", displayName: "Tuan")
        )

        do {
            _ = try await store.signUp(
                name: "Tuan",
                email: "tuan@example.com",
                password: "strong-password",
                authStore: authStore,
                profileStore: profileStore
            )
            XCTFail("Expected Firebase sign-up failure to throw.")
        } catch {
            XCTAssertEqual(error.localizedDescription, TestBackendError.failed.localizedDescription)
        }

        XCTAssertTrue(authStore.isSignedIn)
        XCTAssertNil(store.backendUserID)
        XCTAssertEqual(store.lastAuthErrorMessage, TestBackendError.failed.localizedDescription)
    }

    func testSignUpRetriesFirebaseWhenLocalAccountAlreadyExists() async throws {
        let defaults = makeDefaults()
        let authStore = AuthStore(userDefaults: defaults)
        let profileStore = UserProfileStore(userDefaults: makeDefaults())
        _ = try authStore.signUp(name: "Tuan", email: "tuan@example.com", password: "strong-password")
        let authenticator = FakeFirebaseAuthenticator()
        let store = BackendSessionStore(
            authenticator: authenticator,
            syncer: NoOpReflectionSyncer(),
            identityProvider: StubIdentityProvider(localUserID: "local-user-1", displayName: "Tuan")
        )

        _ = try await store.signUp(
            name: "Tuan",
            email: "tuan@example.com",
            password: "strong-password",
            authStore: authStore,
            profileStore: profileStore
        )

        XCTAssertEqual(store.backendUserID, "firebase-user-1")
        XCTAssertEqual(authenticator.signedUpProfile?.email, "tuan@example.com")
    }

    func testSignUpFallsBackToFirebaseSignInWhenRemoteAccountAlreadyExists() async throws {
        let authStore = AuthStore(userDefaults: makeDefaults())
        let profileStore = UserProfileStore(userDefaults: makeDefaults())
        let authenticator = FakeFirebaseAuthenticator()
        authenticator.signUpError = TestBackendError.remoteEmailExists
        let store = BackendSessionStore(
            authenticator: authenticator,
            syncer: NoOpReflectionSyncer(),
            identityProvider: StubIdentityProvider(localUserID: "local-user-1", displayName: "Tuan")
        )

        _ = try await store.signUp(
            name: "Tuan",
            email: "tuan@example.com",
            password: "strong-password",
            authStore: authStore,
            profileStore: profileStore
        )

        XCTAssertEqual(store.backendUserID, "firebase-user-1")
        XCTAssertEqual(authenticator.signedInEmail, "tuan@example.com")
    }

    func testSignInRestoresLocalAccountWhenOnlyFirebaseAccountExists() async throws {
        let authStore = AuthStore(userDefaults: makeDefaults())
        let profileStore = UserProfileStore(userDefaults: makeDefaults())
        let authenticator = FakeFirebaseAuthenticator()
        let store = BackendSessionStore(
            authenticator: authenticator,
            syncer: NoOpReflectionSyncer(),
            identityProvider: StubIdentityProvider(localUserID: "local-user-1", displayName: "Tuan")
        )

        let account = try await store.signIn(
            email: "tuan@example.com",
            password: "strong-password",
            authStore: authStore,
            profileStore: profileStore
        )

        XCTAssertEqual(account.email, "tuan@example.com")
        XCTAssertEqual(account.displayName, "Tuan")
        XCTAssertEqual(authStore.accounts.map(\.email), ["tuan@example.com"])
        XCTAssertEqual(authStore.currentEmail, "tuan@example.com")
        XCTAssertEqual(profileStore.displayName, "Tuan")
        XCTAssertEqual(store.backendUserID, "firebase-user-1")
        XCTAssertEqual(authenticator.signedInEmail, "tuan@example.com")
    }

    func testSignInDoesNotCreateLocalAccountWhenRemoteSignInFails() async {
        let authStore = AuthStore(userDefaults: makeDefaults())
        let profileStore = UserProfileStore(userDefaults: makeDefaults())
        let authenticator = FakeFirebaseAuthenticator()
        authenticator.signInError = TestBackendError.failed
        let store = BackendSessionStore(authenticator: authenticator, syncer: NoOpReflectionSyncer())

        do {
            _ = try await store.signIn(
                email: "tuan@example.com",
                password: "strong-password",
                authStore: authStore,
                profileStore: profileStore
            )
            XCTFail("Expected Firebase sign-in failure to throw.")
        } catch {
            XCTAssertEqual(error.localizedDescription, TestBackendError.failed.localizedDescription)
        }

        XCTAssertTrue(authStore.accounts.isEmpty)
        XCTAssertNil(authStore.currentEmail)
        XCTAssertNil(store.backendUserID)
    }

    func testUploadPrivateBackupUsesFirebaseUID() async throws {
        let journalStore = ReflectionJournalStore(userDefaults: makeDefaults())
        let questStore = QuestStore(userDefaults: makeDefaults())
        let tipsPracticeStore = TipsPracticeStore(userDefaults: makeDefaults())
        let rewardsStore = RewardsStore(userDefaults: makeDefaults(), seedIfEmpty: false)
        let circleStore = CircleStore(userDefaults: makeDefaults(), seedStarterSpaces: false)
        let aiSessionStore = AIReflectionSessionStore(userDefaults: makeDefaults())
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
            questStore: questStore,
            tipsPracticeStore: tipsPracticeStore,
            rewardsStore: rewardsStore,
            circleStore: circleStore,
            aiSessionStore: aiSessionStore
        )

        XCTAssertEqual(syncer.snapshots.count, 1)
        XCTAssertEqual(syncer.snapshots.first?.userID, "firebase-user-1")
        XCTAssertEqual(syncer.snapshots.first?.journalEntries.count, 1)
        XCTAssertEqual(store.lastSyncResult?.uploadedCounts.journalEntryCount, 1)
    }

    func testUploadPrivateBackupDoesNothingWithoutFirebaseSession() async {
        let syncer = CapturingSyncer()
        let store = BackendSessionStore(authenticator: FakeFirebaseAuthenticator(), syncer: syncer)

        await store.uploadPrivateBackup(
            profileStore: UserProfileStore(userDefaults: makeDefaults()),
            journalStore: ReflectionJournalStore(userDefaults: makeDefaults()),
            questStore: QuestStore(userDefaults: makeDefaults()),
            tipsPracticeStore: TipsPracticeStore(userDefaults: makeDefaults()),
            rewardsStore: RewardsStore(userDefaults: makeDefaults(), seedIfEmpty: false),
            circleStore: CircleStore(userDefaults: makeDefaults(), seedStarterSpaces: false),
            aiSessionStore: AIReflectionSessionStore(userDefaults: makeDefaults())
        )

        XCTAssertEqual(syncer.snapshots.count, 0)
    }

    func testRestorePrivateBackupMergesRemoteSnapshotIntoLocalStores() async {
        let profileStore = UserProfileStore(userDefaults: makeDefaults())
        let journalStore = ReflectionJournalStore(userDefaults: makeDefaults())
        let questStore = QuestStore(userDefaults: makeDefaults())
        let tipsPracticeStore = TipsPracticeStore(userDefaults: makeDefaults())
        let rewardsStore = RewardsStore(userDefaults: makeDefaults(), seedIfEmpty: false)
        let aiSessionStore = AIReflectionSessionStore(userDefaults: makeDefaults())
        let remoteSnapshot = makeRemoteSnapshot()
        let restorer = CapturingRestorer(snapshot: remoteSnapshot)
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
            profileStore: profileStore,
            journalStore: journalStore,
            questStore: questStore,
            tipsPracticeStore: tipsPracticeStore,
            rewardsStore: rewardsStore,
            aiSessionStore: aiSessionStore
        )

        XCTAssertEqual(restorer.restoredUserIDs, ["firebase-user-1"])
        XCTAssertEqual(profileStore.displayName, "Restored Tuan")
        XCTAssertEqual(journalStore.entries.map(\.id), remoteSnapshot.journalEntries.map(\.id))
        XCTAssertEqual(questStore.quests.map(\.id), remoteSnapshot.quests.map(\.id))
        XCTAssertEqual(tipsPracticeStore.recentSessions.map(\.id), remoteSnapshot.tipsPracticeSessions.map(\.id))
        XCTAssertEqual(rewardsStore.points, 42)
        XCTAssertEqual(rewardsStore.pointsLog.map(\.id), remoteSnapshot.pointEntries.map(\.id))
        XCTAssertEqual(rewardsStore.activity.map(\.id), remoteSnapshot.activityEvents.map(\.id))
        XCTAssertEqual(aiSessionStore.sessions.map(\.id), remoteSnapshot.aiSessions.map(\.id))
        XCTAssertEqual(store.lastSyncResult?.downloadedCounts.journalEntryCount, 1)
        XCTAssertEqual(store.lastSyncResult?.uploadedCounts, .zero)
    }

    private func makeEntry() -> JournalReflectionEntry {
        JournalReflectionEntry(
            durationSeconds: 60,
            transcript: "I asked one clear question.",
            engineName: "Local Reflection Engine",
            result: AIReflectionResult(
                title: "Clear question",
                emotion: "Calm",
                summary: "You asked directly.",
                insight: "Small clarity helped.",
                expressionMoment: "You named what you needed.",
                quote: "Clarity can be kind.",
                confidenceScore: 0.8,
                suggestedQuest: "Ask one follow-up tomorrow."
            )
        )
    }

    private func makeRemoteSnapshot() -> BackendSyncSnapshot {
        let entry = makeEntry()
        let quest = Quest(
            title: "Restored quest",
            detail: "Ask a restored follow-up.",
            sourceEntryID: entry.id,
            createdAt: entry.createdAt
        )
        let tipsSession = TipsPracticeSession(
            originalMessage: "I need to pause before answering.",
            scene: .friendship,
            tone: .soft,
            situation: "A hard message",
            turns: [],
            coachOutput: TipsCoachOutput(
                suggestedPhrasing: "Can I take a moment and reply later?",
                whyItWorks: "It keeps the relationship clear.",
                simulatedReply: "Yes, that is okay.",
                roomReading: "Gentle and direct.",
                replyOptions: []
            )
        )
        let pointEntry = PointEntry(label: "Restored points", points: 7, icon: "star")
        let activity = ActivityEvent(type: .reflect, title: "Restored activity", keyword: "restore", refID: entry.id)
        let aiAttempt = AIReflectionAttempt(
            engineName: "Remote engine",
            status: .succeeded,
            result: entry.result
        )
        let aiSession = AIReflectionSession(
            entryID: entry.id,
            engineName: "Remote engine",
            source: .typedFallback,
            transcript: entry.transcript,
            durationSeconds: entry.durationSeconds,
            attempts: [aiAttempt],
            selectedAttemptID: aiAttempt.id
        )

        return BackendSyncSnapshot(
            userID: "firebase-user-1",
            profile: BackendProfileSnapshot(displayName: "Restored Tuan", promptIndex: 3, updatedAt: Date()),
            journalEntries: [entry],
            quests: [quest],
            tipsPracticeSessions: [tipsSession],
            rewardState: BackendRewardSnapshot(
                points: 42,
                level: 1,
                intoLevel: 42,
                nextLevel: 2,
                questAwards: ["daily_reflect": "2026-6-10"],
                updatedAt: Date()
            ),
            pointEntries: [pointEntry],
            activityEvents: [activity],
            circles: [],
            circlePosts: [],
            aiSessions: [aiSession]
        )
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "circleu.backend.session.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}

private final class FakeFirebaseAuthenticator: FirebaseAuthenticating {
    var currentSession: FirebaseAuthSession?
    var signedUpProfile: FirebaseAuthProfile?
    var signedInEmail: String?
    var signUpError: Error?
    var signInError: Error?
    var didSignOut = false

    init(currentSession: FirebaseAuthSession? = nil) {
        self.currentSession = currentSession
    }

    func signUp(profile: FirebaseAuthProfile, password: String) async throws -> FirebaseAuthSession {
        if let signUpError { throw signUpError }
        signedUpProfile = profile
        currentSession = FirebaseAuthSession(
            uid: "firebase-user-1",
            email: profile.email,
            displayName: profile.displayName,
            localUserID: profile.localUserID
        )
        return currentSession!
    }

    func signIn(email: String, password: String) async throws -> FirebaseAuthSession {
        if let signInError { throw signInError }
        signedInEmail = email
        currentSession = FirebaseAuthSession(
            uid: "firebase-user-1",
            email: email,
            displayName: "Tuan",
            localUserID: nil
        )
        return currentSession!
    }

    func signOut() throws {
        didSignOut = true
        currentSession = nil
    }
}

private final class CapturingSyncer: ReflectionSyncing {
    var snapshots: [BackendSyncSnapshot] = []

    func sync(_ snapshot: BackendSyncSnapshot) async throws -> BackendSyncResult {
        snapshots.append(snapshot)
        return BackendSyncResult(uploadedCounts: snapshot.counts)
    }
}

private final class CapturingRestorer: ReflectionBackupRestoring {
    var restoredUserIDs: [String] = []
    private let snapshot: BackendSyncSnapshot

    init(snapshot: BackendSyncSnapshot) {
        self.snapshot = snapshot
    }

    func restorePrivateBackup(userID: String) async throws -> BackendSyncSnapshot {
        restoredUserIDs.append(userID)
        return snapshot
    }
}

private struct StubIdentityProvider: UserIdentityProviding {
    let localUserID: String
    let displayName: String
}

private enum TestBackendError: LocalizedError {
    case failed
    case remoteEmailExists

    var errorDescription: String? {
        switch self {
        case .failed:
            "Firebase unavailable"
        case .remoteEmailExists:
            "The email address is already in use by another account."
        }
    }
}
