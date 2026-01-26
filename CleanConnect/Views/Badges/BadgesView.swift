// BadgesView.swift
// Comprehensive Badges system with earning logic - iOS 17+

import SwiftUI
import Observation

// MARK: - Badge Definition

struct BadgeDefinition: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let category: BadgeCategory
    let tier: BadgeTier
    let requirement: BadgeRequirement
    let pointsReward: Int

    enum BadgeCategory: String, Codable, CaseIterable {
        case cleanup = "Cleanup"
        case events = "Events"
        case community = "Community"
        case tips = "Tips"
        case streaks = "Streaks"
        case special = "Special"

        var color: Color {
            switch self {
            case .cleanup: return .green
            case .events: return .blue
            case .community: return .purple
            case .tips: return .orange
            case .streaks: return .red
            case .special: return .yellow
            }
        }

        var icon: String {
            switch self {
            case .cleanup: return "leaf.fill"
            case .events: return "calendar.badge.checkmark"
            case .community: return "person.3.fill"
            case .tips: return "indianrupeesign.circle.fill"
            case .streaks: return "flame.fill"
            case .special: return "star.fill"
            }
        }
    }

    enum BadgeTier: String, Codable, CaseIterable {
        case bronze = "Bronze"
        case silver = "Silver"
        case gold = "Gold"
        case platinum = "Platinum"
        case diamond = "Diamond"

        var color: Color {
            switch self {
            case .bronze: return Color(red: 0.8, green: 0.5, blue: 0.2)
            case .silver: return Color(red: 0.75, green: 0.75, blue: 0.75)
            case .gold: return Color(red: 1.0, green: 0.84, blue: 0.0)
            case .platinum: return Color(red: 0.9, green: 0.9, blue: 0.95)
            case .diamond: return Color(red: 0.7, green: 0.9, blue: 1.0)
            }
        }

        var glowColor: Color {
            switch self {
            case .bronze: return .orange
            case .silver: return .gray
            case .gold: return .yellow
            case .platinum: return .white
            case .diamond: return .cyan
            }
        }
    }

    struct BadgeRequirement: Codable {
        let type: RequirementType
        let value: Int

        enum RequirementType: String, Codable {
            case cleanups       // Number of cleanup posts
            case wasteKg        // Kg of waste collected
            case eventsAttended // Events attended
            case eventsOrganized // Events organized
            case tipsReceived   // Total tips received (₹)
            case tipsSent       // Total tips sent (₹)
            case tipCount       // Number of tips sent
            case followers      // Number of followers
            case streak         // Current streak days
            case videosVerified // Posts with video proof
            case areasImpacted  // Unique locations cleaned
            case volunteerHours // Total volunteer hours
            case level          // User level reached
            case special        // Special achievement (manually awarded)
        }
    }
}

// MARK: - User Badge (Earned)

struct UserBadge: Identifiable, Codable {
    let id: String
    let badgeId: String
    let userId: String
    var earnedAt: Date
    var progress: Double  // 0.0 to 1.0 for in-progress badges

    var isEarned: Bool { progress >= 1.0 }
}

// MARK: - Badge Store (All Available Badges)

struct BadgeStore {
    static let allBadges: [BadgeDefinition] = [
        // CLEANUP BADGES
        BadgeDefinition(
            id: "first_cleanup", name: "First Step", description: "Complete your first cleanup post",
            icon: "leaf", category: .cleanup, tier: .bronze,
            requirement: .init(type: .cleanups, value: 1), pointsReward: 50
        ),
        BadgeDefinition(
            id: "cleanup_10", name: "Getting Started", description: "Complete 10 cleanups",
            icon: "leaf.fill", category: .cleanup, tier: .bronze,
            requirement: .init(type: .cleanups, value: 10), pointsReward: 100
        ),
        BadgeDefinition(
            id: "cleanup_50", name: "Eco Warrior", description: "Complete 50 cleanups",
            icon: "leaf.circle", category: .cleanup, tier: .silver,
            requirement: .init(type: .cleanups, value: 50), pointsReward: 250
        ),
        BadgeDefinition(
            id: "cleanup_100", name: "Nature Guardian", description: "Complete 100 cleanups",
            icon: "leaf.circle.fill", category: .cleanup, tier: .gold,
            requirement: .init(type: .cleanups, value: 100), pointsReward: 500
        ),
        BadgeDefinition(
            id: "cleanup_500", name: "Earth Protector", description: "Complete 500 cleanups",
            icon: "globe.americas.fill", category: .cleanup, tier: .platinum,
            requirement: .init(type: .cleanups, value: 500), pointsReward: 1000
        ),
        BadgeDefinition(
            id: "waste_100kg", name: "Waste Warrior", description: "Collect 100kg of waste",
            icon: "trash", category: .cleanup, tier: .silver,
            requirement: .init(type: .wasteKg, value: 100), pointsReward: 200
        ),
        BadgeDefinition(
            id: "waste_500kg", name: "Trash Terminator", description: "Collect 500kg of waste",
            icon: "trash.fill", category: .cleanup, tier: .gold,
            requirement: .init(type: .wasteKg, value: 500), pointsReward: 500
        ),
        BadgeDefinition(
            id: "waste_1000kg", name: "Waste Crusher", description: "Collect 1000kg of waste",
            icon: "trash.circle.fill", category: .cleanup, tier: .platinum,
            requirement: .init(type: .wasteKg, value: 1000), pointsReward: 1000
        ),

        // EVENT BADGES
        BadgeDefinition(
            id: "event_first", name: "Team Player", description: "Attend your first event",
            icon: "person.2", category: .events, tier: .bronze,
            requirement: .init(type: .eventsAttended, value: 1), pointsReward: 50
        ),
        BadgeDefinition(
            id: "event_10", name: "Event Regular", description: "Attend 10 events",
            icon: "person.2.fill", category: .events, tier: .silver,
            requirement: .init(type: .eventsAttended, value: 10), pointsReward: 200
        ),
        BadgeDefinition(
            id: "event_50", name: "Event Veteran", description: "Attend 50 events",
            icon: "person.3.fill", category: .events, tier: .gold,
            requirement: .init(type: .eventsAttended, value: 50), pointsReward: 500
        ),
        BadgeDefinition(
            id: "organizer_first", name: "Event Starter", description: "Organize your first event",
            icon: "calendar.badge.plus", category: .events, tier: .silver,
            requirement: .init(type: .eventsOrganized, value: 1), pointsReward: 100
        ),
        BadgeDefinition(
            id: "organizer_10", name: "Community Leader", description: "Organize 10 events",
            icon: "crown", category: .events, tier: .gold,
            requirement: .init(type: .eventsOrganized, value: 10), pointsReward: 500
        ),
        BadgeDefinition(
            id: "organizer_50", name: "Movement Builder", description: "Organize 50 events",
            icon: "crown.fill", category: .events, tier: .platinum,
            requirement: .init(type: .eventsOrganized, value: 50), pointsReward: 1000
        ),

        // COMMUNITY BADGES
        BadgeDefinition(
            id: "followers_10", name: "Rising Star", description: "Gain 10 followers",
            icon: "star", category: .community, tier: .bronze,
            requirement: .init(type: .followers, value: 10), pointsReward: 50
        ),
        BadgeDefinition(
            id: "followers_100", name: "Eco Influencer", description: "Gain 100 followers",
            icon: "star.fill", category: .community, tier: .silver,
            requirement: .init(type: .followers, value: 100), pointsReward: 200
        ),
        BadgeDefinition(
            id: "followers_1000", name: "Green Celebrity", description: "Gain 1000 followers",
            icon: "star.circle.fill", category: .community, tier: .gold,
            requirement: .init(type: .followers, value: 1000), pointsReward: 500
        ),
        BadgeDefinition(
            id: "video_10", name: "Proof Provider", description: "Post 10 verified videos",
            icon: "video", category: .community, tier: .silver,
            requirement: .init(type: .videosVerified, value: 10), pointsReward: 150
        ),
        BadgeDefinition(
            id: "video_50", name: "Video Master", description: "Post 50 verified videos",
            icon: "video.fill", category: .community, tier: .gold,
            requirement: .init(type: .videosVerified, value: 50), pointsReward: 400
        ),
        BadgeDefinition(
            id: "areas_10", name: "Explorer", description: "Clean 10 different locations",
            icon: "map", category: .community, tier: .silver,
            requirement: .init(type: .areasImpacted, value: 10), pointsReward: 200
        ),
        BadgeDefinition(
            id: "areas_50", name: "Wanderer", description: "Clean 50 different locations",
            icon: "map.fill", category: .community, tier: .gold,
            requirement: .init(type: .areasImpacted, value: 50), pointsReward: 500
        ),

        // TIPS BADGES
        BadgeDefinition(
            id: "tips_received_500", name: "Appreciated", description: "Receive ₹500 in tips",
            icon: "gift", category: .tips, tier: .bronze,
            requirement: .init(type: .tipsReceived, value: 500), pointsReward: 50
        ),
        BadgeDefinition(
            id: "tips_received_5000", name: "Well Loved", description: "Receive ₹5000 in tips",
            icon: "gift.fill", category: .tips, tier: .silver,
            requirement: .init(type: .tipsReceived, value: 5000), pointsReward: 200
        ),
        BadgeDefinition(
            id: "tips_received_25000", name: "Community Favorite", description: "Receive ₹25000 in tips",
            icon: "gift.circle.fill", category: .tips, tier: .gold,
            requirement: .init(type: .tipsReceived, value: 25000), pointsReward: 500
        ),
        BadgeDefinition(
            id: "tips_sent_500", name: "Generous Soul", description: "Send ₹500 in tips",
            icon: "heart", category: .tips, tier: .bronze,
            requirement: .init(type: .tipsSent, value: 500), pointsReward: 100
        ),
        BadgeDefinition(
            id: "tips_sent_5000", name: "Big Supporter", description: "Send ₹5000 in tips",
            icon: "heart.fill", category: .tips, tier: .silver,
            requirement: .init(type: .tipsSent, value: 5000), pointsReward: 300
        ),
        BadgeDefinition(
            id: "tips_sent_25000", name: "Philanthropist", description: "Send ₹25000 in tips",
            icon: "heart.circle.fill", category: .tips, tier: .gold,
            requirement: .init(type: .tipsSent, value: 25000), pointsReward: 750
        ),
        BadgeDefinition(
            id: "tip_count_10", name: "First Supporter", description: "Send 10 tips",
            icon: "hand.thumbsup", category: .tips, tier: .bronze,
            requirement: .init(type: .tipCount, value: 10), pointsReward: 75
        ),
        BadgeDefinition(
            id: "tip_count_100", name: "Tip Master", description: "Send 100 tips",
            icon: "hand.thumbsup.fill", category: .tips, tier: .silver,
            requirement: .init(type: .tipCount, value: 100), pointsReward: 250
        ),

        // STREAK BADGES
        BadgeDefinition(
            id: "streak_7", name: "Week Warrior", description: "7-day activity streak",
            icon: "flame", category: .streaks, tier: .bronze,
            requirement: .init(type: .streak, value: 7), pointsReward: 100
        ),
        BadgeDefinition(
            id: "streak_30", name: "Month Master", description: "30-day activity streak",
            icon: "flame.fill", category: .streaks, tier: .silver,
            requirement: .init(type: .streak, value: 30), pointsReward: 300
        ),
        BadgeDefinition(
            id: "streak_100", name: "Centurion", description: "100-day activity streak",
            icon: "flame.circle", category: .streaks, tier: .gold,
            requirement: .init(type: .streak, value: 100), pointsReward: 750
        ),
        BadgeDefinition(
            id: "streak_365", name: "Year Legend", description: "365-day activity streak",
            icon: "flame.circle.fill", category: .streaks, tier: .diamond,
            requirement: .init(type: .streak, value: 365), pointsReward: 2000
        ),
        BadgeDefinition(
            id: "hours_50", name: "Dedicated", description: "50 hours of volunteering",
            icon: "clock", category: .streaks, tier: .silver,
            requirement: .init(type: .volunteerHours, value: 50), pointsReward: 200
        ),
        BadgeDefinition(
            id: "hours_200", name: "Time Giver", description: "200 hours of volunteering",
            icon: "clock.fill", category: .streaks, tier: .gold,
            requirement: .init(type: .volunteerHours, value: 200), pointsReward: 500
        ),

        // SPECIAL BADGES
        BadgeDefinition(
            id: "level_5", name: "Rising Eco", description: "Reach Level 5",
            icon: "arrow.up.circle", category: .special, tier: .silver,
            requirement: .init(type: .level, value: 5), pointsReward: 250
        ),
        BadgeDefinition(
            id: "level_10", name: "Eco Expert", description: "Reach Level 10",
            icon: "arrow.up.circle.fill", category: .special, tier: .gold,
            requirement: .init(type: .level, value: 10), pointsReward: 500
        ),
        BadgeDefinition(
            id: "early_adopter", name: "Early Adopter", description: "Joined during launch period",
            icon: "sparkles", category: .special, tier: .gold,
            requirement: .init(type: .special, value: 1), pointsReward: 500
        ),
        BadgeDefinition(
            id: "verified_user", name: "Verified", description: "Verified account",
            icon: "checkmark.seal.fill", category: .special, tier: .platinum,
            requirement: .init(type: .special, value: 1), pointsReward: 0
        ),
    ]

    static func badge(for id: String) -> BadgeDefinition? {
        allBadges.first { $0.id == id }
    }

    static func badges(for category: BadgeDefinition.BadgeCategory) -> [BadgeDefinition] {
        allBadges.filter { $0.category == category }
    }
}

// MARK: - Badges View Model

@MainActor
@Observable
class BadgesViewModel {
    var earnedBadges: [UserBadge] = []
    var inProgressBadges: [UserBadge] = []
    var selectedCategory: BadgeDefinition.BadgeCategory?
    var isLoading = false

    var filteredBadges: [BadgeDefinition] {
        guard let category = selectedCategory else { return BadgeStore.allBadges }
        return BadgeStore.badges(for: category)
    }

    var earnedCount: Int { earnedBadges.count }
    var totalCount: Int { BadgeStore.allBadges.count }

    func loadBadges() async {
        isLoading = true

        // Simulate loading user's badges
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Mock earned badges
        earnedBadges = [
            UserBadge(id: "ub1", badgeId: "first_cleanup", userId: "user1", earnedAt: Date().addingTimeInterval(-86400 * 30), progress: 1.0),
            UserBadge(id: "ub2", badgeId: "cleanup_10", userId: "user1", earnedAt: Date().addingTimeInterval(-86400 * 20), progress: 1.0),
            UserBadge(id: "ub3", badgeId: "event_first", userId: "user1", earnedAt: Date().addingTimeInterval(-86400 * 15), progress: 1.0),
            UserBadge(id: "ub4", badgeId: "streak_7", userId: "user1", earnedAt: Date().addingTimeInterval(-86400 * 10), progress: 1.0),
            UserBadge(id: "ub5", badgeId: "tips_received_500", userId: "user1", earnedAt: Date().addingTimeInterval(-86400 * 5), progress: 1.0),
            UserBadge(id: "ub6", badgeId: "followers_10", userId: "user1", earnedAt: Date().addingTimeInterval(-86400 * 3), progress: 1.0),
        ]

        // Mock in-progress badges
        inProgressBadges = [
            UserBadge(id: "ip1", badgeId: "cleanup_50", userId: "user1", earnedAt: Date(), progress: 0.5),
            UserBadge(id: "ip2", badgeId: "event_10", userId: "user1", earnedAt: Date(), progress: 0.3),
            UserBadge(id: "ip3", badgeId: "waste_100kg", userId: "user1", earnedAt: Date(), progress: 0.75),
            UserBadge(id: "ip4", badgeId: "streak_30", userId: "user1", earnedAt: Date(), progress: 0.47),
        ]

        isLoading = false
    }

    func isEarned(_ badgeId: String) -> Bool {
        earnedBadges.contains { $0.badgeId == badgeId }
    }

    func progress(for badgeId: String) -> Double? {
        if let inProgress = inProgressBadges.first(where: { $0.badgeId == badgeId }) {
            return inProgress.progress
        }
        if isEarned(badgeId) {
            return 1.0
        }
        return nil
    }

    func earnedDate(for badgeId: String) -> Date? {
        earnedBadges.first { $0.badgeId == badgeId }?.earnedAt
    }
}

// MARK: - Main Badges View

struct BadgesView: View {
    @State private var viewModel = BadgesViewModel()
    @State private var selectedBadge: BadgeDefinition?
    @Namespace private var animation

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Progress summary
                    progressSummary

                    // Category filter
                    categoryFilter

                    // Badges grid
                    badgesGrid
                }
                .padding()
            }
            .navigationTitle("Badges")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedBadge) { badge in
                BadgeDetailSheet(
                    badge: badge,
                    isEarned: viewModel.isEarned(badge.id),
                    progress: viewModel.progress(for: badge.id),
                    earnedDate: viewModel.earnedDate(for: badge.id)
                )
                .presentationDetents([.medium])
            }
            .task {
                await viewModel.loadBadges()
            }
        }
    }

    // MARK: - Progress Summary

    private var progressSummary: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(viewModel.earnedCount) / \(viewModel.totalCount)")
                        .font(.title.weight(.bold))
                    Text("Badges Earned")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Circular progress
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)

                    Circle()
                        .trim(from: 0, to: Double(viewModel.earnedCount) / Double(viewModel.totalCount))
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(Double(viewModel.earnedCount) / Double(viewModel.totalCount) * 100))%")
                        .font(.caption.weight(.bold))
                }
                .frame(width: 60, height: 60)
            }

            // In-progress badges
            if !viewModel.inProgressBadges.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Almost There!")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.inProgressBadges, id: \.id) { userBadge in
                                if let badge = BadgeStore.badge(for: userBadge.badgeId) {
                                    InProgressBadgeCard(badge: badge, progress: userBadge.progress)
                                        .onTapGesture { selectedBadge = badge }
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }

    // MARK: - Category Filter

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryButton(
                    title: "All",
                    icon: "square.grid.2x2.fill",
                    isSelected: viewModel.selectedCategory == nil,
                    color: .gray
                ) {
                    withAnimation { viewModel.selectedCategory = nil }
                }

                ForEach(BadgeDefinition.BadgeCategory.allCases, id: \.self) { category in
                    CategoryButton(
                        title: category.rawValue,
                        icon: category.icon,
                        isSelected: viewModel.selectedCategory == category,
                        color: category.color
                    ) {
                        withAnimation { viewModel.selectedCategory = category }
                    }
                }
            }
        }
    }

    // MARK: - Badges Grid

    private var badgesGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 16) {
            ForEach(viewModel.filteredBadges) { badge in
                BadgeCard(
                    badge: badge,
                    isEarned: viewModel.isEarned(badge.id),
                    progress: viewModel.progress(for: badge.id)
                )
                .onTapGesture { selectedBadge = badge }
            }
        }
    }
}

// MARK: - Category Button

struct CategoryButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption.weight(.medium))
            }
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color : color.opacity(0.15))
            .cornerRadius(20)
        }
    }
}

// MARK: - Badge Card

struct BadgeCard: View {
    let badge: BadgeDefinition
    let isEarned: Bool
    let progress: Double?

    var body: some View {
        VStack(spacing: 8) {
            // Badge icon
            ZStack {
                // Glow effect for earned badges
                if isEarned {
                    Circle()
                        .fill(badge.tier.glowColor.opacity(0.3))
                        .blur(radius: 8)
                }

                Circle()
                    .fill(
                        LinearGradient(
                            colors: isEarned
                                ? [badge.tier.color, badge.tier.color.opacity(0.7)]
                                : [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: badge.icon)
                            .font(.title3)
                            .foregroundColor(isEarned ? .white : .gray)
                    )
                    .overlay(
                        Circle()
                            .stroke(badge.tier.color.opacity(isEarned ? 0.5 : 0), lineWidth: 2)
                    )

                // Progress ring for in-progress
                if let progress = progress, progress < 1.0 {
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(badge.category.color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 64, height: 64)
                        .rotationEffect(.degrees(-90))
                }
            }

            // Name
            Text(badge.name)
                .font(.caption2.weight(.medium))
                .foregroundColor(isEarned ? .primary : .secondary)
                .lineLimit(1)
                .multilineTextAlignment(.center)

            // Tier indicator
            Text(badge.tier.rawValue)
                .font(.caption2)
                .foregroundColor(isEarned ? badge.tier.color : .gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: isEarned ? badge.tier.glowColor.opacity(0.2) : .clear, radius: 4)
        .opacity(isEarned ? 1.0 : 0.6)
    }
}

// MARK: - In-Progress Badge Card

struct InProgressBadgeCard: View {
    let badge: BadgeDefinition
    let progress: Double

    var body: some View {
        HStack(spacing: 10) {
            // Icon
            Circle()
                .fill(badge.category.color.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: badge.icon)
                        .font(.subheadline)
                        .foregroundColor(badge.category.color)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(badge.name)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)

                ProgressView(value: progress)
                    .tint(badge.category.color)

                Text("\(Int(progress * 100))% complete")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(10)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

// MARK: - Badge Detail Sheet

struct BadgeDetailSheet: View {
    let badge: BadgeDefinition
    let isEarned: Bool
    let progress: Double?
    let earnedDate: Date?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            // Badge display
            ZStack {
                // Background glow
                if isEarned {
                    Circle()
                        .fill(badge.tier.glowColor.opacity(0.3))
                        .frame(width: 140, height: 140)
                        .blur(radius: 20)
                }

                Circle()
                    .fill(
                        LinearGradient(
                            colors: isEarned
                                ? [badge.tier.color, badge.tier.color.opacity(0.6)]
                                : [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: badge.icon)
                            .font(.system(size: 40))
                            .foregroundColor(isEarned ? .white : .gray)
                    )
                    .shadow(color: badge.tier.glowColor.opacity(isEarned ? 0.5 : 0), radius: 10)
            }
            .padding(.top, 20)

            // Badge info
            VStack(spacing: 8) {
                Text(badge.name)
                    .font(.title2.weight(.bold))

                HStack(spacing: 8) {
                    // Tier
                    Text(badge.tier.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(badge.tier.color)
                        .cornerRadius(12)

                    // Category
                    Text(badge.category.rawValue)
                        .font(.caption.weight(.medium))
                        .foregroundColor(badge.category.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(badge.category.color.opacity(0.15))
                        .cornerRadius(12)
                }

                Text(badge.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Status
            if isEarned {
                VStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                    Text("Earned")
                        .font(.headline)
                        .foregroundColor(.green)
                    if let date = earnedDate {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            } else if let progress = progress {
                VStack(spacing: 8) {
                    ProgressView(value: progress)
                        .tint(badge.category.color)

                    Text("\(Int(progress * 100))% complete")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(badge.category.color)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(badge.category.color.opacity(0.1))
                .cornerRadius(12)
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                    Text("Locked")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text("+\(badge.pointsReward) points when earned")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }

            Spacer()
        }
        .padding()
    }
}

// Make BadgeDefinition Identifiable for sheet
extension BadgeDefinition: Equatable {
    static func == (lhs: BadgeDefinition, rhs: BadgeDefinition) -> Bool {
        lhs.id == rhs.id
    }
}

#Preview {
    BadgesView()
}
