import Foundation
import MapKit

/// Minimal geohash encoder plus cell coverage for Firestore `in` queries.
enum Geohash {
    private static let base32 = Array("0123456789bcdefghjkmnpqrstuvwxyz")

    static func encode(lat: Double, lng: Double, precision: Int = 9) -> String {
        var latRange = (-90.0, 90.0)
        var lngRange = (-180.0, 180.0)
        var hash = ""
        var bit = 0
        var ch = 0
        var even = true
        while hash.count < precision {
            if even {
                let mid = (lngRange.0 + lngRange.1) / 2
                if lng >= mid { ch |= 1 << (4 - bit); lngRange.0 = mid } else { lngRange.1 = mid }
            } else {
                let mid = (latRange.0 + latRange.1) / 2
                if lat >= mid { ch |= 1 << (4 - bit); latRange.0 = mid } else { latRange.1 = mid }
            }
            even.toggle()
            if bit < 4 {
                bit += 1
            } else {
                hash.append(base32[ch])
                bit = 0
                ch = 0
            }
        }
        return hash
    }

    /// Size of one cell in degrees.
    static func cellSize(precision: Int) -> (lat: Double, lng: Double) {
        let bits = precision * 5
        let lngBits = (bits + 1) / 2
        let latBits = bits / 2
        return (180.0 / pow(2, Double(latBits)), 360.0 / pow(2, Double(lngBits)))
    }

    /// Cells of `precision` that cover the box, or nil when more than `limit` would be needed.
    static func cells(minLat: Double, maxLat: Double, minLng: Double, maxLng: Double,
                      precision: Int, limit: Int = 30) -> [String]? {
        let size = cellSize(precision: precision)
        var result = Set<String>()
        var lat = max(minLat, -89.9)
        while lat <= min(maxLat, 89.9) + size.lat {
            var lng = minLng
            while lng <= maxLng + size.lng {
                let clampedLat = min(max(lat, -89.9), 89.9)
                let wrappedLng = lng > 180 ? lng - 360 : (lng < -180 ? lng + 360 : lng)
                result.insert(encode(lat: clampedLat, lng: wrappedLng, precision: precision))
                if result.count > limit { return nil }
                lng += size.lng
            }
            lat += size.lat
        }
        return Array(result)
    }

    enum Coverage {
        case gh4([String])
        case gh3([String])
        case everywhere
    }

    /// Picks the finest stored precision that covers the region within Firestore's `in` limit.
    static func coverage(for region: MKCoordinateRegion) -> Coverage {
        let c = region.center
        let s = region.span
        let box = (minLat: c.latitude - s.latitudeDelta / 2, maxLat: c.latitude + s.latitudeDelta / 2,
                   minLng: c.longitude - s.longitudeDelta / 2, maxLng: c.longitude + s.longitudeDelta / 2)
        if let cells = cells(minLat: box.minLat, maxLat: box.maxLat, minLng: box.minLng, maxLng: box.maxLng, precision: 4) {
            return .gh4(cells)
        }
        if let cells = cells(minLat: box.minLat, maxLat: box.maxLat, minLng: box.minLng, maxLng: box.maxLng, precision: 3) {
            return .gh3(cells)
        }
        return .everywhere
    }
}

extension MKCoordinateRegion {
    static let india = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 22.3, longitude: 79.0),
        span: MKCoordinateSpan(latitudeDelta: 28, longitudeDelta: 28)
    )

    static func around(_ coordinate: CLLocationCoordinate2D, km: Double = 8) -> MKCoordinateRegion {
        MKCoordinateRegion(center: coordinate, latitudinalMeters: km * 1000, longitudinalMeters: km * 1000)
    }

    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        abs(coordinate.latitude - center.latitude) <= span.latitudeDelta / 2
            && abs(coordinate.longitude - center.longitude) <= span.longitudeDelta / 2
    }
}
