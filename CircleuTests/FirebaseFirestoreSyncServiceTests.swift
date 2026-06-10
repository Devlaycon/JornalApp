import XCTest
@testable import Circleu

@MainActor
final class FirebaseFirestoreSyncServiceTests: XCTestCase {
    func testPrivateBackupMapperCreatesUserScopedDocumentsForSupportedPrivateData() {
        let ids = TestIDs()
        let snapshot = makeSnapshot(ids: ids)

        let documents = FirebaseSyncMapper.privateBackupDocuments(for: snapshot)

        XCTAssertEqual(
            documents.map(\.path),
            [
                "users/firebase-user-1/journalEntries/\(ids.entryID.uuidString)",
                "users/firebase-user-1/quests/\(ids.questID.uuidString)",
                "users/firebase-user-1/aiReflectionSessions/\(ids.sessionID.uuidString)"
            ]
        )
        XCTAssertEqual(documents.map(\.scope), [.journalEntries, .quests, .aiSessions])
    }

    func testJournalPayloadMatchesFirebaseSchemaFields() {
        let ids = TestIDs()
        let journal = FirebaseSyncMapper.privateBackupDocuments(for: makeSnapshot(ids: ids))[0]

        XCTAssertEqual(journal.data["entryID"], .string(ids.entryID.uuidString))
        XCTAssertEqual(journal.data["durationSeconds"], .int(120))
        XCTAssertEqual(journal.data["transcript"], .string("I asked for feedback after the group meeting."))
        XCTAssertEqual(journal.data["engineName"], .string("Local test engine"))
        XCTAssertEqual(journal.data["sessionID"], .string(ids.sessionID.uuidString))
        XCTAssertEqual(journal.data["editableTitle"], .string("Team clarity"))
        XCTAssertEqual(journal.data["editableEmotion"], .string("Focused"))
        XCTAssertEqual(journal.data["privateNote"], .string("Remember to thank Mina."))
        XCTAssertEqual(journal.data["tags"], .stringArray(["team", "feedback"]))

        guard case .dictionary(let result)? = journal.data["result"] else {
            XCTFail("Expected result dictionary")
            return
        }

        XCTAssertEqual(result["title"], .string("Clearer voice"))
        XCTAssertEqual(result["confidenceScore"], .double(0.82))
    }

    func testPrivateBackupMapperDoesNotUploadSharedCircleDataBeforeRulesExist() {
        let ids = TestIDs()
        let documents = FirebaseSyncMapper.privateBackupDocuments(for: makeSnapshot(ids: ids))

        XCTAssertFalse(documents.contains { $0.path.hasPrefix("circles/") })
        XCTAssertFalse(documents.contains { $0.scope == .circles || $0.scope == .circlePosts })
    }

    func testUploadOnlySyncerWritesDocumentsWithMergeAndReportsUploadedPrivateCounts() async throws {
        let ids = TestIDs()
        let client = FakeFirestoreClient()
        let syncer = FirebaseUploadOnlySyncer(client: client)

        let result = try await syncer.sync(makeSnapshot(ids: ids))

        XCTAssertTrue(result.didSucceed)
        XCTAssertEqual(result.uploadedCounts.journalEntryCount, 1)
        XCTAssertEqual(result.uploadedCounts.questCount, 1)
        XCTAssertEqual(result.uploadedCounts.aiSessionCount, 1)
        XCTAssertEqual(result.uploadedCounts.circleCount, 0)
        XCTAssertEqual(result.uploadedCounts.circlePostCount, 0)
        XCTAssertEqual(result.downloadedCounts, .zero)
        XCTAssertEqual(client.writes.map(\.merge), [true, true, true])
        XCTAssertEqual(client.writes.map(\.path).count, 3)
    }

    func testUploadOnlySyncerReportsFailedScopesWithoutThrowingAwaySuccessfulWrites() async throws {
        let ids = TestIDs()
        let client = FakeFirestoreClient(failingPaths: [
            "users/firebase-user-1/quests/\(ids.questID.uuidString)"
        ])
        let syncer = FirebaseUploadOnlySyncer(client: client)

        let result = try await syncer.sync(makeSnapshot(ids: ids))

        XCTAssertFalse(result.didSucceed)
        XCTAssertEqual(result.failedScopes, [.quests])
        XCTAssertEqual(result.uploadedCounts.journalEntryCount, 1)
        XCTAssertEqual(result.uploadedCounts.questCount, 0)
        XCTAssertEqual(result.uploadedCounts.aiSessionCount, 1)
    }
}

private struct TestIDs {
    let entryID = UUID(uuidString: "00000000-0000-0000-0000-000000000101")!
    let questID = UUID(uuidString: "00000000-0000-0000-0000-000000000102")!
    let circleID = UUID(uuidString: "00000000-0000-0000-0000-000000000103")!
    let postID = UUID(uuidString: "00000000-0000-0000-0000-000000000104")!
    let sessionID = UUID(uuidString: "00000000-0000-0000-0000-000000000105")!
    let attemptID = UUID(uuidString: "00000000-0000-0000-0000-000000000106")!
}

private struct FakeFirestoreWrite {
    var path: String
    var data: [String: Any]
    var merge: Bool
}

private final class FakeFirestoreClient: FirebaseFirestoreClient {
    var writes: [FakeFirestoreWrite] = []
    private let failingPaths: Set<String>

    init(failingPaths: Set<String> = []) {
        self.failingPaths = failingPaths
    }

    func setData(_ data: [String: Any], at documentPath: String, merge: Bool) async throws {
        if failingPaths.contains(documentPath) {
            throw FakeFirestoreError.writeFailed
        }

        writes.append(FakeFirestoreWrite(path: documentPath, data: data, merge: merge))
    }
}

private enum FakeFirestoreError: Error {
    case writeFailed
}

private func makeSnapshot(ids: TestIDs) -> BackendSyncSnapshot {
    let createdAt = Date(timeIntervalSince1970: 100)
    let updatedAt = Date(timeIntervalSince1970: 200)
    let entry = JournalReflectionEntry(
        id: ids.entryID,
        createdAt: createdAt,
        durationSeconds: 120,
        transcript: "I asked for feedback after the group meeting.",
        engineName: "Local test engine",
        result: AIReflectionResult(
            title: "Clearer voice",
            emotion: "Focused",
            summary: "You made the conversation easier to enter.",
            insight: "Asking directly helped you get useful feedback.",
            expressionMoment: "You named the ask clearly.",
            quote: "A direct question can be kind.",
            confidenceScore: 0.82,
            suggestedQuest: "Ask one clarifying question tomorrow."
        ),
        sessionID: ids.sessionID,
        editableTitle: "Team clarity",
        editableEmotion: "Focused",
        privateNote: "Remember to thank Mina.",
        tags: ["team", "feedback"],
        lastEditedAt: updatedAt
    )
    let quest = Quest(
        id: ids.questID,
        title: "Ask one question",
        detail: "Ask one clarifying question tomorrow.",
        sourceEntryID: ids.entryID,
        createdAt: createdAt,
        status: .active
    )
    let circle = CircleSpace(id: ids.circleID, name: "Support", intention: "Private practice", createdAt: createdAt)
    let post = CirclePost(
        id: ids.postID,
        circleID: ids.circleID,
        text: "I practiced asking for feedback.",
        createdAt: createdAt,
        sourceEntryID: ids.entryID
    )
    let session = AIReflectionSession(
        id: ids.sessionID,
        createdAt: createdAt,
        updatedAt: updatedAt,
        entryID: ids.entryID,
        engineName: "Local test engine",
        source: .typedFallback,
        transcript: entry.transcript,
        durationSeconds: 120,
        attempts: [
            AIReflectionAttempt(
                id: ids.attemptID,
                createdAt: createdAt,
                engineName: "Local test engine",
                status: .succeeded,
                result: entry.result,
                elapsedMilliseconds: 40
            )
        ],
        selectedAttemptID: ids.attemptID
    )

    return BackendSyncSnapshot(
        userID: "firebase-user-1",
        generatedAt: updatedAt,
        journalEntries: [entry],
        quests: [quest],
        circles: [circle],
        circlePosts: [post],
        aiSessions: [session]
    )
}
