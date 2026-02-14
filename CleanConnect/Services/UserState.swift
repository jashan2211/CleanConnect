// UserState.swift
// User state management (local mode)

import Foundation
import Combine
import SwiftUI

@MainActor
class UserState: ObservableObject {
    static let shared = UserState()

    @Published var currentUser: User?
    @Published var earnedBadges: [Badge] = []
    @Published var recentActivity: [UserActivity] = []
    @Published var wallet: Wallet?
    @Published var isLoading = false

    private var cancellables = Set<AnyCancellable>()
    private let dataManager = LocalDataManager.shared

    var levelProgress: Double {
        guard let user = currentUser else { return 0 }
        let level = ExperienceLevel.level(for: user.totalPoints)
        let pointsInLevel = user.totalPoints - level.minPoints
        let levelRange = min(level.maxPoints, 15000) - level.minPoints
        return Double(pointsInLevel) / Double(levelRange)
    }

    var nextLevelPoints: Int {
        guard let user = currentUser else { return 500 }
        let level = ExperienceLevel.level(for: user.totalPoints)
        return min(level.maxPoints, 15000) - user.totalPoints
    }

    private init() {
        setupAuthListener()
    }

    private func setupAuthListener() {
        AuthManager.shared.$currentUserId
            .sink { [weak self] userId in
                Task { @MainActor in
                    if let userId = userId {
                        await self?.loadUserData(userId: userId)
                    } else {
                        self?.clearUserData()
                    }
                }
            }
            .store(in: &cancellables)
    }

    func loadUserData(userId: String) async {
        isLoading = true

        // Load from local storage
        if let user = dataManager.getUserDefault(User.self, forKey: StorageKeys.currentUser) {
            currentUser = user
            loadBadges()
            loadRecentActivity()
            loadWallet(userId: userId)
        } else {
            // Try to load from file
            if let user = try? dataManager.load(User.self, from: "\(userId).json", in: "users") {
                currentUser = user
                dataManager.setUserDefault(user, forKey: StorageKeys.currentUser)
                loadBadges()
                loadRecentActivity()
                loadWallet(userId: userId)
            }
        }

        isLoading = false
    }

    private func loadBadges() {
        guard let user = currentUser else { return }
        earnedBadges = Badge.allBadges.filter { user.badges.contains($0.id) }
    }

    private func loadRecentActivity() {
        // No hardcoded activity - real activity comes from user actions
        recentActivity = []
    }

    private func loadWallet(userId: String) {
        wallet = Wallet(
            id: userId,
            userId: userId,
            balance: 0,
            totalEarned: currentUser?.tipsReceived ?? 0,
            totalSpent: currentUser?.tipsGiven ?? 0,
            lastUpdated: Date()
        )
    }

    func clearUserData() {
        currentUser = nil
        earnedBadges = []
        recentActivity = []
        wallet = nil
    }

    func updateProfile(displayName: String?, bio: String?, state: String?, district: String?) async throws {
        guard var user = currentUser else { return }

        if let displayName = displayName { user.displayName = displayName }
        if let bio = bio { user.bio = bio }
        if let state = state { user.state = state }
        if let district = district { user.district = district }

        // Save updated user
        try dataManager.save(user, to: "\(user.id).json", in: "users")
        dataManager.setUserDefault(user, forKey: StorageKeys.currentUser)
        currentUser = user
    }

    func updateStats(points: Int, wasteKg: Double) async throws {
        guard var user = currentUser else { return }

        user.totalPoints += points
        user.totalPosts += 1
        user.totalWasteKg += wasteKg

        // Check for level up
        let newLevel = ExperienceLevel.level(for: user.totalPoints)
        if newLevel.level > user.level {
            user.level = newLevel.level
            user.levelName = newLevel.name
        }

        // Save updated user
        try dataManager.save(user, to: "\(user.id).json", in: "users")
        dataManager.setUserDefault(user, forKey: StorageKeys.currentUser)
        currentUser = user
    }
}

struct Wallet: Codable, Identifiable {
    let id: String
    let userId: String
    var balance: Int
    var totalEarned: Int
    var totalSpent: Int
    var lastUpdated: Date
}
