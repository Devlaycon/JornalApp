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

    func testUploadPrivateBackupUsesFirebaseUID() async throws {
        let journalStore = ReflectionJournalStore(userDefaults: makeDefaults())
        let questStore = QuestStore(userDefaults: makeDefaults())
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
            journalStore: journalStore,
            questStore: questStore,
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
            journalStore: ReflectionJournalStore(userDefaults: makeDefaults()),
            questStore: QuestStore(userDefaults: makeDefaults()),
            circleStore: CircleStore(userDefaults: makeDefaults(), seedStarterSpaces: false),
            aiSessionStore: AIReflectionSessionStore(userDefaults: makeDefaults())
        )

        XCTAssertEqual(syncer.snapshots.count, 0)
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
