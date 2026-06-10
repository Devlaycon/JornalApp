import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

enum ReflectionEngineError: LocalizedError {
    case emptyTranscript
    case appleIntelligenceUnavailable(String)
    case invalidModelResponse

    var errorDescription: String? {
        switch self {
        case .emptyTranscript:
            "I need a few spoken words before I can create a reflection."
        case .appleIntelligenceUnavailable(let reason):
            reason
        case .invalidModelResponse:
            "The AI response could not be read. Please try again."
        }
    }
}

protocol ReflectionAnalyzing {
    var displayName: String { get }
    var availabilityMessage: String? { get }
    func analyze(transcript: String, durationSeconds: Int) async throws -> AIReflectionResult
}

enum ReflectionEngineFactory {
    static func makeDefault() -> any ReflectionAnalyzing {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return AppleIntelligenceReflectionEngine(fallback: LocalReflectionEngine())
        }
        #endif

        return LocalReflectionEngine()
    }
}

enum ReflectionPromptContent {
    static let instructions = """
    You are Circleu, a gentle reflection companion for personal voice journaling.
    Be warm, practical, concise, and non-clinical.
    Do not diagnose mental health conditions.
    Do not repeat profanity or insults from the transcript.
    Return only valid JSON.
    """

    static func prompt(transcript: String, durationSeconds: Int) -> String {
        """
        Analyze this voice journal transcript and generate one reflection.

        Requirements:
        - Anchor every field to the transcript.
        - Avoid generic praise.
        - Keep the tone supportive and grounded.
        - Use short app-ready copy.
        - If the transcript is mostly filler, repeated words, or rough language, do not pretend it is a complete reflection. Gently say the check-in needs a clearer real moment.
        - If the transcript includes coherent rough, angry, or hostile language, coach the user toward a calmer boundary or repair step instead of praising it as thoughtful.
        - Do not repeat profanity, insults, slurs, or hostile phrases in any field.
        - summary should name what happened, what the user felt, and why it mattered.
        - insight should name one pattern, tension, or need.
        - quote should be original, plainspoken, and specific to this reflection.
        - expressionMoment should be a short clean phrase from the transcript. If the only memorable phrase contains profanity or filler, write a clean paraphrase instead.
        - suggestedQuest should be one small concrete next action.
        - confidenceScore must be between 0.0 and 1.0.
        - Return exactly this JSON shape with string values except confidenceScore:
        {
          "title": "",
          "emotion": "",
          "summary": "",
          "insight": "",
          "expressionMoment": "",
          "quote": "",
          "confidenceScore": 0.0,
          "suggestedQuest": ""
        }

        Duration seconds: \(durationSeconds)
        Transcript:
        \(transcript)
        """
    }
}

private enum LocalReflectionKind {
    case roughLowSignal
    case roughLanguage
    case boundaryConflict
    case overwhelm
    case anxiety
    case pride
    case tender
    case neutral
}

struct LocalReflectionEngine: ReflectionAnalyzing {
    let displayName = "Local test engine"
    let availabilityMessage: String? = "Apple Intelligence is not available, so Circleu is using a local test reflection."

    func analyze(transcript: String, durationSeconds: Int) async throws -> AIReflectionResult {
        let cleanTranscript = TranscriptQuality.cleanedTranscript(transcript)
        guard !cleanTranscript.isEmpty else { throw ReflectionEngineError.emptyTranscript }

        let kind = reflectionKind(for: cleanTranscript)
        if kind == .roughLowSignal {
            return roughLowSignalReflection(durationSeconds: durationSeconds)
        }

        if kind == .roughLanguage {
            return roughLanguageReflection()
        }

        let profile = reflectionProfile(for: kind)
        let lowercased = cleanTranscript.lowercased()
        let summary = summarize(cleanTranscript)

        return AIReflectionResult(
            title: profile.title,
            emotion: profile.emotion,
            summary: summary,
            insight: profile.insight,
            expressionMoment: expressionMoment(from: cleanTranscript, fallback: profile.expressionMoment),
            quote: profile.quote,
            confidenceScore: profile.score,
            suggestedQuest: suggestedQuest(for: lowercased, durationSeconds: durationSeconds, kind: kind)
        )
    }

    private func reflectionKind(for cleanTranscript: String) -> LocalReflectionKind {
        if TranscriptQuality.isRoughLowSignal(cleanTranscript) { return .roughLowSignal }
        if TranscriptQuality.containsRoughLanguage(cleanTranscript) { return .roughLanguage }
        let text = cleanTranscript.lowercased()
        if containsAny(["boundary", "interrupted", "crossed a line", "need space", "angry", "frustrated", "conflict"], in: text) { return .boundaryConflict }
        if containsAny(["overwhelmed", "too much", "too many", "burned out", "burnt out", "exhausted"], in: text) { return .overwhelm }
        if containsAny(["nervous", "anxious", "scared", "afraid", "worried", "panic"], in: text) { return .anxiety }
        if containsAny(["proud", "grateful", "happy", "relieved", "excited", "win"], in: text) { return .pride }
        if containsAny(["sad", "lonely", "hurt", "miss", "tired", "cry"], in: text) { return .tender }
        return .neutral
    }

    private func roughLowSignalReflection(durationSeconds: Int) -> AIReflectionResult {
        AIReflectionResult(
            title: "Try that check-in again",
            emotion: "Unclear",
            summary: "This recording sounds more like a rough test or vent than a clear reflection moment.",
            insight: "Strong words can point to real emotion, but Circleu needs one specific situation to give useful feedback.",
            expressionMoment: "You may have been testing the recording or letting off steam.",
            quote: "A clearer moment gives your reflection something kind to hold.",
            confidenceScore: 0.32,
            suggestedQuest: "Record again with one real moment, one feeling, and one thing you want to understand."
        )
    }

    private func roughLanguageReflection() -> AIReflectionResult {
        AIReflectionResult(
            title: "Pause before you respond",
            emotion: "Heated",
            summary: "There is strong emotion in this check-in, and it may help to slow the response before choosing words.",
            insight: "Rough language often points to a boundary, hurt, or frustration. Naming the boundary clearly will land better than matching the intensity.",
            expressionMoment: "You noticed the words might be too sharp.",
            quote: "A steady boundary can be stronger than a sharper sentence.",
            confidenceScore: 0.58,
            suggestedQuest: "Write one calm sentence that names the boundary without attacking the person."
        )
    }

    private func reflectionProfile(for kind: LocalReflectionKind) -> LocalReflectionProfile {
        switch kind {
        case .boundaryConflict:
            return LocalReflectionProfile(
                title: "Name the boundary clearly",
                emotion: "Protective",
                insight: "A boundary is easier to hear when it names the moment, the impact, and the need without attacking the person.",
                expressionMoment: "You noticed a line that matters.",
                quote: "Clear does not have to become harsh.",
                score: 0.76
            )
        case .overwhelm:
            return LocalReflectionProfile(
                title: "Make the load smaller",
                emotion: "Overloaded",
                insight: "Too many demands arrived at once, so the useful move is to shrink the next step instead of solving everything.",
                expressionMoment: "Everything arrived at once.",
                quote: "Small enough is often the way back to steady.",
                score: 0.75
            )
        case .anxiety:
            return LocalReflectionProfile(
                title: "You met uncertainty with courage",
                emotion: "Brave",
                insight: "There is worry in this check-in, but there is also motion. Naming the fear gives you a clearer place to begin.",
                expressionMoment: "You named what felt uncertain instead of pushing it away.",
                quote: "Courage often starts as one honest sentence.",
                score: 0.72
            )
        case .pride:
            return LocalReflectionProfile(
                title: "You noticed a meaningful win",
                emotion: "Proud",
                insight: "This reflection carries forward energy. Let yourself register the progress before moving to the next thing.",
                expressionMoment: "You gave your progress room to be seen.",
                quote: "Progress becomes easier to trust when you name it.",
                score: 0.78
            )
        case .tender:
            return LocalReflectionProfile(
                title: "You gave a tender feeling some space",
                emotion: "Tender",
                insight: "There is emotional weight here. Letting it be spoken can make it less lonely and easier to care for.",
                expressionMoment: "You allowed a quieter feeling to have a voice.",
                quote: "Soft honesty is still strength.",
                score: 0.7
            )
        case .neutral:
            return LocalReflectionProfile(
                title: "You checked in with yourself",
                emotion: "Thoughtful",
                insight: "You gave shape to what was on your mind. That makes the next small step easier to choose.",
                expressionMoment: "You spoke honestly instead of keeping the moment vague.",
                quote: "Small honest words can become steady progress.",
                score: 0.62
            )
        case .roughLowSignal, .roughLanguage:
            return LocalReflectionProfile(
                title: "You checked in with yourself",
                emotion: "Thoughtful",
                insight: "You gave shape to what was on your mind. That makes the next small step easier to choose.",
                expressionMoment: "You spoke honestly instead of keeping the moment vague.",
                quote: "Small honest words can become steady progress.",
                score: 0.62
            )
        }
    }

    private func containsAny(_ keywords: [String], in text: String) -> Bool {
        keywords.contains { text.contains($0) }
    }

    private func summarize(_ transcript: String) -> String {
        let words = transcript.split(separator: " ")
        if words.count <= 24 {
            return transcript
        }

        return words.prefix(24).joined(separator: " ") + "..."
    }

    private func expressionMoment(from transcript: String, fallback: String) -> String {
        let separators = CharacterSet(charactersIn: ".!?")
        let sentences = transcript
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter {
                $0.split(separator: " ").count >= 4
                    && !TranscriptQuality.containsRoughLanguage($0)
                    && !TranscriptQuality.isRoughLowSignal($0)
            }

        guard let strongestSentence = sentences.max(by: { $0.count < $1.count }) else {
            return fallback
        }

        return "\"\(strongestSentence)\""
    }

    private func suggestedQuest(for text: String, durationSeconds: Int, kind: LocalReflectionKind) -> String {
        if durationSeconds < 30 {
            return "Try a one-minute check-in next time and name one feeling clearly."
        }

        switch kind {
        case .boundaryConflict:
            return "Write one sentence that names what happened and what you need next."
        case .overwhelm:
            return "Choose the smallest useful task and leave the rest for the next pass."
        case .anxiety:
            return "Write one sentence you can say when the worry gets loud."
        case .pride:
            return "Save one sentence about what helped this moment go well."
        case .tender:
            return "Send yourself one kind sentence you would offer a friend."
        case .roughLowSignal, .roughLanguage, .neutral:
            break
        }

        if containsAny(["stress", "stressed", "overwhelmed", "busy", "deadline"], in: text) {
            return "Choose one task you can make smaller before the day ends."
        }

        return "Write down one next step that would make tomorrow feel lighter."
    }
}

private struct LocalReflectionProfile {
    let title: String
    let emotion: String
    let insight: String
    let expressionMoment: String
    let quote: String
    let score: Double
}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
struct AppleIntelligenceReflectionEngine: ReflectionAnalyzing {
    let displayName = "Apple Intelligence"
    private let fallback: LocalReflectionEngine
    private let model = SystemLanguageModel.default

    init(fallback: LocalReflectionEngine) {
        self.fallback = fallback
    }

    var availabilityMessage: String? {
        switch model.availability {
        case .available:
            nil
        case .unavailable(.deviceNotEligible):
            "This device does not support Apple Intelligence, so Circleu will use the local test engine."
        case .unavailable(.appleIntelligenceNotEnabled):
            "Apple Intelligence is turned off in Settings, so Circleu will use the local test engine."
        case .unavailable(.modelNotReady):
            "Apple Intelligence is still preparing its on-device model, so Circleu will use the local test engine for now."
        case .unavailable:
            "Apple Intelligence is unavailable, so Circleu will use the local test engine."
        }
    }

    func analyze(transcript: String, durationSeconds: Int) async throws -> AIReflectionResult {
        let cleanTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTranscript.isEmpty else { throw ReflectionEngineError.emptyTranscript }

        guard case .available = model.availability else {
            return try await fallback.analyze(transcript: cleanTranscript, durationSeconds: durationSeconds)
        }

        let session = LanguageModelSession(instructions: ReflectionPromptContent.instructions)
        let response = try await session.respond(
            to: ReflectionPromptContent.prompt(transcript: cleanTranscript, durationSeconds: durationSeconds)
        ).content
        do {
            return try decodeReflectionResult(from: response)
        } catch {
            return try await fallback.analyze(transcript: cleanTranscript, durationSeconds: durationSeconds)
        }
    }

    private func decodeReflectionResult(from rawResponse: String) throws -> AIReflectionResult {
        let trimmed = rawResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        let jsonText: String

        if let start = trimmed.firstIndex(of: "{"),
           let end = trimmed.lastIndex(of: "}") {
            jsonText = String(trimmed[start...end])
        } else {
            jsonText = trimmed
        }

        guard let data = jsonText.data(using: .utf8),
              let result = try? JSONDecoder().decode(AIReflectionResult.self, from: data) else {
            throw ReflectionEngineError.invalidModelResponse
        }

        return result
    }
}
#endif
