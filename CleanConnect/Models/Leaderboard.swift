// Leaderboard.swift
// Leaderboard and ranking models

import Foundation

struct LeaderboardEntry: Codable, Identifiable {
    let id: String
    let userId: String
    var displayName: String
    var photoURL: String?
    var points: Int
    var level: String
    var rank: Int
    var totalPosts: Int?
    var totalWasteKg: Double?

    // Scope info (for local leaderboards)
    var state: String?
    var district: String?
    var city: String?
    var pincode: String?

    static let preview = LeaderboardEntry(
        id: "entry-1",
        userId: "user-1",
        displayName: "Rajesh Kumar",
        photoURL: nil,
        points: 5420,
        level: "Eco Champion",
        rank: 1,
        totalPosts: 87,
        totalWasteKg: 432.5,
        state: "Maharashtra",
        district: "Mumbai",
        city: nil,
        pincode: nil
    )
}

struct LeaderboardCache: Codable {
    var global: [LeaderboardEntry]
    var byState: [String: [LeaderboardEntry]]
    var byDistrict: [String: [LeaderboardEntry]]
    var lastUpdated: Date
}

// Campaign/Challenge model
struct Campaign: Codable, Identifiable {
    let id: String
    var title: String
    var description: String
    var hashtag: String
    var imageURL: String?
    var startDate: Date
    var endDate: Date
    var prizes: [CampaignPrize]?
    var participantsCount: Int
    var postsCount: Int
    var isActive: Bool
    var createdAt: Date

    static let preview = Campaign(
        id: "campaign-1",
        title: "Swachh Bharat Week",
        description: "Join the national cleanup drive and win exciting prizes!",
        hashtag: "#SwachhBharatWeek",
        imageURL: nil,
        startDate: Date(),
        endDate: Date().addingTimeInterval(86400 * 7),
        prizes: nil,
        participantsCount: 1250,
        postsCount: 3420,
        isActive: true,
        createdAt: Date()
    )
}

struct CampaignPrize: Codable, Identifiable {
    let id: String
    var rank: Int
    var title: String
    var description: String
    var value: Int?
}

// Squad/Team model
struct Squad: Codable, Identifiable {
    let id: String
    var name: String
    var description: String
    var imageURL: String?
    var leaderId: String
    var leaderName: String
    var memberCount: Int
    var totalPoints: Int
    var rank: Int?
    var isPublic: Bool
    var state: String?
    var district: String?
    var createdAt: Date

    static let preview = Squad(
        id: "squad-1",
        name: "Mumbai Green Warriors",
        description: "Making Mumbai cleaner, one street at a time!",
        imageURL: nil,
        leaderId: "user-1",
        leaderName: "Rajesh Kumar",
        memberCount: 25,
        totalPoints: 45000,
        rank: 3,
        isPublic: true,
        state: "Maharashtra",
        district: "Mumbai",
        createdAt: Date()
    )
}

struct SquadMember: Codable, Identifiable {
    let id: String
    let squadId: String
    let userId: String
    var displayName: String
    var photoURL: String?
    var role: MemberRole
    var contributedPoints: Int
    var joinedAt: Date

    enum MemberRole: String, Codable {
        case leader
        case admin
        case member
    }
}
