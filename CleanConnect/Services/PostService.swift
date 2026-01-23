// PostService.swift
// Post-related local operations

import Foundation

class PostService {
    static let shared = PostService()
    private let dataManager = LocalDataManager.shared

    private init() {
        // Load sample posts if none exist
        loadSampleDataIfNeeded()
    }

    private func loadSampleDataIfNeeded() {
        let posts = (try? dataManager.loadAll(Post.self, from: "posts")) ?? []
        if posts.isEmpty {
            // Create sample posts for demo
            createSamplePosts()
        }
    }

    private func createSamplePosts() {
        let samplePosts = [
            // Verified with video proof
            Post(
                id: UUID().uuidString,
                userId: "sample-user-1",
                userName: "Rajesh Kumar",
                userPhotoURL: nil,
                description: "Cleaned up Juhu Beach today! Collected plastic bottles, wrappers, and other waste. Watch my video for full cleanup journey! #BeachCleanup #CleanMumbai #SwachhBharat",
                beforeImageURL: nil,
                afterImageURL: nil,
                videoProofURL: "https://youtube.com/shorts/juhu_cleanup_demo",
                wasteCollectedKg: 5.5,
                durationMinutes: 45,
                pointsEarned: 75,
                state: "Maharashtra",
                district: "Mumbai",
                pincode: "400049",
                latitude: 19.0883,
                longitude: 72.8264,
                address: "Juhu Beach",
                likes: 24,
                comments: 5,
                shares: 3,
                tipsReceived: 350,
                verified: true,
                verificationScore: 0.95,
                communityVotes: 18,
                communityDownvotes: 0,
                hasVideoProof: true,
                aiVerificationStatus: .likely_genuine,
                isLiked: false,
                createdAt: Date().addingTimeInterval(-3600),
                updatedAt: nil,
                hashtags: ["BeachCleanup", "CleanMumbai", "SwachhBharat"],
                campaignId: nil
            ),
            // Community verified (no video but trusted)
            Post(
                id: UUID().uuidString,
                userId: "sample-user-2",
                userName: "Priya Sharma",
                userPhotoURL: nil,
                description: "Morning cleanup at Lodhi Garden. Found so much plastic waste hidden in bushes. Together we can make Delhi greener! #SwachhBharat #CleanDelhi",
                beforeImageURL: nil,
                afterImageURL: nil,
                videoProofURL: nil,
                wasteCollectedKg: 3.2,
                durationMinutes: 60,
                pointsEarned: 65,
                state: "Delhi",
                district: "South Delhi",
                pincode: "110003",
                latitude: 28.5933,
                longitude: 77.2190,
                address: "Lodhi Garden",
                likes: 45,
                comments: 12,
                shares: 8,
                tipsReceived: 150,
                verified: false,
                verificationScore: nil,
                communityVotes: 32,
                communityDownvotes: 2,
                hasVideoProof: false,
                aiVerificationStatus: .not_analyzed,
                isLiked: false,
                createdAt: Date().addingTimeInterval(-7200),
                updatedAt: nil,
                hashtags: ["SwachhBharat", "CleanDelhi"],
                campaignId: nil
            ),
            // Verified with video, high tips
            Post(
                id: UUID().uuidString,
                userId: "sample-user-3",
                userName: "Arjun Patel",
                userPhotoURL: nil,
                description: "Weekend cleanup drive at Sabarmati Riverfront. Amazing to see so many volunteers! Full video on my Instagram! #CleanGujarat #RiverCleanup",
                beforeImageURL: nil,
                afterImageURL: nil,
                videoProofURL: "https://instagram.com/reel/sabarmati_cleanup",
                wasteCollectedKg: 8.0,
                durationMinutes: 90,
                pointsEarned: 100,
                state: "Gujarat",
                district: "Ahmedabad",
                pincode: "380001",
                latitude: 23.0225,
                longitude: 72.5714,
                address: "Sabarmati Riverfront",
                likes: 67,
                comments: 18,
                shares: 15,
                tipsReceived: 750,
                verified: true,
                verificationScore: 0.98,
                communityVotes: 45,
                communityDownvotes: 1,
                hasVideoProof: true,
                aiVerificationStatus: .likely_genuine,
                isLiked: false,
                createdAt: Date().addingTimeInterval(-86400),
                updatedAt: nil,
                hashtags: ["CleanGujarat", "RiverCleanup"],
                campaignId: nil
            ),
            // Unverified post (no video, low votes)
            Post(
                id: UUID().uuidString,
                userId: "sample-user-4",
                userName: "New User",
                userPhotoURL: nil,
                description: "Cleaned my neighborhood park today. Small effort but makes a difference!",
                beforeImageURL: nil,
                afterImageURL: nil,
                videoProofURL: nil,
                wasteCollectedKg: 1.5,
                durationMinutes: 30,
                pointsEarned: 50,
                state: "Karnataka",
                district: "Bangalore",
                pincode: "560001",
                latitude: 12.9716,
                longitude: 77.5946,
                address: "Cubbon Park",
                likes: 5,
                comments: 2,
                shares: 0,
                tipsReceived: 0,
                verified: false,
                verificationScore: nil,
                communityVotes: 3,
                communityDownvotes: 0,
                hasVideoProof: false,
                aiVerificationStatus: .not_analyzed,
                isLiked: false,
                createdAt: Date().addingTimeInterval(-1800),
                updatedAt: nil,
                hashtags: ["CleanBangalore"],
                campaignId: nil
            )
        ]

        for post in samplePosts {
            try? dataManager.save(post, to: "\(post.id).json", in: "posts")
        }
    }

    func createPost(
        description: String,
        wasteCollectedKg: Double,
        durationMinutes: Int?,
        state: String,
        district: String,
        latitude: Double?,
        longitude: Double?,
        beforeImageData: Data?,
        afterImageData: Data?,
        videoProofURL: String?
    ) async throws {
        guard let userId = await AuthManager.shared.currentUserId else {
            throw PostError.notAuthenticated
        }

        let userName = await UserState.shared.currentUser?.displayName ?? "User"
        let postId = UUID().uuidString

        // Posts with video proof get bonus points
        let hasVideo = videoProofURL != nil && !videoProofURL!.isEmpty
        let points = hasVideo ? PointValues.postCreated + 25 : PointValues.postCreated

        // Save images if provided
        var beforeURL: String?
        var afterURL: String?

        if let data = beforeImageData {
            beforeURL = try? dataManager.saveImage(data, filename: "\(postId)_before.jpg")
        }
        if let data = afterImageData {
            afterURL = try? dataManager.saveImage(data, filename: "\(postId)_after.jpg")
        }

        let post = Post(
            id: postId,
            userId: userId,
            userName: userName,
            userPhotoURL: nil,
            description: description,
            beforeImageURL: beforeURL,
            afterImageURL: afterURL,
            videoProofURL: videoProofURL,
            wasteCollectedKg: wasteCollectedKg,
            durationMinutes: durationMinutes,
            pointsEarned: points,
            state: state,
            district: district,
            pincode: nil,
            latitude: latitude,
            longitude: longitude,
            address: nil,
            likes: 0,
            comments: 0,
            shares: 0,
            tipsReceived: 0,
            verified: hasVideo,
            verificationScore: nil,
            communityVotes: 0,
            communityDownvotes: 0,
            hasVideoProof: hasVideo,
            aiVerificationStatus: .not_analyzed,
            isLiked: false,
            createdAt: Date(),
            updatedAt: nil,
            hashtags: extractHashtags(from: description),
            campaignId: nil
        )

        try dataManager.save(post, to: "\(postId).json", in: "posts")

        // Update user stats
        try await UserState.shared.updateStats(points: points, wasteKg: wasteCollectedKg)
    }

    private func extractHashtags(from text: String) -> [String] {
        let regex = try? NSRegularExpression(pattern: "#\\w+", options: [])
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex?.matches(in: text, options: [], range: range) ?? []

        return matches.compactMap { match in
            guard let range = Range(match.range, in: text) else { return nil }
            return String(text[range]).lowercased()
        }
    }

    func getPosts(state: String? = nil, district: String? = nil, limit: Int = 20) async throws -> [Post] {
        var posts = (try? dataManager.loadAll(Post.self, from: "posts")) ?? []

        // Filter by state/district if specified
        if let state = state {
            posts = posts.filter { $0.state == state }
        }
        if let district = district {
            posts = posts.filter { $0.district == district }
        }

        // Sort by date (newest first) and limit
        return Array(posts.sorted { $0.createdAt > $1.createdAt }.prefix(limit))
    }

    func likePost(postId: String) async throws {
        guard var post = try? dataManager.load(Post.self, from: "\(postId).json", in: "posts") else { return }
        post.likes += 1
        post.isLiked = true
        try dataManager.save(post, to: "\(postId).json", in: "posts")
    }

    func unlikePost(postId: String) async throws {
        guard var post = try? dataManager.load(Post.self, from: "\(postId).json", in: "posts") else { return }
        post.likes = max(0, post.likes - 1)
        post.isLiked = false
        try dataManager.save(post, to: "\(postId).json", in: "posts")
    }

    func getComments(postId: String) async throws -> [Comment] {
        // Return empty for now - comments stored per post
        return []
    }

    func addComment(postId: String, userId: String, userName: String, userPhotoURL: String?, text: String) async throws -> Comment {
        let comment = Comment(
            id: UUID().uuidString,
            postId: postId,
            userId: userId,
            userName: userName,
            userPhotoURL: userPhotoURL,
            text: text,
            likes: 0,
            createdAt: Date()
        )
        return comment
    }
}

enum PostError: LocalizedError {
    case notAuthenticated
    case uploadFailed
    case invalidData

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "You must be signed in to create a post"
        case .uploadFailed: return "Failed to upload image"
        case .invalidData: return "Invalid post data"
        }
    }
}
