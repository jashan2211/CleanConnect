// PaymentService.swift
// Payment operations with Stripe integration

import Foundation
import UIKit

class PaymentService {
    static let shared = PaymentService()
    private let dataManager = LocalDataManager.shared

    // Stripe publishable key - safe to include in app
    static let stripePublishableKey = "pk_live_51S6I50EWkKqSfTvxHRJnHDwzzeExsrnUqDtE34JjcgHcZi2O5YwKNYaTd13l7sEQzliJ6Iy1EpjSMqmafgN2YzEq00Zy8Tn9Wy"

    private init() {}

    // MARK: - Tipping with Stripe

    /// Create a tip payment using Stripe
    /// - Parameters:
    ///   - postId: The post being tipped
    ///   - recipientId: The creator's user ID
    ///   - amount: Amount in rupees (e.g., 100 for ₹100)
    /// - Returns: Client secret for Stripe PaymentSheet
    func createTip(postId: String, recipientId: String, amount: Int) async throws -> Tip {
        guard let userId = await AuthManager.shared.currentUserId,
              let userName = await UserState.shared.currentUser?.displayName else {
            throw PaymentError.notAuthenticated
        }

        // Get recipient name
        let recipient = try? await UserService.shared.getUser(userId: recipientId)
        let recipientName = recipient?.displayName ?? "User"

        // Check if recipient can receive payments
        #if canImport(FirebaseFunctions)
        // Use real Stripe via Firebase Functions
        let result = try await StripeService.shared.createTipPaymentIntent(
            amountInRupees: amount,
            creatorId: recipientId,
            postId: postId
        )

        // Return tip with pending status - will be updated by webhook
        let tip = Tip(
            id: UUID().uuidString,
            postId: postId,
            senderId: userId,
            senderName: userName,
            recipientId: recipientId,
            recipientName: recipientName,
            amount: amount,
            platformFee: Int(Double(amount) * 0.10),
            creatorReceives: Int(Double(amount) * 0.90),
            status: .pending,
            paymentId: result.paymentIntentId,
            createdAt: Date()
        )

        return tip
        #else
        // Demo mode - simulate payment
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
            status: .completed,
            paymentId: "demo_\(UUID().uuidString)",
            createdAt: Date()
        )

        // Update local stats in demo mode
        if var sender = await UserState.shared.currentUser {
            sender.tipsGiven += amount
            try dataManager.save(sender, to: "\(userId).json", in: "users")
            dataManager.setUserDefault(sender, forKey: StorageKeys.currentUser)
        }

        if var recipient = try? await UserService.shared.getUser(userId: recipientId) {
            recipient.tipsReceived += creatorReceives
            recipient.totalPoints += creatorReceives / 10
            try dataManager.save(recipient, to: "\(recipientId).json", in: "users")
        }

        return tip
        #endif
    }

    /// Get the Stripe Payment Sheet client secret for completing payment
    func getPaymentClientSecret(amount: Int, creatorId: String, postId: String?) async throws -> String {
        #if canImport(FirebaseFunctions)
        let result = try await StripeService.shared.createTipPaymentIntent(
            amountInRupees: amount,
            creatorId: creatorId,
            postId: postId
        )
        return result.clientSecret
        #else
        throw PaymentError.notConfigured
        #endif
    }

    // MARK: - Creator Onboarding (Stripe Connect)

    /// Start Stripe Connect onboarding for a creator to receive payments
    func startCreatorOnboarding() async throws -> URL {
        #if canImport(FirebaseFunctions)
        return try await StripeService.shared.startConnectOnboarding()
        #else
        throw PaymentError.notConfigured
        #endif
    }

    /// Check if current user can receive payments
    func checkCanReceivePayments() async throws -> Bool {
        #if canImport(FirebaseFunctions)
        try await StripeService.shared.checkConnectStatus()
        return await StripeService.shared.canReceivePayments
        #else
        return false
        #endif
    }

    /// Get link to Stripe dashboard for creators
    func getStripeDashboardLink() async throws -> URL {
        #if canImport(FirebaseFunctions)
        return try await StripeService.shared.getDashboardLink()
        #else
        throw PaymentError.notConfigured
        #endif
    }

    // MARK: - Wallet & History

    func getWalletBalance(userId: String) async throws -> Int {
        if let user = try? await UserService.shared.getUser(userId: userId) {
            return user.tipsReceived - user.tipsGiven
        }
        return 0
    }

    func verifyPayment(paymentId: String) async throws -> Bool {
        // Demo payments are always verified
        if paymentId.hasPrefix("demo_") {
            return true
        }

        // Real Stripe payments are verified via webhooks
        // The webhook updates Firestore when payment succeeds
        return true
    }
}

// MARK: - Errors

enum PaymentError: LocalizedError {
    case notAuthenticated
    case orderCreationFailed
    case paymentFailed
    case insufficientBalance
    case kycRequired
    case upiLimitExceeded
    case invalidAmount
    case notConfigured
    case creatorNotSetup

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "You must be signed in to make payments"
        case .orderCreationFailed: return "Failed to create payment order"
        case .paymentFailed: return "Payment failed"
        case .insufficientBalance: return "Insufficient balance"
        case .kycRequired: return "KYC verification required for this transaction"
        case .upiLimitExceeded: return "UPI transaction limit exceeded (₹1,00,000)"
        case .invalidAmount: return "Invalid payment amount"
        case .notConfigured: return "Payments are not yet configured"
        case .creatorNotSetup: return "This creator cannot receive tips yet. They need to set up their payment account."
        }
    }
}
