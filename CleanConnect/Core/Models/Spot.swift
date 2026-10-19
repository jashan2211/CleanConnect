import Foundation
import CoreLocation
import SwiftUI

enum SpotStatus: String, CaseIterable, Identifiable {
    case open, claimed, cleaned

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .open: "Needs cleaning"
        case .claimed: "Someone's on it"
        case .cleaned: "Cleaned"
        }
    }

    var shortTitle: LocalizedStringKey {
        switch self {
        case .open: "Dirty"
        case .claimed: "Claimed"
        case .cleaned: "Cleaned"
        }
    }

    var color: Color {
        switch self {
        case .open: .ccDirty
        case .claimed: .ccClaimed
        case .cleaned: .ccCleaned
        }
    }

    var icon: String {
        switch self {
        case .open: "exclamationmark.triangle.fill"
        case .claimed: "hand.raised.fill"
        case .cleaned: "checkmark.seal.fill"
        }
    }
}

enum SpotCategory: String, CaseIterable, Identifiable {
    case mixed, plastic, construction, drain, burning, water, walls, ewaste, organic

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .mixed: "Garbage dump"
        case .plastic: "Plastic litter"
        case .construction: "Construction debris"
        case .drain: "Blocked drain"
        case .burning: "Garbage burning"
        case .water: "River, lake or beach"
        case .walls: "Paan stains & walls"
        case .ewaste: "E-waste"
        case .organic: "Food & organic waste"
        }
    }

    var icon: String {
        switch self {
        case .mixed: "trash.fill"
        case .plastic: "waterbottle.fill"
        case .construction: "hammer.fill"
        case .drain: "drop.triangle.fill"
        case .burning: "flame.fill"
        case .water: "water.waves"
        case .walls: "paintbrush.pointed.fill"
        case .ewaste: "bolt.batteryblock.fill"
        case .organic: "leaf.fill"
        }
    }

    var tint: Color {
        switch self {
        case .mixed: Color(hex: 0x8A6E52)
        case .plastic: Color(hex: 0x2F80ED)
        case .construction: Color(hex: 0x8E8E93)
        case .drain: Color(hex: 0x5B7C99)
        case .burning: Color(hex: 0xE5484D)
        case .water: Color(hex: 0x0EA5B7)
        case .walls: Color(hex: 0xB4386C)
        case .ewaste: Color(hex: 0x7C5CDB)
        case .organic: Color(hex: 0x3F9B48)
        }
    }
}

enum SpotSize: String, CaseIterable, Identifiable {
    case bag, cart, truck

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .bag: "A few bags"
        case .cart: "Cart-load"
        case .truck: "Truck-load"
        }
    }

    var icon: String {
        switch self {
        case .bag: "bag.fill"
        case .cart: "cart.fill"
        case .truck: "truck.box.fill"
        }
    }
}

struct Spot: Identifiable, Hashable {
    var id: String
    var reporterId: String
    var reporterName: String
    var reporterPhoto: String?
    var status: SpotStatus
    var category: SpotCategory
    var size: SpotSize
    var note: String
    var lat: Double
    var lng: Double
    var locality: String
    var city: String
    var state: String
    var beforePhotos: [String]
    var afterPhotos: [String]
    var claimedBy: String?
    var claimedByName: String?
    var claimedAt: Date?
    var cleanedBy: String?
    var cleanedByName: String?
    var cleanedByPhoto: String?
    var cleanedAt: Date?
    var cleanupNote: String?
    var bags: Int
    var crew: Int
    var respectCount: Int
    var stillThereCount: Int
    var verifiedCount: Int
    var commentCount: Int
    var hidden: Bool
    var createdAt: Date
    var driveId: String?

    var coordinate: CLLocationCoordinate2D { .init(latitude: lat, longitude: lng) }
    var location: CLLocation { CLLocation(latitude: lat, longitude: lng) }
    var coverPhoto: String? { status == .cleaned ? (afterPhotos.first ?? beforePhotos.first) : beforePhotos.first }

    /// "Sarabha Nagar, Ludhiana" style label.
    var placeLabel: String {
        let parts = [locality, city].filter { !$0.isEmpty }
        var seen = Set<String>()
        let unique = parts.filter { seen.insert($0.lowercased()).inserted }
        return unique.isEmpty ? String(localized: "Unnamed place") : unique.joined(separator: ", ")
    }

    func isInvolved(_ uid: String?) -> Bool {
        guard let uid else { return false }
        return reporterId == uid || cleanedBy == uid || claimedBy == uid
    }

    static func == (lhs: Spot, rhs: Spot) -> Bool {
        lhs.id == rhs.id && lhs.status == rhs.status && lhs.respectCount == rhs.respectCount
            && lhs.stillThereCount == rhs.stillThereCount && lhs.verifiedCount == rhs.verifiedCount
            && lhs.commentCount == rhs.commentCount && lhs.afterPhotos == rhs.afterPhotos
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

extension Spot {
    init(_ d: Doc) {
        id = d.id
        reporterId = d.string("reporterId")
        reporterName = d.optString("reporterName") ?? String(localized: "Community member")
        reporterPhoto = d.optString("reporterPhoto")
        status = SpotStatus(rawValue: d.string("status")) ?? .open
        category = SpotCategory(rawValue: d.string("category")) ?? .mixed
        size = SpotSize(rawValue: d.string("size")) ?? .bag
        note = d.string("note")
        lat = d.double("lat")
        lng = d.double("lng")
        locality = d.string("locality")
        city = d.string("city")
        state = d.string("state")
        beforePhotos = d.strings("beforePhotos")
        afterPhotos = d.strings("afterPhotos")
        claimedBy = d.optString("claimedBy")
        claimedByName = d.optString("claimedByName")
        claimedAt = d.date("claimedAt")
        cleanedBy = d.optString("cleanedBy")
        cleanedByName = d.optString("cleanedByName")
        cleanedByPhoto = d.optString("cleanedByPhoto")
        cleanedAt = d.date("cleanedAt")
        cleanupNote = d.optString("cleanupNote")
        bags = d.int("bags")
        crew = max(d.int("crew"), 1)
        respectCount = d.int("respectCount")
        stillThereCount = d.int("stillThereCount")
        verifiedCount = d.int("verifiedCount")
        commentCount = d.int("commentCount")
        hidden = d.bool("hidden")
        createdAt = d.date("createdAt") ?? .now
        driveId = d.optString("driveId")
    }
}
