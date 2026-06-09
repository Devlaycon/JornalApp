import SwiftUI

struct JournalView: View {
    @EnvironmentObject private var journalStore: ReflectionJournalStore
    @EnvironmentObject private var aiSessionStore: AIReflectionSessionStore
    @StateObject private var viewModel = JournalViewModel()
    let onStartRecording: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                PinguScreenBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        header
                        searchField

                        if journalStore.entries.isEmpty {
                            emptyState
                        } else if filteredEntries.isEmpty {
                            noSearchResults
                        } else {
                            journalSection(title: sectionTitle, entries: filteredEntries)
                        }
                    }
                    .padding(.horizontal, PinguDesign.screenSidePadding)
                    .padding(.top, 22)
                    .padding(.bottom, PinguDesign.bottomBarHeight + 36)
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            onStartRecording()
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 66, height: 66)
                                .background(PinguDesign.blue)
                                .clipShape(Circle())
                                .shadow(color: PinguDesign.blue.opacity(0.26), radius: 16, y: 10)
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 26)
                        .padding(.bottom, PinguDesign.bottomBarHeight + 14)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Journal History")
                    .font(PinguFont.screenTitle)
                    .foregroundStyle(PinguDesign.ink)

                Text("Saved AI reflections")
                    .font(PinguFont.body)
                    .foregroundStyle(PinguDesign.muted)
            }

            Spacer()

            if !journalStore.entries.isEmpty {
                Menu {
                    Button {
                        viewModel.copyExport(from: journalStore)
                    } label: {
                        Label(viewModel.didCopyExport ? "Copied journal" : "Copy journal", systemImage: "doc.on.doc")
                    }

                    ShareLink(item: journalStore.exportText()) {
                        Label("Share journal", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(PinguDesign.blue)
                        .frame(width: 44, height: 44)
                        .pinguGlass(cornerRadius: 22, tint: 0.16)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(PinguDesign.muted)

            TextField("Search journals", text: $viewModel.searchText)
                .font(PinguFont.body)
                .foregroundStyle(PinguDesign.ink)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.clearSearch()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(PinguDesign.muted.opacity(0.76))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
        .frame(height: 56)
        .pinguGlass(cornerRadius: 18, tint: 0.18)
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 66, weight: .semibold))
                .foregroundStyle(PinguDesign.blue)

            VStack(spacing: 8) {
                Text("No saved reflections yet")
                    .font(PinguFont.sectionTitle)
                    .foregroundStyle(PinguDesign.ink)

                Text("Record a real voice check-in, let Circleu analyze it, then save the reflection here.")
                    .font(PinguFont.body)
                    .foregroundStyle(PinguDesign.muted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Button {
                onStartRecording()
            } label: {
                Label("Start recording", systemImage: "mic.fill")
            }
            .buttonStyle(PinguPrimaryButtonStyle())
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .pinguGlass(cornerRadius: 26, tint: 0.22)
    }

    private var noSearchResults: some View {
        VStack(spacing: 14) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(PinguDesign.blue)

            Text("No matching reflections")
                .font(PinguFont.sectionTitle)
                .foregroundStyle(PinguDesign.ink)

            Text("Try a different emotion, word, or date from your saved check-ins.")
                .font(PinguFont.body)
                .foregroundStyle(PinguDesign.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .pinguGlass(cornerRadius: 26, tint: 0.22)
    }

    private func journalSection(title: String, entries: [JournalReflectionEntry]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(PinguFont.cardTitle)
                .foregroundStyle(PinguDesign.ink)

            VStack(spacing: 12) {
                ForEach(entries) { entry in
                    NavigationLink {
                        JournalEntryDetailView(entry: entry)
                    } label: {
                        JournalEntryRow(entry: entry)
                    }
                    .buttonStyle(.plain)
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
    }

    private var filteredEntries: [JournalReflectionEntry] {
        viewModel.filteredEntries(from: journalStore.entries)
    }

    private var sectionTitle: String {
        viewModel.sectionTitle
    }
}

private struct JournalEntryRow: View {
    let entry: JournalReflectionEntry

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "sparkles")
                .font(.system(size: 21, weight: .bold))
                .foregroundStyle(PinguDesign.blue)
                .frame(width: 50, height: 50)
                .background(PinguDesign.lightBlue.opacity(0.66))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 7) {
                Text(entry.displayTitle)
                    .font(PinguFont.cardTitle)
                    .foregroundStyle(PinguDesign.ink)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Label(entry.createdAt.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                    Text(formattedDuration(entry.durationSeconds))
                }
                .font(PinguFont.caption)
                .foregroundStyle(PinguDesign.muted)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 10) {
                Text(entry.displayEmotion)
                    .font(PinguFont.caption)
                    .foregroundStyle(PinguDesign.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(PinguDesign.lightBlue.opacity(0.62))
                    .clipShape(Capsule())

                Text(entry.engineName)
                    .font(PinguFont.tiny)
                    .foregroundStyle(PinguDesign.muted)
                    .lineLimit(1)
            }
        }
        .padding(16)
        .pinguGlass(cornerRadius: 22, tint: 0.22)
    }

    private func formattedDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let seconds = seconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    JournalView(onStartRecording: {})
        .environmentObject(ReflectionJournalStore())
        .environmentObject(AIReflectionSessionStore())
}
