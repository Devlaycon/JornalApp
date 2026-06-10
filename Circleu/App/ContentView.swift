import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var journalStore = ReflectionJournalStore()
    @StateObject private var profileStore = UserProfileStore()
    @StateObject private var circleStore = CircleStore()
    @StateObject private var questStore = QuestStore()
    @StateObject private var tipsPracticeStore = TipsPracticeStore()
    @StateObject private var aiSessionStore = AIReflectionSessionStore()
    @StateObject private var rewardsStore = RewardsStore()
    @StateObject private var authStore = AuthStore()
    @StateObject private var backendSessionStore = BackendSessionStore()

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                RootView()
                    .onAppear { rewardsStore.claimDailyLogin() }
            } else {
                PinguOnboardingView {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) {
                        hasCompletedOnboarding = true
                    }
                }
            }
        }
        .environmentObject(journalStore)
        .environmentObject(profileStore)
        .environmentObject(circleStore)
        .environmentObject(questStore)
        .environmentObject(tipsPracticeStore)
        .environmentObject(aiSessionStore)
        .environmentObject(rewardsStore)
        .environmentObject(authStore)
        .environmentObject(backendSessionStore)
        // Keep CircleStore tied to the current Firebase auth session so public circles sync
        // from /circles for whoever is signed in (and tear down when signed out).
        .onAppear {
            backendSessionStore.wireBackendStores(circleStore: circleStore)
        }
        .onChange(of: backendSessionStore.session?.uid) {
            backendSessionStore.wireBackendStores(circleStore: circleStore)
        }
    }
}

#Preview {
    ContentView()
}
