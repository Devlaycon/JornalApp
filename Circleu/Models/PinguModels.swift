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
    /// Only true for circles this user created locally. Drives edit/delete permission.
    var isOwnedByMe: Bool = false
    /// Optional cover photos (JPEG-encoded Data). First image is the primary cover.
    var coverImages: [Data] = []

    init(
        id: UUID = UUID(),
        name: String,
        intention: String,
        emoji: String = "🌱",
        members: Int = 1,
        joined: Bool = true,
        createdAt: Date = Date(),
        isOwnedByMe: Bool = false,
        coverImages: [Data] = []
    ) {
        self.id = id
        self.name = name
        self.intention = intention
        self.emoji = emoji
        self.members = members
        self.joined = joined
        self.createdAt = createdAt
        self.isOwnedByMe = isOwnedByMe
        self.coverImages = coverImages
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

    /// Local user is "You" — only their own replies are editable/deletable.
    var isMine: Bool { who == "You" }
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

    /// Local user is "You" — only their own posts are editable/deletable.
    var isMine: Bool { who == "You" }
}

/// A single points reward, shown in the Profile rewards log.
struct PointEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var label: String
    var points: Int
    var icon: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        label: String,
        points: Int,
        icon: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.label = label
        self.points = points
        self.icon = icon
        self.createdAt = createdAt
    }
}

enum ActivityType: String, Codable, Equatable {
    case reflect
    case tips
    case communitySelect = "community_select"
    case communityJoin = "community_join"
}

/// A lightweight record-history event for the Profile timeline.
struct ActivityEvent: Identifiable, Codable, Equatable {
    let id: UUID
    var type: ActivityType
    var title: String
    var keyword: String
    var refID: UUID?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        type: ActivityType,
        title: String,
        keyword: String,
        refID: UUID? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.keyword = keyword
        self.refID = refID
        self.createdAt = createdAt
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
