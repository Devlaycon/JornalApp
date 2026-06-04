import Foundation

struct TranscriptQuality: Equatable {
    let wordCount: Int
    let characterCount: Int
    let isReady: Bool
    let guidance: String

    static func evaluate(_ transcript: String) -> TranscriptQuality {
        let clean = transcript
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let words = clean.split(separator: " ")
        let wordCount = words.count
        let characterCount = clean.count

        if clean.isEmpty {
            return TranscriptQuality(
                wordCount: 0,
                characterCount: 0,
                isReady: false,
                guidance: "Add a few words before finishing."
            )
        }

        if wordCount < 8 || characterCount < 32 {
            return TranscriptQuality(
                wordCount: wordCount,
                characterCount: characterCount,
                isReady: false,
                guidance: "Add one feeling, one moment, and what you want to understand."
            )
        }

        return TranscriptQuality(
            wordCount: wordCount,
            characterCount: characterCount,
            isReady: true,
            guidance: "Ready for AI reflection."
        )
    }
}
