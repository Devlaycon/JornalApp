import PhotosUI
import SwiftUI
import UIKit

struct TipsLiveCoachView: View {
    @ObservedObject var viewModel: TipsPracticeViewModel
    @State private var selectedReplyItem: PhotosPickerItem?

    var body: some View {
        VStack(spacing: 0) {
            topBar
            contextBar

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    if let session = viewModel.activeSession {
                        PinguAvatar(size: 64)
                            .padding(.top, 8)

                        ForEach(session.turns) { turn in
                            TipsCoachBubble(label: turn.label, text: turn.text, role: turn.role)
                        }

                        coachDetailCard(session.coachOutput)
                    }
                }
                .padding(.horizontal, PinguDesign.screenSidePadding)
                .padding(.bottom, 18)
            }

            composer
                .padding(.bottom, PinguDesign.bottomBarHeight)
        }
        .onChange(of: selectedReplyItem) { _, newItem in
            Task {
                guard let data = try? await newItem?.loadTransferable(type: Data.self) else { return }
                await MainActor.run {
                    viewModel.attachReplyImage(data)
                }
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                viewModel.backToSetup()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(PinguDesign.blue)
                    .frame(width: 42, height: 42)
            }

            Spacer()

            VStack(spacing: 2) {
                Text("Live coach")
                    .font(PinguFont.cardTitle)
                    .foregroundStyle(PinguDesign.ink)
                Text("Practice in real time")
                    .font(PinguFont.tiny)
                    .foregroundStyle(PinguDesign.blue)
            }

            Spacer()

            Button {
                viewModel.startNewTip()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(PinguDesign.blue)
                    .frame(width: 42, height: 42)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    private var contextBar: some View {
        HStack(spacing: 8) {
            contextChip(viewModel.sceneTitle, icon: viewModel.scene.icon, isPrimary: true)
            contextChip(viewModel.tone.title, icon: "slider.horizontal.3", isPrimary: false)
            Spacer()
            Button("edit") {
                viewModel.backToSetup()
            }
            .font(PinguFont.caption)
            .foregroundStyle(PinguDesign.blue)
        }
        .padding(.horizontal, PinguDesign.screenSidePadding)
        .padding(.bottom, 8)
    }

    private func contextChip(_ title: String, icon: String, isPrimary: Bool) -> some View {
        Label(title, systemImage: icon)
            .font(PinguFont.caption)
            .foregroundStyle(isPrimary ? .white : PinguDesign.ink)
            .padding(.horizontal, 11)
            .frame(height: 30)
            .background(isPrimary ? PinguDesign.blue : .white)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(isPrimary ? PinguDesign.blue : PinguDesign.border, lineWidth: 1)
            }
    }

    private func coachDetailCard(_ output: TipsCoachOutput) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            Text("Why this works")
                .font(PinguFont.cardTitle)
                .foregroundStyle(PinguDesign.ink)

            Text(output.whyItWorks)
                .font(PinguFont.body)
                .foregroundStyle(PinguDesign.body)
                .lineSpacing(3)

            Text("Try one next")
                .font(PinguFont.caption)
                .foregroundStyle(PinguDesign.muted)
                .padding(.top, 2)

            VStack(spacing: 9) {
                ForEach(output.replyOptions) { option in
                    TipsReplyOptionCard(
                        option: option,
                        onUse: { viewModel.useReplyOption(option) },
                        onCopy: { UIPasteboard.general.string = option.text }
                    )
                }
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [.white, PinguDesign.lightBlue.opacity(0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(PinguDesign.border, lineWidth: 1)
        }
    }

    private var composer: some View {
        VStack(spacing: 10) {
            if let data = viewModel.replyImageData {
                HStack {
                    TipsImagePreview(data: data) {
                        selectedReplyItem = nil
                        viewModel.attachReplyImage(nil)
                    }
                    Spacer()
                }
                .padding(.horizontal, PinguDesign.screenSidePadding)
            }

            HStack(spacing: 8) {
                Button {
                    viewModel.toggleVoice(for: .reply)
                } label: {
                    Image(systemName: viewModel.isReplyVoiceActive ? "stop.circle.fill" : "mic.fill")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(viewModel.isReplyVoiceActive ? PinguDesign.orange : PinguDesign.blue)
                        .frame(width: 40, height: 40)
                        .background(PinguDesign.lightBlue.opacity(0.65))
                        .clipShape(Circle())
                }

                PhotosPicker(selection: $selectedReplyItem, matching: .images) {
                    Image(systemName: "photo")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(PinguDesign.blue)
                        .frame(width: 40, height: 40)
                        .background(PinguDesign.lightBlue.opacity(0.65))
                        .clipShape(Circle())
                }

                TextField("Paste their reply...", text: $viewModel.replyInput, axis: .vertical)
                    .font(PinguFont.body)
                    .lineLimit(1...3)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 40)
                    .background(PinguDesign.lightBlue.opacity(0.36))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                Button {
                    viewModel.submitReply()
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(viewModel.canSendReply ? PinguDesign.blue : PinguDesign.muted.opacity(0.55))
                        .clipShape(Circle())
                }
                .disabled(!viewModel.canSendReply)
            }

            TextField("Add context...", text: $viewModel.extraContextInput)
                .font(PinguFont.caption)
                .padding(.horizontal, 12)
                .frame(height: 34)
                .background(.white)
                .clipShape(Capsule())

            if let hint = viewModel.inputHint ?? viewModel.speechRecognizer.errorMessage {
                Text(hint)
                    .font(PinguFont.caption)
                    .foregroundStyle(PinguDesign.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, PinguDesign.screenSidePadding)
        .padding(.top, 12)
        .background(.white.opacity(0.96))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(PinguDesign.border.opacity(0.55))
                .frame(height: 1)
        }
    }
}
