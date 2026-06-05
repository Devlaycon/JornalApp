import Combine
import Foundation

@MainActor
final class CircleStore: ObservableObject {
    @Published private(set) var circles: [CircleSpace] = []
    @Published private(set) var posts: [CirclePost] = []

    private let circlesKey = "circleu.circles.v1"
    private let postsKey = "circleu.circlePosts.v1"
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

    func createCircle(name: String, intention: String) {
        let cleanName = sanitized(name, fallback: "Reflection Space")
        let cleanIntention = sanitized(intention, fallback: "A private place to organize support notes.")
        circles.insert(CircleSpace(name: cleanName, intention: cleanIntention), at: 0)
        saveCircles()
    }

    func updateCircle(_ circle: CircleSpace, name: String, intention: String) {
        guard let index = circles.firstIndex(where: { $0.id == circle.id }) else { return }
        circles[index].name = sanitized(name, fallback: circle.name)
        circles[index].intention = sanitized(intention, fallback: circle.intention)
        saveCircles()
    }

    func addNote(circle: CircleSpace, title: String, body: String) {
        let cleanTitle = sanitized(title, fallback: "Support note")
        let cleanBody = sanitized(body, fallback: "A small reminder to return to.")
        posts.insert(
            CirclePost(
                circleID: circle.id,
                title: cleanTitle,
                body: cleanBody
            ),
            at: 0
        )
        savePosts()
    }

    func updatePost(_ post: CirclePost, title: String, body: String) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        posts[index].title = sanitized(title, fallback: post.title)
        posts[index].body = sanitized(body, fallback: post.body)
        savePosts()
    }

    func share(entry: JournalReflectionEntry, to circle: CircleSpace) {
        guard !hasShared(entry: entry, to: circle) else { return }

        posts.insert(
            CirclePost(
                circleID: circle.id,
                title: entry.displayTitle,
                body: "\(entry.displaySummary)\n\nQuest: \(entry.displayQuest)",
                sourceEntryID: entry.id
            ),
            at: 0
        )
        savePosts()
    }

    func hasShared(entry: JournalReflectionEntry, to circle: CircleSpace) -> Bool {
        posts.contains { $0.circleID == circle.id && $0.sourceEntryID == entry.id }
    }

    func posts(for circle: CircleSpace) -> [CirclePost] {
        posts
            .filter { $0.circleID == circle.id }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func lastActivity(for circle: CircleSpace) -> Date? {
        posts(for: circle).first?.createdAt ?? circle.createdAt
    }

    func deleteCircle(_ circle: CircleSpace) {
        circles.removeAll { $0.id == circle.id }
        posts.removeAll { $0.circleID == circle.id }
        saveCircles()
        savePosts()
    }

    func deletePost(_ post: CirclePost) {
        posts.removeAll { $0.id == post.id }
        savePosts()
    }

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
        let confidenceCircle = CircleSpace(
            name: "Class Confidence Community",
            intention: "Keep reflection cards that help before speaking in class.",
            createdAt: Calendar.current.date(byAdding: .day, value: -4, to: referenceDate) ?? referenceDate
        )

        let tipsCircle = CircleSpace(
            name: "Daily Voice Tips",
            intention: "Collect small actions and notes that make expression feel easier.",
            createdAt: Calendar.current.date(byAdding: .day, value: -3, to: referenceDate) ?? referenceDate
        )

        circles = [confidenceCircle, tipsCircle]

        posts = [
            CirclePost(
                circleID: confidenceCircle.id,
                createdAt: Calendar.current.date(byAdding: .day, value: -2, to: referenceDate) ?? referenceDate,
                title: "Before class reminder",
                body: "Pause, breathe, and ask one clear question. Small public tips counts."
            ),
            CirclePost(
                circleID: tipsCircle.id,
                createdAt: Calendar.current.date(byAdding: .hour, value: -6, to: referenceDate) ?? referenceDate,
                title: "Two-minute voice warmup",
                body: "Read one note out loud and listen for the clearest sentence."
            )
        ]

        if let latestEntry = entries.sorted(by: { $0.createdAt > $1.createdAt }).first {
            posts.insert(
                CirclePost(
                    circleID: tipsCircle.id,
                    createdAt: referenceDate,
                    title: latestEntry.displayTitle,
                    body: "\(latestEntry.displaySummary)\n\nQuest: \(latestEntry.displayQuest)",
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

        circles = [
            CircleSpace(
                name: "Reflection Tips Community",
                intention: "Save reflection takeaways you want to revisit before speaking or studying."
            ),
            CircleSpace(
                name: "Encouragement Community",
                intention: "Keep short support notes for days when you need a steadier voice."
            )
        ]
        saveCircles()
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
        return String(clean.prefix(180))
    }
}
