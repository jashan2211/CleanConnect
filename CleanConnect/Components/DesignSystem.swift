// DesignSystem.swift
// CleanConnect design tokens, button styles, and card modifier.
//
// Step 1 of the UI/UX overhaul. Introduces HIG-aligned semantic colors,
// reusable ButtonStyles, and a StandardCardStyle modifier. Existing
// `cc*` tokens in Extensions.swift remain in place until Step 2 refactors
// call sites.

import SwiftUI

// MARK: - Semantic Colors

extension Color {
    /// Primary brand / action color. Deeper, WCAG-AA friendly eco green
    /// (HEX #059669) with a slightly lighter dark-mode variant.
    /// Defined in Assets.xcassets/AppPrimary.colorset.
    static let ccPrimary = Color("AppPrimary")

    /// Soft primary fill (10% opacity) for secondary buttons, badges,
    /// and tinted backgrounds.
    static let ccPrimaryTint = ccPrimary.opacity(0.10)

    /// Base page background — matches iOS `.systemGroupedBackground`
    /// across light and dark. Defined in Assets.xcassets/AppBackground.colorset.
    static let ccBackground = Color("AppBackground")

    /// Card / surface background sitting on `ccBackground` — matches
    /// iOS `.secondarySystemGroupedBackground`.
    static let ccSurface = Color("AppSurface")

    /// Tertiary surface for chips, segmented controls, etc. — matches
    /// iOS `.secondarySystemBackground`.
    static let ccSurfaceSubtle = Color("AppSurfaceSubtle")
}

// MARK: - Spacing

/// 8pt grid. Use these constants instead of free-form numbers so
/// padding stays consistent across the app.
enum AppSpacing {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 16
    static let l: CGFloat = 24
    static let xl: CGFloat = 32
}

// MARK: - Corner Radii

enum AppCornerRadius {
    static let card: CGFloat = 16
    static let button: CGFloat = 12
    static let chip: CGFloat = 100
}

// MARK: - Hit Target

extension View {
    /// Apple HIG minimum tappable size (44×44). Apply to icon-only
    /// buttons so the touch area exceeds the visual icon size.
    func iconHitTarget() -> some View {
        frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
    }
}

// MARK: - Button Styles

/// Solid primary action. Capsule-ish rounded rect, white label,
/// 50pt min height, continuous corner curve.
struct PrimaryActionStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(Color.ccPrimary.opacity(isEnabled ? 1.0 : 0.4))
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.button, style: .continuous))
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .contentShape(RoundedRectangle(cornerRadius: AppCornerRadius.button, style: .continuous))
    }
}

/// Tinted primary. Soft `ccPrimaryTint` fill with primary-colored label.
/// Use for "Edit Profile", "Filter", and other secondary actions.
struct SecondaryActionStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundColor(.ccPrimary)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(Color.ccPrimaryTint)
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.button, style: .continuous))
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .contentShape(RoundedRectangle(cornerRadius: AppCornerRadius.button, style: .continuous))
    }
}

/// Plain text action. Use for "Skip", "Cancel", inline links.
struct GhostActionStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.ccPrimary)
            .padding(.vertical, AppSpacing.s)
            .padding(.horizontal, AppSpacing.m)
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .contentShape(Rectangle())
    }
}

// MARK: - Card Modifier

/// Standard surface treatment: 16pt padding, `ccSurface` background,
/// 16pt continuous corner radius. No drop shadow — relies on the grouped
/// background contrast for elevation.
struct StandardCardStyle: ViewModifier {
    var padding: CGFloat = AppSpacing.m

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.ccSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.card, style: .continuous))
    }
}

extension View {
    /// Wraps a view in the standard card surface (no shadow, semantic
    /// background, continuous corners). See `StandardCardStyle`.
    func standardCard(padding: CGFloat = AppSpacing.m) -> some View {
        modifier(StandardCardStyle(padding: padding))
    }
}

// MARK: - Empty State

/// Unified empty / zero-data view: tinted SF Symbol disc, headline,
/// descriptive subtitle, and an optional primary CTA. Dynamic-type
/// friendly; safe to drop into any list/grid.
struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: AppSpacing.m) {
            ZStack {
                Circle()
                    .fill(Color.ccPrimaryTint)
                    .frame(width: 96, height: 96)

                Image(systemName: systemImage)
                    .font(.system(size: 40, weight: .regular))
                    .foregroundColor(.ccPrimary)
                    .accessibilityHidden(true)
            }

            VStack(spacing: AppSpacing.xs) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, AppSpacing.l)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(PrimaryActionStyle())
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.top, AppSpacing.s)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xl)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
    }
}
