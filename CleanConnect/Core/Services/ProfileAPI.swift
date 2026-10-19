import Foundation
import FirebaseFirestore
import UIKit

enum LeaderboardPeriod: String, CaseIterable, Identifiable {
    case week, allTime
    var id: String { rawValue }
}

enum LeaderboardScope: Hashable {
    case india
    case state(String)
    case city(key: String, name: String)
}

struct ProfileEdits {
    var name: String
    var bio: String
    var city: String
    var state: String
    var upiId: String
    var supportURL: String
    var instagram: String
    var newPhoto: UIImage?
}

enum ProfileAPI {
    static func profile(_ uid: String) -> AsyncStream<Profile?> {
        if AppConfig.isDemo { return .just(DemoData.profiles.first { $0.id == uid } ?? DemoData.me) }
        return DB.profiles.document(uid).stream(Profile.init)
    }

    static func fetch(_ uid: String) async throws -> Profile? {
        if AppConfig.isDemo { return DemoData.profiles.first { $0.id == uid } ?? DemoData.me }
        let snap = try await DB.profiles.document(uid).getDocument()
        return snap.exists ? Profile(Doc(snap)) : nil
    }

    /// Creates the public profile on first sign-in. Counters are initialised server-side.
    static func createIfNeeded(uid: String, name: String?, photoURL: String?, place: Place?) async throws -> Bool {
        let ref = DB.profiles.document(uid)
        if try await ref.getDocument().exists { return false }
        var data: [String: Any] = [
            "name": String((name?.trimmed.isEmpty == false ? name! : String(localized: "Swachh Hero")).prefix(40)),
            "bio": "",
            "city": place?.city ?? "",
            "state": place?.state ?? "",
            "cityKey": CityKey.make(city: place?.city ?? "", state: place?.state ?? ""),
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
        ]
        if let photoURL { data["photoURL"] = photoURL }
        try await ref.setData(data)
        try await DB.userPrivate.document(uid).setData([
            "acceptedTermsAt": FieldValue.serverTimestamp(),
            "blocked": [String](),
        ], merge: true)
        return true
    }

    static func update(_ uid: String, edits: ProfileEdits) async throws {
        if AppConfig.isDemo { return }
        var data: [String: Any] = [
            "name": String(edits.name.trimmed.prefix(40)),
            "bio": String(edits.bio.trimmed.prefix(160)),
            "city": String(edits.city.trimmed.prefix(60)),
            "state": String(edits.state.trimmed.prefix(60)),
            "cityKey": CityKey.make(city: edits.city, state: edits.state),
            "updatedAt": FieldValue.serverTimestamp(),
        ]
        let upi = edits.upiId.trimmed.lowercased()
        data["upiId"] = UPI.isValid(upi) ? upi : FieldValue.delete()
        data["supportURL"] = SupportLink.valid(edits.supportURL) ?? FieldValue.delete()
        let insta = edits.instagram.trimmed.replacingOccurrences(of: "@", with: "")
        data["instagram"] = insta.isEmpty ? FieldValue.delete() : String(insta.prefix(30))
        if let photo = edits.newPhoto {
            let square = photo.resized(maxDimension: 600)
            data["photoURL"] = try await Media.upload(square, path: "avatars/\(uid)/avatar_\(Int(Date().timeIntervalSince1970)).jpg")
        }
        try await DB.profiles.document(uid).updateData(data)
    }

    // MARK: Leaderboards

    static func leaderboard(period: LeaderboardPeriod, scope: LeaderboardScope) async throws -> [Profile] {
        if AppConfig.isDemo {
            return DemoData.profiles.sorted {
                period == .week ? $0.weekPoints > $1.weekPoints : $0.points > $1.points
            }
        }
        var query: Query = DB.profiles
        switch scope {
        case .india: break
        case .state(let state): query = query.whereField("state", isEqualTo: state)
        case .city(let key, _): query = query.whereField("cityKey", isEqualTo: key)
        }
        switch period {
        case .week:
            query = query.whereField("weekKey", isEqualTo: WeekKey.current).order(by: "weekPoints", descending: true)
        case .allTime:
            query = query.order(by: "points", descending: true)
        }
        return try await query.limit(to: 100).fetch(Profile.init).filter { period == .week ? $0.weekPoints > 0 : $0.points > 0 }
    }

    // MARK: Stats

    static func indiaStats() -> AsyncStream<ImpactStats?> {
        if AppConfig.isDemo { return .just(DemoData.indiaStats) }
        return DB.stats.document("india").stream(ImpactStats.init)
    }

    static func cityStats(_ key: String) -> AsyncStream<ImpactStats?> {
        if AppConfig.isDemo { return .just(DemoData.cityStats) }
        guard !key.isEmpty else { return .just(nil) }
        return DB.cityStats.document(key).stream(ImpactStats.init)
    }
}

enum SupportLink {
    /// Accepts any https link (fundraiser, Instagram, website). Adds https:// when missing.
    static func valid(_ text: String) -> String? {
        var t = text.trimmed
        guard !t.isEmpty else { return nil }
        if !t.lowercased().hasPrefix("http") { t = "https://" + t }
        guard let url = URL(string: t), url.scheme == "https", let host = url.host, host.contains(".") else { return nil }
        return url.absoluteString
    }
}
