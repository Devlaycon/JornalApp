import XCTest
@testable import Circleu

@MainActor
final class LocalDataFlowTests: XCTestCase {
    private var suiteNames: [String] = []

    override func setUp() {
        super.setUp()
        AIReflectionSessionStore().reset()
    }

    override func tearDown() {
        AIReflectionSessionStore().reset()
        for suiteName in suiteNames {
            UserDefaults.standard.removePersistentDomain(forName: suiteName)
        }
        suiteNames = []
        super.tearDown()
    }

    func testJournalStorePersistsWorkspaceUpdatesInIsolatedDefaults() throws {
        let defaults = makeDefaults()
        let entry = makeEntry(
            title: "Generated title",
            emotion: "Curious",
            summary: "A useful summary",
            suggestedQuest: "Ask one clear question tomorrow."
        )
        let store = ReflectionJournalStore(userDefaults: defaults)

        store.add(entry)
        store.add(entry)
        store.updateWorkspace(
            entry: entry,
            title: "  Team   presentation  ",
            emotion: "  Calm  ",
            privateNote: "  remember\nthis for demo day  ",
            tags: ["voice", " Voice ", "team", " "]
        )

        let reloadedStore = ReflectionJournalStore(userDefaults: defaults)
        let savedEntry = try XCTUnwrap(reloadedStore.entry(with: entry.id))
        XCTAssertEqual(reloadedStore.entries.count, 1)
        XCTAssertEqual(savedEntry.displayTitle, "Team presentation")
        XCTAssertEqual(savedEntry.displayEmotion, "Calm")
        XCTAssertEqual(savedEntry.privateNote, "remember this for demo day")
        XCTAssertEqual(savedEntry.tags, ["voice", "team"])
        XCTAssertNotNil(savedEntry.lastEditedAt)
    }

    func testQuestStoreKeepsOneSourceQuestAndPersistsStatusChanges() throws {
        let defaults = makeDefaults()
        let entry = makeEntry(
            title: "Reflection",
            emotion: "Focused",
            summary: "Summary",
            suggestedQuest: "  Practice your first sentence out loud.  "
        )
        let store = QuestStore(userDefaults: defaults)

        let firstQuest = try XCTUnwrap(store.activateSuggestedQuest(from: entry))
        let updatedQuest = try XCTUnwrap(store.activateSuggestedQuest(from: entry))

        XCTAssertEqual(store.quests.count, 1)
        XCTAssertEqual(firstQuest.id, updatedQuest.id)
        XCTAssertEqual(updatedQuest.detail, "Practice your first sentence out loud.")

        store.complete(updatedQuest)
        let completedQuest = try XCTUnwrap(store.quests.first)
        XCTAssertEqual(completedQuest.status, .completed)
        XCTAssertNotNil(completedQuest.completedAt)

        store.reactivate(completedQuest)
        let reloadedStore = QuestStore(userDefaults: defaults)
        let reloadedQuest = try XCTUnwrap(reloadedStore.quests.first)
        XCTAssertEqual(reloadedQuest.status, .active)
        XCTAssertNil(reloadedQuest.completedAt)
    }

    func testCircleStoreSharesReflectionPrivatelyOncePerCircle() throws {
        let defaults = makeDefaults()
        let entry = makeEntry(
            title: "Honest progress",
            emotion: "Brave",
            summary: "You spoke clearly in a hard moment.",
            suggestedQuest: "Try one direct sentence tomorrow.",
            transcript: "This transcript should stay private.",
            privateNote: "This private note should stay private."
        )
        let store = CircleStore(userDefaults: defaults, seedStarterSpaces: false)

        store.createCircle(name: "  Practice   partners  ", intention: "  Share safe wins  ")
        let circle = try XCTUnwrap(store.circles.first)
        store.share(entry: entry, to: circle)
        store.share(entry: entry, to: circle)

        let posts = store.posts(for: circle)
        XCTAssertEqual(posts.count, 1)
        XCTAssertTrue(store.hasShared(entry: entry, to: circle))
        XCTAssertEqual(posts[0].title, "Honest progress")
        XCTAssertTrue(posts[0].body.contains("You spoke clearly in a hard moment."))
        XCTAssertFalse(posts[0].body.contains(entry.transcript))
        XCTAssertFalse(posts[0].body.contains(entry.privateNote))

        let reloadedStore = CircleStore(userDefaults: defaults, seedStarterSpaces: false)
        let reloadedCircle = try XCTUnwrap(reloadedStore.circles.first)
        XCTAssertEqual(reloadedCircle.name, "Practice partners")
        XCTAssertEqual(reloadedCircle.intention, "Share safe wins")
        XCTAssertEqual(reloadedStore.posts(for: reloadedCircle).count, 1)
    }

    func testProgressEngineSummarizesReflectionQuestProgress() {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let entries = [
            makeEntry(title: "Today", emotion: "Brave", summary: "Today summary", suggestedQuest: "Quest", createdAt: today),
            makeEntry(title: "Yesterday", emotion: "Brave", summary: "Yesterday summary", suggestedQuest: "Quest", createdAt: yesterday)
        ]
        let quests = [
            Quest(title: "One", detail: "Done", status: .completed),
            Quest(title: "Two", detail: "Done", status: .completed),
            Quest(title: "Three", detail: "Active", status: .active)
        ]

        let snapshot = ProgressEngine.snapshot(entries: entries, quests: quests)

        XCTAssertEqual(snapshot.entryCount, 2)
        XCTAssertEqual(snapshot.streak, 2)
        XCTAssertEqual(snapshot.completedQuestCount, 2)
        XCTAssertEqual(snapshot.xp, 120)
        XCTAssertEqual(snapshot.level, 2)
        XCTAssertEqual(snapshot.xpForNextLevel, 200)
        XCTAssertEqual(snapshot.mostCommonEmotion, "Brave")
        XCTAssertEqual(snapshot.badges.first { $0.id == "first-reflection" }?.isUnlocked, true)
        XCTAssertEqual(snapshot.badges.first { $0.id == "three-reflections" }?.isUnlocked, false)
    }

    func testSavedReflectionCanDriveJournalAndSuggestedQuestFlow() throws {
        let journalDefaults = makeDefaults()
        let questDefaults = makeDefaults()
        let entry = makeEntry(
            title: "Clearer check-in",
            emotion: "Focused",
            summary: "You noticed what helped the conversation go better.",
            suggestedQuest: "Write one direct sentence before tomorrow's conversation.",
            transcript: "I explained what I needed and noticed the conversation became easier."
        )
        let journalStore = ReflectionJournalStore(userDefaults: journalDefaults)
        let questStore = QuestStore(userDefaults: questDefaults)

        journalStore.add(entry)
        let savedEntry = try XCTUnwrap(journalStore.entry(with: entry.id))
        let quest = try XCTUnwrap(questStore.activateSuggestedQuest(from: savedEntry))

        XCTAssertEqual(journalStore.entries.count, 1)
        XCTAssertEqual(savedEntry.displayTitle, "Clearer check-in")
        XCTAssertEqual(savedEntry.transcript, entry.transcript)
        XCTAssertEqual(quest.title, "Try this next")
        XCTAssertEqual(quest.detail, "Write one direct sentence before tomorrow's conversation.")
        XCTAssertEqual(quest.sourceEntryID, entry.id)
        XCTAssertEqual(questStore.latestActiveQuest?.id, quest.id)

        let reloadedJournalStore = ReflectionJournalStore(userDefaults: journalDefaults)
        let reloadedQuestStore = QuestStore(userDefaults: questDefaults)

        XCTAssertEqual(reloadedJournalStore.entry(with: entry.id)?.displayQuest, entry.displayQuest)
        XCTAssertEqual(reloadedQuestStore.quest(for: entry)?.detail, quest.detail)
    }

    func testAISessionLinksToSavedJournalEntryAndDeletesWithEntry() throws {
        let defaults = makeDefaults()
        let sessionStore = AIReflectionSessionStore()
        let journalStore = ReflectionJournalStore(userDefaults: defaults)
        let entry = makeEntry(
            title: "Session-backed reflection",
            emotion: "Brave",
            summary: "You kept going while nervous.",
            suggestedQuest: "Practice one opening sentence."
        )
        let attempt = AIReflectionAttempt(
            engineName: "Local test engine",
            status: .succeeded,
            result: entry.result,
            elapsedMilliseconds: 120
        )
        let session = AIReflectionSession(
            engineName: "Draft engine",
            source: .recording,
            transcript: entry.transcript,
            durationSeconds: entry.durationSeconds
        )

        journalStore.add(entry)
        sessionStore.add(session)
        sessionStore.append(attempt, to: session.id)
        sessionStore.link(sessionID: session.id, to: entry.id)
        journalStore.attach(sessionID: session.id, to: entry.id)

        let linkedEntry = try XCTUnwrap(journalStore.entry(with: entry.id))
        let linkedSession = try XCTUnwrap(sessionStore.session(for: linkedEntry))
        XCTAssertEqual(linkedEntry.sessionID, session.id)
        XCTAssertEqual(linkedSession.entryID, entry.id)
        XCTAssertEqual(linkedSession.selectedResult, entry.result)
        XCTAssertEqual(linkedSession.engineName, "Local test engine")

        journalStore.delete(linkedEntry, aiSessionStore: sessionStore)

        XCTAssertNil(journalStore.entry(with: entry.id))
        XCTAssertNil(sessionStore.session(with: session.id))
    }

    func testStoreResetAndExportBehaviorUsesClearEmptyStates() throws {
        let journalDefaults = makeDefaults()
        let questDefaults = makeDefaults()
        let circleDefaults = makeDefaults()
        let journalStore = ReflectionJournalStore(userDefaults: journalDefaults)
        let questStore = QuestStore(userDefaults: questDefaults)
        let circleStore = CircleStore(userDefaults: circleDefaults, seedStarterSpaces: false)
        let sessionStore = AIReflectionSessionStore()
        let entry = makeEntry(
            title: "Exportable reflection",
            emotion: "Calm",
            summary: "You made the next step smaller.",
            suggestedQuest: "Choose one simple action."
        )

        journalStore.add(entry)
        _ = questStore.activateSuggestedQuest(from: entry)
        circleStore.createCircle(name: "Support", intention: "Private notes")
        let circle = try XCTUnwrap(circleStore.circles.first)
        circleStore.share(entry: entry, to: circle)
        sessionStore.add(
            AIReflectionSession(
                entryID: entry.id,
                engineName: entry.engineName,
                source: .typedFallback,
                transcript: entry.transcript,
                durationSeconds: entry.durationSeconds
            )
        )

        XCTAssertTrue(journalStore.exportText().contains("Circleu Journal Export"))
        XCTAssertTrue(sessionStore.exportText().contains("Circleu AI Sessions"))

        journalStore.reset()
        questStore.reset()
        circleStore.reset(seedStarterSpaces: false)
        sessionStore.reset()

        XCTAssertEqual(journalStore.entries, [])
        XCTAssertEqual(questStore.quests, [])
        XCTAssertEqual(circleStore.circles, [])
        XCTAssertEqual(circleStore.posts, [])
        XCTAssertEqual(sessionStore.sessions, [])
        XCTAssertEqual(journalStore.exportText(), "Circleu Journal\n\nNo saved reflections yet.")
        XCTAssertEqual(sessionStore.exportText(), "Circleu AI Sessions\n\nNo AI sessions recorded yet.")
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "circleu.tests.\(UUID().uuidString)"
        suiteNames.append(suiteName)
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    private func makeEntry(
        title: String,
        emotion: String,
        summary: String,
        suggestedQuest: String,
        transcript: String = "I practiced saying what I meant.",
        privateNote: String = "",
        createdAt: Date = Date()
    ) -> JournalReflectionEntry {
        JournalReflectionEntry(
            createdAt: createdAt,
            durationSeconds: 60,
            transcript: transcript,
            engineName: "Test Engine",
            result: AIReflectionResult(
                title: title,
                emotion: emotion,
                summary: summary,
                insight: "Small practice builds confidence.",
                expressionMoment: "The user named what they needed.",
                quote: "Clear can still be kind.",
                confidenceScore: 0.8,
                suggestedQuest: suggestedQuest
            ),
            privateNote: privateNote
        )
    }
}
