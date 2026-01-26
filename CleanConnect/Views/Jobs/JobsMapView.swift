// JobsMapView.swift
// Map-based cleanup jobs view - iOS 17+ with modern MapKit

import SwiftUI
import MapKit
import Observation

// MARK: - Jobs Map View Model

@MainActor
@Observable
class JobsMapViewModel {
    var jobs: [CleanupJob] = []
    var selectedJob: CleanupJob?
    var isLoading = false
    var showCreateJob = false
    var createJobLocation: CLLocationCoordinate2D?
    var filter = JobFilter()
    var userLocation: CLLocationCoordinate2D?

    // Camera position for the map
    var cameraPosition: MapCameraPosition = .automatic

    func loadJobs() async {
        isLoading = true

        // Simulate API call
        try? await Task.sleep(nanoseconds: 600_000_000)

        // Mock jobs data
        jobs = [
            CleanupJob(
                id: "job-1",
                creatorId: "user-1",
                creatorName: "Priya Sharma",
                creatorPhotoURL: nil,
                title: "Plastic waste near park entrance",
                description: "Lots of plastic bottles and wrappers accumulated near the main entrance of Shivaji Park. Needs cleanup.",
                category: .litter,
                difficulty: .easy,
                estimatedTime: 20,
                latitude: 19.0281,
                longitude: 72.8387,
                address: "Shivaji Park Main Entrance",
                district: "Mumbai",
                state: "Maharashtra",
                pointsReward: 40,
                tipReward: 50,
                status: .open,
                claimedBy: nil,
                claimedByName: nil,
                claimedAt: nil,
                completedAt: nil,
                verifiedAt: nil,
                proofPostId: nil,
                proofPhotoURL: nil,
                proofVideoURL: nil,
                createdAt: Date().addingTimeInterval(-3600 * 2),
                expiresAt: Date().addingTimeInterval(86400 * 5),
                viewCount: 45,
                claimCount: 0
            ),
            CleanupJob(
                id: "job-2",
                creatorId: "user-2",
                creatorName: "Amit Patel",
                creatorPhotoURL: nil,
                title: "Graffiti on compound wall",
                description: "Someone sprayed graffiti on the school compound wall. Need help removing it.",
                category: .graffiti,
                difficulty: .medium,
                estimatedTime: 45,
                latitude: 19.0760,
                longitude: 72.8777,
                address: "Near DAV School, Andheri",
                district: "Mumbai",
                state: "Maharashtra",
                pointsReward: 75,
                tipReward: 150,
                status: .open,
                claimedBy: nil,
                claimedByName: nil,
                claimedAt: nil,
                completedAt: nil,
                verifiedAt: nil,
                proofPostId: nil,
                proofPhotoURL: nil,
                proofVideoURL: nil,
                createdAt: Date().addingTimeInterval(-3600 * 5),
                expiresAt: Date().addingTimeInterval(86400 * 3),
                viewCount: 32,
                claimCount: 1
            ),
            CleanupJob(
                id: "job-3",
                creatorId: "user-3",
                creatorName: "Sneha Reddy",
                creatorPhotoURL: nil,
                title: "Beach cleanup - Juhu",
                description: "Section of Juhu beach near food stalls has accumulated a lot of trash. Looking for volunteers.",
                category: .beach,
                difficulty: .hard,
                estimatedTime: 90,
                latitude: 19.0883,
                longitude: 72.8264,
                address: "Juhu Beach, Near Food Court",
                district: "Mumbai",
                state: "Maharashtra",
                pointsReward: 150,
                tipReward: 300,
                status: .open,
                claimedBy: nil,
                claimedByName: nil,
                claimedAt: nil,
                completedAt: nil,
                verifiedAt: nil,
                proofPostId: nil,
                proofPhotoURL: nil,
                proofVideoURL: nil,
                createdAt: Date().addingTimeInterval(-3600 * 8),
                expiresAt: Date().addingTimeInterval(86400 * 7),
                viewCount: 128,
                claimCount: 2
            ),
            CleanupJob(
                id: "job-4",
                creatorId: "user-4",
                creatorName: "Vikram Singh",
                creatorPhotoURL: nil,
                title: "Drain blocked with waste",
                description: "The roadside drain is blocked with plastic waste causing water logging. Please help clear it.",
                category: .drain,
                difficulty: .medium,
                estimatedTime: 40,
                latitude: 19.1176,
                longitude: 72.9060,
                address: "Near Powai Lake, Hiranandani",
                district: "Mumbai",
                state: "Maharashtra",
                pointsReward: 60,
                tipReward: nil,
                status: .claimed,
                claimedBy: "user-5",
                claimedByName: "Rahul K.",
                claimedAt: Date().addingTimeInterval(-3600),
                completedAt: nil,
                verifiedAt: nil,
                proofPostId: nil,
                proofPhotoURL: nil,
                proofVideoURL: nil,
                createdAt: Date().addingTimeInterval(-3600 * 12),
                expiresAt: Date().addingTimeInterval(86400 * 2),
                viewCount: 67,
                claimCount: 1
            ),
            CleanupJob(
                id: "job-5",
                creatorId: "user-5",
                creatorName: "Meera Joshi",
                creatorPhotoURL: nil,
                title: "Plant care needed",
                description: "Community garden plants need watering and weeding. Regular help appreciated!",
                category: .greenery,
                difficulty: .easy,
                estimatedTime: 30,
                latitude: 19.0596,
                longitude: 72.8295,
                address: "Bandra Community Garden",
                district: "Mumbai",
                state: "Maharashtra",
                pointsReward: 35,
                tipReward: 25,
                status: .open,
                claimedBy: nil,
                claimedByName: nil,
                claimedAt: nil,
                completedAt: nil,
                verifiedAt: nil,
                proofPostId: nil,
                proofPhotoURL: nil,
                proofVideoURL: nil,
                createdAt: Date().addingTimeInterval(-3600 * 24),
                expiresAt: nil,
                viewCount: 89,
                claimCount: 3
            )
        ]

        isLoading = false
    }

    func claimJob(_ job: CleanupJob) {
        if let index = jobs.firstIndex(where: { $0.id == job.id }) {
            jobs[index].status = .claimed
            jobs[index].claimedBy = "current-user"
            jobs[index].claimedByName = "You"
            jobs[index].claimedAt = Date()
        }
    }

    var filteredJobs: [CleanupJob] {
        jobs.filter { job in
            if !filter.categories.isEmpty && !filter.categories.contains(job.category) {
                return false
            }
            if !filter.difficulties.isEmpty && !filter.difficulties.contains(job.difficulty) {
                return false
            }
            if let minPoints = filter.minPoints, job.pointsReward < minPoints {
                return false
            }
            if filter.onlyWithTips && job.tipReward == nil {
                return false
            }
            if !filter.showCompleted && (job.status == .completed || job.status == .verified) {
                return false
            }
            return true
        }
    }
}

// MARK: - Jobs Map View

struct JobsMapView: View {
    @State private var viewModel = JobsMapViewModel()
    @State private var showFilter = false
    @State private var showJobDetail = false
    @State private var showJobsList = false
    @Namespace private var animation

    var body: some View {
        NavigationStack {
            ZStack {
                // Map
                mapContent

                // Overlays
                VStack {
                    // Top bar with filters
                    topBar

                    Spacer()

                    // Bottom controls
                    bottomControls
                }

                // Job preview card
                if let job = viewModel.selectedJob {
                    VStack {
                        Spacer()
                        JobPreviewCard(
                            job: job,
                            onClose: { viewModel.selectedJob = nil },
                            onViewDetails: { showJobDetail = true },
                            onClaim: { viewModel.claimJob(job) }
                        )
                        .padding()
                        .padding(.bottom, 80)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .animation(.spring(response: 0.3), value: viewModel.selectedJob?.id)
                }
            }
            .navigationTitle("Cleanup Jobs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showJobsList = true
                    } label: {
                        Image(systemName: "list.bullet")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showCreateJob = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .task {
                await viewModel.loadJobs()
            }
            .sheet(isPresented: $viewModel.showCreateJob) {
                CreateJobSheet(
                    initialLocation: viewModel.createJobLocation,
                    onJobCreated: { job in
                        viewModel.jobs.append(job)
                    }
                )
            }
            .sheet(isPresented: $showFilter) {
                JobFilterSheet(filter: $viewModel.filter)
            }
            .sheet(isPresented: $showJobDetail) {
                if let job = viewModel.selectedJob {
                    JobDetailSheet(job: job, onClaim: {
                        viewModel.claimJob(job)
                    })
                }
            }
            .sheet(isPresented: $showJobsList) {
                JobsListSheet(jobs: viewModel.filteredJobs) { job in
                    viewModel.selectedJob = job
                    showJobsList = false
                    // Center map on selected job
                    viewModel.cameraPosition = .region(MKCoordinateRegion(
                        center: job.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    ))
                }
            }
        }
    }

    private var mapContent: some View {
        Map(position: $viewModel.cameraPosition, selection: Binding(
            get: { viewModel.selectedJob?.id },
            set: { id in
                viewModel.selectedJob = viewModel.jobs.first { $0.id == id }
            }
        )) {
            // Job markers
            ForEach(viewModel.filteredJobs) { job in
                Annotation(job.title, coordinate: job.coordinate, anchor: .bottom) {
                    JobMapMarker(job: job, isSelected: viewModel.selectedJob?.id == job.id)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                viewModel.selectedJob = job
                            }
                        }
                }
                .tag(job.id)
            }

            // User location
            UserAnnotation()
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .onMapCameraChange { context in
            // Could track camera changes here if needed
        }
        .gesture(
            LongPressGesture(minimumDuration: 0.5)
                .sequenced(before: DragGesture(minimumDistance: 0))
                .onEnded { value in
                    // Long press to create job at location
                    // Note: Getting exact coordinates from gesture requires more complex handling
                }
        )
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    JobCategoryChip(
                        title: "All",
                        isSelected: viewModel.filter.categories.isEmpty,
                        action: { viewModel.filter.categories.removeAll() }
                    )

                    ForEach(CleanupJob.JobCategory.allCases, id: \.self) { category in
                        JobCategoryChip(
                            title: category.rawValue,
                            icon: category.icon,
                            isSelected: viewModel.filter.categories.contains(category),
                            action: {
                                if viewModel.filter.categories.contains(category) {
                                    viewModel.filter.categories.remove(category)
                                } else {
                                    viewModel.filter.categories.insert(category)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }

    private var bottomControls: some View {
        HStack {
            // Jobs count
            HStack(spacing: 6) {
                Image(systemName: "briefcase.fill")
                    .foregroundColor(.green)
                Text("\(viewModel.filteredJobs.count) jobs")
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .cornerRadius(20)

            Spacer()

            // Filter button
            Button {
                showFilter = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                    Text("Filters")
                }
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
            }
        }
        .padding()
    }
}

// MARK: - Job Map Marker

struct JobMapMarker: View {
    let job: CleanupJob
    let isSelected: Bool

    private var categoryColor: Color {
        switch job.category.color {
        case "orange": return .orange
        case "purple": return .purple
        case "green": return .green
        case "blue": return .blue
        case "cyan": return .cyan
        case "gray": return .gray
        case "mint": return .mint
        case "brown": return .brown
        default: return .green
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Outer circle
                Circle()
                    .fill(categoryColor)
                    .frame(width: isSelected ? 50 : 40, height: isSelected ? 50 : 40)
                    .shadow(color: categoryColor.opacity(0.5), radius: isSelected ? 8 : 4)

                // Icon
                Image(systemName: job.category.icon)
                    .font(isSelected ? .title3 : .body)
                    .foregroundColor(.white)

                // Status indicator
                if job.status == .claimed {
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Image(systemName: "clock.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.white)
                        )
                        .offset(x: 14, y: -14)
                }

                // Tip indicator
                if job.tipReward != nil {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Text("₹")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .offset(x: -14, y: -14)
                }
            }

            // Points badge
            if isSelected {
                Text("+\(job.pointsReward) pts")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(categoryColor)
                    .cornerRadius(4)
                    .offset(y: 4)
            }
        }
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Job Preview Card

struct JobPreviewCard: View {
    let job: CleanupJob
    let onClose: () -> Void
    let onViewDetails: () -> Void
    let onClaim: () -> Void

    private var categoryColor: Color {
        switch job.category.color {
        case "orange": return .orange
        case "purple": return .purple
        case "green": return .green
        case "blue": return .blue
        case "cyan": return .cyan
        case "gray": return .gray
        case "mint": return .mint
        case "brown": return .brown
        default: return .green
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 8)

            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    // Category badge
                    HStack(spacing: 4) {
                        Image(systemName: job.category.icon)
                        Text(job.category.rawValue)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(categoryColor)
                    .cornerRadius(6)

                    // Difficulty
                    Text(job.difficulty.rawValue)
                        .font(.caption.weight(.medium))
                        .foregroundColor(difficultyColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(difficultyColor.opacity(0.15))
                        .cornerRadius(6)

                    Spacer()

                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }

                // Title
                Text(job.title)
                    .font(.headline)
                    .lineLimit(2)

                // Location
                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.caption)
                    Text(job.address ?? "\(job.district), \(job.state)")
                        .font(.caption)
                }
                .foregroundColor(.secondary)

                // Stats row
                HStack(spacing: 16) {
                    // Points
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("+\(job.pointsReward)")
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)

                    // Tip
                    if let tip = job.tipReward {
                        HStack(spacing: 4) {
                            Image(systemName: "indianrupeesign.circle.fill")
                                .foregroundColor(.green)
                            Text("₹\(tip)")
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                    }

                    // Time
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                        Text("~\(job.estimatedTime) min")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)

                    Spacer()
                }

                // Actions
                HStack(spacing: 12) {
                    Button(action: onViewDetails) {
                        Text("Details")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.gray.opacity(0.15))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)

                    if job.isAvailable {
                        Button(action: onClaim) {
                            HStack {
                                Image(systemName: "hand.raised.fill")
                                Text("Claim Job")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .fontWeight(.semibold)
                        }
                        .buttonStyle(.plain)
                    } else if job.status == .claimed {
                        Text("Claimed by \(job.claimedByName ?? "someone")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.yellow.opacity(0.15))
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: -5)
    }

    private var difficultyColor: Color {
        switch job.difficulty {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
}

// MARK: - Job Category Chip

struct JobCategoryChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color.green : Color.gray.opacity(0.15))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Create Job Sheet

struct CreateJobSheet: View {
    let initialLocation: CLLocationCoordinate2D?
    let onJobCreated: (CleanupJob) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var category: CleanupJob.JobCategory = .litter
    @State private var difficulty: CleanupJob.JobDifficulty = .easy
    @State private var estimatedTime = 30
    @State private var pointsReward = 50
    @State private var tipReward: Int?
    @State private var addTip = false
    @State private var address = ""
    @State private var selectedLocation: CLLocationCoordinate2D?
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 19.076, longitude: 72.8777),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    var body: some View {
        NavigationStack {
            Form {
                Section("Job Details") {
                    TextField("Title", text: $title)

                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)

                    Picker("Category", selection: $category) {
                        ForEach(CleanupJob.JobCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }

                    Picker("Difficulty", selection: $difficulty) {
                        ForEach(CleanupJob.JobDifficulty.allCases, id: \.self) { diff in
                            Text(diff.rawValue).tag(diff)
                        }
                    }

                    Stepper("Est. Time: \(estimatedTime) min", value: $estimatedTime, in: 10...180, step: 10)
                }

                Section("Rewards") {
                    Stepper("Points: \(pointsReward)", value: $pointsReward, in: 10...500, step: 10)

                    Toggle("Add Tip Reward", isOn: $addTip)

                    if addTip {
                        HStack {
                            Text("Tip Amount")
                            Spacer()
                            TextField("Amount", value: $tipReward, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                            Text("₹")
                        }
                    }
                }

                Section("Location") {
                    TextField("Address (optional)", text: $address)

                    // Map for location selection
                    Map(coordinateRegion: $mapRegion, interactionModes: .all, annotationItems: selectedLocation.map { [MapPin(coordinate: $0)] } ?? []) { pin in
                        MapMarker(coordinate: pin.coordinate, tint: .green)
                    }
                    .frame(height: 200)
                    .cornerRadius(12)
                    .onTapGesture { location in
                        // In real app, convert tap to coordinates
                        selectedLocation = mapRegion.center
                    }

                    Text("Tap on map to set location")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button("Use Current Location") {
                        // Would use LocationManager to get current location
                        selectedLocation = mapRegion.center
                    }
                }
            }
            .navigationTitle("Create Cleanup Job")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createJob()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .onAppear {
                if let loc = initialLocation {
                    selectedLocation = loc
                    mapRegion.center = loc
                }
            }
        }
    }

    private func createJob() {
        let location = selectedLocation ?? mapRegion.center

        let job = CleanupJob(
            id: UUID().uuidString,
            creatorId: "current-user",
            creatorName: "You",
            creatorPhotoURL: nil,
            title: title,
            description: description,
            category: category,
            difficulty: difficulty,
            estimatedTime: estimatedTime,
            latitude: location.latitude,
            longitude: location.longitude,
            address: address.isEmpty ? nil : address,
            district: "Mumbai",
            state: "Maharashtra",
            pointsReward: pointsReward,
            tipReward: addTip ? tipReward : nil,
            status: .open,
            claimedBy: nil,
            claimedByName: nil,
            claimedAt: nil,
            completedAt: nil,
            verifiedAt: nil,
            proofPostId: nil,
            proofPhotoURL: nil,
            proofVideoURL: nil,
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(86400 * 7),
            viewCount: 0,
            claimCount: 0
        )

        onJobCreated(job)
        dismiss()
    }
}

struct MapPin: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Job Filter Sheet

struct JobFilterSheet: View {
    @Binding var filter: JobFilter
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Categories") {
                    ForEach(CleanupJob.JobCategory.allCases, id: \.self) { category in
                        Toggle(isOn: Binding(
                            get: { filter.categories.contains(category) },
                            set: { isOn in
                                if isOn {
                                    filter.categories.insert(category)
                                } else {
                                    filter.categories.remove(category)
                                }
                            }
                        )) {
                            Label(category.rawValue, systemImage: category.icon)
                        }
                    }
                }

                Section("Difficulty") {
                    ForEach(CleanupJob.JobDifficulty.allCases, id: \.self) { difficulty in
                        Toggle(isOn: Binding(
                            get: { filter.difficulties.contains(difficulty) },
                            set: { isOn in
                                if isOn {
                                    filter.difficulties.insert(difficulty)
                                } else {
                                    filter.difficulties.remove(difficulty)
                                }
                            }
                        )) {
                            Text(difficulty.rawValue)
                        }
                    }
                }

                Section("Other Filters") {
                    Toggle("Only jobs with tips", isOn: $filter.onlyWithTips)
                    Toggle("Show completed jobs", isOn: $filter.showCompleted)
                }

                Section {
                    Button("Reset Filters") {
                        filter = JobFilter()
                    }
                    .foregroundColor(.red)
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
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Job Detail Sheet

struct JobDetailSheet: View {
    let job: CleanupJob
    let onClaim: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showProofSubmission = false

    private var categoryColor: Color {
        switch job.category.color {
        case "orange": return .orange
        case "purple": return .purple
        case "green": return .green
        case "blue": return .blue
        case "cyan": return .cyan
        case "gray": return .gray
        case "mint": return .mint
        case "brown": return .brown
        default: return .green
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header with category
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: job.category.icon)
                            Text(job.category.rawValue)
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(categoryColor)
                        .cornerRadius(8)

                        Spacer()

                        // Status
                        Text(job.status.rawValue)
                            .font(.caption.weight(.medium))
                            .foregroundColor(statusColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(statusColor.opacity(0.15))
                            .cornerRadius(6)
                    }

                    // Title
                    Text(job.title)
                        .font(.title2.weight(.bold))

                    // Creator
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Posted by \(job.creatorName)")
                                .font(.subheadline)
                            Text(job.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Divider()

                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        Text(job.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }

                    // Location
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location")
                            .font(.headline)

                        HStack(spacing: 8) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.red)
                            Text(job.address ?? "\(job.district), \(job.state)")
                        }
                        .font(.subheadline)

                        // Mini map
                        Map(coordinateRegion: .constant(MKCoordinateRegion(
                            center: job.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )), annotationItems: [MapPin(coordinate: job.coordinate)]) { pin in
                            MapMarker(coordinate: pin.coordinate, tint: categoryColor)
                        }
                        .frame(height: 150)
                        .cornerRadius(12)
                        .disabled(true)

                        Button {
                            openMaps()
                        } label: {
                            Label("Get Directions", systemImage: "arrow.triangle.turn.up.right.diamond")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                    }

                    Divider()

                    // Rewards
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Rewards")
                            .font(.headline)

                        HStack(spacing: 20) {
                            VStack(spacing: 4) {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                    Text("+\(job.pointsReward)")
                                        .font(.title3.weight(.bold))
                                }
                                Text("Points")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            if let tip = job.tipReward {
                                VStack(spacing: 4) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "indianrupeesign.circle.fill")
                                            .foregroundColor(.green)
                                        Text("₹\(tip)")
                                            .font(.title3.weight(.bold))
                                    }
                                    Text("Tip")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            VStack(spacing: 4) {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock")
                                        .foregroundColor(.secondary)
                                    Text("~\(job.estimatedTime)")
                                        .font(.title3.weight(.bold))
                                }
                                Text("Minutes")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    // Job stats
                    HStack(spacing: 20) {
                        Label("\(job.viewCount) views", systemImage: "eye")
                        Label("\(job.claimCount) claims", systemImage: "hand.raised")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)

                    Spacer(minLength: 80)
                }
                .padding()
            }
            .navigationTitle("Job Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 12) {
                    if job.isAvailable {
                        Button {
                            onClaim()
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "hand.raised.fill")
                                Text("Claim This Job")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .fontWeight(.semibold)
                        }
                    } else if job.claimedBy == "current-user" {
                        Button {
                            showProofSubmission = true
                        } label: {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text("Submit Proof")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .fontWeight(.semibold)
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
            }
            .sheet(isPresented: $showProofSubmission) {
                JobProofSubmissionSheet(job: job)
            }
        }
    }

    private var statusColor: Color {
        switch job.status {
        case .open: return .green
        case .claimed, .inProgress: return .orange
        case .proofSubmitted: return .blue
        case .verified, .completed: return .purple
        case .expired, .cancelled: return .red
        }
    }

    private func openMaps() {
        let url = URL(string: "maps://?daddr=\(job.latitude),\(job.longitude)")!
        UIApplication.shared.open(url)
    }
}

// MARK: - Jobs List Sheet

struct JobsListSheet: View {
    let jobs: [CleanupJob]
    let onSelectJob: (CleanupJob) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(jobs) { job in
                JobListRow(job: job)
                    .onTapGesture {
                        onSelectJob(job)
                    }
            }
            .listStyle(.plain)
            .navigationTitle("All Jobs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct JobListRow: View {
    let job: CleanupJob

    private var categoryColor: Color {
        switch job.category.color {
        case "orange": return .orange
        case "purple": return .purple
        case "green": return .green
        case "blue": return .blue
        case "cyan": return .cyan
        case "gray": return .gray
        case "mint": return .mint
        case "brown": return .brown
        default: return .green
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            Circle()
                .fill(categoryColor)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: job.category.icon)
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(job.title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)

                Text(job.address ?? job.district)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Label("+\(job.pointsReward)", systemImage: "star.fill")
                        .foregroundColor(.yellow)

                    if let tip = job.tipReward {
                        Label("₹\(tip)", systemImage: "indianrupeesign.circle.fill")
                            .foregroundColor(.green)
                    }

                    Label(job.difficulty.rawValue, systemImage: "gauge")
                }
                .font(.caption2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Job Proof Submission Sheet

struct JobProofSubmissionSheet: View {
    let job: CleanupJob
    @Environment(\.dismiss) private var dismiss
    @State private var description = ""
    @State private var youtubeURL = ""
    @State private var showImagePicker = false
    @State private var selectedImages: [String] = [] // Would be actual images
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(job.title)
                            .font(.headline)
                        Text("Submit proof that you've completed this job")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section("Photos") {
                    Button {
                        showImagePicker = true
                    } label: {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Add Photos")
                        }
                    }

                    if selectedImages.isEmpty {
                        Text("Add before & after photos")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section("Video (YouTube)") {
                    TextField("Paste YouTube video URL", text: $youtubeURL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)

                    if !youtubeURL.isEmpty {
                        // Preview
                        if let videoId = extractYouTubeId(from: youtubeURL) {
                            AsyncImage(url: URL(string: "https://img.youtube.com/vi/\(videoId)/hqdefault.jpg")) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                            }
                            .frame(height: 150)
                            .cornerRadius(8)
                            .clipped()
                        }
                    }

                    Text("Upload your video to YouTube and paste the link here")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("Description") {
                    TextField("Describe what you did...", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Text("Your proof will be reviewed. Once verified, you'll receive \(job.pointsReward) points\(job.tipReward != nil ? " and ₹\(job.tipReward!) tip" : "").")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Submit Proof")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") {
                        submitProof()
                    }
                    .disabled(description.isEmpty)
                }
            }
        }
    }

    private func extractYouTubeId(from url: String) -> String? {
        let patterns = [
            "(?:youtube\\.com\\/watch\\?v=)([a-zA-Z0-9_-]{11})",
            "(?:youtu\\.be\\/)([a-zA-Z0-9_-]{11})",
            "(?:youtube\\.com\\/shorts\\/)([a-zA-Z0-9_-]{11})"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: url, options: [], range: NSRange(url.startIndex..., in: url)),
               let range = Range(match.range(at: 1), in: url) {
                return String(url[range])
            }
        }
        return nil
    }

    private func submitProof() {
        isSubmitting = true
        // Submit proof logic - would create a feed post
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isSubmitting = false
            dismiss()
        }
    }
}

#Preview {
    JobsMapView()
}
