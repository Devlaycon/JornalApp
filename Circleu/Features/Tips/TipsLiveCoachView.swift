import PhotosUI
import SwiftUI
import UIKit

struct TipsLiveCoachView: View {
    @ObservedObject var viewModel: TipsPracticeViewModel
    @State private var selectedReplyItem: PhotosPickerItem?
    @State private var composerMode: ComposerMode = .reply
    @State private var copiedMain = false
    @State private var copiedOptionID: TipsCoachReplyOption.ID?

    private enum ComposerMode { case reply, context }

    private func copyMain(_ text: String) {
        UIPasteboard.general.string = text
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { copiedMain = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeOut(duration: 0.2)) { copiedMain = false }
        }
    }

    private func copyOption(_ option: TipsCoachReplyOption) {
        UIPasteboard.general.string = option.text
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { copiedOptionID = option.id }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeOut(duration: 0.2)) {
                if copiedOptionID == option.id { copiedOptionID = nil }
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            contextBar

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    if let session = viewModel.activeSession {
                        PinguMascot(size: 64, mood: .idle)
                            .padding(.top, 8)

                        let firstReplyIndex = session.turns.firstIndex { $0.role == .simulatedPerson }
                        // Pin the "Now what?" card to the latest "They replied" turn so any
                        // later turns (Extra context, refreshed Suggested phrasing) appear
                        // BELOW it in chronological order.
                        let lastReplyIndex = session.turns.lastIndex { $0.role == .simulatedPerson }

                        ForEach(Array(session.turns.enumerated()), id: \.element.id) { index, turn in
                            if index == firstReplyIndex {
                                dividerPill
                            }
                            if turn.role == .user || turn.role == .simulatedPerson {
                                TipsCoachBubble(label: turn.label, text: turn.text, role: turn.role)
                            } else if turn.role == .coach && turn.label == "Suggested phrasing" {
                                suggestedPhrasingCard(text: turn.text, why: session.coachOutput.whyItWorks)
                            }

                            if index == lastReplyIndex {
                                nowWhatCard(session)
                            }
                        }
                    }
                }
                .padding(.horizontal, PinguDesign.screenSidePadding)
                .padding(.bottom, 18)
            }

            composer
        }
        .preference(key: TabBarHiddenKey.self, value: true)
        .onChange(of: selectedReplyItem) { _, newItem in
            Task {
                guard let data = try? await newItem?.loadTransferable(type: Data.self) else { return }
                await MainActor.run {
                    viewModel.attachReplyImage(data)
                }
            }
        }
    }

    // MARK: - Top / Context

    private var topBar: some View {
        DemoNavBar(
            title: "Live coach",
            subtitle: "in real time",
            onBack: { viewModel.backToSetup() }
        )
    }

    private var contextBar: some View {
        HStack(spacing: 8) {
            contextChip(viewModel.sceneTitle, icon: viewModel.scene.icon, isPrimary: true)
            contextChip(viewModel.tone.title, icon: "slider.horizontal.3", isPrimary: false)
            Spacer()
            Button("edit ↗") {
                viewModel.backToSetup()
            }
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(PinguDesign.blue)
        }
        .padding(.horizontal, PinguDesign.screenSidePadding)
        .padding(.bottom, 8)
    }

    private func contextChip(_ title: String, icon: String, isPrimary: Bool) -> some View {
        Label(title, systemImage: icon)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(isPrimary ? .white : PinguDesign.ink)
            .padding(.horizontal, 12)
            .frame(height: 30)
            .background {
                if isPrimary {
                    GlassPrimaryFill(cornerRadius: 999)
                } else {
                    Capsule().fill(.ultraThinMaterial)
                        .overlay { Capsule().fill(.white.opacity(0.28)) }
                        .overlay { Capsule().strokeBorder(.white.opacity(0.55), lineWidth: 1) }
                }
            }
            .clipShape(Capsule())
    }

    // MARK: - Suggested Phrasing Card

    @ViewBuilder
    private func suggestedPhrasingCard(text: String, why: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("SUGGESTED PHRASING")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(PinguDesign.blue)

            VStack(alignment: .leading, spacing: 12) {
                // Blue left-border quote
                HStack(alignment: .top, spacing: 0) {
                    Rectangle()
                        .fill(PinguDesign.blue)
                        .frame(width: 4)
                    Text("\u{201C}\(text)\u{201D}")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(PinguDesign.ink)
                        .lineSpacing(3)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(PinguDesign.blue.opacity(0.06))
                }
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                // Why this works inline
                (Text("Why this works: ").font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(PinguDesign.ink)
                 + Text(why).font(.system(size: 12, weight: .regular, design: .rounded)).foregroundStyle(PinguDesign.body))
                    .lineSpacing(3)

                // Action pills
                HStack(spacing: 8) {
                    Button {
                        copyMain(text)
                    } label: {
                        Label(copiedMain ? "Copied!" : "Copy",
                              systemImage: copiedMain ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .frame(height: 30)
                            .background {
                                if copiedMain {
                                    Capsule().fill(Color(hex: 0x22C55E))
                                } else {
                                    GlassPrimaryFill(cornerRadius: 999)
                                }
                            }
                            .clipShape(Capsule())
                    }
                    .buttonStyle(PressableButtonStyle())

                    Button {
                        viewModel.trySofter()
                    } label: {
                        Label("Try softer", systemImage: "arrow.triangle.2.circlepath")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(PinguDesign.ink)
                            .padding(.horizontal, 12)
                            .frame(height: 30)
                            .background(.ultraThinMaterial)
                            .overlay { Capsule().fill(.white.opacity(0.28)) }
                            .overlay { Capsule().strokeBorder(.white.opacity(0.55), lineWidth: 1) }
                            .clipShape(Capsule())
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
            .padding(14)
            .glass(.strong, cornerRadius: 18)
            .frame(maxWidth: 300, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Divider

    private var dividerPill: some View {
        Text("— sent in real life · later —")
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(PinguDesign.muted)
            .padding(.horizontal, 16)
            .frame(height: 30)
            .background(.ultraThinMaterial)
            .overlay { Capsule().fill(.white.opacity(0.28)) }
            .overlay { Capsule().strokeBorder(.white.opacity(0.55), lineWidth: 1) }
            .clipShape(Capsule())
            .frame(maxWidth: .infinity)
    }

    // MARK: - Now What Card (amber)

    @ViewBuilder
    private func nowWhatCard(_ session: TipsPracticeSession) -> some View {
        let roomReading = session.turns.last(where: { $0.role == .coach && $0.label != "Suggested phrasing" })?.text ?? ""
        let output = session.coachOutput

        VStack(alignment: .leading, spacing: 6) {
            Text("NOW WHAT?")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(Pingu.amber)

            VStack(alignment: .leading, spacing: 12) {
                Text("ⓘ Reading the room")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(Pingu.amber)

                if !roomReading.isEmpty {
                    Text(roomReading)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(PinguDesign.ink)
                        .lineSpacing(3)
                }

                VStack(spacing: 8) {
                    ForEach(output.replyOptions) { option in
                        HStack(alignment: .top, spacing: 10) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(option.label.uppercased())
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .tracking(0.8)
                                    .foregroundStyle(PinguDesign.blue)
                                Text(option.text)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundStyle(PinguDesign.ink)
                                    .lineSpacing(3)
                            }
                            Spacer()
                            Button {
                                copyOption(option)
                            } label: {
                                Image(systemName: copiedOptionID == option.id ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(copiedOptionID == option.id ? Color(hex: 0x22C55E) : PinguDesign.muted)
                            }
                        }
                        .padding(12)
                        .glass(.regular, cornerRadius: 14)
                    }
                }
            }
            .padding(14)
            .background(
                LinearGradient(
                    colors: [.white.opacity(0.7), Color(hex: 0xFEF3C7).opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color(hex: 0xFDE68A).opacity(0.8), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Composer

    private var composer: some View {
        VStack(spacing: 0) {
            // Mode pills
            HStack(spacing: 8) {
                modePill("Paste their reply", mode: .reply)
                modePill("Add context", mode: .context)
                Spacer()
            }
            .padding(.horizontal, PinguDesign.screenSidePadding)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // Image preview
            if let data = viewModel.replyImageData {
                HStack {
                    TipsImagePreview(data: data) {
                        selectedReplyItem = nil
                        viewModel.attachReplyImage(nil)
                    }
                    Spacer()
                }
                .padding(.horizontal, PinguDesign.screenSidePadding)
                .padding(.bottom, 8)
            }

            // Input row
            HStack(spacing: 8) {
                PhotosPicker(selection: $selectedReplyItem, matching: .images) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(PinguDesign.ink)
                        .frame(width: 40, height: 40)
                        .background(.ultraThinMaterial)
                        .overlay { Circle().fill(.white.opacity(0.28)) }
                        .overlay { Circle().strokeBorder(.white.opacity(0.55), lineWidth: 1) }
                        .clipShape(Circle())
                }

                if composerMode == .reply {
                    TextField("Paste their reply…", text: $viewModel.replyInput, axis: .vertical)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(PinguDesign.ink)
                        .lineLimit(1...3)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .frame(minHeight: 40)
                        .background(.white.opacity(0.7))
                        .overlay {
                            Capsule().strokeBorder(.white.opacity(0.6), lineWidth: 1)
                        }
                        .clipShape(Capsule())
                } else {
                    TextField("Add your own context…", text: $viewModel.extraContextInput, axis: .vertical)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(PinguDesign.ink)
                        .lineLimit(1...3)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .frame(minHeight: 40)
                        .background(.white.opacity(0.7))
                        .overlay {
                            Capsule().strokeBorder(.white.opacity(0.6), lineWidth: 1)
                        }
                        .clipShape(Capsule())
                }

                let canSend = composerMode == .reply
                    ? viewModel.canSubmitReplyMode
                    : viewModel.canSubmitContextMode

                Button {
                    if composerMode == .reply {
                        viewModel.submitReply()
                    } else {
                        viewModel.submitContext()
                    }
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            canSend
                                ? AnyView(GlassPrimaryFill(cornerRadius: 999))
                                : AnyView(Color(hex: 0xCBD5E1))
                        )
                        .clipShape(Circle())
                }
                .disabled(!canSend)
            }
            .padding(.horizontal, PinguDesign.screenSidePadding)
            .padding(.bottom, 24)

            if let hint = viewModel.inputHint ?? viewModel.speechRecognizer.errorMessage {
                Text(hint)
                    .font(PinguFont.caption)
                    .foregroundStyle(PinguDesign.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, PinguDesign.screenSidePadding)
                    .padding(.bottom, 8)
            }
        }
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(.white.opacity(0.35))
                        .frame(height: 0.5)
                }
                .ignoresSafeArea(edges: .bottom)
        }
    }

    private func modePill(_ label: String, mode: ComposerMode) -> some View {
        Button { composerMode = mode } label: {
            Text(label)
                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                .foregroundStyle(composerMode == mode ? .white : PinguDesign.muted)
                .padding(.horizontal, 12)
                .frame(height: 30)
                .background {
                    if composerMode == mode {
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
