import Foundation

struct BackendSyncSnapshot: Codable, Equatable {
    var userID: String
    var generatedAt: Date
    var journalEntries: [JournalReflectionEntry]
    var quests: [Quest]
    var circles: [CircleSpace]
    var circlePosts: [CirclePost]
    var aiSessions: [AIReflectionSession]

    init(
        userID: String,
        generatedAt: Date = Date(),
        journalEntries: [JournalReflectionEntry],
        quests: [Quest],
        circles: [CircleSpace],
        circlePosts: [CirclePost],
        aiSessions: [AIReflectionSession]
    ) {
        self.userID = userID
        self.generatedAt = generatedAt
        self.journalEntries = journalEntries
        self.quests = quests
        self.circles = circles
        self.circlePosts = circlePosts
        self.aiSessions = aiSessions
    }

    var counts: BackendSyncCounts {
        BackendSyncCounts(snapshot: self)
    }

    var isEmpty: Bool {
        counts == .zero
    }
}

struct BackendSyncCounts: Codable, Equatable {
    var journalEntryCount: Int
    var questCount: Int
    var circleCount: Int
    var circlePostCount: Int
    var aiSessionCount: Int

    static let zero = BackendSyncCounts(
        journalEntryCount: 0,
        questCount: 0,
        circleCount: 0,
        circlePostCount: 0,
        aiSessionCount: 0
    )

    init(
        journalEntryCount: Int,
        questCount: Int,
        circleCount: Int,
        circlePostCount: Int,
        aiSessionCount: Int
    ) {
        self.journalEntryCount = journalEntryCount
        self.questCount = questCount
        self.circleCount = circleCount
        self.circlePostCount = circlePostCount
        self.aiSessionCount = aiSessionCount
    }

    init(snapshot: BackendSyncSnapshot) {
        self.init(
            journalEntryCount: snapshot.journalEntries.count,
            questCount: snapshot.quests.count,
            circleCount: snapshot.circles.count,
            circlePostCount: snapshot.circlePosts.count,
            aiSessionCount: snapshot.aiSessions.count
        )
    }
}

enum BackendSyncScope: String, Codable, Equatable, CaseIterable {
    case journalEntries
    case quests
    case circles
    case circlePosts
    case aiSessions
}

struct BackendSyncResult: Codable, Equatable {
    var syncedAt: Date
    var uploadedCounts: BackendSyncCounts
    var downloadedCounts: BackendSyncCounts
    var failedScopes: [BackendSyncScope]

    init(
        syncedAt: Date = Date(),
        uploadedCounts: BackendSyncCounts = .zero,
        downloadedCounts: BackendSyncCounts = .zero,
        failedScopes: [BackendSyncScope] = []
    ) {
        self.syncedAt = syncedAt
        self.uploadedCounts = uploadedCounts
        self.downloadedCounts = downloadedCounts
        self.failedScopes = failedScopes
    }

    var didSucceed: Bool {
        failedScopes.isEmpty
    }
}

struct AnalyticsEvent: Codable, Equatable {
    var name: String
    var properties: [String: String]
    var createdAt: Date

    init(name: String, properties: [String: String] = [:], createdAt: Date = Date()) {
        let cleanName = name
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: "_")
            .lowercased()
        self.name = cleanName.isEmpty ? "local_event" : String(cleanName.prefix(80))
        self.properties = properties.reduce(into: [:]) { result, item in
            let key = item.key.trimmingCharacters(in: .whitespacesAndNewlines)
            let value = item.value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty, !value.isEmpty else { return }
            result[String(key.prefix(80))] = String(value.prefix(240))
        }
        self.createdAt = createdAt
    }
}

protocol ReflectionModelProvider {
    var providerName: String { get }
    var isAvailable: Bool { get }
    var availabilityReason: String? { get }
    var supportsOnDeviceProcessing: Bool { get }
}

protocol ReflectionSyncing {
    func sync(_ snapshot: BackendSyncSnapshot) async throws -> BackendSyncResult
}

protocol UserIdentityProviding {
    var localUserID: String { get }
    var displayName: String { get }
}

protocol AnalyticsTracking {
    func track(_ event: AnalyticsEvent)
}

struct LocalReflectionModelProvider: ReflectionModelProvider {
    let providerName = "Local"
    let isAvailable = true
    let availabilityReason: String? = nil
    let supportsOnDeviceProcessing = true
}

struct NoOpReflectionSyncer: ReflectionSyncing {
    func sync(_ snapshot: BackendSyncSnapshot) async throws -> BackendSyncResult {
        BackendSyncResult()
    }
}

struct LocalUserIdentityProvider: UserIdentityProviding {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var localUserID: String {
        let key = "circleu.localUserID"

        if let existingID = defaults.string(forKey: key) {
            return existingID
        }

        let newID = UUID().uuidString
        defaults.set(newID, forKey: key)
        return newID
    }

    var displayName: String {
        let savedName = defaults
            .string(forKey: "circleu.profile.displayName.v1")?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return savedName.isEmpty ? "Friend" : savedName
    }
}

struct NoOpAnalyticsTracker: AnalyticsTracking {
    func track(_ event: AnalyticsEvent) {}
}

extension AnalyticsTracking {
    func track(event: String, properties: [String: String] = [:]) {
        track(AnalyticsEvent(name: event, properties: properties))
    }
}
