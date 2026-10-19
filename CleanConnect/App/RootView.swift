import SwiftUI

struct RootView: View {
    @Environment(Session.self) private var session
    @Environment(LocationService.self) private var location
    @Environment(Router.self) private var router
    @AppStorage("cc.onboarded") private var onboarded = false

    var body: some View {
        @Bindable var session = session
        @Bindable var router = router

        ZStack {
            if !onboarded && !AppConfig.isDemo {
                OnboardingView { onboarded = true }
                    .transition(.opacity)
            } else if session.phase == .loading {
                SplashView()
            } else {
                MainTabView()
                    .transition(.opacity)
            }

            if let celebration = session.celebration {
                CelebrationOverlay(celebration: celebration) {
                    withAnimation(.easeOut(duration: 0.2)) { session.celebration = nil }
                }
                .zIndex(10)
                .transition(.opacity)
            }
        }
        .overlay(alignment: .top) {
            if let toast = session.toast {
                ToastView(toast: toast)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .task(id: toast.id) {
                        try? await Task.sleep(for: .seconds(2.8))
                        withAnimation(.snappy) { if session.toast?.id == toast.id { session.toast = nil } }
                    }
                    .zIndex(20)
            }
        }
        .animation(.snappy, value: session.toast)
        .animation(.easeInOut(duration: 0.3), value: onboarded)
        .sheet(item: $session.authPrompt) { prompt in
            SignInSheet(reason: prompt.reason)
        }
        .sheet(isPresented: $session.needsProfileSetup) {
            if let profile = session.profile {
                NavigationStack { EditProfileView(profile: profile, isFirstRun: true) }
            }
        }
        .fullScreenCover(isPresented: $router.showReport) {
            ReportSpotView()
        }
        .sheet(isPresented: $router.showCreateDrive) {
            CreateDriveView(spot: router.createDriveFor)
        }
        .task {
            session.start(location: location)
            if onboarded { location.requestPermission() }
        }
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            Color("LaunchBackground").ignoresSafeArea()
            Image("LaunchLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)
        }
    }
}

struct MainTabView: View {
    @Environment(Router.self) private var router

    var body: some View {
        @Bindable var router = router
        TabView(selection: $router.tab) {
            Tab("Home", systemImage: "house.fill", value: AppTab.home) {
                NavigationStack(path: router.path(.home)) { HomeView().withRoutes() }
            }
            Tab("Map", systemImage: "map.fill", value: AppTab.map) {
                NavigationStack(path: router.path(.map)) { MapScreen().withRoutes() }
            }
            Tab("Drives", systemImage: "person.3.fill", value: AppTab.drives) {
                NavigationStack(path: router.path(.drives)) { DrivesView().withRoutes() }
            }
            Tab("Leaders", systemImage: "trophy.fill", value: AppTab.leaders) {
                NavigationStack(path: router.path(.leaders)) { LeaderboardView().withRoutes() }
            }
            Tab("You", systemImage: "person.crop.circle.fill", value: AppTab.profile) {
                NavigationStack(path: router.path(.profile)) { MyProfileView().withRoutes() }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
    }
}

extension View {
    func withRoutes() -> some View {
        navigationDestination(for: Route.self) { route in
            switch route {
            case .spot(let id): SpotDetailView(spotId: id)
            case .drive(let id): DriveDetailView(driveId: id)
            case .profile(let id): PublicProfileView(uid: id)
            case .leaderboard: LeaderboardView()
            case .settings: SettingsView()
            case .blocked: BlockedUsersView()
            }
        }
    }
}
