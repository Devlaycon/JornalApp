import Combine
import Foundation

/// Drives the Profile screen's points, daily quests, rewards log, and record history.
/// Points accumulate from daily quests and determine the user's level.
@MainActor
final class RewardsStore: ObservableObject {
    /// Total accumulated reward points (drives level).
    @Published private(set) var points: Int = 0
    /// Recent reward log (most recent first, capped).
    @Published private(set) var pointsLog: [PointEntry] = []
    /// questId -> day-key it was last completed, so daily quests reset each day.
    @Published private(set) var questAwards: [String: String] = [:]
    /// Record-history timeline (most recent first, capped).
    @Published private(set) var activity: [ActivityEvent] = []

    private let storageKey = "circleu.rewards.v1"
    private let userDefaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(userDefaults: UserDefaults = .standard, seedIfEmpty: Bool = true) {
        self.userDefaults = userDefaults
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
        if !load() && seedIfEmpty {
            seedStarter()
            save()
        }
    }

    // MARK: - Derived

    var level: Int { min(points / 100 + 1, 12) }
    var intoLevel: Int { points % 100 }
    var nextLevel: Int { min(level + 1, 12) }

    func isDone(_ questID: String) -> Bool {
        questAwards[questID] == Self.dayKey()
    }

    // MARK: - Mutations

    /// Award a quest's points unless it was already earned today.
    func awardPoints(questID: String, label: String, points pointValue: Int, icon: String) {
        guard questAwards[questID] != Self.dayKey() else { return }
        points += pointValue
        questAwards[questID] = Self.dayKey()
        pointsLog.insert(PointEntry(label: label, points: pointValue, icon: icon), at: 0)
        pointsLog = Array(pointsLog.prefix(50))
        save()
    }

    func claimDailyLogin() {
        awardPoints(questID: "daily_login", label: "Daily check-in", points: 2, icon: "☀️")
    }

    func pushActivity(type: ActivityType, title: String, keyword: String, refID: UUID? = nil) {
        activity.insert(
            ActivityEvent(type: type, title: title, keyword: keyword, refID: refID),
            at: 0
        )
        activity = Array(activity.prefix(100))
        save()
    }

    func resetToSeed() {
        seedStarter()
        save()
    }

    func reset() {
        points = 0
        pointsLog = []
        questAwards = [:]
        activity = []
        userDefaults.removeObject(forKey: storageKey)
    }

    // MARK: - Day key

    static func dayKey(_ date: Date = Date()) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)"
    }

    // MARK: - Persistence

    private struct Persisted: Codable {
        var points: Int
        var pointsLog: [PointEntry]
        var questAwards: [String: String]
        var activity: [ActivityEvent]
    }

    @discardableResult
    private func load() -> Bool {
        guard let data = userDefaults.data(forKey: storageKey),
              let saved = try? decoder.decode(Persisted.self, from: data) else {
            return false
        }
        points = saved.points
        pointsLog = saved.pointsLog
        questAwards = saved.questAwards
        activity = saved.activity
        return true
    }

    private func save() {
        let snapshot = Persisted(
            points: points,
            pointsLog: pointsLog,
            questAwards: questAwards,
            activity: activity
        )
        guard let data = try? encoder.encode(snapshot) else { return }
        userDefaults.set(data, forKey: storageKey)
    }

    // MARK: - Seed

    private func seedStarter(referenceDate: Date = Date()) {
        let day: TimeInterval = 86_400
        points = 35
        questAwards = [:]
        pointsLog = [
            PointEntry(label: "Daily reflection", points: 8, icon: "📓", createdAt: referenceDate.addingTimeInterval(-day)),
            PointEntry(label: "Communication tip", points: 5, icon: "💬", createdAt: referenceDate.addingTimeInterval(-day * 2)),
            PointEntry(label: "Joined a circle", points: 4, icon: "🫂", createdAt: referenceDate.addingTimeInterval(-day * 5))
        ]
        activity = [
            ActivityEvent(type: .reflect, title: "Holding my ground at work", keyword: "Brave · boundary", createdAt: referenceDate.addingTimeInterval(-day)),
            ActivityEvent(type: .tips, title: "Workplace · Manager", keyword: "capacity · diplomatic", createdAt: referenceDate.addingTimeInterval(-day * 2)),
            ActivityEvent(type: .reflect, title: "A quiet, steady evening", keyword: "Calm · rest", createdAt: referenceDate.addingTimeInterval(-day * 3)),
            ActivityEvent(type: .communityJoin, title: "Boundary Builders", keyword: "joined", createdAt: referenceDate.addingTimeInterval(-day * 5))
        ]
    }
}
