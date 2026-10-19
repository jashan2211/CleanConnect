import SwiftUI

/// Full-width capsule button used for the main action on a screen.
struct PrimaryButtonStyle: ButtonStyle {
    var tint: Color = .ccGreen
    var foreground: Color = .white
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.cc(.headline, weight: .bold))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity, minHeight: 54)
            .padding(.horizontal, 20)
            .background(tint.opacity(isEnabled ? 1 : 0.35), in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Tinted, lower-emphasis capsule button.
struct SecondaryButtonStyle: ButtonStyle {
    var tint: Color = .ccGreen
    var fullWidth = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.cc(.subheadline, weight: .semibold))
            .foregroundStyle(tint)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: 46)
            .padding(.horizontal, 16)
            .background(tint.opacity(0.12), in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Springy press feedback for card-like tappable rows.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
    static func primary(_ tint: Color) -> PrimaryButtonStyle { PrimaryButtonStyle(tint: tint) }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
    static func secondary(_ tint: Color, fullWidth: Bool = true) -> SecondaryButtonStyle {
        SecondaryButtonStyle(tint: tint, fullWidth: fullWidth)
    }
}

extension ButtonStyle where Self == PressableStyle {
    static var pressable: PressableStyle { PressableStyle() }
}

/// Selectable capsule used for filters and multi-select choices.
struct Chip: View {
    let title: LocalizedStringKey
    var icon: String?
    var isSelected: Bool
    var tint: Color = .ccGreen
    var action: () -> Void

    var body: some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            HStack(spacing: 6) {
                if let icon { Image(systemName: icon).font(.caption.weight(.bold)) }
                Text(title).font(.cc(.subheadline, weight: .semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .foregroundStyle(isSelected ? Color.white : Color.ccInk)
            .background(isSelected ? tint : Color.ccSurface, in: Capsule())
            .overlay(Capsule().strokeBorder(isSelected ? Color.clear : Color.ccStroke, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .animation(.snappy(duration: 0.2), value: isSelected)
    }
}

/// Small round icon button that floats over maps and photos.
struct CircleIconButton: View {
    let systemName: String
    var size: CGFloat = 44
    var tint: Color = .ccInk
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: size, height: size)
                .ccGlass(in: Circle(), interactive: true)
        }
        .buttonStyle(.plain)
    }
}
