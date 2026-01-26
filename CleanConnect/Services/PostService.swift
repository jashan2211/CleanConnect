// PostService.swift
// Post-related operations with Firebase

import Foundation

class PostService {
    static let shared = PostService()

    private let localDataManager = LocalDataManager.shared
    private let useFirebase: Bool

    private init() {
        // Check if Firebase is configured
        #if canImport(FirebaseFirestore)
        useFirebase = true
        #else
        useFirebase = false
        loadSampleDataIfNeeded()
        #endif
    }

    // MARK: - Create Post

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
        let userPhotoURL = await UserState.shared.currentUser?.photoURL
        let postId = UUID().uuidString

        // Posts with video proof get bonus points
        let hasVideo = videoProofURL != nil && !videoProofURL!.isEmpty
        let points = hasVideo ? PointValues.postCreated + 25 : PointValues.postCreated

        // Upload images
        var beforeURL: String?
        var afterURL: String?

        if let data = beforeImageData {
            beforeURL = try await uploadImage(data, postId: postId, type: "before")
        }
        if let data = afterImageData {
            afterURL = try await uploadImage(data, postId: postId, type: "after")
        }

        let post = Post(
            id: postId,
            userId: userId,
            userName: userName,
            userPhotoURL: userPhotoURL,
            postType: .cleanup,
            description: description,
            beforeImageURL: beforeURL,
            afterImageURL: afterURL,
            videoProofURL: videoProofURL,
            jobId: nil,
            jobTitle: nil,
            jobCategory: nil,
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

        // Save to Firebase or local
        #if canImport(FirebaseFirestore)
        try await FirestoreService.shared.savePost(post)
        try await FirestoreService.shared.updateUserStats(userId: userId, points: points, wasteKg: wasteCollectedKg)
        #else
        try localDataManager.save(post, to: "\(postId).json", in: "posts")
        try await UserState.shared.updateStats(points: points, wasteKg: wasteCollectedKg)
        #endif
    }

    private func uploadImage(_ data: Data, postId: String, type: String) async throws -> String {
        #if canImport(FirebaseStorage)
        return try await StorageService.shared.uploadPostImage(data, postId: postId, type: type)
        #else
        // Fallback to local storage
        let filename = "\(postId)_\(type).jpg"
        return try localDataManager.saveImage(data, filename: filename)
        #endif
    }

    // MARK: - Get Posts

    func getPosts(state: String? = nil, district: String? = nil, limit: Int = 20) async throws -> [Post] {
        #if canImport(FirebaseFirestore)
        return try await FirestoreService.shared.getPosts(state: state, limit: limit)
        #else
        var posts = (try? localDataManager.loadAll(Post.self, from: "posts")) ?? []

        if let state = state {
            posts = posts.filter { $0.state == state }
        }
        if let district = district {
            posts = posts.filter { $0.district == district }
        }

        return Array(posts.sorted { $0.createdAt > $1.createdAt }.prefix(limit))
        #endif
    }

    // MARK: - Like/Unlike

    func likePost(postId: String) async throws {
        #if canImport(FirebaseFirestore)
        try await FirestoreService.shared.updatePostLikes(postId: postId, increment: 1)
        #else
        guard var post = try? localDataManager.load(Post.self, from: "\(postId).json", in: "posts") else { return }
        post.likes += 1
        post.isLiked = true
        try localDataManager.save(post, to: "\(postId).json", in: "posts")
        #endif
    }

    func unlikePost(postId: String) async throws {
        #if canImport(FirebaseFirestore)
        try await FirestoreService.shared.updatePostLikes(postId: postId, increment: -1)
        #else
        guard var post = try? localDataManager.load(Post.self, from: "\(postId).json", in: "posts") else { return }
        post.likes = max(0, post.likes - 1)
        post.isLiked = false
        try localDataManager.save(post, to: "\(postId).json", in: "posts")
        #endif
    }

    // MARK: - Comments

    func getComments(postId: String) async throws -> [Comment] {
        #if canImport(FirebaseFirestore)
        return try await FirestoreService.shared.getComments(postId: postId)
        #else
        let allComments = (try? localDataManager.loadAll(Comment.self, from: "comments")) ?? []
        return allComments.filter { $0.postId == postId }.sorted { $0.createdAt > $1.createdAt }
        #endif
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

        #if canImport(FirebaseFirestore)
        try await FirestoreService.shared.saveComment(comment)
        #else
        try localDataManager.save(comment, to: "\(comment.id).json", in: "comments")
        if var post = try? localDataManager.load(Post.self, from: "\(postId).json", in: "posts") {
            post.comments += 1
            try? localDataManager.save(post, to: "\(postId).json", in: "posts")
        }
        #endif

        return comment
    }

    // MARK: - Helpers

    private func extractHashtags(from text: String) -> [String] {
        let regex = try? NSRegularExpression(pattern: "#\\w+", options: [])
        let range = NSRange(text.startIndex..., in: text)
        let matches = regex?.matches(in: text, options: [], range: range) ?? []

        return matches.compactMap { match in
            guard let range = Range(match.range, in: text) else { return nil }
            return String(text[range]).lowercased()
        }
    }

    // MARK: - Sample Data (Local Only)

    private func loadSampleDataIfNeeded() {
        let posts = (try? localDataManager.loadAll(Post.self, from: "posts")) ?? []
        if posts.isEmpty {
            createSamplePosts()
        }
    }

    private func createSamplePosts() {
        let samplePosts = [
            Post(
                id: UUID().uuidString,
                userId: "sample-user-1",
                userName: "Rajesh Kumar",
                userPhotoURL: nil,
                postType: .cleanup,
                description: "Cleaned up Juhu Beach today! Collected plastic bottles and wrappers. #BeachCleanup #CleanMumbai",
                beforeImageURL: nil,
                afterImageURL: nil,
                videoProofURL: "https://youtube.com/shorts/demo",
                jobId: nil,
                jobTitle: nil,
                jobCategory: nil,
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
                hashtags: ["BeachCleanup", "CleanMumbai"],
                campaignId: nil
            ),
            Post(
                id: UUID().uuidString,
                userId: "sample-user-2",
                userName: "Priya Sharma",
                userPhotoURL: nil,
                postType: .cleanup,
                description: "Morning cleanup at Lodhi Garden. Found so much plastic waste! #SwachhBharat #CleanDelhi",
                beforeImageURL: nil,
                afterImageURL: nil,
                videoProofURL: nil,
                jobId: nil,
                jobTitle: nil,
                jobCategory: nil,
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
            )
        ]

        for post in samplePosts {
            try? localDataManager.save(post, to: "\(post.id).json", in: "posts")
        }
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
