// BookingService.swift
// Booking-related local operations

import Foundation

class BookingService {
    static let shared = BookingService()
    private let dataManager = LocalDataManager.shared

    private init() {
        createDirectoryIfNeeded()
    }

    private func createDirectoryIfNeeded() {
        let bookingsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("bookings")
        if !FileManager.default.fileExists(atPath: bookingsDir.path) {
            try? FileManager.default.createDirectory(at: bookingsDir, withIntermediateDirectories: true)
        }
    }

    func createBooking(
        companyId: String,
        companyName: String,
        serviceId: String?,
        serviceName: String?,
        scheduledDate: Date,
        scheduledTime: String,
        address: String,
        serviceCharge: Int,
        notes: String?
    ) async throws -> Booking {
        guard let userId = await AuthManager.shared.currentUserId else {
            throw BookingError.notAuthenticated
        }

        let bookingId = UUID().uuidString
        let gst = Int(Double(serviceCharge) * AppConfig.Payment.gstPercent)
        let total = serviceCharge + gst

        let booking = Booking(
            id: bookingId,
            companyId: companyId,
            companyName: companyName,
            userId: userId,
            serviceId: serviceId,
            serviceName: serviceName,
            scheduledDate: scheduledDate,
            scheduledTime: scheduledTime,
            address: address,
            latitude: nil,
            longitude: nil,
            serviceCharge: serviceCharge,
            gst: gst,
            totalAmount: total,
            status: .pending,
            notes: notes,
            createdAt: Date(),
            updatedAt: nil,
            completedAt: nil
        )

        try dataManager.save(booking, to: "\(bookingId).json", in: "bookings")
        return booking
    }

    func getBookings(userId: String, status: Booking.BookingStatus? = nil) async throws -> [Booking] {
        var bookings = (try? dataManager.loadAll(Booking.self, from: "bookings")) ?? []

        bookings = bookings.filter { $0.userId == userId }

        if let status = status {
            bookings = bookings.filter { $0.status == status }
        }

        return bookings.sorted { $0.createdAt > $1.createdAt }
    }

    func cancelBooking(bookingId: String) async throws {
        guard var booking = try? dataManager.load(Booking.self, from: "\(bookingId).json", in: "bookings") else {
            throw BookingError.notFound
        }

        guard booking.status == .pending || booking.status == .confirmed else {
            throw BookingError.cannotCancel
        }

        booking.status = .cancelled
        booking.updatedAt = Date()
        try dataManager.save(booking, to: "\(bookingId).json", in: "bookings")
    }

    func rescheduleBooking(bookingId: String, newDate: Date, newTime: String) async throws {
        guard var booking = try? dataManager.load(Booking.self, from: "\(bookingId).json", in: "bookings") else {
            throw BookingError.notFound
        }

        booking.scheduledDate = newDate
        booking.scheduledTime = newTime
        booking.status = .pending
        booking.updatedAt = Date()
        try dataManager.save(booking, to: "\(bookingId).json", in: "bookings")
    }

    func rateBooking(bookingId: String, rating: Int, reviewText: String) async throws {
        guard let booking = try? dataManager.load(Booking.self, from: "\(bookingId).json", in: "bookings") else {
            throw BookingError.notFound
        }

        guard booking.status == .completed else {
            throw BookingError.cannotReview
        }

        // Create review
        let review = Review(
            id: UUID().uuidString,
            companyId: booking.companyId,
            userId: booking.userId,
            userName: await UserState.shared.currentUser?.displayName ?? "User",
            userPhotoURL: nil,
            rating: rating,
            text: reviewText,
            images: [],
            helpfulCount: 0,
            bookingId: bookingId,
            createdAt: Date()
        )

        // Save review (would be in reviews directory)
        print("Review created: \(review.id)")
    }
}

enum BookingError: LocalizedError {
    case notAuthenticated
    case companyNotFound
    case notFound
    case unauthorized
    case cannotCancel
    case cannotReview

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "You must be signed in"
        case .companyNotFound: return "Company not found"
        case .notFound: return "Booking not found"
        case .unauthorized: return "You are not authorized to modify this booking"
        case .cannotCancel: return "This booking cannot be cancelled"
        case .cannotReview: return "Cannot review this booking"
        }
    }
}
