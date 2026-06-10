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
    private let restorer: ReflectionBackupRestoring
    private let identityProvider: UserIdentityProviding

    init(
        authenticator: FirebaseAuthenticating = FirebaseAuthService(),
        syncer: ReflectionSyncing = FirebaseUploadOnlySyncer(),
        restorer: ReflectionBackupRestoring = FirebaseUploadOnlySyncer(),
        identityProvider: UserIdentityProviding = LocalUserIdentityProvider()
    ) {
        self.authenticator = authenticator
        self.syncer = syncer
        self.restorer = restorer
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
        let account: Account
        do {
            account = try authStore.signIn(email: email, password: password)
        } catch AuthError.noAccount {
            let restoredSession = try await signInWithFirebase(email: email, password: password)
            account = try authStore.signUp(
                name: restoredDisplayName(from: restoredSession, email: email),
                email: email,
                password: password
            )
        }

        profileStore.updateDisplayName(account.displayName)

        if session?.email != account.email {
            _ = try await signInWithFirebase(email: email, password: password)
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
        profileStore: UserProfileStore,
        journalStore: ReflectionJournalStore,
        questStore: QuestStore,
        tipsPracticeStore: TipsPracticeStore,
        rewardsStore: RewardsStore,
        circleStore: CircleStore,
        aiSessionStore: AIReflectionSessionStore
    ) async {
        guard let uid = session?.uid else { return }
        guard !isSyncing else { return }
        let now = Date()

        let snapshot = BackendSyncSnapshot(
            userID: uid,
            generatedAt: now,
            user: BackendUserSnapshot(
                uid: uid,
                email: session?.email,
                displayName: session?.displayName ?? profileStore.displayName,
                localUserID: session?.localUserID,
                updatedAt: now
            ),
            profile: BackendProfileSnapshot(
                displayName: profileStore.displayName,
                promptIndex: profileStore.dailyPromptIndex,
                updatedAt: now
            ),
            journalEntries: journalStore.entries,
            quests: questStore.quests,
            tipsPracticeSessions: tipsPracticeStore.recentSessions,
            rewardState: BackendRewardSnapshot(
                points: rewardsStore.points,
                level: rewardsStore.level,
                intoLevel: rewardsStore.intoLevel,
                nextLevel: rewardsStore.nextLevel,
                questAwards: rewardsStore.questAwards,
                updatedAt: now
            ),
            pointEntries: rewardsStore.pointsLog,
            activityEvents: rewardsStore.activity,
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

    func restorePrivateBackup(
        profileStore: UserProfileStore,
        journalStore: ReflectionJournalStore,
        questStore: QuestStore,
        tipsPracticeStore: TipsPracticeStore,
        rewardsStore: RewardsStore,
        aiSessionStore: AIReflectionSessionStore
    ) async {
        guard let uid = session?.uid else { return }
        guard !isSyncing else { return }

        isSyncing = true
        defer { isSyncing = false }

        do {
            let snapshot = try await restorer.restorePrivateBackup(userID: uid)
            profileStore.mergeRestoredProfile(snapshot.profile)
            journalStore.mergeRestoredEntries(snapshot.journalEntries)
            questStore.mergeRestoredQuests(snapshot.quests)
            tipsPracticeStore.mergeRestoredSessions(snapshot.tipsPracticeSessions)
            rewardsStore.mergeRestoredBackup(
                rewardState: snapshot.rewardState,
                pointEntries: snapshot.pointEntries,
                activityEvents: snapshot.activityEvents
            )
            aiSessionStore.mergeRestoredSessions(snapshot.aiSessions)

            lastSyncResult = BackendSyncResult(downloadedCounts: snapshot.counts)
            lastSyncErrorMessage = nil
        } catch {
            lastSyncErrorMessage = error.localizedDescription
        }
    }

    private func signInWithFirebase(email: String, password: String) async throws -> FirebaseAuthSession {
        do {
            let firebaseSession = try await authenticator.signIn(email: email, password: password)
            session = firebaseSession
            lastAuthErrorMessage = nil
            return firebaseSession
        } catch {
            lastAuthErrorMessage = error.localizedDescription
            throw error
        }
    }

    private func fallbackDisplayName(from email: String) -> String {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let prefix = cleanEmail.split(separator: "@").first.map(String.init) ?? ""
        return prefix.isEmpty ? "Friend" : prefix
    }

    private func restoredDisplayName(from session: FirebaseAuthSession, email: String) -> String {
        let displayName = session.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return displayName.isEmpty ? fallbackDisplayName(from: email) : displayName
    }
}
