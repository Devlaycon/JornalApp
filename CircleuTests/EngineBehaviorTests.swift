import XCTest
@testable import Circleu

final class EngineBehaviorTests: XCTestCase {
    func testTranscriptQualityRejectsEmptyInput() {
        let quality = TranscriptQuality.evaluate("   \n  ")

        XCTAssertEqual(quality.wordCount, 0)
        XCTAssertEqual(quality.characterCount, 0)
        XCTAssertFalse(quality.isReady)
        XCTAssertEqual(quality.guidance, "Add a few words before finishing.")
    }

    func testTranscriptQualityRejectsShortInputWithActionableGuidance() {
        let quality = TranscriptQuality.evaluate("I feel nervous today")

        XCTAssertEqual(quality.wordCount, 4)
        XCTAssertFalse(quality.isReady)
        XCTAssertEqual(quality.guidance, "Add one feeling, one moment, and what you want to understand.")
    }

    func testTranscriptQualityAcceptsUsefulReflectionInput() {
        let transcript = "I felt stressed before our team meeting, but I asked one clear question and understood the plan."

        let quality = TranscriptQuality.evaluate(transcript)

        XCTAssertGreaterThanOrEqual(quality.wordCount, 8)
        XCTAssertTrue(quality.characterCount >= 32)
        XCTAssertTrue(quality.isReady)
        XCTAssertEqual(quality.guidance, "Ready for AI reflection.")
    }

    func testTranscriptQualityFlagsRoughLowSignalInputWithActionableGuidance() {
        let transcript = "Hello hello hello hello hello hi hi hi hi shit shitty fuck fuck you"

        let quality = TranscriptQuality.evaluate(transcript)

        XCTAssertFalse(quality.isReady)
        XCTAssertEqual(quality.guidance, "Try again with one real moment, one feeling, and words you would be comfortable saving.")
    }

    func testLocalReflectionEngineRejectsEmptyTranscript() async {
        let engine = LocalReflectionEngine()

        do {
            _ = try await engine.analyze(transcript: "   ", durationSeconds: 20)
            XCTFail("Expected empty transcript to throw.")
        } catch ReflectionEngineError.emptyTranscript {
            // Expected behavior.
        } catch {
            XCTFail("Expected emptyTranscript, got \(error).")
        }
    }

    func testLocalReflectionEngineCreatesStressReflectionAndQuest() async throws {
        let engine = LocalReflectionEngine()
        let transcript = "I felt stressed and overwhelmed before the team demo, but writing one clear sentence helped me keep going."

        let result = try await engine.analyze(transcript: transcript, durationSeconds: 90)

        XCTAssertEqual(result.title, "You are carrying a lot")
        XCTAssertEqual(result.emotion, "Resilient")
        XCTAssertTrue(result.summary.contains("stressed"))
        XCTAssertEqual(result.suggestedQuest, "Choose one task you can make smaller before the day ends.")
        XCTAssertGreaterThan(result.confidenceScore, 0)
        XCTAssertLessThanOrEqual(result.confidenceScore, 1)
    }

    func testLocalReflectionEngineCreatesAnxiousReflectionProfile() async throws {
        let result = try await analyze(
            "I was nervous before class and worried I would say the wrong thing, but I still asked my question."
        )

        XCTAssertEqual(result.title, "You met uncertainty with courage")
        XCTAssertEqual(result.emotion, "Brave")
        XCTAssertEqual(result.quote, "Courage often starts as one honest sentence.")
        XCTAssertConfidenceScoreIsValid(result)
    }

    func testLocalReflectionEngineCreatesProudReflectionProfile() async throws {
        let result = try await analyze(
            "I felt proud and grateful because I finished the group update and helped everyone understand the next step."
        )

        XCTAssertEqual(result.title, "You noticed a meaningful win")
        XCTAssertEqual(result.emotion, "Proud")
        XCTAssertEqual(result.suggestedQuest, "Save one sentence about what helped this moment go well.")
        XCTAssertConfidenceScoreIsValid(result)
    }

    func testLocalReflectionEngineCreatesTenderReflectionProfile() async throws {
        let result = try await analyze(
            "I felt sad and lonely after lunch because I missed my old friends and did not know who to talk with."
        )

        XCTAssertEqual(result.title, "You gave a tender feeling some space")
        XCTAssertEqual(result.emotion, "Tender")
        XCTAssertEqual(result.quote, "Soft honesty is still strength.")
        XCTAssertConfidenceScoreIsValid(result)
    }

    func testLocalReflectionEngineCreatesNeutralReflectionProfile() async throws {
        let result = try await analyze(
            "I checked in after school and noticed I want tomorrow to feel more organized and clear."
        )

        XCTAssertEqual(result.title, "You checked in with yourself")
        XCTAssertEqual(result.emotion, "Thoughtful")
        XCTAssertEqual(result.suggestedQuest, "Write down one next step that would make tomorrow feel lighter.")
        XCTAssertConfidenceScoreIsValid(result)
    }

    func testLocalReflectionEngineSuggestsLongerCheckInForShortDuration() async throws {
        let result = try await analyze(
            "I felt proud because I asked a clear question and understood what the team needed from me.",
            durationSeconds: 20
        )

        XCTAssertEqual(result.suggestedQuest, "Try a one-minute check-in next time and name one feeling clearly.")
    }

    func testLocalReflectionEngineCoachesRoughLowSignalInputWithoutRepeatingProfanity() async throws {
        let result = try await analyze(
            "Hello hello hello hello hello hi hi hi hi shit shitty fuck fuck you",
            durationSeconds: 17
        )

        XCTAssertEqual(result.title, "Try that check-in again")
        XCTAssertEqual(result.emotion, "Unclear")
        XCTAssertFalse(result.expressionMoment.lowercased().contains("fuck"))
        XCTAssertFalse(result.summary.lowercased().contains("fuck"))
        XCTAssertEqual(result.suggestedQuest, "Record again with one real moment, one feeling, and one thing you want to understand.")
    }

    func testLocalReflectionEngineCoachesCoherentRoughLanguageWithoutGenericPraise() async throws {
        let result = try await analyze(
            "She said something really rough and I felt angry. Should I tell her that it was fucking disrespectful and crossed a line?",
            durationSeconds: 45
        )

        XCTAssertEqual(result.title, "Pause before you respond")
        XCTAssertEqual(result.emotion, "Heated")
        XCTAssertFalse(result.summary.contains("You gave shape to what was on your mind"))
        XCTAssertFalse(result.summary.lowercased().contains("fuck"))
        XCTAssertFalse(result.expressionMoment.lowercased().contains("fuck"))
        XCTAssertFalse(result.quote.contains("Small honest words"))
        XCTAssertEqual(result.suggestedQuest, "Write one calm sentence that names the boundary without attacking the person.")
    }

    func testAppleIntelligencePromptAsksForSpecificTranscriptAnchoredFeedback() {
        let prompt = ReflectionPromptContent.prompt(
            transcript: "I felt ignored in the team meeting, then I asked one clear question and felt calmer.",
            durationSeconds: 75
        )
        let instructions = ReflectionPromptContent.instructions

        XCTAssertTrue(instructions.contains("Do not diagnose"))
        XCTAssertTrue(prompt.contains("Anchor every field to the transcript"))
        XCTAssertTrue(prompt.contains("Avoid generic praise"))
        XCTAssertTrue(prompt.contains("summary should name what happened, what the user felt, and why it mattered"))
        XCTAssertTrue(prompt.contains("insight should name one pattern, tension, or need"))
        XCTAssertTrue(prompt.contains("quote should be original, plainspoken, and specific to this reflection"))
        XCTAssertTrue(prompt.contains("If the transcript is mostly filler, repeated words, or rough language"))
        XCTAssertTrue(prompt.contains("coherent rough, angry, or hostile language"))
        XCTAssertTrue(prompt.contains("Do not repeat profanity"))
        XCTAssertTrue(prompt.contains("expressionMoment should be a short clean phrase from the transcript"))
        XCTAssertTrue(prompt.contains("suggestedQuest should be one small concrete next action"))
        XCTAssertTrue(prompt.contains("I felt ignored in the team meeting"))
    }

    private func analyze(_ transcript: String, durationSeconds: Int = 90) async throws -> AIReflectionResult {
        let engine = LocalReflectionEngine()
        return try await engine.analyze(transcript: transcript, durationSeconds: durationSeconds)
    }

    private func XCTAssertConfidenceScoreIsValid(
        _ result: AIReflectionResult,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertGreaterThanOrEqual(result.confidenceScore, 0, file: file, line: line)
        XCTAssertLessThanOrEqual(result.confidenceScore, 1, file: file, line: line)
    }
}
