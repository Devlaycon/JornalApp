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
        upsert(session)
    }

    func upsert(_ session: AIReflectionSession) {
        let normalizedSession = normalize(session)
        sessions.append(normalizedSession)
        sessions = normalizedUniqueSortedSessions(from: sessions)
        save()
    }

    func append(_ attempt: AIReflectionAttempt, to sessionID: UUID) {
        guard let index = canonicalSessionIndex(for: sessionID) else { return }

        sessions[index].attempts.append(attempt)
        sessions[index].updatedAt = Date()
        if attempt.status == .succeeded {
            sessions[index].selectedAttemptID = attempt.id
            sessions[index].engineName = attempt.engineName
        }
        sessions[index] = normalize(sessions[index])
        sessions = normalizedUniqueSortedSessions(from: sessions)
        save()
    }

    func link(sessionID: UUID, to entryID: UUID) {
        guard let index = canonicalSessionIndex(for: sessionID) else { return }
        sessions[index].entryID = entryID
        sessions[index].updatedAt = Date()
        sessions = normalizedUniqueSortedSessions(from: sessions)
        save()
    }

    func selectAttempt(_ attemptID: UUID, in sessionID: UUID) {
        guard let index = canonicalSessionIndex(for: sessionID),
              let attempt = sessions[index].attempts.first(where: { $0.id == attemptID && $0.status == .succeeded }) else {
            return
        }

        sessions[index].selectedAttemptID = attemptID
        sessions[index].engineName = attempt.engineName
        sessions[index].updatedAt = Date()
        sessions[index] = normalize(sessions[index])
        sessions = normalizedUniqueSortedSessions(from: sessions)
        save()
    }

    func session(with id: UUID?) -> AIReflectionSession? {
        guard let id else { return nil }
        guard let index = canonicalSessionIndex(for: id) else { return nil }
        return sessions[index]
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
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            sessions = []
            return
        }

        guard let savedSessions = try? decoder.decode([AIReflectionSession].self, from: data) else {
            sessions = []
            UserDefaults.standard.removeObject(forKey: storageKey)
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
        normalizedSession.mergedSessionIDs = normalizedAliasIDs(
            from: normalizedSession.mergedSessionIDs,
            excluding: normalizedSession.id
        )
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
                return $0.offset > $1.offset
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
        let sortedSessions = orderedSessions(source)
        var unvisitedIndices = Set(sortedSessions.indices)
        var components: [[AIReflectionSession]] = []

        while let seedIndex = unvisitedIndices.first {
            var component: [AIReflectionSession] = []
            var pendingIndices = [seedIndex]
            unvisitedIndices.remove(seedIndex)

            while let currentIndex = pendingIndices.popLast() {
                let current = sortedSessions[currentIndex]
                component.append(current)

                let connectedIndices = unvisitedIndices.filter { candidateIndex in
                    areSessionsConnected(current, sortedSessions[candidateIndex])
                }
                for candidateIndex in connectedIndices {
                    unvisitedIndices.remove(candidateIndex)
                    pendingIndices.append(candidateIndex)
                }
            }

            components.append(component)
        }

        return orderedSessions(components.map(mergeComponent))
    }

    private func mergeComponent(_ component: [AIReflectionSession]) -> AIReflectionSession {
        let sortedSessions = orderedSessions(component)
        guard let newestSession = sortedSessions.first else {
            preconditionFailure("Cannot merge an empty AI session component.")
        }

        return sortedSessions.dropFirst().reduce(normalize(newestSession)) { mergedSession, session in
            merge(mergedSession, with: session)
        }
    }

    private func merge(_ newestSession: AIReflectionSession, with olderSession: AIReflectionSession) -> AIReflectionSession {
        var mergedSession = newestSession
        mergedSession.attempts.append(contentsOf: olderSession.attempts)
        mergedSession.mergedSessionIDs = normalizedAliasIDs(
            from: mergedSession.mergedSessionIDs + olderSession.mergedSessionIDs + [olderSession.id],
            excluding: mergedSession.id
        )

        if mergedSession.entryID == nil {
            mergedSession.entryID = olderSession.entryID
        }

        if olderSession.transcript.count > mergedSession.transcript.count {
            mergedSession.transcript = olderSession.transcript
            mergedSession.durationSeconds = olderSession.durationSeconds
            mergedSession.source = olderSession.source
        }

        return normalize(mergedSession)
    }

    private func areSessionsConnected(_ lhs: AIReflectionSession, _ rhs: AIReflectionSession) -> Bool {
        if sessionIdentityIDs(for: lhs).isDisjoint(with: sessionIdentityIDs(for: rhs)) == false {
            return true
        }
        guard let leftEntryID = lhs.entryID,
              let rightEntryID = rhs.entryID else {
            return false
        }
        return leftEntryID == rightEntryID
    }

    private func canonicalSessionIndex(for id: UUID) -> [AIReflectionSession].Index? {
        sessions.firstIndex { session in
            session.id == id || session.mergedSessionIDs.contains(id)
        }
    }

    private func sessionIdentityIDs(for session: AIReflectionSession) -> Set<UUID> {
        Set([session.id] + session.mergedSessionIDs)
    }

    private func normalizedAliasIDs(from ids: [UUID], excluding excludedID: UUID) -> [UUID] {
        Set(ids)
            .filter { $0 != excludedID }
            .sorted { $0.uuidString < $1.uuidString }
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
