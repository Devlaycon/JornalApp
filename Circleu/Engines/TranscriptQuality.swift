import Foundation

struct TranscriptQuality: Equatable {
    let wordCount: Int
    let characterCount: Int
    let isReady: Bool
    let guidance: String

    static func evaluate(_ transcript: String) -> TranscriptQuality {
        let clean = cleanedTranscript(transcript)

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

        if isRoughLowSignal(clean) {
            return TranscriptQuality(
                wordCount: wordCount,
                characterCount: characterCount,
                isReady: false,
                guidance: "Try again with one real moment, one feeling, and words you would be comfortable saving."
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

    static func cleanedTranscript(_ transcript: String) -> String {
        transcript
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func isRoughLowSignal(_ transcript: String) -> Bool {
        let words = normalizedWords(transcript)
        guard words.count >= 5 else { return false }

        let roughWordCount = words.filter { roughWords.contains($0) }.count
        guard roughWordCount > 0 else { return false }

        let fillerCount = words.filter { fillerWords.contains($0) }.count
        let fillerRatio = Double(fillerCount) / Double(words.count)
        let roughRatio = Double(roughWordCount) / Double(words.count)

        return fillerRatio >= 0.35 || roughRatio >= 0.20
    }

    static func containsRoughLanguage(_ transcript: String) -> Bool {
        normalizedWords(transcript).contains { roughWords.contains($0) }
    }

    private static func normalizedWords(_ transcript: String) -> [String] {
        cleanedTranscript(transcript)
            .lowercased()
            .split(separator: " ")
            .map { word in
                word.filter { $0.isLetter || $0.isNumber }
            }
            .filter { !$0.isEmpty }
    }

    private static let roughWords: Set<String> = [
        "fuck",
        "fucking",
        "fucked",
        "shit",
        "shitty",
        "bitch",
        "damn"
    ]

    private static let fillerWords: Set<String> = [
        "hello",
        "hi",
        "hey",
        "um",
        "uh",
        "yeah",
        "okay",
        "ok",
        "test",
        "testing"
    ]
}
