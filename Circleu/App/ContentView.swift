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
    }
}

#Preview {
    ContentView()
}
