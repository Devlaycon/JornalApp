import Combine
import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var selectedEntry: JournalReflectionEntry?

    let dailyPrompts = [
        "What drained you today, and what refilled you?",
        "Where did you show courage, even a little?",
        "What's one thing you handled better than last week?",
        "Who or what are you quietly grateful for?"
    ]

    func dailyPrompt(entries: [JournalReflectionEntry]) -> String {
        dailyPrompts[entries.count % dailyPrompts.count]
    }

    func greetingSubtitle(streak: Int) -> String {
        streak > 0 ? "\(streak)-day streak — let's keep it gentle." : "Let's start a small reflection."
    }

    func greetingKicker() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "GOOD MORNING" }
        if hour < 18 { return "GOOD AFTERNOON" }
        return "GOOD EVENING"
    }

    func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    func activeQuest(from questStore: QuestStore) -> Quest? {
        questStore.activeQuests.first
    }

    func activeQuestSupportText(activeQuest: Quest?) -> String {
        guard let activeQuest else {
            return "Save a reflection and Circleu will turn the insight into one small action."
        }

        return "Created \(relativeDateText(for: activeQuest.createdAt)). Complete it when the tips is done, or skip it if it no longer fits today."
    }

    func betaState(entries: [JournalReflectionEntry], quests: [Quest]) -> DailyReflectionBetaState {
        DailyReflectionBetaState.make(entries: entries, quests: quests)
    }

    func sourceEntry(for quest: Quest, entries: [JournalReflectionEntry]) -> JournalReflectionEntry? {
        guard let sourceEntryID = quest.sourceEntryID else { return nil }
        return entries.first { $0.id == sourceEntryID }
    }

    func progress(entries: [JournalReflectionEntry], quests: [Quest]) -> AppProgressSnapshot {
        ProgressEngine.snapshot(entries: entries, quests: quests)
    }

    func advanceDailyPrompt(profileStore: UserProfileStore) {
        profileStore.advanceDailyPrompt(totalPrompts: dailyPrompts.count)
    }

    func complete(_ quest: Quest, questStore: QuestStore) {
        questStore.complete(quest)
    }

    func skip(_ quest: Quest, questStore: QuestStore) {
        questStore.skip(quest)
    }

    private func relativeDateText(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
