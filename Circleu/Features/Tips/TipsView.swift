import SwiftUI

struct TipsView: View {
    @EnvironmentObject private var journalStore: ReflectionJournalStore
    @EnvironmentObject private var questStore: QuestStore
    @EnvironmentObject private var practiceStore: TipsPracticeStore
    @StateObject private var viewModel = TipsPracticeViewModel()
    @StateObject private var tipsViewModel = TipsViewModel()

    let onOpenJournalEntry: (JournalReflectionEntry) -> Void

    var body: some View {
        ZStack {
            PinguScreenBackground()

            switch viewModel.mode {
            case .setup:
                TipsSetupView(
                    viewModel: viewModel,
                    recentSessions: practiceStore.recentSessions,
                    reflectionHistory: AnyView(reflectionHistory)
                )
            case .liveCoach:
                TipsLiveCoachView(viewModel: viewModel)
            }
        }
        .onAppear {
            viewModel.bind(store: practiceStore)
        }
    }

    private var reflectionHistory: some View {
        ReflectionTipsHistorySection(
            activeQuests: questStore.activeQuests,
            completedQuests: questStore.completedQuests,
            skippedQuests: questStore.skippedQuests,
            sourceEntry: { quest in
                tipsViewModel.sourceEntry(for: quest, journalStore: journalStore)
            },
            onOpenSource: onOpenJournalEntry,
            onComplete: { quest in
                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                    tipsViewModel.complete(quest, questStore: questStore)
                }
            },
            onRestart: { quest in
                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                    tipsViewModel.restart(quest, questStore: questStore)
                }
            }
        )
    }
}

#Preview {
    TipsView(onOpenJournalEntry: { _ in })
        .environmentObject(ReflectionJournalStore())
        .environmentObject(QuestStore())
        .environmentObject(TipsPracticeStore())
}
