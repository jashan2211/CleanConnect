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
        try await db.collection("users").document(userId).updateData([
            "totalPoints": FieldValue.increment(Int64(points)),
            "totalWasteKg": FieldValue.increment(wasteKg),
            "totalPosts": FieldValue.increment(Int64(1)),
            "lastActive": Timestamp(date: Date())
        ])
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
