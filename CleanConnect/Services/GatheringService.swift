// GatheringService.swift
// Event/Gathering-related local operations

import Foundation

class GatheringService {
    static let shared = GatheringService()
    private let dataManager = LocalDataManager.shared

    private init() {
        // No sample data - users create their own events
    }

    func createGathering(
        title: String,
        description: String,
        eventDate: Date,
        durationHours: Int,
        state: String,
        district: String,
        address: String?,
        fundraisingGoal: Int?,
        whatsappLink: String?,
        imageData: Data?
    ) async throws {
        guard let userId = await AuthManager.shared.currentUserId else {
            throw GatheringError.notAuthenticated
        }

        let userName = await UserState.shared.currentUser?.displayName ?? "Organizer"
        let userPhotoURL = await UserState.shared.currentUser?.photoURL
        let gatheringId = UUID().uuidString

        // Upload image to Firebase Storage if provided
        var imageURL: String?
        if let data = imageData {
            // Save locally first for offline access
            let localPath = try? dataManager.saveImage(data, filename: "\(gatheringId)_cover.jpg")

            // Upload to Firebase Storage
            #if canImport(FirebaseStorage)
            do {
                imageURL = try await StorageService.shared.uploadEventImage(data, eventId: gatheringId)
            } catch {
                // Fall back to local storage
                imageURL = localPath
            }
            #else
            imageURL = localPath
            #endif
        }

        let gathering = Gathering(
            id: gatheringId,
            organizerId: userId,
            organizerName: userName,
            organizerPhotoURL: userPhotoURL,
            title: title,
            description: description,
            imageURL: imageURL,
            eventDate: eventDate,
            endDate: nil,
            durationHours: durationHours,
            state: state,
            district: district,
            address: address,
            latitude: nil,
            longitude: nil,
            attendeesCount: 1,
            maxAttendees: nil,
            fundraisingGoal: fundraisingGoal,
            fundraisingRaised: 0,
            whatsappGroupLink: whatsappLink,
            status: "upcoming",
            createdAt: Date(),
            updatedAt: nil
        )

        // Save locally first
        try dataManager.save(gathering, to: "\(gatheringId).json", in: "gatherings")

        // Sync to Firestore
        #if canImport(FirebaseFirestore)
        do {
            try await FirestoreService.shared.saveGathering(gathering)
        } catch {
            // Continue with local storage only
        }
        #endif

        // Update user stats
        if var user = await UserState.shared.currentUser {
            user.totalEventsOrganized += 1
            user.totalPoints += PointValues.eventOrganized
            try dataManager.save(user, to: "\(userId).json", in: "users")
            dataManager.setUserDefault(user, forKey: StorageKeys.currentUser)
        }
    }

    func getGatherings(filter: GatheringsFilter = .upcoming, state: String? = nil, limit: Int = 20) async throws -> [Gathering] {
        var gatherings = (try? dataManager.loadAll(Gathering.self, from: "gatherings")) ?? []

        switch filter {
        case .upcoming:
            gatherings = gatherings.filter { $0.eventDate > Date() && $0.status == "upcoming" }
        case .past:
            gatherings = gatherings.filter { $0.eventDate < Date() }
        case .myEvents:
            if let userId = await AuthManager.shared.currentUserId {
                gatherings = gatherings.filter { $0.organizerId == userId }
            }
        }

        if let state = state {
            gatherings = gatherings.filter { $0.state == state }
        }

        // Sort by date
        let sorted = gatherings.sorted { $0.eventDate < $1.eventDate }
        return Array(sorted.prefix(limit))
    }

    func rsvp(gatheringId: String, status: RSVP.RSVPStatus, note: String?) async throws {
        guard var gathering = try? dataManager.load(Gathering.self, from: "\(gatheringId).json", in: "gatherings") else {
            throw GatheringError.notFound
        }

        if status == .going {
            gathering.attendeesCount += 1
        }

        try dataManager.save(gathering, to: "\(gatheringId).json", in: "gatherings")

        // Update user stats for attending
        if status == .going, var user = await UserState.shared.currentUser {
            user.totalEventsAttended += 1
            user.totalPoints += PointValues.eventAttended
            try dataManager.save(user, to: "\(user.id).json", in: "users")
            dataManager.setUserDefault(user, forKey: StorageKeys.currentUser)
        }
    }

    func getSupplyRequests(gatheringId: String) async throws -> [SupplyRequest] {
        // Return sample supply requests
        return [
            SupplyRequest(id: "1", gatheringId: gatheringId, type: "gloves", name: "Cleaning Gloves", needed: 50, pledged: 30, pledges: nil),
            SupplyRequest(id: "2", gatheringId: gatheringId, type: "bags", name: "Garbage Bags", needed: 100, pledged: 75, pledges: nil),
            SupplyRequest(id: "3", gatheringId: gatheringId, type: "water", name: "Water Bottles", needed: 200, pledged: 120, pledges: nil)
        ]
    }

    func contribute(gatheringId: String, amount: Int) async throws {
        guard var gathering = try? dataManager.load(Gathering.self, from: "\(gatheringId).json", in: "gatherings") else {
            throw GatheringError.notFound
        }

        gathering.fundraisingRaised = (gathering.fundraisingRaised ?? 0) + amount
        try dataManager.save(gathering, to: "\(gatheringId).json", in: "gatherings")
    }

    func deleteGathering(gatheringId: String) async throws {
        // Verify user is the organizer
        guard let userId = await AuthManager.shared.currentUserId else {
            throw GatheringError.notAuthenticated
        }

        guard let gathering = try? dataManager.load(Gathering.self, from: "\(gatheringId).json", in: "gatherings") else {
            throw GatheringError.notFound
        }

        // Allow deletion if user is organizer OR if it's sample data (for testing)
        let isSampleData = gathering.organizerId.hasPrefix("sample-")
        guard gathering.organizerId == userId || isSampleData else {
            throw GatheringError.notAuthorized
        }

        // Delete from Firebase if available (best effort - don't fail if Firestore fails)
        #if canImport(FirebaseFirestore)
        do {
            try await FirestoreService.shared.deleteGathering(gatheringId: gatheringId)
        } catch {
            // Continue with local deletion only
        }
        #endif

        // Delete local file
        try dataManager.delete(filename: "\(gatheringId).json", from: "gatherings")

        // Delete associated image if exists
        if let imageURL = gathering.imageURL, imageURL.hasPrefix("/") {
            try? FileManager.default.removeItem(atPath: imageURL)
        }
    }
}

enum GatheringsFilter {
    case upcoming
    case past
    case myEvents
}

enum GatheringError: LocalizedError {
    case notAuthenticated
    case notFound
    case invalidData
    case notAuthorized

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "You must be signed in"
        case .notFound: return "Event not found"
        case .invalidData: return "Invalid event data"
        case .notAuthorized: return "You don't have permission to do this"
        }
    }
}
