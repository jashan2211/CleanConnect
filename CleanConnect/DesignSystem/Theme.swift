import SwiftUI
import UIKit

// MARK: - Palette

extension Color {
    /// Brand emerald. Used for primary actions and "cleaned" states.
    static let ccGreen = Color(light: 0x0A8F5B, dark: 0x2BC48A)
    static let ccGreenDeep = Color(light: 0x05593A, dark: 0x0C3B29)
    static let ccMint = Color(light: 0xDDF5E8, dark: 0x123326)
    /// Saffron accent. Used for drives, streaks and highlights.
    static let ccSaffron = Color(light: 0xF27A12, dark: 0xFF9E45)
    static let ccSaffronSoft = Color(light: 0xFFEBD6, dark: 0x3A2612)
    /// Status colours.
    static let ccDirty = Color(light: 0xE5484D, dark: 0xFF6369)
    static let ccClaimed = Color(light: 0xE59A0B, dark: 0xFFC53D)
    static let ccCleaned = Color(light: 0x12A365, dark: 0x3DD68C)
    static let ccBlue = Color(light: 0x2F6FEB, dark: 0x6B9BFF)

    static let ccBackground = Color(light: 0xF4F6F1, dark: 0x080D0A)
    static let ccSurface = Color(light: 0xFFFFFF, dark: 0x121A16)
    static let ccSurface2 = Color(light: 0xECF1EA, dark: 0x1B2620)
    static let ccInk = Color(light: 0x0F1A14, dark: 0xF1F5F2)
    static let ccInk2 = Color(light: 0x56665C, dark: 0x9DADA4)
    static let ccStroke = Color(light: 0x0F1A14, dark: 0xFFFFFF).opacity(0.08)

    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }

    init(hex: UInt32) {
        self.init(uiColor: UIColor(hex: hex))
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

extension LinearGradient {
    static let ccHero = LinearGradient(
        colors: [Color(hex: 0x10B072), Color(hex: 0x07724A), Color(hex: 0x04452D)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let ccSaffron = LinearGradient(
        colors: [Color(hex: 0xFFA640), Color(hex: 0xF0670C)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let ccNight = LinearGradient(
        colors: [Color(hex: 0x1D2B24), Color(hex: 0x0B120E)],
        startPoint: .top, endPoint: .bottom
    )
}

// MARK: - Typography

extension Font {
    static func cc(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .rounded, weight: weight)
    }

    static let ccLargeTitle = Font.system(.largeTitle, design: .rounded, weight: .heavy)
    static let ccTitle = Font.system(.title2, design: .rounded, weight: .bold)
    static let ccTitle3 = Font.system(.title3, design: .rounded, weight: .bold)
    static let ccHeadline = Font.system(.headline, design: .rounded, weight: .semibold)
    static let ccBody = Font.system(.body, design: .default)
    static let ccCaption = Font.system(.caption, design: .rounded, weight: .medium)
    static func ccNumber(_ size: CGFloat) -> Font {
        .system(size: size, weight: .heavy, design: .rounded).monospacedDigit()
    }
}

// MARK: - Metrics

enum Metrics {
    static let corner: CGFloat = 22
    static let cornerSmall: CGFloat = 14
    static let gutter: CGFloat = 16
    static let maxReadableWidth: CGFloat = 640
}

// MARK: - Modifiers

struct CardModifier: ViewModifier {
    var padding: CGFloat = 16
    var corner: CGFloat = Metrics.corner

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.ccSurface, in: RoundedRectangle(cornerRadius: corner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .strokeBorder(Color.ccStroke, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 10, y: 4)
    }
}

extension View {
    func ccCard(padding: CGFloat = 16, corner: CGFloat = Metrics.corner) -> some View {
        modifier(CardModifier(padding: padding, corner: corner))
    }

    /// Keeps content at a comfortable width on iPad while filling iPhone screens.
    func readableWidth(_ width: CGFloat = Metrics.maxReadableWidth) -> some View {
        frame(maxWidth: width).frame(maxWidth: .infinity)
    }

    /// Floating glass surface: Liquid Glass on iOS 26+, material before that.
    @ViewBuilder
    func ccGlass<S: Shape>(in shape: S, tint: Color? = nil, interactive: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            let glass: Glass = tint.map { Glass.regular.tint($0) } ?? .regular
            self.glassEffect(interactive ? glass.interactive() : glass, in: shape)
        } else {
            self.background {
                ZStack {
                    shape.fill(.ultraThinMaterial)
                    if let tint { shape.fill(tint.opacity(0.85)) }
                }
            }
            .overlay(shape.stroke(Color.white.opacity(0.18), lineWidth: 0.5))
        }
    }
}

// MARK: - Haptics

enum Haptics {
    static func tap() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func soft() { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
    static func selection() { UISelectionFeedbackGenerator().selectionChanged() }
}
