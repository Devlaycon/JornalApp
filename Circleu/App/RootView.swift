import SwiftUI

struct RootView: View {
    @EnvironmentObject private var journalStore: ReflectionJournalStore
    @EnvironmentObject private var questStore: QuestStore
    @State private var selectedTab: PinguTab = .home
    @State private var showRecording = false

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                PinguTopBar(
                    title: selectedTab.navigationTitle,
                    leadingIcon: selectedTab.navigationIcon,
                    trailing: navigationTrailing
                )

                Group {
                    switch selectedTab {
                    case .home:
                        HomeView(
                            onStartRecording: { showRecording = true },
                            onOpenJournal: { selectedTab = .journal }
                        )
                    case .journal:
                        JournalView(onStartRecording: { showRecording = true })
                    case .circle:
                        CircleView()
                    case .profile:
                        ProfileView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            PinguBottomTabBar(selection: $selectedTab)
        }
        .background(PinguDesign.ice)
        .fullScreenCover(isPresented: $showRecording) {
            RecordingView(
                onViewJournal: {
                    selectedTab = .journal
                    showRecording = false
                }
            )
        }
    }

    private var navigationTrailing: PinguTopBar.Trailing {
        switch selectedTab {
        case .home:
            .level(progress.level)
        case .journal, .profile:
            .streak(progress.streak)
        case .circle:
            .none
        }
    }

    private var progress: AppProgressSnapshot {
        ProgressEngine.snapshot(entries: journalStore.entries, quests: questStore.quests)
    }
}

private extension PinguTab {
    var navigationTitle: String {
        switch self {
        case .home:
            "Circleu"
        case .journal:
            "Journal"
        case .circle:
            "Circles"
        case .profile:
            "Profile"
        }
    }

    var navigationIcon: String {
        switch self {
        case .home:
            "sparkles"
        case .journal:
            "book.closed.fill"
        case .circle:
            "person.2.fill"
        case .profile:
            "person.crop.circle.fill"
        }
    }

}

#Preview {
    RootView()
        .environmentObject(ReflectionJournalStore())
        .environmentObject(QuestStore())
        .environmentObject(CircleStore())
        .environmentObject(UserProfileStore())
        .environmentObject(AIReflectionSessionStore())
}
