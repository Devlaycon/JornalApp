import SwiftUI

struct TabBarHiddenKey: PreferenceKey {
    static var defaultValue: Bool = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

struct RootView: View {
    @State private var hidesTabBar = false
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

            if !hidesTabBar {
                PinguBottomTabBar(selection: $selectedTab)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onPreferenceChange(TabBarHiddenKey.self) { hidesTabBar = $0 }
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
