import SwiftUI

struct JournalEntryDetailView: View {
    let entry: JournalReflectionEntry
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var journalStore: ReflectionJournalStore
    @StateObject private var viewModel = JournalEntryDetailViewModel()
    @State private var showShareSheet = false

    private var currentEntry: JournalReflectionEntry {
        viewModel.currentEntry(fallback: entry, journalStore: journalStore)
    }

    var body: some View {
        ZStack {
            PinguAurora()

            VStack(spacing: 0) {
                DemoNavBar(
                    title: "Reflection",
                    subtitle: currentEntry.createdAt.formatted(date: .abbreviated, time: .omitted),
                    onBack: { dismiss() }
                )

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        headerCard
                        insightCard
                        quoteCard
                        transcriptCard
                        shareToCircleButton
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showShareSheet) {
            JournalCircleShareSheet(entry: currentEntry)
        }
    }

    private var shareToCircleButton: some View {
        Button {
            showShareSheet = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "person.2.wave.2.fill")
                    .font(.system(size: 16, weight: .bold))
                Text("Share to a circle")
                    .font(.system(size: 14.5, weight: .bold, design: .rounded))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(GlassPrimaryFill(cornerRadius: 20))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Pingu.accent.opacity(0.25), radius: 12, y: 6)
        }
        .buttonStyle(PressableButtonStyle())
    }

    // 1. Emotion + title + summary
    private var headerCard: some View {
        let meta = PinguEmotionMeta.of(currentEntry.displayEmotion)
        return GlassCard(style: .strong, sheen: true) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    Text(meta.emoji)
                    Text(currentEntry.displayEmotion)
                }
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(meta.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(meta.bg)
                .clipShape(Capsule())
                .padding(.bottom, 12)

                Text(currentEntry.displayTitle)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Pingu.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 8)

                Text(currentEntry.displaySummary)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(Pingu.body)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)
        }
    }

    // 2. Insight
    private var insightCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .bold))
                    Text("INSIGHT")
                        .tracking(0.6)
                }
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Pingu.accent)
                .padding(.bottom, 8)

                Text(currentEntry.result.insight)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(Pingu.ink)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)
        }
    }

    // 3. Quote
    private var quoteCard: some View {
        GlassCard(style: .strong) {
            VStack(spacing: 8) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Pingu.accent.opacity(0.4))

                Text("“\(currentEntry.result.quote)”")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .italic()
                    .foregroundStyle(Pingu.ink)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
        }
    }

    // 4. Transcript
    private var transcriptCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 0) {
                Text("WHAT YOU SAID")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(0.6)
                    .foregroundStyle(Pingu.slate)
                    .padding(.bottom, 8)

                Text(currentEntry.transcript)
                    .font(.system(size: 13.5, weight: .regular, design: .rounded))
                    .foregroundStyle(Pingu.body)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)
        }
    }
}

#Preview {
    NavigationStack {
        JournalEntryDetailView(entry: .preview)
    }
    .environmentObject(ReflectionJournalStore())
}
