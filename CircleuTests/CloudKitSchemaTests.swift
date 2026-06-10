import XCTest
@testable import Circleu

final class CloudKitSchemaTests: XCTestCase {
    func testRecordTypesUseExpectedDatabaseScopes() {
        XCTAssertEqual(CloudKitRecordSchema.account.scope, .privateDatabase)
        XCTAssertEqual(CloudKitRecordSchema.userProfile.scope, .privateDatabase)
        XCTAssertEqual(CloudKitRecordSchema.journalEntry.scope, .privateDatabase)
        XCTAssertEqual(CloudKitRecordSchema.aiReflectionSession.scope, .privateDatabase)
        XCTAssertEqual(CloudKitRecordSchema.quest.scope, .privateDatabase)
        XCTAssertEqual(CloudKitRecordSchema.tipsPracticeSession.scope, .privateDatabase)
        XCTAssertEqual(CloudKitRecordSchema.rewardState.scope, .privateDatabase)
        XCTAssertEqual(CloudKitRecordSchema.pointEntry.scope, .privateDatabase)
        XCTAssertEqual(CloudKitRecordSchema.activityEvent.scope, .privateDatabase)

        XCTAssertEqual(CloudKitRecordSchema.circle.scope, .sharedDatabase)
        XCTAssertEqual(CloudKitRecordSchema.circleMember.scope, .sharedDatabase)
        XCTAssertEqual(CloudKitRecordSchema.circlePost.scope, .sharedDatabase)
        XCTAssertEqual(CloudKitRecordSchema.circlePostReply.scope, .sharedDatabase)
    }

    func testJournalEntrySchemaUsesStableFieldsAndSensitiveFlags() {
        XCTAssertEqual(CloudKitRecordSchema.journalEntry.recordType, "JournalEntryRecord")
        XCTAssertEqual(
            CloudKitRecordSchema.journalEntry.fieldNames,
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
                "resultJSON"
            ]
        )
        XCTAssertEqual(
            CloudKitRecordSchema.journalEntry.sensitiveFieldNames,
            ["transcript", "privateNote", "tags", "resultJSON"]
        )
    }

    func testCircleSchemasMatchCurrentSocialFeedModels() {
        XCTAssertEqual(
            CloudKitRecordSchema.circle.fieldNames,
            ["circleID", "name", "intention", "emoji", "members", "joined", "createdAt", "updatedAt"]
        )
        XCTAssertEqual(
            CloudKitRecordSchema.circlePost.fieldNames,
            ["postID", "circleID", "who", "text", "createdAt", "updatedAt", "likes", "liked", "sourceEntryID"]
        )
        XCTAssertEqual(CloudKitRecordSchema.circlePost.sensitiveFieldNames, ["text"])
        XCTAssertEqual(
            CloudKitRecordSchema.circlePostReply.fieldNames,
            ["replyID", "postID", "circleID", "who", "text", "createdAt", "likes", "liked"]
        )
        XCTAssertEqual(CloudKitRecordSchema.circlePostReply.sensitiveFieldNames, ["text"])
    }

    func testRewardsAndAccountSchemasUsePrivateRecords() {
        XCTAssertEqual(
            CloudKitRecordSchema.account.fieldNames,
            ["accountID", "email", "displayName", "createdAt", "localAuthMigratedAt"]
        )
        XCTAssertEqual(CloudKitRecordSchema.account.sensitiveFieldNames, ["email"])
        XCTAssertEqual(
            CloudKitRecordSchema.rewardState.fieldNames,
            ["localUserID", "points", "level", "intoLevel", "nextLevel", "questAwardsJSON", "updatedAt"]
        )
        XCTAssertEqual(CloudKitRecordSchema.rewardState.sensitiveFieldNames, ["questAwardsJSON"])
        XCTAssertEqual(
            CloudKitRecordSchema.pointEntry.fieldNames,
            ["pointEntryID", "label", "points", "icon", "createdAt"]
        )
        XCTAssertEqual(
            CloudKitRecordSchema.activityEvent.fieldNames,
            ["activityEventID", "type", "title", "keyword", "refID", "createdAt"]
        )
    }

    func testDeterministicRecordNamesUseStablePrefixes() {
        let id = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!

        XCTAssertEqual(CloudKitRecordSchema.account.recordName(for: id), "account_11111111-2222-3333-4444-555555555555")
        XCTAssertEqual(CloudKitRecordSchema.userProfile.recordName(for: "local-user"), "profile_local-user")
        XCTAssertEqual(CloudKitRecordSchema.journalEntry.recordName(for: id), "journal_11111111-2222-3333-4444-555555555555")
        XCTAssertEqual(CloudKitRecordSchema.aiReflectionSession.recordName(for: id), "aiSession_11111111-2222-3333-4444-555555555555")
        XCTAssertEqual(CloudKitRecordSchema.quest.recordName(for: id), "quest_11111111-2222-3333-4444-555555555555")
        XCTAssertEqual(CloudKitRecordSchema.tipsPracticeSession.recordName(for: id), "tipsPractice_11111111-2222-3333-4444-555555555555")
        XCTAssertEqual(CloudKitRecordSchema.rewardState.recordName(for: "local-user"), "rewardState_local-user")
        XCTAssertEqual(CloudKitRecordSchema.pointEntry.recordName(for: id), "pointEntry_11111111-2222-3333-4444-555555555555")
        XCTAssertEqual(CloudKitRecordSchema.activityEvent.recordName(for: id), "activityEvent_11111111-2222-3333-4444-555555555555")
        XCTAssertEqual(CloudKitRecordSchema.circle.recordName(for: id), "circle_11111111-2222-3333-4444-555555555555")
        XCTAssertEqual(CloudKitRecordSchema.circleMember.recordName(for: id), "circleMember_11111111-2222-3333-4444-555555555555")
        XCTAssertEqual(CloudKitRecordSchema.circlePost.recordName(for: id), "circlePost_11111111-2222-3333-4444-555555555555")
        XCTAssertEqual(CloudKitRecordSchema.circlePostReply.recordName(for: id), "circlePostReply_11111111-2222-3333-4444-555555555555")
    }

    func testCloudKitSchemaListsAllRecordTypes() {
        XCTAssertEqual(
            CloudKitDataModel.recordTypes.map(\.recordType),
            [
                "AccountRecord",
                "UserProfileRecord",
                "JournalEntryRecord",
                "AIReflectionSessionRecord",
                "QuestRecord",
                "TipsPracticeSessionRecord",
                "RewardStateRecord",
                "PointEntryRecord",
                "ActivityEventRecord",
                "CircleRecord",
                "CircleMemberRecord",
                "CirclePostRecord",
                "CirclePostReplyRecord"
            ]
        )
    }
}
