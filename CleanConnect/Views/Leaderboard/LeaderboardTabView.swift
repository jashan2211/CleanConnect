// LeaderboardTabView.swift
// Main leaderboard tab with Givers and Earners rankings

import SwiftUI

struct LeaderboardTabView: View {
    @State private var selectedTab: LeaderboardType = .givers
    @State private var selectedScope: LeaderboardScope = .allIndia
    @State private var givers: [LeaderboardUser] = []
    @State private var earners: [LeaderboardUser] = []
    @State private var isLoading = false

    enum LeaderboardType: String, CaseIterable {
        case givers = "Top Givers"
        case earners = "Top Earners"

        var icon: String {
            switch self {
            case .givers: return "heart.fill"
            case .earners: return "star.fill"
            }
        }

        var color: Color {
            switch self {
            case .givers: return .pink
            case .earners: return .orange
            }
        }

        var description: String {
            switch self {
            case .givers: return "Users who give the most tips and event donations"
            case .earners: return "Users who earn the most from tips on their cleanups"
            }
        }
    }

    enum LeaderboardScope: String, CaseIterable {
        case allIndia = "All India"
        case myState = "My State"
        case myDistrict = "My District"

        var icon: String {
            switch self {
            case .allIndia: return "globe.asia.australia.fill"
            case .myState: return "map.fill"
            case .myDistrict: return "mappin.circle.fill"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Type selector
                typeSelector

                // Scope filter
                scopeFilter

                // Description
                Text(selectedTab.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                Divider()

                // Leaderboard content
                if isLoading {
                    loadingView
                } else {
                    leaderboardList
                }
            }
            .navigationTitle("Rankings")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await loadLeaderboards()
            }
            .refreshable {
                await loadLeaderboards()
            }
        }
    }

    // MARK: - Type Selector
    private var typeSelector: some View {
        HStack(spacing: 0) {
            ForEach(LeaderboardType.allCases, id: \.self) { type in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = type
                    }
                } label: {
                    VStack(spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: type.icon)
                                .font(.title3)
                            Text(type.rawValue)
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundColor(selectedTab == type ? type.color : .secondary)

                        Rectangle()
                            .fill(selectedTab == type ? type.color : .clear)
                            .frame(height: 3)
                            .cornerRadius(1.5)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Scope Filter
    private var scopeFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(LeaderboardScope.allCases, id: \.self) { scope in
                    Button {
                        selectedScope = scope
                        Task { await loadLeaderboards() }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: scope.icon)
                                .font(.caption2)
                            Text(scope.rawValue)
                                .font(.caption.weight(.medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(selectedScope == scope ? selectedTab.color : Color(.systemGray6))
                        .foregroundColor(selectedScope == scope ? .white : .primary)
                        .cornerRadius(16)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading rankings...")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    // MARK: - Leaderboard List
    private var leaderboardList: some View {
        let users = selectedTab == .givers ? givers : earners

        return ScrollView {
            LazyVStack(spacing: 0) {
                if users.isEmpty {
                    emptyState
                } else {
                    // Top 3 podium
                    if users.count >= 3 {
                        podiumView(users: Array(users.prefix(3)))
                            .padding(.vertical)
                    }

                    // Full list (or remaining after podium)
                    let startIndex = users.count >= 3 ? 3 : 0
                    ForEach(Array(users.dropFirst(startIndex).enumerated()), id: \.element.id) { index, user in
                        RankingRow(
                            user: user,
                            rank: index + startIndex + 1,
                            type: selectedTab
                        )
                        Divider()
                            .padding(.leading, 70)
                    }
                }
            }
        }
    }

    // MARK: - Podium View
    private func podiumView(users: [LeaderboardUser]) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            // 2nd place
            if users.count > 1 {
                podiumCard(user: users[1], rank: 2, height: 100)
            }

            // 1st place
            if users.count > 0 {
                podiumCard(user: users[0], rank: 1, height: 130)
            }

            // 3rd place
            if users.count > 2 {
                podiumCard(user: users[2], rank: 3, height: 80)
            }
        }
        .padding(.horizontal)
    }

    private func podiumCard(user: LeaderboardUser, rank: Int, height: CGFloat) -> some View {
        VStack(spacing: 8) {
            // Avatar
            ZStack {
                Circle()
                    .fill(rankColor(rank).opacity(0.2))
                    .frame(width: rank == 1 ? 70 : 56, height: rank == 1 ? 70 : 56)

                if let photoURL = user.photoURL, let url = URL(string: photoURL) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Image(systemName: "person.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    .frame(width: rank == 1 ? 60 : 48, height: rank == 1 ? 60 : 48)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .font(rank == 1 ? .title : .title2)
                        .foregroundColor(.gray)
                }

                // Rank badge
                Text("\(rank)")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .frame(width: 22, height: 22)
                    .background(rankColor(rank))
                    .clipShape(Circle())
                    .offset(x: rank == 1 ? 25 : 20, y: rank == 1 ? 25 : 20)
            }

            // Name
            Text(user.displayName)
                .font(.caption.weight(.semibold))
                .lineLimit(1)

            // Amount
            Text(selectedTab == .givers ? "₹\(user.totalGiven)" : "₹\(user.totalEarned)")
                .font(.subheadline.bold())
                .foregroundColor(selectedTab.color)

            // Podium base
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [rankColor(rank), rankColor(rank).opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: height)
                .overlay(
                    Text(rank == 1 ? "1ST" : (rank == 2 ? "2ND" : "3RD"))
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.top, 8),
                    alignment: .top
                )
        }
        .frame(maxWidth: .infinity)
    }

    private func rankColor(_ rank: Int) -> Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .blue
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: selectedTab == .givers ? "heart.slash" : "star.slash")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("No rankings yet")
                .font(.headline)
            Text("Be the first to \(selectedTab == .givers ? "give tips and donate to events" : "earn tips from your cleanups")!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }

    // MARK: - Load Data
    private func loadLeaderboards() async {
        isLoading = true
        defer { isLoading = false }

        do {
            var users = try await UserService.shared.getAllUsers()

            // Filter by scope
            switch selectedScope {
            case .myState:
                if let state = UserState.shared.currentUser?.state {
                    users = users.filter { $0.state == state }
                }
            case .myDistrict:
                if let district = UserState.shared.currentUser?.district {
                    users = users.filter { $0.district == district }
                }
            case .allIndia:
                break
            }

            // Sort for givers (tips given + event donations)
            let sortedGivers = users.sorted {
                ($0.tipsGiven + $0.totalDonationsAmount) > ($1.tipsGiven + $1.totalDonationsAmount)
            }

            // Sort for earners (tips received)
            let sortedEarners = users.sorted { $0.tipsReceived > $1.tipsReceived }

            await MainActor.run {
                givers = sortedGivers.prefix(50).map { user in
                    LeaderboardUser(
                        id: user.id,
                        displayName: user.displayName,
                        photoURL: user.photoURL,
                        totalGiven: user.tipsGiven + user.totalDonationsAmount,
                        totalEarned: user.tipsReceived,
                        totalPosts: user.totalPosts,
                        state: user.state,
                        district: user.district
                    )
                }

                earners = sortedEarners.prefix(50).map { user in
                    LeaderboardUser(
                        id: user.id,
                        displayName: user.displayName,
                        photoURL: user.photoURL,
                        totalGiven: user.tipsGiven + user.totalDonationsAmount,
                        totalEarned: user.tipsReceived,
                        totalPosts: user.totalPosts,
                        state: user.state,
                        district: user.district
                    )
                }
            }
        } catch {
            // Show empty state on error
            await MainActor.run {
                givers = []
                earners = []
            }
        }
    }
}

// MARK: - Leaderboard User Model
struct LeaderboardUser: Identifiable {
    let id: String
    let displayName: String
    let photoURL: String?
    let totalGiven: Int
    let totalEarned: Int
    let totalPosts: Int
    let state: String?
    let district: String?

    static let sampleGivers: [LeaderboardUser] = [
        LeaderboardUser(id: "1", displayName: "Aditya Sharma", photoURL: nil, totalGiven: 15420, totalEarned: 2100, totalPosts: 45, state: "Maharashtra", district: "Mumbai"),
        LeaderboardUser(id: "2", displayName: "Priya Patel", photoURL: nil, totalGiven: 12850, totalEarned: 1800, totalPosts: 38, state: "Gujarat", district: "Ahmedabad"),
        LeaderboardUser(id: "3", displayName: "Vikram Singh", photoURL: nil, totalGiven: 10200, totalEarned: 950, totalPosts: 28, state: "Delhi", district: "South Delhi"),
        LeaderboardUser(id: "4", displayName: "Ananya Reddy", photoURL: nil, totalGiven: 8500, totalEarned: 1200, totalPosts: 52, state: "Telangana", district: "Hyderabad"),
        LeaderboardUser(id: "5", displayName: "Rahul Kumar", photoURL: nil, totalGiven: 7200, totalEarned: 800, totalPosts: 35, state: "Karnataka", district: "Bengaluru"),
    ]

    static let sampleEarners: [LeaderboardUser] = [
        LeaderboardUser(id: "6", displayName: "Sneha Iyer", photoURL: nil, totalGiven: 500, totalEarned: 18500, totalPosts: 120, state: "Tamil Nadu", district: "Chennai"),
        LeaderboardUser(id: "7", displayName: "Arjun Nair", photoURL: nil, totalGiven: 800, totalEarned: 15200, totalPosts: 98, state: "Kerala", district: "Kochi"),
        LeaderboardUser(id: "8", displayName: "Kavya Menon", photoURL: nil, totalGiven: 1200, totalEarned: 12800, totalPosts: 87, state: "Maharashtra", district: "Pune"),
        LeaderboardUser(id: "9", displayName: "Rohan Joshi", photoURL: nil, totalGiven: 600, totalEarned: 11500, totalPosts: 76, state: "Rajasthan", district: "Jaipur"),
        LeaderboardUser(id: "10", displayName: "Neha Gupta", photoURL: nil, totalGiven: 950, totalEarned: 9800, totalPosts: 65, state: "Uttar Pradesh", district: "Lucknow"),
    ]
}

// MARK: - Ranking Row
struct RankingRow: View {
    let user: LeaderboardUser
    let rank: Int
    let type: LeaderboardTabView.LeaderboardType

    var body: some View {
        HStack(spacing: 12) {
            // Rank
            Text("#\(rank)")
                .font(.subheadline.weight(.bold))
                .foregroundColor(.secondary)
                .frame(width: 36)

            // Avatar
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 44, height: 44)

                if let photoURL = user.photoURL, let url = URL(string: photoURL) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .foregroundColor(.gray)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName)
                    .font(.subheadline.weight(.medium))

                HStack(spacing: 8) {
                    Label("\(user.totalPosts)", systemImage: "leaf.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    if let state = user.state {
                        Text(state)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Amount
            VStack(alignment: .trailing, spacing: 2) {
                Text("₹\(type == .givers ? user.totalGiven : user.totalEarned)")
                    .font(.subheadline.bold())
                    .foregroundColor(type.color)

                Text(type == .givers ? "given" : "earned")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}

#Preview {
    LeaderboardTabView()
}
