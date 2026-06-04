import SwiftUI

struct ReflectionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var aiSessionStore: AIReflectionSessionStore
    @EnvironmentObject private var questStore: QuestStore
    var onSave: ((JournalReflectionEntry) -> Void)?
    @State private var hasSaved = false
    @State private var draftEntry: JournalReflectionEntry?
    @State private var engine = ReflectionEngineFactory.makeDefault()
    @State private var isRegenerating = false
    @State private var regenerateMessage: String?
    @State private var regenerateTask: Task<Void, Never>?

    init(entry: JournalReflectionEntry? = nil, onSave: ((JournalReflectionEntry) -> Void)? = nil) {
        self.onSave = onSave
        _draftEntry = State(initialValue: entry)
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
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "flag.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(PinguDesign.orange)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 7) {
                Text("NEXT QUEST")
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
        guard !hasSaved else { return }
        guard let draftEntry else {
            dismiss()
            return
        }

        hasSaved = true
        questStore.addSuggestedQuest(from: draftEntry)
        onSave?(draftEntry)
    }

    private func regenerateReflection() {
        guard !hasSaved, let draftEntry, !isRegenerating else { return }

        regenerateTask?.cancel()
        isRegenerating = true
        regenerateMessage = nil
        let analysisStartedAt = Date()

        regenerateTask = Task {
            do {
                let result = try await engine.analyze(
                    transcript: draftEntry.transcript,
                    durationSeconds: draftEntry.durationSeconds
                )
                guard !Task.isCancelled else { return }
                let analysisElapsedMilliseconds = Int(Date().timeIntervalSince(analysisStartedAt) * 1000)
                let attempt = AIReflectionAttempt(
                    createdAt: analysisStartedAt,
                    engineName: engine.displayName,
                    status: .succeeded,
                    result: result,
                    elapsedMilliseconds: analysisElapsedMilliseconds
                )

                await MainActor.run {
                    if let sessionID = self.draftEntry?.sessionID {
                        aiSessionStore.append(attempt, to: sessionID)
                    }
                    self.draftEntry?.result = result
                    self.draftEntry?.engineName = engine.displayName
                    self.isRegenerating = false
                    self.regenerateMessage = "Generated a fresh reflection with \(engine.displayName)."
                    self.regenerateTask = nil
                }
            } catch {
                guard !Task.isCancelled else { return }
                let analysisElapsedMilliseconds = Int(Date().timeIntervalSince(analysisStartedAt) * 1000)
                let attempt = AIReflectionAttempt(
                    createdAt: analysisStartedAt,
                    engineName: engine.displayName,
                    status: .failed,
                    errorMessage: error.localizedDescription,
                    elapsedMilliseconds: analysisElapsedMilliseconds
                )

                await MainActor.run {
                    if let sessionID = self.draftEntry?.sessionID {
                        aiSessionStore.append(attempt, to: sessionID)
                    }
                    self.isRegenerating = false
                    self.regenerateMessage = error.localizedDescription
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
}

#Preview {
    ReflectionView()
        .environmentObject(AIReflectionSessionStore())
        .environmentObject(QuestStore())
}
