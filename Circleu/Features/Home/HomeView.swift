import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var journalStore: ReflectionJournalStore
    @EnvironmentObject private var profileStore: UserProfileStore
    @EnvironmentObject private var questStore: QuestStore
    @StateObject private var viewModel = HomeViewModel()
    let onStartRecording: () -> Void
    let onOpenJournal: () -> Void
    let onOpenTips: () -> Void

    var body: some View {
        ZStack {
            PinguScreenBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    greeting
                    heroRecordPanel
                    dailyPromptCard
                    activeQuestCard
                    statsRow
                    latestReflectionSection
                }
                .padding(.horizontal, PinguDesign.screenSidePadding)
                .padding(.top, 24)
                .padding(.bottom, PinguDesign.bottomBarHeight + 28)
            }
        }
        .sheet(item: $viewModel.selectedEntry) { entry in
            NavigationStack {
                JournalEntryDetailView(entry: entry)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") {
                                viewModel.selectedEntry = nil
                            }
                        }
                    }
            }
        }
    }

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hey \(profileStore.firstName),")
                .font(PinguFont.hero)
                .foregroundStyle(PinguDesign.ink)

            Text(viewModel.greetingSubtitle(entries: journalStore.entries))
                .font(PinguFont.body)
                .foregroundStyle(PinguDesign.muted)
                .lineSpacing(3)
        }
    }

    private var heroRecordPanel: some View {
        VStack(spacing: 18) {
            ZStack(alignment: .topTrailing) {
                pinguOrb

                Text(viewModel.latestEmotionLabel(entries: journalStore.entries))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(PinguDesign.blue)
                    .padding(.horizontal, 12)
                    .frame(height: 32)
                    .background(.white)
                    .clipShape(Capsule())
                    .shadow(color: PinguDesign.deepBlue.opacity(0.08), radius: 10, y: 5)
                    .offset(x: 8, y: 4)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 7) {
                Text("Start today's reflection")
                    .font(PinguFont.sectionTitle)
                    .foregroundStyle(PinguDesign.ink)

                Text("Speak or type a quick check-in.")
                    .font(PinguFont.body)
                    .foregroundStyle(PinguDesign.muted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            Button {
                onStartRecording()
            } label: {
                Label("Record now", systemImage: "mic.fill")
                    .font(PinguFont.button)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(PinguDesign.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: PinguDesign.blue.opacity(0.18), radius: 12, y: 7)
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .pinguGlass(cornerRadius: 24, tint: 0.22)
    }

    private var pinguOrb: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 76, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [
                            PinguDesign.aqua,
                            PinguDesign.sky,
                            PinguDesign.blue
                        ],
                        center: .center,
                        startRadius: 18,
                        endRadius: 160
                    )
                )
                .frame(width: 170, height: 170)
                .shadow(color: PinguDesign.blue.opacity(0.18), radius: 18, y: 10)

            Image("PinguMascot")
                .resizable()
                .scaledToFit()
                .frame(width: 126, height: 126)
                .clipShape(RoundedRectangle(cornerRadius: 48, style: .continuous))

            Image(systemName: "heart.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(PinguDesign.orange)
                .frame(width: 44, height: 44)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: PinguDesign.ink.opacity(0.13), radius: 10, y: 5)
                .offset(x: 72, y: -58)
        }
    }

    private var dailyPromptCard: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(PinguDesign.orange)
                .frame(width: 42, height: 42)
                .background(PinguDesign.lightBlue.opacity(0.68))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 7) {
                Text("Today's prompt")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(PinguDesign.muted)

                Text(viewModel.dailyPrompt(for: profileStore))
                    .font(PinguFont.cardTitle)
                    .foregroundStyle(PinguDesign.ink)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Button {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    viewModel.advanceDailyPrompt(profileStore: profileStore)
                }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(PinguDesign.blue)
                    .frame(width: 40, height: 40)
                    .background(PinguDesign.lightBlue.opacity(0.76))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .pinguGlass(cornerRadius: 22, tint: 0.12)
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            HomeStatTile(value: "\(progress.entryCount)", label: "Entries", icon: "book.closed.fill")
            HomeStatTile(value: "\(progress.streak)", label: "Streak", icon: "flame.fill")
            HomeStatTile(value: viewModel.latestEmotionLabel(entries: journalStore.entries), label: "Latest", icon: "heart.fill")
        }
    }

    private var activeQuestCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 11) {
                Image(systemName: activeQuest == nil ? "flag" : "flag.fill")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(activeQuest == nil ? PinguDesign.blue : .white)
                    .frame(width: 38, height: 38)
                    .background(activeQuest == nil ? PinguDesign.lightBlue.opacity(0.78) : PinguDesign.orange)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("Next action")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(PinguDesign.muted)

                    Text(betaState.nextActionTitle)
                        .font(PinguFont.cardTitle)
                        .foregroundStyle(PinguDesign.ink)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            Text(betaState.nextActionSubtitle)
                .font(PinguFont.body)
                .foregroundStyle(PinguDesign.body)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            if let quest = activeQuest {
                if let sourceEntry = viewModel.sourceEntry(for: quest, entries: journalStore.entries) {
                    Button {
                        viewModel.selectedEntry = sourceEntry
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(PinguDesign.blue)

                            VStack(alignment: .leading, spacing: 3) {
                                Text("From reflection")
                                    .font(PinguFont.caption)
                                    .foregroundStyle(PinguDesign.muted)

                                Text(sourceEntry.displayTitle)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundStyle(PinguDesign.ink)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(PinguDesign.muted)
                        }
                        .padding(12)
                        .background(PinguDesign.lightBlue.opacity(0.52))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 10) {
                    Button {
                        onOpenTips()
                    } label: {
                        Label("Open Tips", systemImage: "checklist.checked")
                    }
                    .buttonStyle(HomeQuestButtonStyle(isPrimary: true))
                }

                HStack(spacing: 10) {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.84)) {
                            viewModel.complete(quest, questStore: questStore)
                        }
                    } label: {
                        Label("Complete", systemImage: "checkmark")
                    }
                    .buttonStyle(HomeQuestButtonStyle(isPrimary: false))

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.84)) {
                            viewModel.skip(quest, questStore: questStore)
                        }
                    } label: {
                        Label("Skip", systemImage: "forward.fill")
                    }
                    .buttonStyle(HomeQuestButtonStyle(isPrimary: false))
                }
            } else {
                Button {
                    onStartRecording()
                } label: {
                    Label("Start reflection", systemImage: "mic.fill")
                }
                .buttonStyle(HomeQuestButtonStyle(isPrimary: true))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pinguGlass(cornerRadius: 22, tint: 0.22)
    }

    private var latestReflectionSection: some View {
        Group {
            if let latestEntry = journalStore.entries.first {
                Button {
                    viewModel.selectedEntry = latestEntry
                } label: {
                    latestReflectionCard(latestEntry)
                }
                .buttonStyle(.plain)
            } else {
                emptyReflectionCard
            }
        }
    }

    private func latestReflectionCard(_ entry: JournalReflectionEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Latest reflection", systemImage: "sparkles")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(PinguDesign.blue)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(PinguDesign.muted)
            }

            Text(entry.result.title)
                .font(PinguFont.cardTitle)
                .foregroundStyle(PinguDesign.ink)
                .lineLimit(2)

            Text(entry.result.summary)
                .font(PinguFont.body)
                .foregroundStyle(PinguDesign.body)
                .lineSpacing(4)
                .lineLimit(3)

            HStack {
                Text(entry.result.emotion)
                    .font(PinguFont.caption)
                    .foregroundStyle(PinguDesign.blue)
                    .padding(.horizontal, 10)
                    .frame(height: 28)
                    .background(PinguDesign.lightBlue.opacity(0.72))
                    .clipShape(Capsule())

                Spacer()

                Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(PinguFont.caption)
                    .foregroundStyle(PinguDesign.muted)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pinguGlass(cornerRadius: 24, tint: 0.22)
    }

    private var emptyReflectionCard: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(PinguDesign.blue)

            VStack(alignment: .leading, spacing: 5) {
                Text("Your first reflection is waiting")
                    .font(PinguFont.cardTitle)
                    .foregroundStyle(PinguDesign.ink)

                Text("Record or type a short check-in to fill this space with your own insight.")
                    .font(PinguFont.body)
                    .foregroundStyle(PinguDesign.muted)
                    .lineSpacing(3)
            }

            Spacer(minLength: 0)

            Button {
                onStartRecording()
            } label: {
                Image(systemName: "mic.fill")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(PinguDesign.blue)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .pinguGlass(cornerRadius: 24, tint: 0.22)
    }

    private var activeQuest: Quest? {
        viewModel.activeQuest(from: questStore)
    }

    private var activeQuestSupportText: String {
        viewModel.activeQuestSupportText(activeQuest: activeQuest)
    }

    private var betaState: DailyReflectionBetaState {
        viewModel.betaState(entries: journalStore.entries, quests: questStore.quests)
    }

    private var progress: AppProgressSnapshot {
        viewModel.progress(entries: journalStore.entries, quests: questStore.quests)
    }
}

private struct HomeQuestButtonStyle: ButtonStyle {
    let isPrimary: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundStyle(isPrimary ? .white : PinguDesign.blue)
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(isPrimary ? PinguDesign.blue : PinguDesign.lightBlue.opacity(0.76))
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .opacity(configuration.isPressed ? 0.76 : 1)
    }
}

private struct HomeStatTile: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(PinguDesign.blue)

            Text(value)
                .font(.system(size: value.count > 7 ? 14 : 20, weight: .bold, design: .rounded))
                .foregroundStyle(PinguDesign.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .monospacedDigit()

            Text(label)
                .font(PinguFont.caption)
                .foregroundStyle(PinguDesign.muted)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 94)
        .pinguGlass(cornerRadius: 20, tint: 0.22)
    }
}

#Preview {
    HomeView(onStartRecording: {}, onOpenJournal: {}, onOpenTips: {})
        .environmentObject(ReflectionJournalStore())
        .environmentObject(UserProfileStore())
        .environmentObject(QuestStore())
}
