// CleanupRequestService.swift
// Handles cleanup request/job operations with Firestore sync

import Foundation
import FirebaseFirestore

@MainActor
class CleanupRequestService: ObservableObject {
    static let shared = CleanupRequestService()

    private let db = Firestore.firestore()
    private let localDataManager = LocalDataManager.shared

    @Published var jobs: [CleanupJob] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private init() {}

    // MARK: - Create Job

    func createJob(
        title: String,
        description: String,
        category: CleanupJob.JobCategory,
        difficulty: CleanupJob.JobDifficulty,
        estimatedTime: Int,
        latitude: Double,
        longitude: Double,
        address: String?,
        district: String,
        state: String,
        pointsReward: Int,
        tipReward: Int?
    ) async throws {
        guard let userId = await AuthManager.shared.currentUserId else {
            throw JobError.notAuthenticated
        }

        let userName = await UserState.shared.currentUser?.displayName ?? "User"
        let userPhoto = await UserState.shared.currentUser?.photoURL
        let jobId = UUID().uuidString

        let job = CleanupJob(
            id: jobId,
            creatorId: userId,
            creatorName: userName,
            creatorPhotoURL: userPhoto,
            title: title,
            description: description,
            category: category,
            difficulty: difficulty,
            estimatedTime: estimatedTime,
            latitude: latitude,
            longitude: longitude,
            address: address,
            district: district,
            state: state,
            pointsReward: pointsReward,
            tipReward: tipReward,
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
            expiresAt: Date().addingTimeInterval(86400 * 7), // 7 days
            viewCount: 0,
            claimCount: 0
        )

        // Save to Firestore
        try db.collection("cleanupJobs").document(jobId).setData(from: job)

        // Update local cache
        jobs.insert(job, at: 0)
    }

    // MARK: - Load Jobs

    func loadJobs(state: String? = nil, radius: Double? = nil, userLat: Double? = nil, userLng: Double? = nil) async {
        isLoading = true
        defer { isLoading = false }

        do {
            var query: Query = db.collection("cleanupJobs")
                .whereField("status", isEqualTo: "Open")
                .order(by: "createdAt", descending: true)
                .limit(to: 50)

            if let state = state {
                query = db.collection("cleanupJobs")
                    .whereField("status", isEqualTo: "Open")
                    .whereField("state", isEqualTo: state)
                    .order(by: "createdAt", descending: true)
                    .limit(to: 50)
            }

            let snapshot = try await query.getDocuments()
            var loadedJobs = snapshot.documents.compactMap { try? $0.data(as: CleanupJob.self) }

            // Filter by distance if user location provided
            if let userLat = userLat, let userLng = userLng, let radius = radius {
                loadedJobs = loadedJobs.filter { job in
                    let distance = calculateDistance(
                        lat1: userLat, lon1: userLng,
                        lat2: job.latitude, lon2: job.longitude
                    )
                    return distance <= radius
                }
            }

            jobs = loadedJobs
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Claim Job

    func claimJob(_ job: CleanupJob) async throws {
        guard let userId = await AuthManager.shared.currentUserId else {
            throw JobError.notAuthenticated
        }

        guard job.status == .open else {
            throw JobError.jobNotAvailable
        }

        let userName = await UserState.shared.currentUser?.displayName ?? "User"

        // Update job in Firestore
        try await db.collection("cleanupJobs").document(job.id).updateData([
            "status": CleanupJob.JobStatus.claimed.rawValue,
            "claimedBy": userId,
            "claimedByName": userName,
            "claimedAt": Timestamp(date: Date()),
            "claimCount": FieldValue.increment(Int64(1))
        ])

        // Update local cache
        if let index = jobs.firstIndex(where: { $0.id == job.id }) {
            jobs[index].status = .claimed
            jobs[index].claimedBy = userId
            jobs[index].claimedByName = userName
            jobs[index].claimedAt = Date()
        }
    }

    // MARK: - Complete Job

    func completeJob(_ job: CleanupJob, proofPhotoURL: String?, proofVideoURL: String?) async throws {
        guard let userId = await AuthManager.shared.currentUserId else {
            throw JobError.notAuthenticated
        }

        guard job.claimedBy == userId else {
            throw JobError.notAuthorized
        }

        // Update job in Firestore
        var updateData: [String: Any] = [
            "status": CleanupJob.JobStatus.proofSubmitted.rawValue,
            "completedAt": Timestamp(date: Date())
        ]

        if let photoURL = proofPhotoURL {
            updateData["proofPhotoURL"] = photoURL
        }
        if let videoURL = proofVideoURL {
            updateData["proofVideoURL"] = videoURL
        }

        try await db.collection("cleanupJobs").document(job.id).updateData(updateData)

        // Update local cache
        if let index = jobs.firstIndex(where: { $0.id == job.id }) {
            jobs[index].status = .proofSubmitted
            jobs[index].completedAt = Date()
        }
    }

    // MARK: - Cancel Claim

    func cancelClaim(_ job: CleanupJob) async throws {
        guard let userId = await AuthManager.shared.currentUserId else {
            throw JobError.notAuthenticated
        }

        guard job.claimedBy == userId else {
            throw JobError.notAuthorized
        }

        // Update job in Firestore - make it available again
        try await db.collection("cleanupJobs").document(job.id).updateData([
            "status": CleanupJob.JobStatus.open.rawValue,
            "claimedBy": FieldValue.delete(),
            "claimedByName": FieldValue.delete(),
            "claimedAt": FieldValue.delete()
        ])

        // Update local cache
        if let index = jobs.firstIndex(where: { $0.id == job.id }) {
            jobs[index].status = .open
            jobs[index].claimedBy = nil
            jobs[index].claimedByName = nil
            jobs[index].claimedAt = nil
        }
    }

    // MARK: - Delete Job

    func deleteJob(_ job: CleanupJob) async throws {
        guard let userId = await AuthManager.shared.currentUserId else {
            throw JobError.notAuthenticated
        }

        guard job.creatorId == userId else {
            throw JobError.notAuthorized
        }

        try await db.collection("cleanupJobs").document(job.id).delete()

        // Update local cache
        jobs.removeAll { $0.id == job.id }
    }

    // MARK: - Get My Jobs

    func getMyJobs() async throws -> [CleanupJob] {
        guard let userId = await AuthManager.shared.currentUserId else {
            throw JobError.notAuthenticated
        }

        let snapshot = try await db.collection("cleanupJobs")
            .whereField("creatorId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: CleanupJob.self) }
    }

    // MARK: - Get Claimed Jobs

    func getClaimedJobs() async throws -> [CleanupJob] {
        guard let userId = await AuthManager.shared.currentUserId else {
            throw JobError.notAuthenticated
        }

        let snapshot = try await db.collection("cleanupJobs")
            .whereField("claimedBy", isEqualTo: userId)
            .order(by: "claimedAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: CleanupJob.self) }
    }

    // MARK: - Helpers

    private func calculateDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 6371.0 // Earth's radius in km
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat/2) * sin(dLat/2) +
                cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) *
                sin(dLon/2) * sin(dLon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        return R * c
    }
}

// MARK: - Errors

enum JobError: LocalizedError {
    case notAuthenticated
    case notAuthorized
    case jobNotAvailable
    case jobNotFound

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Please sign in to continue"
        case .notAuthorized: return "You don't have permission for this action"
        case .jobNotAvailable: return "This job is no longer available"
        case .jobNotFound: return "Job not found"
        }
    }
}
