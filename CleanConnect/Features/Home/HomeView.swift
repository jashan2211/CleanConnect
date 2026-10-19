import SwiftUI
import MapKit

@Observable
@MainActor
final class HomeModel {
    var nearby: [Spot] = []
    var cleanups: [Spot] = []
    var drives: [Drive] = []
    var india: ImpactStats?
    var city: ImpactStats?
    var weekLeaders: [Profile] = []
    var respected: Set<String> = []
    var loadedNearby = false
}

struct HomeView: View {
    @Environment(Session.self) private var session
    @Environment(LocationService.self) private var location
    @Environment(Router.self) private var router
    @State private var model = HomeModel()

    private var origin: CLLocation? { location.location }
    private var cityKey: String {
        if let p = session.profile, !p.city.isEmpty { return CityKey.make(city: p.city, state: p.state) }
        if let place = location.place { return CityKey.make(city: place.city, state: place.state) }
        return ""
    }
    private var cityName: String { session.profile?.city.nilIfEmpty ?? location.place?.city ?? "" }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                header
                heroCard
                if let profile = session.profile { progressCard(profile) }
                nearbySection
                drivesSection
                leadersSection
                cleanupsSection
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.bottom, 100)
            .readableWidth(720)
        }
        .background(Color.ccBackground)
        .scrollIndicators(.hidden)
        .overlay(alignment: .bottomTrailing) { reportButton }
        .toolbar(.hidden, for: .navigationBar)
        .refreshable { location.refresh() }
        .task(id: location.location.map { Int($0.coordinate.latitude * 50) * 100_000 + Int($0.coordinate.longitude * 50) }) {
            let center = location.coordinate ?? AppConfig.fallbackCoordinate
            for await spots in SpotAPI.spots(in: .around(center, km: 40)) {
                let visible = spots.filter { $0.status != .cleaned && !session.isBlocked($0.reporterId) }
                model.nearby = visible.sorted {
                    $0.location.distance(from: CLLocation(latitude: center.latitude, longitude: center.longitude))
                        < $1.location.distance(from: CLLocation(latitude: center.latitude, longitude: center.longitude))
                }
                model.loadedNearby = true
            }
        }
        .task {
            for await spots in SpotAPI.recentCleanups(limit: 25) {
                model.cleanups = spots.filter { !session.isBlocked($0.cleanedBy) }
            }
        }
        .task {
            for await drives in DriveAPI.upcoming() {
                let center = location.location ?? CLLocation(latitude: AppConfig.fallbackCoordinate.latitude, longitude: AppConfig.fallbackCoordinate.longitude)
                model.drives = drives.filter { !$0.isPast && !session.isBlocked($0.organizerId) }
                    .sorted { $0.location.distance(from: center) < $1.location.distance(from: center) }
            }
        }
        .task { for await stats in ProfileAPI.indiaStats() { model.india = stats } }
        .task(id: cityKey) { for await stats in ProfileAPI.cityStats(cityKey) { model.city = stats } }
        .task {
            model.weekLeaders = (try? await ProfileAPI.leaderboard(period: .week, scope: .india)) ?? []
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.ccLargeTitle)
                    .foregroundStyle(Color.ccInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Button {
                    location.requestPermission()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: location.isAuthorized ? "location.fill" : "location.slash.fill")
                        Text(location.place?.label.nilIfEmpty ?? (location.isAuthorized ? String(localized: "Finding you…") : String(localized: "Turn on location")))
                    }
                    .font(.cc(.subheadline, weight: .semibold))
                    .foregroundStyle(Color.ccInk2)
                }
                .buttonStyle(.plain)
            }
            Spacer()
            if let profile = session.profile {
                Button { router.tab = .profile } label: {
                    PointsPill(points: profile.points, streak: profile.liveStreak)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 8)
    }

    private var greeting: String {
        if let name = session.profile?.firstName, !name.isEmpty {
            return String(localized: "Namaste, \(name)")
        }
        return String(localized: "Namaste 🙏")
    }

    // MARK: Hero

    private var heroCard: some View {
        let stats = model.city.flatMap { $0.cleaned >= 25 ? $0 : nil } ?? model.india
        let isCity = model.city.map { $0.cleaned >= 25 } ?? false
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(isCity ? "\(cityName) is getting cleaner" : "India is getting cleaner")
                    .font(.cc(.subheadline, weight: .bold))
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
                Image(systemName: "sparkles").foregroundStyle(.white.opacity(0.9))
            }
            if let stats, stats.cleaned > 0 {
                HStack(alignment: .bottom, spacing: 18) {
                    heroStat(Fmt.compact(stats.cleaned), "spots cleaned")
                    heroStat(Fmt.compact(stats.bags), "bags removed")
                    heroStat(Fmt.compact(max(stats.volunteers, 1)), "cleaners")
                }
            } else {
                Text("Every clean street starts with one photo.")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Be one of the first cleaners in your city. Report a spot or clean one today.")
                    .font(.cc(.subheadline, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
            }
            HStack(spacing: 10) {
                Button {
                    if session.gate("Sign in to report a dirty spot and earn Swachh Points.") { router.showReport = true }
                } label: {
                    Label("Report", systemImage: "camera.fill").lineLimit(1)
                }
                .buttonStyle(PrimaryButtonStyle(tint: .white, foreground: .ccGreenDeep))

                Button {
                    router.tab = .map
                } label: {
                    Label("Find one", systemImage: "map.fill").lineLimit(1)
                }
                .buttonStyle(PrimaryButtonStyle(tint: .white.opacity(0.18), foreground: .white))
            }
        }
        .padding(20)
        .background {
            ZStack(alignment: .topTrailing) {
                LinearGradient.ccHero
                Image(systemName: "leaf.fill")
                    .font(.system(size: 150))
                    .foregroundStyle(.white.opacity(0.07))
                    .rotationEffect(.degrees(-20))
                    .offset(x: 40, y: -30)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Color.ccGreen.opacity(0.3), radius: 18, y: 10)
    }

    private func heroStat(_ value: String, _ label: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.ccNumber(30)).foregroundStyle(.white).contentTransition(.numericText())
                .lineLimit(1).minimumScaleFactor(0.5)
            Text(label).font(.ccCaption).foregroundStyle(.white.opacity(0.8)).lineLimit(1).minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Progress

    private func progressCard(_ profile: Profile) -> some View {
        let level = profile.level
        return HStack(spacing: 14) {
            LevelRing(progress: level.progress(points: profile.points), level: level, size: 58)
            VStack(alignment: .leading, spacing: 4) {
                Text(level.title).font(.cc(.headline, weight: .bold)).foregroundStyle(Color.ccInk)
                if let next = level.next {
                    Text("\(next.minPoints - profile.points) points to \(Text(next.title))")
                        .font(.cc(.footnote)).foregroundStyle(Color.ccInk2)
                } else {
                    Text("Top level reached. Legend!").font(.cc(.footnote)).foregroundStyle(Color.ccInk2)
                }
                ProgressView(value: level.progress(points: profile.points))
                    .tint(level.color)
            }
            VStack(spacing: 2) {
                Text("\(profile.thisWeekPoints)").font(.ccNumber(22)).foregroundStyle(Color.ccInk)
                Text("this week").font(.ccCaption).foregroundStyle(Color.ccInk2)
            }
        }
        .ccCard()
    }

    // MARK: Nearby

    private var nearbySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Needs cleaning near you", subtitle: model.nearby.isEmpty ? nil : "Tap one to claim it") {
                Button("Map") { router.tab = .map }.font(.cc(.subheadline, weight: .semibold))
            }
            if model.nearby.isEmpty {
                EmptyStateView(
                    icon: model.loadedNearby ? "checkmark.seal.fill" : "binoculars.fill",
                    title: model.loadedNearby ? "Nothing reported nearby yet" : "Looking around…",
                    message: "Spotted garbage on your street? Be the first to report it.",
                    actionTitle: "Report a spot",
                    action: { if session.gate("Sign in to report a dirty spot and earn Swachh Points.") { router.showReport = true } }
                )
                .ccCard(padding: 0)
            } else {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 12) {
                        ForEach(model.nearby.prefix(12)) { spot in
                            NavigationLink(value: Route.spot(spot.id)) {
                                SpotTile(spot: spot, origin: origin)
                            }
                            .buttonStyle(.pressable)
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, Metrics.gutter)
                }
                .padding(.horizontal, -Metrics.gutter)
                .scrollIndicators(.hidden)
            }
        }
    }

    // MARK: Drives

    @ViewBuilder
    private var drivesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Upcoming cleanup drives") {
                Button("All") { router.tab = .drives }.font(.cc(.subheadline, weight: .semibold))
            }
            if model.drives.isEmpty {
                HStack(spacing: 14) {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.ccSaffron)
                        .frame(width: 48, height: 48)
                        .background(Color.ccSaffronSoft, in: Circle())
                    VStack(alignment: .leading, spacing: 3) {
                        Text("No drives near you yet").font(.cc(.subheadline, weight: .bold)).foregroundStyle(Color.ccInk)
                        Text("Start one. Friends join on WhatsApp in a tap.").font(.cc(.caption)).foregroundStyle(Color.ccInk2)
                    }
                    Spacer()
                    Button("Start") {
                        if session.gate("Sign in to organise a cleanup drive.") { router.startDrive(at: nil) }
                    }
                    .buttonStyle(.secondary(.ccSaffron, fullWidth: false))
                }
                .ccCard()
            } else {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 12) {
                        ForEach(model.drives.prefix(8)) { drive in
                            NavigationLink(value: Route.drive(drive.id)) {
                                DriveCard(drive: drive, origin: origin)
                            }
                            .buttonStyle(.pressable)
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, Metrics.gutter)
                }
                .padding(.horizontal, -Metrics.gutter)
                .scrollIndicators(.hidden)
            }
        }
    }

    // MARK: Leaders

    @ViewBuilder
    private var leadersSection: some View {
        if !model.weekLeaders.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader("Top cleaners this week") {
                    Button("Leaderboard") { router.tab = .leaders }.font(.cc(.subheadline, weight: .semibold))
                }
                VStack(spacing: 0) {
                    ForEach(Array(model.weekLeaders.prefix(3).enumerated()), id: \.element.id) { index, profile in
                        NavigationLink(value: Route.profile(profile.id)) {
                            HStack(spacing: 12) {
                                Text(["🥇", "🥈", "🥉"][index]).font(.title2)
                                Avatar(url: profile.photoURL, name: profile.name, size: 40)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(profile.name).font(.cc(.subheadline, weight: .bold)).foregroundStyle(Color.ccInk)
                                    Text(profile.placeLabel.nilIfEmpty ?? String(localized: "India")).font(.cc(.caption)).foregroundStyle(Color.ccInk2)
                                }
                                Spacer()
                                Text("\(profile.thisWeekPoints)").font(.ccNumber(17)).foregroundStyle(Color.ccGreen)
                            }
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        if index < min(model.weekLeaders.count, 3) - 1 { Divider() }
                    }
                }
                .ccCard(padding: 14)
            }
        }
    }

    // MARK: Cleanups

    private var cleanupsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Fresh cleanups", subtitle: "Slide to see the difference")
            if model.cleanups.isEmpty {
                EmptyStateView(icon: "sparkles", title: "No cleanups yet",
                               message: "The first before/after in India could be yours.")
                    .ccCard(padding: 0)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(model.cleanups) { spot in
                        NavigationLink(value: Route.spot(spot.id)) {
                            CleanupCard(spot: spot)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var reportButton: some View {
        Button {
            if session.gate("Sign in to report a dirty spot and earn Swachh Points.") { router.showReport = true }
        } label: {
            Image(systemName: "camera.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 62, height: 62)
                .background(LinearGradient.ccHero, in: Circle())
                .shadow(color: Color.ccGreen.opacity(0.45), radius: 12, y: 6)
        }
        .accessibilityLabel(Text("Report a dirty spot"))
        .padding(.trailing, 20)
        .padding(.bottom, 16)
    }
}

extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
