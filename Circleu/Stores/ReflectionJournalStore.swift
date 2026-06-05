import Combine
import Foundation

@MainActor
final class ReflectionJournalStore: ObservableObject {
    @Published private(set) var entries: [JournalReflectionEntry] = []

    private let storageKey = "circleu.saved.reflections.v1"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        load()
    }

    func add(_ entry: JournalReflectionEntry) {
        guard !entries.contains(where: { $0.id == entry.id }) else { return }
        entries.insert(entry, at: 0)
        save()
    }

    func replaceAll(with newEntries: [JournalReflectionEntry]) {
        entries = newEntries.sorted { $0.createdAt > $1.createdAt }
        save()
    }

    func updateWorkspace(
        entry: JournalReflectionEntry,
        title: String?,
        emotion: String?,
        privateNote: String,
        tags: [String]
    ) {
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else { return }

        entries[index].editableTitle = sanitizedOptional(title)
        entries[index].editableEmotion = sanitizedOptional(emotion)
        entries[index].privateNote = sanitized(privateNote, fallback: "")
        entries[index].tags = normalizedTags(from: tags)
        entries[index].lastEditedAt = Date()
        save()
    }

    func attach(sessionID: UUID, to entryID: UUID) {
        guard let index = entries.firstIndex(where: { $0.id == entryID }) else { return }

        entries[index].sessionID = sessionID
        entries[index].lastEditedAt = Date()
        save()
    }

    func replaceResult(
        entryID: UUID,
        result: AIReflectionResult,
        engineName: String,
        sessionID: UUID?
    ) {
        guard let index = entries.firstIndex(where: { $0.id == entryID }) else { return }

        entries[index].result = result
        entries[index].engineName = engineName
        if let sessionID {
            entries[index].sessionID = sessionID
        }
        entries[index].lastEditedAt = Date()
        save()
    }

    func entry(with id: UUID) -> JournalReflectionEntry? {
        entries.first { $0.id == id }
    }

    func delete(at offsets: IndexSet, aiSessionStore: AIReflectionSessionStore) {
        let entriesToDelete = offsets.compactMap { index in
            entries.indices.contains(index) ? entries[index] : nil
        }

        entriesToDelete.forEach { entry in
            deleteAISessions(for: entry, aiSessionStore: aiSessionStore)
        }
        remove(at: offsets)
    }

    func delete(_ entry: JournalReflectionEntry, aiSessionStore: AIReflectionSessionStore) {
        deleteAISessions(for: entry, aiSessionStore: aiSessionStore)
        remove(entry)
    }

    func reset() {
        entries = []
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    func seedDemoData(referenceDate: Date = Date()) {
        replaceAll(with: Self.demoEntries(referenceDate: referenceDate))
    }

    func shareText(for entry: JournalReflectionEntry, includePrivateNote: Bool = false) -> String {
        let workspaceMetadata = includePrivateNote ? """

        Private Note
        \(entry.privateNote.isEmpty ? "None" : entry.privateNote)

        Tags
        \(entry.tags.isEmpty ? "None" : entry.tags.joined(separator: ", "))

        Last Edited
        \(entry.lastEditedAt?.formatted(date: .complete, time: .shortened) ?? "Never")
        """ : ""

        return """
        Circleu Reflection

        \(entry.displayTitle)
        \(entry.createdAt.formatted(date: .complete, time: .shortened))
        Emotion: \(entry.displayEmotion)
        Engine: \(entry.engineName)

        Summary
        \(entry.result.summary)

        Insight
        \(entry.result.insight)

        Expression Moment
        \(entry.result.expressionMoment)

        Suggested Quest
        \(entry.result.suggestedQuest)
        \(workspaceMetadata)

        Transcript
        \(entry.transcript)
        """
    }

    func exportText(includePrivateMetadata: Bool = false) -> String {
        guard !entries.isEmpty else {
            return "Circleu Journal\n\nNo saved reflections yet."
        }

        let exportedEntries = entries.map { shareText(for: $0, includePrivateNote: includePrivateMetadata) }
        return "Circleu Journal Export\n\n" + exportedEntries.joined(separator: "\n\n---\n\n")
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let savedEntries = try? decoder.decode([JournalReflectionEntry].self, from: data) else {
            entries = []
            return
        }

        entries = savedEntries
    }

    private func save() {
        guard let data = try? encoder.encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func sanitizedOptional(_ value: String?) -> String? {
        guard let value else { return nil }
        let clean = sanitized(value, fallback: "")
        return clean.isEmpty ? nil : clean
    }

    private func sanitized(_ value: String, fallback: String) -> String {
        let clean = value
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return fallback }
        return String(clean.prefix(280))
    }

    private func normalizedTags(from tags: [String]) -> [String] {
        var seen = Set<String>()

        return tags.compactMap { tag in
            let clean = sanitized(tag, fallback: "")
            guard !clean.isEmpty else { return nil }

            let key = clean.lowercased()
            guard !seen.contains(key) else { return nil }
            seen.insert(key)
            return clean
        }
    }

    private func remove(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            entries.remove(at: index)
        }
        save()
    }

    private func remove(_ entry: JournalReflectionEntry) {
        entries.removeAll { $0.id == entry.id }
        save()
    }

    private func deleteAISessions(for entry: JournalReflectionEntry, aiSessionStore: AIReflectionSessionStore) {
        if let sessionID = entry.sessionID {
            aiSessionStore.delete(sessionID: sessionID)
        }
        aiSessionStore.deleteSessions(forEntryID: entry.id)
    }
}

extension ReflectionJournalStore {
    static func demoEntries(referenceDate: Date = Date()) -> [JournalReflectionEntry] {
        [
            JournalReflectionEntry(
                createdAt: Calendar.current.date(byAdding: .day, value: -2, to: referenceDate) ?? referenceDate,
                durationSeconds: 94,
                transcript: "I felt nervous before speaking in class, but I slowed down and asked my question clearly.",
                engineName: "Local Reflection Engine",
                result: AIReflectionResult(
                    title: "You completed brave clarity",
                    emotion: "Brave",
                    summary: "You noticed nerves and still chose a small public action.",
                    insight: "Slowing down helped you turn pressure into a clear question instead of silence.",
                    expressionMoment: "You named the moment where your voice became steadier.",
                    quote: "A steady voice can start small.",
                    confidenceScore: 0.82,
                    suggestedQuest: "Before your next class, write one question you are willing to ask out loud."
                )
            ),
            JournalReflectionEntry(
                createdAt: Calendar.current.date(byAdding: .day, value: -1, to: referenceDate) ?? referenceDate,
                durationSeconds: 121,
                transcript: "I was tired today, but I still reviewed my notes and noticed I understood more than I expected.",
                engineName: "Local Reflection Engine",
                result: AIReflectionResult(
                    title: "You found progress in a tired day",
                    emotion: "Encouraged",
                    summary: "Even with low energy, you saw evidence that your tips is working.",
                    insight: "Your confidence grew because you measured effort honestly instead of waiting for a perfect mood.",
                    expressionMoment: "You gave yourself credit for continuing when the day felt heavy.",
                    quote: "Progress counts most when it is quiet.",
                    confidenceScore: 0.78,
                    suggestedQuest: "Choose one note from today and explain it in your own words for two minutes."
                )
            ),
            JournalReflectionEntry(
                createdAt: referenceDate,
                durationSeconds: 108,
                transcript: "I want to become more comfortable expressing myself. I think recording helps me hear my thoughts more clearly.",
                engineName: "Local Reflection Engine",
                result: AIReflectionResult(
                    title: "You are building expression tips",
                    emotion: "Hopeful",
                    summary: "You connected voice recording with clearer self-understanding.",
                    insight: "Hearing your thoughts gives you another way to notice patterns and choose the next small step.",
                    expressionMoment: "You described the app as a tips space for becoming more comfortable.",
                    quote: "Expression becomes easier through repetition.",
                    confidenceScore: 0.86,
                    suggestedQuest: "Record a thirty-second check-in tomorrow about one moment you handled well."
                )
            )
        ]
    }
}
