// WatchSyncService.swift
// Handles data sync with Apple Watch companion app

import Foundation
import WatchConnectivity

// MARK: - Watch Sync Data Model

struct WatchSyncData: Codable {
    var totalWasteKg: Double
    var totalCleanups: Int
    var currentStreak: Int
    var todayWasteKg: Double
    var todayGoalKg: Double
    var pointsToday: Int
    var rank: Int
    var lastUpdated: Date

    static func fromUser(_ user: User) -> WatchSyncData {
        WatchSyncData(
            totalWasteKg: user.totalWasteKg,
            totalCleanups: user.totalPosts,
            currentStreak: user.currentStreak,
            todayWasteKg: 0, // Would calculate from today's posts
            todayGoalKg: 5.0,
            pointsToday: 0, // Would calculate from today's activity
            rank: 0, // Would come from leaderboard service
            lastUpdated: Date()
        )
    }
}

// MARK: - Watch Sync Service

@MainActor
@Observable
class WatchSyncService: NSObject {
    static let shared = WatchSyncService()

    var isWatchPaired = false
    var isWatchAppInstalled = false
    var isReachable = false
    var lastSyncDate: Date?

    private var session: WCSession?

    override init() {
        super.init()
        setupWatchConnectivity()
    }

    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else { return }

        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }

    // MARK: - Send Data to Watch

    func syncDataToWatch() {
        guard let session = session,
              session.isPaired,
              session.isWatchAppInstalled else { return }

        Task { @MainActor in
            guard let user = UserState.shared.currentUser else { return }

            let data = WatchSyncData.fromUser(user)

            do {
                let encoded = try JSONEncoder().encode(data)
                let context: [String: Any] = [
                    "type": "data_update",
                    "data": encoded
                ]

                try session.updateApplicationContext(context)
                lastSyncDate = Date()
            } catch {
                // Silently fail watch sync
            }
        }
    }

    func sendStreakNotification(streak: Int) {
        guard let session = session, session.isReachable else { return }

        let message: [String: Any] = [
            "type": "streak_update",
            "streak": streak
        ]

        session.sendMessage(message, replyHandler: nil) { _ in
            // Silently fail
        }
    }

    func sendAchievementNotification(title: String, message: String) {
        guard let session = session, session.isReachable else { return }

        let data: [String: Any] = [
            "type": "achievement",
            "title": title,
            "message": message
        ]

        session.sendMessage(data, replyHandler: nil) { _ in
            // Silently fail
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchSyncService: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            self.isWatchPaired = session.isPaired
            self.isWatchAppInstalled = session.isWatchAppInstalled
            self.isReachable = session.isReachable

            if activationState == .activated {
                self.syncDataToWatch()
            }
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        // Handle session becoming inactive
    }

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // Reactivate session
        session.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isReachable = session.isReachable
        }
    }

    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isWatchPaired = session.isPaired
            self.isWatchAppInstalled = session.isWatchAppInstalled
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        handleReceivedMessage(message, replyHandler: nil)
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        handleReceivedMessage(message, replyHandler: replyHandler)
    }

    nonisolated private func handleReceivedMessage(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)?) {
        guard let type = message["type"] as? String else {
            replyHandler?(["status": "error", "message": "Missing type"])
            return
        }

        Task { @MainActor in
            switch type {
            case "cleanup_log":
                await handleCleanupLog(message, replyHandler: replyHandler)

            case "request_sync":
                await handleSyncRequest(replyHandler: replyHandler)

            default:
                replyHandler?(["status": "unknown_type"])
            }
        }
    }

    @MainActor
    private func handleCleanupLog(_ message: [String: Any], replyHandler: (([String: Any]) -> Void)?) async {
        guard let wasteKg = message["waste_kg"] as? Double else {
            replyHandler?(["status": "error", "message": "Missing waste_kg"])
            return
        }

        do {
            // Log cleanup from watch
            try await UserState.shared.updateStats(points: 50, wasteKg: wasteKg)

            // Create a quick cleanup post
            try await PostService.shared.createPost(
                description: "Quick cleanup logged from Apple Watch",
                wasteCollectedKg: wasteKg,
                durationMinutes: message["duration"] as? Int,
                state: UserState.shared.currentUser?.state ?? "Unknown",
                district: UserState.shared.currentUser?.district ?? "Unknown",
                latitude: nil,
                longitude: nil,
                beforeImageData: nil,
                afterImageData: nil,
                videoProofURL: nil
            )

            replyHandler?(["status": "success", "points_earned": 50])

            // Sync updated data back to watch
            syncDataToWatch()
        } catch {
            replyHandler?(["status": "error", "message": error.localizedDescription])
        }
    }

    @MainActor
    private func handleSyncRequest(replyHandler: (([String: Any]) -> Void)?) async {
        guard let user = UserState.shared.currentUser else {
            replyHandler?(["status": "error", "message": "No user data"])
            return
        }

        let data = WatchSyncData.fromUser(user)

        do {
            let encoded = try JSONEncoder().encode(data)
            replyHandler?(["status": "success", "data": encoded])
            lastSyncDate = Date()
        } catch {
            replyHandler?(["status": "error", "message": "Encoding error"])
        }
    }
}
