import Foundation
import CoreLocation

enum AppConfig {
    static let appStoreID = "6758537635"
    static let appStoreURL = URL(string: "https://apps.apple.com/app/id6758537635")!
    static let reviewURL = URL(string: "https://apps.apple.com/app/id6758537635?action=write-review")!
    static let privacyURL = URL(string: "https://thebighead.ca/cleanconnect/privacy")!
    static let termsURL = URL(string: "https://thebighead.ca/cleanconnect/terms")!
    static let guidelinesURL = URL(string: "https://thebighead.ca/cleanconnect/terms#community-guidelines")!
    static let supportURL = URL(string: "https://thebighead.ca/cleanconnect/support")!
    static let supportEmail = "info@thebighead.ca"
    static let functionsRegion = "us-central1"

    /// Launch with `-demo` to run on bundled sample data (used for App Store screenshots).
    static let isDemo = ProcessInfo.processInfo.arguments.contains("-demo")

    /// Debug builds only: launch with `-useEmulator` to talk to the local Firebase emulators.
    #if DEBUG
    static let useEmulator = ProcessInfo.processInfo.arguments.contains("-useEmulator")
    #else
    static let useEmulator = false
    #endif

    static var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    /// Fallback map centre when location is unavailable: New Delhi.
    static let fallbackCoordinate = CLLocationCoordinate2D(latitude: 28.6139, longitude: 77.2090)
}
