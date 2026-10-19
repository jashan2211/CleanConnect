import Foundation
import FirebaseFirestore
import CoreLocation
import UIKit

struct NewDrive {
    var title: String = ""
    var about: String = ""
    var startsAt: Date = Calendar.current.nextDate(after: .now, matching: DateComponents(hour: 7, minute: 30),
                                                   matchingPolicy: .nextTime) ?? .now.addingTimeInterval(86_400)
    var durationMinutes: Int = 120
    var coordinate: CLLocationCoordinate2D?
    var place: Place?
    var address: String = ""
    var spotId: String?
    var cover: UIImage?
    var bring: Set<DriveItem> = [.water, .cap, .shoes]
    var providing: Set<DriveItem> = [.gloves, .bags]
    var capacity: Int = 0
    var upiId: String = ""
    var whatsappLink: String = ""
}

struct DriveResult {
    var photos: [UIImage] = []
    var bags: Int = 10
    var note: String = ""
}

enum DriveAPI {
    /// Upcoming drives across India (small volume, so we sort by distance on device).
    static func upcoming() -> AsyncStream<[Drive]> {
        if AppConfig.isDemo { return .just(DemoData.drives) }
        let since = Date.now.addingTimeInterval(-6 * 3600)
        return DB.drives.whereField("startsAt", isGreaterThan: Timestamp(date: since))
            .order(by: "startsAt").limit(to: 200)
            .stream { doc in
                let drive = Drive(doc)
                return drive.hidden || drive.status == .cancelled ? nil : drive
            }
    }

    static func recentlyCompleted() -> AsyncStream<[Drive]> {
        if AppConfig.isDemo { return .just([]) }
        return DB.drives.order(by: "completedAt", descending: true).limit(to: 20)
            .stream { doc in
                let drive = Drive(doc)
                return drive.hidden ? nil : drive
            }
    }

    static func drive(_ id: String) -> AsyncStream<Drive?> {
        if AppConfig.isDemo { return .just(DemoData.drives.first { $0.id == id }) }
        return DB.drives.document(id).stream(Drive.init)
    }

    static func attendees(_ driveId: String) -> AsyncStream<[Attendee]> {
        if AppConfig.isDemo { return .just(DemoData.attendees) }
        return DB.drives.document(driveId).collection("attendees").order(by: "joinedAt").limit(to: 300).stream(Attendee.init)
    }

    static func hosted(by uid: String) async throws -> [Drive] {
        if AppConfig.isDemo { return DemoData.drives.filter { $0.organizerId == uid } }
        return try await DB.drives.whereField("organizerId", isEqualTo: uid).limit(to: 100).fetch(Drive.init)
            .filter { !$0.hidden }.sorted { $0.startsAt > $1.startsAt }
    }

    static func joined(by uid: String) async throws -> [Drive] {
        if AppConfig.isDemo { return Array(DemoData.drives.prefix(1)) }
        let ids = try await DB.store.collectionGroup("attendees").whereField("uid", isEqualTo: uid).limit(to: 100)
            .getDocuments().documents.compactMap { $0.reference.parent.parent?.documentID }
        var drives = [Drive]()
        for chunk in stride(from: 0, to: ids.count, by: 30).map({ Array(ids[$0..<min($0 + 30, ids.count)]) }) {
            drives += try await DB.drives.whereField(FieldPath.documentID(), in: chunk).fetch(Drive.init)
        }
        return drives.filter { !$0.hidden }.sorted { $0.startsAt > $1.startsAt }
    }

    static func isAttending(_ driveId: String, uid: String) async -> Bool {
        if AppConfig.isDemo { return false }
        let snap = try? await DB.drives.document(driveId).collection("attendees").document(uid).getDocument()
        return snap?.exists == true
    }

    // MARK: Writes

    static func create(_ draft: NewDrive, by profile: Profile) async throws -> String {
        guard let coordinate = draft.coordinate else { throw BackendError.message(String(localized: "Pick a meeting point on the map.")) }
        if AppConfig.isDemo { return DemoData.drives[0].id }
        let ref = DB.drives.document()
        let place = draft.place ?? Place(locality: "", city: "", state: "")
        let geohash = Geohash.encode(lat: coordinate.latitude, lng: coordinate.longitude)
        var data: [String: Any] = [
            "organizerId": profile.id,
            "organizerName": profile.name,
            "title": String(draft.title.trimmed.prefix(80)),
            "about": String(draft.about.trimmed.prefix(1000)),
            "startsAt": Timestamp(date: draft.startsAt),
            "durationMinutes": draft.durationMinutes,
            "lat": coordinate.latitude,
            "lng": coordinate.longitude,
            "geohash": geohash,
            "gh3": String(geohash.prefix(3)),
            "gh4": String(geohash.prefix(4)),
            "address": String((draft.address.trimmed.isEmpty ? place.locality : draft.address.trimmed).prefix(160)),
            "city": place.city,
            "state": place.state,
            "cityKey": CityKey.make(city: place.city, state: place.state),
            "bring": DriveItem.allCases.filter { draft.bring.contains($0) }.map(\.rawValue),
            "providing": DriveItem.allCases.filter { draft.providing.contains($0) }.map(\.rawValue),
            "status": DriveStatus.upcoming.rawValue,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
        ]
        if let photo = profile.photoURL { data["organizerPhoto"] = photo }
        if let spotId = draft.spotId { data["spotId"] = spotId }
        if draft.capacity > 0 { data["capacity"] = draft.capacity }
        if UPI.isValid(draft.upiId) { data["upiId"] = draft.upiId.trimmed.lowercased() }
        if let link = WhatsApp.validGroupLink(draft.whatsappLink) { data["whatsappLink"] = link }
        if let cover = draft.cover {
            data["coverURL"] = try await Media.upload(cover, path: "drives/\(ref.documentID)/cover_\(Int(Date().timeIntervalSince1970)).jpg")
        }
        try await ref.setData(data)
        // The organiser is the first attendee.
        try? await join(ref.documentID, profile: profile)
        return ref.documentID
    }

    static func join(_ driveId: String, profile: Profile) async throws {
        if AppConfig.isDemo { return }
        var data: [String: Any] = ["uid": profile.id, "name": profile.name, "joinedAt": FieldValue.serverTimestamp()]
        if let photo = profile.photoURL { data["photoURL"] = photo }
        try await DB.drives.document(driveId).collection("attendees").document(profile.id).setData(data)
    }

    static func leave(_ driveId: String, uid: String) async throws {
        if AppConfig.isDemo { return }
        try await DB.drives.document(driveId).collection("attendees").document(uid).delete()
    }

    static func cancel(_ drive: Drive) async throws {
        if AppConfig.isDemo { return }
        try await DB.drives.document(drive.id).updateData([
            "status": DriveStatus.cancelled.rawValue,
            "updatedAt": FieldValue.serverTimestamp(),
        ])
    }

    static func complete(_ drive: Drive, result: DriveResult) async throws {
        if AppConfig.isDemo { return }
        let urls = try await Media.upload(result.photos, folder: "drives/\(drive.id)", prefix: "result")
        try await DB.drives.document(drive.id).updateData([
            "status": DriveStatus.done.rawValue,
            "resultBags": min(max(result.bags, 0), 1000),
            "resultPhotos": urls,
            "resultNote": String(result.note.trimmed.prefix(500)),
            "completedAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
        ])
    }
}

enum WhatsApp {
    static func validGroupLink(_ text: String) -> String? {
        let t = text.trimmed
        guard let url = URL(string: t), let host = url.host?.lowercased(),
              host == "chat.whatsapp.com" || host == "wa.me" else { return nil }
        return url.absoluteString
    }

    static func shareURL(text: String) -> URL? {
        var comps = URLComponents(string: "whatsapp://send")
        comps?.queryItems = [URLQueryItem(name: "text", value: text)]
        return comps?.url
    }
}
