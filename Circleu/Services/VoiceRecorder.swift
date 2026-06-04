import AVFoundation
import Combine
import Foundation
import Speech

enum VoicePermissionState: Equatable {
    case waiting
    case checking
    case granted
    case denied
    case unavailable

    var icon: String {
        switch self {
        case .waiting:
            return "circle"
        case .checking:
            return "clock"
        case .granted:
            return "checkmark.circle.fill"
        case .denied:
            return "exclamationmark.circle.fill"
        case .unavailable:
            return "wifi.exclamationmark"
        }
    }

    var label: String {
        switch self {
        case .waiting:
            return "Waiting"
        case .checking:
            return "Checking"
        case .granted:
            return "Ready"
        case .denied:
            return "Needs access"
        case .unavailable:
            return "Unavailable"
        }
    }
}

final class VoiceRecorder: NSObject, ObservableObject {
    @Published var transcript = ""
    @Published var elapsedSeconds = 0
    @Published var isRecording = false
    @Published var isPaused = false
    @Published var isTypedFallbackAvailable = false
    @Published var microphonePermissionState: VoicePermissionState = .waiting
    @Published var speechPermissionState: VoicePermissionState = .waiting
    @Published var statusMessage = "Preparing microphone..."
    @Published var errorMessage: String?

    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en_US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var timer: Timer?

    var hasTranscript: Bool {
        !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func start() {
        guard !isRecording else { return }

        Task {
            await MainActor.run {
                self.microphonePermissionState = .checking
                self.speechPermissionState = .checking
                self.statusMessage = "Checking permissions..."
            }

            let allowed = await requestPermissions()
            guard allowed else { return }

            await MainActor.run {
                self.beginRecognition()
            }
        }
    }

    func togglePause() {
        guard isRecording else { return }

        if isPaused {
            do {
                try audioEngine.start()
                isPaused = false
                statusMessage = "Listening..."
                startTimer()
            } catch {
                errorMessage = "Could not resume recording."
            }
        } else {
            audioEngine.pause()
            isPaused = true
            statusMessage = "Paused"
            stopTimer()
        }
    }

    func stop() {
        stopTimer()
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isRecording = false
        isPaused = false
        statusMessage = "Finished"
    }

    func resetSession() {
        stop()
        transcript = ""
        elapsedSeconds = 0
        errorMessage = nil
        isTypedFallbackAvailable = false
        microphonePermissionState = .waiting
        speechPermissionState = .waiting
        statusMessage = "Preparing microphone..."
    }

    private func enterTypedFallback(message: String) {
        stopTimer()
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isRecording = false
        isPaused = false
        isTypedFallbackAvailable = true
        errorMessage = message
        statusMessage = "Type reflection"
    }

    private func requestPermissions() async -> Bool {
        let speechAllowed = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }

        guard speechAllowed else {
            await MainActor.run {
                self.speechPermissionState = .denied
                self.microphonePermissionState = .waiting
                self.enterTypedFallback(message: "Speech recognition is unavailable. You can still type your reflection below.")
            }
            return false
        }

        await MainActor.run {
            self.speechPermissionState = .granted
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
            await MainActor.run {
                self.microphonePermissionState = .denied
                self.enterTypedFallback(message: "Microphone permission is unavailable. You can still type your reflection below.")
            }
            return false
        }

        await MainActor.run {
            self.microphonePermissionState = .granted
        }

        return true
    }

    private func beginRecognition() {
        stop()
        transcript = ""
        elapsedSeconds = 0
        errorMessage = nil
        isTypedFallbackAvailable = false

        guard let speechRecognizer, speechRecognizer.isAvailable else {
            speechPermissionState = .unavailable
            enterTypedFallback(message: "Speech recognition is not available right now. You can still type your reflection below.")
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
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                request.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()

            recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
                guard let self else { return }

                DispatchQueue.main.async {
                    if let result {
                        self.transcript = result.bestTranscription.formattedString
                    }

                    if let error {
                        self.errorMessage = error.localizedDescription
                    }
                }
            }

            isRecording = true
            isPaused = false
            microphonePermissionState = .granted
            speechPermissionState = .granted
            statusMessage = "Listening..."
            startTimer()
        } catch {
            microphonePermissionState = .unavailable
            enterTypedFallback(message: "Could not start recording. You can still type your reflection below.")
        }
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.elapsedSeconds += 1
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
