// CleanConnectApp.swift
// CleanConnect - Gamified Social Platform for Environmental Cleanup
// Main app entry point for iOS

import SwiftUI

@main
struct CleanConnectApp: App {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var userState = UserState.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(userState)
                .preferredColorScheme(.light)
                .onAppear {
                    setupAppearance()
                }
        }
    }

    private func setupAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance

        // Configure tab bar appearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }
}
