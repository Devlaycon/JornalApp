import SwiftUI

struct JournalEntryDetailView: View {
    let entry: JournalReflectionEntry
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var journalStore: ReflectionJournalStore
    @EnvironmentObject private var aiSessionStore: AIReflectionSessionStore
    @EnvironmentObject private var questStore: QuestStore
    @EnvironmentObject private var circleStore: CircleStore
    @StateObject private var viewModel = JournalEntryDetailViewModel()

    private var currentEntry: JournalReflectionEntry {
        viewModel.currentEntry(fallback: entry, journalStore: journalStore)
    }

    private var session: AIReflectionSession? {
        viewModel.session(for: currentEntry, aiSessionStore: aiSessionStore)
    }

    var body: some View {
        ZStack {
            PinguScreenBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(currentEntry.displayTitle)
                            .font(PinguFont.screenTitle)
                            .foregroundStyle(PinguDesign.ink)

                        HStack(spacing: 10) {
                            Text(currentEntry.displayEmotion)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(PinguDesign.blue)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(PinguDesign.lightBlue.opacity(0.66))
                                .clipShape(Capsule())

                            Text(currentEntry.engineName)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(PinguDesign.muted)
                        }
                    }

                    detailCard(title: "Summary", body: currentEntry.displaySummary, icon: "text.alignleft")
                    detailCard(title: "Insight", body: currentEntry.result.insight, icon: "heart.fill")
                    detailCard(title: "Expression moment", body: currentEntry.result.expressionMoment, icon: "waveform")
                    detailCard(title: "Suggested quest", body: currentEntry.result.suggestedQuest, icon: "flag.fill")
                    tipsActionsCard
                    workspaceCard
                    sessionHistoryCard

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Transcript")
                            .font(PinguFont.cardTitle)
                            .foregroundStyle(PinguDesign.ink)

                        Text(currentEntry.transcript)
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundStyle(PinguDesign.body)
                            .lineSpacing(5)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .pinguGlass(cornerRadius: 22, tint: 0.22)

                    Text(currentEntry.createdAt.formatted(date: .complete, time: .shortened))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(PinguDesign.muted)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal, PinguDesign.screenSidePadding)
                .padding(.top, 20)
                .padding(.bottom, 34)
            }
        }
        .navigationTitle("Reflection")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        viewModel.copyReflection(currentEntry, journalStore: journalStore)
                    } label: {
                        Label(viewModel.didCopy ? "Copied reflection" : "Copy reflection", systemImage: "doc.on.doc")
                    }

                    ShareLink(item: journalStore.shareText(for: currentEntry)) {
                        Label("Share reflection", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        viewModel.showEditSheet = true
                    } label: {
                        Label("Edit workspace", systemImage: "pencil")
                    }

                    Button(role: .destructive) {
                        deleteEntry()
                        dismiss()
                    } label: {
                        Label("Delete reflection", systemImage: "trash.fill")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $viewModel.showCircleShareSheet) {
            JournalCircleShareSheet(entry: currentEntry)
                .environmentObject(circleStore)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $viewModel.showEditSheet) {
            JournalWorkspaceEditSheet(entry: currentEntry) { title, emotion, privateNote, tags in
                journalStore.updateWorkspace(
                    entry: currentEntry,
                    title: title,
                    emotion: emotion,
                    privateNote: privateNote,
                    tags: tags
                )
            }
        }
    }

    private func detailCard(title: String, body: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(PinguDesign.blue)
                Text(title)
                    .font(PinguFont.cardTitle)
                    .foregroundStyle(PinguDesign.ink)
            }

            Text(body)
                .font(PinguFont.body)
                .foregroundStyle(PinguDesign.body)
                .lineSpacing(4)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pinguGlass(cornerRadius: 22, tint: 0.22)
    }

    private var workspaceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(PinguDesign.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Workspace")
                        .font(PinguFont.cardTitle)
                        .foregroundStyle(PinguDesign.ink)

                    Text(currentEntry.lastEditedAt.map { "Edited \($0.formatted(date: .abbreviated, time: .shortened))" } ?? "Private workspace")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(PinguDesign.muted)
                }

                Spacer()

                Button {
                    viewModel.showEditSheet = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                        .labelStyle(.iconOnly)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(PinguDesign.blue)
                        .frame(width: 38, height: 38)
                        .background(PinguDesign.lightBlue.opacity(0.72))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Edit workspace")
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Private note")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(PinguDesign.ink)

                Text(currentEntry.privateNote.isEmpty ? "No private note yet." : currentEntry.privateNote)
                    .font(PinguFont.body)
                    .foregroundStyle(currentEntry.privateNote.isEmpty ? PinguDesign.muted : PinguDesign.body)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if currentEntry.tags.isEmpty {
                Text("No tags yet.")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(PinguDesign.muted)
            } else {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 88), spacing: 8, alignment: .leading)],
                    alignment: .leading,
                    spacing: 8
                ) {
                    ForEach(currentEntry.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(PinguDesign.blue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(PinguDesign.lightBlue.opacity(0.62))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pinguGlass(cornerRadius: 22, tint: 0.22)
    }

    private var sessionHistoryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(PinguDesign.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Session history")
                        .font(PinguFont.cardTitle)
                        .foregroundStyle(PinguDesign.ink)

                    Text(session?.source.label ?? "No linked AI session")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(PinguDesign.muted)
                }

                Spacer()
            }

            if let session {
                HStack(spacing: 10) {
                    sessionMetric(title: "Engine", value: session.engineName)
                    sessionMetric(title: "Attempts", value: "\(session.attempts.count)")
                }

                HStack(spacing: 10) {
                    sessionMetric(title: "Words", value: "\(session.wordCount)")
                    sessionMetric(title: "Selected", value: session.selectedAttempt?.status.label ?? "None")
                }
            } else {
                Text("This reflection does not have a linked AI session history.")
                    .font(PinguFont.body)
                    .foregroundStyle(PinguDesign.muted)
                    .lineSpacing(4)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pinguGlass(cornerRadius: 22, tint: 0.22)
    }

    private func sessionMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(PinguFont.caption)
                .foregroundStyle(PinguDesign.muted)

            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(PinguDesign.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PinguDesign.lightBlue.opacity(0.42))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var tipsActionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "checklist.checked")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(PinguDesign.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily tip")
                        .font(PinguFont.cardTitle)
                        .foregroundStyle(PinguDesign.ink)

                    Text(questStatusText)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(PinguDesign.muted)
                }

                Spacer()
            }

            Text(currentEntry.result.suggestedQuest)
                .font(PinguFont.body)
                .foregroundStyle(PinguDesign.body)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            questActionButtons

            Divider()
                .overlay(PinguDesign.border.opacity(0.6))

            Button {
                viewModel.showCircleShareSheet = true
            } label: {
                Label("Save insight to a community", systemImage: "person.2.wave.2.fill")
            }
            .buttonStyle(PinguSecondaryButtonStyle())
            .disabled(circleStore.circles.isEmpty)
            .opacity(circleStore.circles.isEmpty ? 0.55 : 1)

            if circleStore.circles.isEmpty {
                Text("Create a private community from the Circle tab before saving this reflection into a support space.")
                    .font(PinguFont.caption)
                    .foregroundStyle(PinguDesign.muted)
                    .lineSpacing(3)
            } else if circleStore.circles.allSatisfy({ circleStore.hasShared(entry: currentEntry, to: $0) }) {
                Text("This reflection is already saved in every community.")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(PinguDesign.blue)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pinguGlass(cornerRadius: 22, tint: 0.22)
    }

    @ViewBuilder
    private var questActionButtons: some View {
        if let quest = questStore.quest(for: currentEntry) {
            switch quest.status {
            case .active:
                HStack(spacing: 10) {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.84)) {
                            viewModel.complete(quest, questStore: questStore)
                        }
                    } label: {
                        Label("Complete", systemImage: "checkmark")
                    }
                    .buttonStyle(PinguPrimaryButtonStyle())

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.84)) {
                            viewModel.skip(quest, questStore: questStore)
                        }
                    } label: {
                        Label("Skip", systemImage: "forward.fill")
                    }
                    .buttonStyle(PinguSecondaryButtonStyle())
                }

            case .completed:
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.84)) {
                        viewModel.activateSuggestedQuest(from: currentEntry, questStore: questStore)
                    }
                } label: {
                    Label("Restart tip", systemImage: "arrow.clockwise")
                }
                .buttonStyle(PinguSecondaryButtonStyle())

            case .skipped:
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.84)) {
                        viewModel.activateSuggestedQuest(from: currentEntry, questStore: questStore)
                    }
                } label: {
                    Label("Make active again", systemImage: "flag.fill")
                }
                .buttonStyle(PinguPrimaryButtonStyle())
            }
        } else {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.84)) {
                    viewModel.activateSuggestedQuest(from: currentEntry, questStore: questStore)
                }
            } label: {
                Label("Add to next actions", systemImage: "flag.fill")
            }
            .buttonStyle(PinguPrimaryButtonStyle())
        }
    }

    private var questStatusText: String {
        viewModel.questStatusText(for: currentEntry, questStore: questStore)
    }

    private func deleteEntry() {
        viewModel.delete(currentEntry, journalStore: journalStore, aiSessionStore: aiSessionStore)
    }
}

#Preview {
    NavigationStack {
        JournalEntryDetailView(entry: .preview)
    }
    .environmentObject(ReflectionJournalStore())
    .environmentObject(AIReflectionSessionStore())
    .environmentObject(QuestStore())
    .environmentObject(CircleStore())
}
