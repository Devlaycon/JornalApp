import SwiftUI

enum ReflectionSaveDestination {
    case confirmation
    case tips
}

struct ReflectionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var questStore: QuestStore
    @StateObject private var viewModel: ReflectionViewModel

    init(
        entry: JournalReflectionEntry? = nil,
        session: AIReflectionSession? = nil,
        onSessionChange: ((AIReflectionSession?) -> Void)? = nil,
        onSave: ((JournalReflectionEntry, ReflectionSaveDestination) -> Void)? = nil
    ) {
        _viewModel = StateObject(
            wrappedValue: ReflectionViewModel(
                entry: entry,
                session: session,
                onSessionChange: onSessionChange,
                onSave: onSave
            )
        )
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
                                    .font(PinguFont.screenTitle)
                                    .foregroundStyle(PinguDesign.ink)
                                    .multilineTextAlignment(.center)

                                Text("Take a moment to soak in your growth.")
                                    .font(PinguFont.body)
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
            viewModel.cancelRegeneration()
        }
    }

    private var reflection: AIReflectionResult? {
        viewModel.reflection
    }

    private func insightCard(icon: String, label: String, title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(PinguDesign.blue)

                Text(label)
                    .font(PinguFont.caption)
                    .tracking(0.8)
                    .foregroundStyle(PinguDesign.muted)
            }

            Text(title)
                .font(PinguFont.sectionTitle)
                .foregroundStyle(PinguDesign.ink)

            Text(body)
                .font(PinguFont.bodyLight)
                .foregroundStyle(PinguDesign.body)
                .lineSpacing(4)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pinguGlass(cornerRadius: 17, tint: 0.22)
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
                    .font(PinguFont.caption)
                    .tracking(0.8)
                    .foregroundStyle(PinguDesign.muted)
            }

            Text(reflection.expressionMoment)
                .font(PinguFont.sectionTitle)
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
        .pinguGlass(cornerRadius: 17, tint: 0.22)
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
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.42))

                Text("\"\(reflection.quote)\"")
                    .font(PinguFont.sectionTitle)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Text("Daily Wisdom")
                    .font(PinguFont.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 26)
                    .frame(height: 34)
                    .background(.white.opacity(0.22))
                    .clipShape(Capsule())
            }
            .padding(26)
        }
        .frame(height: 214)
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
                        .font(PinguFont.cardTitle)
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
            .disabled(!viewModel.canEdit)
            .opacity(viewModel.canEdit ? 1 : 0.48)
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
                if !viewModel.hasSaved {
                    dismiss()
                }
            }
            .disabled(viewModel.hasSaved)
            .font(PinguFont.button)
            .foregroundStyle(PinguDesign.blue)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(PinguDesign.lightBlue)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .opacity(viewModel.hasSaved ? 0.45 : 1)

            Button {
                regenerateReflection()
            } label: {
                Image(systemName: viewModel.isRegenerating ? "sparkles" : "arrow.triangle.2.circlepath")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(PinguDesign.blue)
                    .frame(width: 52, height: 50)
                    .background(PinguDesign.lightBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(!viewModel.canEdit)
            .opacity(viewModel.hasSaved || viewModel.draftEntry == nil ? 0.45 : 1)

            ShareLink(item: shareText) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(PinguDesign.blue)
                    .frame(width: 52, height: 50)
                    .background(PinguDesign.lightBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(viewModel.draftEntry == nil || viewModel.isRegenerating)
            .opacity(viewModel.draftEntry == nil ? 0.45 : 1)

            Button(viewModel.hasSaved ? "Saved" : "Save Entry") {
                saveEntry()
            }
            .disabled(!viewModel.canEdit)
            .font(PinguFont.button)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(viewModel.canEdit ? PinguDesign.blue : PinguDesign.muted)
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
        viewModel.saveEntry(to: destination, questStore: questStore) {
            dismiss()
        }
    }

    private func regenerateReflection() {
        viewModel.regenerateReflection()
    }

    private var shareText: String {
        viewModel.shareText
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
                .font(PinguFont.body)
                .foregroundStyle(PinguDesign.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .pinguGlass(cornerRadius: 26, tint: 0.22)
    }

    private var regenerationStatus: some View {
        Group {
            if viewModel.isRegenerating {
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
            } else if let regenerateMessage = viewModel.regenerateMessage {
                Label(regenerateMessage, systemImage: "sparkles")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(PinguDesign.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .pinguGlass(cornerRadius: 12, tint: 0.22)
            }
        }
    }

    private var aiSessionStatusCard: some View {
        Group {
            if let draftSession = viewModel.draftSession {
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
                .pinguGlass(cornerRadius: 12, tint: 0.22)
            }
        }
    }

    private func sessionStatusItem(icon: String, title: String, value: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(PinguDesign.blue)

            Text(title)
                .font(PinguFont.caption)
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
