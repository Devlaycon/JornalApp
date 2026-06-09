import SwiftUI
import UIKit

struct TipsSectionLabel: View {
    let number: String
    let title: String
    let note: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(number)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Pingu.accent)
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Pingu.ink)
            Text("· \(note)")
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundStyle(Pingu.muted)
            Spacer()
        }
    }
}

struct TipsSceneChip: View {
    let scene: TipsPracticeScene
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .foregroundStyle(isSelected ? .white : Pingu.ink)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background {
                    if isSelected {
                        GlassPrimaryFill(cornerRadius: 999)
                    } else {
                        Capsule().fill(.ultraThinMaterial)
                            .overlay { Capsule().fill(.white.opacity(0.28)) }
                            .overlay { Capsule().strokeBorder(.white.opacity(0.55), lineWidth: 1) }
                    }
                }
                .clipShape(Capsule())
        }
        .buttonStyle(PressableButtonStyle())
    }
}

struct TipsImagePreview: View {
    let data: Data
    let onRemove: () -> Void

    var body: some View {
        if let image = UIImage(data: data) {
            ZStack(alignment: .topTrailing) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 82, height: 82)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(PinguDesign.border, lineWidth: 1)
                    }

                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(PinguDesign.orange)
                        .clipShape(Circle())
                }
                .offset(x: 7, y: -7)
            }
            .padding(.top, 6)
        }
    }
}

struct TipsCoachBubble: View {
    let label: String
    let text: String
    let role: TipsPracticeRole

    var body: some View {
        VStack(alignment: role == .user ? .trailing : .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(role == .coach ? Pingu.accent : Pingu.muted)

            bubble
                .frame(maxWidth: role == .coach ? 310 : 285, alignment: role == .user ? .trailing : .leading)
        }
        .frame(maxWidth: .infinity, alignment: role == .user ? .trailing : .leading)
    }

    @ViewBuilder
    private var bubble: some View {
        let textView = Text(text)
            .font(.system(size: 14, weight: .regular, design: .rounded))
            .lineSpacing(3)
            .padding(14)

        switch role {
        case .user:
            textView
                .foregroundStyle(Color.white)
                .background(GlassPrimaryFill(cornerRadius: 18))
                .clipShape(UnevenRoundedRectangle(
                    topLeadingRadius: 18, bottomLeadingRadius: 18,
                    bottomTrailingRadius: 4, topTrailingRadius: 18
                ))
        case .coach, .simulatedPerson:
            textView
                .foregroundStyle(Pingu.ink)
                .glass(.strong, cornerRadius: 18)
        }
    }
}

struct TipsReplyOptionCard: View {
    let option: TipsCoachReplyOption
    let onUse: () -> Void
    let onCopy: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 5) {
                Text(option.label)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(PinguDesign.blue)

                Text(option.text)
                    .font(PinguFont.body)
                    .foregroundStyle(PinguDesign.ink)
                    .lineSpacing(3)
            }

            Spacer()

            VStack(spacing: 8) {
                Button(action: onCopy) {
                    Image(systemName: "doc.on.doc")
                }
                Button(action: onUse) {
                    Image(systemName: "arrow.down.to.line")
                }
            }
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(PinguDesign.blue)
        }
        .padding(13)
        .pinguGlass(cornerRadius: 14, tint: 0.22)
    }
}

struct TipsPracticeHistorySection: View {
    let sessions: [TipsPracticeSession]
    let onResume: (TipsPracticeSession) -> Void
    let onDelete: (TipsPracticeSession) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Recent practice", systemImage: "bubble.left.and.text.bubble.right.fill")
                    .font(PinguFont.cardTitle)
                    .foregroundStyle(PinguDesign.ink)
                Spacer()
                Text("\(sessions.count)")
                    .font(PinguFont.caption)
                    .foregroundStyle(PinguDesign.blue)
                    .padding(.horizontal, 10)
                    .frame(height: 26)
                    .background(PinguDesign.lightBlue)
                    .clipShape(Capsule())
            }

            VStack(spacing: 10) {
                ForEach(sessions.prefix(4)) { session in
                    TipsPracticeSessionRow(
                        session: session,
                        onResume: { onResume(session) },
                        onDelete: { onDelete(session) }
                    )
                }
            }
        }
        .padding(16)
        .pinguGlass(cornerRadius: 20, tint: 0.22)
    }
}

private struct TipsPracticeSessionRow: View {
    let session: TipsPracticeSession
    let onResume: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 7) {
                Text(session.originalMessage)
                    .font(PinguFont.body)
                    .foregroundStyle(PinguDesign.ink)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    miniChip(session.sceneTitle, icon: session.scene.icon)
                    miniChip(session.tone.title, icon: "slider.horizontal.3")
                }

                Text(session.updatedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(PinguFont.tiny)
                    .foregroundStyle(PinguDesign.muted)
            }

            Spacer(minLength: 8)

            VStack(spacing: 8) {
                Button(action: onResume) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(PinguDesign.blue)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Resume practice")

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(PinguDesign.muted)
                        .frame(width: 34, height: 34)
                        .pinguGlass(cornerRadius: 17, tint: 0.16)
                }
                .accessibilityLabel("Delete practice")
            }
        }
        .padding(12)
        .background(PinguDesign.lightBlue.opacity(0.34))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func miniChip(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(PinguFont.tiny)
            .lineLimit(1)
            .foregroundStyle(PinguDesign.blue)
            .padding(.horizontal, 8)
            .frame(height: 23)
            .background(.white.opacity(0.86))
            .clipShape(Capsule())
    }
}

struct ReflectionTipsHistorySection: View {
    let activeQuests: [Quest]
    let completedQuests: [Quest]
    let skippedQuests: [Quest]
    let sourceEntry: (Quest) -> JournalReflectionEntry?
    let onOpenSource: (JournalReflectionEntry) -> Void
    let onComplete: (Quest) -> Void
    let onRestart: (Quest) -> Void

    var body: some View {
        DisclosureGroup {
            VStack(spacing: 10) {
                ForEach(activeQuests) { quest in
                    row(title: "Active", quest: quest, actionTitle: "Done") {
                        onComplete(quest)
                    }
                }
                ForEach(completedQuests.prefix(3)) { quest in
                    row(title: "Completed", quest: quest, actionTitle: "Open") {
                        if let entry = sourceEntry(quest) {
                            onOpenSource(entry)
                        }
                    }
                }
                ForEach(skippedQuests.prefix(3)) { quest in
                    row(title: "Saved", quest: quest, actionTitle: "Restart") {
                        onRestart(quest)
                    }
                }

                if activeQuests.isEmpty && completedQuests.isEmpty && skippedQuests.isEmpty {
                    Text("Reflection tips from saved AI reflections will stay here.")
                        .font(PinguFont.body)
                        .foregroundStyle(PinguDesign.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .pinguGlass(cornerRadius: 16, tint: 0.22)
                }
            }
            .padding(.top, 10)
        } label: {
            HStack {
                Label("Reflection tips", systemImage: "sparkles")
                    .font(PinguFont.cardTitle)
                    .foregroundStyle(PinguDesign.ink)
                Spacer()
                Text("\(activeQuests.count + completedQuests.count + skippedQuests.count)")
                    .font(PinguFont.caption)
                    .foregroundStyle(PinguDesign.blue)
                    .padding(.horizontal, 10)
                    .frame(height: 26)
                    .background(PinguDesign.lightBlue)
                    .clipShape(Capsule())
            }
        }
        .padding(16)
        .pinguGlass(cornerRadius: 20, tint: 0.22)
    }

    private func row(title: String, quest: Quest, actionTitle: String, action: @escaping () -> Void) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(PinguFont.caption)
                    .foregroundStyle(PinguDesign.muted)
                Text(quest.detail)
                    .font(PinguFont.body)
                    .foregroundStyle(PinguDesign.ink)
                    .lineLimit(2)
            }
            Spacer()
            Button(actionTitle, action: action)
                .font(PinguFont.caption)
                .foregroundStyle(PinguDesign.blue)
        }
        .padding(12)
        .background(PinguDesign.lightBlue.opacity(0.36))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
