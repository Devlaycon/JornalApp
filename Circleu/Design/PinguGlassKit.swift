import SwiftUI

// ============================================================
// PinguGlassKit — a 1:1 SwiftUI rendition of the web demo's
// "Liquid Glass" design system (lg-* classes + shared chrome).
// Screens compose these primitives to match the demo exactly.
// ============================================================

// MARK: - Color tokens (from the demo's theme.css / Tailwind palette)

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

enum Pingu {
    // text
    static let ink = Color(hex: 0x1E293B)        // slate-800 — primary text
    static let slate = Color(hex: 0x64748B)      // slate-500 — secondary text
    static let body = Color(hex: 0x475569)       // slate-600 — body copy
    static let muted = Color(hex: 0x94A3B8)      // slate-400 — muted / meta
    // brand
    static let accent = Color(hex: 0x2563EB)     // blue-600
    static let accentSoft = Color(hex: 0x3B82F6) // blue-500
    static let blueLight = Color(hex: 0x60A5FA)  // blue-400
    static let deepBlue = Color(hex: 0x1E3A8A)   // blue-900 (shadows)
    // accents
    static let amber = Color(hex: 0xF59E0B)
    static let green = Color(hex: 0x16A34A)
    static let pink = Color(hex: 0xEC4899)
    static let red = Color(hex: 0xEF4444)
    static let violet = Color(hex: 0x8B5CF6)
    static let cyan = Color(hex: 0x0891B2)

    static let font = Font.system(size: 15, weight: .semibold, design: .rounded)
}

// MARK: - Aurora background (lg-aurora)

/// Light aurora gradient that sits behind every glass surface.
struct PinguAurora: View {
    var body: some View {
        Color(hex: 0xDBEAFE)
            .overlay {
                LinearGradient(
                    colors: [Color(hex: 0xEFF6FF), Color(hex: 0xDBEAFE), Color(hex: 0xE0E7FF)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .overlay {
                GeometryReader { geo in
                    let w = geo.size.width
                    ZStack {
                        Circle().fill(Color(hex: 0x93C5FD).opacity(0.55))
                            .frame(width: w * 1.1).blur(radius: 110)
                            .offset(x: -w * 0.34, y: -w * 0.5)
                        Circle().fill(Color(hex: 0xC4B5FD).opacity(0.48))
                            .frame(width: w * 1.0).blur(radius: 120)
                            .offset(x: w * 0.42, y: -w * 0.42)
                        Circle().fill(Color(hex: 0x7DD3FC).opacity(0.45))
                            .frame(width: w * 1.2).blur(radius: 130)
                            .offset(x: 0, y: w * 0.95)
                    }
                }
            }
            .clipped()
            .ignoresSafeArea()
    }
}

// MARK: - Glass surfaces (lg-glass / -strong / -nav / -primary / -pill)

enum GlassStyle {
    case regular   // lg-glass
    case strong    // lg-glass-strong
    case nav       // lg-glass-nav
    case pill      // lg-glass-pill

    var tint: Double {
        switch self {
        case .regular: 0.22
        case .strong: 0.40
        case .nav: 0.38
        case .pill: 0.28
        }
    }
    var borderTop: Double {
        switch self {
        case .regular: 0.55
        case .strong: 0.70
        case .nav: 0.62
        case .pill: 0.62
        }
    }
    var borderBottom: Double {
        switch self {
        case .regular: 0.22
        case .strong: 0.30
        case .nav: 0.28
        case .pill: 0.30
        }
    }
    var hasShadow: Bool { self != .pill }
    var shadowOpacity: Double { self == .strong ? 0.12 : 0.10 }
}

struct GlassSurface: ViewModifier {
    var style: GlassStyle = .regular
    var cornerRadius: CGFloat = 24

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return content
            .background {
                ZStack {
                    shape.fill(.ultraThinMaterial)
                    shape.fill(.white.opacity(style.tint))
                }
            }
            .overlay {
                shape.strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(style.borderTop), .white.opacity(style.borderBottom)],
                        startPoint: .top, endPoint: .bottom
                    ),
                    lineWidth: 1
                )
            }
            .clipShape(shape)
            .shadow(
                color: style.hasShadow ? Pingu.deepBlue.opacity(style.shadowOpacity) : .clear,
                radius: style.hasShadow ? 16 : 0, x: 0, y: style.hasShadow ? 10 : 0
            )
    }
}

extension View {
    func glass(_ style: GlassStyle = .regular, cornerRadius: CGFloat = 24) -> some View {
        modifier(GlassSurface(style: style, cornerRadius: cornerRadius))
    }
}

/// The translucent blue fill used on primary buttons / active chips (lg-glass-primary).
struct GlassPrimaryFill: View {
    var cornerRadius: CGFloat = 18
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [Pingu.accentSoft.opacity(0.92), Pingu.accent.opacity(0.92)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.45), lineWidth: 1)
            }
            .shadow(color: Pingu.accent.opacity(0.32), radius: 12, x: 0, y: 8)
    }
}

// MARK: - Glass card container (GlassCard)

struct GlassCard<Content: View>: View {
    var style: GlassStyle = .regular
    var cornerRadius: CGFloat = 24
    var sheen: Bool = false
    @ViewBuilder var content: Content

    var body: some View {
        content
            .glass(style, cornerRadius: cornerRadius)
            .overlay {
                if sheen {
                    GlassSheen()
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                        .allowsHitTesting(false)
                }
            }
    }
}

/// Slow specular sheen sweeping across a glass surface (lg-sheen).
struct GlassSheen: View {
    @State private var phase: CGFloat = -1
    var body: some View {
        GeometryReader { geo in
            LinearGradient(
                colors: [.clear, .white.opacity(0.45), .clear],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .frame(width: geo.size.width * 1.4)
            .offset(x: phase * geo.size.width * 1.6)
            .onAppear {
                withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: false)) {
                    phase = 1.2
                }
            }
        }
    }
}

// MARK: - Kicker (STEP 01 · DESCRIBE style label)

struct Kicker: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10.5, weight: .bold, design: .rounded))
            .tracking(1.8)
            .foregroundStyle(Pingu.accent)
    }
}

// MARK: - Glass pill chip (GlassPill)

struct GlassPill: View {
    let title: String
    var active: Bool = false
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(active ? .white : Pingu.ink)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background {
                    if active {
                        Capsule().fill(
                            LinearGradient(colors: [Pingu.accentSoft.opacity(0.92), Pingu.accent.opacity(0.92)],
                                           startPoint: .top, endPoint: .bottom)
                        )
                        .overlay { Capsule().strokeBorder(.white.opacity(0.45), lineWidth: 1) }
                        .shadow(color: Pingu.accent.opacity(0.32), radius: 10, y: 6)
                    } else {
                        Capsule().fill(.ultraThinMaterial)
                            .overlay { Capsule().fill(.white.opacity(0.28)) }
                            .overlay { Capsule().strokeBorder(.white.opacity(0.55), lineWidth: 1) }
                    }
                }
                .clipShape(Capsule())
                .scaleEffect(active ? 1.03 : 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Primary glass button (PrimaryButton)

struct PinguGlassButton<Label: View>: View {
    var enabled: Bool = true
    var cornerRadius: CGFloat = 18
    var action: () -> Void
    @ViewBuilder var label: Label

    var body: some View {
        Button(action: { if enabled { action() } }) {
            label
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(enabled ? .white : Pingu.muted)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background {
                    if enabled {
                        GlassPrimaryFill(cornerRadius: cornerRadius)
                    } else {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Color(hex: 0xCBD5E1))
                    }
                }
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!enabled)
    }
}

/// Soft glass secondary button (lg-glass-pill, full width).
struct PinguGlassPillButton<Label: View>: View {
    var height: CGFloat = 48
    var cornerRadius: CGFloat = 16
    var action: () -> Void
    @ViewBuilder var label: Label

    var body: some View {
        Button(action: action) {
            label
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Pingu.ink)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .glass(.pill, cornerRadius: cornerRadius)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - In-phone nav bar (NavBar — centered title, blue chevron back)

struct DemoNavBar<Trailing: View>: View {
    let title: String
    var subtitle: String? = nil
    var onBack: (() -> Void)? = nil
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack {
            ZStack {
                if let onBack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Pingu.accent)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
            }
            .frame(width: 40, alignment: .leading)

            Spacer(minLength: 0)
            VStack(spacing: 1) {
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Pingu.ink)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Pingu.accent)
                }
            }
            Spacer(minLength: 0)

            HStack { trailing }.frame(width: 40, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
    }
}

extension DemoNavBar where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil, onBack: (() -> Void)? = nil) {
        self.init(title: title, subtitle: subtitle, onBack: onBack) { EmptyView() }
    }
}

// MARK: - Emotion meta (mirrors the demo's EMOTION_META map)

struct PinguEmotionMeta {
    let color: Color
    let bg: Color
    let emoji: String

    static func of(_ emotion: String?) -> PinguEmotionMeta {
        switch emotion {
        case "Brave":     return .init(color: Color(hex: 0x2563EB), bg: Color(hex: 0x2563EB).opacity(0.12), emoji: "🛡️")
        case "Proud":     return .init(color: Color(hex: 0xF59E0B), bg: Color(hex: 0xF59E0B).opacity(0.14), emoji: "✨")
        case "Resilient": return .init(color: Color(hex: 0x0891B2), bg: Color(hex: 0x0891B2).opacity(0.12), emoji: "🌊")
        case "Tender":    return .init(color: Color(hex: 0xDB2777), bg: Color(hex: 0xDB2777).opacity(0.12), emoji: "🤍")
        case "Calm":      return .init(color: Color(hex: 0x16A34A), bg: Color(hex: 0x16A34A).opacity(0.12), emoji: "🍃")
        default:          return .init(color: Pingu.accent, bg: Pingu.accent.opacity(0.12), emoji: "🐧")
        }
    }
}

// MARK: - Pingu mascot with mood animations

enum PinguMood { case idle, think, celebrate, pop }

struct PinguMascot: View {
    var size: CGFloat = 100
    var mood: PinguMood = .idle
    var ring: Bool = false

    @State private var bob = false
    @State private var think = false
    @State private var celebrate = false
    @State private var pop = false
    @State private var ringPulse = false

    var body: some View {
        ZStack {
            if ring {
                Circle().stroke(Pingu.accent.opacity(0.25), lineWidth: 2)
                    .frame(width: size * 0.9, height: size * 0.9)
                    .scaleEffect(ringPulse ? 1.5 : 0.9)
                    .opacity(ringPulse ? 0 : 0.7)
                Circle().stroke(Pingu.blueLight.opacity(0.25), lineWidth: 2)
                    .frame(width: size * 0.9, height: size * 0.9)
                    .scaleEffect(ringPulse ? 1.5 : 0.9)
                    .opacity(ringPulse ? 0 : 0.7)
            }
            // soft glow disc
            Circle()
                .fill(
                    RadialGradient(colors: [Color(hex: 0x93C5FD).opacity(0.7), .clear],
                                   center: .center, startRadius: 0, endRadius: size * 0.4)
                )
                .frame(width: size * 0.85, height: size * 0.85)
                .blur(radius: 12)

            Image("PinguMascot")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .shadow(color: Pingu.deepBlue.opacity(0.18), radius: 10, y: 6)
                .rotationEffect(.degrees(rotation))
                .offset(y: bobOffset)
                .scaleEffect(scale)
        }
        .frame(width: size, height: size)
        .onAppear { startAnimations() }
    }

    private var rotation: Double {
        switch mood {
        case .idle: bob ? 1.5 : -1.5
        case .think: think ? 3 : -3
        case .celebrate: celebrate ? 6 : -6
        case .pop: 0
        }
    }
    private var bobOffset: CGFloat {
        switch mood {
        case .idle: bob ? -7 : 0
        case .celebrate: celebrate ? -12 : 0
        default: 0
        }
    }
    private var scale: CGFloat {
        switch mood {
        case .pop: pop ? 1 : 0.6
        case .celebrate: celebrate ? 1.05 : 1
        default: 1
        }
    }

    private func startAnimations() {
        switch mood {
        case .idle:
            withAnimation(.easeInOut(duration: 1.7).repeatForever(autoreverses: true)) { bob = true }
        case .think:
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) { think = true }
        case .celebrate:
            withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) { celebrate = true }
        case .pop:
            withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) { pop = true }
        }
        if ring {
            withAnimation(.easeOut(duration: 1.8).repeatForever(autoreverses: false)) { ringPulse = true }
        }
    }
}

// MARK: - Appear animation (animate-slideUp, staggered)

struct SlideUp: ViewModifier {
    var delay: Double = 0
    @State private var shown = false
    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 20)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.82).delay(delay)) {
                    shown = true
                }
            }
    }
}

extension View {
    func slideUp(_ delay: Double = 0) -> some View { modifier(SlideUp(delay: delay)) }
}
