import Combine
import Foundation

/// Source of truth for circles and posts.
///
/// When signed in, mirrors the public `/circles` Firestore collection so every registered
/// user sees the same global set of circles. Posts are observed per-circle (lazily, when the
/// detail view appears) to keep listener counts low. While signed out, falls back to the
/// previous UserDefaults-backed local cache so the demo flow keeps working.
@MainActor
final class CircleStore: ObservableObject {
    @Published private(set) var circles: [CircleSpace] = []
    @Published private(set) var posts: [CirclePost] = []

    /// The Firebase UID of the currently authed user, set by `configureBackend(...)`.
    private(set) var currentUserID: String?
    /// The display name of the currently authed user.
    private(set) var currentUserName: String = "You"

    private let circlesKey = "circleu.circles.v2"
    private let postsKey = "circleu.circlePosts.v2"
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private let firebase: FirebaseCircleService
    private var isObservingFirebase = false
    private var observedPostCircleIDs: Set<UUID> = []

    init(
        userDefaults: UserDefaults = .standard,
        seedStarterSpaces: Bool = true,
        firebase: FirebaseCircleService? = nil
    ) {
        self.userDefaults = userDefaults
        self.firebase = firebase ?? FirebaseCircleService()
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        load()
        if seedStarterSpaces {
            seedStarterSpacesIfNeeded()
        }
    }

    // MARK: - Backend wiring

    /// Wire up Firebase-backed sync. Called when a user signs in.
    func configureBackend(uid: String, displayName: String) {
        currentUserID = uid
        currentUserName = displayName.isEmpty ? "Friend" : displayName
        startObservingCirclesIfNeeded()
        recomputeViewerDerivedFields()
    }

    /// Tear down Firebase-backed sync. Called when the user signs out.
    func teardownBackend() {
        currentUserID = nil
        currentUserName = "You"
        firebase.stopAll()
        isObservingFirebase = false
        observedPostCircleIDs.removeAll()
    }

    /// Start observing a circle's posts. Safe to call multiple times — second call is a no-op.
    /// Caller is responsible for matching `stopObservingPosts(for:)` when the view disappears.
    func observePosts(for circleID: UUID) {
        guard currentUserID != nil, !observedPostCircleIDs.contains(circleID) else { return }
        observedPostCircleIDs.insert(circleID)
        firebase.observePosts(for: circleID) { [weak self] incomingPosts in
            Task { @MainActor in
                self?.applyRemotePosts(incomingPosts, for: circleID)
            }
        }
    }

    func stopObservingPosts(for circleID: UUID) {
        guard observedPostCircleIDs.remove(circleID) != nil else { return }
        firebase.stopObservingPosts(for: circleID)
    }

    // MARK: - Circles

    func createCircle(name: String, intention: String, emoji: String = "🌱", coverImages: [Data] = []) {
        let cleanName = sanitized(name, fallback: "Reflection Space")
        let cleanIntention = sanitized(intention, fallback: "A gentle space")
        let circle = CircleSpace(
            name: cleanName,
            intention: cleanIntention,
            emoji: emoji,
            members: 1,
            joined: true,
            createdAt: Date(),
            creatorUserID: currentUserID ?? "",
            creatorName: currentUserName,
            coverImages: coverImages
        )
        circles.insert(circle, at: 0)
        saveCircles()
        pushCircle(circle, isCreator: true)
    }

    func joinCircle(_ id: UUID) {
        guard let index = circles.firstIndex(where: { $0.id == id }), !circles[index].joined else { return }
        circles[index].joined = true
        circles[index].members += 1
        saveCircles()
        if let uid = currentUserID {
            Task {
                try? await firebase.setMembership(circleID: id, uid: uid, joined: true)
            }
        }
    }

    /// Toggle the current user's like on a circle. No-op when signed out (likes are uid-keyed).
    func toggleLikeCircle(_ id: UUID) {
        guard let uid = currentUserID, !uid.isEmpty,
              let index = circles.firstIndex(where: { $0.id == id }) else { return }
        let nowLiked: Bool
        if circles[index].likedByUserIDs.contains(uid) {
            circles[index].likedByUserIDs.removeAll { $0 == uid }
            nowLiked = false
        } else {
            circles[index].likedByUserIDs.append(uid)
            nowLiked = true
        }
        saveCircles()
        Task { [firebase] in
            try? await firebase.setCircleLike(circleID: id, uid: uid, liked: nowLiked)
        }
    }

    /// Toggle the current user's bookmark on a circle. No-op when signed out.
    func toggleFavoriteCircle(_ id: UUID) {
        guard let uid = currentUserID, !uid.isEmpty,
              let index = circles.firstIndex(where: { $0.id == id }) else { return }
        let nowFavorited: Bool
        if circles[index].favoritedByUserIDs.contains(uid) {
            circles[index].favoritedByUserIDs.removeAll { $0 == uid }
            nowFavorited = false
        } else {
            circles[index].favoritedByUserIDs.append(uid)
            nowFavorited = true
        }
        saveCircles()
        Task { [firebase] in
            try? await firebase.setCircleFavorite(circleID: id, uid: uid, favorited: nowFavorited)
        }
    }

    /// Update is only permitted on circles the user owns.
    func updateCircle(_ id: UUID, name: String, intention: String, emoji: String? = nil, coverImages: [Data]? = nil) {
        guard let index = circles.firstIndex(where: { $0.id == id }),
              circles[index].isOwnedBy(uid: currentUserID) else { return }
        circles[index].name = sanitized(name, fallback: circles[index].name)
        circles[index].intention = sanitized(intention, fallback: circles[index].intention)
        if let emoji, !emoji.isEmpty { circles[index].emoji = emoji }
        if let coverImages { circles[index].coverImages = coverImages }
        saveCircles()
        pushCircle(circles[index], isCreator: false)
    }

    /// Delete is only permitted on circles the user owns.
    func deleteCircle(_ circle: CircleSpace) {
        guard let owned = circles.first(where: { $0.id == circle.id })?.isOwnedBy(uid: currentUserID), owned else { return }
        circles.removeAll { $0.id == circle.id }
        posts.removeAll { $0.circleID == circle.id }
        saveCircles()
        savePosts()
        Task { try? await firebase.deleteCircle(circle.id) }
    }

    // MARK: - Posts

    func addPost(circleID: UUID, text: String) {
        let clean = sanitized(text, fallback: "")
        guard !clean.isEmpty else { return }
        let post = CirclePost(
            circleID: circleID,
            who: currentUserName.isEmpty ? "You" : currentUserName,
            text: clean,
            authorUserID: currentUserID ?? ""
        )
        posts.insert(post, at: 0)
        savePosts()
        pushPost(post)
    }

    func toggleLikePost(_ id: UUID) {
        guard let index = posts.firstIndex(where: { $0.id == id }) else { return }
        if let uid = currentUserID, !uid.isEmpty {
            if posts[index].likedBy.contains(uid) {
                posts[index].likedBy.removeAll { $0 == uid }
            } else {
                posts[index].likedBy.append(uid)
            }
            posts[index].likes = posts[index].likedBy.count
            posts[index].liked = posts[index].likedBy.contains(uid)
        } else {
            // Local-only legacy fallback
            posts[index].liked.toggle()
            posts[index].likes += posts[index].liked ? 1 : -1
        }
        savePosts()
        pushPost(posts[index])
    }

    func addReply(postID: UUID, text: String) {
        let clean = sanitized(text, fallback: "")
        guard !clean.isEmpty, let index = posts.firstIndex(where: { $0.id == postID }) else { return }
        let reply = PostReply(
            who: currentUserName.isEmpty ? "You" : currentUserName,
            text: clean,
            authorUserID: currentUserID ?? ""
        )
        posts[index].replies.append(reply)
        savePosts()
        pushPost(posts[index])
    }

    func toggleLikeReply(postID: UUID, replyID: UUID) {
        guard let pIndex = posts.firstIndex(where: { $0.id == postID }),
              let rIndex = posts[pIndex].replies.firstIndex(where: { $0.id == replyID }) else { return }
        if let uid = currentUserID, !uid.isEmpty {
            var reply = posts[pIndex].replies[rIndex]
            if reply.likedBy.contains(uid) {
                reply.likedBy.removeAll { $0 == uid }
            } else {
                reply.likedBy.append(uid)
            }
            reply.likes = reply.likedBy.count
            reply.liked = reply.likedBy.contains(uid)
            posts[pIndex].replies[rIndex] = reply
        } else {
            posts[pIndex].replies[rIndex].liked.toggle()
            posts[pIndex].replies[rIndex].likes += posts[pIndex].replies[rIndex].liked ? 1 : -1
        }
        savePosts()
        pushPost(posts[pIndex])
    }

    func deletePost(_ post: CirclePost) {
        guard let owned = posts.first(where: { $0.id == post.id })?.isAuthoredBy(uid: currentUserID), owned else { return }
        posts.removeAll { $0.id == post.id }
        savePosts()
        Task { try? await firebase.deletePost(circleID: post.circleID, postID: post.id) }
    }

    func updatePost(_ id: UUID, text: String) {
        guard let index = posts.firstIndex(where: { $0.id == id }),
              posts[index].isAuthoredBy(uid: currentUserID) else { return }
        let clean = sanitized(text, fallback: posts[index].text)
        posts[index].text = clean
        savePosts()
        pushPost(posts[index])
    }

    func updateReply(postID: UUID, replyID: UUID, text: String) {
        guard let pIndex = posts.firstIndex(where: { $0.id == postID }),
              let rIndex = posts[pIndex].replies.firstIndex(where: { $0.id == replyID }),
              posts[pIndex].replies[rIndex].isAuthoredBy(uid: currentUserID) else { return }
        let clean = sanitized(text, fallback: posts[pIndex].replies[rIndex].text)
        posts[pIndex].replies[rIndex].text = clean
        savePosts()
        pushPost(posts[pIndex])
    }

    func deleteReply(postID: UUID, replyID: UUID) {
        guard let pIndex = posts.firstIndex(where: { $0.id == postID }),
              let reply = posts[pIndex].replies.first(where: { $0.id == replyID }),
              reply.isAuthoredBy(uid: currentUserID) else { return }
        posts[pIndex].replies.removeAll { $0.id == replyID }
        savePosts()
        pushPost(posts[pIndex])
    }

    // MARK: - Journal sharing

    func share(entry: JournalReflectionEntry, to circle: CircleSpace) {
        guard !hasShared(entry: entry, to: circle) else { return }

        let post = CirclePost(
            circleID: circle.id,
            who: currentUserName.isEmpty ? "You" : currentUserName,
            text: entry.displaySummary,
            sourceEntryID: entry.id,
            authorUserID: currentUserID ?? ""
        )
        posts.insert(post, at: 0)
        savePosts()
        pushPost(post)
    }

    func hasShared(entry: JournalReflectionEntry, to circle: CircleSpace) -> Bool {
        posts.contains { $0.circleID == circle.id && $0.sourceEntryID == entry.id }
    }

    // MARK: - Queries

    func posts(for circle: CircleSpace) -> [CirclePost] {
        posts
            .filter { $0.circleID == circle.id }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func lastActivity(for circle: CircleSpace) -> Date? {
        posts(for: circle).first?.createdAt ?? circle.createdAt
    }

    // MARK: - Reset / seed

    func reset(seedStarterSpaces: Bool = false) {
        circles = []
        posts = []
        userDefaults.removeObject(forKey: circlesKey)
        userDefaults.removeObject(forKey: postsKey)

        if seedStarterSpaces {
            seedStarterSpacesIfNeeded()
        }
    }

    func seedDemoData(entries: [JournalReflectionEntry], referenceDate: Date = Date()) {
        seedStarterCircles(referenceDate: referenceDate)
        seedStarterPosts(referenceDate: referenceDate)

        if let latestEntry = entries.sorted(by: { $0.createdAt > $1.createdAt }).first,
           let firstCircle = circles.first {
            posts.insert(
                CirclePost(
                    circleID: firstCircle.id,
                    who: "You",
                    text: latestEntry.displaySummary,
                    createdAt: referenceDate,
                    sourceEntryID: latestEntry.id
                ),
                at: 0
            )
        }

        saveCircles()
        savePosts()
    }

    private func load() {
        if let circleData = userDefaults.data(forKey: circlesKey),
           let savedCircles = try? decoder.decode([CircleSpace].self, from: circleData) {
            circles = savedCircles
        }

        if let postData = userDefaults.data(forKey: postsKey),
           let savedPosts = try? decoder.decode([CirclePost].self, from: postData) {
            posts = savedPosts
        }
    }

    private func seedStarterSpacesIfNeeded() {
        guard circles.isEmpty, userDefaults.data(forKey: circlesKey) == nil else { return }
        seedStarterCircles(referenceDate: Date())
        seedStarterPosts(referenceDate: Date())
        saveCircles()
        savePosts()
    }

    private func seedStarterCircles(referenceDate: Date) {
        let day: TimeInterval = 86_400
        circles = [
            CircleSpace(
                name: "Boundary Builders",
                intention: "Practising saying no with kindness",
                emoji: "🛟",
                members: 128,
                joined: true,
                createdAt: referenceDate.addingTimeInterval(-day * 5)
            ),
            CircleSpace(
                name: "Calm Mornings",
                intention: "Small rituals for a softer start",
                emoji: "🌅",
                members: 86,
                joined: false,
                createdAt: referenceDate.addingTimeInterval(-day * 6)
            ),
            CircleSpace(
                name: "First-Job Nerves",
                intention: "Navigating early-career conversations",
                emoji: "💼",
                members: 203,
                joined: false,
                createdAt: referenceDate.addingTimeInterval(-day * 7)
            )
        ]
    }

    private func seedStarterPosts(referenceDate: Date) {
        let hour: TimeInterval = 3_600
        let day: TimeInterval = 86_400
        guard circles.count >= 2 else { posts = []; return }
        let c1 = circles[0].id
        let c2 = circles[1].id

        posts = [
            CirclePost(
                circleID: c1,
                who: "Anonymous penguin",
                text: "Used the 'bounded yes' line today and it actually worked. Felt proud.",
                createdAt: referenceDate.addingTimeInterval(-hour * 3),
                likes: 12,
                replies: [
                    PostReply(
                        who: "Anonymous penguin",
                        text: "Love this — going to steal that phrasing for my 1:1 tomorrow 🙌",
                        createdAt: referenceDate.addingTimeInterval(-hour * 2),
                        likes: 3
                    )
                ]
            ),
            CirclePost(
                circleID: c1,
                who: "Anonymous penguin",
                text: "Reminder that resting is allowed. Took my slow 10 minutes 🍃",
                createdAt: referenceDate.addingTimeInterval(-day),
                likes: 8
            ),
            CirclePost(
                circleID: c2,
                who: "Anonymous penguin",
                text: "Made tea before checking my phone this morning. Tiny win, big calm.",
                createdAt: referenceDate.addingTimeInterval(-day * 2),
                likes: 5
            )
        ]
    }

    private func saveCircles() {
        guard let data = try? encoder.encode(circles) else { return }
        userDefaults.set(data, forKey: circlesKey)
    }

    private func savePosts() {
        guard let data = try? encoder.encode(posts) else { return }
        userDefaults.set(data, forKey: postsKey)
    }

    private func sanitized(_ value: String, fallback: String) -> String {
        let clean = value
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return fallback }
        return String(clean.prefix(280))
    }

    // MARK: - Firebase sync helpers

    private func startObservingCirclesIfNeeded() {
        guard !isObservingFirebase else { return }
        isObservingFirebase = true
        firebase.observeAllCircles { [weak self] remoteCircles in
            Task { @MainActor in
                self?.applyRemoteCircles(remoteCircles)
            }
        }
    }

    private func applyRemoteCircles(_ remoteCircles: [CircleSpace]) {
        // Server is source of truth for the visible list.
        var merged = remoteCircles
        let uid = currentUserID

        // Preserve any local-only circles (not yet pushed) by keeping circles whose ids
        // aren't represented in the remote set. This avoids dropping just-created circles
        // before the listener round-trips them back.
        let remoteIDs = Set(remoteCircles.map(\.id))
        for local in circles where !remoteIDs.contains(local.id) {
            merged.append(local)
        }

        // Stamp per-viewer `joined` flag from the (now-roundtripped) memberUserIDs array.
        for index in merged.indices {
            merged[index].joined = merged[index].isJoined(by: uid)
        }

        merged.sort { $0.createdAt > $1.createdAt }
        circles = merged
        saveCircles()
    }

    private func applyRemotePosts(_ remotePosts: [CirclePost], for circleID: UUID) {
        // Replace just the posts for this circle; keep posts for other circles untouched.
        var others = posts.filter { $0.circleID != circleID }
        var incoming = remotePosts

        // Stamp viewer-derived fields on incoming posts.
        let uid = currentUserID
        for index in incoming.indices {
            incoming[index].liked = incoming[index].isLiked(by: uid)
            for replyIndex in incoming[index].replies.indices {
                incoming[index].replies[replyIndex].liked = incoming[index].replies[replyIndex].isLiked(by: uid)
            }
        }

        others.append(contentsOf: incoming)
        others.sort { $0.createdAt > $1.createdAt }
        posts = others
        savePosts()
    }

    /// Recompute viewer-derived `liked` flags on every post/reply when the auth user changes.
    private func recomputeViewerDerivedFields() {
        let uid = currentUserID
        for index in posts.indices {
            posts[index].liked = posts[index].isLiked(by: uid)
            for r in posts[index].replies.indices {
                posts[index].replies[r].liked = posts[index].replies[r].isLiked(by: uid)
            }
        }
    }

    private func pushCircle(_ circle: CircleSpace, isCreator: Bool) {
        guard let uid = currentUserID, !uid.isEmpty else { return }
        Task { [firebase] in
            let members = isCreator ? [uid] : []
            try? await firebase.upsertCircle(circle, memberUserIDs: members)
        }
    }

    private func pushPost(_ post: CirclePost) {
        guard let uid = currentUserID, !uid.isEmpty else { return }
        _ = uid
        Task { [firebase] in
            try? await firebase.upsertPost(post)
        }
    }
}
