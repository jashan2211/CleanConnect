import SwiftUI
import FirebaseCore
import FirebaseFirestore
import GoogleSignIn

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        if FirebaseApp.app() == nil { FirebaseApp.configure() }
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: NSNumber(value: 100 * 1024 * 1024))
        Firestore.firestore().settings = settings
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }
}

@main
struct CleanConnectApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @State private var session = Session()
    @State private var location = LocationService()
    @State private var router = Router()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
                .environment(location)
                .environment(router)
                .tint(.ccGreen)
                .onOpenURL { url in
                    _ = GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}

enum AppTab: String, Hashable {
    case home, map, drives, leaders, profile
}

enum Route: Hashable {
    case spot(String)
    case drive(String)
    case profile(String)
    case leaderboard
    case settings
    case blocked
}

/// App-wide navigation state: selected tab and the global creation sheets.
@Observable
@MainActor
final class Router {
    var tab: AppTab = .home
    var paths: [AppTab: [Route]] = [:]
    var showReport = false
    var createDriveFor: Spot?
    var showCreateDrive = false
    var mapFocus: Spot?

    init() {
        guard AppConfig.isDemo else { return }
        // Screenshot automation: -tab profile -push spot:s1 -sheet report
        let defaults = UserDefaults.standard
        if let raw = defaults.string(forKey: "tab"), let tab = AppTab(rawValue: raw) { self.tab = tab }
        if let push = defaults.string(forKey: "push") {
            let parts = push.split(separator: ":").map(String.init)
            let route: Route? = switch (parts.first, parts.count > 1 ? parts[1] : nil) {
            case ("spot", let id?): .spot(id)
            case ("drive", let id?): .drive(id)
            case ("profile", let id?): .profile(id)
            case ("settings", _): .settings
            default: nil
            }
            if let route { paths[tab] = [route] }
        }
        switch defaults.string(forKey: "sheet") {
        case "report": showReport = true
        case "drive": showCreateDrive = true
        default: break
        }
    }

    func path(_ tab: AppTab) -> Binding<[Route]> {
        Binding(get: { self.paths[tab] ?? [] }, set: { self.paths[tab] = $0 })
    }

    func startDrive(at spot: Spot?) {
        createDriveFor = spot
        showCreateDrive = true
    }

    func showOnMap(_ spot: Spot) {
        mapFocus = spot
        tab = .map
    }
}
