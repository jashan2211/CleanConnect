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
    var videoMessageURL: String?     // YouTube/video link from organizer
    var liveStreamURL: String?       // YouTube live stream for ongoing events

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
        case whatsappGroupLink, videoMessageURL, liveStreamURL, status
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
        videoMessageURL: "https://youtube.com/shorts/example123",
        liveStreamURL: nil,  // Set to YouTube live URL when event is ongoing
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

// MARK: - Reddit-Style Threaded Forum Comments

struct EventComment: Codable, Identifiable {
    let id: String
    let eventId: String
    let parentId: String? // nil for top-level comments
    let authorId: String
    let authorName: String
    let authorPhotoURL: String?

    var content: String
    var upvotes: Int
    var downvotes: Int
    var replyCount: Int
    var isOrganizer: Bool
    var isPinned: Bool

    var createdAt: Date
    var editedAt: Date?

    // Computed
    var score: Int { upvotes - downvotes }

    static let preview = EventComment(
        id: "comment-1",
        eventId: "event-1",
        parentId: nil,
        authorId: "user-1",
        authorName: "Rahul Sharma",
        authorPhotoURL: nil,
        content: "What should we bring? I have some extra trash bags at home.",
        upvotes: 12,
        downvotes: 1,
        replyCount: 3,
        isOrganizer: false,
        isPinned: false,
        createdAt: Date().addingTimeInterval(-3600),
        editedAt: nil
    )
}

struct CommentVote: Codable {
    let commentId: String
    let userId: String
    var isUpvote: Bool
    var createdAt: Date
}

// MARK: - Task Assignment System

struct EventTask: Codable, Identifiable {
    let id: String
    let eventId: String
    let creatorId: String

    var title: String
    var description: String?
    var category: TaskCategory
    var priority: TaskPriority
    var status: TaskStatus

    var assigneeId: String?
    var assigneeName: String?
    var maxVolunteers: Int
    var currentVolunteers: Int

    var dueTime: Date?
    var completedAt: Date?
    var createdAt: Date

    enum TaskCategory: String, Codable, CaseIterable {
        case setup = "Setup"
        case cleanup = "Cleanup"
        case registration = "Registration"
        case photography = "Photography"
        case refreshments = "Refreshments"
        case transport = "Transport"
        case safety = "Safety"
        case coordination = "Coordination"
        case other = "Other"

        var icon: String {
            switch self {
            case .setup: return "hammer.fill"
            case .cleanup: return "trash.fill"
            case .registration: return "person.badge.plus"
            case .photography: return "camera.fill"
            case .refreshments: return "cup.and.saucer.fill"
            case .transport: return "car.fill"
            case .safety: return "cross.case.fill"
            case .coordination: return "megaphone.fill"
            case .other: return "ellipsis.circle.fill"
            }
        }

        var color: String {
            switch self {
            case .setup: return "orange"
            case .cleanup: return "green"
            case .registration: return "blue"
            case .photography: return "purple"
            case .refreshments: return "brown"
            case .transport: return "indigo"
            case .safety: return "red"
            case .coordination: return "teal"
            case .other: return "gray"
            }
        }
    }

    enum TaskPriority: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
    }

    enum TaskStatus: String, Codable {
        case open = "Open"
        case assigned = "Assigned"
        case inProgress = "In Progress"
        case completed = "Completed"
        case cancelled = "Cancelled"
    }

    static let preview = EventTask(
        id: "task-1",
        eventId: "event-1",
        creatorId: "user-1",
        title: "Set up registration desk",
        description: "Arrange tables and chairs near the entrance for volunteer check-in",
        category: .registration,
        priority: .high,
        status: .open,
        assigneeId: nil,
        assigneeName: nil,
        maxVolunteers: 2,
        currentVolunteers: 0,
        dueTime: Date().addingTimeInterval(86400),
        completedAt: nil,
        createdAt: Date()
    )
}

struct TaskVolunteer: Codable, Identifiable {
    let id: String
    let taskId: String
    let userId: String
    let userName: String
    let userPhotoURL: String?
    var status: VolunteerStatus
    var joinedAt: Date

    enum VolunteerStatus: String, Codable {
        case volunteered
        case confirmed
        case completed
        case noShow
    }
}

// MARK: - Enhanced Supply System with Delivery

enum SupplyCategory: String, Codable, CaseIterable {
    case cleanupKit = "Cleanup Kit"
    case safetyGear = "Safety Gear"
    case foodRefreshments = "Food & Refreshments"
    case tools = "Tools"
    case custom = "Custom"
}

struct SupplyItem: Codable, Identifiable {
    let id: String
    let eventId: String
    let requesterId: String

    var category: String // SupplyCategory raw value
    var name: String
    var description: String?
    var quantity: Int
    var unit: String // pieces, kg, liters, boxes
    var estimatedCost: Int?

    var fulfilledQuantity: Int
    var deliveryAddress: String?
    var deliveryInstructions: String?

    var status: SupplyStatus
    var urgency: SupplyUrgency

    var createdAt: Date
    var neededBy: Date?

    enum SupplyStatus: String, Codable {
        case requested = "Requested"
        case partiallyFulfilled = "Partially Fulfilled"
        case fulfilled = "Fulfilled"
        case delivered = "Delivered"
        case cancelled = "Cancelled"
    }

    enum SupplyUrgency: String, Codable {
        case low = "Low"
        case medium = "Medium"
        case urgent = "Urgent"
    }

    var isFulfilled: Bool { fulfilledQuantity >= quantity }
    var fulfillmentPercentage: Double {
        guard quantity > 0 else { return 0 }
        return min(Double(fulfilledQuantity) / Double(quantity), 1.0)
    }

    static let preview = SupplyItem(
        id: "supply-item-1",
        eventId: "event-1",
        requesterId: "user-1",
        category: "Cleanup Kit",
        name: "Heavy-duty Garbage Bags",
        description: "Large 50L black garbage bags for collecting waste",
        quantity: 100,
        unit: "pieces",
        estimatedCost: 500,
        fulfilledQuantity: 40,
        deliveryAddress: "Juhu Beach, Near Lifeguard Station",
        deliveryInstructions: "Please deliver by 7 AM on event day",
        status: .partiallyFulfilled,
        urgency: .medium,
        createdAt: Date(),
        neededBy: Date().addingTimeInterval(86400 * 3)
    )
}

struct SupplyContribution: Codable, Identifiable {
    let id: String
    let supplyItemId: String
    let contributorId: String
    let contributorName: String
    let contributorPhotoURL: String?

    var quantity: Int
    var isMonetary: Bool // true if paying for it, false if providing physical item
    var amount: Int? // if monetary contribution

    var deliveryMethod: DeliveryMethod
    var trackingInfo: String?
    var status: ContributionStatus

    var createdAt: Date
    var deliveredAt: Date?

    enum DeliveryMethod: String, Codable {
        case dropOff = "Drop Off at Event"
        case shipping = "Shipping to Address"
        case handover = "Handover to Organizer"
        case purchase = "Purchase & Deliver"
    }

    enum ContributionStatus: String, Codable {
        case pledged = "Pledged"
        case preparing = "Preparing"
        case shipped = "Shipped"
        case delivered = "Delivered"
        case cancelled = "Cancelled"
    }

    static let preview = SupplyContribution(
        id: "contrib-1",
        supplyItemId: "supply-item-1",
        contributorId: "user-2",
        contributorName: "Priya Patel",
        contributorPhotoURL: nil,
        quantity: 20,
        isMonetary: false,
        amount: nil,
        deliveryMethod: .dropOff,
        trackingInfo: nil,
        status: .pledged,
        createdAt: Date(),
        deliveredAt: nil
    )
}

// MARK: - Pre-defined Supply Templates

struct SupplyTemplate {
    let category: String
    let items: [(name: String, unit: String, defaultQty: Int)]

    static let cleanupKit = SupplyTemplate(
        category: "Cleanup Kit",
        items: [
            ("Garbage Bags (Large)", "pieces", 50),
            ("Disposable Gloves", "pairs", 100),
            ("Trash Pickers/Grabbers", "pieces", 20),
            ("Face Masks", "pieces", 50),
            ("Hand Sanitizer", "bottles", 10),
            ("Recycling Bags (Color-coded)", "sets", 20)
        ]
    )

    static let safetyGear = SupplyTemplate(
        category: "Safety Gear",
        items: [
            ("First Aid Kit", "kits", 3),
            ("Safety Vests", "pieces", 10),
            ("Sunscreen", "bottles", 5),
            ("Insect Repellent", "bottles", 5),
            ("Drinking Water (for emergencies)", "liters", 20)
        ]
    )

    static let foodRefreshments = SupplyTemplate(
        category: "Food & Refreshments",
        items: [
            ("Bottled Water", "bottles", 100),
            ("Energy Drinks", "bottles", 30),
            ("Biscuit Packets", "packets", 50),
            ("Fruit (Bananas/Apples)", "kg", 10),
            ("Tea/Coffee Supplies", "sets", 2)
        ]
    )

    static let tools = SupplyTemplate(
        category: "Tools",
        items: [
            ("Brooms", "pieces", 10),
            ("Dustpans", "pieces", 10),
            ("Buckets", "pieces", 10),
            ("Rakes", "pieces", 5),
            ("Wheelbarrows", "pieces", 2)
        ]
    )

    static let all: [SupplyTemplate] = [cleanupKit, safetyGear, foodRefreshments, tools]
}
