// Gathering.swift
// Community event/gathering model

import Foundation

struct Gathering: Codable, Identifiable {
    let id: String
    let organizerId: String
    let organizerName: String
    let organizerPhotoURL: String?

    // Basic info
    var title: String
    var description: String
    var imageURL: String?

    // Date & Time
    var eventDate: Date
    var endDate: Date?
    var durationHours: Int?

    // Location
    var state: String
    var district: String
    var address: String?
    var latitude: Double?
    var longitude: Double?

    // Attendance
    var attendeesCount: Int
    var maxAttendees: Int?

    // Fundraising
    var fundraisingGoal: Int?
    var fundraisingRaised: Int?

    // Communication
    var whatsappGroupLink: String?

    // Status
    var status: String // upcoming, ongoing, completed, cancelled

    // Metadata
    var createdAt: Date
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, organizerId, organizerName, organizerPhotoURL
        case title, description, imageURL
        case eventDate, endDate, durationHours
        case state, district, address, latitude, longitude
        case attendeesCount, maxAttendees
        case fundraisingGoal, fundraisingRaised
        case whatsappGroupLink, status
        case createdAt, updatedAt
    }

    static let preview = Gathering(
        id: "preview-gathering",
        organizerId: "user-1",
        organizerName: "Test Organizer",
        organizerPhotoURL: nil,
        title: "Weekend Beach Cleanup Drive",
        description: "Join us for a community beach cleanup! We'll provide gloves and bags. Let's make our beach beautiful again!",
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
        whatsappGroupLink: "https://chat.whatsapp.com/example",
        status: "upcoming",
        createdAt: Date(),
        updatedAt: nil
    )
}

struct RSVP: Codable, Identifiable {
    let id: String
    let gatheringId: String
    let userId: String
    let userName: String
    let userPhotoURL: String?
    var status: RSVPStatus
    var note: String?
    var createdAt: Date

    enum RSVPStatus: String, Codable {
        case going
        case maybe
        case notGoing
    }
}

struct SupplyRequest: Codable, Identifiable {
    let id: String
    let gatheringId: String
    var type: String
    var name: String
    var needed: Int
    var pledged: Int
    var pledges: [SupplyPledge]?

    static let preview = SupplyRequest(
        id: "supply-1",
        gatheringId: "gathering-1",
        type: "gloves",
        name: "Cleaning Gloves",
        needed: 50,
        pledged: 30,
        pledges: nil
    )
}

struct SupplyPledge: Codable, Identifiable {
    let id: String
    let userId: String
    let userName: String
    var quantity: Int
    var status: PledgeStatus

    enum PledgeStatus: String, Codable {
        case pledged
        case delivered
        case cancelled
    }
}

struct GatheringUpdate: Codable, Identifiable {
    let id: String
    let gatheringId: String
    let authorId: String
    let authorName: String
    var content: String
    var imageURL: String?
    var createdAt: Date
}
