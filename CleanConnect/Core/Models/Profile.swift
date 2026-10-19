import Foundation
import SwiftUI

struct Profile: Identifiable, Hashable {
    var id: String
    var name: String
    var photoURL: String?
    var bio: String
    var city: String
    var state: String
    var upiId: String?
    var supportURL: String?
    var instagram: String?
    var points: Int
    var weekKey: String
    var weekPoints: Int
    var reports: Int
    var cleanups: Int
    var bags: Int
    var drivesHosted: Int
    var drivesJoined: Int
    var verifications: Int
    var streak: Int
    var bestStreak: Int
    var lastActiveDay: String
    var createdAt: Date

    var level: Level { Level.for(points: points) }
    var badges: [Badge] { Badge.allCases.filter { $0.isEarned(by: self) } }
    var thisWeekPoints: Int { weekKey == WeekKey.current ? weekPoints : 0 }
    var firstName: String { name.split(separator: " ").first.map(String.init) ?? name }
    var placeLabel: String { [city, state].filter { !$0.isEmpty }.joined(separator: ", ") }

    /// Streak only counts if the person was active today or yesterday (IST).
    var liveStreak: Int {
        guard streak > 0 else { return 0 }
        return [DayKey.today, DayKey.yesterday].contains(lastActiveDay) ? streak : 0
    }

    var canReceiveSupport: Bool { upiId != nil || supportURL != nil }
}

extension Profile {
    init(_ d: Doc) {
        id = d.id
        name = d.optString("name") ?? String(localized: "Swachh Hero")
        photoURL = d.optString("photoURL")
        bio = d.string("bio")
        city = d.string("city")
        state = d.string("state")
        upiId = d.optString("upiId")
        supportURL = d.optString("supportURL")
        instagram = d.optString("instagram")
        points = d.int("points")
        weekKey = d.string("weekKey")
        weekPoints = d.int("weekPoints")
        reports = d.int("reports")
        cleanups = d.int("cleanups")
        bags = d.int("bags")
        drivesHosted = d.int("drivesHosted")
        drivesJoined = d.int("drivesJoined")
        verifications = d.int("verifications")
        streak = d.int("streak")
        bestStreak = d.int("bestStreak")
        lastActiveDay = d.string("lastActiveDay")
        createdAt = d.date("createdAt") ?? .now
    }

    static func placeholder(id: String, name: String, photoURL: String?) -> Profile {
        Profile(id: id, name: name, photoURL: photoURL, bio: "", city: "", state: "", upiId: nil,
                supportURL: nil, instagram: nil, points: 0, weekKey: "", weekPoints: 0, reports: 0,
                cleanups: 0, bags: 0, drivesHosted: 0, drivesJoined: 0, verifications: 0, streak: 0,
                bestStreak: 0, lastActiveDay: "", createdAt: .now)
    }
}

// MARK: - Points

/// Point values. The server (Cloud Functions) is the source of truth; these are for display.
enum Points {
    static let report = 10
    static let cleanup = 50
    static let perBag = 5
    static let maxBagsCounted = 20
    static let reportGotCleaned = 10
    static let verify = 5
    static let joinDrive = 15
    static let hostDrive = 20
    static let completeDrive = 30

    static func forCleanup(bags: Int) -> Int { cleanup + perBag * min(max(bags, 0), maxBagsCounted) }
}

// MARK: - Levels

struct Level: Identifiable, Equatable {
    let index: Int
    let minPoints: Int
    let title: LocalizedStringKey
    let icon: String
    let color: Color

    var id: Int { index }

    static let all: [Level] = [
        Level(index: 1, minPoints: 0, title: "Safai Starter", icon: "leaf.fill", color: Color(hex: 0x6BBF59)),
        Level(index: 2, minPoints: 100, title: "Swachh Sathi", icon: "hands.sparkles.fill", color: Color(hex: 0x12A365)),
        Level(index: 3, minPoints: 300, title: "Green Guardian", icon: "shield.lefthalf.filled", color: Color(hex: 0x0EA5B7)),
        Level(index: 4, minPoints: 750, title: "Clean Crusader", icon: "flame.fill", color: Color(hex: 0xF27A12)),
        Level(index: 5, minPoints: 1500, title: "Swachh Champion", icon: "trophy.fill", color: Color(hex: 0xE59A0B)),
        Level(index: 6, minPoints: 3000, title: "Swachh Legend", icon: "crown.fill", color: Color(hex: 0x7C5CDB)),
        Level(index: 7, minPoints: 6000, title: "Swachh Superstar", icon: "sparkles", color: Color(hex: 0xE5484D)),
    ]

    static func `for`(points: Int) -> Level {
        all.last { points >= $0.minPoints } ?? all[0]
    }

    var next: Level? { Level.all.first { $0.index == index + 1 } }

    func progress(points: Int) -> Double {
        guard let next else { return 1 }
        let span = Double(next.minPoints - minPoints)
        return min(max(Double(points - minPoints) / span, 0), 1)
    }

    static func == (lhs: Level, rhs: Level) -> Bool { lhs.index == rhs.index }
}

// MARK: - Badges

enum Badge: String, CaseIterable, Identifiable {
    case firstReport, sharpEye, firstCleanup, cleanMachine, swachhWarrior, hundredBags
    case driveCaptain, teamPlayer, weekStreak, monthStreak, truthKeeper

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .firstReport: "First Report"
        case .sharpEye: "Sharp Eye"
        case .firstCleanup: "First Cleanup"
        case .cleanMachine: "Clean Machine"
        case .swachhWarrior: "Swachh Warrior"
        case .hundredBags: "100 Bags"
        case .driveCaptain: "Drive Captain"
        case .teamPlayer: "Team Player"
        case .weekStreak: "7-Day Streak"
        case .monthStreak: "Unstoppable"
        case .truthKeeper: "Truth Keeper"
        }
    }

    var detail: LocalizedStringKey {
        switch self {
        case .firstReport: "Report your first dirty spot"
        case .sharpEye: "Report 10 dirty spots"
        case .firstCleanup: "Clean your first spot"
        case .cleanMachine: "Clean 10 spots"
        case .swachhWarrior: "Clean 50 spots"
        case .hundredBags: "Remove 100 bags of waste"
        case .driveCaptain: "Organise a cleanup drive"
        case .teamPlayer: "Join 5 cleanup drives"
        case .weekStreak: "Help out 7 days in a row"
        case .monthStreak: "Help out 30 days in a row"
        case .truthKeeper: "Verify 10 cleanups"
        }
    }

    var icon: String {
        switch self {
        case .firstReport: "eye.fill"
        case .sharpEye: "binoculars.fill"
        case .firstCleanup: "sparkles"
        case .cleanMachine: "bolt.fill"
        case .swachhWarrior: "shield.fill"
        case .hundredBags: "bag.fill"
        case .driveCaptain: "flag.fill"
        case .teamPlayer: "person.3.fill"
        case .weekStreak: "flame.fill"
        case .monthStreak: "flame.circle.fill"
        case .truthKeeper: "checkmark.seal.fill"
        }
    }

    var color: Color {
        switch self {
        case .firstReport, .sharpEye: .ccBlue
        case .firstCleanup, .cleanMachine, .swachhWarrior: .ccGreen
        case .hundredBags: Color(hex: 0x8A6E52)
        case .driveCaptain, .teamPlayer: .ccSaffron
        case .weekStreak, .monthStreak: .ccDirty
        case .truthKeeper: Color(hex: 0x7C5CDB)
        }
    }

    func isEarned(by p: Profile) -> Bool {
        switch self {
        case .firstReport: p.reports >= 1
        case .sharpEye: p.reports >= 10
        case .firstCleanup: p.cleanups >= 1
        case .cleanMachine: p.cleanups >= 10
        case .swachhWarrior: p.cleanups >= 50
        case .hundredBags: p.bags >= 100
        case .driveCaptain: p.drivesHosted >= 1
        case .teamPlayer: p.drivesJoined >= 5
        case .weekStreak: p.bestStreak >= 7
        case .monthStreak: p.bestStreak >= 30
        case .truthKeeper: p.verifications >= 10
        }
    }
}

// MARK: - Day / week keys (IST, shared with Cloud Functions)

enum DayKey {
    static var calendar: Calendar = {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = TimeZone(identifier: "Asia/Kolkata") ?? .current
        return cal
    }()

    static func key(for date: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    static var today: String { key(for: .now) }
    static var yesterday: String { key(for: .now.addingTimeInterval(-86_400)) }
}

enum WeekKey {
    static func key(for date: Date) -> String {
        let c = DayKey.calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return String(format: "%04d-W%02d", c.yearForWeekOfYear ?? 0, c.weekOfYear ?? 0)
    }

    static var current: String { key(for: .now) }
}

/// Normalised key used to group spots, profiles and stats by city.
enum CityKey {
    static func make(city: String, state: String) -> String {
        let c = city.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let s = state.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !c.isEmpty else { return "" }
        return "\(s)|\(c)".replacingOccurrences(of: "/", with: "-")
    }
}
