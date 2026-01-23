// CleaningCompany.swift
// Cleaning services marketplace models

import Foundation

struct CleaningCompany: Codable, Identifiable {
    let id: String

    // Basic info
    var name: String
    var description: String
    var logoURL: String?
    var coverImageURL: String?

    // Categories & Services
    var categories: [String]
    var serviceAreas: [String]

    // Pricing
    var startingPrice: Int

    // Ratings & Reviews
    var rating: Double
    var reviewCount: Int
    var completedJobs: Int

    // Contact
    var phone: String?
    var email: String?
    var website: String?
    var operatingHours: String?

    // Status
    var verified: Bool
    var isActive: Bool

    // Metadata
    var createdAt: Date
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, description, logoURL, coverImageURL
        case categories, serviceAreas, startingPrice
        case rating, reviewCount, completedJobs
        case phone, email, website, operatingHours
        case verified, isActive, createdAt, updatedAt
    }

    static let preview = CleaningCompany(
        id: "preview-company",
        name: "SparkleClean Services",
        description: "Professional cleaning services for homes and offices. We use eco-friendly products and offer satisfaction guarantee.",
        logoURL: nil,
        coverImageURL: nil,
        categories: ["residential", "commercial", "deep_cleaning"],
        serviceAreas: ["Mumbai", "Thane", "Navi Mumbai"],
        startingPrice: 999,
        rating: 4.7,
        reviewCount: 234,
        completedJobs: 1580,
        phone: "+91 98765 43210",
        email: "info@sparkleclean.com",
        website: "www.sparkleclean.com",
        operatingHours: "Mon-Sat: 8AM - 8PM",
        verified: true,
        isActive: true,
        createdAt: Date(),
        updatedAt: nil
    )
}

struct CleaningService: Codable, Identifiable {
    let id: String
    let companyId: String
    var name: String
    var description: String
    var price: Int
    var duration: String
    var includes: [String]?

    static let preview = CleaningService(
        id: "service-1",
        companyId: "company-1",
        name: "Basic Home Cleaning",
        description: "Complete cleaning of all rooms including dusting, mopping, and bathroom cleaning",
        price: 999,
        duration: "2-3 hours",
        includes: ["Dusting", "Mopping", "Bathroom cleaning", "Kitchen cleaning"]
    )
}

struct Review: Codable, Identifiable {
    let id: String
    let companyId: String
    let userId: String
    let userName: String
    let userPhotoURL: String?
    var rating: Int
    var text: String
    var images: [String]
    var helpfulCount: Int
    var bookingId: String?
    var createdAt: Date

    static let preview = Review(
        id: "review-1",
        companyId: "company-1",
        userId: "user-1",
        userName: "Priya Sharma",
        userPhotoURL: nil,
        rating: 5,
        text: "Excellent service! The team was professional and thorough. My house has never been cleaner!",
        images: [],
        helpfulCount: 12,
        bookingId: "booking-1",
        createdAt: Date().addingTimeInterval(-86400 * 3)
    )
}

struct Booking: Codable, Identifiable {
    let id: String
    let companyId: String
    let companyName: String
    let userId: String
    let serviceId: String?
    let serviceName: String?

    // Schedule
    var scheduledDate: Date
    var scheduledTime: String

    // Location
    var address: String
    var latitude: Double?
    var longitude: Double?

    // Pricing
    var serviceCharge: Int
    var gst: Int
    var totalAmount: Int

    // Status
    var status: BookingStatus
    var notes: String?

    // Metadata
    var createdAt: Date
    var updatedAt: Date?
    var completedAt: Date?

    enum BookingStatus: String, Codable {
        case pending
        case confirmed
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    static let preview = Booking(
        id: "booking-1",
        companyId: "company-1",
        companyName: "SparkleClean Services",
        userId: "user-1",
        serviceId: "service-1",
        serviceName: "Basic Home Cleaning",
        scheduledDate: Date().addingTimeInterval(86400 * 2),
        scheduledTime: "10:00 AM",
        address: "123 Main Street, Andheri West, Mumbai 400053",
        latitude: 19.1364,
        longitude: 72.8296,
        serviceCharge: 999,
        gst: 180,
        totalAmount: 1179,
        status: .confirmed,
        notes: nil,
        createdAt: Date(),
        updatedAt: nil,
        completedAt: nil
    )
}

struct Enquiry: Codable, Identifiable {
    let id: String
    let companyId: String
    let userId: String
    let userName: String
    var question: String
    var answer: String?
    var answeredAt: Date?
    var createdAt: Date
}
