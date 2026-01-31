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

    // MARK: - Event Comments (Discussions)

    func saveEventComment(_ comment: EventComment) async throws {
        try db.collection("eventComments").document(comment.id).setData(from: comment)

        // Update parent reply count if it's a reply
        if let parentId = comment.parentId {
            try await db.collection("eventComments").document(parentId).updateData([
                "replyCount": FieldValue.increment(Int64(1))
            ])
        }
    }

    func getEventComments(eventId: String) async throws -> [EventComment] {
        let snapshot = try await db.collection("eventComments")
            .whereField("eventId", isEqualTo: eventId)
            .order(by: "createdAt", descending: false)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: EventComment.self) }
    }

    func deleteEventComment(commentId: String) async throws {
        try await db.collection("eventComments").document(commentId).delete()
    }

    func voteOnEventComment(commentId: String, userId: String, isUpvote: Bool) async throws {
        let voteRef = db.collection("eventCommentVotes").document("\(commentId)_\(userId)")
        let commentRef = db.collection("eventComments").document(commentId)

        // Check if user already voted
        let existingVote = try await voteRef.getDocument()

        if existingVote.exists {
            // User already voted - update or remove vote
            let oldVote = try existingVote.data(as: CommentVote.self)

            if oldVote.isUpvote == isUpvote {
                // Same vote - remove it
                try await voteRef.delete()
                try await commentRef.updateData([
                    isUpvote ? "upvotes" : "downvotes": FieldValue.increment(Int64(-1))
                ])
            } else {
                // Different vote - switch it
                try await voteRef.updateData(["isUpvote": isUpvote])
                try await commentRef.updateData([
                    isUpvote ? "upvotes" : "downvotes": FieldValue.increment(Int64(1)),
                    isUpvote ? "downvotes" : "upvotes": FieldValue.increment(Int64(-1))
                ])
            }
        } else {
            // New vote
            let vote = CommentVote(commentId: commentId, userId: userId, isUpvote: isUpvote, createdAt: Date())
            try voteRef.setData(from: vote)
            try await commentRef.updateData([
                isUpvote ? "upvotes" : "downvotes": FieldValue.increment(Int64(1))
            ])
        }
    }

    // MARK: - Event Supplies

    func saveSupplyItem(_ supply: SupplyItem) async throws {
        try db.collection("eventSupplies").document(supply.id).setData(from: supply)
    }

    func getEventSupplies(eventId: String) async throws -> [SupplyItem] {
        let snapshot = try await db.collection("eventSupplies")
            .whereField("eventId", isEqualTo: eventId)
            .order(by: "createdAt", descending: false)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: SupplyItem.self) }
    }

    func updateSupplyFulfillment(supplyId: String, additionalQuantity: Int) async throws {
        try await db.collection("eventSupplies").document(supplyId).updateData([
            "fulfilledQuantity": FieldValue.increment(Int64(additionalQuantity))
        ])
    }

    func saveSupplyContribution(_ contribution: SupplyContribution) async throws {
        try db.collection("supplyContributions").document(contribution.id).setData(from: contribution)

        // Update the supply item's fulfilled quantity
        try await updateSupplyFulfillment(supplyId: contribution.supplyItemId, additionalQuantity: contribution.quantity)
    }

    func getSupplyContributions(supplyItemId: String) async throws -> [SupplyContribution] {
        let snapshot = try await db.collection("supplyContributions")
            .whereField("supplyItemId", isEqualTo: supplyItemId)
            .order(by: "createdAt", descending: false)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: SupplyContribution.self) }
    }

    // MARK: - Event Tasks

    func saveEventTask(_ task: EventTask) async throws {
        try db.collection("eventTasks").document(task.id).setData(from: task)
    }

    func getEventTasks(eventId: String) async throws -> [EventTask] {
        let snapshot = try await db.collection("eventTasks")
            .whereField("eventId", isEqualTo: eventId)
            .order(by: "createdAt", descending: false)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: EventTask.self) }
    }

    func updateTaskStatus(taskId: String, status: EventTask.TaskStatus) async throws {
        try await db.collection("eventTasks").document(taskId).updateData([
            "status": status.rawValue
        ])
    }

    func volunteerForTask(taskId: String, volunteer: TaskVolunteer) async throws {
        // Save volunteer record
        try db.collection("taskVolunteers").document(volunteer.id).setData(from: volunteer)

        // Update task volunteer count
        try await db.collection("eventTasks").document(taskId).updateData([
            "currentVolunteers": FieldValue.increment(Int64(1))
        ])
    }

    func getTaskVolunteers(taskId: String) async throws -> [TaskVolunteer] {
        let snapshot = try await db.collection("taskVolunteers")
            .whereField("taskId", isEqualTo: taskId)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: TaskVolunteer.self) }
    }

    // MARK: - Event RSVPs

    func saveRSVP(_ rsvp: RSVP) async throws {
        try db.collection("eventRSVPs").document(rsvp.id).setData(from: rsvp)

        // Update gathering attendee count
        try await db.collection("gatherings").document(rsvp.gatheringId).updateData([
            "attendeesCount": FieldValue.increment(Int64(1))
        ])
    }

    func getUserRSVP(eventId: String, userId: String) async throws -> RSVP? {
        let snapshot = try await db.collection("eventRSVPs")
            .whereField("gatheringId", isEqualTo: eventId)
            .whereField("userId", isEqualTo: userId)
            .limit(to: 1)
            .getDocuments()

        return snapshot.documents.first.flatMap { try? $0.data(as: RSVP.self) }
    }

    func getEventRSVPs(eventId: String) async throws -> [RSVP] {
        let snapshot = try await db.collection("eventRSVPs")
            .whereField("gatheringId", isEqualTo: eventId)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: RSVP.self) }
    }
}
