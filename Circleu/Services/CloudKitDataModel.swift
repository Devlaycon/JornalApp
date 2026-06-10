import Foundation

enum CloudKitDatabaseScope: String, Codable, Equatable {
    case privateDatabase
    case sharedDatabase
}

struct CloudKitRecordField: Codable, Equatable {
    var name: String
    var isSensitive: Bool

    init(_ name: String, isSensitive: Bool = false) {
        self.name = name
        self.isSensitive = isSensitive
    }
}

struct CloudKitRecordSchema: Codable, Equatable {
    var recordType: String
    var scope: CloudKitDatabaseScope
    var recordNamePrefix: String
    var fields: [CloudKitRecordField]

    var fieldNames: [String] {
        fields.map(\.name)
    }

    var sensitiveFieldNames: [String] {
        fields.filter(\.isSensitive).map(\.name)
    }

    func recordName(for identifier: String) -> String {
        "\(recordNamePrefix)_\(identifier)"
    }

    func recordName(for id: UUID) -> String {
        recordName(for: id.uuidString)
    }
}

extension CloudKitRecordSchema {
    static let account = CloudKitRecordSchema(
        recordType: "AccountRecord",
        scope: .privateDatabase,
        recordNamePrefix: "account",
        fields: [
            CloudKitRecordField("accountID"),
            CloudKitRecordField("email", isSensitive: true),
            CloudKitRecordField("displayName"),
            CloudKitRecordField("createdAt"),
            CloudKitRecordField("localAuthMigratedAt")
        ]
    )

    static let userProfile = CloudKitRecordSchema(
        recordType: "UserProfileRecord",
        scope: .privateDatabase,
        recordNamePrefix: "profile",
        fields: [
            CloudKitRecordField("localUserID"),
            CloudKitRecordField("displayName"),
            CloudKitRecordField("promptIndex"),
            CloudKitRecordField("updatedAt")
        ]
    )

    static let journalEntry = CloudKitRecordSchema(
        recordType: "JournalEntryRecord",
        scope: .privateDatabase,
        recordNamePrefix: "journal",
        fields: [
            CloudKitRecordField("entryID"),
            CloudKitRecordField("createdAt"),
            CloudKitRecordField("updatedAt"),
            CloudKitRecordField("durationSeconds"),
            CloudKitRecordField("transcript", isSensitive: true),
            CloudKitRecordField("engineName"),
            CloudKitRecordField("sessionID"),
            CloudKitRecordField("editableTitle"),
            CloudKitRecordField("editableEmotion"),
            CloudKitRecordField("privateNote", isSensitive: true),
            CloudKitRecordField("tags", isSensitive: true),
            CloudKitRecordField("resultJSON", isSensitive: true)
        ]
    )

    static let aiReflectionSession = CloudKitRecordSchema(
        recordType: "AIReflectionSessionRecord",
        scope: .privateDatabase,
        recordNamePrefix: "aiSession",
        fields: [
            CloudKitRecordField("sessionID"),
            CloudKitRecordField("createdAt"),
            CloudKitRecordField("updatedAt"),
            CloudKitRecordField("entryID"),
            CloudKitRecordField("engineName"),
            CloudKitRecordField("source"),
            CloudKitRecordField("transcript", isSensitive: true),
            CloudKitRecordField("durationSeconds"),
            CloudKitRecordField("selectedAttemptID"),
            CloudKitRecordField("mergedSessionIDs"),
            CloudKitRecordField("attemptsJSON", isSensitive: true)
        ]
    )

    static let quest = CloudKitRecordSchema(
        recordType: "QuestRecord",
        scope: .privateDatabase,
        recordNamePrefix: "quest",
        fields: [
            CloudKitRecordField("questID"),
            CloudKitRecordField("title"),
            CloudKitRecordField("detail"),
            CloudKitRecordField("sourceEntryID"),
            CloudKitRecordField("createdAt"),
            CloudKitRecordField("completedAt"),
            CloudKitRecordField("status")
        ]
    )

    static let tipsPracticeSession = CloudKitRecordSchema(
        recordType: "TipsPracticeSessionRecord",
        scope: .privateDatabase,
        recordNamePrefix: "tipsPractice",
        fields: [
            CloudKitRecordField("sessionID"),
            CloudKitRecordField("createdAt"),
            CloudKitRecordField("updatedAt"),
            CloudKitRecordField("originalMessage", isSensitive: true),
            CloudKitRecordField("scene"),
            CloudKitRecordField("customScene"),
            CloudKitRecordField("tone"),
            CloudKitRecordField("situation", isSensitive: true),
            CloudKitRecordField("attachedImageCount"),
            CloudKitRecordField("turnsJSON", isSensitive: true),
            CloudKitRecordField("coachOutputJSON", isSensitive: true)
        ]
    )

    static let circle = CloudKitRecordSchema(
        recordType: "CircleRecord",
        scope: .sharedDatabase,
        recordNamePrefix: "circle",
        fields: [
            CloudKitRecordField("circleID"),
            CloudKitRecordField("name"),
            CloudKitRecordField("intention"),
            CloudKitRecordField("emoji"),
            CloudKitRecordField("members"),
            CloudKitRecordField("joined"),
            CloudKitRecordField("createdAt"),
            CloudKitRecordField("updatedAt")
        ]
    )

    static let circleMember = CloudKitRecordSchema(
        recordType: "CircleMemberRecord",
        scope: .sharedDatabase,
        recordNamePrefix: "circleMember",
        fields: [
            CloudKitRecordField("memberID"),
            CloudKitRecordField("circleID"),
            CloudKitRecordField("userID"),
            CloudKitRecordField("role"),
            CloudKitRecordField("status"),
            CloudKitRecordField("createdAt"),
            CloudKitRecordField("updatedAt")
        ]
    )

    static let circlePost = CloudKitRecordSchema(
        recordType: "CirclePostRecord",
        scope: .sharedDatabase,
        recordNamePrefix: "circlePost",
        fields: [
            CloudKitRecordField("postID"),
            CloudKitRecordField("circleID"),
            CloudKitRecordField("who"),
            CloudKitRecordField("text", isSensitive: true),
            CloudKitRecordField("createdAt"),
            CloudKitRecordField("updatedAt"),
            CloudKitRecordField("likes"),
            CloudKitRecordField("liked"),
            CloudKitRecordField("sourceEntryID")
        ]
    )

    static let circlePostReply = CloudKitRecordSchema(
        recordType: "CirclePostReplyRecord",
        scope: .sharedDatabase,
        recordNamePrefix: "circlePostReply",
        fields: [
            CloudKitRecordField("replyID"),
            CloudKitRecordField("postID"),
            CloudKitRecordField("circleID"),
            CloudKitRecordField("who"),
            CloudKitRecordField("text", isSensitive: true),
            CloudKitRecordField("createdAt"),
            CloudKitRecordField("likes"),
            CloudKitRecordField("liked")
        ]
    )

    static let rewardState = CloudKitRecordSchema(
        recordType: "RewardStateRecord",
        scope: .privateDatabase,
        recordNamePrefix: "rewardState",
        fields: [
            CloudKitRecordField("localUserID"),
            CloudKitRecordField("points"),
            CloudKitRecordField("level"),
            CloudKitRecordField("intoLevel"),
            CloudKitRecordField("nextLevel"),
            CloudKitRecordField("questAwardsJSON", isSensitive: true),
            CloudKitRecordField("updatedAt")
        ]
    )

    static let pointEntry = CloudKitRecordSchema(
        recordType: "PointEntryRecord",
        scope: .privateDatabase,
        recordNamePrefix: "pointEntry",
        fields: [
            CloudKitRecordField("pointEntryID"),
            CloudKitRecordField("label"),
            CloudKitRecordField("points"),
            CloudKitRecordField("icon"),
            CloudKitRecordField("createdAt")
        ]
    )

    static let activityEvent = CloudKitRecordSchema(
        recordType: "ActivityEventRecord",
        scope: .privateDatabase,
        recordNamePrefix: "activityEvent",
        fields: [
            CloudKitRecordField("activityEventID"),
            CloudKitRecordField("type"),
            CloudKitRecordField("title"),
            CloudKitRecordField("keyword"),
            CloudKitRecordField("refID"),
            CloudKitRecordField("createdAt")
        ]
    )
}

enum CloudKitDataModel {
    static let recordTypes: [CloudKitRecordSchema] = [
        .account,
        .userProfile,
        .journalEntry,
        .aiReflectionSession,
        .quest,
        .tipsPracticeSession,
        .rewardState,
        .pointEntry,
        .activityEvent,
        .circle,
        .circleMember,
        .circlePost,
        .circlePostReply
    ]
}
