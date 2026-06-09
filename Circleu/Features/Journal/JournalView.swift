import SwiftUI

struct JournalView: View {
    @EnvironmentObject private var journalStore: ReflectionJournalStore
    @EnvironmentObject private var aiSessionStore: AIReflectionSessionStore
    @StateObject private var viewModel = JournalViewModel()
    let onStartRecording: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                PinguAurora()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        header
                        searchField

                        if filteredEntries.isEmpty {
                            emptyState
                        } else {
                            entryList
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 54)
                    .padding(.bottom, 120)
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Kicker("YOUR PRIVATE JOURNAL")
            Text("Journal")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Pingu.ink)
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Pingu.muted)

            TextField("Search reflections…", text: $viewModel.searchText)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(Pingu.ink)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .glass(.regular, cornerRadius: 16)
    }

    private var emptyState: some View {
        VStack(spacing: 0) {
            PinguMascot(size: 120, mood: .idle)

            Text("Nothing here yet")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(Pingu.ink)
                .padding(.top, 12)

            Text("Your saved reflections will collect here, like a quiet diary.")
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(Pingu.slate)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
                .padding(.bottom, 20)
                .padding(.horizontal, 24)

            Button {
                onStartRecording()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text("Record one now")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(GlassPrimaryFill(cornerRadius: 999))
            }
            .buttonStyle(PressableButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    private var entryList: some View {
        VStack(spacing: 12) {
            ForEach(filteredEntries) { entry in
                NavigationLink {
                    JournalEntryDetailView(entry: entry)
                } label: {
                    JournalEntryRow(entry: entry, timeAgo: viewModel.timeAgo(entry.createdAt))
                }
                .buttonStyle(PressableButtonStyle())
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        viewModel.delete(entry, journalStore: journalStore, aiSessionStore: aiSessionStore)
                    } label: {
                        Label("Delete", systemImage: "trash.fill")
                    }
                }
                .contextMenu {
                    Button {
                        viewModel.copyReflection(entry, journalStore: journalStore)
                    } label: {
                        Label("Copy reflection", systemImage: "doc.on.doc")
                    }

                    ShareLink(item: journalStore.shareText(for: entry)) {
                        Label("Share reflection", systemImage: "square.and.arrow.up")
                    }

                    Button(role: .destructive) {
                        viewModel.delete(entry, journalStore: journalStore, aiSessionStore: aiSessionStore)
                    } label: {
                        Label("Delete reflection", systemImage: "trash.fill")
                    }
                }
            }
        }
    }

    private var filteredEntries: [JournalReflectionEntry] {
        viewModel.filteredEntries(from: journalStore.entries)
    }
}

private struct JournalEntryRow: View {
    let entry: JournalReflectionEntry
    let timeAgo: String

    var body: some View {
        let meta = PinguEmotionMeta.of(entry.displayEmotion)
        return GlassCard {
            HStack(alignment: .top, spacing: 12) {
                Text(meta.emoji)
                    .font(.system(size: 18))
                    .frame(width: 40, height: 40)
                    .background(meta.bg)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(entry.displayTitle)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(Pingu.ink)
                            .lineLimit(1)

                        Spacer(minLength: 0)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Pingu.muted)
                    }

                    Text(entry.displaySummary)
                        .font(.system(size: 12.5, weight: .regular, design: .rounded))
                        .foregroundStyle(Pingu.slate)
                        .lineSpacing(2)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 8) {
                        Text(entry.displayEmotion)
                            .font(.system(size: 10.5, weight: .bold, design: .rounded))
                            .foregroundStyle(meta.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(meta.bg)
                            .clipShape(Capsule())

                        Text(timeAgo)
                            .font(.system(size: 10.5, weight: .medium, design: .rounded))
                            .foregroundStyle(Pingu.muted)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(16)
        }
    }
}

#Preview {
    JournalView(onStartRecording: {})
        .environmentObject(ReflectionJournalStore())
        .environmentObject(AIReflectionSessionStore())
}
