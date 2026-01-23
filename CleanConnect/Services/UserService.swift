// UserService.swift
// User-related local operations

import Foundation

class UserService {
    static let shared = UserService()
    private let dataManager = LocalDataManager.shared

    private init() {}

    func getUser(userId: String) async throws -> User? {
        return try? dataManager.load(User.self, from: "\(userId).json", in: "users")
    }

    func updateUserStats(userId: String, points: Int, wasteKg: Double) async throws {
        guard var user = try await getUser(userId: userId) else { return }

        user.totalPoints += points
        user.totalPosts += 1
        user.totalWasteKg += wasteKg

        // Check for level up
        let newLevel = ExperienceLevel.level(for: user.totalPoints)
        if newLevel.level > user.level {
            user.level = newLevel.level
            user.levelName = newLevel.name
        }

        try dataManager.save(user, to: "\(userId).json", in: "users")
        dataManager.setUserDefault(user, forKey: StorageKeys.currentUser)
    }

    func awardBadge(userId: String, badgeId: String) async throws {
        guard var user = try await getUser(userId: userId) else { return }

        if !user.badges.contains(badgeId) {
            user.badges.append(badgeId)
            try dataManager.save(user, to: "\(userId).json", in: "users")
            dataManager.setUserDefault(user, forKey: StorageKeys.currentUser)
        }
    }

    func updateKarma(userId: String, delta: Int) async throws {
        guard var user = try await getUser(userId: userId) else { return }

        user.karmaScore += delta
        try dataManager.save(user, to: "\(userId).json", in: "users")
        dataManager.setUserDefault(user, forKey: StorageKeys.currentUser)
    }

    // Get all users for leaderboard
    func getAllUsers() async throws -> [User] {
        return (try? dataManager.loadAll(User.self, from: "users")) ?? []
    }
}
