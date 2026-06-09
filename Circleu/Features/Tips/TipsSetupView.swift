import PhotosUI
import SwiftUI

struct TipsSetupView: View {
    @ObservedObject var viewModel: TipsPracticeViewModel
    let recentSessions: [TipsPracticeSession]
    let reflectionHistory: AnyView
    @State private var selectedMessageItem: PhotosPickerItem?

    var body: some View {
        VStack(spacing: 0) {
            DemoNavBar(title: "New tip") {
                Image(systemName: "clock")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(Pingu.slate)
            }

            ZStack(alignment: .bottom) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        messageCard
                        sceneSection
                        toneSection
                        situationSection
                    }
                    .padding(.horizontal, PinguDesign.screenSidePadding)
                    .padding(.top, 12)
                    .padding(.bottom, PinguDesign.bottomBarHeight + 106)
                }

                continueButton
            }
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
        VStack(spacing: 0) {
            PinguMascot(size: 92, mood: .think)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 16)

            VStack(alignment: .leading, spacing: 8) {
                Kicker("STEP 01 · DESCRIBE")

                Text("What do you want to say?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Pingu.ink)
                    .lineSpacing(2)

                Text("Tell me the message in your own words. The scene comes next.")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(Pingu.slate)
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
            .glass(.strong, cornerRadius: 18)
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
        .glass(.strong, cornerRadius: 18)
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
            .glass(.regular, cornerRadius: 18)
        }
    }

    private var continueButton: some View {
        PinguGlassButton(
            enabled: viewModel.canContinue,
            action: { viewModel.startCoach() }
        ) {
            HStack(spacing: 8) {
                Text("Continue")
                ZStack {
                    Circle().fill(.white).frame(width: 24, height: 24)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Pingu.accent)
                }
            }
        }
        .padding(.horizontal, PinguDesign.screenSidePadding)
        .padding(.bottom, PinguDesign.bottomBarHeight + 16)
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
