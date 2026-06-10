import Combine
import Foundation

@MainActor
final class CircleStore: ObservableObject {
    @Published private(set) var circles: [CircleSpace] = []
    @Published private(set) var posts: [CirclePost] = []

    private let circlesKey = "circleu.circles.v2"
    private let postsKey = "circleu.circlePosts.v2"
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(userDefaults: UserDefaults = .standard, seedStarterSpaces: Bool = true) {
        self.userDefaults = userDefaults
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        load()
        if seedStarterSpaces {
            seedStarterSpacesIfNeeded()
        }
    }

    // MARK: - Circles

    func createCircle(name: String, intention: String, emoji: String = "🌱", coverImages: [Data] = []) {
        let cleanName = sanitized(name, fallback: "Reflection Space")
        let cleanIntention = sanitized(intention, fallback: "A gentle space")
        circles.insert(
            CircleSpace(
                name: cleanName,
                intention: cleanIntention,
                emoji: emoji,
                members: 1,
                joined: true,
                isOwnedByMe: true,
                coverImages: coverImages
            ),
            at: 0
        )
        saveCircles()
    }

    func joinCircle(_ id: UUID) {
        guard let index = circles.firstIndex(where: { $0.id == id }), !circles[index].joined else { return }
        circles[index].joined = true
        circles[index].members += 1
        saveCircles()
    }

    /// Update is only permitted on circles the user owns.
    func updateCircle(_ id: UUID, name: String, intention: String, emoji: String? = nil, coverImages: [Data]? = nil) {
        guard let index = circles.firstIndex(where: { $0.id == id }),
              circles[index].isOwnedByMe else { return }
        circles[index].name = sanitized(name, fallback: circles[index].name)
        circles[index].intention = sanitized(intention, fallback: circles[index].intention)
        if let emoji, !emoji.isEmpty { circles[index].emoji = emoji }
        if let coverImages { circles[index].coverImages = coverImages }
        saveCircles()
    }

    /// Delete is only permitted on circles the user owns.
    func deleteCircle(_ circle: CircleSpace) {
        guard let owned = circles.first(where: { $0.id == circle.id })?.isOwnedByMe, owned else { return }
        circles.removeAll { $0.id == circle.id }
        posts.removeAll { $0.circleID == circle.id }
        saveCircles()
        savePosts()
    }

    // MARK: - Posts

    func addPost(circleID: UUID, text: String) {
        let clean = sanitized(text, fallback: "")
        guard !clean.isEmpty else { return }
        posts.insert(CirclePost(circleID: circleID, who: "You", text: clean), at: 0)
        savePosts()
    }

    func toggleLikePost(_ id: UUID) {
        guard let index = posts.firstIndex(where: { $0.id == id }) else { return }
        posts[index].liked.toggle()
        posts[index].likes += posts[index].liked ? 1 : -1
        savePosts()
    }

    func addReply(postID: UUID, text: String) {
        let clean = sanitized(text, fallback: "")
        guard !clean.isEmpty, let index = posts.firstIndex(where: { $0.id == postID }) else { return }
        posts[index].replies.append(PostReply(who: "You", text: clean))
        savePosts()
    }

    func toggleLikeReply(postID: UUID, replyID: UUID) {
        guard let pIndex = posts.firstIndex(where: { $0.id == postID }),
              let rIndex = posts[pIndex].replies.firstIndex(where: { $0.id == replyID }) else { return }
        posts[pIndex].replies[rIndex].liked.toggle()
        posts[pIndex].replies[rIndex].likes += posts[pIndex].replies[rIndex].liked ? 1 : -1
        savePosts()
    }

    func deletePost(_ post: CirclePost) {
        guard let owned = posts.first(where: { $0.id == post.id })?.isMine, owned else { return }
        posts.removeAll { $0.id == post.id }
        savePosts()
    }

    func updatePost(_ id: UUID, text: String) {
        guard let index = posts.firstIndex(where: { $0.id == id }), posts[index].isMine else { return }
        let clean = sanitized(text, fallback: posts[index].text)
        posts[index].text = clean
        savePosts()
    }

    func updateReply(postID: UUID, replyID: UUID, text: String) {
        guard let pIndex = posts.firstIndex(where: { $0.id == postID }),
              let rIndex = posts[pIndex].replies.firstIndex(where: { $0.id == replyID }),
              posts[pIndex].replies[rIndex].isMine else { return }
        let clean = sanitized(text, fallback: posts[pIndex].replies[rIndex].text)
        posts[pIndex].replies[rIndex].text = clean
        savePosts()
    }

    func deleteReply(postID: UUID, replyID: UUID) {
        guard let pIndex = posts.firstIndex(where: { $0.id == postID }),
              let reply = posts[pIndex].replies.first(where: { $0.id == replyID }),
              reply.isMine else { return }
        posts[pIndex].replies.removeAll { $0.id == replyID }
        savePosts()
    }

    // MARK: - Journal sharing

    func share(entry: JournalReflectionEntry, to circle: CircleSpace) {
        guard !hasShared(entry: entry, to: circle) else { return }

        posts.insert(
            CirclePost(
                circleID: circle.id,
                who: "You",
                text: entry.displaySummary,
                sourceEntryID: entry.id
            ),
            at: 0
        )
        savePosts()
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
}
