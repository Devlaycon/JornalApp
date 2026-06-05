import Foundation

struct DailyReflectionBetaState: Equatable {
    let hasCompletedToday: Bool
    let nextActionTitle: String
    let nextActionSubtitle: String
    let tipsProgressText: String

    static func make(
        entries: [JournalReflectionEntry],
        quests: [Quest],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> DailyReflectionBetaState {
        let hasCompletedToday = entries.contains { calendar.isDate($0.createdAt, inSameDayAs: now) }
        let activeTips = quests.first { $0.status == .active }
        let completedCount = quests.filter { $0.status == .completed }.count

        if let activeTips {
            return DailyReflectionBetaState(
                hasCompletedToday: hasCompletedToday,
                nextActionTitle: "Continue today's tip",
                nextActionSubtitle: activeTips.detail,
                tipsProgressText: "\(completedCount) completed"
            )
        }

        if hasCompletedToday {
            return DailyReflectionBetaState(
                hasCompletedToday: true,
                nextActionTitle: "Reflect again if something changed",
                nextActionSubtitle: "You already saved a reflection today. Add another if a new moment needs attention.",
                tipsProgressText: "\(completedCount) completed"
            )
        }

        return DailyReflectionBetaState(
            hasCompletedToday: false,
            nextActionTitle: "Start today's reflection",
            nextActionSubtitle: "Record or type one honest check-in to create your next AI-guided tip.",
            tipsProgressText: "\(completedCount) completed"
        )
    }
}
