// LeaderboardViewModel.swift
// View model for leaderboard view

import Foundation
import Combine

@MainActor
class LeaderboardViewModel: ObservableObject {
    @Published var entries: [LeaderboardEntry] = []
    @Published var isLoading = false

    func loadLeaderboard(scope: LeaderboardView.LeaderboardScope) {
        isLoading = true

        Task {
            do {
                var users = try await UserService.shared.getAllUsers()

                switch scope {
                case .state:
                    if let state = UserState.shared.currentUser?.state {
                        users = users.filter { $0.state == state }
                    }
                case .district:
                    if let district = UserState.shared.currentUser?.district {
                        users = users.filter { $0.district == district }
                    }
                case .city, .global:
                    break
                }

                // Sort by points and create entries
                let sortedUsers = users.sorted { $0.totalPoints > $1.totalPoints }

                entries = sortedUsers.enumerated().map { index, user in
                    LeaderboardEntry(
                        id: user.id,
                        userId: user.id,
                        displayName: user.displayName,
                        photoURL: user.photoURL,
                        points: user.totalPoints,
                        level: user.levelName,
                        rank: index + 1,
                        totalPosts: user.totalPosts,
                        totalWasteKg: user.totalWasteKg,
                        state: user.state,
                        district: user.district,
                        city: nil,
                        pincode: nil
                    )
                }

                // If no users, add sample entries
                if entries.isEmpty {
                    entries = createSampleLeaderboard()
                }
            } catch {
                entries = createSampleLeaderboard()
            }
            isLoading = false
        }
    }

    private func createSampleLeaderboard() -> [LeaderboardEntry] {
        return [
            LeaderboardEntry(id: "1", userId: "1", displayName: "Rajesh Kumar", photoURL: nil, points: 5420, level: "Eco Champion", rank: 1, totalPosts: 87, totalWasteKg: 432.5, state: "Maharashtra", district: "Mumbai", city: nil, pincode: nil),
            LeaderboardEntry(id: "2", userId: "2", displayName: "Priya Sharma", photoURL: nil, points: 4850, level: "Nature Defender", rank: 2, totalPosts: 72, totalWasteKg: 380.2, state: "Delhi", district: "South Delhi", city: nil, pincode: nil),
            LeaderboardEntry(id: "3", userId: "3", displayName: "Arjun Patel", photoURL: nil, points: 4200, level: "Nature Defender", rank: 3, totalPosts: 65, totalWasteKg: 325.0, state: "Gujarat", district: "Ahmedabad", city: nil, pincode: nil),
            LeaderboardEntry(id: "4", userId: "4", displayName: "Ananya Reddy", photoURL: nil, points: 3800, level: "Green Guardian", rank: 4, totalPosts: 58, totalWasteKg: 290.5, state: "Telangana", district: "Hyderabad", city: nil, pincode: nil),
            LeaderboardEntry(id: "5", userId: "5", displayName: "Vikram Singh", photoURL: nil, points: 3500, level: "Green Guardian", rank: 5, totalPosts: 52, totalWasteKg: 265.8, state: "Rajasthan", district: "Jaipur", city: nil, pincode: nil)
        ]
    }
}
