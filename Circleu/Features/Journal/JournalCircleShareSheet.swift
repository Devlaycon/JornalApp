import SwiftUI

struct JournalCircleShareSheet: View {
    let entry: JournalReflectionEntry
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var circleStore: CircleStore

    var body: some View {
        NavigationStack {
            ZStack {
                PinguScreenBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Save to community")
                                .font(PinguFont.screenTitle)
                                .foregroundStyle(PinguDesign.ink)

                            Text("Choose where this reflection should live as a private local community post.")
                                .font(PinguFont.body)
                                .foregroundStyle(PinguDesign.muted)
                                .lineSpacing(4)
                        }

                        reflectionContextCard

                        if circleStore.circles.isEmpty {
                            emptyCommunityState
                        } else {
                            ForEach(circleStore.circles) { circle in
                                circleChoice(circle)
                            }
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

    private var reflectionContextCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("Saving")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(PinguDesign.muted)

            Text(entry.displayTitle)
                .font(PinguFont.cardTitle)
                .foregroundStyle(PinguDesign.ink)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Text(entry.displayEmotion)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(PinguDesign.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(PinguDesign.lightBlue.opacity(0.66))
                    .clipShape(Capsule())

                Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(PinguDesign.muted)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pinguGlass(cornerRadius: 22, tint: 0.22)
    }

    private var emptyCommunityState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(PinguDesign.blue)

            Text("No communities yet")
                .font(PinguFont.cardTitle)
                .foregroundStyle(PinguDesign.ink)

            Text("Open the Circle tab and create a private community before saving journal insights there.")
                .font(PinguFont.body)
                .foregroundStyle(PinguDesign.muted)
                .lineSpacing(4)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pinguGlass(cornerRadius: 22, tint: 0.22)
    }

    private func circleChoice(_ circle: CircleSpace) -> some View {
        let hasShared = circleStore.hasShared(entry: entry, to: circle)

        return Button {
            circleStore.share(entry: entry, to: circle)
            dismiss()
        } label: {
            HStack(spacing: 13) {
                Image(systemName: hasShared ? "checkmark.circle.fill" : "person.2.wave.2.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(hasShared ? PinguDesign.muted : PinguDesign.blue)
                    .frame(width: 46, height: 46)
                    .background(PinguDesign.lightBlue.opacity(0.62))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text(circle.name)
                        .font(PinguFont.cardTitle)
                        .foregroundStyle(PinguDesign.ink)
                        .lineLimit(1)

                    Text(hasShared ? "Already saved here" : circle.intention)
                        .font(PinguFont.body)
                        .foregroundStyle(PinguDesign.muted)
                        .lineLimit(2)
                        .lineSpacing(3)
                }

                Spacer()

                Image(systemName: hasShared ? "checkmark" : "plus")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(hasShared ? PinguDesign.muted : PinguDesign.blue)
            }
            .padding(15)
            .pinguGlass(cornerRadius: 20, tint: 0.22)
            .opacity(hasShared ? 0.62 : 1)
        }
        .buttonStyle(.plain)
        .disabled(hasShared)
    }
}
