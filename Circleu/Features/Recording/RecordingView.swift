import SwiftUI

struct RecordingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var journalStore: ReflectionJournalStore
    @StateObject private var recorder = VoiceRecorder()
    let onViewJournal: () -> Void

    @State private var engine = ReflectionEngineFactory.makeDefault()
    @State private var showReflection = false
    @State private var showSaveConfirmation = false
    @State private var pendingEntry: JournalReflectionEntry?
    @State private var savedEntry: JournalReflectionEntry?
    @State private var isAnalyzing = false
    @State private var analysisMessage: String?
    @State private var manualTranscript = ""
    @State private var analysisTask: Task<Void, Never>?

    init(onViewJournal: @escaping () -> Void = {}) {
        self.onViewJournal = onViewJournal
    }

    var body: some View {
        ZStack {
            PinguScreenBackground()

            GeometryReader { proxy in
                VStack(spacing: 0) {
                    recordingHeader
                        .padding(.top, 18)

                    Spacer(minLength: max(54, proxy.size.height * 0.07))

                    VStack(spacing: 14) {
                        Text(isAnalyzing ? "Thinking..." : recorder.statusMessage)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(PinguDesign.blue)

                        Text(subtitle)
                            .font(.system(size: 22, weight: .medium, design: .rounded))
                            .foregroundStyle(PinguDesign.muted)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 330)
                    }

                    Spacer(minLength: max(40, proxy.size.height * 0.05))

                    WaveformView()
                        .opacity(recorder.isRecording && !recorder.isPaused ? 1 : 0.42)

                    transcriptPanel
                        .padding(.horizontal, PinguDesign.screenSidePadding)
                        .padding(.top, 34)

                    Spacer(minLength: 22)

                    VStack(spacing: 8) {
                        Text("LIVE REFLECTION")
                            .font(.system(size: 15, weight: .medium))
                            .tracking(2.0)
                            .foregroundStyle(PinguDesign.muted)

                        Text(Date.now.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(PinguDesign.muted.opacity(0.82))
                    }

                    Text(formattedTime(recorder.elapsedSeconds))
                        .font(.system(size: 58, weight: .regular, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(PinguDesign.ink)
                        .padding(.top, 28)

                    Spacer()

                    HStack(spacing: 48) {
                        recordingAction(
                            title: recorder.isPaused ? "RESUME" : "PAUSE",
                            icon: recorder.isPaused ? "play.fill" : "pause.fill",
                            background: PinguDesign.lightBlue,
                            foreground: PinguDesign.muted
                        ) {
                            recorder.togglePause()
                        }
                        .disabled(!recorder.isRecording || isAnalyzing)
                        .opacity(!recorder.isRecording || isAnalyzing ? 0.48 : 1)

                        recordingAction(
                            title: finishActionTitle,
                            icon: isAnalyzing ? "sparkles" : "checkmark",
                            background: canFinish ? PinguDesign.blue : PinguDesign.lightBlue,
                            foreground: canFinish ? .white : PinguDesign.muted
                        ) {
                            finishRecording()
                        }
                        .disabled(!canFinish)
                        .opacity(canFinish ? 1 : 0.72)
                    }
                    .padding(.bottom, 34)
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }

            if isAnalyzing {
                analyzingOverlay
            }
        }
        .task {
            recorder.start()
        }
        .onDisappear {
            analysisTask?.cancel()
            recorder.stop()
        }
        .fullScreenCover(isPresented: $showReflection) {
            ReflectionView(entry: pendingEntry) { entry in
                journalStore.add(entry)
                savedEntry = entry
                showReflection = false
                showSaveConfirmation = true
            }
        }
        .fullScreenCover(isPresented: $showSaveConfirmation) {
            SaveConfirmationView(entry: savedEntry) {
                showSaveConfirmation = false
                dismiss()
            } onViewJournal: {
                showSaveConfirmation = false
                onViewJournal()
                dismiss()
            } onRecordAnother: {
                showSaveConfirmation = false
                resetForAnotherRecording()
            }
        }
    }

    private var subtitle: String {
        if isAnalyzing {
            return "Apple Intelligence is creating your reflection."
        }

        if recorder.isTypedFallbackAvailable {
            return "Voice is not ready, but typing works. Your reflection can still continue."
        }

        if let message = recorder.errorMessage {
            return message
        }

        if let message = engine.availabilityMessage {
            return message
        }

        return "Speak naturally. Your transcript stays on this device."
    }

    private var recordingHeader: some View {
        HStack {
            Button {
                recorder.stop()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(PinguDesign.tabText)
                    .frame(width: 48, height: 48)
            }

            Spacer()

            Button {
                analysisTask?.cancel()
                pendingEntry = nil
                savedEntry = nil
                analysisMessage = nil
                manualTranscript = ""
                recorder.resetSession()
                recorder.start()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundStyle(PinguDesign.tabText)
                    .frame(width: 48, height: 48)
            }
            .disabled(isAnalyzing || showReflection || showSaveConfirmation)
        }
        .padding(.horizontal, 24)
    }

    private var transcriptPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "text.bubble.fill")
                    .foregroundStyle(PinguDesign.blue)

                Text("Transcript")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(PinguDesign.ink)

                Spacer()

                Text(engine.displayName)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(PinguDesign.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(PinguDesign.lightBlue.opacity(0.62))
                    .clipShape(Capsule())
            }

            if recorder.transcript.isEmpty {
                TextEditor(text: $manualTranscript)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(manualTranscript.isEmpty ? PinguDesign.muted : PinguDesign.body)
                    .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
                    .scrollContentBackground(.hidden)
                    .background(.clear)
                    .disabled(isAnalyzing)
                    .overlay(alignment: .topLeading) {
                        if manualTranscript.isEmpty {
                            Text("Speak naturally, or type here if microphone or speech recognition is not ready.")
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundStyle(PinguDesign.muted)
                                .lineSpacing(4)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                    }
            } else {
                Text(recorder.transcript)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(PinguDesign.body)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
            }

            if let analysisMessage {
                Text(analysisMessage)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(PinguDesign.orange)
            }

            if analysisMessage != nil && canFinish {
                Button {
                    finishRecording()
                } label: {
                    Label("Try analysis again", systemImage: "arrow.clockwise")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }
                .buttonStyle(.plain)
                .foregroundStyle(PinguDesign.blue)
            }

            Label(transcriptQuality.guidance, systemImage: transcriptQuality.isReady ? "checkmark.circle.fill" : "info.circle.fill")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(transcriptQuality.isReady ? PinguDesign.blue : PinguDesign.muted)

            if !canFinish && !isAnalyzing {
                Label("\(transcriptQuality.wordCount) words captured", systemImage: "text.word.spacing")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(PinguDesign.muted)
            }
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(PinguDesign.border, lineWidth: 1)
        }
    }

    private var analyzingOverlay: some View {
        ZStack {
            PinguDesign.ice.opacity(0.82).ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .controlSize(.large)
                    .tint(PinguDesign.blue)

                Text("Analyzing your reflection")
                    .font(.system(size: 23, weight: .bold, design: .rounded))
                    .foregroundStyle(PinguDesign.ink)

                Text("Circleu is turning your transcript into a useful insight.")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(PinguDesign.muted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 270)
            }
            .padding(24)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .shadow(color: PinguDesign.deepBlue.opacity(0.12), radius: 22, y: 12)
        }
    }

    private func finishRecording() {
        guard canFinish else {
            analysisMessage = transcriptQuality.guidance
            return
        }

        analysisTask?.cancel()
        recorder.stop()
        analysisMessage = nil
        let transcript = effectiveTranscript

        analysisTask = Task {
            await MainActor.run {
                isAnalyzing = true
            }

            do {
                let result = try await engine.analyze(
                    transcript: transcript,
                    durationSeconds: recorder.elapsedSeconds
                )
                guard !Task.isCancelled else { return }
                let entry = JournalReflectionEntry(
                    durationSeconds: recorder.elapsedSeconds,
                    transcript: transcript,
                    engineName: engine.displayName,
                    result: result
                )

                await MainActor.run {
                    pendingEntry = entry
                    isAnalyzing = false
                    analysisTask = nil
                    showReflection = true
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    isAnalyzing = false
                    analysisTask = nil
                    analysisMessage = error.localizedDescription
                }
            }
        }
    }

    private var effectiveTranscript: String {
        let liveTranscript = recorder.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        if !liveTranscript.isEmpty {
            return liveTranscript
        }

        return manualTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canFinish: Bool {
        !isAnalyzing && transcriptQuality.isReady
    }

    private var transcriptQuality: TranscriptQuality {
        TranscriptQuality.evaluate(effectiveTranscript)
    }

    private var finishActionTitle: String {
        if isAnalyzing {
            return "WAIT"
        }

        return canFinish ? "FINISH" : "TYPE"
    }

    private func resetForAnotherRecording() {
        analysisTask?.cancel()
        analysisTask = nil
        pendingEntry = nil
        savedEntry = nil
        showReflection = false
        showSaveConfirmation = false
        isAnalyzing = false
        analysisMessage = nil
        manualTranscript = ""
        recorder.resetSession()
        recorder.start()
    }

    private func recordingAction(
        title: String,
        icon: String,
        background: Color,
        foreground: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 13) {
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(foreground)
                    .frame(width: 86, height: 86)
                    .background(background)
                    .clipShape(Circle())
                    .shadow(color: PinguDesign.ink.opacity(0.12), radius: 12, y: 8)

                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .tracking(2.0)
                    .foregroundStyle(title == "FINISH" || title == "WAIT" ? PinguDesign.blue : PinguDesign.muted)
            }
        }
        .buttonStyle(.plain)
    }

    private func formattedTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    RecordingView()
        .environmentObject(ReflectionJournalStore())
}
