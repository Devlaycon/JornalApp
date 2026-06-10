import Combine
import Foundation

enum TipsPracticeMode {
    case setup
    case liveCoach
}

enum TipsPracticeInputTarget {
    case message
    case reply
}

@MainActor
final class TipsPracticeViewModel: ObservableObject {
    @Published var mode: TipsPracticeMode = .setup
    @Published var message = ""
    @Published var scene: TipsPracticeScene = .workplace
    @Published var customScene = ""
    @Published var toneValue = TipsPracticeTone.diplomatic.sliderValue
    @Published var situation = ""
    @Published var messageImageData: Data?
    @Published var replyImageData: Data?
    @Published var replyInput = ""
    @Published var extraContextInput = ""
    @Published var activeSession: TipsPracticeSession?
    @Published var showCustomSceneSheet = false
    @Published var customSceneDraft = ""
    @Published var inputHint: String?

    let speechRecognizer = TipsSpeechRecognizer()

    private let engine = CommunicationCoachEngine()
    private var store: TipsPracticeStore?
    private var cancellables = Set<AnyCancellable>()
    private var activeSpeechTarget: TipsPracticeInputTarget?
    private var speechBaseText = ""
    private var hasBoundStore = false

    init() {
        speechRecognizer.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    var tone: TipsPracticeTone {
        TipsPracticeTone.fromSliderValue(toneValue)
    }

    var characterCount: Int {
        message.count
    }

    var canContinue: Bool {
        !clean(message).isEmpty || messageImageData != nil
    }

    var sceneTitle: String {
        scene.displayTitle(customScene: customScene)
    }

    var voiceButtonTitle: String {
        speechRecognizer.isListening ? "Stop voice" : "Voice"
    }

    var isMessageVoiceActive: Bool {
        speechRecognizer.isListening && activeSpeechTarget == .message
    }

    var isReplyVoiceActive: Bool {
        speechRecognizer.isListening && activeSpeechTarget == .reply
    }

    var canSendReply: Bool {
        !clean(replyInput).isEmpty || !clean(extraContextInput).isEmpty || replyImageData != nil
    }

    func bind(store: TipsPracticeStore) {
        guard !hasBoundStore else { return }
        hasBoundStore = true
        self.store = store
        message = store.draftMessage
        scene = store.draftScene
        customScene = store.draftCustomScene
        toneValue = store.draftTone.sliderValue
        situation = store.draftSituation
        activeSession = store.currentSession
        if store.currentSession != nil {
            mode = .liveCoach
        }
    }

    func persistDraft() {
        store?.saveDraft(
            message: message,
            scene: scene,
            customScene: customScene,
            tone: tone,
            situation: situation
        )
    }

    func selectScene(_ newScene: TipsPracticeScene) {
        scene = newScene
        if newScene == .custom {
            customSceneDraft = customScene
            showCustomSceneSheet = true
        }
        persistDraft()
    }

    func saveCustomScene() {
        let cleanScene = clean(customSceneDraft)
        guard !cleanScene.isEmpty else { return }
        customScene = cleanScene
        scene = .custom
        showCustomSceneSheet = false
        persistDraft()
    }

    func attachMessageImage(_ data: Data?) {
        messageImageData = data
        if data != nil {
            inputHint = "Image attached. Add or edit the message above."
        }
    }

    func attachReplyImage(_ data: Data?) {
        replyImageData = data
        if data != nil {
            inputHint = "Reply image attached. Add any text you want the coach to know."
        }
    }

    func toggleVoice(for target: TipsPracticeInputTarget) {
        inputHint = nil

        if speechRecognizer.isListening, activeSpeechTarget == target {
            speechRecognizer.stop()
            activeSpeechTarget = nil
            return
        }

        if speechRecognizer.isListening {
            speechRecognizer.stop()
        }

        activeSpeechTarget = target
        speechBaseText = target == .message ? message : replyInput
        speechRecognizer.start { [weak self] transcript in
            guard let self else { return }
            self.applyTranscript(transcript, to: target)
        }
    }

    func startCoach() {
        guard canContinue else {
            inputHint = "Add the message you want to practice."
            return
        }

        speechRecognizer.stop()
        activeSpeechTarget = nil
        let practiceMessage = clean(message).isEmpty
            ? "I attached a chat screenshot and want help replying clearly."
            : clean(message)

        let session = engine.startSession(
            message: practiceMessage,
            scene: scene,
            customScene: customScene,
            tone: tone,
            situation: situation,
            attachedImageCount: messageImageData == nil ? 0 : 1
        )
        activeSession = session
        store?.activate(session)
        persistDraft()
        mode = .liveCoach
    }

    func backToSetup() {
        speechRecognizer.stop()
        activeSpeechTarget = nil
        mode = .setup
    }

    func resume(_ session: TipsPracticeSession) {
        speechRecognizer.stop()
        activeSpeechTarget = nil
        activeSession = session
        scene = session.scene
        customScene = session.customScene ?? ""
        toneValue = session.tone.sliderValue
        situation = session.situation
        replyInput = ""
        extraContextInput = ""
        replyImageData = nil
        inputHint = nil
        store?.resume(session)
        mode = .liveCoach
    }

    func delete(_ session: TipsPracticeSession) {
        store?.delete(session)
        if activeSession?.id == session.id {
            activeSession = nil
            mode = .setup
        }
    }

    func startNewTip() {
        speechRecognizer.stop()
        activeSpeechTarget = nil
        store?.resetDraft()
        mode = .setup
        message = ""
        scene = .workplace
        customScene = ""
        toneValue = TipsPracticeTone.diplomatic.sliderValue
        situation = ""
        messageImageData = nil
        replyImageData = nil
        replyInput = ""
        extraContextInput = ""
        activeSession = nil
        inputHint = nil
    }

    var canSubmitReplyMode: Bool {
        !clean(replyInput).isEmpty || replyImageData != nil
    }

    var canSubmitContextMode: Bool {
        !clean(extraContextInput).isEmpty
    }

    /// "Paste their reply" → triggers the "Now what?" analysis.
    func submitReply() {
        guard let session = activeSession else { return }
        guard canSubmitReplyMode else {
            inputHint = "Paste what they said (or attach a screenshot)."
            return
        }

        speechRecognizer.stop()
        activeSpeechTarget = nil

        let reply = clean(replyInput).isEmpty && replyImageData != nil
            ? "They replied in the attached chat screenshot."
            : clean(replyInput)

        let updated = engine.handleIncomingReply(session, reply: reply)
        activeSession = updated
        store?.updateCurrentSession(updated)
        replyInput = ""
        replyImageData = nil
        inputHint = nil
    }

    /// "Add context" → triggers a refreshed Suggested phrasing.
    func submitContext() {
        guard let session = activeSession else { return }
        guard canSubmitContextMode else {
            inputHint = "Add a sentence of context so I can restyle the phrasing."
            return
        }

        speechRecognizer.stop()
        activeSpeechTarget = nil

        let updated = engine.handleExtraContext(session, context: extraContextInput)
        activeSession = updated
        store?.updateCurrentSession(updated)
        extraContextInput = ""
        inputHint = nil
    }

    func useReplyOption(_ option: TipsCoachReplyOption) {
        replyInput = option.text
    }

    func trySofter() {
        guard let session = activeSession else { return }
        let updated = engine.rephraseSofter(session)
        activeSession = updated
        store?.updateCurrentSession(updated)
    }

    private func applyTranscript(_ transcript: String, to target: TipsPracticeInputTarget) {
        let cleanTranscript = clean(transcript)
        let combined = [speechBaseText, cleanTranscript]
            .map(clean)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        switch target {
        case .message:
            message = String(combined.prefix(240))
        case .reply:
            replyInput = combined
        }
    }

    private func clean(_ value: String) -> String {
        value
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
