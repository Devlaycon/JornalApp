import SwiftUI
import UIKit

struct ProfileQAToolsSheet: View {
    @Binding var hasCompletedOnboarding: Bool
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var journalStore: ReflectionJournalStore
    @EnvironmentObject private var profileStore: UserProfileStore
    @EnvironmentObject private var circleStore: CircleStore
    @EnvironmentObject private var questStore: QuestStore
    @EnvironmentObject private var aiSessionStore: AIReflectionSessionStore
    @State private var showAILab = false
    @State private var showResetConfirmation = false
    @State private var statusMessage = "Ready for local phone testing."

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
            .sheet(isPresented: $showAILab) {
                NavigationStack {
                    AIReflectionLabView()
                        .environmentObject(aiSessionStore)
                }
            }
            .confirmationDialog(
                "Reset all local Circleu data?",
                isPresented: $showResetConfirmation,
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
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(PinguDesign.ink)

            Text(statusMessage)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(PinguDesign.muted)
                .lineSpacing(4)
        }
    }

    private var buildCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Build info", systemImage: "iphone")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(PinguDesign.ink)

            ProfileDataRow(title: "App", value: appName)
            ProfileDataRow(title: "Version", value: appVersion)
            ProfileDataRow(title: "Build", value: buildNumber)
            ProfileDataRow(title: "Bundle", value: bundleIdentifier)
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var dataCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Current local state", systemImage: "externaldrive.fill")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(PinguDesign.ink)

            ProfileDataRow(title: "Onboarding", value: hasCompletedOnboarding ? "Complete" : "Open")
            ProfileDataRow(title: "Profile", value: profileStore.displayName.isEmpty ? "No name" : profileStore.displayName)
            ProfileDataRow(title: "Reflections", value: "\(currentProgress.entryCount)")
            ProfileDataRow(title: "AI sessions", value: "\(aiSessionStore.sessions.count)")
            ProfileDataRow(title: "Quests", value: "\(questStore.quests.count)")
            ProfileDataRow(title: "Circles", value: "\(circleStore.circles.count)")
            ProfileDataRow(title: "Posts", value: "\(circleStore.posts.count)")
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var exportCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Export", systemImage: "square.and.arrow.up")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(PinguDesign.ink)

            HStack(spacing: 10) {
                Button {
                    UIPasteboard.general.string = qaExport
                    statusMessage = "Copied QA export to clipboard."
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
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var actionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Local actions", systemImage: "slider.horizontal.3")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(PinguDesign.ink)

            Button {
                seedDemoData()
            } label: {
                Label("Seed demo data", systemImage: "sparkles")
            }
            .buttonStyle(PinguPrimaryButtonStyle())

            Button {
                showAILab = true
            } label: {
                Label("Open AI Lab", systemImage: "cpu")
            }
            .buttonStyle(PinguSecondaryButtonStyle())

            Button(role: .destructive) {
                showResetConfirmation = true
            } label: {
                Label("Reset local data", systemImage: "trash")
            }
            .buttonStyle(PinguSecondaryButtonStyle())

            Text("Seed creates a repeatable local state with demo reflections, AI sessions and transcripts, quests, circles, and support posts. Reset clears app data, including AI sessions and transcripts, and returns onboarding to the first-run state.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(PinguDesign.muted)
                .lineSpacing(4)
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var qaExport: String {
        """
        Circleu QA Export

        \(profileSummary)

        Local State
        Onboarding complete: \(hasCompletedOnboarding)
        Total AI sessions: \(aiSessionStore.sessions.count)
        Total quests: \(questStore.quests.count)
        Active quests: \(questStore.activeQuests.count)
        Total circles: \(circleStore.circles.count)
        Total posts: \(circleStore.posts.count)

        \(journalExport)

        \(aiSessionStore.exportText())
        """
    }

    private var currentProgress: AppProgressSnapshot {
        ProgressEngine.snapshot(entries: journalStore.entries, quests: questStore.quests)
    }

    private var profileSummary: String {
        profileStore.summaryText(
            progress: currentProgress,
            circleCount: circleStore.circles.count,
            supportPostCount: circleStore.posts.count
        )
    }

    private var journalExport: String {
        journalStore.exportText(includePrivateMetadata: true)
    }

    private func seedDemoData() {
        let referenceDate = Date()
        let entries = ReflectionJournalStore.demoEntries(referenceDate: referenceDate)
        profileStore.seedDemoProfile()
        journalStore.replaceAll(with: entries)
        aiSessionStore.seedDemoData(entries: entries)
        questStore.seedDemoData(entries: entries, referenceDate: referenceDate)
        circleStore.seedDemoData(entries: entries, referenceDate: referenceDate)
        hasCompletedOnboarding = true
        statusMessage = "Seeded repeatable demo data for phone testing."
    }

    private func resetLocalData() {
        profileStore.reset()
        journalStore.reset()
        aiSessionStore.reset()
        questStore.reset()
        circleStore.reset(seedStarterSpaces: false)
        hasCompletedOnboarding = false
        statusMessage = "Cleared local data. Relaunch or close this sheet to see onboarding."
    }

    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
        Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ??
        "Circleu"
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1"
    }

    private var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    private var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "Unknown"
    }
}
