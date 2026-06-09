import Combine
import Foundation
import UIKit

@MainActor
final class JournalViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var didCopyExport = false

    func filteredEntries(from entries: [JournalReflectionEntry]) -> [JournalReflectionEntry] {
        let query = clean(searchText).lowercased()
        guard !query.isEmpty else { return entries }

        return entries.filter { entry in
            [
                entry.displayTitle,
                entry.displayEmotion,
                entry.displaySummary,
                entry.result.insight,
                entry.result.quote,
                entry.privateNote,
                entry.tags.joined(separator: " "),
                entry.transcript,
                entry.engineName
            ]
            .joined(separator: " ")
            .lowercased()
            .contains(query)
        }
    }

    var sectionTitle: String {
        clean(searchText).isEmpty ? "Saved reflections" : "Search results"
    }

    func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    func clearSearch() {
        searchText = ""
    }

    func copyExport(from journalStore: ReflectionJournalStore) {
        UIPasteboard.general.string = journalStore.exportText()
        didCopyExport = true
    }

    func copyReflection(_ entry: JournalReflectionEntry, journalStore: ReflectionJournalStore) {
        UIPasteboard.general.string = journalStore.shareText(for: entry)
    }

    func delete(_ entry: JournalReflectionEntry, journalStore: ReflectionJournalStore, aiSessionStore: AIReflectionSessionStore) {
        journalStore.delete(entry, aiSessionStore: aiSessionStore)
    }

    private func clean(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
