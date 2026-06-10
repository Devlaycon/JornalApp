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

    nonisolated init(
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
    /// Cached member count for legacy / pre-membership-array records. Authoritative count is
    /// `memberUserIDs.count` when non-empty.
    var members: Int
    /// Cached "current viewer joined" flag for legacy records. Per-viewer truth is `isJoined(by:)`.
    var joined: Bool
    var createdAt: Date
    /// Firebase UID of the user who created this circle. Empty for legacy local-only data.
    var creatorUserID: String = ""
    /// Display name of the creator at creation time (for showing "by Name" in UI).
    var creatorName: String = ""
    /// Optional cover photos (JPEG-encoded Data). First image is the primary cover.
    var coverImages: [Data] = []
    /// Firebase UIDs of every user who has joined. Source of truth for membership when populated.
    var memberUserIDs: [String] = []
    /// Firebase UIDs that liked this circle (public counter).
    var likedByUserIDs: [String] = []
    /// Firebase UIDs that bookmarked this circle (personal "save for later" — private to each user
    /// but stored on the shared doc so the array is the source of truth across devices).
    var favoritedByUserIDs: [String] = []

    nonisolated init(
        id: UUID = UUID(),
        name: String,
        intention: String,
        emoji: String = "🌱",
        members: Int = 1,
        joined: Bool = true,
        createdAt: Date = Date(),
        creatorUserID: String = "",
        creatorName: String = "",
        coverImages: [Data] = [],
        memberUserIDs: [String] = [],
        likedByUserIDs: [String] = [],
        favoritedByUserIDs: [String] = []
    ) {
        self.id = id
        self.name = name
        self.intention = intention
        self.emoji = emoji
        self.members = members
        self.joined = joined
        self.createdAt = createdAt
        self.creatorUserID = creatorUserID
        self.creatorName = creatorName
        self.coverImages = coverImages
        self.memberUserIDs = memberUserIDs
        self.likedByUserIDs = likedByUserIDs
        self.favoritedByUserIDs = favoritedByUserIDs
    }

    /// True if this circle was created by the given Firebase UID. Legacy circles with empty
    /// creatorUserID are treated as not-owned (since auth context is required to edit/delete).
    func isOwnedBy(uid: String?) -> Bool {
        guard let uid, !uid.isEmpty, !creatorUserID.isEmpty else { return false }
        return creatorUserID == uid
    }

    /// Authoritative member count for display.
    var displayMemberCount: Int { memberUserIDs.isEmpty ? members : memberUserIDs.count }

    /// True if the given UID has joined this circle. Falls back to the cached `joined` flag for
    /// legacy local-only records without a `memberUserIDs` array.
    func isJoined(by uid: String?) -> Bool {
        if let uid, !uid.isEmpty, !memberUserIDs.isEmpty {
            return memberUserIDs.contains(uid)
        }
        return joined
    }

    /// True if the given UID has liked this circle.
    func isLiked(by uid: String?) -> Bool {
        guard let uid, !uid.isEmpty else { return false }
        return likedByUserIDs.contains(uid)
    }

    /// True if the given UID has bookmarked this circle.
    func isFavorited(by uid: String?) -> Bool {
        guard let uid, !uid.isEmpty else { return false }
        return favoritedByUserIDs.contains(uid)
    }

    var likeCount: Int { likedByUserIDs.count }
    var favoriteCount: Int { favoritedByUserIDs.count }
}

struct PostReply: Identifiable, Codable, Equatable {
    let id: UUID
    var who: String
    var text: String
    var createdAt: Date
    /// Cached count for legacy records. Authoritative count is `likedBy.count` when non-empty.
    var likes: Int
    /// Cached self-like flag for legacy local-only records. Per-viewer truth is `isLiked(by:)`.
    var liked: Bool
    /// Firebase UID of the author. Empty for legacy local-only data, which falls back to `who == "You"`.
    var authorUserID: String = ""
    /// Firebase UIDs that liked this reply. Source of truth for like counts when populated.
    var likedBy: [String] = []

    nonisolated init(
        id: UUID = UUID(),
        who: String = "You",
        text: String,
        createdAt: Date = Date(),
        likes: Int = 0,
        liked: Bool = false,
        authorUserID: String = "",
        likedBy: [String] = []
    ) {
        self.id = id
        self.who = who
        self.text = text
        self.createdAt = createdAt
        self.likes = likes
        self.liked = liked
        self.authorUserID = authorUserID
        self.likedBy = likedBy
    }

    /// True if this reply was authored by the given Firebase UID, or — for legacy local-only
    /// records without an authorUserID — if `who == "You"`.
    func isAuthoredBy(uid: String?) -> Bool {
        if !authorUserID.isEmpty, let uid, !uid.isEmpty {
            return authorUserID == uid
        }
        return who == "You"
    }

    /// Total like count — Firebase-backed `likedBy` if populated, otherwise the cached `likes`.
    var displayLikeCount: Int { likedBy.isEmpty ? likes : likedBy.count }

    /// True if the given UID has liked this reply (Firebase-backed) — falls back to the
    /// cached `liked` flag for legacy local-only records.
    func isLiked(by uid: String?) -> Bool {
        if let uid, !uid.isEmpty, !likedBy.isEmpty {
            return likedBy.contains(uid)
        }
        return liked
    }
}

struct CirclePost: Identifiable, Codable, Equatable {
    let id: UUID
    var circleID: UUID
    var who: String
    var text: String
    var createdAt: Date
    /// Cached count for legacy records. Authoritative count is `likedBy.count` when non-empty.
    var likes: Int
    /// Cached self-like flag for legacy records. Per-viewer truth is `isLiked(by:)`.
    var liked: Bool
    var replies: [PostReply]
    var sourceEntryID: UUID?
    /// Firebase UID of the author. Empty for legacy local-only data, which falls back to `who == "You"`.
    var authorUserID: String = ""
    /// Firebase UIDs that liked this post. Source of truth for like counts when populated.
    var likedBy: [String] = []

    nonisolated init(
        id: UUID = UUID(),
        circleID: UUID,
        who: String = "You",
        text: String,
        createdAt: Date = Date(),
        likes: Int = 0,
        liked: Bool = false,
        replies: [PostReply] = [],
        sourceEntryID: UUID? = nil,
        authorUserID: String = "",
        likedBy: [String] = []
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
        self.authorUserID = authorUserID
        self.likedBy = likedBy
    }

    /// True if this post was authored by the given Firebase UID, or — for legacy local-only
    /// records without an authorUserID — if `who == "You"`.
    func isAuthoredBy(uid: String?) -> Bool {
        if !authorUserID.isEmpty, let uid, !uid.isEmpty {
            return authorUserID == uid
        }
        return who == "You"
    }

    /// Total like count — Firebase-backed `likedBy` if populated, otherwise the cached `likes`.
    var displayLikeCount: Int { likedBy.isEmpty ? likes : likedBy.count }

    /// True if the given UID has liked this post (Firebase-backed) — falls back to the
    /// cached `liked` flag for legacy local-only records.
    func isLiked(by uid: String?) -> Bool {
        if let uid, !uid.isEmpty, !likedBy.isEmpty {
            return likedBy.contains(uid)
        }
        return liked
    }
}

/// A single points reward, shown in the Profile rewards log.
struct PointEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var label: String
    var points: Int
    var icon: String
    var createdAt: Date

    nonisolated init(
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

    nonisolated init(
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
