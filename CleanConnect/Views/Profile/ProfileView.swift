// ProfileView.swift
// User profile and settings

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var userState: UserState
    @State private var showSettings = false
    @State private var showEditProfile = false
    @State private var showWallet = false
    @State private var userPosts: [Post] = []
    @State private var isLoadingPosts = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile header
                    profileHeader

                    // Social Links
                    if let socialLinks = userState.currentUser?.socialLinks, socialLinks.hasAnyLink {
                        socialLinksSection(socialLinks)
                    }

                    // Stats cards
                    statsCards

                    // Extended Stats
                    extendedStatsSection

                    // Level progress
                    levelProgress

                    // Badges
                    badgesSection

                    // My Posts
                    myPostsSection

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

    // MARK: - Social Links Section

    private func socialLinksSection(_ socialLinks: SocialLinks) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Connect")
                .font(.headline)

            HStack(spacing: 16) {
                if let instagram = socialLinks.instagram {
                    SocialLinkButton(platform: .instagram, username: instagram)
                }
                if let twitter = socialLinks.twitter {
                    SocialLinkButton(platform: .twitter, username: twitter)
                }
                if let linkedin = socialLinks.linkedin {
                    SocialLinkButton(platform: .linkedin, username: linkedin)
                }
                if let youtube = socialLinks.youtube {
                    SocialLinkButton(platform: .youtube, username: youtube)
                }
                if let website = socialLinks.website {
                    SocialLinkButton(platform: .website, username: website)
                }
            }
        }
    }

    private var statsCards: some View {
        HStack(spacing: 12) {
            ProfileStatCard(icon: "leaf.fill", value: "\(userState.currentUser?.totalPosts ?? 0)", label: "Cleanups", color: .green)
            ProfileStatCard(icon: "trash.fill", value: "\(String(format: "%.1f", userState.currentUser?.totalWasteKg ?? 0)) kg", label: "Collected", color: .orange)
            ProfileStatCard(icon: "star.fill", value: "\(userState.currentUser?.totalPoints ?? 0)", label: "Points", color: .yellow)
        }
    }

    // MARK: - Extended Stats Section

    private var extendedStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Impact Stats")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ImpactStatCard(
                    icon: "clock.fill",
                    value: String(format: "%.1f", userState.currentUser?.totalVolunteerHours ?? 0),
                    unit: "hrs",
                    label: "Volunteer Time",
                    color: .blue
                )

                ImpactStatCard(
                    icon: "leaf.arrow.circlepath",
                    value: String(format: "%.1f", userState.currentUser?.totalCO2Saved ?? 0),
                    unit: "kg",
                    label: "CO₂ Saved",
                    color: .green
                )

                ImpactStatCard(
                    icon: "flame.fill",
                    value: "\(userState.currentUser?.currentStreak ?? 0)",
                    unit: "days",
                    label: "Current Streak",
                    color: .orange
                )

                ImpactStatCard(
                    icon: "trophy.fill",
                    value: "\(userState.currentUser?.longestStreak ?? 0)",
                    unit: "days",
                    label: "Best Streak",
                    color: .yellow
                )

                ImpactStatCard(
                    icon: "mappin.and.ellipse",
                    value: "\(userState.currentUser?.totalAreasImpacted ?? 0)",
                    unit: "areas",
                    label: "Locations Cleaned",
                    color: .purple
                )

                ImpactStatCard(
                    icon: "video.fill",
                    value: "\(userState.currentUser?.videosVerified ?? 0)",
                    unit: "posts",
                    label: "Verified Videos",
                    color: .teal
                )

                ImpactStatCard(
                    icon: "shippingbox.fill",
                    value: "\(userState.currentUser?.totalSuppliesContributed ?? 0)",
                    unit: "items",
                    label: "Supplies Given",
                    color: .indigo
                )

                ImpactStatCard(
                    icon: "indianrupeesign.circle.fill",
                    value: "₹\(userState.currentUser?.totalDonationsAmount ?? 0)",
                    unit: "",
                    label: "Total Donated",
                    color: .pink
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
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

    // MARK: - My Posts Section

    private var myPostsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("My Posts")
                    .font(.headline)
                Spacer()
                if !userPosts.isEmpty {
                    NavigationLink(destination: AllUserPostsView(posts: userPosts)) {
                        Text("See All")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }

            if isLoadingPosts {
                HStack {
                    Spacer()
                    ProgressView()
                        .padding()
                    Spacer()
                }
            } else if userPosts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "leaf")
                        .font(.largeTitle)
                        .foregroundColor(.gray.opacity(0.5))
                    Text("No posts yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Share your first cleanup!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                // Show preview of first 3 posts
                ForEach(userPosts.prefix(3)) { post in
                    NavigationLink(destination: PostDetailView(post: post)) {
                        MyPostRow(post: post)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .onAppear {
            loadUserPosts()
        }
    }

    private func loadUserPosts() {
        guard let userId = userState.currentUser?.id else { return }
        isLoadingPosts = true

        Task {
            do {
                let posts = try await FirestoreService.shared.getUserPosts(userId: userId)
                await MainActor.run {
                    self.userPosts = posts
                    self.isLoadingPosts = false
                }
            } catch {
                await MainActor.run {
                    self.isLoadingPosts = false
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
            NavigationLink(destination: WalletView()) {
                HStack(spacing: 12) {
                    Image(systemName: "creditcard.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                        .frame(width: 30)
                    Text("Wallet & Payments")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            MenuItem(icon: "gift.fill", title: "Refer & Earn", color: .pink) {}
            MenuItem(icon: "questionmark.circle.fill", title: "Help & Support", color: .gray) {}
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Social Link Button

struct SocialLinkButton: View {
    let platform: SocialPlatform
    let username: String

    var body: some View {
        Button {
            if let url = platform.url(for: username) {
                UIApplication.shared.open(url)
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: platform.icon)
                    .font(.title2)
                    .foregroundColor(platform.color)

                Text(platform.displayName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 60)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Impact Stat Card

struct ImpactStatCard: View {
    let icon: String
    let value: String
    let unit: String
    let label: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Spacer()
            }

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.headline)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - My Post Row

struct MyPostRow: View {
    let post: Post

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail or placeholder
            if let imageURL = post.afterImageURL ?? post.beforeImageURL {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(ProgressView())
                }
                .frame(width: 60, height: 60)
                .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: "leaf.fill")
                            .foregroundColor(.green)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(post.description.isEmpty ? "Cleanup post" : post.description)
                    .font(.subheadline)
                    .lineLimit(2)

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up")
                            .font(.caption2)
                        Text("\(post.communityVotes)")
                            .font(.caption)
                    }
                    .foregroundColor(.orange)

                    HStack(spacing: 4) {
                        Image(systemName: "trash.fill")
                            .font(.caption2)
                        Text("\(String(format: "%.1f", post.wasteCollectedKg)) kg")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)

                    if post.tipsReceived > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "indianrupeesign.circle.fill")
                                .font(.caption2)
                            Text("₹\(post.tipsReceived)")
                                .font(.caption)
                        }
                        .foregroundColor(.green)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(post.createdAt.timeAgo())
                    .font(.caption2)
                    .foregroundColor(.secondary)

                if post.hasVideoProof {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - All User Posts View

struct AllUserPostsView: View {
    let posts: [Post]

    var body: some View {
        List(posts) { post in
            NavigationLink(destination: PostDetailView(post: post)) {
                MyPostRow(post: post)
            }
        }
        .listStyle(.plain)
        .navigationTitle("My Posts")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager.shared)
        .environmentObject(UserState.shared)
}
