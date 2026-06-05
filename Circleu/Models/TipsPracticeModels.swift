import Foundation

enum TipsPracticeScene: String, Codable, CaseIterable, Equatable {
    case workplace
    case family
    case friendship
    case romantic
    case custom

    var title: String {
        switch self {
        case .workplace:
            "Workplace"
        case .family:
            "Family"
        case .friendship:
            "Friendship"
        case .romantic:
            "Romantic"
        case .custom:
            "Custom"
        }
    }

    var icon: String {
        switch self {
        case .workplace:
            "briefcase.fill"
        case .family:
            "house.fill"
        case .friendship:
            "person.2.fill"
        case .romantic:
            "heart.fill"
        case .custom:
            "plus"
        }
    }

    func displayTitle(customScene: String?) -> String {
        guard self == .custom else { return title }
        let clean = customScene?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return clean.isEmpty ? "Custom" : clean
    }
}

enum TipsPracticeTone: String, Codable, CaseIterable, Equatable {
    case soft
    case diplomatic
    case firm

    var title: String {
        switch self {
        case .soft:
            "Soft"
        case .diplomatic:
            "Diplomatic"
        case .firm:
            "Firm"
        }
    }

    var sliderValue: Double {
        switch self {
        case .soft:
            0
        case .diplomatic:
            0.5
        case .firm:
            1
        }
    }

    static func fromSliderValue(_ value: Double) -> TipsPracticeTone {
        if value < 0.33 { return .soft }
        if value < 0.72 { return .diplomatic }
        return .firm
    }
}

enum TipsPracticeRole: String, Codable, Equatable {
    case user
    case coach
    case simulatedPerson
}

struct TipsPracticeTurn: Identifiable, Codable, Equatable {
    let id: UUID
    var role: TipsPracticeRole
    var label: String
    var text: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        role: TipsPracticeRole,
        label: String,
        text: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.label = label
        self.text = text
        self.createdAt = createdAt
    }
}

struct TipsCoachReplyOption: Identifiable, Codable, Equatable {
    let id: UUID
    var label: String
    var text: String

    init(id: UUID = UUID(), label: String, text: String) {
        self.id = id
        self.label = label
        self.text = text
    }
}

struct TipsCoachOutput: Codable, Equatable {
    var suggestedPhrasing: String
    var whyItWorks: String
    var simulatedReply: String
    var roomReading: String
    var replyOptions: [TipsCoachReplyOption]
}

struct TipsPracticeSession: Identifiable, Codable, Equatable {
    let id: UUID
    var createdAt: Date
    var updatedAt: Date
    var originalMessage: String
    var scene: TipsPracticeScene
    var customScene: String?
    var tone: TipsPracticeTone
    var situation: String
    var turns: [TipsPracticeTurn]
    var coachOutput: TipsCoachOutput
    var attachedImageCount: Int

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        originalMessage: String,
        scene: TipsPracticeScene,
        customScene: String? = nil,
        tone: TipsPracticeTone,
        situation: String,
        turns: [TipsPracticeTurn],
        coachOutput: TipsCoachOutput,
        attachedImageCount: Int = 0
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.originalMessage = originalMessage
        self.scene = scene
        self.customScene = customScene
        self.tone = tone
        self.situation = situation
        self.turns = turns
        self.coachOutput = coachOutput
        self.attachedImageCount = attachedImageCount
    }

    var sceneTitle: String {
        scene.displayTitle(customScene: customScene)
    }
}
