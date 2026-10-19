// ContentView.swift
// Main navigation container for CleanConnect
// Events-first design - 2026

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var userState: UserState
    @State private var selectedTab: Tab = .events

    enum Tab: String, CaseIterable {
        case events = "Events"
        case feed = "Feed"
        case profile = "Profile"

        var icon: String {
            switch self {
            case .events: return "calendar.badge.plus"
            case .feed: return "leaf.fill"
            case .profile: return "person.circle.fill"
            }
        }
    }

    var body: some View {
        Group {
            if authManager.isLoading {
                launchScreen
            } else if authManager.isAuthenticated {
                mainTabView
            } else {
                AuthView()
            }
        }
        .animation(.easeInOut, value: authManager.isAuthenticated)
    }

    private var launchScreen: some View {
        ZStack {
            Color.ccPrimaryTint.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "leaf.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.ccPrimary)
                Text("CleanConnect")
                    .font(.title.bold())
                ProgressView()
            }
        }
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            GatheringsView()
                .tabItem {
                    Label(Tab.events.rawValue, systemImage: Tab.events.icon)
                }
                .tag(Tab.events)

            FeedView()
                .tabItem {
                    Label(Tab.feed.rawValue, systemImage: Tab.feed.icon)
                }
                .tag(Tab.feed)

            ProfileView()
                .tabItem {
                    Label(Tab.profile.rawValue, systemImage: Tab.profile.icon)
                }
                .tag(Tab.profile)
        }
        .tint(.ccPrimary)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager.shared)
        .environmentObject(UserState.shared)
}
