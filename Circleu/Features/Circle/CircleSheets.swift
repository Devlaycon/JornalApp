import SwiftUI

struct CircleDetailView: View {
    let circleID: UUID
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var circleStore: CircleStore
    @State private var draft = ""

    private var circle: CircleSpace? {
        circleStore.circles.first { $0.id == circleID }
    }

    var body: some View {
        ZStack {
            PinguAurora()

            VStack(spacing: 0) {
                DemoNavBar(title: circle?.name ?? "Circle", onBack: { dismiss() })

                if let circle {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {
                            headerCard(circle)
                                .padding(.top, 8)
                                .padding(.bottom, 16)

                            Text("RECENT SHARES")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .tracking(0.8)
                                .foregroundStyle(Pingu.slate)
                                .padding(.leading, 4)
                                .padding(.bottom, 8)

                            composer(circle)
                                .padding(.bottom, 12)

                            postsList(circle)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 110)
                    }
                } else {
                    Spacer()
                    Text("Not found")
                        .font(PinguFont.cardTitle)
                        .foregroundStyle(Pingu.slate)
                    Spacer()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .preference(key: TabBarHiddenKey.self, value: true)
    }

    private func headerCard(_ circle: CircleSpace) -> some View {
        GlassCard(style: .strong, sheen: true) {
            VStack(spacing: 0) {
                Text(circle.emoji)
                    .font(.system(size: 40))
                    .padding(.bottom, 4)

                Text(circle.name)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Pingu.ink)

                Text(circle.intention)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(Pingu.slate)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
                    .padding(.bottom, 12)

                HStack(spacing: 6) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text("\(circle.members) members")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                    Text("·")
                    Text("created \(CircleViewModel.timeAgo(circle.createdAt))")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(Pingu.muted)
                .padding(.bottom, 16)

                if circle.joined {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .heavy))
                        Text("You're in this circle")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(Color(hex: 0x16A34A))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(hex: 0x16A34A).opacity(0.12))
                    .clipShape(Capsule())
                } else {
                    Button {
                        circleStore.joinCircle(circle.id)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 14, weight: .bold))
                            Text("Join circle")
                        }
                    }
                    .buttonStyle(PinguPrimaryButtonStyle())
                }
            }
            .frame(maxWidth: .infinity)
            .padding(24)
        }
    }

    private func composer(_ circle: CircleSpace) -> some View {
        GlassCard(style: .regular, cornerRadius: 24) {
            HStack(spacing: 8) {
                Text("🐧")
                    .font(.system(size: 13))
                    .frame(width: 28, height: 28)
                    .glass(.pill, cornerRadius: 999)

                TextField("Share something kind…", text: $draft)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(Pingu.ink)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.white.opacity(0.7))
                    .overlay { Capsule().strokeBorder(.white.opacity(0.6), lineWidth: 1) }
                    .clipShape(Capsule())
                    .onSubmit { sharePost(circle) }

                sendButton(enabled: !draft.trimmed.isEmpty, size: 40) {
                    sharePost(circle)
                }
            }
            .padding(10)
        }
    }

    private func postsList(_ circle: CircleSpace) -> some View {
        let posts = circleStore.posts(for: circle)
        return VStack(spacing: 12) {
            if posts.isEmpty {
                Text("Be the first to share something gentle here.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Pingu.muted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                ForEach(Array(posts.enumerated()), id: \.element.id) { index, post in
                    CirclePostCard(post: post)
                        .slideUp(Double(index) * 0.06)
                }
            }
        }
    }

    private func sharePost(_ circle: CircleSpace) {
        let text = draft.trimmed
        guard !text.isEmpty else { return }
        circleStore.addPost(circleID: circle.id, text: text)
        draft = ""
    }
}

private struct CirclePostCard: View {
    let post: CirclePost
    @EnvironmentObject private var circleStore: CircleStore
    @State private var open = false
    @State private var reply = ""

    var body: some View {
        GlassCard(style: .regular, cornerRadius: 24) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    Text("🐧")
                        .font(.system(size: 13))
                        .frame(width: 28, height: 28)
                        .glass(.pill, cornerRadius: 999)
                    Text(post.who)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Pingu.ink)
                    Spacer()
                    Text(CircleViewModel.timeAgo(post.createdAt))
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundStyle(Pingu.muted)
                }
                .padding(.bottom, 6)

                Text(post.text)
                    .font(.system(size: 13.5, weight: .regular, design: .rounded))
                    .foregroundStyle(Pingu.body)
                    .lineSpacing(3)
                    .padding(.bottom, 10)

                HStack(spacing: 8) {
                    likeButton(
                        liked: post.liked,
                        count: post.likes,
                        action: { circleStore.toggleLikePost(post.id) }
                    )

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { open.toggle() }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "bubble.left")
                                .font(.system(size: 13, weight: .semibold))
                            Text(post.replies.isEmpty ? "Reply" : "\(post.replies.count)")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(Pingu.slate)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .glass(.pill, cornerRadius: 999)
                    }
                    .buttonStyle(PressableButtonStyle())
                }

                if open {
                    repliesSection
                        .padding(.top, 12)
                }
            }
            .padding(16)
        }
    }

    private var repliesSection: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(Pingu.accent.opacity(0.15))
                .frame(width: 2)
            VStack(alignment: .leading, spacing: 10) {
                ForEach(post.replies) { r in
                    HStack(alignment: .top, spacing: 8) {
                        Text("🐧")
                            .font(.system(size: 11))
                            .frame(width: 24, height: 24)
                            .glass(.pill, cornerRadius: 999)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(r.who)
                                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                                    .foregroundStyle(Pingu.ink)
                                Text(CircleViewModel.timeAgo(r.createdAt))
                                    .font(.system(size: 10.5, weight: .regular, design: .rounded))
                                    .foregroundStyle(Pingu.muted)
                            }
                            Text(r.text)
                                .font(.system(size: 12.5, weight: .regular, design: .rounded))
                                .foregroundStyle(Pingu.body)
                                .lineSpacing(2)

                            Button {
                                circleStore.toggleLikeReply(postID: post.id, replyID: r.id)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: r.liked ? "heart.fill" : "heart")
                                        .font(.system(size: 11, weight: .bold))
                                    Text("\(r.likes)")
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                }
                                .foregroundStyle(r.liked ? Color(hex: 0xEC4899) : Pingu.muted)
                            }
                            .buttonStyle(PressableButtonStyle())
                            .padding(.top, 1)
                        }
                    }
                }

                HStack(spacing: 8) {
                    Text("🐧")
                        .font(.system(size: 11))
                        .frame(width: 24, height: 24)
                        .glass(.pill, cornerRadius: 999)
                    TextField("Write a kind reply…", text: $reply)
                        .font(.system(size: 12.5, design: .rounded))
                        .foregroundStyle(Pingu.ink)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.7))
                        .overlay { Capsule().strokeBorder(.white.opacity(0.6), lineWidth: 1) }
                        .clipShape(Capsule())
                        .onSubmit { sendReply() }
                    sendButton(enabled: !reply.trimmed.isEmpty, size: 32) {
                        sendReply()
                    }
                }
                .padding(.top, 1)
            }
            .padding(.leading, 12)
        }
    }

    @ViewBuilder
    private func likeButton(liked: Bool, count: Int, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            let pill = HStack(spacing: 6) {
                Image(systemName: liked ? "heart.fill" : "heart")
                    .font(.system(size: 13, weight: .semibold))
                Text("\(count)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            }
            .foregroundStyle(liked ? Color(hex: 0xEC4899) : Pingu.slate)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)

            if liked {
                pill
                    .background(Color(hex: 0xEC4899).opacity(0.12))
                    .clipShape(Capsule())
            } else {
                pill.glass(.pill, cornerRadius: 999)
            }
        }
        .buttonStyle(PressableButtonStyle())
    }

    private func sendReply() {
        let text = reply.trimmed
        guard !text.isEmpty else { return }
        circleStore.addReply(postID: post.id, text: text)
        reply = ""
        open = true
    }
}

private func sendButton(enabled: Bool, size: CGFloat, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Image(systemName: "paperplane.fill")
            .font(.system(size: size * 0.38, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background {
                if enabled {
                    GlassPrimaryFill(cornerRadius: 999)
                } else {
                    Circle().fill(Color(hex: 0xCBD5E1))
                }
            }
            .clipShape(Circle())
    }
    .buttonStyle(PressableButtonStyle())
    .disabled(!enabled)
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
