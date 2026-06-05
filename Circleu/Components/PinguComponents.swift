import SwiftUI

struct PinguScreenBackground: View {
    var body: some View {
        PinguDesign.ice
            .ignoresSafeArea()
    }
}

struct PinguCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PinguDesign.surface)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: PinguDesign.deepBlue.opacity(0.08), radius: 20, x: 0, y: 10)
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
                .font(.system(size: 25, weight: .bold))
                .foregroundStyle(PinguDesign.blue)
                .frame(width: 30)

            Text(title)
                .font(.system(size: 31, weight: .bold, design: .rounded))
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
                            .font(.system(size: 18, weight: .bold))
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
        .background(PinguDesign.ice.opacity(0.98))
        .overlay(alignment: .bottom) {
            Divider().overlay(PinguDesign.border.opacity(0.55))
        }
    }

    private func navPill(icon: String, text: String, tint: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(tint)
            Text(text)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(PinguDesign.ink)
                .monospacedDigit()
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
        .background(PinguDesign.lightBlue.opacity(0.78))
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(.white.opacity(0.75), lineWidth: 1)
        }
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
                            .font(.system(size: 23, weight: .semibold))
                        Text(tab.rawValue)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                    }
                    .foregroundStyle(selection == tab ? PinguDesign.ink : PinguDesign.muted)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background {
                        if selection == tab {
                            Capsule()
                                .fill(PinguDesign.lightBlue.opacity(0.92))
                                .overlay {
                                    Capsule()
                                        .stroke(.white.opacity(0.78), lineWidth: 1)
                                }
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 26)
        .padding(.top, 10)
        .frame(height: PinguDesign.bottomBarHeight)
        .background(PinguDesign.ice.opacity(0.98))
        .overlay(alignment: .top) {
            Divider().overlay(PinguDesign.border.opacity(0.7))
        }
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
                .font(.system(size: 25, weight: .bold, design: .rounded))
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
        .background(PinguDesign.ice)
        .overlay(alignment: .bottom) {
            Divider().overlay(PinguDesign.border.opacity(0.7))
        }
    }
}

struct PinguPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(PinguDesign.blue.opacity(configuration.isPressed ? 0.82 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct PinguSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(PinguDesign.ink)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.white.opacity(configuration.isPressed ? 0.74 : 0.92))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(PinguDesign.lightBlue.opacity(0.5), lineWidth: 1)
            }
    }
}
