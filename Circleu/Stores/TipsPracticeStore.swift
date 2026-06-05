import Combine
import Foundation

@MainActor
final class TipsPracticeStore: ObservableObject {
    @Published var draftMessage = ""
    @Published var draftScene: TipsPracticeScene = .workplace
    @Published var draftCustomScene = ""
    @Published var draftTone: TipsPracticeTone = .diplomatic
    @Published var draftSituation = ""
    @Published var currentSession: TipsPracticeSession?
    @Published private(set) var recentSessions: [TipsPracticeSession] = []

    private let storageKey = "circleu.tipsPractice.sessions.v1"
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        load()
    }

    func saveDraft(
        message: String,
        scene: TipsPracticeScene,
        customScene: String,
        tone: TipsPracticeTone,
        situation: String
    ) {
        draftMessage = message
        draftScene = scene
        draftCustomScene = customScene
        draftTone = tone
        draftSituation = situation
    }

    func activate(_ session: TipsPracticeSession) {
        currentSession = session
        upsertRecent(session)
    }

    func updateCurrentSession(_ session: TipsPracticeSession) {
        currentSession = session
        upsertRecent(session)
    }

    func resume(_ session: TipsPracticeSession) {
        var resumedSession = session
        resumedSession.updatedAt = Date()
        currentSession = resumedSession
        upsertRecent(resumedSession)
    }

    func delete(_ session: TipsPracticeSession) {
        recentSessions.removeAll { $0.id == session.id }
        if currentSession?.id == session.id {
            currentSession = nil
        }
        save()
    }

    func clearCurrentSession() {
        currentSession = nil
    }

    func resetDraft() {
        draftMessage = ""
        draftScene = .workplace
        draftCustomScene = ""
        draftTone = .diplomatic
        draftSituation = ""
        currentSession = nil
    }

    func resetAll() {
        resetDraft()
        recentSessions = []
        userDefaults.removeObject(forKey: storageKey)
    }

    private func upsertRecent(_ session: TipsPracticeSession) {
        recentSessions.removeAll { $0.id == session.id }
        recentSessions.insert(session, at: 0)
        recentSessions = Array(recentSessions.prefix(12))
        save()
    }

    private func load() {
        guard let data = userDefaults.data(forKey: storageKey),
              let sessions = try? decoder.decode([TipsPracticeSession].self, from: data) else {
            recentSessions = []
            return
        }

        recentSessions = sessions.sorted { $0.updatedAt > $1.updatedAt }
    }

    private func save() {
        guard let data = try? encoder.encode(recentSessions) else { return }
        userDefaults.set(data, forKey: storageKey)
    }
}
