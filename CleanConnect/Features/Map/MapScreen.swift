import SwiftUI
import MapKit

enum MapFilter: String, CaseIterable, Identifiable {
    case all, dirty, cleaned, drives
    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .all: "All"
        case .dirty: "Needs cleaning"
        case .cleaned: "Cleaned"
        case .drives: "Drives"
        }
    }

    var icon: String {
        switch self {
        case .all: "square.grid.2x2.fill"
        case .dirty: "exclamationmark.triangle.fill"
        case .cleaned: "checkmark.seal.fill"
        case .drives: "person.3.fill"
        }
    }

    var tint: Color {
        switch self {
        case .all: .ccInk
        case .dirty: .ccDirty
        case .cleaned: .ccCleaned
        case .drives: .ccSaffron
        }
    }
}

enum MapItem: Identifiable, Hashable {
    case spot(Spot)
    case drive(Drive)

    var id: String {
        switch self {
        case .spot(let s): "s_\(s.id)"
        case .drive(let d): "d_\(d.id)"
        }
    }
}

struct MapScreen: View {
    @Environment(Session.self) private var session
    @Environment(LocationService.self) private var location
    @Environment(Router.self) private var router

    @State private var camera: MapCameraPosition = .userLocation(fallback: .region(.around(AppConfig.fallbackCoordinate, km: 30)))
    @State private var region: MKCoordinateRegion?
    @State private var queryRegion: MKCoordinateRegion?
    @State private var spots: [Spot] = []
    @State private var drives: [Drive] = []
    @State private var filter: MapFilter = .all
    @State private var selection: MapItem?
    @State private var showList = false

    private var visibleSpots: [Spot] {
        spots.filter { spot in
            guard !session.isBlocked(spot.reporterId) else { return false }
            switch filter {
            case .all: return true
            case .dirty: return spot.status != .cleaned
            case .cleaned: return spot.status == .cleaned
            case .drives: return false
            }
        }
    }

    private var visibleDrives: [Drive] {
        guard filter == .all || filter == .drives else { return [] }
        return drives.filter { !$0.isPast && !session.isBlocked($0.organizerId) }
    }

    var body: some View {
        Map(position: $camera, selection: $selection) {
            UserAnnotation()
            ForEach(visibleSpots) { spot in
                Annotation(spot.category.rawValue, coordinate: spot.coordinate, anchor: .bottom) {
                    SpotPin(spot: spot, selected: selection == .spot(spot))
                }
                .tag(MapItem.spot(spot))
                .annotationTitles(.hidden)
            }
            ForEach(visibleDrives) { drive in
                Annotation(drive.title, coordinate: drive.coordinate, anchor: .bottom) {
                    DrivePin(selected: selection == .drive(drive))
                }
                .tag(MapItem.drive(drive))
                .annotationTitles(.hidden)
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll, showsTraffic: false))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            region = context.region
            if shouldRequery(for: context.region) { queryRegion = context.region }
        }
        .task(id: queryRegion.map(regionKey)) {
            guard let queryRegion else { return }
            let padded = MKCoordinateRegion(center: queryRegion.center,
                                            span: MKCoordinateSpan(latitudeDelta: queryRegion.span.latitudeDelta * 1.6,
                                                                   longitudeDelta: queryRegion.span.longitudeDelta * 1.6))
            for await result in SpotAPI.spots(in: padded) {
                withAnimation(.snappy) { spots = result }
            }
        }
        .task {
            for await result in DriveAPI.upcoming() { drives = result }
        }
        .safeAreaInset(edge: .top) { filterBar }
        .safeAreaInset(edge: .bottom) { bottomPanel }
        .overlay(alignment: .trailing) { sideControls }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showList) { listSheet }
        .onChange(of: router.mapFocus) { _, spot in
            guard let spot else { return }
            withAnimation(.smooth) {
                camera = .region(.around(spot.coordinate, km: 1.5))
                selection = .spot(spot)
            }
            router.mapFocus = nil
        }
        .onChange(of: selection) { _, item in
            if item != nil { Haptics.selection() }
        }
        .onAppear {
            guard region == nil else { return }
            if AppConfig.isDemo {
                camera = .region(.around(DemoData.home, km: 9))
            } else if let c = location.coordinate {
                camera = .region(.around(c, km: 8))
            }
        }
    }

    // MARK: Querying

    private func regionKey(_ r: MKCoordinateRegion) -> String {
        String(format: "%.3f,%.3f,%.3f", r.center.latitude, r.center.longitude, r.span.latitudeDelta)
    }

    private func shouldRequery(for new: MKCoordinateRegion) -> Bool {
        guard let old = queryRegion else { return true }
        let moved = abs(new.center.latitude - old.center.latitude) > old.span.latitudeDelta * 0.35
            || abs(new.center.longitude - old.center.longitude) > old.span.longitudeDelta * 0.35
        let zoomed = new.span.latitudeDelta > old.span.latitudeDelta * 1.5 || new.span.latitudeDelta < old.span.latitudeDelta / 3
        return moved || zoomed
    }

    // MARK: Chrome

    private var filterBar: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(MapFilter.allCases) { f in
                    Chip(title: f.title, icon: f.icon, isSelected: filter == f, tint: f == .all ? .ccGreen : f.tint) {
                        filter = f
                        selection = nil
                    }
                }
            }
            .padding(.horizontal, Metrics.gutter)
            .padding(.vertical, 8)
        }
        .scrollIndicators(.hidden)
    }

    private var sideControls: some View {
        VStack(spacing: 10) {
            CircleIconButton(systemName: "location.fill", tint: .ccBlue) {
                location.requestPermission()
                if let c = location.coordinate {
                    withAnimation(.smooth) { camera = .region(.around(c, km: 4)) }
                } else {
                    withAnimation(.smooth) { camera = .userLocation(fallback: .region(.india)) }
                }
            }
            CircleIconButton(systemName: "globe.asia.australia.fill") {
                withAnimation(.smooth) { camera = .region(.india) }
            }
            CircleIconButton(systemName: "list.bullet") { showList = true }
        }
        .padding(.trailing, 12)
        .padding(.bottom, 120)
    }

    @ViewBuilder
    private var bottomPanel: some View {
        VStack(spacing: 10) {
            if let selection {
                switch selection {
                case .spot(let spot):
                    NavigationLink(value: Route.spot(spot.id)) {
                        SpotPreviewCard(spot: spot, origin: location.location)
                    }
                    .buttonStyle(.pressable)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                case .drive(let drive):
                    NavigationLink(value: Route.drive(drive.id)) {
                        DriveCard(drive: drive, origin: location.location, width: nil)
                    }
                    .buttonStyle(.pressable)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            HStack(spacing: 10) {
                Button {
                    if session.gate("Sign in to report a dirty spot and earn Swachh Points.") { router.showReport = true }
                } label: {
                    Label("Report a spot", systemImage: "camera.fill")
                }
                .buttonStyle(.primary)
                Button {
                    if session.gate("Sign in to organise a cleanup drive.") { router.startDrive(at: nil) }
                } label: {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 54, height: 54)
                        .background(Color.ccSaffron, in: Circle())
                }
                .accessibilityLabel(Text("Organise a drive"))
            }
        }
        .padding(.horizontal, Metrics.gutter)
        .padding(.bottom, 8)
        .readableWidth(560)
        .animation(.snappy, value: selection)
    }

    private var listSheet: some View {
        NavigationStack {
            List {
                if !visibleDrives.isEmpty {
                    Section("Drives") {
                        ForEach(visibleDrives) { drive in
                            Button {
                                showList = false
                                withAnimation { camera = .region(.around(drive.coordinate, km: 2)); selection = .drive(drive) }
                            } label: {
                                HStack(spacing: 12) {
                                    DateBlock(date: drive.startsAt, compact: true)
                                    VStack(alignment: .leading) {
                                        Text(drive.title).font(.cc(.subheadline, weight: .bold)).foregroundStyle(Color.ccInk)
                                        Text(drive.placeLabel).font(.cc(.caption)).foregroundStyle(Color.ccInk2)
                                    }
                                }
                            }
                        }
                    }
                }
                Section("Spots in this area") {
                    if visibleSpots.isEmpty {
                        Text("No spots here yet. Zoom out or report one.").foregroundStyle(Color.ccInk2)
                    }
                    ForEach(visibleSpots.sorted { a, b in
                        guard let o = location.location else { return a.createdAt > b.createdAt }
                        return a.location.distance(from: o) < b.location.distance(from: o)
                    }) { spot in
                        Button {
                            showList = false
                            withAnimation { camera = .region(.around(spot.coordinate, km: 1.5)); selection = .spot(spot) }
                        } label: {
                            SpotRow(spot: spot, origin: location.location)
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                        .listRowSeparator(.hidden)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Around here")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { showList = false } }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct SpotPin: View {
    let spot: Spot
    var selected = false

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(spot.status.color)
                    .frame(width: selected ? 46 : 34, height: selected ? 46 : 34)
                    .overlay(Circle().strokeBorder(.white, lineWidth: 3))
                    .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
                Image(systemName: spot.status == .cleaned ? "sparkles" : spot.category.icon)
                    .font(.system(size: selected ? 19 : 14, weight: .bold))
                    .foregroundStyle(.white)
            }
            Triangle()
                .fill(.white)
                .frame(width: 12, height: 7)
                .offset(y: -1)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selected)
    }
}

struct DrivePin: View {
    var selected = false

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(LinearGradient.ccSaffron)
                    .frame(width: selected ? 48 : 38, height: selected ? 48 : 38)
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(.white, lineWidth: 3))
                    .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
                Image(systemName: "person.3.fill")
                    .font(.system(size: selected ? 16 : 13, weight: .bold))
                    .foregroundStyle(.white)
            }
            Triangle().fill(.white).frame(width: 12, height: 7).offset(y: -1)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selected)
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}

struct SpotPreviewCard: View {
    let spot: Spot
    var origin: CLLocation?

    var body: some View {
        HStack(spacing: 12) {
            RemoteImage(spot.coverPhoto)
                .frame(width: 86, height: 86)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            VStack(alignment: .leading, spacing: 5) {
                StatusBadge(status: spot.status, compact: true)
                Text(spot.category.title).font(.cc(.headline, weight: .bold)).foregroundStyle(Color.ccInk).lineLimit(1)
                Text(spot.placeLabel).font(.cc(.caption)).foregroundStyle(Color.ccInk2).lineLimit(1)
                HStack(spacing: 8) {
                    if let d = Fmt.distance(from: origin, to: spot.location) {
                        Label(d, systemImage: "location.fill")
                    }
                    Text(Fmt.relative(spot.createdAt))
                }
                .font(.cc(.caption2, weight: .semibold)).foregroundStyle(Color.ccInk2)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.headline).foregroundStyle(Color.ccInk2)
        }
        .padding(12)
        .background(Color.ccSurface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 14, y: 6)
    }
}
