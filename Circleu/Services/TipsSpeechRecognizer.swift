import AVFoundation
import Combine
import Foundation
import Speech

@MainActor
final class TipsSpeechRecognizer: NSObject, ObservableObject {
    @Published private(set) var isListening = false
    @Published private(set) var statusMessage = "Mic ready"
    @Published private(set) var errorMessage: String?

    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en_US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var onTranscript: ((String) -> Void)?

    func start(onTranscript: @escaping (String) -> Void) {
        guard !isListening else {
            stop()
            return
        }

        self.onTranscript = onTranscript
        errorMessage = nil
        statusMessage = "Checking mic..."

        Task {
            let allowed = await requestPermissions()
            guard allowed else { return }
            beginRecognition()
        }
    }

    func stop() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isListening = false
        statusMessage = "Mic ready"
        onTranscript = nil
    }

    func resetError() {
        errorMessage = nil
    }

    private func requestPermissions() async -> Bool {
        let speechAllowed = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }

        guard speechAllowed else {
            errorMessage = "Speech is not available. Typing still works."
            statusMessage = "Type instead"
            return false
        }

        let microphoneAllowed = await withCheckedContinuation { continuation in
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission { allowed in
                    continuation.resume(returning: allowed)
                }
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                    continuation.resume(returning: allowed)
                }
            }
        }

        guard microphoneAllowed else {
            errorMessage = "Microphone access is not ready. Typing still works."
            statusMessage = "Type instead"
            return false
        }

        return true
    }

    private func beginRecognition() {
        stopEngineOnly()

        guard let speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "Speech recognition is not available right now."
            statusMessage = "Type instead"
            return
        }

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            let request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true
            recognitionRequest = request

            let inputNode = audioEngine.inputNode
            let format = inputNode.outputFormat(forBus: 0)
            guard format.sampleRate > 0, format.channelCount > 0 else {
                errorMessage = "The microphone input is not ready. Typing still works."
                statusMessage = "Type instead"
                return
            }

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                request.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()

            recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
                guard let self else { return }

                DispatchQueue.main.async {
                    if let result {
                        self.onTranscript?(result.bestTranscription.formattedString)
                    }

                    if let error {
                        self.errorMessage = error.localizedDescription
                    }
                }
            }

            isListening = true
            statusMessage = "Listening..."
        } catch {
            errorMessage = "Could not start voice input. Typing still works."
            statusMessage = "Type instead"
            stopEngineOnly()
        }
    }

    private func stopEngineOnly() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isListening = false
    }
}
