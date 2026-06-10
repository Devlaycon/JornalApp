import XCTest
@testable import Circleu

@MainActor
final class ViewModelBehaviorTests: XCTestCase {
    func testAuthStoreRequiresValidEmailAndStrongPassword() {
        let store = AuthStore(userDefaults: makeDefaults())

        XCTAssertThrowsError(try store.signUp(name: "Tuan", email: "not-email", password: "longenough")) { error in
            XCTAssertEqual(error as? AuthError, .invalidEmail)
        }

        XCTAssertThrowsError(try store.signUp(name: "Tuan", email: "tuan@example.com", password: "12345678")) { error in
            XCTAssertEqual(error as? AuthError, .weakPassword)
        }
    }

    func testAuthStoreSignsUpSignsInAndLogsOutLocalAccount() throws {
        let defaults = makeDefaults()
        let store = AuthStore(userDefaults: defaults)

        let account = try store.signUp(name: "  Tuan  ", email: " TUAN@example.com ", password: "strong-pass")

        XCTAssertTrue(store.isSignedIn)
        XCTAssertEqual(account.email, "tuan@example.com")
        XCTAssertEqual(account.displayName, "Tuan")
        XCTAssertNotEqual(account.passwordHash, "strong-pass")

        store.logout()
        XCTAssertFalse(store.isSignedIn)

        let signedIn = try store.signIn(email: "tuan@example.com", password: "strong-pass")
        XCTAssertEqual(signedIn.id, account.id)
        XCTAssertTrue(store.isSignedIn)
    }

    func testJournalSearchFindsEntryContentAcrossEditableAndGeneratedFields() {
        let entry = JournalReflectionEntry(
            durationSeconds: 90,
            transcript: "I explained my idea clearly during the group discussion.",
            engineName: "Apple Intelligence",
            result: AIReflectionResult(
                title: "A clearer voice",
                emotion: "Focused",
                summary: "You stayed calm and direct.",
                insight: "You can lead with one clear sentence.",
                expressionMoment: "You named the point without apologizing first.",
                quote: "Clarity can be gentle.",
                confidenceScore: 0.82,
                suggestedQuest: "Practice a two-sentence update tomorrow."
            ),
            editableTitle: "Presentation courage",
            editableEmotion: "Confident",
            privateNote: "Try this again in the team meeting.",
            tags: ["speaking", "team"]
        )
        let viewModel = JournalViewModel()

        viewModel.searchText = " team meeting "
        XCTAssertEqual(viewModel.filteredEntries(from: [entry]), [entry])
        XCTAssertEqual(viewModel.sectionTitle, "Search results")

        viewModel.clearSearch()
        XCTAssertEqual(viewModel.filteredEntries(from: [entry]), [entry])
        XCTAssertEqual(viewModel.sectionTitle, "Saved reflections")
    }

    func testJournalWorkspaceParsesCommaSeparatedTags() {
        let viewModel = JournalWorkspaceEditViewModel(entry: .preview)

        viewModel.tagsText = " speaking,  school , , reflection  "

        XCTAssertEqual(viewModel.parsedTags, ["speaking", "school", "reflection"])
    }

    func testTipsSetupCanContinueWithTypedMessageOrAttachedImage() {
        let viewModel = TipsPracticeViewModel()

        XCTAssertFalse(viewModel.canContinue)

        viewModel.message = "   Could you help me ask for more time politely?   "
        XCTAssertTrue(viewModel.canContinue)

        viewModel.message = ""
        viewModel.attachMessageImage(Data([0x01, 0x02]))
        XCTAssertTrue(viewModel.canContinue)
    }

    func testTipsToneMapsSliderToExpectedVoice() {
        let viewModel = TipsPracticeViewModel()

        viewModel.toneValue = 0.1
        XCTAssertEqual(viewModel.tone, .soft)

        viewModel.toneValue = 0.5
        XCTAssertEqual(viewModel.tone, .diplomatic)

        viewModel.toneValue = 0.9
        XCTAssertEqual(viewModel.tone, .firm)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "circleu.viewmodel.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
