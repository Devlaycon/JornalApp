import SwiftUI

struct ProfileQAToolsSheet: View {
    @Binding var hasCompletedOnboarding: Bool
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var journalStore: ReflectionJournalStore
    @EnvironmentObject private var profileStore: UserProfileStore
    @EnvironmentObject private var circleStore: CircleStore
    @EnvironmentObject private var questStore: QuestStore
    @EnvironmentObject private var tipsPracticeStore: TipsPracticeStore
    @EnvironmentObject private var aiSessionStore: AIReflectionSessionStore
    @EnvironmentObject private var rewardsStore: RewardsStore
    @EnvironmentObject private var backendSessionStore: BackendSessionStore
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
                        backendCard
                        backendDiagnosticsCard
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
            ProfileDataRow(title: "Tips practice", value: "\(tipsPracticeStore.recentSessions.count)")
            ProfileDataRow(title: "Reward points", value: "\(rewardsStore.points)")
            ProfileDataRow(title: "Communities", value: "\(circleStore.circles.count)")
            ProfileDataRow(title: "Posts", value: "\(circleStore.posts.count)")
        }
        .padding(16)
        .pinguGlass(cornerRadius: 22, tint: 0.22)
    }

    private var backendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Firebase status", systemImage: "externaldrive.connected.to.line.below")
                .font(PinguFont.cardTitle)
                .foregroundStyle(PinguDesign.ink)

            ProfileDataRow(
                title: "Auth",
                value: backendSessionStore.backendUserID == nil ? "Local only" : "Signed in"
            )
            ProfileDataRow(title: "Email", value: backendSessionStore.backendEmail ?? "None")
            ProfileDataRow(title: "UID", value: shortUID)
            ProfileDataRow(title: "Sync", value: syncStateSummary)
            ProfileDataRow(title: "Uploaded", value: uploadedSummary)
            ProfileDataRow(title: "Downloaded", value: downloadedSummary)
            ProfileDataRow(title: "Failed scopes", value: failedScopesSummary)
            ProfileDataRow(title: "Last sync", value: lastSyncTime)

            HStack(spacing: 10) {
                Button {
                    backUpNow()
                } label: {
                    Label("Back Up Now", systemImage: "arrow.up.doc")
                }
                .buttonStyle(ProfileActionButtonStyle(isPrimary: true))
                .disabled(backendActionsDisabled)

                Button {
                    restoreNow()
                } label: {
                    Label("Restore Now", systemImage: "arrow.down.doc")
                }
                .buttonStyle(ProfileActionButtonStyle(isPrimary: false))
                .disabled(backendActionsDisabled)
            }

            if let authError = backendSessionStore.lastAuthErrorMessage {
                ProfileDataRow(title: "Auth error", value: authError)
            }

            if let syncError = backendSessionStore.lastSyncErrorMessage {
                ProfileDataRow(title: "Sync error", value: syncError)
            }
        }
        .padding(16)
        .pinguGlass(cornerRadius: 22, tint: 0.22)
    }

    private var backendDiagnosticsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("TestFlight backend diagnostics", systemImage: "stethoscope")
                .font(PinguFont.cardTitle)
                .foregroundStyle(PinguDesign.ink)

            ProfileDataRow(title: "Operation", value: backendSessionStore.syncOperation.rawValue.capitalized)
            ProfileDataRow(title: "Firebase path", value: backendSessionStore.backendUserID == nil ? "None" : "users/\(shortUID)")
            ProfileDataRow(title: "Local payload", value: localPayloadSummary)
            ProfileDataRow(title: "Last upload", value: formattedSyncTime(backendSessionStore.lastUploadResult))
            ProfileDataRow(title: "Uploaded payload", value: uploadedDiagnosticsSummary)
            ProfileDataRow(title: "Last restore", value: formattedSyncTime(backendSessionStore.lastRestoreResult))
            ProfileDataRow(title: "Restored payload", value: restoredDiagnosticsSummary)
            ProfileDataRow(title: "Last error source", value: lastErrorSourceSummary)
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
            tipsPracticeStore: tipsPracticeStore,
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
            tipsPracticeStore: tipsPracticeStore,
            rewardsStore: rewardsStore,
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
            tipsPracticeStore: tipsPracticeStore,
            rewardsStore: rewardsStore,
            aiSessionStore: aiSessionStore
        )
    }

    private func backUpNow() {
        guard backendSessionStore.backendUserID != nil else {
            viewModel.statusMessage = "Sign in before backing up Firebase data."
            return
        }

        viewModel.statusMessage = "Backing up private Firebase data..."
        Task {
            await backendSessionStore.uploadPrivateBackup(
                profileStore: profileStore,
                journalStore: journalStore,
                questStore: questStore,
                tipsPracticeStore: tipsPracticeStore,
                rewardsStore: rewardsStore,
                circleStore: circleStore,
                aiSessionStore: aiSessionStore
            )
            viewModel.statusMessage = backendSessionStore.lastSyncErrorMessage == nil
                ? "Firebase backup finished."
                : "Firebase backup finished with an error."
        }
    }

    private func restoreNow() {
        guard backendSessionStore.backendUserID != nil else {
            viewModel.statusMessage = "Sign in before restoring Firebase data."
            return
        }

        viewModel.statusMessage = "Restoring private Firebase data..."
        Task {
            await backendSessionStore.restorePrivateBackup(
                profileStore: profileStore,
                journalStore: journalStore,
                questStore: questStore,
                tipsPracticeStore: tipsPracticeStore,
                rewardsStore: rewardsStore,
                aiSessionStore: aiSessionStore
            )
            viewModel.statusMessage = backendSessionStore.lastSyncErrorMessage == nil
                ? "Firebase restore finished."
                : "Firebase restore finished with an error."
        }
    }

    private var shortUID: String {
        guard let uid = backendSessionStore.backendUserID else { return "None" }
        guard uid.count > 10 else { return uid }
        return "\(uid.prefix(6))...\(uid.suffix(4))"
    }

    private var backendActionsDisabled: Bool {
        backendSessionStore.backendUserID == nil || backendSessionStore.isSyncing
    }

    private var syncStateSummary: String {
        switch backendSessionStore.syncOperation {
        case .idle:
            guard let result = backendSessionStore.lastSyncResult else { return "Not yet" }
            return result.didSucceed ? "OK" : "Partial"
        case .uploading:
            return "Uploading"
        case .restoring:
            return "Restoring"
        }
    }

    private var uploadedSummary: String {
        guard let result = backendSessionStore.lastSyncResult else { return "0 docs" }
        return "\(privateDocumentCount(for: result.uploadedCounts, includeFixedDocuments: true)) docs"
    }

    private var downloadedSummary: String {
        guard let result = backendSessionStore.lastSyncResult else { return "0 docs" }
        return "\(privateDocumentCount(for: result.downloadedCounts, includeFixedDocuments: false)) records"
    }

    private var uploadedDiagnosticsSummary: String {
        guard let result = backendSessionStore.lastUploadResult else { return "Not yet" }
        return "\(privateDocumentCount(for: result.uploadedCounts, includeFixedDocuments: true)) docs"
    }

    private var restoredDiagnosticsSummary: String {
        guard let result = backendSessionStore.lastRestoreResult else { return "Not yet" }
        return "\(privateDocumentCount(for: result.downloadedCounts, includeFixedDocuments: false)) records"
    }

    private var localPayloadSummary: String {
        let fixedPrivateDocs = backendSessionStore.backendUserID == nil ? 0 : 3
        let total = fixedPrivateDocs
            + journalStore.entries.count
            + questStore.quests.count
            + tipsPracticeStore.recentSessions.count
            + rewardsStore.pointsLog.count
            + rewardsStore.activity.count
            + aiSessionStore.sessions.count
        return "\(total) docs"
    }

    private var failedScopesSummary: String {
        guard let result = backendSessionStore.lastSyncResult else { return "None" }
        guard !result.failedScopes.isEmpty else { return "None" }
        return result.failedScopes.map(\.rawValue).joined(separator: ", ")
    }

    private var lastSyncTime: String {
        guard let syncedAt = backendSessionStore.lastSyncResult?.syncedAt else { return "Never" }
        return syncedAt.formatted(date: .omitted, time: .shortened)
    }

    private var lastErrorSourceSummary: String {
        guard let message = backendSessionStore.lastSyncErrorMessage else { return "None" }
        guard let operation = backendSessionStore.lastSyncErrorOperation else { return message }
        return "\(operation.rawValue.capitalized): \(message)"
    }

    private func formattedSyncTime(_ result: BackendSyncResult?) -> String {
        guard let result else { return "Never" }
        return result.syncedAt.formatted(date: .abbreviated, time: .shortened)
    }

    private func privateDocumentCount(
        for counts: BackendSyncCounts,
        includeFixedDocuments: Bool
    ) -> Int {
        let fixedPrivateDocs = includeFixedDocuments && backendSessionStore.backendUserID != nil ? 3 : 0
        return fixedPrivateDocs
            + counts.journalEntryCount
            + counts.questCount
            + counts.tipsPracticeSessionCount
            + counts.pointEntryCount
            + counts.activityEventCount
            + counts.aiSessionCount
    }
}
