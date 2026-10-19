import Foundation
import CoreLocation
import SwiftUI

enum DriveStatus: String {
    case upcoming, done, cancelled
}

/// Things volunteers bring or organisers provide at a drive.
enum DriveItem: String, CaseIterable, Identifiable {
    case gloves, bags, water, cap, mask, shoes, brooms, sunscreen, snacks, firstAid

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .gloves: "Gloves"
        case .bags: "Garbage bags"
        case .water: "Water bottle"
        case .cap: "Cap or hat"
        case .mask: "Mask"
        case .shoes: "Sturdy shoes"
        case .brooms: "Brooms & rakes"
        case .sunscreen: "Sunscreen"
        case .snacks: "Snacks"
        case .firstAid: "First-aid kit"
        }
    }

    var icon: String {
        switch self {
        case .gloves: "hand.raised.fill"
        case .bags: "bag.fill"
        case .water: "waterbottle.fill"
        case .cap: "sun.max.fill"
        case .mask: "facemask.fill"
        case .shoes: "shoe.fill"
        case .brooms: "wind"
        case .sunscreen: "sun.haze.fill"
        case .snacks: "takeoutbag.and.cup.and.straw.fill"
        case .firstAid: "cross.case.fill"
        }
    }
}

struct Drive: Identifiable, Hashable {
    var id: String
    var organizerId: String
    var organizerName: String
    var organizerPhoto: String?
    var title: String
    var about: String
    var startsAt: Date
    var durationMinutes: Int
    var lat: Double
    var lng: Double
    var address: String
    var city: String
    var state: String
    var spotId: String?
    var coverURL: String?
    var bring: [DriveItem]
    var providing: [DriveItem]
    var capacity: Int?
    var attendeeCount: Int
    var upiId: String?
    var whatsappLink: String?
    var status: DriveStatus
    var resultBags: Int
    var resultPhotos: [String]
    var commentCount: Int
    var hidden: Bool
    var createdAt: Date

    var coordinate: CLLocationCoordinate2D { .init(latitude: lat, longitude: lng) }
    var location: CLLocation { CLLocation(latitude: lat, longitude: lng) }
    var endsAt: Date { startsAt.addingTimeInterval(TimeInterval(durationMinutes * 60)) }
    var isPast: Bool { endsAt < .now || status == .done }
    var isFull: Bool { capacity.map { attendeeCount >= $0 } ?? false }
    var placeLabel: String { [address, city].filter { !$0.isEmpty }.joined(separator: ", ") }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Drive, rhs: Drive) -> Bool {
        lhs.id == rhs.id && lhs.attendeeCount == rhs.attendeeCount && lhs.status == rhs.status
            && lhs.commentCount == rhs.commentCount && lhs.resultPhotos == rhs.resultPhotos
    }
}

extension Drive {
    init(_ d: Doc) {
        id = d.id
        organizerId = d.string("organizerId")
        organizerName = d.optString("organizerName") ?? String(localized: "Organiser")
        organizerPhoto = d.optString("organizerPhoto")
        title = d.string("title")
        about = d.string("about")
        startsAt = d.date("startsAt") ?? .now
        durationMinutes = max(d.int("durationMinutes"), 30)
        lat = d.double("lat")
        lng = d.double("lng")
        address = d.string("address")
        city = d.string("city")
        state = d.string("state")
        spotId = d.optString("spotId")
        coverURL = d.optString("coverURL")
        bring = d.strings("bring").compactMap(DriveItem.init(rawValue:))
        providing = d.strings("providing").compactMap(DriveItem.init(rawValue:))
        capacity = d.optInt("capacity").flatMap { $0 > 0 ? $0 : nil }
        attendeeCount = d.int("attendeeCount")
        upiId = d.optString("upiId")
        whatsappLink = d.optString("whatsappLink")
        status = DriveStatus(rawValue: d.string("status")) ?? .upcoming
        resultBags = d.int("resultBags")
        resultPhotos = d.strings("resultPhotos")
        commentCount = d.int("commentCount")
        hidden = d.bool("hidden")
        createdAt = d.date("createdAt") ?? .now
    }
}

struct Attendee: Identifiable, Hashable {
    var id: String { uid }
    var uid: String
    var name: String
    var photoURL: String?
    var joinedAt: Date

    init(_ d: Doc) {
        uid = d.id
        name = d.optString("name") ?? String(localized: "Volunteer")
        photoURL = d.optString("photoURL")
        joinedAt = d.date("joinedAt") ?? .now
    }

    init(uid: String, name: String, photoURL: String?, joinedAt: Date = .now) {
        self.uid = uid
        self.name = name
        self.photoURL = photoURL
        self.joinedAt = joinedAt
    }
}
