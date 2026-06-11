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
        appContent
            .environmentObject(journalStore)
            .environmentObject(profileStore)
            .environmentObject(circleStore)
            .environmentObject(questStore)
            .environmentObject(tipsPracticeStore)
            .environmentObject(aiSessionStore)
            .environmentObject(rewardsStore)
            .environmentObject(authStore)
            .environmentObject(backendSessionStore)
            // Keep backend-aware stores tied to the current Firebase auth session: CircleStore
            // mirrors /circles for whoever is signed in, while user stores scope their
            // on-device cache by UID so accounts cannot see each other's data.
            .onAppear {
                seedSnapshotDataIfRequested()
                backendSessionStore.wireBackendStores(
                    circleStore: circleStore,
                    journalStore: journalStore,
                    aiSessionStore: aiSessionStore,
                    rewardsStore: rewardsStore,
                    questStore: questStore,
                    tipsPracticeStore: tipsPracticeStore,
                    profileStore: profileStore
                )
            }
            .onChange(of: backendSessionStore.session?.uid) {
                backendSessionStore.wireBackendStores(
                    circleStore: circleStore,
                    journalStore: journalStore,
                    aiSessionStore: aiSessionStore,
                    rewardsStore: rewardsStore,
                    questStore: questStore,
                    tipsPracticeStore: tipsPracticeStore,
                    profileStore: profileStore
                )
            }
    }

    @ViewBuilder
    private var appContent: some View {
#if DEBUG
        if snapshotScreen == "reflection", let entry = ReflectionJournalStore.demoEntries().first {
            ReflectionView(entry: entry)
        } else if hasCompletedOnboarding {
            RootView()
                .onAppear { rewardsStore.claimDailyLogin() }
        } else {
            PinguOnboardingView {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) {
                    hasCompletedOnboarding = true
                }
            }
        }
#else
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
#endif
    }

#if DEBUG
    private var snapshotScreen: String? {
        ProcessInfo.processInfo.environment["SNAPSHOT_SCREEN"]
    }

    private func seedSnapshotDataIfRequested() {
        guard ProcessInfo.processInfo.environment["SNAPSHOT_MODE"] == "1" else { return }

        let referenceDate = Date()
        let entries = ReflectionJournalStore.demoEntries(referenceDate: referenceDate)
        hasCompletedOnboarding = true
        journalStore.replaceAll(with: entries)
        aiSessionStore.seedDemoData(entries: entries)
        questStore.seedDemoData(entries: entries, referenceDate: referenceDate)
        circleStore.seedDemoData(entries: entries, referenceDate: referenceDate)
        tipsPracticeStore.activate(PreviewData.tipsSession)
        rewardsStore.resetToSeed()
    }
#else
    private func seedSnapshotDataIfRequested() {}
#endif
}

#Preview {
    ContentView()
}
