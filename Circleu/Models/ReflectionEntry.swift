import Foundation

struct AIReflectionResult: Codable, Equatable {
    var title: String
    var emotion: String
    var summary: String
    var insight: String
    var expressionMoment: String
    var quote: String
    var confidenceScore: Double
    var suggestedQuest: String
}

struct JournalReflectionEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var createdAt: Date
    var durationSeconds: Int
    var transcript: String
    var engineName: String
    var result: AIReflectionResult
    var sessionID: UUID?
    var editableTitle: String?
    var editableEmotion: String?
    var privateNote: String
    var tags: [String]
    var lastEditedAt: Date?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        durationSeconds: Int,
        transcript: String,
        engineName: String,
        result: AIReflectionResult,
        sessionID: UUID? = nil,
        editableTitle: String? = nil,
        editableEmotion: String? = nil,
        privateNote: String = "",
        tags: [String] = [],
        lastEditedAt: Date? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.durationSeconds = durationSeconds
        self.transcript = transcript
        self.engineName = engineName
        self.result = result
        self.sessionID = sessionID
        self.editableTitle = editableTitle
        self.editableEmotion = editableEmotion
        self.privateNote = privateNote
        self.tags = tags
        self.lastEditedAt = lastEditedAt
    }

    var displayTitle: String {
        sanitized(editableTitle, fallback: result.title)
    }

    var displayEmotion: String {
        sanitized(editableEmotion, fallback: result.emotion)
    }

    var displayQuest: String {
        result.suggestedQuest
    }

    var displaySummary: String {
        result.summary
    }

    private func sanitized(_ value: String?, fallback: String) -> String {
        guard let value else { return fallback }
        let clean = value
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.isEmpty ? fallback : clean
    }
}

extension JournalReflectionEntry {
    static let preview = JournalReflectionEntry(
        durationSeconds: 103,
        transcript: "I felt nervous before class, but I still asked my question and felt proud afterward.",
        engineName: "Preview",
        result: AIReflectionResult(
            title: "You showed up honestly",
            emotion: "Brave",
            summary: "You noticed nervousness and still took a small public step.",
            insight: "Naming the feeling helped you move through it instead of avoiding it.",
            expressionMoment: "You spoke with honesty about a real moment of growth.",
            quote: "Confidence grows through expression.",
            confidenceScore: 0.76,
            suggestedQuest: "Record one short reflection after your next class."
        )
    )
}
