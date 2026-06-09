import SwiftUI

struct ProfileQAToolsSheet: View {
    @Binding var hasCompletedOnboarding: Bool
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var journalStore: ReflectionJournalStore
    @EnvironmentObject private var profileStore: UserProfileStore
    @EnvironmentObject private var circleStore: CircleStore
    @EnvironmentObject private var questStore: QuestStore
    @EnvironmentObject private var aiSessionStore: AIReflectionSessionStore
    @StateObject private var viewModel = ProfileQAToolsViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                PinguScreenBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        buildCard
                        dataCard
                        exportCard
                        actionsCard
                    }
                    .padding(.horizontal, PinguDesign.screenSidePadding)
                    .padding(.top, 20)
                    .padding(.bottom, 34)
                }
            }
            .navigationTitle("QA Tools")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $viewModel.showAILab) {
                NavigationStack {
                    AIReflectionLabView()
                        .environmentObject(aiSessionStore)
                }
            }
            .confirmationDialog(
                "Reset all local Circleu data?",
                isPresented: $viewModel.showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset local data", role: .destructive) {
                    resetLocalData()
                }

                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This clears profile, onboarding, reflections, AI sessions, transcripts, quests, circles, and support posts stored on this iPhone.")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reproducible testing")
                .font(PinguFont.screenTitle)
                .foregroundStyle(PinguDesign.ink)

            Text(viewModel.statusMessage)
                .font(PinguFont.body)
                .foregroundStyle(PinguDesign.muted)
                .lineSpacing(4)
        }
    }

    private var buildCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Build info", systemImage: "iphone")
                .font(PinguFont.cardTitle)
                .foregroundStyle(PinguDesign.ink)

            ProfileDataRow(title: "App", value: viewModel.appName)
            ProfileDataRow(title: "Version", value: viewModel.appVersion)
            ProfileDataRow(title: "Build", value: viewModel.buildNumber)
            ProfileDataRow(title: "Bundle", value: viewModel.bundleIdentifier)
        }
        .padding(16)
        .pinguGlass(cornerRadius: 22, tint: 0.22)
    }

    private var dataCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Current local state", systemImage: "externaldrive.fill")
                .font(PinguFont.cardTitle)
                .foregroundStyle(PinguDesign.ink)

            ProfileDataRow(title: "Onboarding", value: hasCompletedOnboarding ? "Complete" : "Open")
            ProfileDataRow(title: "Profile", value: profileStore.displayName.isEmpty ? "No name" : profileStore.displayName)
            ProfileDataRow(title: "Reflections", value: "\(currentProgress.entryCount)")
            ProfileDataRow(title: "AI sessions", value: "\(aiSessionStore.sessions.count)")
            ProfileDataRow(title: "Quests", value: "\(questStore.quests.count)")
            ProfileDataRow(title: "Communities", value: "\(circleStore.circles.count)")
            ProfileDataRow(title: "Posts", value: "\(circleStore.posts.count)")
        }
        .padding(16)
        .pinguGlass(cornerRadius: 22, tint: 0.22)
    }

    private var exportCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Export", systemImage: "square.and.arrow.up")
                .font(PinguFont.cardTitle)
                .foregroundStyle(PinguDesign.ink)

            HStack(spacing: 10) {
                Button {
                    viewModel.copyQAExport(qaExport)
                } label: {
                    Label("Copy QA", systemImage: "doc.on.doc")
                }
                .buttonStyle(ProfileActionButtonStyle(isPrimary: false))

                ShareLink(item: qaExport) {
                    Label("Share QA", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(ProfileActionButtonStyle(isPrimary: true))
            }
        }
        .padding(16)
        .pinguGlass(cornerRadius: 22, tint: 0.22)
    }

    private var actionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Local actions", systemImage: "slider.horizontal.3")
                .font(PinguFont.cardTitle)
                .foregroundStyle(PinguDesign.ink)

            Button {
                seedDemoData()
            } label: {
                Label("Seed demo data", systemImage: "sparkles")
            }
            .buttonStyle(PinguPrimaryButtonStyle())

            Button {
                viewModel.showAILab = true
            } label: {
                Label("Open AI Lab", systemImage: "cpu")
            }
            .buttonStyle(PinguSecondaryButtonStyle())

            Button(role: .destructive) {
                viewModel.showResetConfirmation = true
            } label: {
                Label("Reset local data", systemImage: "trash")
            }
            .buttonStyle(PinguSecondaryButtonStyle())

            Text("Seed creates a repeatable local state with demo reflections, AI sessions and transcripts, quests, circles, and support posts. Reset clears app data, including AI sessions and transcripts, and returns onboarding to the first-run state.")
                .font(PinguFont.caption)
                .foregroundStyle(PinguDesign.muted)
                .lineSpacing(4)
        }
        .padding(16)
        .pinguGlass(cornerRadius: 22, tint: 0.22)
    }

    private var qaExport: String {
        viewModel.qaExport(
            hasCompletedOnboarding: hasCompletedOnboarding,
            journalStore: journalStore,
            profileStore: profileStore,
            circleStore: circleStore,
            questStore: questStore,
            aiSessionStore: aiSessionStore
        )
    }

    private var currentProgress: AppProgressSnapshot {
        viewModel.currentProgress(journalStore: journalStore, questStore: questStore)
    }

    private var profileSummary: String {
        viewModel.profileSummary(
            journalStore: journalStore,
            profileStore: profileStore,
            circleStore: circleStore,
            questStore: questStore
        )
    }

    private func seedDemoData() {
        viewModel.seedDemoData(
            hasCompletedOnboarding: &hasCompletedOnboarding,
            journalStore: journalStore,
            profileStore: profileStore,
            circleStore: circleStore,
            questStore: questStore,
            aiSessionStore: aiSessionStore
        )
    }

    private func resetLocalData() {
        viewModel.resetLocalData(
            hasCompletedOnboarding: &hasCompletedOnboarding,
            journalStore: journalStore,
            profileStore: profileStore,
            circleStore: circleStore,
            questStore: questStore,
            aiSessionStore: aiSessionStore
        )
    }
}
