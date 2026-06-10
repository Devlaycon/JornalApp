import Combine
import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    enum Stage {
        case welcome
        case signup
        case signin
    }

    @Published var stage: Stage = .welcome
    @Published var name = ""
    @Published var email = ""
    @Published var password = ""
    @Published var errorMessage: String?

    var canSubmitSignup: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func go(to stage: Stage) {
        errorMessage = nil
        self.stage = stage
    }

    func signUp(authStore: AuthStore, profileStore: UserProfileStore, onContinue: () -> Void) {
        do {
            let account = try authStore.signUp(name: name, email: email, password: password)
            profileStore.updateDisplayName(account.displayName)
            UserDefaults.standard.set(true, forKey: "showWelcomeHints")
            errorMessage = nil
            onContinue()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signIn(authStore: AuthStore, profileStore: UserProfileStore, onContinue: () -> Void) {
        do {
            let account = try authStore.signIn(email: email, password: password)
            profileStore.updateDisplayName(account.displayName)
            errorMessage = nil
            onContinue()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func skip(profileStore: UserProfileStore, onContinue: () -> Void) {
        if !profileStore.hasDisplayName {
            profileStore.updateDisplayName("Friend")
        }
        onContinue()
    }
}
