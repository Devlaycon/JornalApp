import SwiftUI

/// Quick tour shown the first time a freshly registered user lands on the app.
/// Driven by the `showWelcomeHints` UserDefaults flag set after a successful signup.
struct WelcomeHintsOverlay: View {
    let onDismiss: () -> Void

    @State private var index = 0

    private let hints: [Hint] = [
        Hint(
            icon: "mic.fill",
            tint: Pingu.accent,
            title: "Reflect with your voice",
            body: "Tap the record button on Home to talk through your day. Pingu turns it into a gentle reflection."
        ),
        Hint(
            icon: "book.fill",
            tint: Pingu.violet,
            title: "Journal stays private",
            body: "Every reflection is saved locally on your device. Open Journal to revisit anything you've recorded."
        ),
        Hint(
            icon: "bubble.left.and.bubble.right.fill",
            tint: Pingu.cyan,
            title: "Practise conversations",
            body: "Tips coaches you through tough conversations — work, family, friends — at your own pace."
        ),
        Hint(
            icon: "person.2.wave.2.fill",
            tint: Pingu.green,
            title: "Share when you're ready",
            body: "Found a reflection worth sharing? Open it from Journal and tap Share to a circle — anonymously."
        )
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { /* swallow taps */ }

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                card
                    .padding(.horizontal, 24)

                Spacer(minLength: 0)
            }
        }
        .transition(.opacity)
    }

    private var card: some View {
        GlassCard(style: .strong, cornerRadius: 28) {
            VStack(spacing: 18) {
                let hint = hints[index]

                ZStack {
                    Circle()
                        .fill(hint.tint.opacity(0.16))
                        .frame(width: 76, height: 76)
                    Image(systemName: hint.icon)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(hint.tint)
                }
                .padding(.top, 8)

                VStack(spacing: 10) {
                    Text(hint.title)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Pingu.ink)
                        .multilineTextAlignment(.center)

                    Text(hint.body)
                        .font(.system(size: 13.5, weight: .regular, design: .rounded))
                        .foregroundStyle(Pingu.slate)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .frame(maxWidth: 280)
                }

                HStack(spacing: 6) {
                    ForEach(0..<hints.count, id: \.self) { dot in
                        Capsule()
                            .fill(dot == index ? hints[index].tint : Pingu.muted.opacity(0.3))
                            .frame(width: dot == index ? 22 : 7, height: 7)
                            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: index)
                    }
                }
                .padding(.top, 4)

                HStack(spacing: 10) {
                    Button {
                        onDismiss()
                    } label: {
                        Text("Skip")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(Pingu.slate)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .glass(.pill, cornerRadius: 14)
                    }
                    .buttonStyle(PressableButtonStyle())

                    Button {
                        if index == hints.count - 1 {
                            onDismiss()
                        } else {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.86)) {
                                index += 1
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(index == hints.count - 1 ? "Got it" : "Next")
                            Image(systemName: index == hints.count - 1 ? "checkmark" : "chevron.right")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(GlassPrimaryFill(cornerRadius: 14))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(PressableButtonStyle())
                }
                .padding(.top, 4)
            }
            .padding(24)
        }
    }
}

private struct Hint {
    let icon: String
    let tint: Color
    let title: String
    let body: String
}

#Preview {
    ZStack {
        PinguAurora()
        WelcomeHintsOverlay(onDismiss: {})
    }
}
