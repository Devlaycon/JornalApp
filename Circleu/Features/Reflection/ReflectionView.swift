import SwiftUI

enum ReflectionSaveDestination {
    case confirmation
    case tips
}

struct ReflectionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var questStore: QuestStore
    var onSave: ((JournalReflectionEntry, ReflectionSaveDestination) -> Void)?
    var onSessionChange: ((AIReflectionSession?) -> Void)?
    @State private var hasSaved = false
    @State private var draftEntry: JournalReflectionEntry?
    @State private var draftSession: AIReflectionSession?
    @State private var engine = ReflectionEngineFactory.makeDefault()
    @State private var sessionRunner = ReflectionSessionRunner()
    @State private var isRegenerating = false
    @State private var regenerateMessage: String?
    @State private var regenerateTask: Task<Void, Never>?

    init(
        entry: JournalReflectionEntry? = nil,
        session: AIReflectionSession? = nil,
        onSessionChange: ((AIReflectionSession?) -> Void)? = nil,
        onSave: ((JournalReflectionEntry, ReflectionSaveDestination) -> Void)? = nil
    ) {
        self.onSessionChange = onSessionChange
        self.onSave = onSave
        _draftEntry = State(initialValue: entry)
        _draftSession = State(initialValue: session)
    }

    var body: some View {
        ZStack {
            PinguScreenBackground()

            VStack(spacing: 0) {
                PinguNavBar(
                    title: "Reflection",
                    leadingIcon: "xmark",
                    trailingIcon: nil,
                    onLeadingTap: { dismiss() }
                )

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        Spacer(minLength: 116)

                        if let reflection {
                            VStack(spacing: 14) {
                                Text("Here's what I noticed")
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                                    .foregroundStyle(PinguDesign.ink)
                                    .multilineTextAlignment(.center)

                                Text("Take a moment to soak in your growth.")
                                    .font(.system(size: 19, weight: .medium, design: .rounded))
                                    .foregroundStyle(PinguDesign.muted)
                            }
                            .padding(.bottom, 22)

                            insightCard(
                                icon: "heart.fill",
                                label: "EMOTION",
                                title: "You seemed \(reflection.emotion.lowercased()).",
                                body: reflection.insight
                            )

                            expressionCard(reflection: reflection)

                            questCard(reflection: reflection)

                            quoteCard(reflection: reflection)

                            aiSessionStatusCard

                            regenerationStatus
                        } else {
                            emptyReflectionState
                        }
                    }
                    .padding(.horizontal, PinguDesign.screenSidePadding)
                    .padding(.bottom, 22)
                }

                bottomActions
            }
        }
        .onDisappear {
            regenerateTask?.cancel()
        }
    }

    private var reflection: AIReflectionResult? {
        draftEntry?.result
    }

    private func insightCard(icon: String, label: String, title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(PinguDesign.blue)

                Text(label)
                    .font(.system(size: 18, weight: .medium))
                    .tracking(1.1)
                    .foregroundStyle(PinguDesign.muted)
            }

            Text(title)
                .font(.system(size: 25, weight: .bold, design: .rounded))
                .foregroundStyle(PinguDesign.ink)

            Text(body)
                .font(.system(size: 20, weight: .regular, design: .rounded))
                .foregroundStyle(PinguDesign.body)
                .lineSpacing(6)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(PinguDesign.border, lineWidth: 1)
        }
    }

    private func expressionCard(reflection: AIReflectionResult) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(spacing: 12) {
                Image(systemName: "waveform")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 26, height: 26)
                    .background(PinguDesign.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))

                Text("EXPRESSION MOMENT")
                    .font(.system(size: 18, weight: .medium))
                    .tracking(1.1)
                    .foregroundStyle(PinguDesign.muted)
            }

            Text(reflection.expressionMoment)
                .font(.system(size: 25, weight: .bold, design: .rounded))
                .foregroundStyle(PinguDesign.ink)
                .lineSpacing(4)

            HStack(spacing: 12) {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(PinguDesign.lightBlue)
                        Capsule()
                            .fill(PinguDesign.blue)
                            .frame(width: proxy.size.width * min(max(reflection.confidenceScore, 0.0), 1.0))
                    }
                }
                .frame(height: 5)

                Text(reflection.emotion)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(PinguDesign.blue)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(PinguDesign.border, lineWidth: 1)
        }
    }

    private func quoteCard(reflection: AIReflectionResult) -> some View {
        ZStack {
            PinguDesign.blue

            Circle()
                .fill(.white.opacity(0.10))
                .frame(width: 260, height: 260)
                .offset(x: -150, y: -120)

            Circle()
                .fill(.white.opacity(0.10))
                .frame(width: 260, height: 260)
                .offset(x: 140, y: 126)

            VStack(spacing: 18) {
                Text("”")
                    .font(.system(size: 54, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.42))

                Text("\"\(reflection.quote)\"")
                    .font(.system(size: 31, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)

                Text("Daily Wisdom")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 26)
                    .frame(height: 34)
                    .background(.white.opacity(0.22))
                    .clipShape(Capsule())
            }
            .padding(26)
        }
        .frame(height: 248)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: PinguDesign.blue.opacity(0.18), radius: 18, y: 10)
    }

    private func questCard(reflection: AIReflectionResult) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "flag.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(PinguDesign.orange)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 7) {
                    Text("NEXT TIP")
                        .font(.system(size: 14, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(PinguDesign.muted)

                    Text(reflection.suggestedQuest)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(PinguDesign.ink)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            Button {
                saveAndStartTips()
            } label: {
                Label("Save & Open Tips", systemImage: "checklist.checked")
            }
            .buttonStyle(PinguPrimaryButtonStyle())
            .disabled(hasSaved || draftEntry == nil || isRegenerating)
            .opacity(hasSaved || draftEntry == nil || isRegenerating ? 0.48 : 1)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PinguDesign.lightBlue.opacity(0.46))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(PinguDesign.border.opacity(0.7), lineWidth: 1)
        }
    }

    private var bottomActions: some View {
        HStack(spacing: 10) {
            Button("Cancel") {
                if !hasSaved {
                    dismiss()
                }
            }
            .disabled(hasSaved)
            .font(.system(size: 22, weight: .medium, design: .rounded))
            .foregroundStyle(PinguDesign.blue)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(PinguDesign.lightBlue)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .opacity(hasSaved ? 0.45 : 1)

            Button {
                regenerateReflection()
            } label: {
                Image(systemName: isRegenerating ? "sparkles" : "arrow.triangle.2.circlepath")
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundStyle(PinguDesign.blue)
                    .frame(width: 58, height: 56)
                    .background(PinguDesign.lightBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(hasSaved || draftEntry == nil || isRegenerating)
            .opacity(hasSaved || draftEntry == nil ? 0.45 : 1)

            ShareLink(item: shareText) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(PinguDesign.blue)
                    .frame(width: 58, height: 56)
                    .background(PinguDesign.lightBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(draftEntry == nil || isRegenerating)
            .opacity(draftEntry == nil ? 0.45 : 1)

            Button(hasSaved ? "Saved" : "Save Entry") {
                saveEntry()
            }
            .disabled(hasSaved || draftEntry == nil || isRegenerating)
            .font(.system(size: 22, weight: .medium, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(hasSaved || draftEntry == nil || isRegenerating ? PinguDesign.muted : PinguDesign.blue)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: PinguDesign.blue.opacity(0.20), radius: 12, y: 6)
        }
        .padding(.horizontal, PinguDesign.screenSidePadding)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(PinguDesign.ice)
    }

    private func saveEntry() {
        saveEntry(to: .confirmation)
    }

    private func saveAndStartTips() {
        saveEntry(to: .tips)
    }

    private func saveEntry(to destination: ReflectionSaveDestination) {
        guard !hasSaved else { return }
        guard let draftEntry else {
            dismiss()
            return
        }

        hasSaved = true
        questStore.addSuggestedQuest(from: draftEntry)
        onSave?(draftEntry, destination)
    }

    private func regenerateReflection() {
        guard !hasSaved, let draftEntry, !isRegenerating else { return }

        regenerateTask?.cancel()
        isRegenerating = true
        regenerateMessage = nil

        regenerateTask = Task {
            let run = await sessionRunner.analyze(
                transcript: draftEntry.transcript,
                durationSeconds: draftEntry.durationSeconds,
                source: .journalRegeneration,
                engine: engine,
                existingSession: draftSession
            )
            guard !Task.isCancelled else { return }

            if let result = run.result {
                await MainActor.run {
                    self.draftSession = run.session
                    self.draftEntry?.result = result
                    self.draftEntry?.engineName = run.attempt.engineName
                    self.draftEntry?.sessionID = run.session.id
                    self.onSessionChange?(run.session)
                    self.isRegenerating = false
                    self.regenerateMessage = "Generated attempt \(run.session.attempts.count) with \(run.attempt.engineName)."
                    self.regenerateTask = nil
                }
            } else {
                await MainActor.run {
                    self.draftSession = run.session
                    self.onSessionChange?(run.session)
                    self.isRegenerating = false
                    self.regenerateMessage = run.attempt.errorMessage ?? "AI regeneration failed. Please try again."
                    self.regenerateTask = nil
                }
            }
        }
    }

    private var shareText: String {
        guard let reflection else {
            return "Circleu Reflection\n\nNo reflection is available yet."
        }

        return """
        Circleu Reflection

        \(reflection.title)
        Emotion: \(reflection.emotion)

        \(reflection.insight)

        "\(reflection.quote)"
        """
    }

    private var emptyReflectionState: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.badge.magnifyingglass")
                .font(.system(size: 58, weight: .semibold))
                .foregroundStyle(PinguDesign.blue)

            Text("No reflection to review")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(PinguDesign.ink)

            Text("Record a voice check-in first. Circleu will analyze it and bring the real reflection here.")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(PinguDesign.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: PinguDesign.deepBlue.opacity(0.06), radius: 16, y: 8)
    }

    private var regenerationStatus: some View {
        Group {
            if isRegenerating {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(PinguDesign.blue)

                    Text("Refreshing your AI reflection...")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(PinguDesign.blue)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(PinguDesign.lightBlue.opacity(0.54))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else if let regenerateMessage {
                Label(regenerateMessage, systemImage: "sparkles")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(PinguDesign.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(PinguDesign.border, lineWidth: 1)
                    }
            }
        }
    }

    private var aiSessionStatusCard: some View {
        Group {
            if let draftSession {
                HStack(spacing: 10) {
                    sessionStatusItem(
                        icon: "tray.full.fill",
                        title: draftSession.source.label,
                        value: "Source"
                    )

                    Divider()
                        .frame(height: 28)

                    sessionStatusItem(
                        icon: "cpu.fill",
                        title: draftSession.engineName,
                        value: "Engine"
                    )

                    Divider()
                        .frame(height: 28)

                    sessionStatusItem(
                        icon: "sparkles",
                        title: "\(draftSession.attempts.count)",
                        value: "Attempts"
                    )

                    Divider()
                        .frame(height: 28)

                    sessionStatusItem(
                        icon: "text.word.spacing",
                        title: "\(draftSession.wordCount)",
                        value: "Words"
                    )
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(PinguDesign.border, lineWidth: 1)
                }
            }
        }
    }

    private func sessionStatusItem(icon: String, title: String, value: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(PinguDesign.blue)

            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(PinguDesign.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(value)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(PinguDesign.muted)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ReflectionView()
        .environmentObject(QuestStore())
}
