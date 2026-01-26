// CleanConnectWatchApp.swift
// Apple Watch companion app for CleanConnect
// To use: Add a Watch App target in Xcode (File > New > Target > watchOS > App)

import SwiftUI

@main
struct CleanConnectWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchContentView()
        }
    }
}
