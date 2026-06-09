import Combine
import Foundation

@MainActor
final class UserProfileStore: ObservableObject {
    @Published var displayName: String {
        didSet { saveDisplayName(displayName) }
    }

    @Published var dailyPromptIndex: Int {
        didSet { userDefaults.set(dailyPromptIndex, forKey: dailyPromptIndexKey) }
    }

    private let userDefaults: UserDefaults
    private let displayNameKey = "circleu.profile.displayName.v1"
    private let dailyPromptIndexKey = "circleu.profile.dailyPromptIndex.v1"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        let savedName = userDefaults.string(forKey: displayNameKey) ?? ""
        displayName = savedName.trimmingCharacters(in: .whitespacesAndNewlines)
        dailyPromptIndex = userDefaults.integer(forKey: dailyPromptIndexKey)
    }

    var firstName: String {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.split(separator: " ").first else { return "friend" }
        return String(first)
    }

    var hasDisplayName: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func updateDisplayName(_ value: String) {
        displayName = sanitizedName(value)
    }

    func reset() {
        displayName = ""
        dailyPromptIndex = 0
        userDefaults.removeObject(forKey: displayNameKey)
        userDefaults.removeObject(forKey: dailyPromptIndexKey)
    }

    func seedDemoProfile() {
        updateDisplayName("Mike")
        dailyPromptIndex = 1
    }

    func advanceDailyPrompt(totalPrompts: Int) {
        guard totalPrompts > 0 else { return }
        dailyPromptIndex = (dailyPromptIndex + 1) % totalPrompts
    }

    func summaryText(progress: AppProgressSnapshot, circleCount: Int, supportPostCount: Int) -> String {
        """
        Circleu Local Profile

        Name: \(displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Friend" : displayName)
        Level: \(progress.level)
        XP: \(progress.xp)
        Saved reflections: \(progress.entryCount)
        Current streak: \(progress.streak)
        Most common mood: \(progress.mostCommonEmotion)
        Communities: \(circleCount)
        Support posts: \(supportPostCount)
        Completed quests: \(progress.completedQuestCount)

        Circleu stores this data locally on this iPhone.
        """
    }

    private func sanitizedName(_ value: String) -> String {
        let collapsed = value
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
        return String(collapsed.prefix(32))
    }

    private func saveDisplayName(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        userDefaults.set(trimmed, forKey: displayNameKey)
    }
}
