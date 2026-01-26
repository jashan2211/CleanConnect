// CleanupJob.swift
// Map-based cleanup job model - 2026

import Foundation
import CoreLocation

// MARK: - Cleanup Job Model

struct CleanupJob: Codable, Identifiable, Equatable {
    let id: String
    let creatorId: String
    let creatorName: String
    let creatorPhotoURL: String?

    // Job details
    var title: String
    var description: String
    var category: JobCategory
    var difficulty: JobDifficulty
    var estimatedTime: Int // in minutes

    // Location
    var latitude: Double
    var longitude: Double
    var address: String?
    var district: String
    var state: String

    // Rewards
    var pointsReward: Int
    var tipReward: Int? // Optional tip from creator

    // Status
    var status: JobStatus
    var claimedBy: String?
    var claimedByName: String?
    var claimedAt: Date?
    var completedAt: Date?
    var verifiedAt: Date?

    // Proof
    var proofPostId: String? // Link to the proof post in feed
    var proofPhotoURL: String?
    var proofVideoURL: String? // YouTube URL

    // Metadata
    var createdAt: Date
    var expiresAt: Date?
    var viewCount: Int
    var claimCount: Int // How many times it's been claimed (some might abandon)

    // Computed
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var isExpired: Bool {
        if let expires = expiresAt {
            return Date() > expires
        }
        return false
    }

    var isAvailable: Bool {
        status == .open && !isExpired
    }

    enum JobCategory: String, Codable, CaseIterable {
        case litter = "Litter Pickup"
        case graffiti = "Graffiti Removal"
        case greenery = "Plant/Garden Care"
        case drain = "Drain Cleaning"
        case beach = "Beach Cleanup"
        case roadside = "Roadside Cleanup"
        case park = "Park Maintenance"
        case other = "Other"

        var icon: String {
            switch self {
            case .litter: return "trash.fill"
            case .graffiti: return "paintbrush.fill"
            case .greenery: return "leaf.fill"
            case .drain: return "drop.fill"
            case .beach: return "water.waves"
            case .roadside: return "road.lanes"
            case .park: return "tree.fill"
            case .other: return "wrench.fill"
            }
        }

        var color: String {
            switch self {
            case .litter: return "orange"
            case .graffiti: return "purple"
            case .greenery: return "green"
            case .drain: return "blue"
            case .beach: return "cyan"
            case .roadside: return "gray"
            case .park: return "mint"
            case .other: return "brown"
            }
        }
    }

    enum JobDifficulty: String, Codable, CaseIterable {
        case easy = "Easy"
        case medium = "Medium"
        case hard = "Hard"

        var pointsMultiplier: Double {
            switch self {
            case .easy: return 1.0
            case .medium: return 1.5
            case .hard: return 2.0
            }
        }

        var color: String {
            switch self {
            case .easy: return "green"
            case .medium: return "orange"
            case .hard: return "red"
            }
        }
    }

    enum JobStatus: String, Codable {
        case open = "Open"
        case claimed = "Claimed"
        case inProgress = "In Progress"
        case proofSubmitted = "Proof Submitted"
        case verified = "Verified"
        case completed = "Completed"
        case expired = "Expired"
        case cancelled = "Cancelled"
    }

    static let preview = CleanupJob(
        id: "job-preview-1",
        creatorId: "user-1",
        creatorName: "Rahul Sharma",
        creatorPhotoURL: nil,
        title: "Litter near bus stop",
        description: "There's a lot of plastic waste accumulated near the Andheri West bus stop. Needs someone to clean it up.",
        category: .litter,
        difficulty: .easy,
        estimatedTime: 30,
        latitude: 19.1196,
        longitude: 72.8464,
        address: "Near Andheri West Bus Stop",
        district: "Mumbai",
        state: "Maharashtra",
        pointsReward: 50,
        tipReward: 100,
        status: .open,
        claimedBy: nil,
        claimedByName: nil,
        claimedAt: nil,
        completedAt: nil,
        verifiedAt: nil,
        proofPostId: nil,
        proofPhotoURL: nil,
        proofVideoURL: nil,
        createdAt: Date(),
        expiresAt: Date().addingTimeInterval(86400 * 7),
        viewCount: 24,
        claimCount: 0
    )
}

// MARK: - Job Application/Claim

struct JobClaim: Codable, Identifiable {
    let id: String
    let jobId: String
    let userId: String
    let userName: String
    let userPhotoURL: String?
    var status: ClaimStatus
    var note: String?
    var createdAt: Date
    var completedAt: Date?

    enum ClaimStatus: String, Codable {
        case active
        case completed
        case abandoned
        case rejected
    }
}

// MARK: - Job Proof Submission

struct JobProof: Codable, Identifiable {
    let id: String
    let jobId: String
    let userId: String
    let userName: String

    var photoURLs: [String]
    var videoURL: String? // YouTube URL
    var description: String?
    var beforePhotoURL: String?
    var afterPhotoURL: String?

    var status: ProofStatus
    var submittedAt: Date
    var reviewedAt: Date?
    var reviewedBy: String?
    var rejectionReason: String?

    enum ProofStatus: String, Codable {
        case pending = "Pending Review"
        case approved = "Approved"
        case rejected = "Rejected"
    }
}

// MARK: - Job Filter

struct JobFilter {
    var categories: Set<CleanupJob.JobCategory> = []
    var difficulties: Set<CleanupJob.JobDifficulty> = []
    var maxDistance: Double? = nil // in km
    var minPoints: Int? = nil
    var onlyWithTips: Bool = false
    var showCompleted: Bool = false
}

// MARK: - Job Stats

struct JobStats: Codable {
    var totalJobsCreated: Int
    var totalJobsCompleted: Int
    var totalPointsEarned: Int
    var totalTipsEarned: Int
    var currentStreak: Int
    var longestStreak: Int
    var favoriteCategory: String?

    static let empty = JobStats(
        totalJobsCreated: 0,
        totalJobsCompleted: 0,
        totalPointsEarned: 0,
        totalTipsEarned: 0,
        currentStreak: 0,
        longestStreak: 0,
        favoriteCategory: nil
    )
}
