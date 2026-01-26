// WatchConnectivityManager.swift
// Handles data sync between iOS app and Apple Watch

import Foundation
import WatchConnectivity

// MARK: - Watch Connectivity Manager

class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    @Published var lastReceivedData: WatchCleanupData?
    @Published var isReachable = false

    private var session: WCSession?

    override init() {
        super.init()

        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    // MARK: - Send Data to iOS App

    func sendCleanupLog(wasteKg: Double, duration: Int? = nil) {
        guard let session = session, session.isReachable else {
            // Queue for later sync
            queueMessage(["type": "cleanup_log", "waste_kg": wasteKg, "duration": duration ?? 0])
            return
        }

        let message: [String: Any] = [
            "type": "cleanup_log",
            "waste_kg": wasteKg,
            "duration": duration ?? 0,
            "timestamp": Date().timeIntervalSince1970
        ]

        session.sendMessage(message, replyHandler: { response in
            print("Cleanup logged successfully: \(response)")
        }, errorHandler: { error in
            print("Error sending cleanup log: \(error.localizedDescription)")
        })
    }

    func requestDataSync() {
        guard let session = session, session.isReachable else { return }

        let message: [String: Any] = ["type": "request_sync"]

        session.sendMessage(message, replyHandler: { [weak self] response in
            if let data = response["data"] as? Data {
                do {
                    let cleanupData = try JSONDecoder().decode(WatchCleanupData.self, from: data)
                    DispatchQueue.main.async {
                        self?.lastReceivedData = cleanupData
                    }
                } catch {
                    print("Error decoding sync data: \(error)")
                }
            }
        }, errorHandler: { error in
            print("Error requesting sync: \(error.localizedDescription)")
        })
    }

    // MARK: - Queue Messages for Later

    private func queueMessage(_ message: [String: Any]) {
        var queued = UserDefaults.standard.array(forKey: "queued_messages") as? [[String: Any]] ?? []
        queued.append(message)
        UserDefaults.standard.set(queued, forKey: "queued_messages")
    }

    private func sendQueuedMessages() {
        guard let session = session, session.isReachable else { return }

        let queued = UserDefaults.standard.array(forKey: "queued_messages") as? [[String: Any]] ?? []
        guard !queued.isEmpty else { return }

        for message in queued {
            session.sendMessage(message, replyHandler: nil, errorHandler: nil)
        }

        UserDefaults.standard.removeObject(forKey: "queued_messages")
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }

        if activationState == .activated {
            sendQueuedMessages()
            requestDataSync()
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }

        if session.isReachable {
            sendQueuedMessages()
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        handleReceivedMessage(message)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        handleReceivedMessage(message)
        replyHandler(["status": "received"])
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        handleReceivedMessage(applicationContext)
    }

    private func handleReceivedMessage(_ message: [String: Any]) {
        if let type = message["type"] as? String {
            switch type {
            case "data_update":
                if let data = message["data"] as? Data {
                    do {
                        let cleanupData = try JSONDecoder().decode(WatchCleanupData.self, from: data)
                        DispatchQueue.main.async {
                            self.lastReceivedData = cleanupData
                        }
                    } catch {
                        print("Error decoding data: \(error)")
                    }
                }

            case "streak_update":
                if let streak = message["streak"] as? Int {
                    DispatchQueue.main.async {
                        self.lastReceivedData?.currentStreak = streak
                    }
                }

            default:
                break
            }
        }
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif
}

// MARK: - iOS App Side Handler

#if os(iOS)
import SwiftUI

class iOSWatchConnectivityHandler: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = iOSWatchConnectivityHandler()

    private var session: WCSession?

    override init() {
        super.init()

        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    // MARK: - Send Data to Watch

    func sendDataToWatch(data: WatchCleanupData) {
        guard let session = session, session.isPaired, session.isWatchAppInstalled else { return }

        do {
            let encoded = try JSONEncoder().encode(data)
            let context: [String: Any] = [
                "type": "data_update",
                "data": encoded
            ]

            try session.updateApplicationContext(context)
        } catch {
            print("Error sending data to watch: \(error)")
        }
    }

    func sendStreakUpdate(streak: Int) {
        guard let session = session, session.isReachable else { return }

        let message: [String: Any] = [
            "type": "streak_update",
            "streak": streak
        ]

        session.sendMessage(message, replyHandler: nil, errorHandler: nil)
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("iOS Watch session activated: \(activationState.rawValue)")
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        if let type = message["type"] as? String {
            switch type {
            case "cleanup_log":
                handleCleanupLog(message, replyHandler: replyHandler)

            case "request_sync":
                sendSyncResponse(replyHandler: replyHandler)

            default:
                replyHandler(["status": "unknown_type"])
            }
        }
    }

    private func handleCleanupLog(_ message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        guard let wasteKg = message["waste_kg"] as? Double else {
            replyHandler(["status": "error", "message": "Missing waste_kg"])
            return
        }

        let duration = message["duration"] as? Int

        // In real implementation, save this to the local database
        // and update user stats

        Task { @MainActor in
            do {
                try await UserState.shared.updateStats(points: 50, wasteKg: wasteKg)
                replyHandler(["status": "success", "points_earned": 50])
            } catch {
                replyHandler(["status": "error", "message": error.localizedDescription])
            }
        }
    }

    private func sendSyncResponse(replyHandler: @escaping ([String: Any]) -> Void) {
        Task { @MainActor in
            guard let user = UserState.shared.currentUser else {
                replyHandler(["status": "error", "message": "No user data"])
                return
            }

            let data = WatchCleanupData(
                totalWasteKg: user.totalWasteCollected,
                totalCleanups: user.totalCleanups,
                currentStreak: user.currentStreak,
                todayWasteKg: 0, // Would need to calculate from today's posts
                todayGoalKg: 5.0,
                pointsToday: 0, // Would need to calculate from today's activity
                rank: user.rank ?? 0,
                lastUpdated: Date()
            )

            do {
                let encoded = try JSONEncoder().encode(data)
                replyHandler(["status": "success", "data": encoded])
            } catch {
                replyHandler(["status": "error", "message": "Encoding error"])
            }
        }
    }
}
#endif
