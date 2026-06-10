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

    @ViewBuilder
    private func coverHero(_ circle: CircleSpace) -> some View {
        if !circle.coverImages.isEmpty {
            TabView {
                ForEach(Array(circle.coverImages.enumerated()), id: \.offset) { _, data in
                    if let img = UIImage(data: data) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: circle.coverImages.count > 1 ? .always : .never))
            .indexViewStyle(.page(backgroundDisplayMode: .interactive))
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(.white.opacity(0.5), lineWidth: 1)
            }
            .padding(.bottom, 12)
        }
    }

    private func headerCard(_ circle: CircleSpace) -> some View {
        GlassCard(style: .strong, sheen: true) {
            VStack(spacing: 0) {
                coverHero(circle)

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
    @State private var editingPost = false
    @State private var editPostText = ""
    @State private var pendingDelete = false
    @State private var editingReplyID: UUID?
    @State private var editReplyText = ""
    @State private var pendingDeleteReplyID: UUID?

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
                    if post.isMine {
                        ownPostMenu
                    }
                }
                .padding(.bottom, 6)

                if editingPost {
                    postEditor
                        .padding(.bottom, 10)
                } else {
                    Text(post.text)
                        .font(.system(size: 13.5, weight: .regular, design: .rounded))
                        .foregroundStyle(Pingu.body)
                        .lineSpacing(3)
                        .padding(.bottom, 10)
                }

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
                                Spacer(minLength: 0)
                                if r.isMine {
                                    ownReplyMenu(r)
                                }
                            }

                            if editingReplyID == r.id {
                                replyEditor(replyID: r.id)
                            } else {
                                Text(r.text)
                                    .font(.system(size: 12.5, weight: .regular, design: .rounded))
                                    .foregroundStyle(Pingu.body)
                                    .lineSpacing(2)
                            }

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

    // MARK: - Own post menu / editor

    private var ownPostMenu: some View {
        Menu {
            Button {
                editPostText = post.text
                editingPost = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive) {
                pendingDelete = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Pingu.muted)
                .frame(width: 24, height: 24)
        }
        .confirmationDialog(
            "Delete this post?",
            isPresented: $pendingDelete,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                circleStore.deletePost(post)
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var postEditor: some View {
        VStack(alignment: .trailing, spacing: 6) {
            TextField("Edit your share…", text: $editPostText, axis: .vertical)
                .font(.system(size: 13.5, design: .rounded))
                .foregroundStyle(Pingu.ink)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.white.opacity(0.75))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(.white.opacity(0.7), lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            HStack(spacing: 8) {
                Button("Cancel") {
                    editingPost = false
                    editPostText = ""
                }
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(Pingu.muted)

                Button {
                    let trimmed = editPostText.trimmed
                    guard !trimmed.isEmpty else { return }
                    circleStore.updatePost(post.id, text: trimmed)
                    editingPost = false
                    editPostText = ""
                } label: {
                    Text("Save")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(GlassPrimaryFill(cornerRadius: 999))
                        .clipShape(Capsule())
                }
                .disabled(editPostText.trimmed.isEmpty)
            }
        }
    }

    // MARK: - Reply menu / editor

    private func ownReplyMenu(_ r: PostReply) -> some View {
        Menu {
            Button {
                editReplyText = r.text
                editingReplyID = r.id
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive) {
                pendingDeleteReplyID = r.id
            } label: {
                Label("Delete", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Pingu.muted)
                .frame(width: 20, height: 20)
        }
        .confirmationDialog(
            "Delete this reply?",
            isPresented: Binding(
                get: { pendingDeleteReplyID == r.id },
                set: { if !$0 { pendingDeleteReplyID = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                circleStore.deleteReply(postID: post.id, replyID: r.id)
                pendingDeleteReplyID = nil
            }
            Button("Cancel", role: .cancel) {
                pendingDeleteReplyID = nil
            }
        }
    }

    private func replyEditor(replyID: UUID) -> some View {
        VStack(alignment: .trailing, spacing: 6) {
            TextField("Edit your reply…", text: $editReplyText, axis: .vertical)
                .font(.system(size: 12.5, design: .rounded))
                .foregroundStyle(Pingu.ink)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(.white.opacity(0.75))
                .overlay {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(.white.opacity(0.7), lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            HStack(spacing: 8) {
                Button("Cancel") {
                    editingReplyID = nil
                    editReplyText = ""
                }
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Pingu.muted)

                Button {
                    let trimmed = editReplyText.trimmed
                    guard !trimmed.isEmpty else { return }
                    circleStore.updateReply(postID: post.id, replyID: replyID, text: trimmed)
                    editingReplyID = nil
                    editReplyText = ""
                } label: {
                    Text("Save")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(GlassPrimaryFill(cornerRadius: 999))
                        .clipShape(Capsule())
                }
                .disabled(editReplyText.trimmed.isEmpty)
            }
        }
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
