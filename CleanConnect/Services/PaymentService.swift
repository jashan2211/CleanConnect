// PaymentService.swift
// Payment-related operations (placeholder for future UPI/Razorpay integration)

import Foundation

class PaymentService {
    static let shared = PaymentService()
    private let dataManager = LocalDataManager.shared

    private init() {}

    // MARK: - Tipping

    func createTip(postId: String, recipientId: String, amount: Int) async throws -> Tip {
        guard let userId = await AuthManager.shared.currentUserId,
              let userName = await UserState.shared.currentUser?.displayName else {
            throw PaymentError.notAuthenticated
        }

        // Get recipient name
        let recipient = try? await UserService.shared.getUser(userId: recipientId)
        let recipientName = recipient?.displayName ?? "User"

        // Calculate fees (matching web app: 90% to creator, 5% platform, 5% payment gateway)
        let platformFee = Int(Double(amount) * AppConfig.Payment.platformFeePercent)
        let creatorReceives = Int(Double(amount) * AppConfig.Payment.creatorSharePercent)

        let tip = Tip(
            id: UUID().uuidString,
            postId: postId,
            senderId: userId,
            senderName: userName,
            recipientId: recipientId,
            recipientName: recipientName,
            amount: amount,
            platformFee: platformFee,
            creatorReceives: creatorReceives,
            status: .completed, // Demo mode
            paymentId: "demo_\(UUID().uuidString)",
            createdAt: Date()
        )

        // Update sender stats
        if var sender = await UserState.shared.currentUser {
            sender.tipsGiven += amount
            try dataManager.save(sender, to: "\(userId).json", in: "users")
            dataManager.setUserDefault(sender, forKey: StorageKeys.currentUser)
        }

        // Update recipient stats (if local user)
        if var recipient = try? await UserService.shared.getUser(userId: recipientId) {
            recipient.tipsReceived += creatorReceives
            recipient.totalPoints += creatorReceives / 10 // +1 pt per ₹10
            try dataManager.save(recipient, to: "\(recipientId).json", in: "users")
        }

        return tip
    }

    // MARK: - Service Booking Payment

    func createBookingPayment(bookingId: String, amount: Int) async throws -> String {
        guard await AuthManager.shared.currentUserId != nil else {
            throw PaymentError.notAuthenticated
        }

        // In demo mode, return a demo order ID
        // In production, this would integrate with Razorpay
        return "order_demo_\(UUID().uuidString)"
    }

    // MARK: - Fundraising Contribution

    func contributeToEvent(gatheringId: String, amount: Int) async throws {
        guard await AuthManager.shared.currentUserId != nil else {
            throw PaymentError.notAuthenticated
        }

        // Update gathering fundraising amount
        try await GatheringService.shared.contribute(gatheringId: gatheringId, amount: amount)
    }

    // MARK: - Wallet Operations

    func getWalletBalance(userId: String) async throws -> Int {
        if let user = try? await UserService.shared.getUser(userId: userId) {
            return user.tipsReceived - user.tipsGiven
        }
        return 0
    }

    // MARK: - UPI Payment (Placeholder)

    func initiateUPIPayment(amount: Int, upiId: String, note: String) async throws -> String {
        // Check UPI limit
        if amount > AppConfig.Payment.upiLimit {
            throw PaymentError.upiLimitExceeded
        }

        // In production, this would integrate with UPI SDK
        return "upi_demo_\(UUID().uuidString)"
    }

    func verifyPayment(paymentId: String) async throws -> Bool {
        // In production, verify with payment gateway
        return paymentId.hasPrefix("demo_") || paymentId.hasPrefix("upi_demo_") || paymentId.hasPrefix("order_demo_")
    }
}

struct BankDetails {
    let accountNumber: String
    let ifscCode: String
    let accountHolderName: String
}

enum PaymentError: LocalizedError {
    case notAuthenticated
    case orderCreationFailed
    case paymentFailed
    case insufficientBalance
    case kycRequired
    case upiLimitExceeded
    case invalidAmount

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "You must be signed in to make payments"
        case .orderCreationFailed: return "Failed to create payment order"
        case .paymentFailed: return "Payment failed"
        case .insufficientBalance: return "Insufficient balance"
        case .kycRequired: return "KYC verification required for this transaction"
        case .upiLimitExceeded: return "UPI transaction limit exceeded (₹1,00,000)"
        case .invalidAmount: return "Invalid payment amount"
        }
    }
}
