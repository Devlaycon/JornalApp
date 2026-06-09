import SwiftUI

struct PinguOnboardingView: View {
    @EnvironmentObject private var profileStore: UserProfileStore
    let onContinue: () -> Void
    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                PinguDesign.deepBlue.ignoresSafeArea()

                Image("PinguHero")
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .opacity(0.82)
                    .ignoresSafeArea()

                LinearGradient(
                    colors: [
                        .black.opacity(0.14),
                        PinguDesign.deepBlue.opacity(0.34),
                        PinguDesign.deepBlue.opacity(0.96)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    topBar
                        .padding(.top, max(16, proxy.safeAreaInsets.top + 4))

                    Spacer(minLength: max(48, proxy.size.height * 0.18))

                    VStack(spacing: 24) {
                        TabView(selection: $viewModel.selectedPage) {
                            ForEach(viewModel.pages.indices, id: \.self) { index in
                                onboardingPage(viewModel.pages[index])
                                    .tag(index)
                                    .padding(.horizontal, 28)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .frame(height: min(390, max(340, proxy.size.height * 0.46)))

                        pagerDots

                        VStack(spacing: 13) {
                            Button {
                                advance()
                            } label: {
                                Label(viewModel.primaryButtonTitle, systemImage: viewModel.primaryButtonIcon)
                            }
                            .buttonStyle(PinguPrimaryButtonStyle())

                            Button {
                                completeOnboarding()
                            } label: {
                                Text(viewModel.selectedPage == viewModel.pages.indices.last ? "Maybe Later" : "Skip")
                            }
                            .buttonStyle(PinguSecondaryButtonStyle())
                        }
                        .padding(.horizontal, 28)
                    }
                    .padding(.bottom, max(30, proxy.safeAreaInsets.bottom + 22))
                }
            }
        }
    }

    private var topBar: some View {
        HStack {
            Text("Circleu")
                .font(PinguFont.sectionTitle)
                .foregroundStyle(.white)

            Spacer()

            Button("Skip") {
                completeOnboarding()
            }
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundStyle(.white.opacity(0.88))
        }
        .padding(.horizontal, 26)
        .frame(height: 52)
    }

    private func onboardingPage(_ page: PinguOnboardingPage) -> some View {
        VStack(spacing: 18) {
            trustPill

            Image(systemName: page.icon)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 66, height: 66)
                .background(.white.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 19, style: .continuous)
                        .stroke(.white.opacity(0.22), lineWidth: 1)
                }

            VStack(spacing: 14) {
                Text(page.title)
                    .font(PinguFont.hero)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .minimumScaleFactor(0.82)
                    .fixedSize(horizontal: false, vertical: true)

                Text(page.subtitle)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.86))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .frame(maxWidth: 336)
                    .fixedSize(horizontal: false, vertical: true)

                if page == viewModel.pages.last {
                    nameInput
                        .padding(.top, 2)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }

    private var trustPill: some View {
        Label("Private local reflections", systemImage: "lock.fill")
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .frame(height: 34)
            .background(.white.opacity(0.16))
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(.white.opacity(0.22), lineWidth: 1)
            }
    }

    private var nameInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What should Circleu call you?")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.92))

            TextField("Your name", text: $viewModel.draftName)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(PinguDesign.ink)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .padding(.horizontal, 16)
                .frame(height: 54)
                .pinguGlass(cornerRadius: 18, tint: 0.18)

            Text("This stays on this iPhone and helps Circleu greet you naturally.")
                .font(PinguFont.caption)
                .foregroundStyle(.white.opacity(0.78))
                .lineSpacing(3)
        }
        .frame(maxWidth: 336, alignment: .leading)
    }

    private var pagerDots: some View {
        HStack(spacing: 8) {
            ForEach(viewModel.pages.indices, id: \.self) { index in
                Capsule()
                    .fill(index == viewModel.selectedPage ? .white : .white.opacity(0.34))
                    .frame(width: index == viewModel.selectedPage ? 28 : 8, height: 8)
                    .animation(.spring(response: 0.28, dampingFraction: 0.82), value: viewModel.selectedPage)
            }
        }
        .padding(.vertical, 2)
    }

    private func advance() {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.84)) {
            viewModel.advance(profileStore: profileStore, onContinue: onContinue)
        }
    }

    private func completeOnboarding() {
        viewModel.completeOnboarding(profileStore: profileStore, onContinue: onContinue)
    }
}

struct PinguOnboardingPage: Equatable {
    let icon: String
    let title: String
    let subtitle: String

    static let allPages = [
        PinguOnboardingPage(
            icon: "lock.fill",
            title: "Private daily reflection",
            subtitle: "A calm local space to understand your day without turning every thought into an account or feed."
        ),
        PinguOnboardingPage(
            icon: "waveform",
            title: "Speak or type honestly",
            subtitle: "Record when voice feels natural, or type when microphone and speech recognition are not ready."
        ),
        PinguOnboardingPage(
            icon: "sparkles",
            title: "Turn insight into tips",
            subtitle: "Circleu turns each reflection into a journal insight and one small action you can complete today."
        ),
        PinguOnboardingPage(
            icon: "person.crop.circle.fill",
            title: "Make it yours",
            subtitle: "Add your name so Circleu can guide your daily reflection flow in a warmer, more personal way."
        )
    ]
}

#Preview {
    PinguOnboardingView {}
        .environmentObject(UserProfileStore())
}
