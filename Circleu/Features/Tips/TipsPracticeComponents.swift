import SwiftUI
import UIKit

struct TipsSectionLabel: View {
    let number: String
    let title: String
    let note: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 7) {
            Text(number)
                .font(PinguFont.caption)
                .foregroundStyle(PinguDesign.blue)
            Text(title)
                .font(PinguFont.caption)
                .foregroundStyle(PinguDesign.ink)
            Text(note)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(PinguDesign.muted)
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
            Label(title, systemImage: scene.icon)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .foregroundStyle(isSelected ? .white : PinguDesign.ink)
                .padding(.horizontal, 14)
                .frame(height: 42)
                .background(isSelected ? PinguDesign.blue : .white)
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .stroke(isSelected ? PinguDesign.blue : PinguDesign.border, lineWidth: 1.2)
                }
                .shadow(color: isSelected ? PinguDesign.blue.opacity(0.18) : .clear, radius: 8, y: 4)
        }
        .buttonStyle(.plain)
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
                .foregroundStyle(role == .coach ? PinguDesign.blue : PinguDesign.muted)

            Text(text)
                .font(PinguFont.body)
                .foregroundStyle(role == .user ? .white : PinguDesign.ink)
                .lineSpacing(3)
                .padding(14)
                .background(background)
                .clipShape(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
                .frame(maxWidth: role == .coach ? 310 : 285, alignment: role == .user ? .trailing : .leading)
        }
        .frame(maxWidth: .infinity, alignment: role == .user ? .trailing : .leading)
    }

    private var background: Color {
        switch role {
        case .user:
            PinguDesign.blue
        case .coach:
            .white
        case .simulatedPerson:
            PinguDesign.lightBlue.opacity(0.72)
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
