import FirebaseAuth
import Foundation

struct FirebaseAuthSession: Codable, Equatable {
    var uid: String
    var email: String?
    var displayName: String
    var localUserID: String?
}

struct FirebaseAuthProfile: Codable, Equatable {
    var email: String
    var displayName: String
    var localUserID: String

    init(email: String, displayName: String, localUserID: String) {
        self.email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        let cleanName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.displayName = cleanName.isEmpty ? "Friend" : cleanName
        self.localUserID = localUserID
    }

    init(account: Account, localUserID: String) {
        self.init(email: account.email, displayName: account.displayName, localUserID: localUserID)
    }
}

nonisolated protocol FirebaseAuthenticating {
    var currentSession: FirebaseAuthSession? { get }

    func signUp(profile: FirebaseAuthProfile, password: String) async throws -> FirebaseAuthSession
    func signIn(email: String, password: String) async throws -> FirebaseAuthSession
    func signOut() throws
}

nonisolated protocol FirebaseAuthClient {
    var currentUser: FirebaseAuthSession? { get }

    func createUser(email: String, password: String) async throws -> FirebaseAuthSession
    func signIn(email: String, password: String) async throws -> FirebaseAuthSession
    func updateDisplayName(_ displayName: String) async throws -> FirebaseAuthSession
    func signOut() throws
}

struct FirebaseAuthService: FirebaseAuthenticating {
    nonisolated(unsafe) private let client: FirebaseAuthClient

    nonisolated init(client: FirebaseAuthClient = LiveFirebaseAuthClient()) {
        self.client = client
    }

    nonisolated var currentSession: FirebaseAuthSession? {
        client.currentUser
    }

    nonisolated func signUp(profile: FirebaseAuthProfile, password: String) async throws -> FirebaseAuthSession {
        let created = try await client.createUser(email: profile.email, password: password)
        let updated = try await client.updateDisplayName(profile.displayName)

        return FirebaseAuthSession(
            uid: updated.uid,
            email: updated.email ?? created.email ?? profile.email,
            displayName: updated.displayName,
            localUserID: profile.localUserID
        )
    }

    nonisolated func signIn(email: String, password: String) async throws -> FirebaseAuthSession {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return try await client.signIn(email: cleanEmail, password: password)
    }

    nonisolated func signOut() throws {
        try client.signOut()
    }
}

struct NoOpFirebaseAuthenticator: FirebaseAuthenticating {
    nonisolated var currentSession: FirebaseAuthSession? { nil }

    nonisolated func signUp(profile: FirebaseAuthProfile, password: String) async throws -> FirebaseAuthSession {
        FirebaseAuthSession(
            uid: profile.localUserID,
            email: profile.email,
            displayName: profile.displayName,
            localUserID: profile.localUserID
        )
    }

    nonisolated func signIn(email: String, password: String) async throws -> FirebaseAuthSession {
        FirebaseAuthSession(
            uid: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            displayName: "Friend",
            localUserID: nil
        )
    }

    nonisolated func signOut() throws {}
}

struct LiveFirebaseAuthClient: FirebaseAuthClient {
    nonisolated init() {}

    nonisolated var currentUser: FirebaseAuthSession? {
        Auth.auth().currentUser.map(Self.session(from:))
    }

    nonisolated func createUser(email: String, password: String) async throws -> FirebaseAuthSession {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<FirebaseAuthSession, Error>) in
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let user = result?.user else {
                    continuation.resume(throwing: FirebaseAuthServiceError.missingUser)
                    return
                }

                continuation.resume(returning: Self.session(from: user))
            }
        }
    }

    nonisolated func signIn(email: String, password: String) async throws -> FirebaseAuthSession {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<FirebaseAuthSession, Error>) in
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let user = result?.user else {
                    continuation.resume(throwing: FirebaseAuthServiceError.missingUser)
                    return
                }

                continuation.resume(returning: Self.session(from: user))
            }
        }
    }

    nonisolated func updateDisplayName(_ displayName: String) async throws -> FirebaseAuthSession {
        guard let user = Auth.auth().currentUser else {
            throw FirebaseAuthServiceError.missingUser
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let request = user.createProfileChangeRequest()
            request.displayName = displayName
            request.commitChanges { error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                continuation.resume()
            }
        }

        return Self.session(from: user)
    }

    nonisolated func signOut() throws {
        try Auth.auth().signOut()
    }

    nonisolated private static func session(from user: User) -> FirebaseAuthSession {
        let trimmedName = user.displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return FirebaseAuthSession(
            uid: user.uid,
            email: user.email,
            displayName: trimmedName.isEmpty ? "Friend" : trimmedName,
            localUserID: nil
        )
    }
}

enum FirebaseAuthServiceError: LocalizedError, Equatable {
    case missingUser

    var errorDescription: String? {
        switch self {
        case .missingUser:
            return "Firebase did not return an authenticated user."
        }
    }
}
