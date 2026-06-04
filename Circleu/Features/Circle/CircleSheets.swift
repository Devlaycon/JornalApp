import SwiftUI

struct CircleCreateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var circleStore: CircleStore
    @State private var name = ""
    @State private var intention = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Capsule()
                .fill(PinguDesign.border)
                .frame(width: 46, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

            Text("Create a circle")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(PinguDesign.ink)

            VStack(spacing: 12) {
                PinguTextInput(title: "Name", placeholder: "Study confidence", text: $name)
                PinguTextInput(title: "Intention", placeholder: "What will this space help you remember?", text: $intention)
            }

            Text("This creates a private local space, not a live group.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(PinguDesign.muted)

            Spacer()

            Button {
                circleStore.createCircle(name: name, intention: intention)
                dismiss()
            } label: {
                Label("Create circle", systemImage: "plus")
            }
            .buttonStyle(PinguPrimaryButtonStyle())
            .disabled(!canSave)
            .opacity(canSave ? 1 : 0.55)
        }
        .padding(24)
        .background(PinguDesign.ice)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !intention.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct CircleDetailSheet: View {
    let circleID: UUID
    let entries: [JournalReflectionEntry]
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var circleStore: CircleStore
    @State private var noteTitle = ""
    @State private var noteBody = ""
    @State private var showEditCircle = false
    @State private var showReflectionPicker = false
    @State private var editingPost: CirclePost?

    var body: some View {
        NavigationStack {
            ZStack {
                PinguScreenBackground()

                if let circle {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 18) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(circle.name)
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundStyle(PinguDesign.ink)

                                Text(circle.intention)
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundStyle(PinguDesign.muted)
                                    .lineSpacing(4)
                            }

                            quickActions(circle: circle)
                            addNoteForm(circle: circle)
                            postsList(circle: circle)
                        }
                        .padding(.horizontal, PinguDesign.screenSidePadding)
                        .padding(.top, 18)
                        .padding(.bottom, 34)
                    }
                } else {
                    Text("This circle is no longer available.")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(PinguDesign.muted)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        if let circle {
                            Button {
                                showEditCircle = true
                            } label: {
                                Image(systemName: "pencil")
                            }

                            Button(role: .destructive) {
                                circleStore.deleteCircle(circle)
                                dismiss()
                            } label: {
                                Image(systemName: "trash")
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showEditCircle) {
            if let circle {
                CircleEditSheet(circle: circle)
                    .environmentObject(circleStore)
                    .presentationDetents([.medium])
            }
        }
        .sheet(isPresented: $showReflectionPicker) {
            if let circle {
                ReflectionPickerSheet(circle: circle, entries: entries)
                    .environmentObject(circleStore)
                    .presentationDetents([.large])
            }
        }
        .sheet(item: $editingPost) { post in
            CirclePostEditSheet(post: post)
                .environmentObject(circleStore)
                .presentationDetents([.medium])
        }
    }

    private var circle: CircleSpace? {
        circleStore.circles.first { $0.id == circleID }
    }

    private func quickActions(circle: CircleSpace) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick actions")
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(PinguDesign.ink)

            Button {
                showReflectionPicker = true
            } label: {
                Label(entries.isEmpty ? "Save a reflection to share" : "Choose reflection to share", systemImage: "sparkles")
            }
            .buttonStyle(PinguPrimaryButtonStyle())
            .disabled(entries.isEmpty)
            .opacity(entries.isEmpty ? 0.55 : 1)
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func addNoteForm(circle: CircleSpace) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add support note")
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(PinguDesign.ink)

            PinguTextInput(title: "Title", placeholder: "Before presentation", text: $noteTitle)
            PinguTextInput(title: "Note", placeholder: "What do you want to remember?", text: $noteBody, axis: .vertical)

            Button {
                circleStore.addNote(circle: circle, title: noteTitle, body: noteBody)
                noteTitle = ""
                noteBody = ""
            } label: {
                Label("Save note", systemImage: "text.badge.plus")
            }
            .buttonStyle(PinguSecondaryButtonStyle())
            .disabled(!canSaveNote)
            .opacity(canSaveNote ? 1 : 0.55)
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var canSaveNote: Bool {
        !noteTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !noteBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func postsList(circle: CircleSpace) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Saved posts")
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(PinguDesign.ink)

            let posts = circleStore.posts(for: circle)
            if posts.isEmpty {
                Text("Notes and reflection shares you save here will appear in this space.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(PinguDesign.muted)
                    .lineSpacing(4)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                ForEach(posts) { post in
                    CirclePostCard(post: post)
                        .contextMenu {
                            Button {
                                editingPost = post
                            } label: {
                                Label("Edit post", systemImage: "pencil")
                            }

                            Button(role: .destructive) {
                                circleStore.deletePost(post)
                            } label: {
                                Label("Delete post", systemImage: "trash")
                            }
                        }
                }
            }
        }
    }
}

private struct CirclePostCard: View {
    let post: CirclePost

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Label(post.sourceEntryID == nil ? "Note" : "Reflection", systemImage: post.sourceEntryID == nil ? "text.bubble.fill" : "sparkles")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(PinguDesign.blue)

                Spacer()

                Text(post.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(PinguDesign.muted)
            }

            Text(post.title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(PinguDesign.ink)

            Text(post.body)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(PinguDesign.body)
                .lineSpacing(4)
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

private struct CircleEditSheet: View {
    let circle: CircleSpace
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var circleStore: CircleStore
    @State private var name = ""
    @State private var intention = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Capsule()
                .fill(PinguDesign.border)
                .frame(width: 46, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

            Text("Edit circle")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(PinguDesign.ink)

            VStack(spacing: 12) {
                PinguTextInput(title: "Name", placeholder: "Circle name", text: $name)
                PinguTextInput(title: "Intention", placeholder: "What this space supports", text: $intention)
            }

            Spacer()

            Button("Save changes") {
                circleStore.updateCircle(circle, name: name, intention: intention)
                dismiss()
            }
            .buttonStyle(PinguPrimaryButtonStyle())
            .disabled(!canSave)
            .opacity(canSave ? 1 : 0.55)
        }
        .padding(24)
        .background(PinguDesign.ice)
        .onAppear {
            name = circle.name
            intention = circle.intention
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !intention.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

private struct ReflectionPickerSheet: View {
    let circle: CircleSpace
    let entries: [JournalReflectionEntry]
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var circleStore: CircleStore

    var body: some View {
        NavigationStack {
            ZStack {
                PinguScreenBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Share to \(circle.name)")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(PinguDesign.ink)

                        Text("Choose a saved reflection. Circleu keeps a privacy-safe local copy in this circle.")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(PinguDesign.muted)
                            .lineSpacing(4)

                        ForEach(entries) { entry in
                            Button {
                                circleStore.share(entry: entry, to: circle)
                                dismiss()
                            } label: {
                                HStack(spacing: 13) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(PinguDesign.blue)
                                        .frame(width: 44, height: 44)
                                        .background(PinguDesign.lightBlue.opacity(0.66))
                                        .clipShape(Circle())

                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(entry.displayTitle)
                                            .font(.system(size: 17, weight: .bold, design: .rounded))
                                            .foregroundStyle(PinguDesign.ink)
                                            .lineLimit(1)

                                        Text("\(entry.displayEmotion) - \(entry.createdAt.formatted(date: .abbreviated, time: .shortened))")
                                            .font(.system(size: 13, weight: .bold, design: .rounded))
                                            .foregroundStyle(PinguDesign.muted)
                                    }

                                    Spacer()

                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundStyle(PinguDesign.blue)
                                }
                                .padding(15)
                                .background(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .disabled(circleStore.posts(for: circle).contains { $0.sourceEntryID == entry.id })
                            .opacity(circleStore.posts(for: circle).contains { $0.sourceEntryID == entry.id } ? 0.45 : 1)
                        }
                    }
                    .padding(.horizontal, PinguDesign.screenSidePadding)
                    .padding(.top, 20)
                    .padding(.bottom, 34)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct CirclePostEditSheet: View {
    let post: CirclePost
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var circleStore: CircleStore
    @State private var title = ""
    @State private var postBody = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Capsule()
                .fill(PinguDesign.border)
                .frame(width: 46, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

            Text(post.sourceEntryID == nil ? "Edit note" : "Edit saved reflection")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(PinguDesign.ink)

            VStack(spacing: 12) {
                PinguTextInput(title: "Title", placeholder: "Post title", text: $title)
                PinguTextInput(title: "Body", placeholder: "Post body", text: $postBody, axis: .vertical)
            }

            Spacer()

            HStack(spacing: 10) {
                Button(role: .destructive) {
                    circleStore.deletePost(post)
                    dismiss()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(PinguSecondaryButtonStyle())

                Button("Save") {
                    circleStore.updatePost(post, title: title, body: postBody)
                    dismiss()
                }
                .buttonStyle(PinguPrimaryButtonStyle())
                .disabled(!canSave)
                .opacity(canSave ? 1 : 0.55)
            }
        }
        .padding(24)
        .background(PinguDesign.ice)
        .onAppear {
            title = post.title
            postBody = post.body
        }
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !postBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
