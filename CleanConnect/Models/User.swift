// User.swift
// User model and related types

import Foundation

struct User: Codable, Identifiable {
    let id: String
    var displayName: String
    var email: String?
    var photoURL: String?
    var bio: String?
    var state: String?
    var district: String?
    var pincode: String?

    // Stats
    var totalPoints: Int
    var totalPosts: Int
    var totalWasteKg: Double
    var totalEventsOrganized: Int
    var totalEventsAttended: Int
    var tipsReceived: Int
    var tipsGiven: Int

    // Level system
    var level: Int
    var levelName: String

    // Social
    var karmaScore: Int
    var followersCount: Int
    var followingCount: Int

    // Badges
    var badges: [String]

    // Metadata
    var createdAt: Date
    var lastActive: Date?
    var isAnonymous: Bool
    var verified: Bool

    enum CodingKeys: String, CodingKey {
        case id, displayName, email, photoURL, bio, state, district, pincode
        case totalPoints, totalPosts, totalWasteKg
        case totalEventsOrganized, totalEventsAttended
        case tipsReceived, tipsGiven
        case level, levelName
        case karmaScore, followersCount, followingCount
        case badges, createdAt, lastActive, isAnonymous, verified
    }

    static let preview = User(
        id: "preview-user",
        displayName: "Test User",
        email: "test@example.com",
        photoURL: nil,
        bio: "Environmental enthusiast",
        state: "Maharashtra",
        district: "Mumbai",
        pincode: "400001",
        totalPoints: 1500,
        totalPosts: 25,
        totalWasteKg: 125.5,
        totalEventsOrganized: 3,
        totalEventsAttended: 10,
        tipsReceived: 500,
        tipsGiven: 200,
        level: 3,
        levelName: "Green Guardian",
        karmaScore: 45,
        followersCount: 150,
        followingCount: 80,
        badges: ["first_cleanup", "eco_warrior"],
        createdAt: Date(),
        lastActive: Date(),
        isAnonymous: false,
        verified: false
    )
}

// Experience levels matching web app
struct ExperienceLevel {
    let level: Int
    let name: String
    let minPoints: Int
    let maxPoints: Int

    static let all: [ExperienceLevel] = [
        ExperienceLevel(level: 1, name: "Eco Scout", minPoints: 0, maxPoints: 499),
        ExperienceLevel(level: 2, name: "Green Starter", minPoints: 500, maxPoints: 1499),
        ExperienceLevel(level: 3, name: "Green Guardian", minPoints: 1500, maxPoints: 2999),
        ExperienceLevel(level: 4, name: "Nature Defender", minPoints: 3000, maxPoints: 4999),
        ExperienceLevel(level: 5, name: "Eco Champion", minPoints: 5000, maxPoints: 7499),
        ExperienceLevel(level: 6, name: "Earth Keeper", minPoints: 7500, maxPoints: 9999),
        ExperienceLevel(level: 7, name: "Climate Hero", minPoints: 10000, maxPoints: 11999),
        ExperienceLevel(level: 8, name: "Planet Protector", minPoints: 12000, maxPoints: Int.max)
    ]

    static func level(for points: Int) -> ExperienceLevel {
        return all.first { points >= $0.minPoints && points <= $0.maxPoints } ?? all[0]
    }
}

struct Badge: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let emoji: String
    let criteria: String
    let pointsRequired: Int?
    let postsRequired: Int?
    let eventsRequired: Int?

    static let allBadges: [Badge] = [
        Badge(id: "first_step", name: "First Step", description: "Complete your first cleanup", emoji: "🌱", criteria: "first_cleanup", pointsRequired: nil, postsRequired: 1, eventsRequired: nil),
        Badge(id: "eco_warrior", name: "Eco Warrior", description: "Complete 10 cleanups", emoji: "🦸", criteria: "cleanups_10", pointsRequired: nil, postsRequired: 10, eventsRequired: nil),
        Badge(id: "community_leader", name: "Community Leader", description: "Organize 5 events", emoji: "👑", criteria: "events_5", pointsRequired: nil, postsRequired: nil, eventsRequired: 5),
        Badge(id: "waste_warrior", name: "Waste Warrior", description: "Collect 100kg of waste", emoji: "♻️", criteria: "waste_100kg", pointsRequired: nil, postsRequired: nil, eventsRequired: nil),
        Badge(id: "point_master", name: "Point Master", description: "Earn 5000 points", emoji: "⭐", criteria: "points_5000", pointsRequired: 5000, postsRequired: nil, eventsRequired: nil),
        Badge(id: "helper", name: "Generous Helper", description: "Tip others 10 times", emoji: "💝", criteria: "tips_given_10", pointsRequired: nil, postsRequired: nil, eventsRequired: nil),
        Badge(id: "influencer", name: "Eco Influencer", description: "Get 50 followers", emoji: "📢", criteria: "followers_50", pointsRequired: nil, postsRequired: nil, eventsRequired: nil),
        Badge(id: "streak_7", name: "Week Warrior", description: "7-day activity streak", emoji: "🔥", criteria: "streak_7", pointsRequired: nil, postsRequired: nil, eventsRequired: nil)
    ]
}

struct UserActivity: Identifiable {
    let id: String
    let type: ActivityType
    let title: String
    let description: String?
    let timestamp: Date
    let pointsEarned: Int?
    let relatedId: String?

    var icon: String {
        switch type {
        case .postCreated: return "leaf.fill"
        case .eventOrganized: return "calendar.badge.plus"
        case .eventAttended: return "person.2.fill"
        case .tipReceived: return "indianrupeesign.circle.fill"
        case .tipGiven: return "gift.fill"
        case .badgeEarned: return "medal.fill"
        case .levelUp: return "arrow.up.circle.fill"
        }
    }

    var color: Color {
        switch type {
        case .postCreated: return .green
        case .eventOrganized: return .blue
        case .eventAttended: return .purple
        case .tipReceived: return .orange
        case .tipGiven: return .pink
        case .badgeEarned: return .yellow
        case .levelUp: return .green
        }
    }

    enum ActivityType: String, Codable {
        case postCreated
        case eventOrganized
        case eventAttended
        case tipReceived
        case tipGiven
        case badgeEarned
        case levelUp
    }
}

import SwiftUI

extension UserActivity {
    static let preview = UserActivity(
        id: "1",
        type: .postCreated,
        title: "Created cleanup post",
        description: "Cleaned up local park",
        timestamp: Date().addingTimeInterval(-3600),
        pointsEarned: 50,
        relatedId: nil
    )
}
