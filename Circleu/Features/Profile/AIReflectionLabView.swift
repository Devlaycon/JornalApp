import SwiftUI

struct AIReflectionLabView: View {
    @EnvironmentObject private var aiSessionStore: AIReflectionSessionStore
    @StateObject private var viewModel = AIReflectionLabViewModel()

    var body: some View {
        ZStack {
            PinguScreenBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    exportCard

                    if aiSessionStore.sessions.isEmpty {
                        emptyState
                    } else {
                        sessionList
                    }
                }
                .padding(.horizontal, PinguDesign.screenSidePadding)
                .padding(.top, 20)
                .padding(.bottom, 34)
            }
        }
        .navigationTitle("AI Lab")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $viewModel.selectedSession) { session in
            AIReflectionSessionExportDetailView(session: session) {
                viewModel.copySession(session)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AI Lab")
                .font(PinguFont.screenTitle)
                .foregroundStyle(PinguDesign.ink)

            Text(viewModel.statusMessage)
                .font(PinguFont.body)
                .foregroundStyle(PinguDesign.muted)
                .lineSpacing(4)
        }
    }

    private var exportCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("AI session export", systemImage: "cpu")
                .font(PinguFont.cardTitle)
                .foregroundStyle(PinguDesign.ink)

            Text("\(aiSessionStore.sessions.count) session\(aiSessionStore.sessions.count == 1 ? "" : "s") available for QA review.")
                .font(PinguFont.body)
                .foregroundStyle(PinguDesign.muted)

            HStack(spacing: 10) {
                Button {
                    viewModel.copyAll(from: aiSessionStore)
                } label: {
                    Label("Copy AI QA", systemImage: "doc.on.doc")
                }
                .buttonStyle(PinguSecondaryButtonStyle())

                ShareLink(item: aiSessionStore.exportText()) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(PinguPrimaryButtonStyle())
            }
        }
        .padding(16)
        .pinguGlass(cornerRadius: 22, tint: 0.22)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("No AI sessions yet", systemImage: "tray")
                .font(PinguFont.cardTitle)
                .foregroundStyle(PinguDesign.ink)

            Text("Seed demo data or complete a reflection to populate the AI lab.")
                .font(PinguFont.body)
                .foregroundStyle(PinguDesign.muted)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .pinguGlass(cornerRadius: 22, tint: 0.22)
    }

    private var sessionList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Sessions", systemImage: "list.bullet.rectangle")
                .font(PinguFont.cardTitle)
                .foregroundStyle(PinguDesign.ink)

            ForEach(aiSessionStore.sessions) { session in
                Button {
                    viewModel.selectedSession = session
                } label: {
                    AIReflectionSessionRow(session: session)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct AIReflectionSessionRow: View {
    let session: AIReflectionSession

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(PinguDesign.blue)
                    .frame(width: 34, height: 34)
                    .background(PinguDesign.lightBlue.opacity(0.75))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(PinguFont.cardTitle)
                        .foregroundStyle(PinguDesign.ink)
                        .lineLimit(2)

                    Text(session.updatedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(PinguDesign.muted)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(PinguDesign.muted)
                    .padding(.top, 8)
            }

            VStack(alignment: .leading, spacing: 8) {
                AIReflectionLabMetric(title: "Source", value: session.source.label, systemImage: "waveform")
                AIReflectionLabMetric(title: "Engine", value: session.engineName, systemImage: "cpu")

                HStack(spacing: 8) {
                    AIReflectionLabMetric(
                        title: "Attempts",
                        value: "\(session.attempts.count)",
                        systemImage: "arrow.triangle.2.circlepath"
                    )

                    AIReflectionLabMetric(
                        title: "Words",
                        value: "\(session.wordCount)",
                        systemImage: "text.word.spacing"
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .pinguGlass(cornerRadius: 22, tint: 0.22)
    }

    private var title: String {
        let selectedTitle = session.selectedResult?.title.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return selectedTitle.isEmpty ? "No selected result" : selectedTitle
    }
}

private struct AIReflectionLabMetric: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(PinguFont.tiny)
                    .foregroundStyle(PinguDesign.muted)
                    .textCase(.uppercase)

                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(PinguDesign.ink)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } icon: {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(PinguDesign.blue)
                .frame(width: 24)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PinguDesign.ice.opacity(0.68))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct AIReflectionSessionExportDetailView: View {
    let session: AIReflectionSession
    let onCopy: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                PinguScreenBackground()

                ScrollView(showsIndicators: false) {
                    Text(session.exportText)
                        .font(.system(size: 13, weight: .regular, design: .monospaced))
                        .foregroundStyle(PinguDesign.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .pinguGlass(cornerRadius: 22, tint: 0.22)
                        .padding(.horizontal, PinguDesign.screenSidePadding)
                        .padding(.top, 20)
                        .padding(.bottom, 34)
                }
            }
            .navigationTitle(sessionTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Copy") {
                        onCopy()
                    }
                }
            }
        }
    }

    private var sessionTitle: String {
        let title = session.selectedResult?.title.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return title.isEmpty ? "AI Session" : title
    }
}
