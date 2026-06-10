import Combine
import CryptoKit
import Foundation

/// A locally-stored user account. Passwords are never stored in plain text —
/// only a salted SHA-256 hash is persisted on the device.
struct Account: Codable, Equatable {
    let id: UUID
    var email: String
    var displayName: String
    var passwordHash: String
    var salt: String
    var createdAt: Date
}

enum AuthError: LocalizedError, Equatable {
    case invalidEmail
    case weakPassword
    case emailTaken
    case noAccount
    case wrongPassword

    var errorDescription: String? {
        switch self {
        case .invalidEmail: return "Please enter a valid email address."
        case .weakPassword: return "Password must be more than 8 characters."
        case .emailTaken: return "An account with this email already exists."
        case .noAccount: return "No account found for this email."
        case .wrongPassword: return "Incorrect password. Please try again."
        }
    }
}

/// Local account database + session. Accounts live in UserDefaults on this
/// device only; there is no server. Validates real credentials on sign in.
@MainActor
final class AuthStore: ObservableObject {
    @Published private(set) var accounts: [Account] = []
    @Published private(set) var currentEmail: String?

    private let accountsKey = "circleu.auth.accounts.v1"
    private let sessionKey = "circleu.auth.session.v1"
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        load()
    }

    var currentAccount: Account? {
        guard let currentEmail else { return nil }
        return accounts.first { $0.email == currentEmail }
    }

    var isSignedIn: Bool { currentEmail != nil }

    // MARK: - Auth

    @discardableResult
    func signUp(name: String, email: String, password: String) throws -> Account {
        let cleanEmail = normalize(email)
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard isValidEmail(cleanEmail) else { throw AuthError.invalidEmail }
        guard password.count > 8 else { throw AuthError.weakPassword }
        guard !accounts.contains(where: { $0.email == cleanEmail }) else { throw AuthError.emailTaken }

        let salt = Self.makeSalt()
        let account = Account(
            id: UUID(),
            email: cleanEmail,
            displayName: cleanName.isEmpty ? "Friend" : cleanName,
            passwordHash: Self.hash(password: password, salt: salt),
            salt: salt,
            createdAt: Date()
        )
        accounts.append(account)
        currentEmail = cleanEmail
        save()
        return account
    }

    @discardableResult
    func signIn(email: String, password: String) throws -> Account {
        let cleanEmail = normalize(email)
        guard isValidEmail(cleanEmail) else { throw AuthError.invalidEmail }
        guard let account = accounts.first(where: { $0.email == cleanEmail }) else {
            throw AuthError.noAccount
        }
        guard Self.hash(password: password, salt: account.salt) == account.passwordHash else {
            throw AuthError.wrongPassword
        }
        currentEmail = cleanEmail
        save()
        return account
    }

    func logout() {
        currentEmail = nil
        userDefaults.removeObject(forKey: sessionKey)
    }

    func reset() {
        accounts = []
        currentEmail = nil
        userDefaults.removeObject(forKey: accountsKey)
        userDefaults.removeObject(forKey: sessionKey)
    }

    // MARK: - Helpers

    private func normalize(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func isValidEmail(_ email: String) -> Bool {
        guard email.count >= 5, email.contains("@") else { return false }
        let parts = email.split(separator: "@")
        return parts.count == 2 && !parts[0].isEmpty && parts[1].contains(".")
    }

    private static func makeSalt() -> String {
        UUID().uuidString
    }

    private static func hash(password: String, salt: String) -> String {
        let digest = SHA256.hash(data: Data((salt + password).utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Persistence

    private func load() {
        if let data = userDefaults.data(forKey: accountsKey),
           let saved = try? decoder.decode([Account].self, from: data) {
            accounts = saved
        }
        currentEmail = userDefaults.string(forKey: sessionKey)
    }

    private func save() {
        if let data = try? encoder.encode(accounts) {
            userDefaults.set(data, forKey: accountsKey)
        }
        if let currentEmail {
            userDefaults.set(currentEmail, forKey: sessionKey)
        } else {
            userDefaults.removeObject(forKey: sessionKey)
        }
    }
}
