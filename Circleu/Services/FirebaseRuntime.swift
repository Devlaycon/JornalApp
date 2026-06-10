import FirebaseCore
import Foundation

enum FirebaseRuntime {
    static var expectedBundleID: String {
        Bundle.main.bundleIdentifier ?? ""
    }

    static var configuredApp: FirebaseApp? {
        FirebaseApp.app()
    }

    static var canUseLiveFirebase: Bool {
        configuredApp != nil
    }

    @discardableResult
    static func configureIfAvailable() -> Bool {
        guard FirebaseApp.app() == nil else { return true }
        guard let options = FirebaseOptions.defaultOptions() else {
            print("Firebase disabled: GoogleService-Info.plist is missing.")
            return false
        }

        let configuredBundleID = options.bundleID
        let appBundleID = expectedBundleID
        guard configuredBundleID == appBundleID else {
            print("Firebase disabled: GoogleService-Info.plist bundle ID '\(configuredBundleID)' does not match app bundle ID '\(appBundleID)'.")
            return false
        }

        FirebaseApp.configure(options: options)
        return true
    }

    static func makeAuthenticator() -> FirebaseAuthenticating {
        canUseLiveFirebase ? FirebaseAuthService() : NoOpFirebaseAuthenticator()
    }

    static func makeSyncer() -> any ReflectionSyncing & ReflectionBackupRestoring {
        canUseLiveFirebase ? FirebaseUploadOnlySyncer() : NoOpBackendSyncer()
    }
}

struct NoOpBackendSyncer: ReflectionSyncing, ReflectionBackupRestoring {
    func sync(_ snapshot: BackendSyncSnapshot) async throws -> BackendSyncResult {
        BackendSyncResult()
    }

    func restorePrivateBackup(userID: String) async throws -> BackendSyncSnapshot {
        BackendSyncSnapshot(
            userID: userID,
            journalEntries: [],
            quests: [],
            circles: [],
            circlePosts: [],
            aiSessions: []
        )
    }
}
