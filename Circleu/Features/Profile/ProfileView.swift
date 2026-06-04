import SwiftUI
import UIKit

struct ProfileView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @EnvironmentObject private var journalStore: ReflectionJournalStore
    @EnvironmentObject private var profileStore: UserProfileStore
    @EnvironmentObject private var circleStore: CircleStore
    @EnvironmentObject private var questStore: QuestStore
    @EnvironmentObject private var aiSessionStore: AIReflectionSessionStore
    @State private var showProfileEditor = false
    @State private var showQATools = false
    @State private var didCopySummary = false

    var body: some View {
        NavigationStack {
            ZStack {
                PinguScreenBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        profileHeader
                        progressCard
                        statsRow
                        badgeSection
                        activeQuestSection
                        localDataCard
                        qaToolsCard
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
                            showProfileEditor = true
                        } label: {
                            Image(systemName: "pencil")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 62, height: 62)
                                .background(PinguDesign.blue)
                                .clipShape(Circle())
                                .shadow(color: PinguDesign.blue.opacity(0.25), radius: 16, y: 10)
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 26)
                        .padding(.bottom, PinguDesign.bottomBarHeight + 14)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showProfileEditor) {
            ProfileEditSheet(
                entriesCount: progress.entryCount,
                circleCount: circleStore.circles.count,
                completedQuestCount: progress.completedQuestCount
            )
            .environmentObject(profileStore)
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showQATools) {
            ProfileQAToolsSheet(
                hasCompletedOnboarding: $hasCompletedOnboarding
            )
            .environmentObject(journalStore)
            .environmentObject(profileStore)
            .environmentObject(circleStore)
            .environmentObject(questStore)
            .environmentObject(aiSessionStore)
            .presentationDetents([.large])
        }
    }

    private var profileHeader: some View {
        HStack(spacing: 16) {
            Image("PinguMascot")
                .resizable()
                .scaledToFill()
                .frame(width: 86, height: 86)
                .background(.white)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(.white, lineWidth: 5)
                }
                .shadow(color: PinguDesign.deepBlue.opacity(0.12), radius: 14, y: 7)

            VStack(alignment: .leading, spacing: 5) {
                Text(profileStore.firstName.capitalized)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(PinguDesign.ink)

                Text(profileTitle)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(PinguDesign.blue)

                Text("Level \(progress.level) local journey")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(PinguDesign.muted)
            }

            Spacer()
        }
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Progress to Level \(min(progress.level + 1, 12))")
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundStyle(PinguDesign.ink)

                    Text("\(progress.xp) XP earned")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(PinguDesign.blue)
                }

                Spacer()

                Text("\(Int(levelProgress * 100))%")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(PinguDesign.blue)
                    .monospacedDigit()
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(PinguDesign.lightBlue.opacity(0.65))

                    Capsule()
                        .fill(PinguDesign.blue)
                        .frame(width: proxy.size.width * levelProgress)
                }
            }
            .frame(height: 13)

            Text("XP comes from saved reflections, active streaks, and completed quests.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(PinguDesign.muted)
                .lineSpacing(3)
        }
        .padding(20)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: PinguDesign.deepBlue.opacity(0.05), radius: 14, y: 7)
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            ProfileStat(value: "\(progress.entryCount)", title: "Entries")
            ProfileStat(value: "\(progress.streak)", title: "Streak")
            ProfileStat(value: "\(circleStore.circles.count)", title: "Circles")
            ProfileStat(value: progress.mostCommonEmotion, title: "Mood")
        }
    }

    private var badgeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Badges")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(PinguDesign.ink)

            VStack(spacing: 10) {
                ForEach(progress.badges) { badge in
                    BadgeRow(badge: badge)
                }
            }
        }
    }

    private var activeQuestSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Active Quests")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(PinguDesign.ink)

            if questStore.activeQuests.isEmpty {
                EmptyQuestProfileCard()
            } else {
                VStack(spacing: 12) {
                    ForEach(questStore.activeQuests) { quest in
                        ProfileQuestRow(
                            quest: quest,
                            onComplete: { questStore.complete(quest) },
                            onSkip: { questStore.skip(quest) }
                        )
                    }
                }
            }
        }
    }

    private var localDataCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(PinguDesign.blue)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("Local data")
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundStyle(PinguDesign.ink)

                    Text("Stored on this iPhone")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(PinguDesign.muted)
                }
            }

            VStack(spacing: 9) {
                ProfileDataRow(title: "Saved reflections", value: "\(progress.entryCount)")
                ProfileDataRow(title: "Private circles", value: "\(circleStore.circles.count)")
                ProfileDataRow(title: "Support posts", value: "\(circleStore.posts.count)")
                ProfileDataRow(title: "Completed quests", value: "\(progress.completedQuestCount)")
            }

            HStack(spacing: 10) {
                Button {
                    UIPasteboard.general.string = profileSummary
                    didCopySummary = true
                } label: {
                    Label(didCopySummary ? "Copied" : "Copy summary", systemImage: "doc.on.doc")
                }
                .buttonStyle(ProfileActionButtonStyle(isPrimary: false))

                ShareLink(item: profileSummary) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(ProfileActionButtonStyle(isPrimary: true))
            }

            Text("Your journal, circles, quests, and profile name stay in local app storage until you delete the app or clear app data from iOS.")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(PinguDesign.muted)
                .lineSpacing(4)
        }
        .padding(18)
        .background(PinguDesign.lightBlue.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var qaToolsCard: some View {
        Button {
            showQATools = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(PinguDesign.ink)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("QA tools")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(PinguDesign.ink)

                    Text("Reset, seed, and export local test data")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(PinguDesign.muted)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(PinguDesign.muted)
            }
            .padding(16)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: PinguDesign.deepBlue.opacity(0.05), radius: 14, y: 7)
        }
        .buttonStyle(.plain)
    }

    private var progress: AppProgressSnapshot {
        ProgressEngine.snapshot(entries: journalStore.entries, quests: questStore.quests)
    }

    private var profileSummary: String {
        profileStore.summaryText(
            progress: progress,
            circleCount: circleStore.circles.count,
            supportPostCount: circleStore.posts.count
        )
    }

    private var profileTitle: String {
        if progress.level >= 5 { return "Steady Reflector" }
        if progress.entryCount >= 3 { return "Pattern Finder" }
        if progress.entryCount >= 1 { return "Voice Explorer" }
        return "New Voice Explorer"
    }

    private var levelProgress: CGFloat {
        let lowerBound = max(0, (progress.level - 1) * 100)
        let upperBound = max(progress.xpForNextLevel, lowerBound + 100)
        let value = CGFloat(progress.xp - lowerBound) / CGFloat(upperBound - lowerBound)
        return min(max(value, 0), 1)
    }
}

private struct ProfileEditSheet: View {
    let entriesCount: Int
    let circleCount: Int
    let completedQuestCount: Int
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var profileStore: UserProfileStore
    @State private var draftName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Capsule()
                .fill(PinguDesign.border)
                .frame(width: 46, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

            HStack(spacing: 16) {
                Image("PinguMascot")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 72, height: 72)
                    .background(.white)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text(profileStore.firstName.capitalized)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(PinguDesign.ink)

                    Text("Local profile")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(PinguDesign.blue)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                displayNameEditor
                ProfileEditorRow(icon: "sparkles", title: "Journey", value: "\(entriesCount) saved reflections")
                ProfileEditorRow(icon: "person.2.fill", title: "Private circles", value: "\(circleCount) local spaces")
                ProfileEditorRow(icon: "checkmark.seal.fill", title: "Quests", value: "\(completedQuestCount) completed")
                ProfileEditorRow(icon: "lock.fill", title: "Privacy", value: "Local journal and circles")
            }

            Spacer()

            Button("Save Profile") {
                profileStore.updateDisplayName(draftName.isEmpty ? "Friend" : draftName)
                dismiss()
            }
            .buttonStyle(PinguPrimaryButtonStyle())
        }
        .padding(24)
        .background(PinguDesign.ice)
        .onAppear {
            draftName = profileStore.displayName
        }
    }

    private var displayNameEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Display name")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(PinguDesign.ink)

            TextField("Your name", text: $draftName)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(PinguDesign.ink)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .padding(.horizontal, 14)
                .frame(height: 50)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct ProfileEditorRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(PinguDesign.blue)
                .frame(width: 38, height: 38)
                .background(PinguDesign.lightBlue.opacity(0.68))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(PinguDesign.ink)

                Text(value)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(PinguDesign.muted)
            }

            Spacer()
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct ProfileStat: View {
    let value: String
    let title: String

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: value.count > 7 ? 13 : 21, weight: .bold, design: .rounded))
                .foregroundStyle(PinguDesign.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(PinguDesign.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 82)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: PinguDesign.deepBlue.opacity(0.04), radius: 12, y: 6)
    }
}

private struct BadgeRow: View {
    let badge: ProgressBadge

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: badge.icon)
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(badge.isUnlocked ? .white : PinguDesign.muted)
                .frame(width: 48, height: 48)
                .background(badge.isUnlocked ? PinguDesign.blue : PinguDesign.border.opacity(0.7))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(badge.title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(PinguDesign.ink)

                Text(badge.subtitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(PinguDesign.muted)
            }

            Spacer()

            Text(badge.isUnlocked ? "Unlocked" : "Locked")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(badge.isUnlocked ? PinguDesign.blue : PinguDesign.muted)
                .padding(.horizontal, 9)
                .frame(height: 26)
                .background((badge.isUnlocked ? PinguDesign.lightBlue : PinguDesign.border).opacity(0.65))
                .clipShape(Capsule())
        }
        .padding(15)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: PinguDesign.deepBlue.opacity(0.04), radius: 12, y: 6)
    }
}

private struct ProfileQuestRow: View {
    let quest: Quest
    let onComplete: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 13) {
                Image(systemName: "flag.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(PinguDesign.orange)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text(quest.title)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(PinguDesign.ink)

                    Text(quest.detail)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(PinguDesign.body)
                        .lineSpacing(4)
                }
            }

            HStack(spacing: 10) {
                Button {
                    onComplete()
                } label: {
                    Label("Complete", systemImage: "checkmark")
                }
                .buttonStyle(ProfileQuestButtonStyle(isPrimary: true))

                Button {
                    onSkip()
                } label: {
                    Label("Skip", systemImage: "forward.fill")
                }
                .buttonStyle(ProfileQuestButtonStyle(isPrimary: false))
            }
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: PinguDesign.deepBlue.opacity(0.05), radius: 14, y: 7)
    }
}

private struct EmptyQuestProfileCard: View {
    var body: some View {
        HStack(alignment: .top, spacing: 13) {
            Image(systemName: "flag")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(PinguDesign.blue)
                .frame(width: 46, height: 46)
                .background(PinguDesign.lightBlue.opacity(0.72))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text("No active quests")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(PinguDesign.ink)

                Text("Save a reflection and Circleu will create one practical next action here.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(PinguDesign.muted)
                    .lineSpacing(4)
            }
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: PinguDesign.deepBlue.opacity(0.05), radius: 14, y: 7)
    }
}

private struct ProfileQuestButtonStyle: ButtonStyle {
    let isPrimary: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(isPrimary ? .white : PinguDesign.blue)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(isPrimary ? PinguDesign.blue : PinguDesign.lightBlue.opacity(0.74))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(configuration.isPressed ? 0.76 : 1)
    }
}

struct ProfileDataRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(PinguDesign.ink)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(PinguDesign.blue)
                .monospacedDigit()
        }
        .padding(.horizontal, 14)
        .frame(height: 42)
        .background(.white.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct ProfileActionButtonStyle: ButtonStyle {
    let isPrimary: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(isPrimary ? .white : PinguDesign.blue)
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(isPrimary ? PinguDesign.blue : .white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

#Preview {
    ProfileView()
        .environmentObject(ReflectionJournalStore())
        .environmentObject(UserProfileStore())
        .environmentObject(CircleStore())
        .environmentObject(QuestStore())
        .environmentObject(AIReflectionSessionStore())
}
