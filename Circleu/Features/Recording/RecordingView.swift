import SwiftUI

struct RecordingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var journalStore: ReflectionJournalStore
    @EnvironmentObject private var aiSessionStore: AIReflectionSessionStore
    @StateObject private var viewModel = RecordingViewModel()
    let onViewJournal: () -> Void
    let onViewTips: () -> Void

    init(
        onViewJournal: @escaping () -> Void = {},
        onViewTips: @escaping () -> Void = {}
    ) {
        self.onViewJournal = onViewJournal
        self.onViewTips = onViewTips
    }

    var body: some View {
        ZStack {
            PinguScreenBackground()

            GeometryReader { proxy in
                VStack(spacing: 0) {
                    Spacer(minLength: max(24, proxy.size.height * 0.03))

                    VStack(spacing: 14) {
                        Text(viewModel.isAnalyzing ? "Thinking..." : viewModel.recorder.statusMessage)
                            .font(PinguFont.hero)
                            .foregroundStyle(PinguDesign.blue)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                            .padding(.horizontal, PinguDesign.screenSidePadding)

                        Text(viewModel.subtitle)
                            .font(PinguFont.body)
                            .foregroundStyle(PinguDesign.muted)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.82)
                            .frame(maxWidth: 330)
                    }

                    Spacer(minLength: max(40, proxy.size.height * 0.05))

                    WaveformView()
                        .opacity(viewModel.recorder.isRecording && !viewModel.recorder.isPaused ? 1 : 0.42)

                    transcriptPanel
                        .padding(.horizontal, PinguDesign.screenSidePadding)
                        .padding(.top, 34)

                    Spacer(minLength: 22)

                    VStack(spacing: 8) {
                        Text("LIVE REFLECTION")
                            .font(PinguFont.caption)
                            .tracking(1.2)
                            .foregroundStyle(PinguDesign.muted)

                        Text(Date.now.formatted(date: .abbreviated, time: .omitted))
                            .font(PinguFont.body)
                            .foregroundStyle(PinguDesign.muted.opacity(0.82))
                    }

                    Text(viewModel.formattedElapsedTime)
                        .font(.system(size: 50, weight: .regular, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(PinguDesign.ink)
                        .padding(.top, 22)

                    Spacer()

                    HStack(spacing: 48) {
                        recordingAction(
                            title: viewModel.recorder.isPaused ? "RESUME" : "PAUSE",
                            icon: viewModel.recorder.isPaused ? "play.fill" : "pause.fill",
                            background: PinguDesign.lightBlue,
                            foreground: PinguDesign.muted
                        ) {
                            viewModel.togglePause()
                        }
                        .disabled(!viewModel.recorder.isRecording || viewModel.isAnalyzing)
                        .opacity(!viewModel.recorder.isRecording || viewModel.isAnalyzing ? 0.48 : 1)

                        recordingAction(
                            title: viewModel.finishActionTitle,
                            icon: viewModel.isAnalyzing ? "sparkles" : "checkmark",
                            background: viewModel.canFinish ? PinguDesign.blue : PinguDesign.lightBlue,
                            foreground: viewModel.canFinish ? .white : PinguDesign.muted
                        ) {
                            viewModel.finishRecording()
                        }
                        .disabled(!viewModel.canFinish)
                        .opacity(viewModel.canFinish ? 1 : 0.72)
                    }
                    .padding(.bottom, max(22, proxy.safeAreaInsets.bottom + 14))
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }

            if viewModel.isAnalyzing {
                analyzingOverlay
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            recordingHeader
                .padding(.top, 8)
                .padding(.bottom, 10)
                .background(PinguDesign.ice.opacity(0.96))
        }
        .task {
            viewModel.start()
        }
        .onDisappear {
            viewModel.stop()
        }
        .fullScreenCover(isPresented: $viewModel.showReflection) {
            ReflectionView(
                entry: viewModel.pendingEntry,
                session: viewModel.pendingSession,
                onSessionChange: { session in
                    viewModel.applySessionChange(session)
                }
            ) { entry, destination in
                viewModel.savePendingEntry(entry, journalStore: journalStore, aiSessionStore: aiSessionStore)

                switch destination {
                case .confirmation:
                    viewModel.showConfirmationAfterSave()
                case .tips:
                    onViewTips()
                    dismiss()
                }
            }
        }
        .fullScreenCover(isPresented: $viewModel.showSaveConfirmation) {
            SaveConfirmationView(entry: viewModel.savedEntry) {
                viewModel.clearSaveConfirmation()
                dismiss()
            } onViewJournal: {
                viewModel.clearSaveConfirmation()
                onViewJournal()
                dismiss()
            } onRecordAnother: {
                viewModel.clearSaveConfirmation()
                viewModel.resetForAnotherRecording()
            }
        }
    }

    private var recordingHeader: some View {
        HStack {
            Button {
                viewModel.stop()
                dismiss()
            } label: {
                Label("Close", systemImage: "xmark")
                    .labelStyle(.iconOnly)
                    .font(.system(size: 27, weight: .medium))
                    .foregroundStyle(PinguDesign.tabText)
                    .frame(width: 58, height: 50)
                    .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .background(.white.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: PinguDesign.deepBlue.opacity(0.08), radius: 10, y: 5)
            }
            .accessibilityLabel("Close recording")

            Spacer()

            Button {
                viewModel.restartRecording()
            } label: {
                Label("Replay", systemImage: "arrow.clockwise")
                    .labelStyle(.iconOnly)
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundStyle(PinguDesign.tabText)
                    .frame(width: 58, height: 50)
                    .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .background(.white.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: PinguDesign.deepBlue.opacity(0.08), radius: 10, y: 5)
            }
            .disabled(viewModel.isAnalyzing || viewModel.showReflection || viewModel.showSaveConfirmation)
            .accessibilityLabel("Restart recording")
        }
        .padding(.horizontal, PinguDesign.screenSidePadding)
    }

    private var transcriptPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "text.bubble.fill")
                    .foregroundStyle(PinguDesign.blue)

                Text("Transcript")
                    .font(PinguFont.cardTitle)
                    .foregroundStyle(PinguDesign.ink)

                Spacer()

                Text(viewModel.engine.displayName)
                    .font(PinguFont.caption)
                    .foregroundStyle(PinguDesign.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(PinguDesign.lightBlue.opacity(0.62))
                    .clipShape(Capsule())
            }

            if viewModel.recorder.transcript.isEmpty {
                TextEditor(text: $viewModel.manualTranscript)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(viewModel.manualTranscript.isEmpty ? PinguDesign.muted : PinguDesign.body)
                    .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
                    .scrollContentBackground(.hidden)
                    .background(.clear)
                    .disabled(viewModel.isAnalyzing)
                    .overlay(alignment: .topLeading) {
                        if viewModel.manualTranscript.isEmpty {
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
                Text(viewModel.recorder.transcript)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(PinguDesign.body)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
            }

            if let analysisMessage = viewModel.analysisMessage {
                Text(analysisMessage)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(PinguDesign.orange)
            }

            if viewModel.analysisMessage != nil && viewModel.canFinish {
                Button {
                    viewModel.finishRecording()
                } label: {
                    Label("Try analysis again", systemImage: "arrow.clockwise")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }
                .buttonStyle(.plain)
                .foregroundStyle(PinguDesign.blue)
            }

            permissionReadinessRow

            Label(viewModel.transcriptQuality.guidance, systemImage: viewModel.transcriptQuality.isReady ? "checkmark.circle.fill" : "info.circle.fill")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(viewModel.transcriptQuality.isReady ? PinguDesign.blue : PinguDesign.muted)

            if !viewModel.canFinish && !viewModel.isAnalyzing {
                Label("\(viewModel.transcriptQuality.wordCount) words captured", systemImage: "text.word.spacing")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(PinguDesign.muted)
            }
        }
        .padding(16)
        .pinguGlass(cornerRadius: 22, tint: 0.18)
    }

    private var permissionReadinessRow: some View {
        HStack(spacing: 8) {
            permissionBadge(
                title: "Mic",
                state: viewModel.recorder.microphonePermissionState
            )

            permissionBadge(
                title: "Speech",
                state: viewModel.recorder.speechPermissionState
            )
        }
        .padding(.top, 2)
    }

    private func permissionBadge(title: String, state: VoicePermissionState) -> some View {
        HStack(spacing: 6) {
            Image(systemName: state.icon)
                .font(.system(size: 12, weight: .bold))

            Text("\(title) \(state.label)")
                .font(PinguFont.caption)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(permissionColor(for: state))
        .frame(maxWidth: .infinity, minHeight: 34)
        .padding(.horizontal, 8)
        .background(permissionColor(for: state).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func permissionColor(for state: VoicePermissionState) -> Color {
        switch state {
        case .granted:
            return PinguDesign.blue
        case .checking:
            return PinguDesign.orange
        case .denied, .unavailable:
            return PinguDesign.muted
        case .waiting:
            return PinguDesign.muted.opacity(0.82)
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
                    .font(PinguFont.sectionTitle)
                    .foregroundStyle(PinguDesign.ink)

                Text("Circleu is turning your transcript into a useful insight.")
                    .font(PinguFont.body)
                    .foregroundStyle(PinguDesign.muted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 270)
            }
            .padding(24)
            .pinguGlass(cornerRadius: 26, tint: 0.22)
        }
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
                    .font(.system(size: 29, weight: .bold))
                    .foregroundStyle(foreground)
                    .frame(width: 76, height: 76)
                    .background(background)
                    .clipShape(Circle())
                    .shadow(color: PinguDesign.ink.opacity(0.12), radius: 12, y: 8)

                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .tracking(2.0)
                    .foregroundStyle(title == "FINISH" || title == "WAIT" ? PinguDesign.blue : PinguDesign.muted)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RecordingView()
        .environmentObject(ReflectionJournalStore())
        .environmentObject(AIReflectionSessionStore())
}
