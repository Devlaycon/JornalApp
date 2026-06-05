import SwiftUI

struct TipsView: View {
    @EnvironmentObject private var journalStore: ReflectionJournalStore
    @EnvironmentObject private var questStore: QuestStore
    @EnvironmentObject private var practiceStore: TipsPracticeStore
    @StateObject private var viewModel = TipsPracticeViewModel()

    let onOpenJournalEntry: (JournalReflectionEntry) -> Void

    var body: some View {
        ZStack {
            PinguScreenBackground()

            switch viewModel.mode {
            case .setup:
                TipsSetupView(
                    viewModel: viewModel,
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
            sourceEntry: sourceEntry(for:),
            onOpenSource: onOpenJournalEntry,
            onComplete: { quest in
                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                    questStore.complete(quest)
                }
            },
            onRestart: { quest in
                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                    questStore.reactivate(quest)
                }
            }
        )
    }

    private func sourceEntry(for quest: Quest) -> JournalReflectionEntry? {
        guard let sourceEntryID = quest.sourceEntryID else { return nil }
        return journalStore.entry(with: sourceEntryID)
    }
}

#Preview {
    TipsView(onOpenJournalEntry: { _ in })
        .environmentObject(ReflectionJournalStore())
        .environmentObject(QuestStore())
        .environmentObject(TipsPracticeStore())
}
