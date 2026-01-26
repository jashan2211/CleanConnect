// AuthManager.swift
// Local Authentication manager (offline mode)

import Foundation
import SwiftUI

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var currentUserId: String?
    @Published var isAuthenticated = false
    @Published var isLoading = true

    private let dataManager = LocalDataManager.shared

    private init() {
        loadAuthState()
    }

    private func loadAuthState() {
        // Check if user was previously logged in
        if let userId = UserDefaults.standard.string(forKey: StorageKeys.isAuthenticated) {
            currentUserId = userId
            isAuthenticated = true
        }
        isLoading = false
    }

    // MARK: - Sign In With Name (Local User)

    func signInWithName(_ name: String, state: String?, district: String?) async throws {
        let userId = UUID().uuidString

        let newUser = User(
            id: userId,
            displayName: name,
            email: nil,
            photoURL: nil,
            bio: nil,
            state: state,
            district: district,
            pincode: nil,
            totalPoints: 0,
            totalPosts: 0,
            totalWasteKg: 0,
            totalEventsOrganized: 0,
            totalEventsAttended: 0,
            tipsReceived: 0,
            tipsGiven: 0,
            totalVolunteerHours: 0,
            totalSuppliesContributed: 0,
            totalDonationsAmount: 0,
            totalCO2Saved: 0,
            longestStreak: 0,
            currentStreak: 0,
            totalAreasImpacted: 0,
            videosVerified: 0,
            socialLinks: nil,
            level: 1,
            levelName: "Eco Scout",
            karmaScore: 0,
            followersCount: 0,
            followingCount: 0,
            badges: [],
            createdAt: Date(),
            lastActive: Date(),
            isAnonymous: false,
            verified: false,
            stripeAccountId: nil,
            stripeOnboardingComplete: nil
        )

        try dataManager.save(newUser, to: "\(userId).json", in: "users")
        dataManager.setUserDefault(newUser, forKey: StorageKeys.currentUser)

        UserDefaults.standard.set(userId, forKey: StorageKeys.isAuthenticated)
        currentUserId = userId
        isAuthenticated = true

        await UserState.shared.loadUserData(userId: userId)
    }

    // MARK: - Check Auth Status (sync with AuthenticationService)

    func checkAuthStatus() async {
        let authService = AuthenticationService.shared
        if authService.isAuthenticated, let user = authService.currentUser {
            currentUserId = user.id
            isAuthenticated = true
            await UserState.shared.loadUserData(userId: user.id)
        }
    }

    // MARK: - Sign Out

    func signOut() async throws {
        await AuthenticationService.shared.signOut()
        UserDefaults.standard.removeObject(forKey: StorageKeys.isAuthenticated)
        dataManager.removeUserDefault(forKey: StorageKeys.currentUser)
        currentUserId = nil
        isAuthenticated = false
        UserState.shared.clearUserData()
    }
}

enum AuthError: LocalizedError {
    case invalidCredential
    case userNotFound
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .invalidCredential: return "Invalid credentials"
        case .userNotFound: return "User not found"
        case .saveFailed: return "Failed to save user data"
        }
    }
}
