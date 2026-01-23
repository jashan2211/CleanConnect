// AccessibilityHelpers.swift
// Accessibility labels and helpers for VoiceOver support

import SwiftUI
import UIKit

// MARK: - Accessibility Labels

struct AccessibilityLabels {
    // Feed
    static func postCard(userName: String, wasteKg: Double, likes: Int, isVerified: Bool) -> String {
        var label = "Post by \(userName). Collected \(String(format: "%.1f", wasteKg)) kilograms of waste. \(likes) likes."
        if isVerified {
            label += " Verified post."
        }
        return label
    }

    static func likeButton(isLiked: Bool, count: Int) -> String {
        isLiked ? "Unlike. Currently \(count) likes" : "Like. Currently \(count) likes"
    }

    static func tipButton(amount: Int) -> String {
        "Send tip. Total tips received: \(amount) rupees"
    }

    static func verificationBadge(_ badge: VerificationBadge) -> String {
        switch badge {
        case .verified: return "Verified with video proof and community approval"
        case .videoProof: return "Has video proof"
        case .communityVerified: return "Community verified"
        case .unverified: return "Not yet verified"
        }
    }

    // Profile
    static func levelProgress(current: Int, next: Int, levelName: String) -> String {
        "Level \(levelName). \(current) points. \(next) points to next level."
    }

    static func statCard(label: String, value: String) -> String {
        "\(label): \(value)"
    }

    // Events
    static func eventCard(title: String, date: Date, attendees: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(title). \(formatter.string(from: date)). \(attendees) attendees."
    }

    static func rsvpButton(isGoing: Bool) -> String {
        isGoing ? "Cancel RSVP" : "Join event"
    }

    // Leaderboard
    static func leaderboardEntry(rank: Int, name: String, points: Int, level: String) -> String {
        "Rank \(rank). \(name). \(points) points. Level: \(level)"
    }
}

// MARK: - Accessibility View Modifiers

extension View {
    func accessiblePostCard(userName: String, wasteKg: Double, likes: Int, isVerified: Bool) -> some View {
        self.accessibilityElement(children: .combine)
            .accessibilityLabel(AccessibilityLabels.postCard(userName: userName, wasteKg: wasteKg, likes: likes, isVerified: isVerified))
    }

    func accessibleButton(_ label: String, hint: String? = nil) -> some View {
        self.accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isButton)
    }

    func accessibleImage(_ description: String) -> some View {
        self.accessibilityLabel(description)
            .accessibilityAddTraits(.isImage)
    }

    func accessibleHeader(_ text: String) -> some View {
        self.accessibilityLabel(text)
            .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - Dynamic Type Support

struct ScaledFont: ViewModifier {
    @Environment(\.sizeCategory) var sizeCategory
    var size: CGFloat
    var weight: Font.Weight = .regular

    func body(content: Content) -> some View {
        content.font(.system(size: scaledSize, weight: weight))
    }

    private var scaledSize: CGFloat {
        UIFontMetrics.default.scaledValue(for: size)
    }
}

extension View {
    func scaledFont(size: CGFloat, weight: Font.Weight = .regular) -> some View {
        modifier(ScaledFont(size: size, weight: weight))
    }
}

// MARK: - Reduce Motion Support

struct ReduceMotionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    let animation: Animation?

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? nil : animation, value: UUID())
    }
}

extension View {
    func accessibleAnimation(_ animation: Animation?) -> some View {
        modifier(ReduceMotionModifier(animation: animation))
    }
}

// MARK: - High Contrast Support

extension Color {
    static func adaptiveColor(light: Color, dark: Color, highContrast: Color) -> Color {
        // This would be expanded with proper high contrast detection
        return light
    }
}

// MARK: - Accessible Tap Targets

struct AccessibleTapTarget: ViewModifier {
    let minSize: CGFloat

    func body(content: Content) -> some View {
        content
            .frame(minWidth: minSize, minHeight: minSize)
            .contentShape(Rectangle())
    }
}

extension View {
    func accessibleTapTarget(minSize: CGFloat = 44) -> some View {
        modifier(AccessibleTapTarget(minSize: minSize))
    }
}

// MARK: - Screen Reader Announcements

@MainActor
class AccessibilityAnnouncer {
    static let shared = AccessibilityAnnouncer()

    func announce(_ message: String, after delay: TimeInterval = 0.1) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }

    func announceScreenChange(_ message: String) {
        UIAccessibility.post(notification: .screenChanged, argument: message)
    }

    func announceLayoutChange(_ message: String) {
        UIAccessibility.post(notification: .layoutChanged, argument: message)
    }
}
