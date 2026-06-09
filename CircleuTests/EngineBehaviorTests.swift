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
}
