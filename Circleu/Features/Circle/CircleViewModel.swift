import Combine
import Foundation

@MainActor
final class CircleViewModel: ObservableObject {
    @Published var selectedCircle: CircleSpace?
    @Published var showCreateCommunity = false

    func open(_ circle: CircleSpace) {
        selectedCircle = circle
    }

    func showCreateSheet() {
        showCreateCommunity = true
    }

    static func timeAgo(_ date: Date, now: Date = Date()) -> String {
        let mins = Int(now.timeIntervalSince(date) / 60)
        if mins < 1 { return "just now" }
        if mins < 60 { return "\(mins)m ago" }
        let hrs = mins / 60
        if hrs < 24 { return "\(hrs)h ago" }
        let days = hrs / 24
        if days == 1 { return "yesterday" }
        return "\(days)d ago"
    }
}
