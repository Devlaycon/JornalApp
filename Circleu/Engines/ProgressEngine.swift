import Foundation

enum ProgressEngine {
    static func snapshot(entries: [JournalReflectionEntry], quests: [Quest]) -> AppProgressSnapshot {
        let completedQuestCount = quests.filter { $0.status == .completed }.count
        let currentStreak = streak(from: entries)
        let currentXP = xp(
            entryCount: entries.count,
            completedQuestCount: completedQuestCount,
            streak: currentStreak
        )
        let currentLevel = level(
            entryCount: entries.count,
            completedQuestCount: completedQuestCount,
            streak: currentStreak
        )

        return AppProgressSnapshot(
            entryCount: entries.count,
            streak: currentStreak,
            level: currentLevel,
            xp: currentXP,
            xpForNextLevel: max(100, currentLevel * 100),
            mostCommonEmotion: mostCommonEmotion(from: entries),
            completedQuestCount: completedQuestCount,
            badges: badges(
                entryCount: entries.count,
                streak: currentStreak,
                completedQuestCount: completedQuestCount
            )
        )
    }

    static func streak(from entries: [JournalReflectionEntry], calendar: Calendar = .current) -> Int {
        let days = Set(entries.map { calendar.startOfDay(for: $0.createdAt) })
        guard !days.isEmpty else { return 0 }

        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        var cursor: Date

        if days.contains(today) {
            cursor = today
        } else if days.contains(yesterday) {
            cursor = yesterday
        } else {
            return 0
        }

        var count = 0
        while days.contains(cursor) {
            count += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previousDay
        }

        return count
    }

    static func level(entryCount: Int, completedQuestCount: Int, streak: Int) -> Int {
        max(1, min(12, xp(entryCount: entryCount, completedQuestCount: completedQuestCount, streak: streak) / 100 + 1))
    }

    static func xp(entryCount: Int, completedQuestCount: Int, streak: Int) -> Int {
        // Mirrors the daily-quest values shown in Profile:
        // reflect=8, tips=5, daily login (≈streak) =2
        entryCount * 8 + completedQuestCount * 5 + streak * 2
    }

    private static func mostCommonEmotion(from entries: [JournalReflectionEntry]) -> String {
        let emotions = entries
            .map { $0.result.emotion.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !emotions.isEmpty else { return "None" }

        let counts = Dictionary(grouping: emotions, by: { $0 }).mapValues(\.count)
        return counts.max { lhs, rhs in
            if lhs.value == rhs.value { return lhs.key > rhs.key }
            return lhs.value < rhs.value
        }?.key ?? "None"
    }

    private static func badges(entryCount: Int, streak: Int, completedQuestCount: Int) -> [ProgressBadge] {
        [
            ProgressBadge(
                id: "first-reflection",
                title: "First Reflection",
                subtitle: "Save your first check-in",
                icon: "sparkles",
                isUnlocked: entryCount >= 1
            ),
            ProgressBadge(
                id: "three-reflections",
                title: "Pattern Finder",
                subtitle: "Save three reflections",
                icon: "chart.line.uptrend.xyaxis",
                isUnlocked: entryCount >= 3
            ),
            ProgressBadge(
                id: "seven-day-streak",
                title: "Steady Week",
                subtitle: "Reflect seven days in a row",
                icon: "flame.fill",
                isUnlocked: streak >= 7
            ),
            ProgressBadge(
                id: "three-quests",
                title: "Action Taker",
                subtitle: "Complete three quests",
                icon: "checkmark.seal.fill",
                isUnlocked: completedQuestCount >= 3
            )
        ]
    }
}
