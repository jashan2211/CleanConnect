import Foundation
import UserNotifications

/// Local reminders for drives you've joined. No server push needed.
enum Reminders {
    static func schedule(for drive: Drive) async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        }
        guard await center.notificationSettings().authorizationStatus == .authorized else { return }
        cancel(for: drive.id)

        let reminders: [(String, TimeInterval, String)] = [
            ("dayBefore", -18 * 3600, String(localized: "Tomorrow: \(drive.title). Keep gloves, water and a cap ready!")),
            ("soon", -90 * 60, String(localized: "\(drive.title) starts at \(Fmt.time(drive.startsAt)). See you at \(drive.address.isEmpty ? drive.city : drive.address)!")),
        ]
        for (suffix, offset, body) in reminders {
            let fire = drive.startsAt.addingTimeInterval(offset)
            guard fire > .now else { continue }
            let content = UNMutableNotificationContent()
            content.title = String(localized: "Cleanup drive reminder")
            content.body = body
            content.sound = .default
            content.userInfo = ["driveId": drive.id]
            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: "drive_\(drive.id)_\(suffix)", content: content, trigger: trigger))
        }
    }

    static func cancel(for driveId: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["drive_\(driveId)_dayBefore", "drive_\(driveId)_soon"])
    }
}
