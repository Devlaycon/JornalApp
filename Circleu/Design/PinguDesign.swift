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

enum PinguFont {
    static let hero = Font.system(size: 30, weight: .bold, design: .rounded)
    static let screenTitle = Font.system(size: 29, weight: .bold, design: .rounded)
    static let sectionTitle = Font.system(size: 20, weight: .bold, design: .rounded)
    static let cardTitle = Font.system(size: 17, weight: .bold, design: .rounded)
    static let body = Font.system(size: 14, weight: .medium, design: .rounded)
    static let bodyLight = Font.system(size: 14, weight: .regular, design: .rounded)
    static let caption = Font.system(size: 12, weight: .semibold, design: .rounded)
    static let tiny = Font.system(size: 11, weight: .bold, design: .rounded)
    static let button = Font.system(size: 15, weight: .bold, design: .rounded)
}
