import Foundation

enum QuestStatus: String, Codable, Equatable {
    case active
    case completed
    case skipped
}

struct Quest: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var detail: String
    var sourceEntryID: UUID?
    var createdAt: Date
    var completedAt: Date?
    var status: QuestStatus

    init(
        id: UUID = UUID(),
        title: String,
        detail: String,
        sourceEntryID: UUID? = nil,
        createdAt: Date = Date(),
        completedAt: Date? = nil,
        status: QuestStatus = .active
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.sourceEntryID = sourceEntryID
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.status = status
    }
}

struct CircleSpace: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var intention: String
    var emoji: String
    var members: Int
    var joined: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        intention: String,
        emoji: String = "🌱",
        members: Int = 1,
        joined: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.intention = intention
        self.emoji = emoji
        self.members = members
        self.joined = joined
        self.createdAt = createdAt
    }
}

struct PostReply: Identifiable, Codable, Equatable {
    let id: UUID
    var who: String
    var text: String
    var createdAt: Date
    var likes: Int
    var liked: Bool

    init(
        id: UUID = UUID(),
        who: String = "You",
        text: String,
        createdAt: Date = Date(),
        likes: Int = 0,
        liked: Bool = false
    ) {
        self.id = id
        self.who = who
        self.text = text
        self.createdAt = createdAt
        self.likes = likes
        self.liked = liked
    }
}

struct CirclePost: Identifiable, Codable, Equatable {
    let id: UUID
    var circleID: UUID
    var who: String
    var text: String
    var createdAt: Date
    var likes: Int
    var liked: Bool
    var replies: [PostReply]
    var sourceEntryID: UUID?

    init(
        id: UUID = UUID(),
        circleID: UUID,
        who: String = "You",
        text: String,
        createdAt: Date = Date(),
        likes: Int = 0,
        liked: Bool = false,
        replies: [PostReply] = [],
        sourceEntryID: UUID? = nil
    ) {
        self.id = id
        self.circleID = circleID
        self.who = who
        self.text = text
        self.createdAt = createdAt
        self.likes = likes
        self.liked = liked
        self.replies = replies
        self.sourceEntryID = sourceEntryID
    }
}

struct ProgressBadge: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let isUnlocked: Bool
}

struct AppProgressSnapshot: Equatable {
    var entryCount: Int
    var streak: Int
    var level: Int
    var xp: Int
    var xpForNextLevel: Int
    var mostCommonEmotion: String
    var completedQuestCount: Int
    var badges: [ProgressBadge]

    static let empty = AppProgressSnapshot(
        entryCount: 0,
        streak: 0,
        level: 1,
        xp: 0,
        xpForNextLevel: 100,
        mostCommonEmotion: "None",
        completedQuestCount: 0,
        badges: []
    )
}
