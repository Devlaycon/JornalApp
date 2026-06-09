import SwiftUI

enum PinguDesign {
    static let ink = Color("PinguInk")
    static let deepBlue = Color("PinguDeepBlue")
    static let blue = Color("PinguBlue")
    static let electricBlue = Color("PinguElectricBlue")
    static let aqua = Color("PinguAqua")
    static let sky = Color("PinguSky")
    static let lightBlue = Color("PinguLightBlue")
    static let ice = Color("PinguIce")
    static let orange = Color("PinguOrange")
    static let surface = Color("PinguSurface")
    static let body = Color("PinguBody")
    static let muted = Color("PinguMuted")
    static let border = Color("PinguBorder")
    static let tabText = Color("PinguTabText")
    static let screenSidePadding: CGFloat = 22
    static let bottomBarHeight: CGFloat = 92
}

// MARK: - Liquid Frosted Glass

/// Aurora gradient that sits behind every screen. Glass only reads as glass
/// when this shows through it, so use it as the root background everywhere.
struct PinguAuroraBackground: View {
    var body: some View {
        ZStack {
            PinguDesign.ice
            Circle()
                .fill(PinguDesign.sky.opacity(0.55))
                .frame(width: 440)
                .blur(radius: 120)
                .offset(x: -140, y: -280)
            Circle()
                .fill(Color(red: 0.55, green: 0.36, blue: 0.96).opacity(0.38))
                .frame(width: 400)
                .blur(radius: 130)
                .offset(x: 160, y: -210)
            Circle()
                .fill(PinguDesign.electricBlue.opacity(0.40))
                .frame(width: 480)
                .blur(radius: 140)
                .offset(x: 0, y: 340)
        }
        .ignoresSafeArea()
    }
}

/// The one material for all cards, sheets, bars and pills.
/// Translucent white + blur (.ultraThinMaterial) + a luminous hairline border.
struct PinguGlass: ViewModifier {
    var cornerRadius: CGFloat = 24
    var tint: Double = 0.14

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.white.opacity(tint))
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.75), .white.opacity(0.18)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: PinguDesign.deepBlue.opacity(0.12), radius: 18, x: 0, y: 10)
    }
}

extension View {
    /// Apply the standard Circleu liquid-glass treatment to any container.
    func pinguGlass(cornerRadius: CGFloat = 24, tint: Double = 0.14) -> some View {
        modifier(PinguGlass(cornerRadius: cornerRadius, tint: tint))
    }
}
