import Foundation
import FirebaseFirestore
import FirebaseAuth
import MapKit
import UIKit

struct NewSpot {
    var photos: [UIImage] = []
    var category: SpotCategory = .mixed
    var size: SpotSize = .bag
    var note: String = ""
    var coordinate: CLLocationCoordinate2D?
    var place: Place?
}

struct CleanupReport {
    var photos: [UIImage] = []
    var bags: Int = 2
    var crew: Int = 1
    var note: String = ""
}

enum ReactionKind: String, CaseIterable {
    case respect, stillThere, verified

    var counterField: String { "\(rawValue)Count" }
}

enum SpotAPI {
    // MARK: Queries

    /// Spots inside a map region, newest first.
    static func spots(in region: MKCoordinateRegion) -> AsyncStream<[Spot]> {
        if AppConfig.isDemo { return .just(DemoData.spots.filter { region.contains($0.coordinate) }) }
        let query: Query
        switch Geohash.coverage(for: region) {
        case .gh4(let cells): query = DB.spots.whereField("gh4", in: cells).limit(to: 400)
        case .gh3(let cells): query = DB.spots.whereField("gh3", in: cells).limit(to: 400)
        case .everywhere: query = DB.spots.order(by: "createdAt", descending: true).limit(to: 400)
        }
        return query.stream { doc in
            let spot = Spot(doc)
            return spot.hidden ? nil : spot
        }
        .mapStream { $0.sorted { $0.createdAt > $1.createdAt } }
    }

    /// Most recent cleanups across India: the before/after feed.
    static func recentCleanups(limit: Int = 30) -> AsyncStream<[Spot]> {
        if AppConfig.isDemo { return .just(DemoData.spots.filter { $0.status == .cleaned }) }
        return DB.spots.order(by: "cleanedAt", descending: true).limit(to: limit)
            .stream { doc in
                let spot = Spot(doc)
                return spot.hidden ? nil : spot
            }
    }

    static func recentReports(limit: Int = 40) -> AsyncStream<[Spot]> {
        if AppConfig.isDemo { return .just(DemoData.spots) }
        return DB.spots.order(by: "createdAt", descending: true).limit(to: limit)
            .stream { doc in
                let spot = Spot(doc)
                return spot.hidden ? nil : spot
            }
    }

    static func spot(_ id: String) -> AsyncStream<Spot?> {
        if AppConfig.isDemo { return .just(DemoData.spots.first { $0.id == id }) }
        return DB.spots.document(id).stream(Spot.init)
    }

    static func reported(by uid: String) async throws -> [Spot] {
        if AppConfig.isDemo { return DemoData.spots.filter { $0.reporterId == uid } }
        return try await DB.spots.whereField("reporterId", isEqualTo: uid).limit(to: 100).fetch(Spot.init)
            .filter { !$0.hidden }.sorted { $0.createdAt > $1.createdAt }
    }

    static func cleaned(by uid: String) async throws -> [Spot] {
        if AppConfig.isDemo { return DemoData.spots.filter { $0.cleanedBy == uid } }
        return try await DB.spots.whereField("cleanedBy", isEqualTo: uid).limit(to: 100).fetch(Spot.init)
            .filter { !$0.hidden }.sorted { ($0.cleanedAt ?? $0.createdAt) > ($1.cleanedAt ?? $1.createdAt) }
    }

    // MARK: Writes

    static func create(_ draft: NewSpot, by profile: Profile) async throws -> String {
        guard let coordinate = draft.coordinate else { throw BackendError.message(String(localized: "Set the location first.")) }
        if AppConfig.isDemo { return DemoData.spots[0].id }
        let ref = DB.spots.document()
        let urls = try await Media.upload(draft.photos, folder: "spots/\(ref.documentID)", prefix: "before")
        let place = draft.place ?? Place(locality: "", city: "", state: "")
        let geohash = Geohash.encode(lat: coordinate.latitude, lng: coordinate.longitude)
        var data: [String: Any] = [
            "reporterId": profile.id,
            "reporterName": profile.name,
            "status": SpotStatus.open.rawValue,
            "category": draft.category.rawValue,
            "size": draft.size.rawValue,
            "note": String(draft.note.trimmed.prefix(280)),
            "lat": coordinate.latitude,
            "lng": coordinate.longitude,
            "geohash": geohash,
            "gh3": String(geohash.prefix(3)),
            "gh4": String(geohash.prefix(4)),
            "locality": place.locality,
            "city": place.city,
            "state": place.state,
            "cityKey": CityKey.make(city: place.city, state: place.state),
            "beforePhotos": urls,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
        ]
        if let photo = profile.photoURL { data["reporterPhoto"] = photo }
        try await ref.setData(data)
        return ref.documentID
    }

    static func claim(_ spot: Spot, by profile: Profile) async throws {
        if AppConfig.isDemo { return }
        try await DB.spots.document(spot.id).updateData([
            "status": SpotStatus.claimed.rawValue,
            "claimedBy": profile.id,
            "claimedByName": profile.name,
            "claimedAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp(),
        ])
    }

    static func unclaim(_ spot: Spot) async throws {
        if AppConfig.isDemo { return }
        try await DB.spots.document(spot.id).updateData([
            "status": SpotStatus.open.rawValue,
            "claimedBy": FieldValue.delete(),
            "claimedByName": FieldValue.delete(),
            "claimedAt": FieldValue.delete(),
            "updatedAt": FieldValue.serverTimestamp(),
        ])
    }

    static func markCleaned(_ spot: Spot, report: CleanupReport, by profile: Profile, driveId: String? = nil) async throws {
        if AppConfig.isDemo { return }
        let urls = try await Media.upload(report.photos, folder: "spots/\(spot.id)", prefix: "after")
        var data: [String: Any] = [
            "status": SpotStatus.cleaned.rawValue,
            "cleanedBy": profile.id,
            "cleanedByName": profile.name,
            "cleanedAt": FieldValue.serverTimestamp(),
            "afterPhotos": urls,
            "bags": min(max(report.bags, 0), 100),
            "crew": min(max(report.crew, 1), 500),
            "cleanupNote": String(report.note.trimmed.prefix(280)),
            "updatedAt": FieldValue.serverTimestamp(),
        ]
        if let photo = profile.photoURL { data["cleanedByPhoto"] = photo }
        if let driveId { data["driveId"] = driveId }
        try await DB.spots.document(spot.id).updateData(data)
    }

    static func delete(_ spot: Spot) async throws {
        if AppConfig.isDemo { return }
        try await DB.spots.document(spot.id).delete()
    }

    // MARK: Reactions

    static func myReactions(on spotId: String, uid: String) async -> Set<ReactionKind> {
        if AppConfig.isDemo { return [] }
        var result = Set<ReactionKind>()
        await withTaskGroup(of: ReactionKind?.self) { group in
            for kind in ReactionKind.allCases {
                group.addTask {
                    let snap = try? await DB.spots.document(spotId).collection("reactions").document("\(uid)_\(kind.rawValue)").getDocument()
                    return snap?.exists == true ? kind : nil
                }
            }
            for await kind in group { if let kind { result.insert(kind) } }
        }
        return result
    }

    static func setReaction(_ kind: ReactionKind, on spotId: String, uid: String, active: Bool) async throws {
        if AppConfig.isDemo { return }
        let ref = DB.spots.document(spotId).collection("reactions").document("\(uid)_\(kind.rawValue)")
        if active {
            try await ref.setData(["uid": uid, "type": kind.rawValue, "createdAt": FieldValue.serverTimestamp()])
        } else {
            try await ref.delete()
        }
    }
}

// MARK: - Comments (shared by spots and drives)

enum CommentAPI {
    static func comments(parent: DocumentReference) -> AsyncStream<[Comment]> {
        if AppConfig.isDemo { return .just(DemoData.comments) }
        return parent.collection("comments").order(by: "createdAt").limit(to: 200).stream(Comment.init)
    }

    static func add(_ text: String, parent: DocumentReference, by profile: Profile) async throws {
        if AppConfig.isDemo { return }
        var data: [String: Any] = [
            "authorId": profile.id,
            "authorName": profile.name,
            "text": String(text.trimmed.prefix(500)),
            "createdAt": FieldValue.serverTimestamp(),
        ]
        if let photo = profile.photoURL { data["authorPhoto"] = photo }
        try await parent.collection("comments").addDocument(data: data)
    }

    static func delete(_ comment: Comment, parent: DocumentReference) async throws {
        if AppConfig.isDemo { return }
        try await parent.collection("comments").document(comment.id).delete()
    }
}

extension AsyncStream {
    /// A stream that yields one value and stays open (mirrors a live listener with no updates).
    static func just(_ value: Element) -> AsyncStream<Element> {
        AsyncStream { continuation in continuation.yield(value) }
    }

    func mapStream<T>(_ transform: @escaping (Element) -> T) -> AsyncStream<T> {
        AsyncStream<T> { continuation in
            let task = Task {
                for await value in self { continuation.yield(transform(value)) }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
