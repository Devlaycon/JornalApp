import XCTest
@testable import Circleu

@MainActor
final class BackendPreparationTests: XCTestCase {
    private var suiteNames: [String] = []

    override func tearDown() {
        for suiteName in suiteNames {
            UserDefaults.standard.removePersistentDomain(forName: suiteName)
        }
        suiteNames = []
        super.tearDown()
    }

    func testLocalIdentityProviderCreatesStableLocalUserIDAndDisplayNameFallback() {
        let defaults = makeDefaults()
        let provider = LocalUserIdentityProvider(defaults: defaults)

        let firstID = provider.localUserID
        let secondID = provider.localUserID

        XCTAssertFalse(firstID.isEmpty)
        XCTAssertEqual(firstID, secondID)
        XCTAssertEqual(provider.displayName, "Friend")

        defaults.set("  Tuan Nguyen  ", forKey: "circleu.profile.displayName.v1")

        XCTAssertEqual(provider.displayName, "Tuan Nguyen")
    }

    func testBackendSyncSnapshotReportsCountsAndEmptyState() {
        let entry = makeEntry()
        let quest = Quest(title: "Try this next", detail: entry.result.suggestedQuest, sourceEntryID: entry.id)
        let circle = CircleSpace(name: "Support", intention: "Private notes")
        let post = CirclePost(circleID: circle.id, title: entry.displayTitle, body: entry.displaySummary, sourceEntryID: entry.id)
        let session = AIReflectionSession(
            entryID: entry.id,
            engineName: entry.engineName,
            source: .typedFallback,
            transcript: entry.transcript,
            durationSeconds: entry.durationSeconds
        )

        let snapshot = BackendSyncSnapshot(
            userID: "local-user",
            journalEntries: [entry],
            quests: [quest],
            circles: [circle],
            circlePosts: [post],
            aiSessions: [session]
        )

        XCTAssertFalse(snapshot.isEmpty)
        XCTAssertEqual(snapshot.counts.journalEntryCount, 1)
        XCTAssertEqual(snapshot.counts.questCount, 1)
        XCTAssertEqual(snapshot.counts.circleCount, 1)
        XCTAssertEqual(snapshot.counts.circlePostCount, 1)
        XCTAssertEqual(snapshot.counts.aiSessionCount, 1)

        let emptySnapshot = BackendSyncSnapshot(
            userID: "local-user",
            journalEntries: [],
            quests: [],
            circles: [],
            circlePosts: [],
            aiSessions: []
        )

        XCTAssertTrue(emptySnapshot.isEmpty)
        XCTAssertEqual(emptySnapshot.counts, .zero)
    }

    func testNoOpSyncerReturnsSuccessfulNoChangeResult() async throws {
        let snapshot = BackendSyncSnapshot(
            userID: "local-user",
            journalEntries: [makeEntry()],
            quests: [],
            circles: [],
            circlePosts: [],
            aiSessions: []
        )
        let syncer = NoOpReflectionSyncer()

        let result = try await syncer.sync(snapshot)

        XCTAssertTrue(result.didSucceed)
        XCTAssertEqual(result.uploadedCounts, .zero)
        XCTAssertEqual(result.downloadedCounts, .zero)
        XCTAssertEqual(result.failedScopes, [])
    }

    func testAnalyticsEventSanitizesNameAndProperties() {
        let event = AnalyticsEvent(
            name: "  Reflection Saved  ",
            properties: [
                " source ": " journal detail ",
                "empty": "   ",
                " ": "ignored"
            ],
            createdAt: Date(timeIntervalSince1970: 10)
        )

        XCTAssertEqual(event.name, "reflection_saved")
        XCTAssertEqual(event.properties, ["source": "journal detail"])
        XCTAssertEqual(event.createdAt, Date(timeIntervalSince1970: 10))
    }

    func testLocalModelProviderDeclaresOnDeviceAvailability() {
        let provider = LocalReflectionModelProvider()

        XCTAssertEqual(provider.providerName, "Local")
        XCTAssertTrue(provider.isAvailable)
        XCTAssertNil(provider.availabilityReason)
        XCTAssertTrue(provider.supportsOnDeviceProcessing)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "circleu.backend.tests.\(UUID().uuidString)"
        suiteNames.append(suiteName)
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    private func makeEntry() -> JournalReflectionEntry {
        JournalReflectionEntry(
            durationSeconds: 60,
            transcript: "I practiced explaining my thought clearly before the team meeting.",
            engineName: "Local test engine",
            result: AIReflectionResult(
                title: "Clearer voice",
                emotion: "Focused",
                summary: "You found a simpler way to say what mattered.",
                insight: "Clearer preparation made the conversation easier to enter.",
                expressionMoment: "You named the sentence before the moment arrived.",
                quote: "A clear sentence can steady the next step.",
                confidenceScore: 0.8,
                suggestedQuest: "Write one opening sentence before tomorrow's check-in."
            )
        )
    }
}
