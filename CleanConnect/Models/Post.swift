// Post.swift
// Cleanup post model

import Foundation

struct Post: Codable, Identifiable {
    let id: String
    let userId: String
    let userName: String
    let userPhotoURL: String?

    // Content
    var description: String
    var beforeImageURL: String?
    var afterImageURL: String?
    var videoProofURL: String?         // YouTube/Instagram link for video proof

    // Stats
    var wasteCollectedKg: Double
    var durationMinutes: Int?
    var pointsEarned: Int

    // Location
    var state: String
    var district: String
    var pincode: String?
    var latitude: Double?
    var longitude: Double?
    var address: String?

    // Engagement
    var likes: Int
    var comments: Int
    var shares: Int
    var tipsReceived: Int

    // Verification Status
    var verified: Bool                 // Has video proof
    var verificationScore: Double?     // AI confidence score (0-1)
    var communityVotes: Int            // Upvotes from community
    var communityDownvotes: Int        // Downvotes (flagged as fake)
    var hasVideoProof: Bool            // Quick check for video
    var aiVerificationStatus: AIVerificationStatus  // AI analysis result
    var isLiked: Bool

    // Metadata
    var createdAt: Date
    var updatedAt: Date?

    // Tags
    var hashtags: [String]?
    var campaignId: String?

    enum CodingKeys: String, CodingKey {
        case id, userId, userName, userPhotoURL
        case description, beforeImageURL, afterImageURL, videoProofURL
        case wasteCollectedKg, durationMinutes, pointsEarned
        case state, district, pincode, latitude, longitude, address
        case likes, comments, shares, tipsReceived
        case verified, verificationScore, communityVotes, communityDownvotes
        case hasVideoProof, aiVerificationStatus, isLiked
        case createdAt, updatedAt
        case hashtags, campaignId
    }

    // Computed property for verification badge type
    var verificationBadge: VerificationBadge {
        if hasVideoProof && communityVotes > 5 && communityDownvotes < 2 {
            return .verified
        } else if hasVideoProof {
            return .videoProof
        } else if communityVotes > 10 {
            return .communityVerified
        } else {
            return .unverified
        }
    }
}

// AI Verification Status
enum AIVerificationStatus: String, Codable {
    case pending = "pending"
    case likely_genuine = "likely_genuine"
    case possibly_ai = "possibly_ai"
    case likely_ai = "likely_ai"
    case not_analyzed = "not_analyzed"

    var displayText: String {
        switch self {
        case .pending: return "Analyzing..."
        case .likely_genuine: return "Looks genuine"
        case .possibly_ai: return "May be AI-generated"
        case .likely_ai: return "Likely AI-generated"
        case .not_analyzed: return "Not analyzed"
        }
    }

    var color: String {
        switch self {
        case .pending: return "gray"
        case .likely_genuine: return "green"
        case .possibly_ai: return "orange"
        case .likely_ai: return "red"
        case .not_analyzed: return "gray"
        }
    }
}

// Verification Badge Types
enum VerificationBadge: String, Codable {
    case verified = "verified"           // Video proof + community approval
    case videoProof = "video_proof"      // Has video proof only
    case communityVerified = "community" // High community votes
    case unverified = "unverified"       // No verification

    var icon: String {
        switch self {
        case .verified: return "checkmark.seal.fill"
        case .videoProof: return "video.fill"
        case .communityVerified: return "person.2.fill"
        case .unverified: return "questionmark.circle"
        }
    }

    var color: String {
        switch self {
        case .verified: return "blue"
        case .videoProof: return "green"
        case .communityVerified: return "orange"
        case .unverified: return "gray"
        }
    }
}

// MARK: - Post Preview
extension Post {
    static let preview = Post(
        id: "preview-post",
        userId: "user-1",
        userName: "Test User",
        userPhotoURL: nil,
        description: "Cleaned up the local beach today! Found a lot of plastic waste. Let's keep our beaches clean!",
        beforeImageURL: nil,
        afterImageURL: nil,
        videoProofURL: "https://youtube.com/shorts/example",
        wasteCollectedKg: 5.5,
        durationMinutes: 45,
        pointsEarned: 75,
        state: "Maharashtra",
        district: "Mumbai",
        pincode: "400001",
        latitude: 19.0760,
        longitude: 72.8777,
        address: "Juhu Beach",
        likes: 24,
        comments: 5,
        shares: 3,
        tipsReceived: 100,
        verified: true,
        verificationScore: 0.95,
        communityVotes: 15,
        communityDownvotes: 1,
        hasVideoProof: true,
        aiVerificationStatus: .likely_genuine,
        isLiked: false,
        createdAt: Date().addingTimeInterval(-3600),
        updatedAt: nil,
        hashtags: ["BeachCleanup", "CleanMumbai"],
        campaignId: nil
    )
}

struct Comment: Codable, Identifiable {
    let id: String
    let postId: String
    let userId: String
    let userName: String
    let userPhotoURL: String?
    var text: String
    var likes: Int
    var createdAt: Date

    static let preview = Comment(
        id: "comment-1",
        postId: "post-1",
        userId: "user-2",
        userName: "Jane Doe",
        userPhotoURL: nil,
        text: "Great work! Keep it up! 👏",
        likes: 3,
        createdAt: Date().addingTimeInterval(-1800)
    )
}

struct Tip: Codable, Identifiable {
    let id: String
    let postId: String
    let senderId: String
    let senderName: String
    let recipientId: String
    let recipientName: String
    var amount: Int
    var platformFee: Int
    var creatorReceives: Int
    var status: TipStatus
    var paymentId: String?
    var createdAt: Date

    enum TipStatus: String, Codable {
        case pending
        case completed
        case failed
        case refunded
    }
}

// Point values matching web app
struct PointValues {
    static let postCreated = 50
    static let eventOrganized = 100
    static let eventAttended = 25
    static let tipReceivedPer10 = 1 // +1 pt per ₹10 received
}
