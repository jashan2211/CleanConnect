// ProfileView.swift
// User profile and settings

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var userState: UserState
    @State private var showSettings = false
    @State private var showEditProfile = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile header
                    profileHeader

                    // Stats cards
                    statsCards

                    // Level progress
                    levelProgress

                    // Badges
                    badgesSection

                    // Recent activity
                    recentActivitySection

                    // Menu items
                    menuSection
                }
                .padding()
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView()
            }
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                AsyncImage(url: URL(string: userState.currentUser?.photoURL ?? "")) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.gray)
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.green, lineWidth: 3))

                // Level badge
                Text("Lv.\(userState.currentUser?.level ?? 1)")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .cornerRadius(10)
            }

            // Name and bio
            VStack(spacing: 4) {
                Text(userState.currentUser?.displayName ?? "User")
                    .font(.title2.weight(.bold))

                if let bio = userState.currentUser?.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Location
                if let state = userState.currentUser?.state {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.red)
                        Text("\(userState.currentUser?.district ?? ""), \(state)")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }

            // Edit profile button
            Button(action: { showEditProfile = true }) {
                Text("Edit Profile")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(20)
            }

            // Karma score
            HStack(spacing: 16) {
                VStack {
                    Text("\(userState.currentUser?.karmaScore ?? 0)")
                        .font(.headline)
                    Text("Karma")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider().frame(height: 30)

                VStack {
                    Text("\(userState.currentUser?.followersCount ?? 0)")
                        .font(.headline)
                    Text("Followers")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider().frame(height: 30)

                VStack {
                    Text("\(userState.currentUser?.followingCount ?? 0)")
                        .font(.headline)
                    Text("Following")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private var statsCards: some View {
        HStack(spacing: 12) {
            StatCard(icon: "leaf.fill", value: "\(userState.currentUser?.totalPosts ?? 0)", label: "Cleanups", color: .green)
            StatCard(icon: "trash.fill", value: "\(String(format: "%.1f", userState.currentUser?.totalWasteKg ?? 0)) kg", label: "Collected", color: .orange)
            StatCard(icon: "star.fill", value: "\(userState.currentUser?.totalPoints ?? 0)", label: "Points", color: .yellow)
        }
    }

    private var levelProgress: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Level Progress")
                    .font(.headline)
                Spacer()
                Text(userState.currentUser?.levelName ?? "Eco Scout")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }

            VStack(alignment: .leading, spacing: 4) {
                ProgressView(value: userState.levelProgress, total: 1.0)
                    .tint(.green)

                HStack {
                    Text("\(userState.currentUser?.totalPoints ?? 0) pts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(userState.nextLevelPoints) pts to next level")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }

    private var badgesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Badges")
                    .font(.headline)
                Spacer()
                NavigationLink(destination: AllBadgesView()) {
                    Text("See All")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(userState.earnedBadges) { badge in
                        BadgeView(badge: badge)
                    }
                }
            }
        }
    }

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)

            ForEach(userState.recentActivity.prefix(3)) { activity in
                ActivityRow(activity: activity)
            }
        }
    }

    private var menuSection: some View {
        VStack(spacing: 0) {
            MenuItem(icon: "bookmark.fill", title: "Saved Posts", color: .blue) {}
            MenuItem(icon: "person.2.fill", title: "My Squad", color: .purple) {}
            MenuItem(icon: "calendar", title: "My Events", color: .orange) {}
            MenuItem(icon: "creditcard.fill", title: "Wallet & Payments", color: .green) {}
            MenuItem(icon: "gift.fill", title: "Refer & Earn", color: .pink) {}
            MenuItem(icon: "questionmark.circle.fill", title: "Help & Support", color: .gray) {}
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager.shared)
        .environmentObject(UserState.shared)
}
