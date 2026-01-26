// PollutionMapView.swift
// Pollution Hotspot Map with reporting - iOS 17+ MapKit

import SwiftUI
import MapKit
import Observation
import CoreLocation

// MARK: - Pollution Hotspot Model

struct PollutionHotspot: Identifiable, Codable, Equatable {
    let id: String
    let reporterId: String
    let reporterName: String
    var title: String
    var description: String
    var latitude: Double
    var longitude: Double
    var address: String?
    var category: PollutionCategory
    var severity: SeverityLevel
    var imageURLs: [String]
    var reportCount: Int      // Number of people who reported this
    var resolvedCount: Int    // Number of cleanups at this location
    var status: HotspotStatus
    var createdAt: Date
    var lastReportedAt: Date
    var cleanedAt: Date?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    enum PollutionCategory: String, Codable, CaseIterable {
        case plastic = "Plastic Waste"
        case organic = "Organic Waste"
        case construction = "Construction Debris"
        case ewaste = "E-Waste"
        case sewage = "Sewage/Drainage"
        case industrial = "Industrial Waste"
        case mixed = "Mixed Waste"

        var icon: String {
            switch self {
            case .plastic: return "bag.fill"
            case .organic: return "leaf.fill"
            case .construction: return "hammer.fill"
            case .ewaste: return "desktopcomputer"
            case .sewage: return "drop.fill"
            case .industrial: return "building.2.fill"
            case .mixed: return "trash.fill"
            }
        }

        var color: Color {
            switch self {
            case .plastic: return .blue
            case .organic: return .green
            case .construction: return .orange
            case .ewaste: return .purple
            case .sewage: return .brown
            case .industrial: return .gray
            case .mixed: return .red
            }
        }
    }

    enum SeverityLevel: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"

        var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .yellow
            case .high: return .orange
            case .critical: return .red
            }
        }

        var scale: Double {
            switch self {
            case .low: return 0.6
            case .medium: return 0.8
            case .high: return 1.0
            case .critical: return 1.2
            }
        }
    }

    enum HotspotStatus: String, Codable {
        case active = "Active"
        case inProgress = "Cleanup Scheduled"
        case cleaned = "Cleaned"
        case verified = "Verified Clean"
    }

    static let preview = PollutionHotspot(
        id: "hotspot-1",
        reporterId: "user-1",
        reporterName: "Rahul S.",
        title: "Plastic dump near park",
        description: "Large pile of plastic waste accumulated near the children's park entrance",
        latitude: 19.0760,
        longitude: 72.8777,
        address: "Juhu Beach Road, Mumbai",
        category: .plastic,
        severity: .high,
        imageURLs: [],
        reportCount: 12,
        resolvedCount: 0,
        status: .active,
        createdAt: Date().addingTimeInterval(-86400 * 3),
        lastReportedAt: Date().addingTimeInterval(-3600),
        cleanedAt: nil
    )
}

// MARK: - Map View Model

@MainActor
@Observable
class PollutionMapViewModel {
    var hotspots: [PollutionHotspot] = []
    var selectedHotspot: PollutionHotspot?
    var cameraPosition: MapCameraPosition = .automatic
    var isLoading = false
    var showReportSheet = false
    var filterCategory: PollutionHotspot.PollutionCategory?
    var filterSeverity: PollutionHotspot.SeverityLevel?
    var showCleanedSpots = false
    var userLocation: CLLocationCoordinate2D?

    var filteredHotspots: [PollutionHotspot] {
        hotspots.filter { hotspot in
            // Filter by status
            if !showCleanedSpots && (hotspot.status == .cleaned || hotspot.status == .verified) {
                return false
            }
            // Filter by category
            if let category = filterCategory, hotspot.category != category {
                return false
            }
            // Filter by severity
            if let severity = filterSeverity, hotspot.severity != severity {
                return false
            }
            return true
        }
    }

    func loadHotspots() async {
        isLoading = true

        // Simulate API call
        try? await Task.sleep(nanoseconds: 600_000_000)

        // Mock data - Mumbai area hotspots
        hotspots = [
            PollutionHotspot(
                id: "h1", reporterId: "u1", reporterName: "Rahul S.",
                title: "Beach plastic accumulation",
                description: "Large amounts of plastic washed up after high tide",
                latitude: 19.0883, longitude: 72.8264,
                address: "Juhu Beach, Mumbai",
                category: .plastic, severity: .critical,
                imageURLs: [], reportCount: 45, resolvedCount: 2,
                status: .active,
                createdAt: Date().addingTimeInterval(-86400 * 7),
                lastReportedAt: Date().addingTimeInterval(-1800),
                cleanedAt: nil
            ),
            PollutionHotspot(
                id: "h2", reporterId: "u2", reporterName: "Priya P.",
                title: "Construction debris dump",
                description: "Illegal dumping of construction waste on roadside",
                latitude: 19.0596, longitude: 72.8295,
                address: "Link Road, Bandra",
                category: .construction, severity: .high,
                imageURLs: [], reportCount: 23, resolvedCount: 0,
                status: .active,
                createdAt: Date().addingTimeInterval(-86400 * 5),
                lastReportedAt: Date().addingTimeInterval(-7200),
                cleanedAt: nil
            ),
            PollutionHotspot(
                id: "h3", reporterId: "u3", reporterName: "Amit V.",
                title: "Clogged drainage",
                description: "Drain blocked with mixed waste causing waterlogging",
                latitude: 19.0178, longitude: 72.8478,
                address: "Dadar West, Mumbai",
                category: .sewage, severity: .high,
                imageURLs: [], reportCount: 67, resolvedCount: 1,
                status: .inProgress,
                createdAt: Date().addingTimeInterval(-86400 * 10),
                lastReportedAt: Date().addingTimeInterval(-3600),
                cleanedAt: nil
            ),
            PollutionHotspot(
                id: "h4", reporterId: "u4", reporterName: "Sneha R.",
                title: "E-waste dumping spot",
                description: "Old electronics and computer parts dumped",
                latitude: 19.1136, longitude: 72.8697,
                address: "Andheri East, Mumbai",
                category: .ewaste, severity: .medium,
                imageURLs: [], reportCount: 8, resolvedCount: 0,
                status: .active,
                createdAt: Date().addingTimeInterval(-86400 * 2),
                lastReportedAt: Date().addingTimeInterval(-14400),
                cleanedAt: nil
            ),
            PollutionHotspot(
                id: "h5", reporterId: "u5", reporterName: "Vikram S.",
                title: "Organic waste pile",
                description: "Vegetable market waste rotting in open",
                latitude: 18.9388, longitude: 72.8354,
                address: "Crawford Market, Mumbai",
                category: .organic, severity: .medium,
                imageURLs: [], reportCount: 34, resolvedCount: 3,
                status: .active,
                createdAt: Date().addingTimeInterval(-86400 * 4),
                lastReportedAt: Date().addingTimeInterval(-5400),
                cleanedAt: nil
            ),
            PollutionHotspot(
                id: "h6", reporterId: "u6", reporterName: "Meera J.",
                title: "Industrial effluent",
                description: "Factory discharge into nullah",
                latitude: 19.1854, longitude: 72.9542,
                address: "Thane Creek, Mumbai",
                category: .industrial, severity: .critical,
                imageURLs: [], reportCount: 89, resolvedCount: 0,
                status: .active,
                createdAt: Date().addingTimeInterval(-86400 * 30),
                lastReportedAt: Date().addingTimeInterval(-600),
                cleanedAt: nil
            ),
            // Cleaned spots
            PollutionHotspot(
                id: "h7", reporterId: "u7", reporterName: "Karthik N.",
                title: "Park cleanup completed",
                description: "Community cleanup drive successful",
                latitude: 19.0453, longitude: 72.8201,
                address: "Shivaji Park, Mumbai",
                category: .mixed, severity: .low,
                imageURLs: [], reportCount: 15, resolvedCount: 15,
                status: .verified,
                createdAt: Date().addingTimeInterval(-86400 * 14),
                lastReportedAt: Date().addingTimeInterval(-86400 * 7),
                cleanedAt: Date().addingTimeInterval(-86400 * 5)
            ),
        ]

        // Center on Mumbai
        cameraPosition = .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 19.0760, longitude: 72.8777),
            span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
        ))

        isLoading = false
    }

    func reportHotspot(_ hotspot: PollutionHotspot) async {
        hotspots.append(hotspot)
    }

    func markAsCleaned(_ hotspotId: String) async {
        if let index = hotspots.firstIndex(where: { $0.id == hotspotId }) {
            hotspots[index].status = .cleaned
            hotspots[index].cleanedAt = Date()
        }
    }
}

// MARK: - Main Map View

struct PollutionMapView: View {
    @State private var viewModel = PollutionMapViewModel()
    @State private var showFilters = false
    @State private var showLegend = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Map
                mapContent

                // Overlays
                VStack {
                    Spacer()

                    // Bottom sheet preview for selected hotspot
                    if let selected = viewModel.selectedHotspot {
                        HotspotPreviewCard(
                            hotspot: selected,
                            onClose: { viewModel.selectedHotspot = nil },
                            onNavigate: { openInMaps(selected) },
                            onReport: { /* Join report */ }
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.3), value: viewModel.selectedHotspot)

                // Loading overlay
                if viewModel.isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay(ProgressView().tint(.white))
                }
            }
            .navigationTitle("Pollution Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showLegend.toggle()
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            showFilters.toggle()
                        } label: {
                            Image(systemName: viewModel.filterCategory != nil || viewModel.filterSeverity != nil
                                  ? "line.3.horizontal.decrease.circle.fill"
                                  : "line.3.horizontal.decrease.circle")
                        }

                        Button {
                            viewModel.showReportSheet = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .sheet(isPresented: $viewModel.showReportSheet) {
                ReportHotspotSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showFilters) {
                FilterSheet(viewModel: viewModel)
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showLegend) {
                LegendSheet()
                    .presentationDetents([.medium])
            }
            .task {
                await viewModel.loadHotspots()
            }
        }
    }

    // MARK: - Map Content

    private var mapContent: some View {
        Map(position: $viewModel.cameraPosition, selection: Binding(
            get: { viewModel.selectedHotspot?.id },
            set: { newId in
                viewModel.selectedHotspot = viewModel.hotspots.first { $0.id == newId }
            }
        )) {
            // User location
            UserAnnotation()

            // Hotspot markers
            ForEach(viewModel.filteredHotspots) { hotspot in
                Annotation(hotspot.title, coordinate: hotspot.coordinate, anchor: .bottom) {
                    HotspotMarker(hotspot: hotspot)
                }
                .tag(hotspot.id)
            }
        }
        .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
    }

    private func openInMaps(_ hotspot: PollutionHotspot) {
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: hotspot.coordinate))
        mapItem.name = hotspot.title
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
    }
}

// MARK: - Hotspot Marker

struct HotspotMarker: View {
    let hotspot: PollutionHotspot

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Pulsing effect for critical
                if hotspot.severity == .critical {
                    Circle()
                        .fill(hotspot.severity.color.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .scaleEffect(1.0)
                        .opacity(0.8)
                }

                // Main marker
                Circle()
                    .fill(hotspot.category.color)
                    .frame(width: 36 * hotspot.severity.scale, height: 36 * hotspot.severity.scale)
                    .overlay(
                        Image(systemName: hotspot.category.icon)
                            .font(.system(size: 14 * hotspot.severity.scale))
                            .foregroundColor(.white)
                    )
                    .shadow(color: hotspot.category.color.opacity(0.5), radius: 4, y: 2)

                // Report count badge
                if hotspot.reportCount > 5 {
                    Text("\(hotspot.reportCount)")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .cornerRadius(8)
                        .offset(x: 18, y: -18)
                }

                // Cleaned checkmark
                if hotspot.status == .cleaned || hotspot.status == .verified {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                        .background(Circle().fill(.white))
                        .offset(x: 14, y: 14)
                }
            }

            // Arrow pointer
            MapTriangle()
                .fill(hotspot.category.color)
                .frame(width: 12, height: 8)
                .offset(y: -2)
        }
    }
}

// MARK: - Map Triangle Shape

struct MapTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Hotspot Preview Card

struct HotspotPreviewCard: View {
    let hotspot: PollutionHotspot
    let onClose: () -> Void
    let onNavigate: () -> Void
    let onReport: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.top, 8)

            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    // Category icon
                    Circle()
                        .fill(hotspot.category.color)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: hotspot.category.icon)
                                .foregroundColor(.white)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(hotspot.title)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)

                        HStack(spacing: 8) {
                            // Severity
                            Text(hotspot.severity.rawValue)
                                .font(.caption2.weight(.medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(hotspot.severity.color)
                                .cornerRadius(4)

                            // Status
                            Text(hotspot.status.rawValue)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }

                // Description
                Text(hotspot.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                // Stats
                HStack(spacing: 16) {
                    Label("\(hotspot.reportCount) reports", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)

                    if let address = hotspot.address {
                        Label(address, systemImage: "mappin")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                // Actions
                HStack(spacing: 12) {
                    Button(action: onNavigate) {
                        Label("Navigate", systemImage: "arrow.triangle.turn.up.right.circle.fill")
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }

                    Button(action: onReport) {
                        Label("I saw this too", systemImage: "hand.raised.fill")
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.orange.opacity(0.15))
                            .foregroundColor(.orange)
                            .cornerRadius(10)
                    }
                }
            }
            .padding()
        }
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.15), radius: 10, y: -5)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

// MARK: - Report Hotspot Sheet

struct ReportHotspotSheet: View {
    @Bindable var viewModel: PollutionMapViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var category: PollutionHotspot.PollutionCategory = .mixed
    @State private var severity: PollutionHotspot.SeverityLevel = .medium
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Location") {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.blue)
                        Text("Using current location")
                            .font(.subheadline)
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }

                Section("Details") {
                    TextField("Title (e.g., Plastic dump near park)", text: $title)

                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...5)

                    Picker("Category", selection: $category) {
                        ForEach(PollutionHotspot.PollutionCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }

                    Picker("Severity", selection: $severity) {
                        ForEach(PollutionHotspot.SeverityLevel.allCases, id: \.self) { level in
                            HStack {
                                Circle()
                                    .fill(level.color)
                                    .frame(width: 12, height: 12)
                                Text(level.rawValue)
                            }
                            .tag(level)
                        }
                    }
                }

                Section {
                    Button {
                        // Add photo
                    } label: {
                        Label("Add Photos", systemImage: "camera.fill")
                    }
                } header: {
                    Text("Evidence")
                } footer: {
                    Text("Photos help verify the report and attract volunteers")
                }
            }
            .navigationTitle("Report Pollution")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        submitReport()
                    }
                    .disabled(title.isEmpty || isSubmitting)
                }
            }
        }
    }

    private func submitReport() {
        isSubmitting = true

        Task {
            let newHotspot = PollutionHotspot(
                id: UUID().uuidString,
                reporterId: UserState.shared.currentUser?.id ?? "",
                reporterName: UserState.shared.currentUser?.displayName ?? "Anonymous",
                title: title,
                description: description,
                latitude: viewModel.userLocation?.latitude ?? 19.0760,
                longitude: viewModel.userLocation?.longitude ?? 72.8777,
                address: nil,
                category: category,
                severity: severity,
                imageURLs: [],
                reportCount: 1,
                resolvedCount: 0,
                status: .active,
                createdAt: Date(),
                lastReportedAt: Date(),
                cleanedAt: nil
            )

            await viewModel.reportHotspot(newHotspot)
            dismiss()
        }
    }
}

// MARK: - Filter Sheet

struct FilterSheet: View {
    @Bindable var viewModel: PollutionMapViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    Button {
                        viewModel.filterCategory = nil
                    } label: {
                        HStack {
                            Text("All Categories")
                            Spacer()
                            if viewModel.filterCategory == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .foregroundColor(.primary)

                    ForEach(PollutionHotspot.PollutionCategory.allCases, id: \.self) { category in
                        Button {
                            viewModel.filterCategory = category
                        } label: {
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(category.color)
                                    .frame(width: 24)
                                Text(category.rawValue)
                                Spacer()
                                if viewModel.filterCategory == category {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }

                Section("Severity") {
                    Button {
                        viewModel.filterSeverity = nil
                    } label: {
                        HStack {
                            Text("All Levels")
                            Spacer()
                            if viewModel.filterSeverity == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .foregroundColor(.primary)

                    ForEach(PollutionHotspot.SeverityLevel.allCases, id: \.self) { level in
                        Button {
                            viewModel.filterSeverity = level
                        } label: {
                            HStack {
                                Circle()
                                    .fill(level.color)
                                    .frame(width: 12, height: 12)
                                Text(level.rawValue)
                                Spacer()
                                if viewModel.filterSeverity == level {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }

                Section {
                    Toggle("Show cleaned spots", isOn: $viewModel.showCleanedSpots)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Legend Sheet

struct LegendSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Categories
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Pollution Types")
                            .font(.headline)

                        ForEach(PollutionHotspot.PollutionCategory.allCases, id: \.self) { category in
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(category.color)
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Image(systemName: category.icon)
                                            .font(.caption)
                                            .foregroundColor(.white)
                                    )
                                Text(category.rawValue)
                                    .font(.subheadline)
                            }
                        }
                    }

                    Divider()

                    // Severity
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Severity Levels")
                            .font(.headline)

                        ForEach(PollutionHotspot.SeverityLevel.allCases, id: \.self) { level in
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(level.color)
                                    .frame(width: 20, height: 20)
                                Text(level.rawValue)
                                    .font(.subheadline)
                                Text("- Marker size: \(Int(level.scale * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Divider()

                    // How it works
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How it works")
                            .font(.headline)

                        Text("1. Tap + to report a pollution hotspot at your location")
                        Text("2. Add photos and details to help verify the report")
                        Text("3. Others can confirm reports they've seen")
                        Text("4. High-report areas attract cleanup events")
                        Text("5. Mark spots as cleaned after cleanup drives")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("Map Legend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    PollutionMapView()
}
