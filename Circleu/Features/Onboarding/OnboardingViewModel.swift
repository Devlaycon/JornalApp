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
    @Published private(set) var isSubmitting = false

    var canSubmitSignup: Bool {
        !isSubmitting && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func go(to stage: Stage) {
        errorMessage = nil
        self.stage = stage
    }

    func signUp(
        authStore: AuthStore,
        profileStore: UserProfileStore,
        backendSessionStore: BackendSessionStore,
        onContinue: () -> Void
    ) async {
        guard !isSubmitting else { return }
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            _ = try await backendSessionStore.signUp(
                name: name,
                email: email,
                password: password,
                authStore: authStore,
                profileStore: profileStore
            )
            UserDefaults.standard.set(true, forKey: "showWelcomeHints")
            errorMessage = nil
            onContinue()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signIn(
        authStore: AuthStore,
        profileStore: UserProfileStore,
        backendSessionStore: BackendSessionStore,
        onContinue: () -> Void
    ) async {
        guard !isSubmitting else { return }
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            _ = try await backendSessionStore.signIn(
                email: email,
                password: password,
                authStore: authStore,
                profileStore: profileStore
            )
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
