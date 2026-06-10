import FirebaseFirestore
import Foundation

/// Live, public sync of `circles` + their nested `posts` to Firestore.
///
/// Schema:
///   /circles/{circleID}
///     - id, name, intention, emoji, createdAt
///     - creatorUserID, creatorName
///     - memberUserIDs: [String]   // membership + member count
///     - coverImagesBase64: [String]  // tight-compressed cover photos (data: URI not used; raw base64)
///   /circles/{circleID}/posts/{postID}
///     - id, circleID, who, authorUserID, text, createdAt
///     - likedBy: [String]         // UIDs that liked this post
///     - sourceEntryID?
///     - replies: [ { id, who, authorUserID, text, createdAt, likedBy } ]
@MainActor
final class FirebaseCircleService {
    private let db: Firestore
    private var circlesListener: ListenerRegistration?
    private var postListeners: [UUID: ListenerRegistration] = [:]

    init() {
        self.db = Firestore.firestore()
    }

    // MARK: - Listening

    /// Subscribe to the full list of circles. Updates fire whenever ANY user creates/edits/deletes.
    func observeAllCircles(onChange: @escaping ([CircleSpace]) -> Void) {
        circlesListener?.remove()
        circlesListener = db.collection("circles")
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else {
                    onChange([])
                    return
                }
                let circles = docs.compactMap { CircleSpace(firestoreData: $0.data()) }
                onChange(circles)
            }
    }

    /// Subscribe to posts for one circle. Caller is responsible for matching unobserve.
    func observePosts(for circleID: UUID, onChange: @escaping ([CirclePost]) -> Void) {
        postListeners[circleID]?.remove()
        postListeners[circleID] = db
            .collection("circles").document(circleID.uuidString)
            .collection("posts")
            .addSnapshotListener { snapshot, _ in
                guard let docs = snapshot?.documents else {
                    onChange([])
                    return
                }
                let posts = docs.compactMap { CirclePost(firestoreData: $0.data()) }
                onChange(posts)
            }
    }

    func stopObservingCircles() {
        circlesListener?.remove()
        circlesListener = nil
    }

    func stopObservingPosts(for circleID: UUID) {
        postListeners[circleID]?.remove()
        postListeners[circleID] = nil
    }

    func stopAll() {
        stopObservingCircles()
        for (_, listener) in postListeners { listener.remove() }
        postListeners.removeAll()
    }

    // MARK: - Circle writes

    func upsertCircle(_ circle: CircleSpace, memberUserIDs: [String]) async throws {
        var data = circle.firestoreData
        data["memberUserIDs"] = memberUserIDs
        try await db.collection("circles")
            .document(circle.id.uuidString)
            .setData(data, merge: true)
    }

    func deleteCircle(_ circleID: UUID) async throws {
        // Best-effort: posts subcollection won't auto-delete in Firestore, but listeners filter to
        // existing circles so orphaned posts are invisible. A Cloud Function could sweep later.
        try await db.collection("circles").document(circleID.uuidString).delete()
    }

    func setMembership(circleID: UUID, uid: String, joined: Bool) async throws {
        let ref = db.collection("circles").document(circleID.uuidString)
        if joined {
            try await ref.updateData(["memberUserIDs": FieldValue.arrayUnion([uid])])
        } else {
            try await ref.updateData(["memberUserIDs": FieldValue.arrayRemove([uid])])
        }
    }

    func setCircleLike(circleID: UUID, uid: String, liked: Bool) async throws {
        let ref = db.collection("circles").document(circleID.uuidString)
        if liked {
            try await ref.updateData(["likedByUserIDs": FieldValue.arrayUnion([uid])])
        } else {
            try await ref.updateData(["likedByUserIDs": FieldValue.arrayRemove([uid])])
        }
    }

    func setCircleFavorite(circleID: UUID, uid: String, favorited: Bool) async throws {
        let ref = db.collection("circles").document(circleID.uuidString)
        if favorited {
            try await ref.updateData(["favoritedByUserIDs": FieldValue.arrayUnion([uid])])
        } else {
            try await ref.updateData(["favoritedByUserIDs": FieldValue.arrayRemove([uid])])
        }
    }

    // MARK: - Post writes

    func upsertPost(_ post: CirclePost) async throws {
        try await db
            .collection("circles").document(post.circleID.uuidString)
            .collection("posts").document(post.id.uuidString)
            .setData(post.firestoreData, merge: true)
    }

    func deletePost(circleID: UUID, postID: UUID) async throws {
        try await db
            .collection("circles").document(circleID.uuidString)
            .collection("posts").document(postID.uuidString)
            .delete()
    }
}

// MARK: - Codec: CircleSpace

extension CircleSpace {
    nonisolated var firestoreData: [String: Any] {
        var data: [String: Any] = [
            "id": id.uuidString,
            "name": name,
            "intention": intention,
            "emoji": emoji,
            "createdAt": createdAt,
            "creatorUserID": creatorUserID,
            "creatorName": creatorName
        ]
        if !coverImages.isEmpty {
            data["coverImagesBase64"] = coverImages.map { $0.base64EncodedString() }
        }
        return data
    }

    /// Decode a Firestore document back into a CircleSpace. Returns nil if the id is missing.
    nonisolated init?(firestoreData data: [String: Any]) {
        guard
            let idString = data["id"] as? String,
            let id = UUID(uuidString: idString)
        else { return nil }

        let name = data["name"] as? String ?? ""
        let intention = data["intention"] as? String ?? ""
        let emoji = data["emoji"] as? String ?? "🌱"
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
            ?? (data["createdAt"] as? Date)
            ?? Date()
        let creatorUserID = data["creatorUserID"] as? String ?? ""
        let creatorName = data["creatorName"] as? String ?? ""
        let memberUserIDs = data["memberUserIDs"] as? [String] ?? []
        let likedByUserIDs = data["likedByUserIDs"] as? [String] ?? []
        let favoritedByUserIDs = data["favoritedByUserIDs"] as? [String] ?? []
        let coverImages = (data["coverImagesBase64"] as? [String] ?? [])
            .compactMap { Data(base64Encoded: $0) }

        self.init(
            id: id,
            name: name,
            intention: intention,
            emoji: emoji,
            members: max(memberUserIDs.count, 1),
            joined: false, // recomputed per-viewer via isJoined(by:)
            createdAt: createdAt,
            creatorUserID: creatorUserID,
            creatorName: creatorName,
            coverImages: coverImages,
            memberUserIDs: memberUserIDs,
            likedByUserIDs: likedByUserIDs,
            favoritedByUserIDs: favoritedByUserIDs
        )
    }
}

// MARK: - Codec: CirclePost / PostReply

extension CirclePost {
    nonisolated var firestoreData: [String: Any] {
        var data: [String: Any] = [
            "id": id.uuidString,
            "circleID": circleID.uuidString,
            "who": who,
            "authorUserID": authorUserID,
            "text": text,
            "createdAt": createdAt,
            "likedBy": likedBy,
            "replies": replies.map(\.firestoreData)
        ]
        if let sourceEntryID {
            data["sourceEntryID"] = sourceEntryID.uuidString
        }
        return data
    }

    nonisolated init?(firestoreData data: [String: Any]) {
        guard
            let idString = data["id"] as? String,
            let id = UUID(uuidString: idString),
            let circleIDString = data["circleID"] as? String,
            let circleID = UUID(uuidString: circleIDString)
        else { return nil }

        let who = data["who"] as? String ?? "Anonymous penguin"
        let authorUserID = data["authorUserID"] as? String ?? ""
        let text = data["text"] as? String ?? ""
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
            ?? (data["createdAt"] as? Date)
            ?? Date()
        let likedBy = data["likedBy"] as? [String] ?? []
        let repliesRaw = data["replies"] as? [[String: Any]] ?? []
        let replies = repliesRaw.compactMap(PostReply.init(firestoreData:))
        let sourceEntryID: UUID? = (data["sourceEntryID"] as? String).flatMap(UUID.init(uuidString:))

        self.init(
            id: id,
            circleID: circleID,
            who: who,
            text: text,
            createdAt: createdAt,
            likes: likedBy.count,
            liked: false, // recomputed per-viewer via isLiked(by:)
            replies: replies,
            sourceEntryID: sourceEntryID,
            authorUserID: authorUserID,
            likedBy: likedBy
        )
    }
}

extension PostReply {
    nonisolated var firestoreData: [String: Any] {
        [
            "id": id.uuidString,
            "who": who,
            "authorUserID": authorUserID,
            "text": text,
            "createdAt": createdAt,
            "likedBy": likedBy
        ]
    }

    nonisolated init?(firestoreData data: [String: Any]) {
        guard
            let idString = data["id"] as? String,
            let id = UUID(uuidString: idString)
        else { return nil }

        let who = data["who"] as? String ?? "Anonymous penguin"
        let authorUserID = data["authorUserID"] as? String ?? ""
        let text = data["text"] as? String ?? ""
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
            ?? (data["createdAt"] as? Date)
            ?? Date()
        let likedBy = data["likedBy"] as? [String] ?? []

        self.init(
            id: id,
            who: who,
            text: text,
            createdAt: createdAt,
            likes: likedBy.count,
            liked: false,
            authorUserID: authorUserID,
            likedBy: likedBy
        )
    }
}
