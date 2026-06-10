import SwiftUI

struct PinguOnboardingView: View {
    @EnvironmentObject private var profileStore: UserProfileStore
    @EnvironmentObject private var authStore: AuthStore
    @EnvironmentObject private var backendSessionStore: BackendSessionStore
    let onContinue: () -> Void
    @StateObject private var viewModel = OnboardingViewModel()

    private static let dark = Color(hex: 0x0B1220)
    private static let mutedText = Color(hex: 0x94A3B8)
    private static let dimText = Color(hex: 0x64748B)
    private static let link = Color(hex: 0x7C9DFF)

    var body: some View {
        ZStack {
            background

            switch viewModel.stage {
            case .welcome:
                welcome
                    .transition(.opacity)
            case .signup:
                signup
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .signin:
                signin
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.86), value: viewModel.stage)
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            Self.dark.ignoresSafeArea()

            LinearGradient(
                colors: [Color(hex: 0x111A2E), Self.dark, Color(hex: 0x0B1326)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            GeometryReader { geo in
                let w = geo.size.width
                ZStack {
                    Circle()
                        .fill(Color(hex: 0x3B82F6).opacity(0.25))
                        .frame(width: 260).blur(radius: 80)
                        .offset(x: 0, y: -geo.size.height * 0.42)
                    Circle()
                        .fill(Color(hex: 0x6366F1).opacity(0.25))
                        .frame(width: 200).blur(radius: 80)
                        .offset(x: w * 0.4, y: geo.size.height * 0.28)
                }
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Welcome

    private var welcome: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Skip") {
                    viewModel.skip(profileStore: profileStore, onContinue: onContinue)
                }
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Self.mutedText)
            }
            .padding(.horizontal, 28)
            .padding(.top, 58)

            Spacer()

            VStack(spacing: 0) {
                PinguMascot(size: 172, mood: .celebrate, ring: true)

                Text("A digital embrace\nfor your growth")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.top, 32)

                Text("Reflect, find calm, and grow gently — with Pingu by your side every day.")
                    .font(.system(size: 14.5, weight: .regular, design: .rounded))
                    .foregroundStyle(Self.mutedText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .frame(maxWidth: 280)
                    .padding(.top, 16)
            }

            Spacer()

            HStack(spacing: 8) {
                Capsule().fill(Color(hex: 0x60A5FA)).frame(width: 24, height: 8)
                Circle().fill(.white.opacity(0.2)).frame(width: 8, height: 8)
                Circle().fill(.white.opacity(0.2)).frame(width: 8, height: 8)
            }
            .padding(.bottom, 28)

            VStack(spacing: 16) {
                Button {
                    viewModel.go(to: .signup)
                } label: {
                    HStack(spacing: 8) {
                        Text("Get Started")
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                .buttonStyle(OnbPrimaryButtonStyle())

                Button {
                    viewModel.go(to: .signin)
                } label: {
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .foregroundStyle(Self.mutedText)
                        Text("Log in")
                            .foregroundStyle(Self.link)
                            .fontWeight(.bold)
                    }
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Signup

    private var signup: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    PinguMascot(size: 84, mood: .idle)
                        .padding(.bottom, 20)

                    Text("Create Your Space")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("A private corner that grows with you.")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(Self.mutedText)
                        .padding(.top, 8)
                        .padding(.bottom, 32)

                    OnbField(icon: "person", placeholder: "Display Name", text: $viewModel.name)
                    OnbField(icon: "envelope", placeholder: "Email", text: $viewModel.email, keyboard: .emailAddress)
                    OnbField(icon: "lock", placeholder: "Password", text: $viewModel.password, secure: true)

                    errorBanner

                    Button {
                        Task {
                            await viewModel.signUp(
                                authStore: authStore,
                                profileStore: profileStore,
                                backendSessionStore: backendSessionStore,
                                onContinue: onContinue
                            )
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if viewModel.isSubmitting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Create Account")
                                Image(systemName: "chevron.right").font(.system(size: 16, weight: .bold))
                            }
                        }
                    }
                    .buttonStyle(OnbPrimaryButtonStyle(enabled: viewModel.canSubmitSignup))
                    .disabled(!viewModel.canSubmitSignup)
                    .padding(.top, 12)

                    termsText
                        .padding(.top, 20)
                }
                .padding(.horizontal, 32)
                .padding(.top, 80)
            }

            Button {
                viewModel.go(to: .signin)
            } label: {
                HStack(spacing: 4) {
                    Text("Already have an account?").foregroundStyle(Self.mutedText)
                    Text("Sign in").foregroundStyle(Self.link).fontWeight(.bold)
                }
                .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Signin

    private var signin: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    PinguMascot(size: 84, mood: .idle)
                        .padding(.bottom, 20)

                    Text("Welcome Back")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Pingu missed you. Let's pick up where you left off.")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(Self.mutedText)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                        .padding(.bottom, 32)

                    OnbField(icon: "envelope", placeholder: "Email", text: $viewModel.email, keyboard: .emailAddress)
                    OnbField(icon: "lock", placeholder: "Password", text: $viewModel.password, secure: true)

                    errorBanner

                    Button {
                        Task {
                            await viewModel.signIn(
                                authStore: authStore,
                                profileStore: profileStore,
                                backendSessionStore: backendSessionStore,
                                onContinue: onContinue
                            )
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if viewModel.isSubmitting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Sign In")
                                Image(systemName: "chevron.right").font(.system(size: 16, weight: .bold))
                            }
                        }
                    }
                    .buttonStyle(OnbPrimaryButtonStyle())
                    .disabled(viewModel.isSubmitting)
                    .padding(.top, 12)
                }
                .padding(.horizontal, 32)
                .padding(.top, 80)
            }

            Button {
                viewModel.go(to: .signup)
            } label: {
                HStack(spacing: 4) {
                    Text("New here?").foregroundStyle(Self.mutedText)
                    Text("Create Account").foregroundStyle(Self.link).fontWeight(.bold)
                }
                .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Shared bits

    @ViewBuilder
    private var errorBanner: some View {
        if let message = viewModel.errorMessage {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12, weight: .bold))
                Text(message)
                    .font(.system(size: 12.5, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(Color(hex: 0xFCA5A5))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(hex: 0xEF4444).opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.top, 10)
        }
    }

    private var termsText: some View {
        Text("By continuing you agree to our Terms & Privacy Policy. Your reflections stay on your device.")
            .font(.system(size: 11.5, weight: .regular, design: .rounded))
            .foregroundStyle(Self.dimText)
            .multilineTextAlignment(.center)
            .lineSpacing(3)
            .padding(.horizontal, 8)
    }
}

// MARK: - Onboarding field

private struct OnbField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var secure: Bool = false
    var keyboard: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Color(hex: 0x64748B))
                .frame(width: 20)

            Group {
                if secure {
                    SecureField("", text: $text, prompt: prompt)
                } else {
                    TextField("", text: $text, prompt: prompt)
                        .keyboardType(keyboard)
                        .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
                        .autocorrectionDisabled()
                }
            }
            .font(.system(size: 15, weight: .medium, design: .rounded))
            .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(Color.white.opacity(0.06))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.bottom, 14)
    }

    private var prompt: Text {
        Text(placeholder).foregroundColor(Color(hex: 0x64748B))
    }
}

// MARK: - Onboarding primary button

private struct OnbPrimaryButtonStyle: ButtonStyle {
    var enabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundStyle(enabled ? .white : Color(hex: 0x64748B))
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background {
                if enabled {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: 0x3B82F6), Color(hex: 0x6366F1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color(hex: 0x3B82F6).opacity(0.4), radius: 14, y: 8)
                } else {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.white.opacity(0.1))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .scaleEffect(configuration.isPressed && enabled ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

#Preview {
    PinguOnboardingView {}
        .environmentObject(UserProfileStore())
        .environmentObject(AuthStore())
        .environmentObject(BackendSessionStore(authenticator: NoOpFirebaseAuthenticator(), syncer: NoOpReflectionSyncer()))
}
