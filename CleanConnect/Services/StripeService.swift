// StripeService.swift
// Handles Stripe payments via Firebase Functions

import Foundation
import FirebaseFunctions

@MainActor
class StripeService: ObservableObject {
    static let shared = StripeService()

    private lazy var functions = Functions.functions()

    @Published var isLoading = false
    @Published var canReceivePayments = false
    @Published var hasStripeAccount = false

    private init() {}

    // MARK: - Connect Onboarding (For Creators)

    /// Start Stripe Connect onboarding for a creator
    /// Returns a URL to open in Safari for onboarding
    func startConnectOnboarding() async throws -> URL {
        isLoading = true
        defer { isLoading = false }

        let result = try await functions.httpsCallable("createConnectAccount").call()

        guard let data = result.data as? [String: Any],
              let urlString = data["url"] as? String,
              let url = URL(string: urlString) else {
            throw StripeError.invalidResponse
        }

        return url
    }

    /// Check if current user can receive payments
    func checkConnectStatus() async throws {
        isLoading = true
        defer { isLoading = false }

        let result = try await functions.httpsCallable("checkConnectStatus").call()

        guard let data = result.data as? [String: Any] else {
            throw StripeError.invalidResponse
        }

        hasStripeAccount = data["hasAccount"] as? Bool ?? false
        canReceivePayments = data["canReceivePayments"] as? Bool ?? false
    }

    /// Get link to Stripe Express Dashboard
    func getDashboardLink() async throws -> URL {
        isLoading = true
        defer { isLoading = false }

        let result = try await functions.httpsCallable("createDashboardLink").call()

        guard let data = result.data as? [String: Any],
              let urlString = data["url"] as? String,
              let url = URL(string: urlString) else {
            throw StripeError.invalidResponse
        }

        return url
    }

    // MARK: - Payments (For Tippers)

    /// Create a payment intent for tipping a creator
    /// - Parameters:
    ///   - amountInRupees: Amount in INR (e.g., 100 for ₹100)
    ///   - creatorId: The Firebase user ID of the creator
    ///   - postId: Optional post ID if tipping on a specific post
    /// - Returns: Client secret for Stripe SDK payment sheet
    func createTipPaymentIntent(
        amountInRupees: Int,
        creatorId: String,
        postId: String? = nil
    ) async throws -> PaymentIntentResult {
        isLoading = true
        defer { isLoading = false }

        // Convert to paise (1 rupee = 100 paise)
        let amountInPaise = amountInRupees * 100

        var params: [String: Any] = [
            "amount": amountInPaise,
            "creatorId": creatorId
        ]

        if let postId = postId {
            params["postId"] = postId
        }

        let result = try await functions.httpsCallable("createTipPaymentIntent").call(params)

        guard let data = result.data as? [String: Any],
              let clientSecret = data["clientSecret"] as? String,
              let paymentIntentId = data["paymentIntentId"] as? String else {
            throw StripeError.invalidResponse
        }

        return PaymentIntentResult(
            clientSecret: clientSecret,
            paymentIntentId: paymentIntentId
        )
    }
}

// MARK: - Models

struct PaymentIntentResult {
    let clientSecret: String
    let paymentIntentId: String
}

enum StripeError: LocalizedError {
    case invalidResponse
    case paymentFailed(String)
    case notConfigured
    case creatorNotSetup

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from payment server"
        case .paymentFailed(let message):
            return "Payment failed: \(message)"
        case .notConfigured:
            return "Payment system not configured"
        case .creatorNotSetup:
            return "This creator cannot receive tips yet"
        }
    }
}
