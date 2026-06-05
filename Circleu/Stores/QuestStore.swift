import Combine
import Foundation

@MainActor
final class QuestStore: ObservableObject {
    @Published private(set) var quests: [Quest] = []

    private let storageKey = "circleu.quests.v1"
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        load()
    }

    var activeQuests: [Quest] {
        quests.filter { $0.status == .active }
    }

    var completedQuests: [Quest] {
        quests.filter { $0.status == .completed }
    }

    var skippedQuests: [Quest] {
        quests.filter { $0.status == .skipped }
    }

    var latestActiveQuest: Quest? {
        activeQuests.first
    }

    func quest(for entry: JournalReflectionEntry) -> Quest? {
        quests.first { $0.sourceEntryID == entry.id }
    }

    func activeQuest(for entry: JournalReflectionEntry) -> Quest? {
        quests.first { $0.sourceEntryID == entry.id && $0.status == .active }
    }

    func addSuggestedQuest(from entry: JournalReflectionEntry) {
        _ = activateSuggestedQuest(from: entry)
    }

    @discardableResult
    func activateSuggestedQuest(from entry: JournalReflectionEntry) -> Quest? {
        let detail = entry.result.suggestedQuest.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !detail.isEmpty else { return nil }

        if let index = quests.firstIndex(where: { $0.sourceEntryID == entry.id }) {
            quests[index].title = "Try this next"
            quests[index].detail = detail
            quests[index].status = .active
            quests[index].completedAt = nil
            save()
            return quests[index]
        }

        let quest = Quest(
            title: "Try this next",
            detail: detail,
            sourceEntryID: entry.id
        )
        quests.insert(quest, at: 0)
        save()
        return quest
    }

    func complete(_ quest: Quest) {
        update(quest, status: .completed, completedAt: Date())
    }

    func skip(_ quest: Quest) {
        update(quest, status: .skipped, completedAt: Date())
    }

    func reactivate(_ quest: Quest) {
        update(quest, status: .active, completedAt: nil)
    }

    func delete(_ quest: Quest) {
        quests.removeAll { $0.id == quest.id }
        save()
    }

    func replaceAll(with newQuests: [Quest]) {
        quests = newQuests.sorted { $0.createdAt > $1.createdAt }
        save()
    }

    func reset() {
        quests = []
        userDefaults.removeObject(forKey: storageKey)
    }

    func seedDemoData(entries: [JournalReflectionEntry], referenceDate: Date = Date()) {
        let sortedEntries = entries.sorted { $0.createdAt > $1.createdAt }
        let latestEntry = sortedEntries.first
        let previousEntry = sortedEntries.dropFirst().first

        var demoQuests: [Quest] = [
            Quest(
                title: "Try this next",
                detail: latestEntry?.result.suggestedQuest ?? "Record a thirty-second check-in tomorrow about one moment you handled well.",
                sourceEntryID: latestEntry?.id,
                createdAt: referenceDate,
                status: .active
            )
        ]

        if let previousEntry {
            demoQuests.append(
                Quest(
                    title: "Completed tips",
                    detail: previousEntry.result.suggestedQuest,
                    sourceEntryID: previousEntry.id,
                    createdAt: Calendar.current.date(byAdding: .day, value: -1, to: referenceDate) ?? referenceDate,
                    completedAt: referenceDate,
                    status: .completed
                )
            )
        }

        replaceAll(with: demoQuests)
    }

    private func update(_ quest: Quest, status: QuestStatus, completedAt: Date?) {
        guard let index = quests.firstIndex(where: { $0.id == quest.id }) else { return }
        quests[index].status = status
        quests[index].completedAt = completedAt
        save()
    }

    private func load() {
        guard let data = userDefaults.data(forKey: storageKey),
              let savedQuests = try? decoder.decode([Quest].self, from: data) else {
            quests = []
            return
        }

        quests = savedQuests
    }

    private func save() {
        guard let data = try? encoder.encode(quests) else { return }
        userDefaults.set(data, forKey: storageKey)
    }
}
