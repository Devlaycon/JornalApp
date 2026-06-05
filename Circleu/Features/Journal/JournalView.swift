import SwiftUI
import UIKit

struct JournalView: View {
    @EnvironmentObject private var journalStore: ReflectionJournalStore
    @EnvironmentObject private var aiSessionStore: AIReflectionSessionStore
    @State private var searchText = ""
    @State private var didCopyExport = false
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
                        UIPasteboard.general.string = journalStore.exportText()
                        didCopyExport = true
                    } label: {
                        Label(didCopyExport ? "Copied journal" : "Copy journal", systemImage: "doc.on.doc")
                    }

                    ShareLink(item: journalStore.exportText()) {
                        Label("Share journal", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(PinguDesign.blue)
                        .frame(width: 44, height: 44)
                        .background(.white)
                        .clipShape(Circle())
                        .shadow(color: PinguDesign.deepBlue.opacity(0.05), radius: 10, y: 5)
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

            TextField("Search journals", text: $searchText)
                .font(PinguFont.body)
                .foregroundStyle(PinguDesign.ink)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
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
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(PinguDesign.border.opacity(0.72), lineWidth: 1)
        }
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
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: PinguDesign.deepBlue.opacity(0.06), radius: 16, y: 8)
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
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: PinguDesign.deepBlue.opacity(0.06), radius: 16, y: 8)
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
                            delete(entry)
                        } label: {
                            Label("Delete", systemImage: "trash.fill")
                        }
                    }
                    .contextMenu {
                        Button {
                            UIPasteboard.general.string = journalStore.shareText(for: entry)
                        } label: {
                            Label("Copy reflection", systemImage: "doc.on.doc")
                        }

                        ShareLink(item: journalStore.shareText(for: entry)) {
                            Label("Share reflection", systemImage: "square.and.arrow.up")
                        }

                        Button(role: .destructive) {
                            delete(entry)
                        } label: {
                            Label("Delete reflection", systemImage: "trash.fill")
                        }
                    }
                }
            }
        }
    }

    private var filteredEntries: [JournalReflectionEntry] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return journalStore.entries }

        return journalStore.entries.filter { entry in
            [
                entry.displayTitle,
                entry.displayEmotion,
                entry.displaySummary,
                entry.result.insight,
                entry.result.quote,
                entry.privateNote,
                entry.tags.joined(separator: " "),
                entry.transcript,
                entry.engineName
            ]
            .joined(separator: " ")
            .lowercased()
            .contains(query)
        }
    }

    private var sectionTitle: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Saved reflections" : "Search results"
    }

    private func delete(_ entry: JournalReflectionEntry) {
        journalStore.delete(entry, aiSessionStore: aiSessionStore)
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
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: PinguDesign.deepBlue.opacity(0.05), radius: 14, y: 7)
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
