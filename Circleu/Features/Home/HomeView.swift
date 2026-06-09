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
            PinguAurora()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    greeting.slideUp()
                    heroRecordPanel.slideUp(0.06)
                    dailyPromptCard.slideUp(0.12)
                    statsRow.slideUp(0.24)
                    if let latest = journalStore.entries.first {
                        latestReflectionSection(latest).slideUp(0.3)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 64)
                .padding(.bottom, 120)
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

    // MARK: - Greeting

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 4) {
            Kicker(viewModel.greetingKicker())

            Text("Hey \(profileStore.firstName) 👋")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(Pingu.ink)

            Text(viewModel.greetingSubtitle(streak: progress.streak))
                .font(.system(size: 13.5, weight: .regular, design: .rounded))
                .foregroundStyle(Pingu.slate)
        }
    }

    // MARK: - Hero record panel

    private var heroRecordPanel: some View {
        GlassCard(style: .strong, sheen: true) {
            VStack(spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    PinguMascot(size: 120, mood: .idle, ring: true)
                        .frame(maxWidth: .infinity)

                    emotionPill
                        .padding(.top, 4)
                        .padding(.trailing, 4)
                }
                .padding(.bottom, 12)

                Text("Start today's reflection")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Pingu.ink)

                Text("Speak or type a quick check-in.")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(Pingu.slate)
                    .padding(.top, 1)
                    .padding(.bottom, 16)

                PinguGlassButton(action: onStartRecording) {
                    Label("Record now", systemImage: "mic.fill")
                }
            }
            .padding(24)
        }
    }

    private var emotionPill: some View {
        let latest = journalStore.entries.first
        let meta = PinguEmotionMeta.of(latest?.result.emotion)
        return HStack(spacing: 4) {
            Text(meta.emoji)
                .font(.system(size: 12))
            Text(latest?.result.emotion ?? "Ready")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Pingu.accent)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .glass(.pill, cornerRadius: 999)
    }

    // MARK: - Daily prompt

    private var dailyPromptCard: some View {
        GlassCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Pingu.amber)
                    .frame(width: 40, height: 40)
                    .glass(.pill, cornerRadius: 999)

                VStack(alignment: .leading, spacing: 4) {
                    Text("TODAY'S PROMPT")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(0.6)
                        .foregroundStyle(Pingu.slate)

                    Text(viewModel.dailyPrompt(entries: journalStore.entries))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Pingu.ink)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .padding(16)
        }
    }

    // MARK: - Stats

    private var statsRow: some View {
        let latest = journalStore.entries.first
        return HStack(spacing: 10) {
            HomeStat(value: "\(journalStore.entries.count)", label: "Entries") {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Pingu.accent)
            }
            HomeStat(value: "\(progress.streak)", label: "Streak") {
                Image(systemName: "flame.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Pingu.amber)
            }
            HomeStat(value: latest?.result.emotion ?? "—", label: "Latest") {
                Text(latest != nil ? PinguEmotionMeta.of(latest?.result.emotion).emoji : "✨")
                    .font(.system(size: 14))
            }
        }
    }

    // MARK: - Latest reflection

    private func latestReflectionSection(_ entry: JournalReflectionEntry) -> some View {
        let meta = PinguEmotionMeta.of(entry.result.emotion)
        return Button {
            viewModel.selectedEntry = entry
        } label: {
            GlassCard {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 13, weight: .bold))
                            Text("Latest reflection")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(Pingu.accent)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Pingu.muted)
                    }
                    .padding(.bottom, 8)

                    Text(entry.result.title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Pingu.ink)
                        .multilineTextAlignment(.leading)
                        .padding(.bottom, 4)

                    Text(entry.result.summary)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(Pingu.body)
                        .lineSpacing(3)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 12)

                    HStack {
                        HStack(spacing: 4) {
                            Text(meta.emoji)
                            Text(entry.result.emotion)
                        }
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(meta.color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(meta.bg)
                        .clipShape(Capsule())

                        Spacer()

                        Text(viewModel.timeAgo(entry.createdAt))
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(Pingu.muted)
                    }
                }
                .padding(20)
            }
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var progress: AppProgressSnapshot {
        viewModel.progress(entries: journalStore.entries, quests: questStore.quests)
    }
}

// MARK: - Stat tile (lg-glass rounded-[18px])

private struct HomeStat<Icon: View>: View {
    let value: String
    let label: String
    @ViewBuilder var icon: Icon

    var body: some View {
        VStack(spacing: 6) {
            icon
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Pingu.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Pingu.slate)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .glass(.regular, cornerRadius: 18)
    }
}

#Preview {
    HomeView(onStartRecording: {}, onOpenJournal: {}, onOpenTips: {})
        .environmentObject(ReflectionJournalStore())
        .environmentObject(UserProfileStore())
        .environmentObject(QuestStore())
}
