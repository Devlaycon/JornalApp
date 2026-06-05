import SwiftUI

struct CircleView: View {
    @EnvironmentObject private var circleStore: CircleStore
    @EnvironmentObject private var journalStore: ReflectionJournalStore
    @State private var selectedCircle: CircleSpace?
    @State private var showCreateCommunity = false

    var body: some View {
        NavigationStack {
            ZStack {
                PinguScreenBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        localSummary

                        if circleStore.circles.isEmpty {
                            emptyCommunityState
                        } else {
                            VStack(spacing: 12) {
                                ForEach(circleStore.circles) { circle in
                                    CommunitySpaceCard(
                                        circle: circle,
                                        postCount: circleStore.posts(for: circle).count,
                                        lastActivity: circleStore.lastActivity(for: circle)
                                    ) {
                                        selectedCircle = circle
                                    }
                                }
                            }
                        }

                        privacyNote
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
                            showCreateCommunity = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 25, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 64, height: 64)
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
        .sheet(isPresented: $showCreateCommunity) {
            CircleCreateSheet()
                .environmentObject(circleStore)
                .presentationDetents([.medium])
        }
        .sheet(item: $selectedCircle) { circle in
            CircleDetailSheet(circleID: circle.id, entries: journalStore.entries)
                .environmentObject(circleStore)
                .presentationDetents([.large])
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Communities")
                .font(.system(size: 35, weight: .bold, design: .rounded))
                .foregroundStyle(PinguDesign.ink)

            Text("Organize reflection shares, support notes, and tips wins by community.")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(PinguDesign.muted)
                .lineSpacing(4)
        }
    }

    private var localSummary: some View {
        HStack(spacing: 10) {
            CircleSummaryTile(value: "\(circleStore.circles.count)", label: "Groups", icon: "person.2.fill")
            CircleSummaryTile(value: "\(circleStore.posts.count)", label: "Posts", icon: "text.bubble.fill")
            CircleSummaryTile(value: "\(journalStore.entries.count)", label: "Shares", icon: "sparkles")
        }
    }

    private var privacyNote: some View {
        HStack(alignment: .top, spacing: 13) {
            Image(systemName: "lock.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(PinguDesign.blue)
                .frame(width: 38, height: 38)
                .background(.white)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text("Local community mode")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(PinguDesign.ink)

                Text("Communities are private on this iPhone for now. Shared reflection cards use summaries and tips, never raw recording audio.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(PinguDesign.muted)
                    .lineSpacing(4)
            }
        }
        .padding(16)
        .background(PinguDesign.lightBlue.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var emptyCommunityState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.badge.plus")
                .font(.system(size: 50, weight: .semibold))
                .foregroundStyle(PinguDesign.blue)

            VStack(spacing: 7) {
                Text("Create your first community")
                    .font(.system(size: 23, weight: .bold, design: .rounded))
                    .foregroundStyle(PinguDesign.ink)

                Text("Group your tips notes, reflection shares, and encouragement cards by class, friends, or goals.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(PinguDesign.muted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Button {
                showCreateCommunity = true
            } label: {
                Label("Create community", systemImage: "plus")
            }
            .buttonStyle(PinguPrimaryButtonStyle())
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: PinguDesign.deepBlue.opacity(0.05), radius: 14, y: 7)
    }
}

private struct CommunitySpaceCard: View {
    let circle: CircleSpace
    let postCount: Int
    let lastActivity: Date?
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 14) {
                Image(systemName: "person.2.wave.2.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(PinguDesign.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text(circle.name)
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundStyle(PinguDesign.ink)
                        .lineLimit(1)

                    Text(circle.intention)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(PinguDesign.muted)
                        .lineLimit(2)
                        .lineSpacing(3)

                    HStack(spacing: 6) {
                        Label(activityText, systemImage: "clock.fill")
                        Label("Private", systemImage: "lock.fill")
                    }
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(PinguDesign.blue)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
                }

                Spacer(minLength: 8)

                VStack(spacing: 5) {
                    Text("\(postCount)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(PinguDesign.ink)
                        .monospacedDigit()

                    Text("posts")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(PinguDesign.muted)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(PinguDesign.muted)
                }
            }
            .padding(16)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: PinguDesign.deepBlue.opacity(0.05), radius: 14, y: 7)
        }
        .buttonStyle(.plain)
    }

    private var activityText: String {
        guard let lastActivity else { return "Created \(circle.createdAt.formatted(date: .abbreviated, time: .omitted))" }
        return "Active \(lastActivity.formatted(date: .abbreviated, time: .shortened))"
    }
}

private struct CircleSummaryTile: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(PinguDesign.blue)

            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(PinguDesign.ink)

            Text(label)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(PinguDesign.muted)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 92)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: PinguDesign.deepBlue.opacity(0.04), radius: 12, y: 6)
    }
}

#Preview {
    CircleView()
        .environmentObject(CircleStore())
        .environmentObject(ReflectionJournalStore())
}
