import SwiftUI

struct JournalWorkspaceEditSheet: View {
    let entry: JournalReflectionEntry
    let onSave: (String, String, String, [String]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var emotion: String
    @State private var privateNote: String
    @State private var tagsText: String

    init(
        entry: JournalReflectionEntry,
        onSave: @escaping (String, String, String, [String]) -> Void
    ) {
        self.entry = entry
        self.onSave = onSave
        _title = State(initialValue: entry.displayTitle)
        _emotion = State(initialValue: entry.displayEmotion)
        _privateNote = State(initialValue: entry.privateNote)
        _tagsText = State(initialValue: entry.tags.joined(separator: ", "))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PinguScreenBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Edit workspace")
                                .font(PinguFont.screenTitle)
                                .foregroundStyle(PinguDesign.ink)

                            Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(PinguDesign.muted)
                        }

                        PinguTextInput(title: "Title", placeholder: "Reflection title", text: $title)
                        PinguTextInput(title: "Emotion", placeholder: "Emotion", text: $emotion)
                        PinguTextInput(
                            title: "Private note",
                            placeholder: "Add a note only you can see",
                            text: $privateNote,
                            axis: .vertical
                        )
                        PinguTextInput(title: "Tags", placeholder: "class, confidence, tips", text: $tagsText)
                    }
                    .padding(.horizontal, PinguDesign.screenSidePadding)
                    .padding(.top, 20)
                    .padding(.bottom, 34)
                }
            }
            .navigationTitle("Workspace")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(title, emotion, privateNote, parsedTags)
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }

    private var parsedTags: [String] {
        tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

#Preview {
    JournalWorkspaceEditSheet(entry: .preview) { _, _, _, _ in }
}
