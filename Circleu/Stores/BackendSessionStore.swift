import Combine
import Foundation

@MainActor
final class BackendSessionStore: ObservableObject {
    @Published private(set) var session: FirebaseAuthSession?
    @Published private(set) var lastAuthErrorMessage: String?
    @Published private(set) var lastSyncResult: BackendSyncResult?
    @Published private(set) var lastSyncErrorMessage: String?
    @Published private(set) var isSyncing = false

    private let authenticator: FirebaseAuthenticating
    private let syncer: ReflectionSyncing
    private let identityProvider: UserIdentityProviding

    init(
        authenticator: FirebaseAuthenticating = FirebaseAuthService(),
        syncer: ReflectionSyncing = FirebaseUploadOnlySyncer(),
        identityProvider: UserIdentityProviding = LocalUserIdentityProvider()
    ) {
        self.authenticator = authenticator
        self.syncer = syncer
        self.identityProvider = identityProvider
        session = authenticator.currentSession
    }

    var backendUserID: String? {
        session?.uid
    }

    func signUp(
        name: String,
        email: String,
        password: String,
        authStore: AuthStore,
        profileStore: UserProfileStore
    ) async throws -> Account {
        let account: Account
        do {
            account = try authStore.signUp(name: name, email: email, password: password)
        } catch AuthError.emailTaken {
            account = try authStore.signIn(email: email, password: password)
        }
        profileStore.updateDisplayName(account.displayName)

        do {
            session = try await authenticator.signUp(
                profile: FirebaseAuthProfile(account: account, localUserID: identityProvider.localUserID),
                password: password
            )
            lastAuthErrorMessage = nil
        } catch {
            do {
                session = try await authenticator.signIn(email: account.email, password: password)
                lastAuthErrorMessage = nil
            } catch {
                lastAuthErrorMessage = error.localizedDescription
                throw error
            }
        }

        return account
    }

    func signIn(
        email: String,
        password: String,
        authStore: AuthStore,
        profileStore: UserProfileStore
    ) async throws -> Account {
        let account = try authStore.signIn(email: email, password: password)
        profileStore.updateDisplayName(account.displayName)

        do {
            session = try await authenticator.signIn(email: email, password: password)
            lastAuthErrorMessage = nil
        } catch {
            lastAuthErrorMessage = error.localizedDescription
            throw error
        }

        return account
    }

    func signOut(authStore: AuthStore) {
        do {
            try authenticator.signOut()
            lastAuthErrorMessage = nil
        } catch {
            lastAuthErrorMessage = error.localizedDescription
        }

        session = nil
        authStore.logout()
    }

    func uploadPrivateBackup(
        journalStore: ReflectionJournalStore,
        questStore: QuestStore,
        circleStore: CircleStore,
        aiSessionStore: AIReflectionSessionStore
    ) async {
        guard let uid = session?.uid else { return }
        guard !isSyncing else { return }

        let snapshot = BackendSyncSnapshot(
            userID: uid,
            journalEntries: journalStore.entries,
            quests: questStore.quests,
            circles: circleStore.circles,
            circlePosts: circleStore.posts,
            aiSessions: aiSessionStore.sessions
        )

        guard !snapshot.isEmpty else { return }

        isSyncing = true
        defer { isSyncing = false }

        do {
            lastSyncResult = try await syncer.sync(snapshot)
            lastSyncErrorMessage = nil
        } catch {
            lastSyncErrorMessage = error.localizedDescription
        }
    }
}
