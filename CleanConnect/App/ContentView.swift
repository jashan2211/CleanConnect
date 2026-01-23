// ContentView.swift
// Main navigation container for CleanConnect

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var userState: UserState
    @State private var selectedTab: Tab = .feed

    enum Tab: String, CaseIterable {
        case feed = "Feed"
        case gatherings = "Events"
        case companies = "Services"
        case profile = "Profile"

        var icon: String {
            switch self {
            case .feed: return "leaf.fill"
            case .gatherings: return "person.3.fill"
            case .companies: return "building.2.fill"
            case .profile: return "person.circle.fill"
            }
        }
    }

    var body: some View {
        Group {
            if authManager.isAuthenticated {
                mainTabView
            } else {
                AuthView()
            }
        }
        .animation(.easeInOut, value: authManager.isAuthenticated)
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            FeedView()
                .tabItem {
                    Label(Tab.feed.rawValue, systemImage: Tab.feed.icon)
                }
                .tag(Tab.feed)

            GatheringsView()
                .tabItem {
                    Label(Tab.gatherings.rawValue, systemImage: Tab.gatherings.icon)
                }
                .tag(Tab.gatherings)

            CompaniesView()
                .tabItem {
                    Label(Tab.companies.rawValue, systemImage: Tab.companies.icon)
                }
                .tag(Tab.companies)

            ProfileView()
                .tabItem {
                    Label(Tab.profile.rawValue, systemImage: Tab.profile.icon)
                }
                .tag(Tab.profile)
        }
        .tint(Color("AccentColor"))
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager.shared)
        .environmentObject(UserState.shared)
}
