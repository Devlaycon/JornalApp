import SwiftUI

struct CircleCreateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var circleStore: CircleStore
    @StateObject private var viewModel = CircleCreateViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Capsule()
                .fill(PinguDesign.border)
                .frame(width: 46, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

            Text("Create community")
                .font(PinguFont.screenTitle)
                .foregroundStyle(PinguDesign.ink)

            VStack(spacing: 12) {
                PinguTextInput(title: "Name", placeholder: "Study confidence", text: $viewModel.name)
                PinguTextInput(title: "Purpose", placeholder: "What will this community help you tips?", text: $viewModel.intention)
            }

            Text("This creates a private local community space. Live group sync can be added later when the backend is ready.")
                .font(PinguFont.body)
                .foregroundStyle(PinguDesign.muted)

            Spacer()

            Button {
                viewModel.create(circleStore: circleStore)
                dismiss()
            } label: {
                Label("Create community", systemImage: "plus")
            }
            .buttonStyle(PinguPrimaryButtonStyle())
            .disabled(!viewModel.canSave)
            .opacity(viewModel.canSave ? 1 : 0.55)
        }
        .padding(24)
        .background(PinguDesign.ice)
    }
}

struct CircleDetailSheet: View {
    let circleID: UUID
    let entries: [JournalReflectionEntry]
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var circleStore: CircleStore
    @StateObject private var viewModel = CircleDetailViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                PinguScreenBackground()

                if let circle {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 18) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(circle.name)
                                    .font(PinguFont.screenTitle)
                                    .foregroundStyle(PinguDesign.ink)

                                Text(circle.intention)
                                    .font(PinguFont.body)
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
                    Text("This community is no longer available.")
                        .font(PinguFont.cardTitle)
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
                                viewModel.showEditCircle = true
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
        .sheet(isPresented: $viewModel.showEditCircle) {
            if let circle {
                CircleEditSheet(circle: circle)
                    .environmentObject(circleStore)
                    .presentationDetents([.medium])
            }
        }
        .sheet(isPresented: $viewModel.showReflectionPicker) {
            if let circle {
                ReflectionPickerSheet(circle: circle, entries: entries)
                    .environmentObject(circleStore)
                    .presentationDetents([.large])
            }
        }
        .sheet(item: $viewModel.editingPost) { post in
            CirclePostEditSheet(post: post)
                .environmentObject(circleStore)
                .presentationDetents([.medium])
        }
    }

    private var circle: CircleSpace? {
        viewModel.circle(id: circleID, circleStore: circleStore)
    }

    private func quickActions(circle: CircleSpace) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick actions")
                .font(PinguFont.cardTitle)
                .foregroundStyle(PinguDesign.ink)

            Button {
                viewModel.showReflectionPicker = true
            } label: {
                Label(entries.isEmpty ? "Save a reflection first" : "Share a reflection card", systemImage: "sparkles")
            }
            .buttonStyle(PinguPrimaryButtonStyle())
            .disabled(entries.isEmpty)
            .opacity(entries.isEmpty ? 0.55 : 1)
        }
        .padding(16)
        .pinguGlass(cornerRadius: 22, tint: 0.22)
    }

    private func addNoteForm(circle: CircleSpace) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add community note")
                .font(PinguFont.cardTitle)
                .foregroundStyle(PinguDesign.ink)

            PinguTextInput(title: "Title", placeholder: "Before presentation", text: $viewModel.noteTitle)
            PinguTextInput(title: "Note", placeholder: "What should this community help you remember?", text: $viewModel.noteBody, axis: .vertical)

            Button {
                viewModel.saveNote(circle: circle, circleStore: circleStore)
            } label: {
                Label("Save note", systemImage: "text.badge.plus")
            }
            .buttonStyle(PinguSecondaryButtonStyle())
            .disabled(!viewModel.canSaveNote)
            .opacity(viewModel.canSaveNote ? 1 : 0.55)
        }
        .padding(16)
        .pinguGlass(cornerRadius: 22, tint: 0.22)
    }

    private func postsList(circle: CircleSpace) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Saved posts")
                .font(PinguFont.cardTitle)
                .foregroundStyle(PinguDesign.ink)

            let posts = circleStore.posts(for: circle)
            if posts.isEmpty {
                Text("Community notes and reflection cards you save here will appear in this space.")
                    .font(PinguFont.body)
                    .foregroundStyle(PinguDesign.muted)
                    .lineSpacing(4)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .pinguGlass(cornerRadius: 20, tint: 0.22)
            } else {
                ForEach(posts) { post in
                    CirclePostCard(post: post)
                        .contextMenu {
                            Button {
                                viewModel.edit(post)
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
                    .font(PinguFont.caption)
                    .foregroundStyle(PinguDesign.blue)

                Spacer()

                Text(post.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(PinguFont.tiny)
                    .foregroundStyle(PinguDesign.muted)
            }

            Text(post.title)
                .font(PinguFont.cardTitle)
                .foregroundStyle(PinguDesign.ink)

            Text(post.body)
                .font(PinguFont.body)
                .foregroundStyle(PinguDesign.body)
                .lineSpacing(4)
        }
        .padding(16)
        .pinguGlass(cornerRadius: 20, tint: 0.22)
    }
}

private struct CircleEditSheet: View {
    let circle: CircleSpace
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var circleStore: CircleStore
    @StateObject private var viewModel = CircleEditViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Capsule()
                .fill(PinguDesign.border)
                .frame(width: 46, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

            Text("Edit community")
                .font(PinguFont.screenTitle)
                .foregroundStyle(PinguDesign.ink)

            VStack(spacing: 12) {
                PinguTextInput(title: "Name", placeholder: "Community name", text: $viewModel.name)
                PinguTextInput(title: "Purpose", placeholder: "What this community supports", text: $viewModel.intention)
            }

            Spacer()

            Button("Save changes") {
                viewModel.save(circle: circle, circleStore: circleStore)
                dismiss()
            }
            .buttonStyle(PinguPrimaryButtonStyle())
            .disabled(!viewModel.canSave)
            .opacity(viewModel.canSave ? 1 : 0.55)
        }
        .padding(24)
        .background(PinguDesign.ice)
        .onAppear {
            viewModel.load(circle: circle)
        }
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
                            .font(PinguFont.screenTitle)
                            .foregroundStyle(PinguDesign.ink)

                        Text("Choose a saved reflection. Circleu keeps a privacy-safe local copy in this community.")
                            .font(PinguFont.body)
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
                                            .font(PinguFont.cardTitle)
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
                                .pinguGlass(cornerRadius: 20, tint: 0.22)
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
    @StateObject private var viewModel = CirclePostEditViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Capsule()
                .fill(PinguDesign.border)
                .frame(width: 46, height: 5)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

            Text(post.sourceEntryID == nil ? "Edit note" : "Edit saved reflection")
                .font(PinguFont.screenTitle)
                .foregroundStyle(PinguDesign.ink)

            VStack(spacing: 12) {
                PinguTextInput(title: "Title", placeholder: "Post title", text: $viewModel.title)
                PinguTextInput(title: "Body", placeholder: "Post body", text: $viewModel.postBody, axis: .vertical)
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
                    viewModel.save(post: post, circleStore: circleStore)
                    dismiss()
                }
                .buttonStyle(PinguPrimaryButtonStyle())
                .disabled(!viewModel.canSave)
                .opacity(viewModel.canSave ? 1 : 0.55)
            }
        }
        .padding(24)
        .background(PinguDesign.ice)
        .onAppear {
            viewModel.load(post: post)
        }
    }
}
