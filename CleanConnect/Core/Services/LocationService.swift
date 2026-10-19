import Foundation
import CoreLocation
import Observation

struct Place: Hashable {
    var locality: String
    var city: String
    var state: String

    var label: String {
        var seen = Set<String>()
        return [locality, city].filter { !$0.isEmpty && seen.insert($0.lowercased()).inserted }.joined(separator: ", ")
    }

    var cityLabel: String { [city, state].filter { !$0.isEmpty }.joined(separator: ", ") }
}

@Observable
@MainActor
final class LocationService: NSObject, CLLocationManagerDelegate {
    var authorization: CLAuthorizationStatus
    var location: CLLocation?
    var place: Place?

    private let manager = CLLocationManager()
    private var waiters: [CheckedContinuation<CLLocation?, Never>] = []

    override init() {
        authorization = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        if AppConfig.isDemo {
            location = CLLocation(latitude: DemoData.home.latitude, longitude: DemoData.home.longitude)
            place = DemoData.homePlace
            authorization = .authorizedWhenInUse
        }
    }

    var isAuthorized: Bool { authorization == .authorizedWhenInUse || authorization == .authorizedAlways }
    var isDenied: Bool { authorization == .denied || authorization == .restricted }
    var coordinate: CLLocationCoordinate2D? { location?.coordinate }

    func requestPermission() {
        guard !AppConfig.isDemo else { return }
        if authorization == .notDetermined {
            manager.requestWhenInUseAuthorization()
        } else if isAuthorized {
            manager.requestLocation()
        }
    }

    func refresh() {
        guard !AppConfig.isDemo, isAuthorized else { return }
        manager.requestLocation()
    }

    /// Fresh-ish location for pinning a report. Waits up to a few seconds.
    func currentLocation() async -> CLLocation? {
        if AppConfig.isDemo { return location }
        if let location, location.timestamp.timeIntervalSinceNow > -120 { return location }
        guard isAuthorized else { return location }
        manager.requestLocation()
        return await withCheckedContinuation { continuation in
            waiters.append(continuation)
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(6))
                self.flushWaiters()
            }
        }
    }

    func reverseGeocode(_ coordinate: CLLocationCoordinate2D) async -> Place? {
        if AppConfig.isDemo { return DemoData.homePlace }
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()
        guard let mark = try? await geocoder.reverseGeocodeLocation(location, preferredLocale: Locale(identifier: "en_IN")).first else {
            return nil
        }
        let city = mark.locality ?? mark.subAdministrativeArea ?? ""
        let locality = mark.subLocality ?? mark.thoroughfare ?? mark.name ?? ""
        return Place(locality: locality, city: city, state: mark.administrativeArea ?? "")
    }

    private func flushWaiters() {
        let pending = waiters
        waiters.removeAll()
        pending.forEach { $0.resume(returning: location) }
    }

    // MARK: CLLocationManagerDelegate

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            guard !AppConfig.isDemo else { return }
            self.authorization = status
            if self.isAuthorized { self.manager.requestLocation() }
            if self.isDenied { self.flushWaiters() }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        Task { @MainActor in
            guard !AppConfig.isDemo else { return }
            let previous = self.location
            self.location = latest
            self.flushWaiters()
            if self.place == nil || (previous.map { $0.distance(from: latest) > 2000 } ?? true) {
                self.place = await self.reverseGeocode(latest.coordinate)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in self.flushWaiters() }
    }
}
