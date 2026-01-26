// AppConfiguration.swift
// App-level configuration and setup - 2026 Best Practices

import Foundation
import SwiftUI
import UIKit

// MARK: - Firebase Configuration
// Uncomment after adding Firebase SDK via Swift Package Manager
// import FirebaseCore

/// Handles app-level configuration
enum AppConfiguration {

    /// Configure Firebase and other services
    /// Call this in your App's init() or AppDelegate
    static func configure() {
        // === FIREBASE SETUP ===
        // Uncomment after adding Firebase SDK:
        // FirebaseApp.configure()

        // Configure other services here
        configureAppearance()
    }

    /// Configure global UI appearance
    private static func configureAppearance() {
        // Navigation bar appearance
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithDefaultBackground()
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance

        // Tab bar appearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }
}

// MARK: - Environment Keys
// Note: AuthenticationService is accessed via @StateObject or directly via .shared

// MARK: - App Constants

enum AppConstants {
    static let appName = "CleanConnect"
    static let bundleId = "com.cleanconnect.app"
    static let appStoreId = "" // Add your App Store ID

    // URLs
    static let termsURL = URL(string: "https://thebighead.ca/CleanConnect/terms")!
    static let privacyURL = URL(string: "https://thebighead.ca/CleanConnect/privacy")!
    static let supportURL = URL(string: "https://thebighead.ca/CleanConnect/support")!
    static let supportEmail = "support@thebighead.ca"

    // Feature Flags
    static let isFirebaseEnabled = true
}
