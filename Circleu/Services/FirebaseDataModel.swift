import Foundation

enum FirebaseDataScope: String, Codable, Equatable {
    case privateUser
    case sharedCircle
}

struct FirebaseDocumentField: Codable, Equatable {
    var name: String
    var isSensitive: Bool

    init(_ name: String, isSensitive: Bool = false) {
        self.name = name
        self.isSensitive = isSensitive
    }
}

struct FirebaseCollectionSchema: Codable, Equatable {
    var name: String
    var pathTemplate: String
    var scope: FirebaseDataScope
    var fields: [FirebaseDocumentField]

    var fieldNames: [String] {
        fields.map(\.name)
    }

    var sensitiveFieldNames: [String] {
        fields.filter(\.isSensitive).map(\.name)
    }
}

extension FirebaseCollectionSchema {
    static let user = FirebaseCollectionSchema(
        name: "users",
        pathTemplate: "users/{uid}",
        scope: .privateUser,
        fields: [
            FirebaseDocumentField("uid"),
            FirebaseDocumentField("email", isSensitive: true),
            FirebaseDocumentField("displayName"),
            FirebaseDocumentField("createdAt"),
            FirebaseDocumentField("localUserID"),
            FirebaseDocumentField("updatedAt")
        ]
    )

    static let profile = FirebaseCollectionSchema(
        name: "profile",
        pathTemplate: "users/{uid}/profile/main",
        scope: .privateUser,
        fields: [
            FirebaseDocumentField("displayName"),
            FirebaseDocumentField("promptIndex"),
            FirebaseDocumentField("updatedAt")
        ]
    )

    static let journalEntries = FirebaseCollectionSchema(
        name: "journalEntries",
        pathTemplate: "users/{uid}/journalEntries/{entryID}",
        scope: .privateUser,
        fields: [
            FirebaseDocumentField("entryID"),
            FirebaseDocumentField("createdAt"),
            FirebaseDocumentField("updatedAt"),
            FirebaseDocumentField("durationSeconds"),
            FirebaseDocumentField("transcript", isSensitive: true),
            FirebaseDocumentField("engineName"),
            FirebaseDocumentField("sessionID"),
            FirebaseDocumentField("editableTitle"),
            FirebaseDocumentField("editableEmotion"),
            FirebaseDocumentField("privateNote", isSensitive: true),
            FirebaseDocumentField("tags", isSensitive: true),
            FirebaseDocumentField("result", isSensitive: true)
        ]
    )

    static let aiReflectionSessions = FirebaseCollectionSchema(
        name: "aiReflectionSessions",
        pathTemplate: "users/{uid}/aiReflectionSessions/{sessionID}",
        scope: .privateUser,
        fields: [
            FirebaseDocumentField("sessionID"),
            FirebaseDocumentField("createdAt"),
            FirebaseDocumentField("updatedAt"),
            FirebaseDocumentField("entryID"),
            FirebaseDocumentField("engineName"),
            FirebaseDocumentField("source"),
            FirebaseDocumentField("transcript", isSensitive: true),
            FirebaseDocumentField("durationSeconds"),
            FirebaseDocumentField("selectedAttemptID"),
            FirebaseDocumentField("mergedSessionIDs"),
            FirebaseDocumentField("attempts", isSensitive: true)
        ]
    )

    static let quests = FirebaseCollectionSchema(
        name: "quests",
        pathTemplate: "users/{uid}/quests/{questID}",
        scope: .privateUser,
        fields: [
            FirebaseDocumentField("questID"),
            FirebaseDocumentField("title"),
            FirebaseDocumentField("detail"),
            FirebaseDocumentField("sourceEntryID"),
            FirebaseDocumentField("createdAt"),
            FirebaseDocumentField("completedAt"),
            FirebaseDocumentField("status")
        ]
    )

    static let tipsPracticeSessions = FirebaseCollectionSchema(
        name: "tipsPracticeSessions",
        pathTemplate: "users/{uid}/tipsPracticeSessions/{sessionID}",
        scope: .privateUser,
        fields: [
            FirebaseDocumentField("sessionID"),
            FirebaseDocumentField("createdAt"),
            FirebaseDocumentField("updatedAt"),
            FirebaseDocumentField("originalMessage", isSensitive: true),
            FirebaseDocumentField("scene"),
            FirebaseDocumentField("customScene"),
            FirebaseDocumentField("tone"),
            FirebaseDocumentField("situation", isSensitive: true),
            FirebaseDocumentField("attachedImageCount"),
            FirebaseDocumentField("turns", isSensitive: true),
            FirebaseDocumentField("coachOutput", isSensitive: true)
        ]
    )

    static let rewardState = FirebaseCollectionSchema(
        name: "rewardState",
        pathTemplate: "users/{uid}/rewardState/main",
        scope: .privateUser,
        fields: [
            FirebaseDocumentField("points"),
            FirebaseDocumentField("level"),
            FirebaseDocumentField("intoLevel"),
            FirebaseDocumentField("nextLevel"),
            FirebaseDocumentField("questAwards", isSensitive: true),
            FirebaseDocumentField("updatedAt")
        ]
    )

    static let pointEntries = FirebaseCollectionSchema(
        name: "pointEntries",
        pathTemplate: "users/{uid}/pointEntries/{pointEntryID}",
        scope: .privateUser,
        fields: [
            FirebaseDocumentField("pointEntryID"),
            FirebaseDocumentField("label"),
            FirebaseDocumentField("points"),
            FirebaseDocumentField("icon"),
            FirebaseDocumentField("createdAt")
        ]
    )

    static let activityEvents = FirebaseCollectionSchema(
        name: "activityEvents",
        pathTemplate: "users/{uid}/activityEvents/{activityEventID}",
        scope: .privateUser,
        fields: [
            FirebaseDocumentField("activityEventID"),
            FirebaseDocumentField("type"),
            FirebaseDocumentField("title"),
            FirebaseDocumentField("keyword"),
            FirebaseDocumentField("refID"),
            FirebaseDocumentField("createdAt")
        ]
    )

    static let circles = FirebaseCollectionSchema(
        name: "circles",
        pathTemplate: "circles/{circleID}",
        scope: .sharedCircle,
        fields: [
            FirebaseDocumentField("circleID"),
            FirebaseDocumentField("name"),
            FirebaseDocumentField("intention"),
            FirebaseDocumentField("emoji"),
            FirebaseDocumentField("members"),
            FirebaseDocumentField("createdAt"),
            FirebaseDocumentField("updatedAt")
        ]
    )

    static let circleMembers = FirebaseCollectionSchema(
        name: "circleMembers",
        pathTemplate: "circles/{circleID}/members/{memberID}",
        scope: .sharedCircle,
        fields: [
            FirebaseDocumentField("memberID"),
            FirebaseDocumentField("circleID"),
            FirebaseDocumentField("uid"),
            FirebaseDocumentField("role"),
            FirebaseDocumentField("status"),
            FirebaseDocumentField("createdAt"),
            FirebaseDocumentField("updatedAt")
        ]
    )

    static let circlePosts = FirebaseCollectionSchema(
        name: "circlePosts",
        pathTemplate: "circles/{circleID}/posts/{postID}",
        scope: .sharedCircle,
        fields: [
            FirebaseDocumentField("postID"),
            FirebaseDocumentField("circleID"),
            FirebaseDocumentField("uid"),
            FirebaseDocumentField("who"),
            FirebaseDocumentField("text", isSensitive: true),
            FirebaseDocumentField("createdAt"),
            FirebaseDocumentField("updatedAt"),
            FirebaseDocumentField("likes"),
            FirebaseDocumentField("sourceEntryID")
        ]
    )

    static let circlePostReplies = FirebaseCollectionSchema(
        name: "circlePostReplies",
        pathTemplate: "circles/{circleID}/posts/{postID}/replies/{replyID}",
        scope: .sharedCircle,
        fields: [
            FirebaseDocumentField("replyID"),
            FirebaseDocumentField("postID"),
            FirebaseDocumentField("circleID"),
            FirebaseDocumentField("uid"),
            FirebaseDocumentField("who"),
            FirebaseDocumentField("text", isSensitive: true),
            FirebaseDocumentField("createdAt"),
            FirebaseDocumentField("likes")
        ]
    )
}

enum FirebaseDataModel {
    static let collections: [FirebaseCollectionSchema] = [
        .user,
        .profile,
        .journalEntries,
        .aiReflectionSessions,
        .quests,
        .tipsPracticeSessions,
        .rewardState,
        .pointEntries,
        .activityEvents,
        .circles,
        .circleMembers,
        .circlePosts,
        .circlePostReplies
    ]
}
