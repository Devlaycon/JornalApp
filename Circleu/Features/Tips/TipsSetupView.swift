import PhotosUI
import SwiftUI

struct TipsSetupView: View {
    @ObservedObject var viewModel: TipsPracticeViewModel
    let recentSessions: [TipsPracticeSession]
    let reflectionHistory: AnyView
    @State private var selectedMessageItem: PhotosPickerItem?

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    if !recentSessions.isEmpty {
                        TipsPracticeHistorySection(
                            sessions: recentSessions,
                            onResume: { session in
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                                    viewModel.resume(session)
                                }
                            },
                            onDelete: { session in
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                                    viewModel.delete(session)
                                }
                            }
                        )
                    }
                    messageCard
                    sceneSection
                    toneSection
                    situationSection
                    reflectionHistory
                }
                .padding(.horizontal, PinguDesign.screenSidePadding)
                .padding(.top, 18)
                .padding(.bottom, PinguDesign.bottomBarHeight + 106)
            }

            continueButton
        }
        .sheet(isPresented: $viewModel.showCustomSceneSheet) {
            customSceneSheet
                .presentationDetents([.height(260)])
        }
        .onChange(of: selectedMessageItem) { _, newItem in
            Task {
                guard let data = try? await newItem?.loadTransferable(type: Data.self) else { return }
                await MainActor.run {
                    viewModel.attachMessageImage(data)
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 13) {
            HStack {
                Spacer()
                Text("New Tip")
                    .font(PinguFont.cardTitle)
                    .foregroundStyle(PinguDesign.ink)
                Spacer()
            }

            PinguAvatar(size: 92)
                .shadow(color: PinguDesign.deepBlue.opacity(0.10), radius: 16, y: 8)

            VStack(alignment: .leading, spacing: 10) {
                Text("STEP 01 · DESCRIBE")
                    .font(PinguFont.tiny)
                    .tracking(1.3)
                    .foregroundStyle(PinguDesign.blue)

                Text("What do you want to say?")
                    .font(PinguFont.hero)
                    .foregroundStyle(PinguDesign.ink)
                    .lineSpacing(2)

                Text("Tell us the message in your own words.")
                    .font(PinguFont.body)
                    .foregroundStyle(PinguDesign.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var messageCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            TipsSectionLabel(number: "①", title: "Your message", note: "in your own words")

            VStack(alignment: .leading, spacing: 10) {
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $viewModel.message)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundStyle(PinguDesign.ink)
                        .frame(minHeight: 112)
                        .scrollContentBackground(.hidden)
                        .onChange(of: viewModel.message) { _, newValue in
                            if newValue.count > 240 {
                                viewModel.message = String(newValue.prefix(240))
                            }
                            viewModel.persistDraft()
                        }

                    if viewModel.message.isEmpty {
                        Text("Type your message here...")
                            .font(.system(size: 15, weight: .regular, design: .rounded))
                            .foregroundStyle(PinguDesign.muted.opacity(0.55))
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }
                }

                if let data = viewModel.messageImageData {
                    TipsImagePreview(data: data) {
                        selectedMessageItem = nil
                        viewModel.attachMessageImage(nil)
                    }
                }

                Divider()
                    .overlay(PinguDesign.border.opacity(0.7))

                HStack(spacing: 16) {
                    Button {
                        viewModel.toggleVoice(for: .message)
                    } label: {
                        Image(systemName: viewModel.isMessageVoiceActive ? "stop.circle.fill" : "mic")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(viewModel.isMessageVoiceActive ? PinguDesign.orange : PinguDesign.muted)
                    }
                    .accessibilityLabel(viewModel.voiceButtonTitle)

                    PhotosPicker(selection: $selectedMessageItem, matching: .images) {
                        Image(systemName: "camera")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(PinguDesign.muted)
                    }

                    Spacer()

                    Text("\(viewModel.characterCount) / 240")
                        .font(PinguFont.caption)
                        .foregroundStyle(viewModel.characterCount > 210 ? PinguDesign.orange : PinguDesign.muted)
                }

                if let hint = viewModel.inputHint ?? viewModel.speechRecognizer.errorMessage {
                    Text(hint)
                        .font(PinguFont.caption)
                        .foregroundStyle(PinguDesign.orange)
                }
            }
            .padding(16)
            .pinguGlass(cornerRadius: 18, tint: 0.18)
        }
    }

    private var sceneSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            TipsSectionLabel(number: "②", title: "Choose a scene", note: "pick one")

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 10)], alignment: .leading, spacing: 10) {
                ForEach([TipsPracticeScene.workplace, .family, .friendship, .romantic], id: \.self) { scene in
                    TipsSceneChip(
                        scene: scene,
                        title: scene.title,
                        isSelected: viewModel.scene == scene
                    ) {
                        viewModel.selectScene(scene)
                    }
                }

                TipsSceneChip(
                    scene: .custom,
                    title: viewModel.scene == .custom ? viewModel.sceneTitle : "Add specific",
                    isSelected: viewModel.scene == .custom
                ) {
                    viewModel.selectScene(.custom)
                }
            }
        }
    }

    private var toneSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Desired tone")
                    .font(PinguFont.caption)
                    .foregroundStyle(PinguDesign.ink)
                Spacer()
                Text(viewModel.tone.title)
                    .font(PinguFont.button)
                    .foregroundStyle(PinguDesign.blue)
            }

            Slider(value: $viewModel.toneValue, in: 0...1)
                .tint(PinguDesign.blue)
                .onChange(of: viewModel.toneValue) { _, _ in
                    viewModel.persistDraft()
                }

            HStack {
                Text("SOFT")
                Spacer()
                Text("DIRECT")
                Spacer()
                Text("FIRM")
            }
            .font(PinguFont.tiny)
            .foregroundStyle(PinguDesign.muted)
        }
        .padding(18)
        .pinguGlass(cornerRadius: 18, tint: 0.22)
    }

    private var situationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            TipsSectionLabel(number: "③", title: "Situation", note: "optional · context helps")

            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.situation)
                    .font(PinguFont.bodyLight)
                    .foregroundStyle(PinguDesign.ink)
                    .frame(minHeight: 92)
                    .scrollContentBackground(.hidden)
                    .onChange(of: viewModel.situation) { _, _ in
                        viewModel.persistDraft()
                    }

                if viewModel.situation.isEmpty {
                    Text("e.g. My manager already gave me three deadlines this week.")
                        .font(PinguFont.bodyLight)
                        .foregroundStyle(PinguDesign.muted.opacity(0.68))
                        .padding(.top, 8)
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
                }
            }
            .padding(14)
            .pinguGlass(cornerRadius: 18, tint: 0.18)
        }
    }

    private var continueButton: some View {
        VStack {
            Button {
                viewModel.startCoach()
            } label: {
                HStack(spacing: 8) {
                    Text("Continue")
                    Image(systemName: "chevron.right.circle.fill")
                }
            }
            .buttonStyle(PinguPrimaryButtonStyle())
            .disabled(!viewModel.canContinue)
            .opacity(viewModel.canContinue ? 1 : 0.45)
        }
        .padding(.horizontal, PinguDesign.screenSidePadding)
        .padding(.top, 18)
        .padding(.bottom, PinguDesign.bottomBarHeight + 10)
        .background(
            LinearGradient(
                colors: [PinguDesign.ice.opacity(0), PinguDesign.ice, PinguDesign.ice],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var customSceneSheet: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Add custom scene")
                .font(PinguFont.sectionTitle)
                .foregroundStyle(PinguDesign.ink)

            TextField("School, client, teammate...", text: $viewModel.customSceneDraft)
                .font(PinguFont.body)
                .padding(14)
                .background(PinguDesign.lightBlue.opacity(0.42))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            HStack(spacing: 10) {
                Button("Cancel") {
                    viewModel.showCustomSceneSheet = false
                }
                .buttonStyle(PinguSecondaryButtonStyle())

                Button("Add") {
                    viewModel.saveCustomScene()
                }
                .buttonStyle(PinguPrimaryButtonStyle())
                .disabled(viewModel.customSceneDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(22)
    }
}
