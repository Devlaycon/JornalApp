import SwiftUI

struct TabBarHiddenKey: PreferenceKey {
    static var defaultValue: Bool = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

struct RootView: View {
    @EnvironmentObject private var journalStore: ReflectionJournalStore
    @EnvironmentObject private var tipsPracticeStore: TipsPracticeStore
    @EnvironmentObject private var circleStore: CircleStore
    @EnvironmentObject private var rewardsStore: RewardsStore

    @AppStorage("showWelcomeHints") private var showWelcomeHints = false
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
    @State private var lastJoinedIDs: Set<UUID> = []

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
                    ProfileView(
                        onStartRecording: { showRecording = true },
                        onOpenTips: { selectedTab = .tips },
                        onOpenEntry: { id in
                            if let entry = journalStore.entry(with: id) {
                                selectedJournalEntry = entry
                            }
                        }
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .id(selectedTab)
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .offset(y: 20)),
                removal: .opacity
            ))
            .animation(.spring(response: 0.5, dampingFraction: 0.82), value: selectedTab)

            if !hidesTabBar {
                PinguBottomTabBar(selection: $selectedTab)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if showWelcomeHints {
                WelcomeHintsOverlay(onDismiss: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.86)) {
                        showWelcomeHints = false
                    }
                })
                .zIndex(10)
            }
        }
        .onPreferenceChange(TabBarHiddenKey.self) { hidesTabBar = $0 }
        .onAppear {
            lastJoinedIDs = Set(circleStore.circles.filter { $0.joined }.map { $0.id })
        }
        .onChange(of: journalStore.entries.count) { oldCount, newCount in
            guard newCount > oldCount, let entry = journalStore.entries.first else { return }
            rewardsStore.awardPoints(questID: "daily_reflect", label: "Daily reflection", points: 8, icon: "📓")
            rewardsStore.pushActivity(
                type: .reflect,
                title: entry.displayTitle,
                keyword: "\(entry.displayEmotion) · reflection",
                refID: entry.id
            )
        }
        .onChange(of: tipsPracticeStore.recentSessions.count) { oldCount, newCount in
            guard newCount > oldCount, let session = tipsPracticeStore.recentSessions.first else { return }
            rewardsStore.awardPoints(questID: "daily_tips", label: "Communication tip", points: 5, icon: "💬")
            rewardsStore.pushActivity(
                type: .tips,
                title: session.sceneTitle,
                keyword: "\(session.tone)"
            )
        }
        .onChange(of: circleStore.circles.filter { $0.joined }.count) { _, _ in
            let current = Set(circleStore.circles.filter { $0.joined }.map { $0.id })
            let newlyJoined = current.subtracting(lastJoinedIDs)
            for id in newlyJoined {
                if let circle = circleStore.circles.first(where: { $0.id == id }) {
                    rewardsStore.pushActivity(type: .communityJoin, title: circle.name, keyword: "joined", refID: circle.id)
                }
            }
            lastJoinedIDs = current
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
        .environmentObject(RewardsStore())
}
