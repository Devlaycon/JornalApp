import SwiftUI

struct SaveConfirmationView: View {
    let entry: JournalReflectionEntry?
    let onDone: () -> Void
    let onViewJournal: () -> Void
    let onRecordAnother: () -> Void

    init(
        entry: JournalReflectionEntry?,
        onDone: @escaping () -> Void,
        onViewJournal: @escaping () -> Void = {},
        onRecordAnother: @escaping () -> Void = {}
    ) {
        self.entry = entry
        self.onDone = onDone
        self.onViewJournal = onViewJournal
        self.onRecordAnother = onRecordAnother
    }

    var body: some View {
        ZStack {
            PinguScreenBackground()

            VStack(spacing: 26) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(PinguDesign.lightBlue.opacity(0.72))
                        .frame(width: 124, height: 124)

                    Image(systemName: "checkmark")
                        .font(.system(size: 46, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 86, height: 86)
                        .background(PinguDesign.blue)
                        .clipShape(Circle())
                }

                VStack(spacing: 12) {
                    Text("Reflection saved")
                        .font(PinguFont.screenTitle)
                        .foregroundStyle(PinguDesign.ink)

                    Text(entry == nil ? "Your reflection is complete." : "Saved in Journal.")
                        .font(PinguFont.body)
                        .foregroundStyle(PinguDesign.muted)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .frame(maxWidth: 330)
                }

                if let entry {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(entry.result.title)
                            .font(PinguFont.cardTitle)
                            .foregroundStyle(PinguDesign.ink)

                        Text(entry.result.summary)
                            .font(PinguFont.body)
                            .foregroundStyle(PinguDesign.body)
                            .lineSpacing(4)

                        Text(entry.engineName)
                            .font(PinguFont.caption)
                            .foregroundStyle(PinguDesign.blue)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .pinguGlass(cornerRadius: 22, tint: 0.22)
                    .padding(.horizontal, PinguDesign.screenSidePadding)
                }

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        onViewJournal()
                    } label: {
                        Label("View Journal", systemImage: "book.closed.fill")
                    }
                    .buttonStyle(PinguPrimaryButtonStyle())
                    .disabled(entry == nil)
                    .opacity(entry == nil ? 0.55 : 1)

                    Button {
                        onRecordAnother()
                    } label: {
                        Label("Record Another", systemImage: "mic.fill")
                    }
                    .buttonStyle(PinguSecondaryButtonStyle())

                    Button("Done") {
                        onDone()
                    }
                    .font(PinguFont.cardTitle)
                    .foregroundStyle(PinguDesign.blue)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, PinguDesign.screenSidePadding)
                .padding(.bottom, 28)
            }
        }
    }
}

#Preview {
    SaveConfirmationView(entry: .preview, onDone: {})
}
