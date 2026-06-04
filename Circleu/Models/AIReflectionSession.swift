import Foundation

enum AIReflectionSource: String, Codable, CaseIterable {
    case recording
    case typedFallback
    case journalRegeneration
    case qaSeed

    var label: String {
        switch self {
        case .recording:
            return "Recording"
        case .typedFallback:
            return "Typed fallback"
        case .journalRegeneration:
            return "Journal regeneration"
        case .qaSeed:
            return "QA seed"
        }
    }
}

enum AIReflectionAttemptStatus: String, Codable {
    case succeeded
    case failed
    case cancelled

    var label: String {
        switch self {
        case .succeeded:
            return "Succeeded"
        case .failed:
            return "Failed"
        case .cancelled:
            return "Cancelled"
        }
    }
}

struct AIReflectionAttempt: Identifiable, Codable, Equatable {
    let id: UUID
    var createdAt: Date
    var engineName: String
    var status: AIReflectionAttemptStatus
    var result: AIReflectionResult?
    var errorMessage: String?
    var elapsedMilliseconds: Int?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        engineName: String,
        status: AIReflectionAttemptStatus,
        result: AIReflectionResult? = nil,
        errorMessage: String? = nil,
        elapsedMilliseconds: Int? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.engineName = engineName
        self.status = status
        self.result = result
        self.errorMessage = errorMessage
        self.elapsedMilliseconds = elapsedMilliseconds
    }
}

struct AIReflectionSession: Identifiable, Codable, Equatable {
    let id: UUID
    var mergedSessionIDs: [UUID]
    var createdAt: Date
    var updatedAt: Date
    var entryID: UUID?
    var engineName: String
    var source: AIReflectionSource
    var transcript: String
    var durationSeconds: Int
    var attempts: [AIReflectionAttempt]
    var selectedAttemptID: UUID?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        entryID: UUID? = nil,
        engineName: String,
        source: AIReflectionSource,
        transcript: String,
        durationSeconds: Int,
        attempts: [AIReflectionAttempt] = [],
        selectedAttemptID: UUID? = nil,
        mergedSessionIDs: [UUID] = []
    ) {
        self.id = id
        self.mergedSessionIDs = mergedSessionIDs
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.entryID = entryID
        self.engineName = engineName
        self.source = source
        self.transcript = transcript
        self.durationSeconds = durationSeconds
        self.attempts = attempts
        self.selectedAttemptID = selectedAttemptID
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case mergedSessionIDs
        case createdAt
        case updatedAt
        case entryID
        case engineName
        case source
        case transcript
        case durationSeconds
        case attempts
        case selectedAttemptID
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        mergedSessionIDs = try container.decodeIfPresent([UUID].self, forKey: .mergedSessionIDs) ?? []
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        entryID = try container.decodeIfPresent(UUID.self, forKey: .entryID)
        engineName = try container.decode(String.self, forKey: .engineName)
        source = try container.decode(AIReflectionSource.self, forKey: .source)
        transcript = try container.decode(String.self, forKey: .transcript)
        durationSeconds = try container.decode(Int.self, forKey: .durationSeconds)
        attempts = try container.decode([AIReflectionAttempt].self, forKey: .attempts)
        selectedAttemptID = try container.decodeIfPresent(UUID.self, forKey: .selectedAttemptID)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(mergedSessionIDs, forKey: .mergedSessionIDs)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(entryID, forKey: .entryID)
        try container.encode(engineName, forKey: .engineName)
        try container.encode(source, forKey: .source)
        try container.encode(transcript, forKey: .transcript)
        try container.encode(durationSeconds, forKey: .durationSeconds)
        try container.encode(attempts, forKey: .attempts)
        try container.encodeIfPresent(selectedAttemptID, forKey: .selectedAttemptID)
    }

    var selectedAttempt: AIReflectionAttempt? {
        if let selectedAttemptID,
           let selected = attempts.first(where: { $0.id == selectedAttemptID }) {
            return selected
        }

        return attempts.last(where: { $0.status == .succeeded }) ?? attempts.last
    }

    var selectedResult: AIReflectionResult? {
        selectedAttempt?.result
    }

    var latestErrorMessage: String? {
        attempts.last(where: { $0.status == .failed })?.errorMessage
    }

    var wordCount: Int {
        transcript.split(whereSeparator: { $0.isWhitespace }).count
    }

    var succeededAttemptCount: Int {
        attempts.filter { $0.status == .succeeded }.count
    }

    var failedAttemptCount: Int {
        attempts.filter { $0.status == .failed }.count
    }

    var exportText: String {
        let mergedIDsLine = mergedSessionIDs.isEmpty ? "" : "\nMerged sessions: \(mergedSessionIDs.map(\.uuidString).joined(separator: ", "))"
        let attemptLines = attempts.map { attempt in
            """
            Attempt: \(attempt.createdAt.formatted(date: .abbreviated, time: .shortened))
            Engine: \(attempt.engineName)
            Status: \(attempt.status.label)
            Elapsed: \(attempt.elapsedMilliseconds.map { "\($0) ms" } ?? "Unknown")
            Result: \(attempt.result?.title ?? "No result")
            Error: \(attempt.errorMessage ?? "None")
            """
        }
        .joined(separator: "\n\n")

        return """
        AI Reflection Session

        Session: \(id.uuidString)\(mergedIDsLine)
        Source: \(source.label)
        Engine: \(engineName)
        Created: \(createdAt.formatted(date: .complete, time: .shortened))
        Transcript words: \(wordCount)
        Duration: \(durationSeconds)s
        Linked entry: \(entryID?.uuidString ?? "Not saved")

        Transcript
        \(transcript)

        Attempts
        \(attemptLines.isEmpty ? "No attempts recorded." : attemptLines)
        """
    }
}
