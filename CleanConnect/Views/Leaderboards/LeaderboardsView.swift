// LeaderboardsView.swift
// Leaderboards for tips received and sent - iOS 17+ optimized

import SwiftUI
import Observation

// MARK: - Leaderboard Entry Model

struct TipsLeaderboardEntry: Identifiable, Codable {
    let id: String
    let rank: Int
    let userId: String
    let userName: String
    let userPhotoURL: String?
    let amount: Int
    let count: Int  // Number of tips
    let level: Int
    let verified: Bool
    let trend: TrendDirection

    enum TrendDirection: String, Codable {
        case up, down, stable

        var icon: String {
            switch self {
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            case .stable: return "minus"
            }
        }

        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .stable: return .secondary
            }
        }
    }
}

// MARK: - Leaderboard View Model

@MainActor
@Observable
class TipsLeaderboardViewModel {
    var tipsReceivedLeaderboard: [TipsLeaderboardEntry] = []
    var tipsSentLeaderboard: [TipsLeaderboardEntry] = []
    var timeFilter: TimeFilter = .allTime
    var regionFilter: RegionFilter = .national
    var isLoading = false
    var currentUserRankReceived: Int?
    var currentUserRankSent: Int?

    enum TimeFilter: String, CaseIterable {
        case week = "This Week"
        case month = "This Month"
        case allTime = "All Time"

        var icon: String {
            switch self {
            case .week: return "calendar.badge.clock"
            case .month: return "calendar"
            case .allTime: return "infinity"
            }
        }
    }

    enum RegionFilter: String, CaseIterable {
        case local = "My City"
        case state = "My State"
        case national = "National"

        var icon: String {
            switch self {
            case .local: return "building.2"
            case .state: return "map"
            case .national: return "flag"
            }
        }
    }

    func loadLeaderboards() async {
        isLoading = true

        // Simulate API call
        try? await Task.sleep(nanoseconds: 800_000_000)

        // Mock data - Tips Received (Creators)
        tipsReceivedLeaderboard = [
            TipsLeaderboardEntry(id: "1", rank: 1, userId: "u1", userName: "Aarav Sharma", userPhotoURL: nil, amount: 15750, count: 89, level: 7, verified: true, trend: .up),
            TipsLeaderboardEntry(id: "2", rank: 2, userId: "u2", userName: "Priya Patel", userPhotoURL: nil, amount: 12400, count: 67, level: 6, verified: true, trend: .stable),
            TipsLeaderboardEntry(id: "3", rank: 3, userId: "u3", userName: "Rohan Gupta", userPhotoURL: nil, amount: 9800, count: 54, level: 5, verified: true, trend: .up),
            TipsLeaderboardEntry(id: "4", rank: 4, userId: "u4", userName: "Sneha Reddy", userPhotoURL: nil, amount: 8500, count: 48, level: 5, verified: false, trend: .down),
            TipsLeaderboardEntry(id: "5", rank: 5, userId: "u5", userName: "Vikram Singh", userPhotoURL: nil, amount: 7200, count: 42, level: 4, verified: true, trend: .up),
            TipsLeaderboardEntry(id: "6", rank: 6, userId: "u6", userName: "Ananya Iyer", userPhotoURL: nil, amount: 6100, count: 38, level: 4, verified: true, trend: .stable),
            TipsLeaderboardEntry(id: "7", rank: 7, userId: "u7", userName: "Karthik Nair", userPhotoURL: nil, amount: 5400, count: 31, level: 4, verified: false, trend: .down),
            TipsLeaderboardEntry(id: "8", rank: 8, userId: "u8", userName: "Meera Joshi", userPhotoURL: nil, amount: 4800, count: 28, level: 3, verified: true, trend: .up),
            TipsLeaderboardEntry(id: "9", rank: 9, userId: "u9", userName: "Arjun Kapoor", userPhotoURL: nil, amount: 4200, count: 25, level: 3, verified: false, trend: .stable),
            TipsLeaderboardEntry(id: "10", rank: 10, userId: "u10", userName: "Diya Menon", userPhotoURL: nil, amount: 3600, count: 22, level: 3, verified: true, trend: .up),
        ]

        // Mock data - Tips Sent (Supporters)
        tipsSentLeaderboard = [
            TipsLeaderboardEntry(id: "s1", rank: 1, userId: "s1", userName: "Rajesh Kumar", userPhotoURL: nil, amount: 25000, count: 156, level: 8, verified: true, trend: .up),
            TipsLeaderboardEntry(id: "s2", rank: 2, userId: "s2", userName: "Sunita Devi", userPhotoURL: nil, amount: 18500, count: 124, level: 7, verified: true, trend: .up),
            TipsLeaderboardEntry(id: "s3", rank: 3, userId: "s3", userName: "Amit Verma", userPhotoURL: nil, amount: 14200, count: 98, level: 6, verified: false, trend: .stable),
            TipsLeaderboardEntry(id: "s4", rank: 4, userId: "s4", userName: "Neha Sharma", userPhotoURL: nil, amount: 11800, count: 87, level: 6, verified: true, trend: .down),
            TipsLeaderboardEntry(id: "s5", rank: 5, userId: "s5", userName: "Sanjay Mehta", userPhotoURL: nil, amount: 9500, count: 72, level: 5, verified: true, trend: .up),
            TipsLeaderboardEntry(id: "s6", rank: 6, userId: "s6", userName: "Pooja Rao", userPhotoURL: nil, amount: 8200, count: 65, level: 5, verified: true, trend: .stable),
            TipsLeaderboardEntry(id: "s7", rank: 7, userId: "s7", userName: "Vivek Jain", userPhotoURL: nil, amount: 7100, count: 58, level: 4, verified: false, trend: .up),
            TipsLeaderboardEntry(id: "s8", rank: 8, userId: "s8", userName: "Kavita Singh", userPhotoURL: nil, amount: 6300, count: 51, level: 4, verified: true, trend: .down),
            TipsLeaderboardEntry(id: "s9", rank: 9, userId: "s9", userName: "Rahul Khanna", userPhotoURL: nil, amount: 5500, count: 44, level: 4, verified: true, trend: .stable),
            TipsLeaderboardEntry(id: "s10", rank: 10, userId: "s10", userName: "Anjali Desai", userPhotoURL: nil, amount: 4800, count: 38, level: 3, verified: true, trend: .up),
        ]

        // Set current user rank (mock)
        currentUserRankReceived = 42
        currentUserRankSent = 28

        isLoading = false
    }
}

// MARK: - Main Leaderboards View

struct LeaderboardsView: View {
    @State private var viewModel = TipsLeaderboardViewModel()
    @State private var selectedTab: LeaderboardTab = .received
    @Namespace private var animation

    enum LeaderboardTab: String, CaseIterable {
        case received = "Top Earners"
        case sent = "Top Supporters"

        var icon: String {
            switch self {
            case .received: return "arrow.down.circle.fill"
            case .sent: return "arrow.up.circle.fill"
            }
        }

        var description: String {
            switch self {
            case .received: return "Users who received the most tips"
            case .sent: return "Users who sent the most tips"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab selector
                tabSelector

                // Filters
                filterBar

                // Content
                if viewModel.isLoading {
                    loadingView
                } else {
                    leaderboardList
                }
            }
            .navigationTitle("Leaderboards")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.loadLeaderboards() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task {
                await viewModel.loadLeaderboards()
            }
        }
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(LeaderboardTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.subheadline)
                            Text(tab.rawValue)
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundColor(selectedTab == tab ? .white : .primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background {
                            if selectedTab == tab {
                                Capsule()
                                    .fill(tab == .received ? Color.green : Color.orange)
                                    .matchedGeometryEffect(id: "tab", in: animation)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.gray.opacity(0.1))
        .clipShape(Capsule())
        .padding()
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Time filter
                Menu {
                    ForEach(TipsLeaderboardViewModel.TimeFilter.allCases, id: \.self) { filter in
                        Button {
                            viewModel.timeFilter = filter
                            Task { await viewModel.loadLeaderboards() }
                        } label: {
                            Label(filter.rawValue, systemImage: filter.icon)
                        }
                    }
                } label: {
                    FilterChipView(
                        icon: viewModel.timeFilter.icon,
                        text: viewModel.timeFilter.rawValue
                    )
                }

                // Region filter
                Menu {
                    ForEach(TipsLeaderboardViewModel.RegionFilter.allCases, id: \.self) { filter in
                        Button {
                            viewModel.regionFilter = filter
                            Task { await viewModel.loadLeaderboards() }
                        } label: {
                            Label(filter.rawValue, systemImage: filter.icon)
                        }
                    }
                } label: {
                    FilterChipView(
                        icon: viewModel.regionFilter.icon,
                        text: viewModel.regionFilter.rawValue
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 8)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading leaderboard...")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    // MARK: - Leaderboard List

    private var leaderboardList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Your rank card
                yourRankCard
                    .padding()

                // Description
                Text(selectedTab.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                // Top 3 podium
                podiumView
                    .padding(.bottom, 16)

                // Rest of the list
                ForEach(currentLeaderboard.dropFirst(3)) { entry in
                    LeaderboardRowView(entry: entry, accentColor: accentColor)

                    if entry.id != currentLeaderboard.last?.id {
                        Divider()
                            .padding(.leading, 70)
                    }
                }
            }
            .padding(.bottom, 100)
        }
    }

    // MARK: - Your Rank Card

    private var yourRankCard: some View {
        let rank = selectedTab == .received ? viewModel.currentUserRankReceived : viewModel.currentUserRankSent

        return HStack(spacing: 16) {
            // Rank
            VStack(spacing: 2) {
                Text("#\(rank ?? 0)")
                    .font(.title2.weight(.bold))
                    .foregroundColor(accentColor)
                Text("Your Rank")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 70)

            Divider()
                .frame(height: 40)

            // Stats
            VStack(alignment: .leading, spacing: 4) {
                Text("Keep going!")
                    .font(.subheadline.weight(.semibold))
                Text(selectedTab == .received
                     ? "Create more verified posts to earn tips"
                     : "Support cleaners to climb the ranks")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(accentColor.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accentColor.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Podium View

    private var podiumView: some View {
        let top3 = Array(currentLeaderboard.prefix(3))
        guard top3.count >= 3 else { return AnyView(EmptyView()) }

        return AnyView(
            HStack(alignment: .bottom, spacing: 8) {
                // 2nd place
                PodiumEntryView(entry: top3[1], place: 2, color: .gray, height: 90)

                // 1st place
                PodiumEntryView(entry: top3[0], place: 1, color: .yellow, height: 110)

                // 3rd place
                PodiumEntryView(entry: top3[2], place: 3, color: .orange.opacity(0.7), height: 70)
            }
            .padding(.horizontal, 24)
        )
    }

    // MARK: - Helpers

    private var currentLeaderboard: [TipsLeaderboardEntry] {
        selectedTab == .received ? viewModel.tipsReceivedLeaderboard : viewModel.tipsSentLeaderboard
    }

    private var accentColor: Color {
        selectedTab == .received ? .green : .orange
    }
}

// MARK: - Podium Entry View

struct PodiumEntryView: View {
    let entry: TipsLeaderboardEntry
    let place: Int
    let color: Color
    let height: CGFloat

    var body: some View {
        VStack(spacing: 8) {
            // Avatar
            ZStack(alignment: .bottom) {
                AsyncImage(url: URL(string: entry.userPhotoURL ?? "")) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            Text(String(entry.userName.prefix(1)))
                                .font(.title2.weight(.bold))
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: place == 1 ? 70 : 56, height: place == 1 ? 70 : 56)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(color, lineWidth: place == 1 ? 4 : 3)
                )

                // Crown for #1
                if place == 1 {
                    Image(systemName: "crown.fill")
                        .font(.title3)
                        .foregroundColor(.yellow)
                        .offset(y: -50)
                }
            }

            // Name
            Text(entry.userName.components(separatedBy: " ").first ?? "")
                .font(.caption.weight(.semibold))
                .lineLimit(1)

            // Amount
            Text("₹\(entry.amount)")
                .font(.caption2.weight(.bold))
                .foregroundColor(color == .yellow ? .orange : color)

            // Podium
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.8), color.opacity(0.4)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: height)
                .overlay(
                    Text("\(place)")
                        .font(.title.weight(.bold))
                        .foregroundColor(.white.opacity(0.8))
                )
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Leaderboard Row View

struct LeaderboardRowView: View {
    let entry: TipsLeaderboardEntry
    let accentColor: Color

    var body: some View {
        HStack(spacing: 12) {
            // Rank
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 36, height: 36)

                Text("\(entry.rank)")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.secondary)
            }

            // Avatar
            AsyncImage(url: URL(string: entry.userPhotoURL ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        Text(String(entry.userName.prefix(1)))
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())

            // Info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(entry.userName)
                        .font(.subheadline.weight(.semibold))

                    if entry.verified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }

                HStack(spacing: 8) {
                    Text("Lv.\(entry.level)")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text("•")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text("\(entry.count) tips")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Amount & Trend
            VStack(alignment: .trailing, spacing: 2) {
                Text("₹\(entry.amount)")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(accentColor)

                HStack(spacing: 2) {
                    Image(systemName: entry.trend.icon)
                        .font(.caption2)
                    Text(entry.trend == .up ? "Rising" : entry.trend == .down ? "Falling" : "Stable")
                        .font(.caption2)
                }
                .foregroundColor(entry.trend.color)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}

// MARK: - Filter Chip View

struct FilterChipView: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption.weight(.medium))
            Image(systemName: "chevron.down")
                .font(.caption2)
        }
        .foregroundColor(.primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(20)
    }
}

#Preview {
    LeaderboardsView()
}
