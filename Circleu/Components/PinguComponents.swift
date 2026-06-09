import SwiftUI

struct PinguScreenBackground: View {
    var body: some View {
        PinguAuroraBackground()
    }
}

struct PinguCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .pinguGlass(cornerRadius: 24)
    }
}

enum PinguTab: String {
    case home = "Home"
    case journal = "Journal"
    case tips = "Tips"
    case circle = "Circle"
    case profile = "Profile"

    static let bottomTabs: [PinguTab] = [.home, .tips, .circle, .profile]

    var icon: String {
        switch self {
        case .home: "house.fill"
        case .journal: "book.closed.fill"
        case .tips: "mic.fill"
        case .circle: "person.2.fill"
        case .profile: "person.crop.circle.fill"
        }
    }
}

struct PinguTopBar: View {
    let title: String
    var leadingIcon: String = "line.3.horizontal"
    var trailing: Trailing = .none

    enum Trailing {
        case level(Int)
        case streak(Int)
        case edit(() -> Void)
        case none
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: leadingIcon)
                .font(.system(size: 21, weight: .bold))
                .foregroundStyle(PinguDesign.blue)
                .frame(width: 30)

            Text(title)
                .font(PinguFont.screenTitle)
                .foregroundStyle(PinguDesign.blue)

            Spacer()

            HStack(spacing: 10) {
                switch trailing {
                case .level(let value):
                    navPill(icon: "sparkles", text: "LV\(value)", tint: PinguDesign.orange)
                    PinguAvatar(size: 42)
                case .streak(let value):
                    navPill(icon: "flame.fill", text: "\(value)", tint: PinguDesign.blue)
                    PinguAvatar(size: 42)
                case .edit(let action):
                    Button(action: action) {
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(PinguDesign.blue)
                            .frame(width: 42, height: 42)
                            .background(PinguDesign.lightBlue)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                case .none:
                    EmptyView()
                }
            }
            .frame(minWidth: 42, alignment: .trailing)
        }
        .padding(.horizontal, PinguDesign.screenSidePadding)
        .frame(height: 70)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Divider().overlay(.white.opacity(0.4))
        }
    }

    private func navPill(icon: String, text: String, tint: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(tint)
            Text(text)
                .font(PinguFont.caption)
                .foregroundStyle(PinguDesign.ink)
                .monospacedDigit()
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
        .pinguGlass(cornerRadius: 18, tint: 0.10)
    }
}

struct PinguAvatar: View {
    let size: CGFloat

    var body: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .symbolRenderingMode(.palette)
            .foregroundStyle(PinguDesign.ink, PinguDesign.lightBlue)
            .frame(width: size, height: size)
            .background(Circle().fill(PinguDesign.lightBlue))
            .clipShape(Circle())
    }
}

struct PinguBottomTabBar: View {
    @Binding var selection: PinguTab

    var body: some View {
        HStack(spacing: 12) {
            ForEach(PinguTab.bottomTabs, id: \.self) { tab in
                Button {
                    selection = tab
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 21, weight: .semibold))
                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                    }
                    .foregroundStyle(selection == tab ? PinguDesign.blue : PinguDesign.muted)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background {
                        if selection == tab {
                            Capsule()
                                .fill(.white.opacity(0.38))
                                .overlay {
                                    Capsule()
                                        .strokeBorder(.white.opacity(0.65), lineWidth: 0.8)
                                }
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 64)
        .pinguGlass(cornerRadius: 30)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

struct PinguNavBar: View {
    let title: String
    let leadingIcon: String
    let trailingIcon: String?
    let onLeadingTap: () -> Void
    var onTrailingTap: () -> Void = {}

    var body: some View {
        HStack {
            Button(action: onLeadingTap) {
                Image(systemName: leadingIcon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(PinguDesign.blue)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text(title)
                .font(PinguFont.sectionTitle)
                .foregroundStyle(PinguDesign.blue)

            Spacer()

            if let trailingIcon {
                Button(action: onTrailingTap) {
                    Image(systemName: trailingIcon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(PinguDesign.tabText)
                        .frame(width: 44, height: 44)
                }
            } else {
                Color.clear.frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, PinguDesign.screenSidePadding)
        .frame(height: 66)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Divider().overlay(.white.opacity(0.4))
        }
    }
}

struct PinguPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PinguFont.button)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [PinguDesign.electricBlue, PinguDesign.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(configuration.isPressed ? 0.85 : 1)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.white.opacity(0.45), lineWidth: 0.8)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: PinguDesign.blue.opacity(0.40), radius: 14, x: 0, y: 8)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct PinguSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PinguFont.button)
            .foregroundStyle(PinguDesign.ink)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .pinguGlass(cornerRadius: 16, tint: configuration.isPressed ? 0.06 : 0.16)
    }
}
