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
                            onOpenPractice: { selectedTab = .practice }
                        )
                    case .journal:
                        JournalView(onStartRecording: { showRecording = true })
                    case .practice:
                        PracticeView(
                            onStartRecording: { showRecording = true },
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

            PinguBottomTabBar(selection: $selectedTab)
        }
        .background(PinguAuroraBackground())
        .fullScreenCover(isPresented: $showRecording) {
            RecordingView(
                onViewJournal: {
                    selectedTab = .journal
                    showRecording = false
                },
                onViewPractice: {
                    selectedTab = .practice
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
        case .journal, .practice, .profile:
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
        case .practice:
            "Tips"
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
        case .practice:
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
        .environmentObject(CircleStore())
        .environmentObject(UserProfileStore())
        .environmentObject(AIReflectionSessionStore())
}
