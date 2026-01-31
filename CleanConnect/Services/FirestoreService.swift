// FirestoreService.swift
// Firebase Firestore database operations

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class FirestoreService {
    static let shared = FirestoreService()

    private let db = Firestore.firestore()

    private init() {}

    // MARK: - Users

    func saveUser(_ user: User) async throws {
        try db.collection("users").document(user.id).setData(from: user, merge: true)
    }

    func getUser(userId: String) async throws -> User? {
        let doc = try await db.collection("users").document(userId).getDocument()
        return try? doc.data(as: User.self)
    }

    func updateUserStats(userId: String, points: Int, wasteKg: Double) async throws {
        let userRef = db.collection("users").document(userId)

        // Check if user document exists first
        let doc = try await userRef.getDocument()

        if doc.exists {
            // Update existing user
            try await userRef.updateData([
                "totalPoints": FieldValue.increment(Int64(points)),
                "totalWasteKg": FieldValue.increment(wasteKg),
                "totalPosts": FieldValue.increment(Int64(1)),
                "lastActive": Timestamp(date: Date())
            ])
        } else {
            // Create user document with initial stats (shouldn't normally happen)
            try await userRef.setData([
                "id": userId,
                "displayName": "User",
                "totalPoints": points,
                "totalWasteKg": wasteKg,
                "totalPosts": 1,
                "totalEventsOrganized": 0,
                "totalEventsAttended": 0,
                "tipsReceived": 0,
                "tipsGiven": 0,
                "totalVolunteerHours": 0,
                "totalSuppliesContributed": 0,
                "totalDonationsAmount": 0,
                "totalCO2Saved": 0,
                "longestStreak": 0,
                "currentStreak": 0,
                "totalAreasImpacted": 0,
                "videosVerified": 0,
                "level": 1,
                "levelName": "Eco Scout",
                "karmaScore": 0,
                "followersCount": 0,
                "followingCount": 0,
                "badges": [],
                "createdAt": Timestamp(date: Date()),
                "lastActive": Timestamp(date: Date()),
                "isAnonymous": false,
                "verified": false
            ])
        }
    }

    // MARK: - Posts

    func savePost(_ post: Post) async throws {
        try db.collection("posts").document(post.id).setData(from: post)
    }

    func getPosts(state: String? = nil, limit: Int = 20) async throws -> [Post] {
        var query: Query = db.collection("posts")
            .order(by: "createdAt", descending: true)
            .limit(to: limit)

        if let state = state {
            query = db.collection("posts")
                .whereField("state", isEqualTo: state)
                .order(by: "createdAt", descending: true)
                .limit(to: limit)
        }

        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Post.self) }
    }

    func getUserPosts(userId: String) async throws -> [Post] {
        let snapshot = try await db.collection("posts")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: Post.self) }
    }

    func updatePostLikes(postId: String, increment: Int) async throws {
        try await db.collection("posts").document(postId).updateData([
            "likes": FieldValue.increment(Int64(increment))
        ])
    }

    func updatePostTips(postId: String, amount: Int) async throws {
        try await db.collection("posts").document(postId).updateData([
            "tipsReceived": FieldValue.increment(Int64(amount))
        ])
    }

    // MARK: - Comments

    func saveComment(_ comment: Comment) async throws {
        try db.collection("comments").document(comment.id).setData(from: comment)

        // Update post comment count
        try await db.collection("posts").document(comment.postId).updateData([
            "comments": FieldValue.increment(Int64(1))
        ])
    }

    func getComments(postId: String) async throws -> [Comment] {
        let snapshot = try await db.collection("comments")
            .whereField("postId", isEqualTo: postId)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: Comment.self) }
    }

    // MARK: - Gatherings/Events

    func saveGathering(_ gathering: Gathering) async throws {
        try db.collection("gatherings").document(gathering.id).setData(from: gathering)
    }

    func getGatherings(state: String? = nil) async throws -> [Gathering] {
        var query: Query = db.collection("gatherings")
            .order(by: "startDate", descending: false)

        if let state = state {
            query = db.collection("gatherings")
                .whereField("state", isEqualTo: state)
                .order(by: "startDate", descending: false)
        }

        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Gathering.self) }
    }

    // MARK: - Leaderboard

    func getLeaderboard(state: String? = nil, limit: Int = 50) async throws -> [User] {
        var query: Query = db.collection("users")
            .order(by: "totalPoints", descending: true)
            .limit(to: limit)

        if let state = state {
            query = db.collection("users")
                .whereField("state", isEqualTo: state)
                .order(by: "totalPoints", descending: true)
                .limit(to: limit)
        }

        let snapshot = try await query.getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: User.self) }
    }

    // MARK: - Real-time Listeners

    func listenToPosts(state: String? = nil, onChange: @escaping ([Post]) -> Void) -> ListenerRegistration {
        var query: Query = db.collection("posts")
            .order(by: "createdAt", descending: true)
            .limit(to: 50)

        if let state = state {
            query = db.collection("posts")
                .whereField("state", isEqualTo: state)
                .order(by: "createdAt", descending: true)
                .limit(to: 50)
        }

        return query.addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else { return }
            let posts = documents.compactMap { try? $0.data(as: Post.self) }
            onChange(posts)
        }
    }
}
