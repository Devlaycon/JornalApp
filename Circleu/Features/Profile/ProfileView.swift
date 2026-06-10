import SwiftUI

struct ProfileView: View {
    var onStartRecording: () -> Void = {}
    var onOpenTips: () -> Void = {}
    var onOpenEntry: (UUID) -> Void = { _ in }

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @EnvironmentObject private var journalStore: ReflectionJournalStore
    @EnvironmentObject private var profileStore: UserProfileStore
    @EnvironmentObject private var circleStore: CircleStore
    @EnvironmentObject private var rewardsStore: RewardsStore
    @EnvironmentObject private var authStore: AuthStore

    @State private var filter: ActivityFilter = .all

    private var xp: Int { rewardsStore.points }
    private var level: Int { rewardsStore.level }
    private var intoLevel: Int { rewardsStore.intoLevel }
    private var joinedCount: Int { circleStore.circles.filter { $0.joined }.count }
    private var streak: Int { Self.computeStreak(journalStore.entries) }
    private var questsDone: Int { DailyQuest.all.filter { rewardsStore.isDone($0.id) }.count }
    private var events: [ActivityEvent] {
        Array(rewardsStore.activity.filter { filter.matches($0.type) }.prefix(60))
    }

    var body: some View {
        ZStack {
            PinguAurora()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .slideUp(0)
                        .padding(.bottom, 20)

                    statsRow
                        .slideUp(0.06)
                        .padding(.bottom, 20)

                    questsHeader
                        .slideUp(0.1)
                        .padding(.bottom, 12)
                    questsSection
                        .slideUp(0.14)
                        .padding(.bottom, 24)

                    rewardsHeader
                        .slideUp(0.16)
                        .padding(.bottom, 12)
                    rewardsSection
                        .slideUp(0.18)
                        .padding(.bottom, 24)

                    historyHeader
                        .slideUp(0.12)
                        .padding(.bottom, 12)
                    filterRow
                        .slideUp(0.16)
                        .padding(.bottom, 16)
                    historySection
                        .slideUp(0.2)

                    historyFooter
                        .padding(.top, 12)

                    logoutButton
                        .padding(.top, 24)

                    resetButton
                        .padding(.top, 16)
                }
                .padding(.horizontal, 20)
                .padding(.top, 64)
                .padding(.bottom, 120)
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 16) {
            PinguMascot(size: 72, mood: .idle)
                .padding(6)
                .glass(.strong, cornerRadius: 24)

            VStack(alignment: .leading, spacing: 0) {
                Kicker("LEVEL \(level) · \(xp) XP")

                Text(profileStore.firstName.capitalized)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Pingu.ink)
                    .padding(.top, 2)

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.6))
                        GlassPrimaryFill(cornerRadius: 999)
                            .frame(width: proxy.size.width * CGFloat(intoLevel) / 100, height: proxy.size.height)
                            .clipShape(Capsule())
                    }
                }
                .frame(height: 8)
                .padding(.top, 8)

                Text("\(100 - intoLevel) XP to level \(rewardsStore.nextLevel)")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Pingu.slate)
                    .padding(.top, 5)
            }
        }
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: 10) {
            ProfileStatCard(icon: "book.fill", color: Pingu.accent, value: "\(journalStore.entries.count)", label: "Entries")
            ProfileStatCard(icon: "flame.fill", color: Pingu.amber, value: "\(streak)", label: "Streak")
            ProfileStatCard(icon: "trophy.fill", color: Pingu.green, value: "\(joinedCount)", label: "Circles")
        }
    }

    // MARK: - Quests

    private var questsHeader: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "target")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Pingu.accent)
                Text("Today's quests")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Pingu.ink)
            }
            Spacer()
            Text("\(questsDone)/\(DailyQuest.all.count) done")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Pingu.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Pingu.accent.opacity(0.1))
                .clipShape(Capsule())
        }
    }

    private var questsSection: some View {
        VStack(spacing: 10) {
            ForEach(DailyQuest.all) { quest in
                QuestRow(
                    quest: quest,
                    done: rewardsStore.isDone(quest.id),
                    onStart: {
                        switch quest.go {
                        case .record: onStartRecording()
                        case .tips: onOpenTips()
                        case .none: break
                        }
                    }
                )
            }

            Text("Quests refresh every day — points level you up and keep your streak alive.")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Pingu.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.top, 4)
        }
    }

    // MARK: - Rewards

    private var rewardsHeader: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Pingu.amber)
                Text("Recent rewards")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Pingu.ink)
            }
            Spacer()
            Text("\(xp) pts total")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Pingu.muted)
        }
    }

    private var rewardsSection: some View {
        GlassCard(style: .regular, cornerRadius: 24) {
            VStack(spacing: 0) {
                let log = Array(rewardsStore.pointsLog.prefix(5))
                ForEach(Array(log.enumerated()), id: \.element.id) { index, entry in
                    HStack(spacing: 12) {
                        Text(entry.icon)
                            .font(.system(size: 15))
                            .frame(width: 32, height: 32)
                            .glass(.pill, cornerRadius: 999)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.label)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(Pingu.ink)
                                .lineLimit(1)
                            Text(CircleViewModel.timeAgo(entry.createdAt))
                                .font(.system(size: 10.5, weight: .medium, design: .rounded))
                                .foregroundStyle(Pingu.muted)
                        }

                        Spacer()

                        Text("+\(entry.points)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(Pingu.green)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 10)

                    if index < log.count - 1 {
                        Rectangle()
                            .fill(.white.opacity(0.4))
                            .frame(height: 1)
                    }
                }
            }
            .padding(8)
        }
    }

    // MARK: - Record history

    private var historyHeader: some View {
        HStack {
            Text("Record history")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Pingu.ink)
            Spacer()
            Text("\(rewardsStore.activity.count) events")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Pingu.muted)
        }
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ActivityFilter.allCases, id: \.self) { f in
                    let active = filter == f
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { filter = f }
                    } label: {
                        Text(f.label)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(active ? .white : Pingu.ink)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background {
                                if active {
                                    GlassPrimaryFill(cornerRadius: 999)
                                } else {
                                    Color.clear.glass(.pill, cornerRadius: 999)
                                }
                            }
                            .clipShape(Capsule())
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
        }
    }

    private var historySection: some View {
        GlassCard(style: .regular, cornerRadius: 24) {
            Group {
                if events.isEmpty {
                    Text("No activity in this filter yet.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Pingu.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                } else {
                    ZStack(alignment: .topLeading) {
                        Rectangle()
                            .fill(Pingu.accent.opacity(0.15))
                            .frame(width: 2)
                            .padding(.leading, 9)
                            .padding(.vertical, 8)

                        VStack(spacing: 0) {
                            ForEach(events) { event in
                                historyRow(event)
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    private func historyRow(_ event: ActivityEvent) -> some View {
        let meta = ActivityMeta.meta(for: event.type)
        let clickable = event.type == .reflect && event.refID != nil

        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: meta.icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(meta.color)
                .frame(width: 20, height: 20)
                .background(Circle().fill(meta.color.opacity(0.12)))
                .overlay(Circle().stroke(.white.opacity(0.7), lineWidth: 3))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(meta.label.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(0.4)
                        .foregroundStyle(meta.color)
                    Text(CircleViewModel.timeAgo(event.createdAt))
                        .font(.system(size: 10.5, weight: .medium, design: .rounded))
                        .foregroundStyle(Pingu.muted)
                }
                Text(event.title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Pingu.ink)
                    .lineLimit(1)
                Text(event.keyword)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(Pingu.slate)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            if clickable {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Pingu.muted)
                    .padding(.top, 2)
            }
        }
        .padding(.bottom, 16)
        .contentShape(Rectangle())
        .onTapGesture {
            if clickable, let id = event.refID { onOpenEntry(id) }
        }
    }

    private var historyFooter: some View {
        Text("History stores lightweight keywords only (capped at 100 events) — your full reflections live privately in Journal.")
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundStyle(Pingu.muted)
            .multilineTextAlignment(.center)
            .lineSpacing(2)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
    }

    // MARK: - Footer actions

    private var logoutButton: some View {
        Button {
            authStore.logout()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.86)) {
                hasCompletedOnboarding = false
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 16, weight: .bold))
                Text("Log out")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
            .foregroundStyle(Pingu.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .glass(.pill, cornerRadius: 16)
        }
        .buttonStyle(PressableButtonStyle())
    }

    private var resetButton: some View {
        Button {
            rewardsStore.resetToSeed()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 13, weight: .bold))
                Text("Reset demo data")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            }
            .foregroundStyle(Pingu.muted)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PressableButtonStyle())
    }

    // MARK: - Streak

    private static func computeStreak(_ entries: [JournalReflectionEntry]) -> Int {
        guard !entries.isEmpty else { return 0 }
        let calendar = Calendar.current
        let days = Set(entries.map { calendar.startOfDay(for: $0.createdAt) })
        var streak = 0
        var cursor = calendar.startOfDay(for: Date())
        while days.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return max(streak, 1)
    }
}

// MARK: - Daily quest model

private struct DailyQuest: Identifiable {
    enum Destination { case record, tips }

    let id: String
    let label: String
    let desc: String
    let points: Int
    let emoji: String
    let go: Destination?

    static let all: [DailyQuest] = [
        DailyQuest(id: "daily_login", label: "Daily check-in", desc: "Open Circleu today", points: 2, emoji: "☀️", go: nil),
        DailyQuest(id: "daily_reflect", label: "Reflect once", desc: "Record a reflection", points: 8, emoji: "📓", go: .record),
        DailyQuest(id: "daily_tips", label: "Practise a conversation", desc: "Finish a communication tip", points: 5, emoji: "💬", go: .tips)
    ]
}

private enum ActivityFilter: String, CaseIterable {
    case all, reflect, tips, circles

    var label: String {
        switch self {
        case .all: return "All"
        case .reflect: return "Reflections"
        case .tips: return "Tips"
        case .circles: return "Circles"
        }
    }

    func matches(_ type: ActivityType) -> Bool {
        switch self {
        case .all: return true
        case .reflect: return type == .reflect
        case .tips: return type == .tips
        case .circles: return type == .communityJoin || type == .communitySelect
        }
    }
}

private enum ActivityMeta {
    static func meta(for type: ActivityType) -> (label: String, color: Color, icon: String) {
        switch type {
        case .reflect: return ("Reflection", Pingu.accent, "sparkles")
        case .tips: return ("Communication tip", Pingu.violet, "message.fill")
        case .communitySelect: return ("Viewed circle", Pingu.cyan, "person.2.fill")
        case .communityJoin: return ("Joined circle", Pingu.green, "person.fill.badge.plus")
        }
    }
}

// MARK: - Stat card

private struct ProfileStatCard: View {
    let icon: String
    let color: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Pingu.ink)
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Pingu.slate)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .glass(.regular, cornerRadius: 18)
    }
}

// MARK: - Quest row

private struct QuestRow: View {
    let quest: DailyQuest
    let done: Bool
    let onStart: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                if done {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(GlassPrimaryFill(cornerRadius: 12))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else {
                    Text(quest.emoji)
                        .font(.system(size: 17))
                        .frame(width: 36, height: 36)
                        .glass(.pill, cornerRadius: 12)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(quest.label)
                        .font(.system(size: 13.5, weight: .bold, design: .rounded))
                        .foregroundStyle(done ? Pingu.muted : Pingu.ink)
                        .strikethrough(done, color: Pingu.muted)
                        .lineLimit(1)
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 9))
                        Text("\(quest.points)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(Pingu.amber)
                }
                Text(quest.desc)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(Pingu.slate)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            trailing
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .glass(.regular, cornerRadius: 20)
    }

    @ViewBuilder
    private var trailing: some View {
        if done {
            Text("Earned")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(Pingu.green)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Pingu.green.opacity(0.1))
                .clipShape(Capsule())
        } else if quest.go != nil {
            Button(action: onStart) {
                Text("Start")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(GlassPrimaryFill(cornerRadius: 999))
                    .clipShape(Capsule())
            }
            .buttonStyle(PressableButtonStyle())
        } else {
            Text("Pending")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(Pingu.muted)
        }
    }
}

// MARK: - Shared QA helpers (used by ProfileQAToolsSheet)

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
        .environmentObject(RewardsStore())
        .environmentObject(AuthStore())
}
