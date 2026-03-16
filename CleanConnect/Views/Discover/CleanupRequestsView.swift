// CleanupRequestsView.swift
// Map-based cleanup requests where people can post and pick up jobs

import SwiftUI
import MapKit

struct CleanupRequestsView: View {
    @StateObject private var service = CleanupRequestService.shared
    @StateObject private var locationManager = LocationManager.shared
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 20.5937, longitude: 78.9629), // India center
        span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
    )
    @State private var selectedJob: CleanupJob?
    @State private var showCreateSheet = false
    @State private var showListView = false
    @State private var showFilterSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Map View
                Map(coordinateRegion: $region, annotationItems: service.jobs) { job in
                    MapAnnotation(coordinate: job.coordinate) {
                        JobMapPin(job: job, isSelected: selectedJob?.id == job.id) {
                            withAnimation {
                                selectedJob = job
                                region.center = job.coordinate
                            }
                        }
                    }
                }
                .ignoresSafeArea(edges: .bottom)

                // Overlay controls
                VStack {
                    Spacer()

                    // Selected job card
                    if let job = selectedJob {
                        JobPreviewCard(job: job) {
                            selectedJob = nil
                        }
                        .padding(.horizontal)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // Bottom controls
                    HStack(spacing: 12) {
                        // List view toggle
                        Button {
                            showListView = true
                        } label: {
                            Image(systemName: "list.bullet")
                                .font(.title3)
                                .foregroundColor(.primary)
                                .frame(width: 50, height: 50)
                                .background(.regularMaterial)
                                .clipShape(Circle())
                        }

                        Spacer()

                        // Create new request
                        Button {
                            showCreateSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "plus")
                                Text("Post Request")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .background(Color.green)
                            .clipShape(Capsule())
                            .shadow(radius: 4)
                        }

                        Spacer()

                        // Filter
                        Button {
                            showFilterSheet = true
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.title3)
                                .foregroundColor(.primary)
                                .frame(width: 50, height: 50)
                                .background(.regularMaterial)
                                .clipShape(Circle())
                        }
                    }
                    .padding()
                }

                // Location button
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            centerOnUser()
                        } label: {
                            Image(systemName: "location.fill")
                                .font(.title3)
                                .foregroundColor(.blue)
                                .frame(width: 44, height: 44)
                                .background(.regularMaterial)
                                .clipShape(Circle())
                        }
                        .padding()
                    }
                    Spacer()
                }
                .padding(.top, 60)

                // Loading overlay
                if service.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(width: 80, height: 80)
                        .background(.regularMaterial)
                        .cornerRadius(16)
                }
            }
            .navigationTitle("Cleanup Requests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        MyJobsView()
                    } label: {
                        Image(systemName: "person.crop.circle")
                    }
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                CreateJobSheet()
            }
            .sheet(isPresented: $showListView) {
                JobsListView(jobs: service.jobs, selectedJob: $selectedJob)
            }
            .task {
                await service.loadJobs()
                centerOnUser()
            }
            .refreshable {
                await service.loadJobs()
            }
        }
    }

    private func centerOnUser() {
        if let location = locationManager.lastLocation {
            withAnimation {
                region = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            }
        }
    }
}

// MARK: - Job Map Pin

struct JobMapPin: View {
    let job: CleanupJob
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(categoryColor)
                        .frame(width: isSelected ? 50 : 40, height: isSelected ? 50 : 40)

                    Image(systemName: job.category.icon)
                        .font(isSelected ? .title2 : .body)
                        .foregroundColor(.white)
                }
                .shadow(radius: isSelected ? 4 : 2)

                // Points badge
                if job.pointsReward > 0 {
                    Text("+\(job.pointsReward)")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange)
                        .cornerRadius(8)
                        .offset(y: -5)
                }
            }
        }
        .animation(.spring(), value: isSelected)
    }

    private var categoryColor: Color {
        switch job.category.color {
        case "orange": return .orange
        case "purple": return .purple
        case "green": return .green
        case "blue": return .blue
        case "cyan": return .cyan
        case "gray": return .gray
        case "mint": return .mint
        default: return .brown
        }
    }
}

// MARK: - Job Preview Card

struct JobPreviewCard: View {
    let job: CleanupJob
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Category icon
                Image(systemName: job.category.icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(categoryColor)
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 2) {
                    Text(job.title)
                        .font(.headline)
                        .lineLimit(1)

                    Text(job.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }

            Text(job.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)

            HStack {
                // Reward
                Label("+\(job.pointsReward) pts", systemImage: "star.fill")
                    .font(.caption.bold())
                    .foregroundColor(.orange)

                if let tip = job.tipReward, tip > 0 {
                    Label("₹\(tip) tip", systemImage: "indianrupeesign.circle.fill")
                        .font(.caption.bold())
                        .foregroundColor(.green)
                }

                Spacer()

                // Difficulty
                Text(job.difficulty.rawValue)
                    .font(.caption.bold())
                    .foregroundColor(difficultyColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(difficultyColor.opacity(0.2))
                    .cornerRadius(6)
            }

            // Action button
            NavigationLink {
                JobDetailView(job: job)
            } label: {
                Text("View Details")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 8)
    }

    private var categoryColor: Color {
        switch job.category.color {
        case "orange": return .orange
        case "purple": return .purple
        case "green": return .green
        case "blue": return .blue
        case "cyan": return .cyan
        case "gray": return .gray
        case "mint": return .mint
        default: return .brown
        }
    }

    private var difficultyColor: Color {
        switch job.difficulty {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
}

// MARK: - Jobs List View

struct JobsListView: View {
    let jobs: [CleanupJob]
    @Binding var selectedJob: CleanupJob?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(jobs) { job in
                NavigationLink {
                    JobDetailView(job: job)
                } label: {
                    JobRowView(job: job)
                }
            }
            .navigationTitle("All Requests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if jobs.isEmpty {
                    ContentUnavailableView(
                        "No Requests Yet",
                        systemImage: "mappin.slash",
                        description: Text("Be the first to post a cleanup request!")
                    )
                }
            }
        }
    }
}

// MARK: - Job Row View

struct JobRowView: View {
    let job: CleanupJob

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: job.category.icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(categoryColor)
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                Text(job.title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)

                HStack {
                    Text(job.address ?? job.district)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("+\(job.pointsReward) pts")
                        .font(.caption.bold())
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var categoryColor: Color {
        switch job.category.color {
        case "orange": return .orange
        case "purple": return .purple
        case "green": return .green
        case "blue": return .blue
        case "cyan": return .cyan
        case "gray": return .gray
        case "mint": return .mint
        default: return .brown
        }
    }
}

// MARK: - Job Detail View

struct JobDetailView: View {
    let job: CleanupJob
    @StateObject private var service = CleanupRequestService.shared
    @EnvironmentObject var userState: UserState
    @State private var isProcessing = false
    @State private var showClaimSuccess = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(job.category.rawValue)
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(categoryColor)
                            .cornerRadius(6)

                        Text(job.difficulty.rawValue)
                            .font(.caption.bold())
                            .foregroundColor(difficultyColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(difficultyColor.opacity(0.2))
                            .cornerRadius(6)

                        Spacer()

                        Text(job.status.rawValue)
                            .font(.caption.bold())
                            .foregroundColor(statusColor)
                    }

                    Text(job.title)
                        .font(.title2.bold())

                    Text(job.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }

                // Rewards
                HStack(spacing: 20) {
                    VStack {
                        Text("+\(job.pointsReward)")
                            .font(.title.bold())
                            .foregroundColor(.orange)
                        Text("Points")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)

                    if let tip = job.tipReward, tip > 0 {
                        VStack {
                            Text("₹\(tip)")
                                .font(.title.bold())
                                .foregroundColor(.green)
                            Text("Tip")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                    }

                    VStack {
                        Text("~\(job.estimatedTime) min")
                            .font(.title3.bold())
                            .foregroundColor(.blue)
                        Text("Time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }

                // Location
                VStack(alignment: .leading, spacing: 8) {
                    Text("Location")
                        .font(.headline)

                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.red)
                        Text(job.address ?? "\(job.district), \(job.state)")
                            .font(.subheadline)
                    }

                    // Mini map
                    Map(coordinateRegion: .constant(MKCoordinateRegion(
                        center: job.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )), annotationItems: [job]) { j in
                        MapMarker(coordinate: j.coordinate, tint: .red)
                    }
                    .frame(height: 150)
                    .cornerRadius(12)
                    .disabled(true)
                }

                // Posted by
                VStack(alignment: .leading, spacing: 8) {
                    Text("Posted by")
                        .font(.headline)

                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)

                        VStack(alignment: .leading) {
                            Text(job.creatorName)
                                .font(.subheadline.weight(.medium))
                            Text(job.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer(minLength: 100)
            }
            .padding()
        }
        .navigationTitle("Request Details")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if job.status == .open {
                Button {
                    claimJob()
                } label: {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "hand.raised.fill")
                            Text("Accept This Job")
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(16)
                }
                .disabled(isProcessing)
                .padding()
                .background(.regularMaterial)
            } else if job.claimedBy == userState.currentUser?.id {
                VStack(spacing: 12) {
                    Text("You've accepted this job")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Button {
                        // Navigate to complete flow
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Mark as Complete")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(16)
                    }
                }
                .padding()
                .background(.regularMaterial)
            }
        }
        .alert("Job Accepted!", isPresented: $showClaimSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("You've accepted this cleanup job. Complete it and post proof to earn \(job.pointsReward) points!")
        }
    }

    private func claimJob() {
        isProcessing = true
        Task {
            do {
                try await service.claimJob(job)
                await MainActor.run {
                    isProcessing = false
                    showClaimSuccess = true
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                }
            }
        }
    }

    private var categoryColor: Color {
        switch job.category.color {
        case "orange": return .orange
        case "purple": return .purple
        case "green": return .green
        case "blue": return .blue
        case "cyan": return .cyan
        case "gray": return .gray
        case "mint": return .mint
        default: return .brown
        }
    }

    private var difficultyColor: Color {
        switch job.difficulty {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }

    private var statusColor: Color {
        switch job.status {
        case .open: return .green
        case .claimed, .inProgress: return .orange
        case .proofSubmitted: return .blue
        case .verified, .completed: return .green
        case .expired, .cancelled: return .red
        }
    }
}

// MARK: - Create Job Sheet

struct CreateJobSheet: View {
    @StateObject private var service = CleanupRequestService.shared
    @StateObject private var locationManager = LocationManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var category: CleanupJob.JobCategory = .litter
    @State private var difficulty: CleanupJob.JobDifficulty = .easy
    @State private var estimatedTime = 30
    @State private var pointsReward = 50
    @State private var tipReward = ""
    @State private var address = ""
    @State private var selectedState = "Maharashtra"
    @State private var selectedDistrict = "Mumbai"
    @State private var isSubmitting = false

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

                    Stepper("Est. Time: \(estimatedTime) min", value: $estimatedTime, in: 15...180, step: 15)
                }

                Section("Rewards") {
                    Stepper("Points: \(pointsReward)", value: $pointsReward, in: 10...500, step: 10)

                    HStack {
                        Text("Tip (optional)")
                        Spacer()
                        TextField("₹0", text: $tipReward)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }

                Section("Location") {
                    TextField("Address/Landmark", text: $address)

                    Picker("State", selection: $selectedState) {
                        ForEach(IndianStates.all, id: \.self) { state in
                            Text(state).tag(state)
                        }
                    }

                    TextField("District", text: $selectedDistrict)

                    if let location = locationManager.lastLocation {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.blue)
                            Text("Using current location")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Post Cleanup Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        submitJob()
                    } label: {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("Post")
                                .bold()
                        }
                    }
                    .disabled(title.isEmpty || description.isEmpty || isSubmitting)
                }
            }
        }
    }

    private func submitJob() {
        isSubmitting = true
        Task {
            do {
                let location = locationManager.lastLocation
                try await service.createJob(
                    title: title,
                    description: description,
                    category: category,
                    difficulty: difficulty,
                    estimatedTime: estimatedTime,
                    latitude: location?.coordinate.latitude ?? 19.076,
                    longitude: location?.coordinate.longitude ?? 72.8777,
                    address: address.isEmpty ? nil : address,
                    district: selectedDistrict,
                    state: selectedState,
                    pointsReward: pointsReward,
                    tipReward: Int(tipReward)
                )
                await MainActor.run {
                    dismiss()
                }
            } catch {
                isSubmitting = false
            }
        }
    }
}

// MARK: - My Jobs View

struct MyJobsView: View {
    @StateObject private var service = CleanupRequestService.shared
    @State private var myJobs: [CleanupJob] = []
    @State private var claimedJobs: [CleanupJob] = []
    @State private var selectedTab = 0

    var body: some View {
        VStack {
            Picker("", selection: $selectedTab) {
                Text("My Requests").tag(0)
                Text("Accepted Jobs").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()

            if selectedTab == 0 {
                List(myJobs) { job in
                    NavigationLink {
                        JobDetailView(job: job)
                    } label: {
                        JobRowView(job: job)
                    }
                }
                .overlay {
                    if myJobs.isEmpty {
                        ContentUnavailableView(
                            "No Requests Posted",
                            systemImage: "plus.circle",
                            description: Text("Post a cleanup request to get help from the community")
                        )
                    }
                }
            } else {
                List(claimedJobs) { job in
                    NavigationLink {
                        JobDetailView(job: job)
                    } label: {
                        JobRowView(job: job)
                    }
                }
                .overlay {
                    if claimedJobs.isEmpty {
                        ContentUnavailableView(
                            "No Jobs Accepted",
                            systemImage: "hand.raised",
                            description: Text("Accept cleanup requests to help your community")
                        )
                    }
                }
            }
        }
        .navigationTitle("My Activity")
        .task {
            do {
                myJobs = try await service.getMyJobs()
                claimedJobs = try await service.getClaimedJobs()
            } catch {
                // Silently fail
            }
        }
    }
}

#Preview {
    CleanupRequestsView()
        .environmentObject(UserState.shared)
}
