// CloudFunctionsService.swift
// Handles calls to Firebase Cloud Functions for voting, deleting, and feed management

import Foundation
import FirebaseFunctions

@MainActor
class CloudFunctionsService {
    static let shared = CloudFunctionsService()

    private lazy var functions = Functions.functions()

    private init() {}

    // MARK: - Voting

    /// Vote on a post (upvote, downvote, or remove vote)
    /// - Parameters:
    ///   - postId: The post to vote on
    ///   - voteType: "up", "down", or "none" (to remove vote)
    /// - Returns: Updated vote counts
    func voteOnPost(postId: String, voteType: String) async throws -> VoteResult {
        let params: [String: Any] = [
            "postId": postId,
            "voteType": voteType
        ]

        let result = try await functions.httpsCallable("voteOnPost").call(params)

        guard let data = result.data as? [String: Any],
              let success = data["success"] as? Bool, success,
              let upvotes = data["communityVotes"] as? Int,
              let downvotes = data["communityDownvotes"] as? Int,
              let voteScore = data["voteScore"] as? Int else {
            throw CloudFunctionError.invalidResponse
        }

        return VoteResult(
            communityVotes: upvotes,
            communityDownvotes: downvotes,
            voteScore: voteScore
        )
    }

    /// Get the current user's vote on a post
    func getUserVote(postId: String) async throws -> String? {
        let params: [String: Any] = ["postId": postId]

        let result = try await functions.httpsCallable("getUserVote").call(params)

        guard let data = result.data as? [String: Any] else {
            throw CloudFunctionError.invalidResponse
        }

        return data["voteType"] as? String
    }

    // MARK: - Delete Operations

    /// Delete a post (owner only)
    func deletePost(postId: String) async throws {
        let params: [String: Any] = ["postId": postId]

        let result = try await functions.httpsCallable("deletePost").call(params)

        guard let data = result.data as? [String: Any],
              let success = data["success"] as? Bool, success else {
            throw CloudFunctionError.deleteFailed
        }
    }

    /// Delete a comment (owner only)
    func deleteComment(commentId: String) async throws {
        let params: [String: Any] = ["commentId": commentId]

        let result = try await functions.httpsCallable("deleteComment").call(params)

        guard let data = result.data as? [String: Any],
              let success = data["success"] as? Bool, success else {
            throw CloudFunctionError.deleteFailed
        }
    }

    // MARK: - Feed with Advanced Sorting

    /// Get posts with sorting and filtering
    /// - Parameters:
    ///   - sortBy: "hot", "new", "top", "tipped"
    ///   - timeRange: "day", "week", "month", "year", "all"
    ///   - state: Filter by state (optional)
    ///   - district: Filter by district (optional)
    ///   - verifiedOnly: Only show verified posts
    ///   - limit: Number of posts to fetch
    ///   - startAfter: Post ID for pagination
    /// - Returns: Feed result with posts
    func getFeedPosts(
        sortBy: String = "hot",
        timeRange: String = "all",
        state: String? = nil,
        district: String? = nil,
        verifiedOnly: Bool = false,
        limit: Int = 20,
        startAfter: String? = nil
    ) async throws -> FeedResult {
        var params: [String: Any] = [
            "sortBy": sortBy,
            "timeRange": timeRange,
            "verifiedOnly": verifiedOnly,
            "limit": limit
        ]

        if let state = state {
            params["state"] = state
        }
        if let district = district {
            params["district"] = district
        }
        if let startAfter = startAfter {
            params["startAfter"] = startAfter
        }

        let result = try await functions.httpsCallable("getFeedPosts").call(params)

        guard let data = result.data as? [String: Any],
              let postsData = data["posts"] as? [[String: Any]] else {
            throw CloudFunctionError.invalidResponse
        }

        let hasMore = data["hasMore"] as? Bool ?? false
        let lastPostId = data["lastPostId"] as? String

        // Convert posts data to Post objects
        let posts = postsData.compactMap { postDict -> Post? in
            return Post.fromDictionary(postDict)
        }

        return FeedResult(
            posts: posts,
            hasMore: hasMore,
            lastPostId: lastPostId
        )
    }

    // MARK: - User Stats

    /// Recalculate user stats (if they get out of sync)
    func recalculateUserStats() async throws -> UserStatsResult {
        let result = try await functions.httpsCallable("recalculateUserStats").call()

        guard let data = result.data as? [String: Any],
              let success = data["success"] as? Bool, success,
              let stats = data["stats"] as? [String: Any] else {
            throw CloudFunctionError.invalidResponse
        }

        return UserStatsResult(
            totalPosts: stats["totalPosts"] as? Int ?? 0,
            totalWasteKg: stats["totalWasteKg"] as? Double ?? 0,
            totalPoints: stats["totalPoints"] as? Int ?? 0,
            tipsReceived: stats["tipsReceived"] as? Int ?? 0
        )
    }
}

// MARK: - Result Models

struct VoteResult {
    let communityVotes: Int
    let communityDownvotes: Int
    let voteScore: Int
}

struct FeedResult {
    let posts: [Post]
    let hasMore: Bool
    let lastPostId: String?
}

struct UserStatsResult {
    let totalPosts: Int
    let totalWasteKg: Double
    let totalPoints: Int
    let tipsReceived: Int
}

// MARK: - Errors

enum CloudFunctionError: LocalizedError {
    case invalidResponse
    case deleteFailed
    case voteFailed
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .deleteFailed:
            return "Failed to delete"
        case .voteFailed:
            return "Failed to register vote"
        case .notAuthenticated:
            return "You must be logged in"
        }
    }
}

// MARK: - Post Extension for Dictionary Parsing

extension Post {
    static func fromDictionary(_ dict: [String: Any]) -> Post? {
        guard let id = dict["id"] as? String,
              let userId = dict["userId"] as? String,
              let userName = dict["userName"] as? String else {
            return nil
        }

        // Parse timestamp
        var createdAt = Date()
        if let timestamp = dict["createdAt"] as? [String: Any],
           let seconds = timestamp["_seconds"] as? TimeInterval {
            createdAt = Date(timeIntervalSince1970: seconds)
        }

        // Parse post type
        let postTypeString = dict["postType"] as? String ?? "cleanup"
        let postType: PostType
        switch postTypeString {
        case "jobProof": postType = .jobProof
        case "event": postType = .event
        default: postType = .cleanup
        }

        // Parse AI verification status
        let aiStatusString = dict["aiVerificationStatus"] as? String ?? "not_analyzed"
        let aiStatus: AIVerificationStatus
        switch aiStatusString {
        case "likely_genuine": aiStatus = .likely_genuine
        case "possibly_ai": aiStatus = .possibly_ai
        case "likely_ai": aiStatus = .likely_ai
        case "pending": aiStatus = .pending
        default: aiStatus = .not_analyzed
        }

        return Post(
            id: id,
            userId: userId,
            userName: userName,
            userPhotoURL: dict["userPhotoURL"] as? String,
            postType: postType,
            description: dict["description"] as? String ?? "",
            beforeImageURL: dict["beforeImageURL"] as? String,
            afterImageURL: dict["afterImageURL"] as? String,
            videoProofURL: dict["videoProofURL"] as? String,
            jobId: dict["jobId"] as? String,
            jobTitle: dict["jobTitle"] as? String,
            jobCategory: dict["jobCategory"] as? String,
            wasteCollectedKg: dict["wasteCollectedKg"] as? Double ?? 0,
            durationMinutes: dict["durationMinutes"] as? Int,
            pointsEarned: dict["pointsEarned"] as? Int ?? 0,
            state: dict["state"] as? String ?? "",
            district: dict["district"] as? String ?? "",
            pincode: dict["pincode"] as? String,
            latitude: dict["latitude"] as? Double,
            longitude: dict["longitude"] as? Double,
            address: dict["address"] as? String,
            likes: dict["likes"] as? Int ?? 0,
            comments: dict["comments"] as? Int ?? 0,
            shares: dict["shares"] as? Int ?? 0,
            tipsReceived: dict["tipsReceived"] as? Int ?? 0,
            verified: dict["verified"] as? Bool ?? false,
            verificationScore: dict["verificationScore"] as? Double,
            communityVotes: dict["communityVotes"] as? Int ?? 0,
            communityDownvotes: dict["communityDownvotes"] as? Int ?? 0,
            hasVideoProof: dict["hasVideoProof"] as? Bool ?? false,
            aiVerificationStatus: aiStatus,
            isLiked: false,
            createdAt: createdAt,
            updatedAt: nil,
            hashtags: dict["hashtags"] as? [String] ?? [],
            campaignId: dict["campaignId"] as? String
        )
    }
}
