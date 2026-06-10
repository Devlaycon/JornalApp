import XCTest
@testable import Circleu

final class FirebaseSchemaTests: XCTestCase {
    func testFirebaseSchemaListsExpectedCollectionsInBuildOrder() {
        XCTAssertEqual(
            FirebaseDataModel.collections.map(\.name),
            [
                "users",
                "profile",
                "journalEntries",
                "aiReflectionSessions",
                "quests",
                "tipsPracticeSessions",
                "rewardState",
                "pointEntries",
                "activityEvents",
                "circles",
                "circleMembers",
                "circlePosts",
                "circlePostReplies"
            ]
        )
    }

    func testPrivateUserCollectionsUseUserScopedPaths() {
        let privateCollections = FirebaseDataModel.collections.filter { $0.scope == .privateUser }

        XCTAssertFalse(privateCollections.isEmpty)
        XCTAssertTrue(privateCollections.allSatisfy { $0.pathTemplate.hasPrefix("users/{uid}") })
    }

    func testJournalSchemaMarksPrivateReflectionFieldsSensitive() {
        XCTAssertEqual(
            FirebaseCollectionSchema.journalEntries.fieldNames,
            [
                "entryID",
                "createdAt",
                "updatedAt",
                "durationSeconds",
                "transcript",
                "engineName",
                "sessionID",
                "editableTitle",
                "editableEmotion",
                "privateNote",
                "tags",
                "result"
            ]
        )
        XCTAssertEqual(
            FirebaseCollectionSchema.journalEntries.sensitiveFieldNames,
            ["transcript", "privateNote", "tags", "result"]
        )
    }

    func testFirebaseAuthUserSchemaDoesNotStorePasswordHash() {
        XCTAssertEqual(
            FirebaseCollectionSchema.user.fieldNames,
            ["uid", "email", "displayName", "createdAt", "localUserID", "updatedAt"]
        )
        XCTAssertEqual(FirebaseCollectionSchema.user.sensitiveFieldNames, ["email"])
        XCTAssertFalse(FirebaseCollectionSchema.user.fieldNames.contains("passwordHash"))
        XCTAssertFalse(FirebaseCollectionSchema.user.fieldNames.contains("salt"))
    }

    func testSharedCircleSchemasUseSharedCircleScope() {
        XCTAssertEqual(FirebaseCollectionSchema.circles.scope, .sharedCircle)
        XCTAssertEqual(FirebaseCollectionSchema.circleMembers.scope, .sharedCircle)
        XCTAssertEqual(FirebaseCollectionSchema.circlePosts.scope, .sharedCircle)
        XCTAssertEqual(FirebaseCollectionSchema.circlePostReplies.scope, .sharedCircle)
        XCTAssertEqual(FirebaseCollectionSchema.circlePosts.sensitiveFieldNames, ["text"])
        XCTAssertEqual(FirebaseCollectionSchema.circlePostReplies.sensitiveFieldNames, ["text"])
    }

    func testRewardAndActivitySchemasMatchCurrentModels() {
        XCTAssertEqual(
            FirebaseCollectionSchema.rewardState.fieldNames,
            ["points", "level", "intoLevel", "nextLevel", "questAwards", "updatedAt"]
        )
        XCTAssertEqual(FirebaseCollectionSchema.rewardState.sensitiveFieldNames, ["questAwards"])
        XCTAssertEqual(
            FirebaseCollectionSchema.pointEntries.fieldNames,
            ["pointEntryID", "label", "points", "icon", "createdAt"]
        )
        XCTAssertEqual(
            FirebaseCollectionSchema.activityEvents.fieldNames,
            ["activityEventID", "type", "title", "keyword", "refID", "createdAt"]
        )
    }
}
