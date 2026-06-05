import XCTest
@testable import Circleu

@MainActor
final class TipsPracticeFlowTests: XCTestCase {
    private var suiteNames: [String] = []

    override func tearDown() {
        for suiteName in suiteNames {
            UserDefaults.standard.removePersistentDomain(forName: suiteName)
        }
        suiteNames = []
        super.tearDown()
    }

    func testPracticeStorePersistsRecentSessionsAndSupportsResumeAndDelete() throws {
        let defaults = makeDefaults()
        let store = TipsPracticeStore(userDefaults: defaults)
        let firstSession = makeSession(message: "Ask for deadline help", updatedAt: Date(timeIntervalSince1970: 10))
        let secondSession = makeSession(message: "Reply to a friend", updatedAt: Date(timeIntervalSince1970: 20))

        store.activate(firstSession)
        store.activate(secondSession)
        store.resume(firstSession)

        XCTAssertEqual(store.currentSession?.id, firstSession.id)
        XCTAssertEqual(store.recentSessions.map(\.id), [firstSession.id, secondSession.id])

        let reloadedStore = TipsPracticeStore(userDefaults: defaults)
        XCTAssertEqual(reloadedStore.recentSessions.map(\.id), [firstSession.id, secondSession.id])

        reloadedStore.delete(firstSession)
        XCTAssertNil(reloadedStore.currentSession)
        XCTAssertEqual(reloadedStore.recentSessions.map(\.id), [secondSession.id])
    }

    func testPracticeStoreKeepsOnlyTwelveRecentSessions() {
        let store = TipsPracticeStore(userDefaults: makeDefaults())

        for index in 0..<13 {
            store.activate(makeSession(message: "Practice \(index)", updatedAt: Date(timeIntervalSince1970: TimeInterval(index))))
        }

        XCTAssertEqual(store.recentSessions.count, 12)
        XCTAssertEqual(store.recentSessions.first?.originalMessage, "Practice 12")
        XCTAssertFalse(store.recentSessions.contains { $0.originalMessage == "Practice 0" })
    }

    func testPracticeViewModelResumesStoredSession() {
        let store = TipsPracticeStore(userDefaults: makeDefaults())
        let session = makeSession(message: "Negotiate a scope change", updatedAt: Date())
        store.activate(session)
        let viewModel = TipsPracticeViewModel()
        viewModel.bind(store: store)
        viewModel.startNewTip()

        XCTAssertEqual(viewModel.mode, .setup)

        viewModel.resume(session)

        XCTAssertEqual(viewModel.mode, .liveCoach)
        XCTAssertEqual(viewModel.activeSession?.id, session.id)
        XCTAssertEqual(store.currentSession?.id, session.id)
        XCTAssertEqual(viewModel.replyInput, "")
        XCTAssertEqual(viewModel.extraContextInput, "")
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "circleu.tips.tests.\(UUID().uuidString)"
        suiteNames.append(suiteName)
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    private func makeSession(message: String, updatedAt: Date) -> TipsPracticeSession {
        TipsPracticeSession(
            createdAt: updatedAt,
            updatedAt: updatedAt,
            originalMessage: message,
            scene: .workplace,
            tone: .diplomatic,
            situation: "The conversation matters.",
            turns: [
                TipsPracticeTurn(role: .user, label: "You said", text: message)
            ],
            coachOutput: TipsCoachOutput(
                suggestedPhrasing: "Try a clear first sentence.",
                whyItWorks: "It names the need and leaves room for the other person.",
                simulatedReply: "What do you need from me?",
                roomReading: "Reflect their concern first, then ask for the next step.",
                replyOptions: [
                    TipsCoachReplyOption(label: "CLEAR", text: "Here is the one thing I need.")
                ]
            )
        )
    }
}
