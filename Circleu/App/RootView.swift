import SwiftUI

struct RootView: View {
    @State private var selectedTab: PinguTab = {
        switch ProcessInfo.processInfo.environment["START_TAB"] {
        case "journal": return .journal
        case "tips": return .tips
        case "circle": return .circle
        case "profile": return .profile
        default: return .home
        }
    }()
    @State private var showRecording = false
    @State private var selectedJournalEntry: JournalReflectionEntry?

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    HomeView(
                        onStartRecording: { showRecording = true },
                        onOpenJournal: { selectedTab = .journal },
                        onOpenTips: { selectedTab = .tips }
                    )
                case .journal:
                    JournalView(onStartRecording: { showRecording = true })
                case .tips:
                    TipsView(
                        onOpenJournalEntry: { selectedJournalEntry = $0 }
                    )
                case .circle:
                    CircleView()
                case .profile:
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            PinguBottomTabBar(selection: $selectedTab)
        }
        .background(PinguAurora())
        .fullScreenCover(isPresented: $showRecording) {
            RecordingView(
                onViewJournal: {
                    selectedTab = .journal
                    showRecording = false
                },
                onViewTips: {
                    selectedTab = .tips
                    showRecording = false
                }
            )
        }
        .sheet(item: $selectedJournalEntry) { entry in
            NavigationStack {
                JournalEntryDetailView(entry: entry)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") {
                                selectedJournalEntry = nil
                            }
                        }
                    }
            }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(ReflectionJournalStore())
        .environmentObject(QuestStore())
        .environmentObject(TipsPracticeStore())
        .environmentObject(CircleStore())
        .environmentObject(UserProfileStore())
        .environmentObject(AIReflectionSessionStore())
}
