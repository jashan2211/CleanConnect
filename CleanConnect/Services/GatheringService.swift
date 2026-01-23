// GatheringService.swift
// Event/Gathering-related local operations

import Foundation

class GatheringService {
    static let shared = GatheringService()
    private let dataManager = LocalDataManager.shared

    private init() {
        loadSampleDataIfNeeded()
    }

    private func loadSampleDataIfNeeded() {
        let gatherings = (try? dataManager.loadAll(Gathering.self, from: "gatherings")) ?? []
        if gatherings.isEmpty {
            createSampleGatherings()
        }
    }

    private func createSampleGatherings() {
        let sampleGatherings = [
            Gathering(
                id: UUID().uuidString,
                organizerId: "sample-user-1",
                organizerName: "Rajesh Kumar",
                organizerPhotoURL: nil,
                title: "Weekend Beach Cleanup Drive",
                description: "Join us for a community beach cleanup at Juhu! We'll provide gloves and bags. Let's make our beach beautiful again!",
                imageURL: nil,
                eventDate: Date().addingTimeInterval(86400 * 7),
                endDate: nil,
                durationHours: 3,
                state: "Maharashtra",
                district: "Mumbai",
                address: "Juhu Beach, Near Food Court",
                latitude: 19.0883,
                longitude: 72.8264,
                attendeesCount: 45,
                maxAttendees: 100,
                fundraisingGoal: 5000,
                fundraisingRaised: 3200,
                whatsappGroupLink: nil,
                status: "upcoming",
                createdAt: Date(),
                updatedAt: nil
            ),
            Gathering(
                id: UUID().uuidString,
                organizerId: "sample-user-2",
                organizerName: "Priya Sharma",
                organizerPhotoURL: nil,
                title: "Lodhi Garden Green Initiative",
                description: "Monthly cleanup drive at Lodhi Garden. Families welcome! We'll also have a tree plantation activity.",
                imageURL: nil,
                eventDate: Date().addingTimeInterval(86400 * 14),
                endDate: nil,
                durationHours: 4,
                state: "Delhi",
                district: "South Delhi",
                address: "Lodhi Garden Main Gate",
                latitude: 28.5933,
                longitude: 77.2190,
                attendeesCount: 32,
                maxAttendees: 50,
                fundraisingGoal: 3000,
                fundraisingRaised: 1500,
                whatsappGroupLink: nil,
                status: "upcoming",
                createdAt: Date().addingTimeInterval(-86400),
                updatedAt: nil
            ),
            Gathering(
                id: UUID().uuidString,
                organizerId: "sample-user-3",
                organizerName: "Arjun Patel",
                organizerPhotoURL: nil,
                title: "Sabarmati River Cleanup",
                description: "Large scale cleanup of Sabarmati Riverfront. Join hands to keep our river clean!",
                imageURL: nil,
                eventDate: Date().addingTimeInterval(86400 * 21),
                endDate: nil,
                durationHours: 5,
                state: "Gujarat",
                district: "Ahmedabad",
                address: "Sabarmati Riverfront, East Bank",
                latitude: 23.0225,
                longitude: 72.5714,
                attendeesCount: 78,
                maxAttendees: 200,
                fundraisingGoal: 10000,
                fundraisingRaised: 6500,
                whatsappGroupLink: nil,
                status: "upcoming",
                createdAt: Date().addingTimeInterval(-172800),
                updatedAt: nil
            )
        ]

        for gathering in sampleGatherings {
            try? dataManager.save(gathering, to: "\(gathering.id).json", in: "gatherings")
        }
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
        let gatheringId = UUID().uuidString

        // Save image if provided
        var imageURL: String?
        if let data = imageData {
            imageURL = try? dataManager.saveImage(data, filename: "\(gatheringId)_cover.jpg")
        }

        let gathering = Gathering(
            id: gatheringId,
            organizerId: userId,
            organizerName: userName,
            organizerPhotoURL: nil,
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

        try dataManager.save(gathering, to: "\(gatheringId).json", in: "gatherings")

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

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "You must be signed in"
        case .notFound: return "Event not found"
        case .invalidData: return "Invalid event data"
        }
    }
}
