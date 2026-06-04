import Foundation

protocol ReflectionModelProvider {
    var providerName: String { get }
    var isAvailable: Bool { get }
}

protocol ReflectionSyncing {
    func syncIfNeeded() async
}

protocol UserIdentityProviding {
    var localUserID: String { get }
    var displayName: String { get }
}

protocol AnalyticsTracking {
    func track(event: String, properties: [String: String])
}

struct LocalReflectionModelProvider: ReflectionModelProvider {
    let providerName = "Local"
    let isAvailable = true
}

struct NoOpReflectionSyncer: ReflectionSyncing {
    func syncIfNeeded() async {}
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
        defaults.string(forKey: "circleu.displayName") ?? "Friend"
    }
}

struct NoOpAnalyticsTracker: AnalyticsTracking {
    func track(event: String, properties: [String: String] = [:]) {}
}
