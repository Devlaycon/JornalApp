import Combine
import Foundation

@MainActor
final class AIReflectionSessionStore: ObservableObject {
    private typealias EnumeratedAttempt = (offset: Int, element: AIReflectionAttempt)

    @Published private(set) var sessions: [AIReflectionSession] = []

    private let storageKey = "circleu.aiReflectionSessions.v1"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        load()
    }

    func add(_ session: AIReflectionSession) {
        let normalizedSession = normalize(session)
        guard !sessions.contains(where: { $0.id == normalizedSession.id }) else { return }
        sessions.insert(normalizedSession, at: 0)
        sortSessions()
        save()
    }

    func upsert(_ session: AIReflectionSession) {
        let normalizedSession = normalize(session)
        if let index = sessions.firstIndex(where: { $0.id == normalizedSession.id }) {
            sessions[index] = normalizedSession
        } else {
            sessions.insert(normalizedSession, at: 0)
        }
        sortSessions()
        save()
    }

    func append(_ attempt: AIReflectionAttempt, to sessionID: UUID) {
        guard let index = sessions.firstIndex(where: { $0.id == sessionID }) else { return }
        guard !sessions[index].attempts.contains(where: { $0.id == attempt.id }) else { return }

        sessions[index].attempts.append(attempt)
        sessions[index].updatedAt = Date()
        if attempt.status == .succeeded {
            sessions[index].selectedAttemptID = attempt.id
            sessions[index].engineName = attempt.engineName
        }
        sortSessions()
        save()
    }

    func link(sessionID: UUID, to entryID: UUID) {
        guard let index = sessions.firstIndex(where: { $0.id == sessionID }) else { return }
        sessions[index].entryID = entryID
        sessions[index].updatedAt = Date()
        sortSessions()
        save()
    }

    func selectAttempt(_ attemptID: UUID, in sessionID: UUID) {
        guard let index = sessions.firstIndex(where: { $0.id == sessionID }),
              let attempt = sessions[index].attempts.first(where: { $0.id == attemptID && $0.status == .succeeded }) else {
            return
        }

        sessions[index].selectedAttemptID = attemptID
        sessions[index].engineName = attempt.engineName
        sessions[index].updatedAt = Date()
        sortSessions()
        save()
    }

    func session(with id: UUID?) -> AIReflectionSession? {
        guard let id else { return nil }
        return sessions.first { $0.id == id }
    }

    func session(for entry: JournalReflectionEntry) -> AIReflectionSession? {
        if let linked = session(with: entry.sessionID) {
            return linked
        }
        return sessions.first { $0.entryID == entry.id }
    }

    func replaceAll(with newSessions: [AIReflectionSession]) {
        sessions = normalizedUniqueSortedSessions(from: newSessions)
        save()
    }

    func reset() {
        sessions = []
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    func exportText() -> String {
        guard !sessions.isEmpty else {
            return "Circleu AI Sessions\n\nNo AI sessions recorded yet."
        }

        return "Circleu AI Sessions\n\n" + sessions.map(\.exportText).joined(separator: "\n\n---\n\n")
    }

    func seedDemoData(entries: [JournalReflectionEntry]) {
        let demoSessions = entries.map { entry in
            let attempt = AIReflectionAttempt(
                createdAt: entry.createdAt,
                engineName: entry.engineName,
                status: .succeeded,
                result: entry.result,
                elapsedMilliseconds: 420
            )

            return AIReflectionSession(
                id: entry.sessionID ?? UUID(),
                createdAt: entry.createdAt,
                updatedAt: entry.createdAt,
                entryID: entry.id,
                engineName: entry.engineName,
                source: .qaSeed,
                transcript: entry.transcript,
                durationSeconds: entry.durationSeconds,
                attempts: [attempt],
                selectedAttemptID: attempt.id
            )
        }

        replaceAll(with: demoSessions)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let savedSessions = try? decoder.decode([AIReflectionSession].self, from: data) else {
            sessions = []
            return
        }

        let normalizedSessions = normalizedUniqueSortedSessions(from: savedSessions)
        sessions = normalizedSessions

        if normalizedSessions != savedSessions {
            save()
        }
    }

    private func normalize(_ session: AIReflectionSession) -> AIReflectionSession {
        var normalizedSession = session
        normalizedSession.attempts = deduplicatedAttempts(from: normalizedSession)

        let selectedAttempt: AIReflectionAttempt?
        if let selectedAttemptID = normalizedSession.selectedAttemptID,
           let currentSelection = normalizedSession.attempts.first(where: { $0.id == selectedAttemptID && $0.status == .succeeded }) {
            selectedAttempt = currentSelection
        } else {
            selectedAttempt = normalizedSession.attempts.last(where: { $0.status == .succeeded })
            normalizedSession.selectedAttemptID = selectedAttempt?.id
        }

        if let selectedAttempt {
            normalizedSession.engineName = selectedAttempt.engineName
        } else {
            normalizedSession.selectedAttemptID = nil
        }

        return normalizedSession
    }

    private func deduplicatedAttempts(from session: AIReflectionSession) -> [AIReflectionAttempt] {
        let enumeratedAttempts = session.attempts.enumerated().map { item in
            (offset: item.offset, element: item.element)
        }
        let groupedAttempts = Dictionary(grouping: enumeratedAttempts) { item in
            item.element.id
        }

        return groupedAttempts.values
            .compactMap { attempts in
                preferredAttempt(from: attempts, selectedAttemptID: session.selectedAttemptID)
            }
            .sorted(by: areAttemptsInChronologicalOrder)
    }

    private func preferredAttempt(
        from attempts: [EnumeratedAttempt],
        selectedAttemptID: UUID?
    ) -> AIReflectionAttempt? {
        if let selectedAttemptID,
           attempts.contains(where: { $0.element.id == selectedAttemptID }),
           let selectedSucceeded = latestAttempt(from: attempts.filter {
               $0.element.id == selectedAttemptID && $0.element.status == .succeeded
           }) {
            return selectedSucceeded
        }

        if let latestSucceeded = latestAttempt(from: attempts.filter {
            $0.element.status == .succeeded
        }) {
            return latestSucceeded
        }

        if let latestWithResult = latestAttempt(from: attempts.filter {
            $0.element.result != nil
        }) {
            return latestWithResult
        }

        return latestAttempt(from: attempts)
    }

    private func latestAttempt(from attempts: [EnumeratedAttempt]) -> AIReflectionAttempt? {
        attempts.sorted {
            if $0.element.createdAt == $1.element.createdAt {
                return $0.offset < $1.offset
            }
            return $0.element.createdAt > $1.element.createdAt
        }
        .first?
        .element
    }

    private func areAttemptsInChronologicalOrder(_ lhs: AIReflectionAttempt, _ rhs: AIReflectionAttempt) -> Bool {
        if lhs.createdAt != rhs.createdAt {
            return lhs.createdAt < rhs.createdAt
        }
        return lhs.id.uuidString < rhs.id.uuidString
    }

    private func normalizedUniqueSortedSessions(from source: [AIReflectionSession]) -> [AIReflectionSession] {
        let sortedSessions = orderedSessions(source.map(normalize))

        var seenSessionIDs = Set<UUID>()
        return sortedSessions.compactMap { session in
            guard seenSessionIDs.insert(session.id).inserted else { return nil }
            return session
        }
    }

    private func sortSessions() {
        sessions = orderedSessions(sessions)
    }

    private func orderedSessions(_ source: [AIReflectionSession]) -> [AIReflectionSession] {
        source.enumerated()
            .sorted {
                if areSessionsInStoreOrder($0.element, $1.element) {
                    return true
                }
                if areSessionsInStoreOrder($1.element, $0.element) {
                    return false
                }
                return $0.offset < $1.offset
            }
            .map(\.element)
    }

    private func areSessionsInStoreOrder(_ lhs: AIReflectionSession, _ rhs: AIReflectionSession) -> Bool {
        if lhs.updatedAt != rhs.updatedAt {
            return lhs.updatedAt > rhs.updatedAt
        }
        if lhs.createdAt != rhs.createdAt {
            return lhs.createdAt > rhs.createdAt
        }
        return lhs.id.uuidString < rhs.id.uuidString
    }

    private func save() {
        guard let data = try? encoder.encode(sessions) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
