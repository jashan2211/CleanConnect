import SwiftUI
import CoreLocation

struct DrivesView: View {
    enum Segment: String, CaseIterable, Identifiable {
        case nearby, india, mine
        var id: String { rawValue }
        var title: LocalizedStringKey {
            switch self {
            case .nearby: "Near me"
            case .india: "All India"
            case .mine: "My drives"
            }
        }
    }

    @Environment(Session.self) private var session
    @Environment(LocationService.self) private var location
    @Environment(Router.self) private var router
    @State private var segment: Segment = .nearby
    @State private var drives: [Drive] = []
    @State private var mine: [Drive] = []
    @State private var loaded = false

    private var origin: CLLocation {
        location.location ?? CLLocation(latitude: AppConfig.fallbackCoordinate.latitude, longitude: AppConfig.fallbackCoordinate.longitude)
    }

    private var list: [Drive] {
        let visible = drives.filter { !$0.isPast && !session.isBlocked($0.organizerId) }
        switch segment {
        case .nearby:
            return visible.filter { $0.location.distance(from: origin) < 60_000 }
                .sorted { $0.startsAt < $1.startsAt }
        case .india:
            return visible.sorted { $0.startsAt < $1.startsAt }
        case .mine:
            return mine
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                createCard
                Picker("Show", selection: $segment) {
                    ForEach(Segment.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)

                if list.isEmpty {
                    EmptyStateView(
                        icon: segment == .mine ? "flag.fill" : "calendar.badge.plus",
                        title: segment == .mine ? "No drives yet" : (loaded ? "No upcoming drives here" : "Loading drives…"),
                        message: segment == .mine ? "Drives you organise or join show up here." : "Be the one who gets the mohalla together. It takes a minute to set up.",
                        actionTitle: "Organise a drive",
                        action: { if session.gate("Sign in to organise a cleanup drive.") { router.startDrive(at: nil) } }
                    )
                    .ccCard(padding: 0)
                } else {
                    LazyVStack(spacing: 14) {
                        ForEach(list) { drive in
                            NavigationLink(value: Route.drive(drive.id)) {
                                DriveCard(drive: drive, origin: location.location, width: nil)
                            }
                            .buttonStyle(.pressable)
                        }
                    }
                }
            }
            .padding(Metrics.gutter)
            .padding(.bottom, 40)
            .readableWidth()
        }
        .background(Color.ccBackground)
        .navigationTitle("Cleanup drives")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    if session.gate("Sign in to organise a cleanup drive.") { router.startDrive(at: nil) }
                } label: { Image(systemName: "plus") }
                .accessibilityLabel(Text("Organise a drive"))
            }
        }
        .task {
            for await result in DriveAPI.upcoming() {
                drives = result
                loaded = true
            }
        }
        .task(id: "\(segment.rawValue)-\(session.uid ?? "")") {
            guard segment == .mine, let uid = session.uid else { mine = []; return }
            async let hosted = (try? await DriveAPI.hosted(by: uid)) ?? []
            async let joined = (try? await DriveAPI.joined(by: uid)) ?? []
            var seen = Set<String>()
            mine = (await hosted + joined).filter { seen.insert($0.id).inserted }.sorted { $0.startsAt > $1.startsAt }
        }
    }

    private var createCard: some View {
        Button {
            if session.gate("Sign in to organise a cleanup drive.") { router.startDrive(at: nil) }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "megaphone.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(.white.opacity(0.2), in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text("Organise a cleanup drive").font(.cc(.headline, weight: .bold)).foregroundStyle(.white)
                    Text("Pick a spot, set a time, invite your WhatsApp groups. +\(Points.hostDrive) pts")
                        .font(.cc(.caption, weight: .medium)).foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.white)
            }
            .padding(16)
            .background(LinearGradient.ccSaffron, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color.ccSaffron.opacity(0.3), radius: 12, y: 6)
        }
        .buttonStyle(.pressable)
    }
}
