import SwiftUI

struct RootView: View {
    @EnvironmentObject private var journalStore: ReflectionJournalStore
    @EnvironmentObject private var questStore: QuestStore
    @State private var selectedTab: PinguTab = .home
    @State private var showRecording = false
    @State private var selectedJournalEntry: JournalReflectionEntry?

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
            }

            // Fade scrolling content out before it reaches the floating glass
            // tab bar, so nothing peeks through or below the translucent pill.
            LinearGradient(
                colors: [PinguDesign.ice.opacity(0), PinguDesign.ice],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 132)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .allowsHitTesting(false)
            .ignoresSafeArea()

            PinguBottomTabBar(selection: $selectedTab)
        }
        .background(PinguAuroraBackground())
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

    private var navigationTrailing: PinguTopBar.Trailing {
        switch selectedTab {
        case .home:
            .level(progress.level)
        case .journal, .tips, .profile:
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
        case .tips:
            "Tips"
        case .circle:
            "Communities"
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
        case .tips:
            "mic.fill"
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
        .environmentObject(TipsPracticeStore())
        .environmentObject(CircleStore())
        .environmentObject(UserProfileStore())
        .environmentObject(AIReflectionSessionStore())
}
